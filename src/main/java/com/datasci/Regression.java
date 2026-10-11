package com.datasci;

import java.util.ArrayList;
import java.util.List;

public class Regression {

    public static class RegressionResult {
        public String colX;
        public String colY;
        public int validCount;
        public double slope;
        public double intercept;
        public String equation;
        public double rSquared;
        public List<Double> xPoints;
        public List<Double> yPoints;
        public List<Double> predictedPoints;
        public double minX;
        public double maxX;
        public double predAtMinX;
        public double predAtMaxX;

        public RegressionResult() {
            xPoints = new ArrayList<>();
            yPoints = new ArrayList<>();
            predictedPoints = new ArrayList<>();
        }

        public double predict(double x) {
            return (slope * x) + intercept;
        }
    }

    public static RegressionResult calculate(List<String> headers, List<List<String>> dataRows, 
                                            String colX, String colY) {
        RegressionResult res = new RegressionResult();
        res.colX = colX;
        res.colY = colY;

        int indexX = headers.indexOf(colX);
        int indexY = headers.indexOf(colY);

        if (indexX == -1 || indexY == -1 || dataRows == null) {
            res.equation = "Columns not found";
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
            res.equation = "Insufficient data points (at least 2 required).";
            return res;
        }

        int n = xList.size();
        double sumX = 0;
        double sumY = 0;

        double minX = xList.get(0);
        double maxX = xList.get(0);

        for (int i = 0; i < n; i++) {
            double x = xList.get(i);
            double y = yList.get(i);
            sumX += x;
            sumY += y;

            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
        }

        res.minX = minX;
        res.maxX = maxX;

        double meanX = sumX / n;
        double meanY = sumY / n;

        double num = 0;
        double den = 0;

        for (int i = 0; i < n; i++) {
            double dx = xList.get(i) - meanX;
            double dy = yList.get(i) - meanY;
            num += dx * dy;
            den += dx * dx;
        }

        if (den == 0) {
            res.slope = 0;
            res.intercept = meanY;
            res.equation = "y = " + String.format("%.4f", meanY) + " (vertical data / zero variance in X)";
            res.rSquared = 0;
            return res;
        }

        double m = num / den;
        double c = meanY - (m * meanX);

        res.slope = m;
        res.intercept = c;

        if (c >= 0) {
            res.equation = "y = " + String.format("%.4f", m) + "x + " + String.format("%.4f", c);
        } else {
            res.equation = "y = " + String.format("%.4f", m) + "x - " + String.format("%.4f", Math.abs(c));
        }

        double ssTot = 0;
        double ssRes = 0;

        for (int i = 0; i < n; i++) {
            double x = xList.get(i);
            double y = yList.get(i);
            double yHat = (m * x) + c;
            res.predictedPoints.add(yHat);

            ssRes += Math.pow(y - yHat, 2);
            ssTot += Math.pow(y - meanY, 2);
        }

        if (ssTot == 0) {
            res.rSquared = 1.0;
        } else {
            double r2 = 1.0 - (ssRes / ssTot);
            if (r2 < 0) r2 = 0;
            if (r2 > 1) r2 = 1;
            res.rSquared = r2;
        }

        res.predAtMinX = (m * minX) + c;
        res.predAtMaxX = (m * maxX) + c;

        return res;
    }
}
