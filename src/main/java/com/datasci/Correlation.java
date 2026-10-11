package com.datasci;

import java.util.ArrayList;
import java.util.List;

public class Correlation {

    public static class CorrelationResult {
        public String colX;
        public String colY;
        public int validCount;
        public double correlation;
        public String rangeDescription;
        public List<Double> xPoints;
        public List<Double> yPoints;

        public CorrelationResult() {
            xPoints = new ArrayList<>();
            yPoints = new ArrayList<>();
        }
    }

    public static CorrelationResult calculate(List<String> headers, List<List<String>> dataRows, 
                                             String colX, String colY) {
        CorrelationResult res = new CorrelationResult();
        res.colX = colX;
        res.colY = colY;

        int indexX = headers.indexOf(colX);
        int indexY = headers.indexOf(colY);

        if (indexX == -1 || indexY == -1 || dataRows == null) {
            return res;
        }

        List<Double> xList = new ArrayList<>();
        List<Double> yList = new ArrayList<>();

        for (List<String> row : dataRows) {
            if (indexX < row.size() && indexY < row.size()) {
                String valX = row.get(indexX);
                String valY = row.get(indexY);

                if (ReadData.isNumeric(valX) && ReadData.isNumeric(valY)) {
                    xList.add(Double.parseDouble(valX.trim()));
                    yList.add(Double.parseDouble(valY.trim()));
                }
            }
        }

        res.validCount = xList.size();
        res.xPoints = xList;
        res.yPoints = yList;

        if (xList.size() < 2) {
            res.correlation = 0.0;
            res.rangeDescription = "Insufficient data points to calculate correlation.";
            return res;
        }

        double sumX = 0;
        double sumY = 0;
        int n = xList.size();

        for (int i = 0; i < n; i++) {
            sumX += xList.get(i);
            sumY += yList.get(i);
        }

        double meanX = sumX / n;
        double meanY = sumY / n;

        double num = 0;
        double denX = 0;
        double denY = 0;

        for (int i = 0; i < n; i++) {
            double dx = xList.get(i) - meanX;
            double dy = yList.get(i) - meanY;
            num += dx * dy;
            denX += dx * dx;
            denY += dy * dy;
        }

        double denominator = Math.sqrt(denX * denY);
        if (denominator == 0) {
            res.correlation = 0.0;
            res.rangeDescription = "Zero variance in one or both selected columns.";
            return res;
        }

        double r = num / denominator;
        if (r > 1.0) r = 1.0;
        if (r < -1.0) r = -1.0;

        res.correlation = r;

        if (r >= 0.7) {
            res.rangeDescription = "Strong positive linear correlation (r >= 0.70)";
        } else if (r >= 0.3) {
            res.rangeDescription = "Moderate positive linear correlation (0.30 <= r < 0.70)";
        } else if (r > -0.3) {
            res.rangeDescription = "Weak or no linear correlation (-0.30 < r < 0.30)";
        } else if (r > -0.7) {
            res.rangeDescription = "Moderate negative linear correlation (-0.70 < r <= -0.30)";
        } else {
            res.rangeDescription = "Strong negative linear correlation (r <= -0.70)";
        }

        return res;
    }
}
