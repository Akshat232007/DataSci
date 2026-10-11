package com.datasci;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class GroupData {

    public static class GroupResult {
        public List<String> resultHeaders;
        public List<List<String>> resultRows;

        public GroupResult(List<String> headers, List<List<String>> rows) {
            this.resultHeaders = headers;
            this.resultRows = rows;
        }
    }

    public static GroupResult group(List<String> headers, List<List<String>> dataRows, 
                                    String groupCol, String operation, String numCol) {
        int groupIndex = headers.indexOf(groupCol);
        int numIndex = (numCol != null && !numCol.isEmpty()) ? headers.indexOf(numCol) : -1;

        Map<String, List<Double>> groupMap = new LinkedHashMap<>();
        Map<String, Integer> countMap = new LinkedHashMap<>();

        if (groupIndex != -1 && dataRows != null) {
            for (List<String> row : dataRows) {
                if (groupIndex < row.size()) {
                    String groupVal = row.get(groupIndex);
                    if (ReadData.isValueMissing(groupVal)) {
                        groupVal = "(Empty)";
                    } else {
                        groupVal = groupVal.trim();
                    }

                    countMap.put(groupVal, countMap.getOrDefault(groupVal, 0) + 1);

                    if (numIndex != -1 && numIndex < row.size()) {
                        String numVal = row.get(numIndex);
                        if (ReadData.isNumeric(numVal)) {
                            if (!groupMap.containsKey(groupVal)) {
                                groupMap.put(groupVal, new ArrayList<>());
                            }
                            groupMap.get(groupVal).add(Double.parseDouble(numVal.trim()));
                        }
                    }
                }
            }
        }

        List<String> resHeaders = new ArrayList<>();
        resHeaders.add(groupCol);
        String opUpper = (operation != null) ? operation.toUpperCase() : "COUNT";

        if ("COUNT".equals(opUpper)) {
            resHeaders.add("Count");
        } else {
            resHeaders.add(opUpper + " of " + numCol);
        }

        List<List<String>> resRows = new ArrayList<>();
        for (String key : countMap.keySet()) {
            List<String> row = new ArrayList<>();
            row.add(key);

            if ("COUNT".equals(opUpper)) {
                row.add(String.valueOf(countMap.get(key)));
            } else {
                List<Double> vals = groupMap.get(key);
                if (vals == null || vals.isEmpty()) {
                    row.add("N/A");
                } else {
                    double calculated = 0;
                    switch (opUpper) {
                        case "SUM":
                            double sum = 0;
                            for (double d : vals) sum += d;
                            calculated = sum;
                            row.add(String.format("%.2f", calculated));
                            break;
                        case "AVERAGE":
                        case "AVG":
                        case "MEAN":
                            double total = 0;
                            for (double d : vals) total += d;
                            calculated = total / vals.size();
                            row.add(String.format("%.2f", calculated));
                            break;
                        case "MINIMUM":
                        case "MIN":
                            double min = vals.get(0);
                            for (double d : vals) if (d < min) min = d;
                            calculated = min;
                            row.add(String.format("%.2f", calculated));
                            break;
                        case "MAXIMUM":
                        case "MAX":
                            double max = vals.get(0);
                            for (double d : vals) if (d > max) max = d;
                            calculated = max;
                            row.add(String.format("%.2f", calculated));
                            break;
                        default:
                            row.add(String.valueOf(vals.size()));
                            break;
                    }
                }
            }
            resRows.add(row);
        }

        return new GroupResult(resHeaders, resRows);
    }
}
