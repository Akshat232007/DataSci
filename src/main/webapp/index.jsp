<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("user_id") != null) {
        response.sendRedirect("home.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>DataSci — Visual Data Processing and Analysis Platform</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

    <div class="navbar">
        <div class="nav-brand">
            DataSci Platform
        </div>
        <div class="nav-menu">
            <a href="login.jsp" class="btn btn-secondary btn-sm">Login</a>
            <a href="register.jsp" class="btn btn-primary btn-sm">Register</a>
        </div>
    </div>

    <!-- Hero -->
    <div class="hero">
        <div class="hero-motto">"DataSci calculates. The user interprets."</div>
        <h1 class="hero-title">Visual Data Processing &amp; Analysis</h1>
        <p class="hero-subtitle">Upload and analyze your dataset without writing code. Clean missing values, calculate statistics, filter, group, visualize, compute correlation, and perform linear regression.</p>
        <div>
            <a href="register.jsp" class="btn btn-primary" style="padding: 8px 16px;">Create Account</a>
            <a href="login.jsp" class="btn btn-secondary" style="padding: 8px 16px; margin-left: 8px;">Sign In</a>
        </div>
    </div>

    <!-- Feature Section -->
    <div class="features-section">
        <div class="grid-3">
            <div class="feature-item">
                <h3>CSV Upload</h3>
                <p>Upload comma-separated files to inspect total rows, columns, data types, and missing value counts.</p>
            </div>
            <div class="feature-item">
                <h3>Data Cleaning</h3>
                <p>Remove missing rows, impute values with mean, median, or mode, eliminate duplicate rows, and modify columns.</p>
            </div>
            <div class="feature-item">
                <h3>Descriptive Statistics</h3>
                <p>Calculate count, sum, mean, median, mode, minimum, maximum, range, variance, and standard deviation.</p>
            </div>
            <div class="feature-item">
                <h3>Filter, Sort &amp; Group</h3>
                <p>Filter numerical columns with comparison operators, order ascending/descending, and group by categorical variables.</p>
            </div>
            <div class="feature-item">
                <h3>Data Visualization</h3>
                <p>Generate interactive bar charts, line charts, pie charts, histograms, and scatter plots using Chart.js.</p>
            </div>
            <div class="feature-item">
                <h3>Correlation &amp; Regression</h3>
                <p>Compute Pearson correlation coefficient (r) and ordinary least squares linear regression (y = mx + c).</p>
            </div>
        </div>
    </div>

</body>
</html>
