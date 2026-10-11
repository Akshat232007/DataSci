package com.datasci;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class FilterData {

    public static List<List<String>> filter(List<String> headers, List<List<String>> dataRows, 
                                            String column, String operator, double targetValue) {
        List<List<String>> result = new ArrayList<>();
        int colIndex = headers.indexOf(column);
        if (colIndex == -1 || dataRows == null) {
            return result;
        }

        for (List<String> row : dataRows) {
            if (colIndex < row.size()) {
                String cell = row.get(colIndex);
                if (ReadData.isNumeric(cell)) {
                    double val = Double.parseDouble(cell.trim());
                    boolean match = false;

                    switch (operator) {
                        case ">":
                            match = (val > targetValue);
                            break;
                        case "<":
                            match = (val < targetValue);
                            break;
                        case "=":
                        case "==":
                            match = (Math.abs(val - targetValue) < 0.0001);
                            break;
                        case "!=":
                            match = (Math.abs(val - targetValue) >= 0.0001);
                            break;
                        case ">=":
                            match = (val >= targetValue - 0.0001);
                            break;
                        case "<=":
                            match = (val <= targetValue + 0.0001);
                            break;
                    }

                    if (match) {
                        result.add(new ArrayList<>(row));
                    }
                }
            }
        }
        return result;
    }

    public static List<List<String>> sort(List<String> headers, List<List<String>> dataRows, 
                                          String column, boolean ascending) {
        List<List<String>> sorted = new ArrayList<>();
        for (List<String> r : dataRows) {
            sorted.add(new ArrayList<>(r));
        }

        int colIndex = headers.indexOf(column);
        if (colIndex == -1 || sorted.isEmpty()) {
            return sorted;
        }

        // Determine if this column is numeric in the current rows
        boolean numeric = true;
        for (List<String> r : sorted) {
            if (colIndex < r.size()) {
                String cell = r.get(colIndex);
                if (!ReadData.isValueMissing(cell) && !ReadData.isNumeric(cell)) {
                    numeric = false;
                    break;
                }
            }
        }

        final boolean isNumericCol = numeric;

        Collections.sort(sorted, new Comparator<List<String>>() {
            @Override
            public int compare(List<String> r1, List<String> r2) {
                String v1 = (colIndex < r1.size()) ? r1.get(colIndex) : "";
                String v2 = (colIndex < r2.size()) ? r2.get(colIndex) : "";

                int cmp;
                if (isNumericCol && ReadData.isNumeric(v1) && ReadData.isNumeric(v2)) {
                    double d1 = Double.parseDouble(v1.trim());
                    double d2 = Double.parseDouble(v2.trim());
                    cmp = Double.compare(d1, d2);
                } else {
                    cmp = v1.compareToIgnoreCase(v2);
                }

                return ascending ? cmp : -cmp;
            }
        });

        return sorted;
    }

    public static List<List<String>> getTopN(List<List<String>> rows, int n) {
        List<List<String>> result = new ArrayList<>();
        if (rows == null || n <= 0) {
            return result;
        }
        int limit = Math.min(n, rows.size());
        for (int i = 0; i < limit; i++) {
            result.add(new ArrayList<>(rows.get(i)));
        }
        return result;
    }

    public static List<List<String>> getBottomN(List<List<String>> rows, int n) {
        List<List<String>> result = new ArrayList<>();
        if (rows == null || n <= 0) {
            return result;
        }
        int size = rows.size();
        int start = Math.max(0, size - n);
        for (int i = start; i < size; i++) {
            result.add(new ArrayList<>(rows.get(i)));
        }
        return result;
    }
}
