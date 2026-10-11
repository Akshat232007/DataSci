package com.datasci;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;

public class ReadData {

    public static List<String> parseLine(String line) {
        List<String> values = new ArrayList<>();
        if (line == null) {
            return values;
        }
        StringBuilder current = new StringBuilder();
        boolean inQuotes = false;
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '\"') {
                if (inQuotes && i + 1 < line.length() && line.charAt(i + 1) == '\"') {
                    // Escaped double quote ("" -> ") inside quotes
                    current.append('\"');
                    i++;
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (c == ',' && !inQuotes) {
                values.add(current.toString().trim());
                current.setLength(0);
            } else {
                current.append(c);
            }
        }
        values.add(current.toString().trim());
        return values;
    }

    public static List<List<String>> readAll(String filePath) throws IOException {
        List<List<String>> records = new ArrayList<>();
        File file = new File(filePath);
        if (!file.exists()) {
            return records;
        }
        try (BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(file), StandardCharsets.UTF_8))) {
            String line;
            boolean firstLine = true;
            while ((line = br.readLine()) != null) {
                if (firstLine) {
                    firstLine = false;
                    if (line.startsWith("\uFEFF")) {
                        line = line.substring(1);
                    }
                }
                if (line.trim().isEmpty()) {
                    continue;
                }
                records.add(parseLine(line));
            }
        }
        return records;
    }

    public static List<String> getHeaders(List<List<String>> allRows) {
        if (allRows != null && !allRows.isEmpty()) {
            return new ArrayList<>(allRows.get(0));
        }
        return new ArrayList<>();
    }

    public static List<List<String>> getDataRows(List<List<String>> allRows) {
        List<List<String>> data = new ArrayList<>();
        if (allRows != null && allRows.size() > 1) {
            int headerCount = allRows.get(0).size();
            for (int i = 1; i < allRows.size(); i++) {
                List<String> row = new ArrayList<>(allRows.get(i));
                while (row.size() < headerCount) {
                    row.add("");
                }
                data.add(row);
            }
        }
        return data;
    }

    public static int getTotalRows(List<List<String>> dataRows) {
        return (dataRows != null) ? dataRows.size() : 0;
    }

    public static int getTotalColumns(List<String> headers) {
        return (headers != null) ? headers.size() : 0;
    }

    public static List<List<String>> getPreview(List<List<String>> dataRows, int count) {
        List<List<String>> preview = new ArrayList<>();
        if (dataRows == null) {
            return preview;
        }
        int limit = Math.min(count, dataRows.size());
        for (int i = 0; i < limit; i++) {
            preview.add(dataRows.get(i));
        }
        return preview;
    }

    public static boolean isNumeric(String str) {
        if (str == null || str.trim().isEmpty()) {
            return false;
        }
        try {
            Double.parseDouble(str.trim());
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    public static boolean isValueMissing(String val) {
        if (val == null) {
            return true;
        }
        String clean = val.trim();
        return clean.isEmpty() 
            || clean.equalsIgnoreCase("null") 
            || clean.equalsIgnoreCase("na") 
            || clean.equalsIgnoreCase("n/a")
            || clean.equalsIgnoreCase("nan")
            || clean.equalsIgnoreCase("none");
    }

    public static List<String> getNumericalColumns(List<String> headers, List<List<String>> dataRows) {
        List<String> numerical = new ArrayList<>();
        if (headers == null || dataRows == null || dataRows.isEmpty()) {
            return numerical;
        }

        for (int col = 0; col < headers.size(); col++) {
            boolean hasAtLeastOneNumber = false;
            boolean allNumbers = true;

            for (List<String> row : dataRows) {
                if (col < row.size()) {
                    String val = row.get(col);
                    if (!isValueMissing(val)) {
                        if (isNumeric(val)) {
                            hasAtLeastOneNumber = true;
                        } else {
                            allNumbers = false;
                            break;
                        }
                    }
                }
            }

            if (hasAtLeastOneNumber && allNumbers) {
                numerical.add(headers.get(col));
            }
        }
        return numerical;
    }

    public static List<String> getCategoricalColumns(List<String> headers, List<List<String>> dataRows) {
        List<String> categorical = new ArrayList<>();
        if (headers == null) {
            return categorical;
        }
        List<String> numerical = getNumericalColumns(headers, dataRows);
        for (String col : headers) {
            if (!numerical.contains(col)) {
                categorical.add(col);
            }
        }
        return categorical;
    }

    public static Map<String, Integer> getMissingValueCounts(List<String> headers, List<List<String>> dataRows) {
        Map<String, Integer> missingMap = new HashMap<>();
        if (headers == null || dataRows == null) {
            return missingMap;
        }

        for (int col = 0; col < headers.size(); col++) {
            String colName = headers.get(col);
            int missingCount = 0;
            for (List<String> row : dataRows) {
                if (col >= row.size() || isValueMissing(row.get(col))) {
                    missingCount++;
                }
            }
            missingMap.put(colName, missingCount);
        }
        return missingMap;
    }

    public static int getTotalMissingRows(List<List<String>> dataRows, int colCount) {
        if (dataRows == null) {
            return 0;
        }
        int count = 0;
        for (List<String> row : dataRows) {
            boolean hasMissing = false;
            for (int col = 0; col < colCount; col++) {
                if (col >= row.size() || isValueMissing(row.get(col))) {
                    hasMissing = true;
                    break;
                }
            }
            if (hasMissing) {
                count++;
            }
        }
        return count;
    }

    public static int getDuplicateRowCount(List<List<String>> dataRows) {
        if (dataRows == null || dataRows.isEmpty()) {
            return 0;
        }
        Set<String> seen = new HashSet<>();
        int duplicates = 0;
        for (List<String> row : dataRows) {
            String rowStr = String.join("|||", row);
            if (!seen.add(rowStr)) {
                duplicates++;
            }
        }
        return duplicates;
    }

    public static void writeCSV(String filePath, List<String> headers, List<List<String>> dataRows) throws IOException {
        File file = new File(filePath);
        if (file.getParentFile() != null && !file.getParentFile().exists()) {
            file.getParentFile().mkdirs();
        }
        try (BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(file), StandardCharsets.UTF_8))) {
            // Write headers
            bw.write(formatCSVLine(headers));
            bw.newLine();
            // Write rows
            for (List<String> row : dataRows) {
                bw.write(formatCSVLine(row));
                bw.newLine();
            }
        }
    }

    private static String formatCSVLine(List<String> items) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < items.size(); i++) {
            String item = items.get(i);
            if (item == null) {
                item = "";
            }
            if (item.contains(",") || item.contains("\"") || item.contains("\n") || item.contains("\r")) {
                sb.append("\"").append(item.replace("\"", "\"\"")).append("\"");
            } else {
                sb.append(item);
            }
            if (i < items.size() - 1) {
                sb.append(",");
            }
        }
        return sb.toString();
    }
}
