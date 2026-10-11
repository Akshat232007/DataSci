package com.datasci;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class Statistics {

    public static List<Double> extractNumbers(List<String> headers, List<List<String>> dataRows, String column) {
        List<Double> numbers = new ArrayList<>();
        int colIndex = headers.indexOf(column);
        if (colIndex == -1 || dataRows == null) {
            return numbers;
        }

        for (List<String> row : dataRows) {
            if (colIndex < row.size()) {
                String val = row.get(colIndex);
                if (ReadData.isNumeric(val)) {
                    numbers.add(Double.parseDouble(val.trim()));
                }
            }
        }
        return numbers;
    }

    public static int getCount(List<Double> values) {
        return values.size();
    }

    public static double getSum(List<Double> values) {
        double sum = 0;
        for (double v : values) {
            sum += v;
        }
        return sum;
    }

    public static double getMean(List<Double> values) {
        if (values.isEmpty()) {
            return 0;
        }
        return getSum(values) / values.size();
    }

    public static double getMedian(List<Double> values) {
        if (values.isEmpty()) {
            return 0;
        }
        List<Double> sorted = new ArrayList<>(values);
        Collections.sort(sorted);
        int n = sorted.size();
        if (n % 2 == 1) {
            return sorted.get(n / 2);
        } else {
            return (sorted.get((n / 2) - 1) + sorted.get(n / 2)) / 2.0;
        }
    }

    public static double getMode(List<Double> values) {
        if (values.isEmpty()) {
            return 0;
        }
        Map<Double, Integer> freq = new HashMap<>();
        for (double v : values) {
            freq.put(v, freq.getOrDefault(v, 0) + 1);
        }
        double mode = values.get(0);
        int maxCount = 0;
        for (Map.Entry<Double, Integer> entry : freq.entrySet()) {
            if (entry.getValue() > maxCount) {
                maxCount = entry.getValue();
                mode = entry.getKey();
            }
        }
        return mode;
    }

    public static double getMin(List<Double> values) {
        if (values.isEmpty()) {
            return 0;
        }
        double min = values.get(0);
        for (double v : values) {
            if (v < min) {
                min = v;
            }
        }
        return min;
    }

    public static double getMax(List<Double> values) {
        if (values.isEmpty()) {
            return 0;
        }
        double max = values.get(0);
        for (double v : values) {
            if (v > max) {
                max = v;
            }
        }
        return max;
    }

    public static double getRange(List<Double> values) {
        if (values.isEmpty()) {
            return 0;
        }
        return getMax(values) - getMin(values);
    }

    public static double getVariance(List<Double> values) {
        if (values.size() <= 1) {
            return 0;
        }
        double mean = getMean(values);
        double sumSq = 0;
        for (double v : values) {
            sumSq += Math.pow(v - mean, 2);
        }
        return sumSq / (values.size() - 1);
    }

    public static double getStandardDeviation(List<Double> values) {
        return Math.sqrt(getVariance(values));
    }

    public static Map<String, String> calculateAll(List<String> headers, List<List<String>> dataRows, String column) {
        Map<String, String> results = new LinkedHashMap<>();
        List<Double> numbers = extractNumbers(headers, dataRows, column);
        if (numbers.isEmpty()) {
            return results;
        }

        results.put("Column", column);
        results.put("Count", String.valueOf(getCount(numbers)));
        results.put("Sum", String.format("%.2f", getSum(numbers)));
        results.put("Mean", String.format("%.2f", getMean(numbers)));
        results.put("Median", String.format("%.2f", getMedian(numbers)));
        results.put("Mode", String.format("%.2f", getMode(numbers)));
        results.put("Minimum", String.format("%.2f", getMin(numbers)));
        results.put("Maximum", String.format("%.2f", getMax(numbers)));
        results.put("Range", String.format("%.2f", getRange(numbers)));
        results.put("Variance", String.format("%.4f", getVariance(numbers)));
        results.put("Standard Deviation", String.format("%.4f", getStandardDeviation(numbers)));

        return results;
    }
}
