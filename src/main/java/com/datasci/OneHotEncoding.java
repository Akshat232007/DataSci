package com.datasci;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class OneHotEncoding {

    public static class EncodingResult {
        public List<String> encodedHeaders;
        public List<List<String>> encodedRows;
        public List<String> newlyGeneratedColumns;
        public int originalColumnCount;
        public int encodedColumnCount;
        public String message;
        public boolean success;

        public EncodingResult() {
            this.encodedHeaders = new ArrayList<>();
            this.encodedRows = new ArrayList<>();
            this.newlyGeneratedColumns = new ArrayList<>();
            this.success = false;
        }
    }

    public static final int MAX_DISTINCT_CATEGORIES = 50;

    /**
     * Performs One-Hot Encoding on selected categorical columns.
     * Policy:
     * - Each distinct category generates a binary (0/1) indicator column.
     * - If a row has a missing category value, all indicator columns for that variable receive '0'.
     * - Columns with more than MAX_DISTINCT_CATEGORIES unique values are rejected to protect performance.
     */
    public static EncodingResult encode(List<String> headers, List<List<String>> dataRows, List<String> targetColumns) {
        EncodingResult result = new EncodingResult();
        if (headers == null || dataRows == null || targetColumns == null || targetColumns.isEmpty()) {
            result.message = "Please select at least one column to encode.";
            return result;
        }

        // Verify target columns exist and are categorical
        List<String> numCols = ReadData.getNumericalColumns(headers, dataRows);
        for (String col : targetColumns) {
            if (!headers.contains(col)) {
                result.message = "Column '" + col + "' does not exist in dataset.";
                return result;
            }
            if (numCols.contains(col)) {
                result.message = "Column '" + col + "' is a numerical column. One-Hot Encoding only applies to categorical columns.";
                return result;
            }
        }

        // Collect distinct non-missing categories per target column in order of appearance
        Map<String, List<String>> categoriesPerCol = new LinkedHashMap<>();
        for (String col : targetColumns) {
            int colIdx = headers.indexOf(col);
            Set<String> seen = new LinkedHashSet<>();
            for (List<String> row : dataRows) {
                if (colIdx < row.size()) {
                    String val = row.get(colIdx);
                    if (!ReadData.isValueMissing(val)) {
                        seen.add(val.trim());
                    }
                }
            }
            if (seen.isEmpty()) {
                result.message = "Column '" + col + "' contains no valid categories to encode.";
                return result;
            }
            if (seen.size() > MAX_DISTINCT_CATEGORIES) {
                result.message = "Column '" + col + "' has too many unique categories (" + seen.size() 
                        + "). Maximum limit is " + MAX_DISTINCT_CATEGORIES + " to prevent table overflow.";
                return result;
            }
            categoriesPerCol.put(col, new ArrayList<>(seen));
        }

        // Build new headers, preventing collisions with existing headers
        List<String> newHeaders = new ArrayList<>();
        List<String> newlyGenerated = new ArrayList<>();
        Set<String> headerLookup = new HashSet<>();

        for (int i = 0; i < headers.size(); i++) {
            String col = headers.get(i);
            if (categoriesPerCol.containsKey(col)) {
                List<String> cats = categoriesPerCol.get(col);
                for (String cat : cats) {
                    String cleanCat = cat.replaceAll("[^a-zA-Z0-9_]", "_");
                    String candidateName = col + "_" + cleanCat;
                    int counter = 1;
                    while (headers.contains(candidateName) || headerLookup.contains(candidateName)) {
                        candidateName = col + "_" + cleanCat + "_" + (counter++);
                    }
                    headerLookup.add(candidateName);
                    newHeaders.add(candidateName);
                    newlyGenerated.add(candidateName);
                }
            } else {
                newHeaders.add(col);
                headerLookup.add(col);
            }
        }

        // Build new rows with 0/1 binary indicator values
        List<List<String>> newRows = new ArrayList<>();
        for (List<String> row : dataRows) {
            List<String> newRow = new ArrayList<>();
            for (int i = 0; i < headers.size(); i++) {
                String col = headers.get(i);
                if (categoriesPerCol.containsKey(col)) {
                    List<String> cats = categoriesPerCol.get(col);
                    String rowVal = (i < row.size()) ? row.get(i) : "";
                    boolean isMissing = ReadData.isValueMissing(rowVal);
                    String cleanVal = isMissing ? "" : rowVal.trim();
                    for (String cat : cats) {
                        if (!isMissing && cleanVal.equals(cat)) {
                            newRow.add("1");
                        } else {
                            newRow.add("0");
                        }
                    }
                } else {
                    newRow.add((i < row.size()) ? row.get(i) : "");
                }
            }
            newRows.add(newRow);
        }

        result.encodedHeaders = newHeaders;
        result.encodedRows = newRows;
        result.newlyGeneratedColumns = newlyGenerated;
        result.originalColumnCount = headers.size();
        result.encodedColumnCount = newHeaders.size();
        result.success = true;
        result.message = "Successfully encoded " + targetColumns.size() + " categorical column(s) into " 
                + newlyGenerated.size() + " binary indicator column(s).";
        return result;
    }
}
