package com.datasci;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class CleanData {

    public static List<List<String>> removeMissingRows(List<String> headers, List<List<String>> dataRows) {
        List<List<String>> cleaned = new ArrayList<>();
        int colCount = headers.size();
        for (List<String> row : dataRows) {
            boolean hasMissing = false;
            for (int c = 0; c < colCount; c++) {
                if (c >= row.size() || ReadData.isValueMissing(row.get(c))) {
                    hasMissing = true;
                    break;
                }
            }
            if (!hasMissing) {
                cleaned.add(new ArrayList<>(row));
            }
        }
        return cleaned;
    }

    public static int fillMissingWithMean(List<String> headers, List<List<String>> dataRows, String column) {
        int colIndex = headers.indexOf(column);
        if (colIndex == -1) {
            return 0;
        }

        double sum = 0;
        int count = 0;
        for (List<String> row : dataRows) {
            if (colIndex < row.size()) {
                String val = row.get(colIndex);
                if (ReadData.isNumeric(val)) {
                    sum += Double.parseDouble(val.trim());
                    count++;
                }
            }
        }

        if (count == 0) {
            return 0;
        }

        double mean = sum / count;
        String meanStr = String.format("%.2f", mean);

        int filledCount = 0;
        for (List<String> row : dataRows) {
            while (row.size() <= colIndex) {
                row.add("");
            }
            if (ReadData.isValueMissing(row.get(colIndex))) {
                row.set(colIndex, meanStr);
                filledCount++;
            }
        }
        return filledCount;
    }

    public static int fillMissingWithMedian(List<String> headers, List<List<String>> dataRows, String column) {
        int colIndex = headers.indexOf(column);
        if (colIndex == -1) {
            return 0;
        }

        List<Double> values = new ArrayList<>();
        for (List<String> row : dataRows) {
            if (colIndex < row.size()) {
                String val = row.get(colIndex);
                if (ReadData.isNumeric(val)) {
                    values.add(Double.parseDouble(val.trim()));
                }
            }
        }

        if (values.isEmpty()) {
            return 0;
        }

        Collections.sort(values);
        double median;
        int n = values.size();
        if (n % 2 == 1) {
            median = values.get(n / 2);
        } else {
            median = (values.get((n / 2) - 1) + values.get(n / 2)) / 2.0;
        }

        String medianStr = String.format("%.2f", median);
        int filledCount = 0;
        for (List<String> row : dataRows) {
            while (row.size() <= colIndex) {
                row.add("");
            }
            if (ReadData.isValueMissing(row.get(colIndex))) {
                row.set(colIndex, medianStr);
                filledCount++;
            }
        }
        return filledCount;
    }

    public static int fillMissingWithMode(List<String> headers, List<List<String>> dataRows, String column) {
        int colIndex = headers.indexOf(column);
        if (colIndex == -1) {
            return 0;
        }

        Map<String, Integer> freq = new HashMap<>();
        for (List<String> row : dataRows) {
            if (colIndex < row.size()) {
                String val = row.get(colIndex);
                if (!ReadData.isValueMissing(val)) {
                    String clean = val.trim();
                    freq.put(clean, freq.getOrDefault(clean, 0) + 1);
                }
            }
        }

        if (freq.isEmpty()) {
            return 0;
        }

        String mode = "";
        int maxFreq = -1;
        for (Map.Entry<String, Integer> entry : freq.entrySet()) {
            if (entry.getValue() > maxFreq) {
                maxFreq = entry.getValue();
                mode = entry.getKey();
            }
        }

        int filledCount = 0;
        for (List<String> row : dataRows) {
            while (row.size() <= colIndex) {
                row.add("");
            }
            if (ReadData.isValueMissing(row.get(colIndex))) {
                row.set(colIndex, mode);
                filledCount++;
            }
        }
        return filledCount;
    }

    public static List<List<String>> removeDuplicates(List<List<String>> dataRows) {
        List<List<String>> unique = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        for (List<String> row : dataRows) {
            String key = String.join("|||", row);
            if (!seen.contains(key)) {
                seen.add(key);
                unique.add(new ArrayList<>(row));
            }
        }
        return unique;
    }

    public static boolean renameColumn(List<String> headers, String oldName, String newName) {
        int index = headers.indexOf(oldName);
        if (index != -1 && newName != null && !newName.trim().isEmpty()) {
            headers.set(index, newName.trim());
            return true;
        }
        return false;
    }

    public static boolean deleteColumn(List<String> headers, List<List<String>> dataRows, String column) {
        int index = headers.indexOf(column);
        if (index == -1) {
            return false;
        }
        headers.remove(index);
        for (List<String> row : dataRows) {
            if (index < row.size()) {
                row.remove(index);
            }
        }
        return true;
    }
}
