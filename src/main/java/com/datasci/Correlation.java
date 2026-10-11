package com.datasci;

import java.util.ArrayList;
import java.util.List;

public class Correlation {

    public static class CorrelationResult {
        public String colX;
        public String colY;
        public int validCount;
        public int excludedCount;
        public boolean isDefined;
        public double correlation;
        public String rangeDescription;
        public List<Double> xPoints;
        public List<Double> yPoints;

        public CorrelationResult() {
            this.xPoints = new ArrayList<>();
            this.yPoints = new ArrayList<>();
            this.isDefined = false;
            this.correlation = Double.NaN;
        }
    }

    public static CorrelationResult calculate(List<String> headers, List<List<String>> dataRows, 
                                             String colX, String colY) {
        CorrelationResult res = new CorrelationResult();
        res.colX = colX;
        res.colY = colY;

        if (headers == null || dataRows == null || colX == null || colY == null) {
            res.rangeDescription = "Invalid dataset or columns specified.";
            return res;
        }

        int indexX = headers.indexOf(colX);
        int indexY = headers.indexOf(colY);

        if (indexX == -1 || indexY == -1) {
            res.rangeDescription = "One or both selected columns not found in dataset.";
            return res;
        }

        List<Double> xList = new ArrayList<>();
        List<Double> yList = new ArrayList<>();
        int excluded = 0;

        for (List<String> row : dataRows) {
            String valX = (indexX < row.size()) ? row.get(indexX) : null;
            String valY = (indexY < row.size()) ? row.get(indexY) : null;

            if (!ReadData.isValueMissing(valX) && !ReadData.isValueMissing(valY)
                    && ReadData.isNumeric(valX) && ReadData.isNumeric(valY)) {
                xList.add(Double.parseDouble(valX.trim()));
                yList.add(Double.parseDouble(valY.trim()));
            } else {
                excluded++;
            }
        }

        res.validCount = xList.size();
        res.excludedCount = excluded;
        res.xPoints = xList;
        res.yPoints = yList;

        if (xList.size() < 2) {
            res.isDefined = false;
            res.correlation = Double.NaN;
            res.rangeDescription = "Undefined: Insufficient data points to calculate correlation (at least 2 valid pairs required).";
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
        // Zero variance in X or Y means correlation is strictly undefined, NOT zero
        if (denominator <= 1e-12 || Double.isNaN(denominator)) {
            res.isDefined = false;
            res.correlation = Double.NaN;
            res.rangeDescription = "Undefined: Constant values / Zero variance in one or both selected columns.";
            return res;
        }

        double r = num / denominator;
        if (r > 1.0) r = 1.0;
        if (r < -1.0) r = -1.0;

        res.isDefined = true;
        res.correlation = r;

        if (r >= 0.7) {
            res.rangeDescription = "Strong positive linear association (r >= 0.70)";
        } else if (r >= 0.3) {
            res.rangeDescription = "Moderate positive linear association (0.30 <= r < 0.70)";
        } else if (r > -0.3) {
            res.rangeDescription = "Weak or negligible linear association (-0.30 < r < 0.30)";
        } else if (r > -0.7) {
            res.rangeDescription = "Moderate negative linear association (-0.70 < r <= -0.30)";
        } else {
            res.rangeDescription = "Strong negative linear association (r <= -0.70)";
        }

        return res;
    }
}
