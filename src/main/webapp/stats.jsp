<%@page import="java.util.LinkedHashMap"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%@page import="com.datasci.ReadData"%>
<%@page import="com.datasci.Statistics"%>
<%@page import="com.datasci.Database"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp?error=Please login first");
        return;
    }

    String userName = (String) session.getAttribute("user_name");
    String userRole = (String) session.getAttribute("user_role");
    int userId = (int) session.getAttribute("user_id");
    String currentFileName = (String) session.getAttribute("current_file_name");

    @SuppressWarnings("unchecked")
    List<String> headers = (List<String>) session.getAttribute("dataset_headers");
    @SuppressWarnings("unchecked")
    List<List<String>> rows = (List<List<String>>) session.getAttribute("dataset_rows");

    boolean hasData = (headers != null && rows != null && !headers.isEmpty());
    List<String> numCols = hasData ? ReadData.getNumericalColumns(headers, rows) : null;

    String selectedCol = request.getParameter("column");
    if (selectedCol == null && numCols != null && !numCols.isEmpty()) {
        selectedCol = numCols.get(0);
    }

    Map<String, String> stats = null;
    if (hasData && selectedCol != null && numCols != null && numCols.contains(selectedCol)) {
        stats = Statistics.calculateAll(headers, rows, selectedCol);
    }

    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Statistics — DataSci</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

    <div class="navbar">
        <div class="nav-brand">
            <a href="home.jsp" style="text-decoration:none; color:inherit;">DataSci Platform</a>
        </div>
        <div class="nav-menu">
            <span class="nav-user">User: <%= userName %></span>
            <span class="badge-role <%= "ADMIN".equalsIgnoreCase(userRole) ? "role-admin" : "role-user" %>"><%= userRole %></span>
            <a href="Logout" class="btn btn-secondary btn-sm">Logout</a>
        </div>
    </div>

    <div class="app-container">
        <!-- Sidebar -->
        <div class="sidebar">
            <a href="Data?action=newUpload" class="btn-new-chat">+ Upload New CSV File</a>

            <div class="sidebar-title">Pipeline</div>
            <a href="home.jsp" class="sidebar-link">Dashboard</a>
            <a href="upload.jsp" class="sidebar-link">Upload Dataset</a>
            <a href="clean.jsp" class="sidebar-link">Clean Data</a>
            <a href="stats.jsp" class="sidebar-link active">Statistics</a>
            <a href="filter.jsp" class="sidebar-link">Filter and Sort</a>
            <a href="group.jsp" class="sidebar-link">Group By</a>
            <a href="charts.jsp" class="sidebar-link">Visualize Charts</a>
            <a href="correlation.jsp" class="sidebar-link">Correlation</a>
            <a href="onehot.jsp" class="sidebar-link">One-Hot Encoding</a>

            <div class="sidebar-title">Dataset History</div>
            <% if (fileHistory.isEmpty()) { %>
                <div style="font-size: 11px; color: #888; padding: 4px 8px;">No saved files</div>
            <% } else { 
                for (Database.UploadedFile uf : fileHistory) { 
                    boolean isCurr = uf.fileName.equals(currentFileName);
            %>
                <a href="Data?action=openFile&id=<%= uf.id %>" class="sidebar-history-item <%= isCurr ? "current" : "" %>" title="Click to open <%= uf.fileName %>">
                    <%= isCurr ? "&bull; " : "" %><%= uf.fileName %>
                </a>
            <% } } %>

            <div class="sidebar-title">Workspace</div>
            <a href="ExportData" class="sidebar-link">Export CSV</a>
            <a href="history.jsp" class="sidebar-link">History</a>
        </div>

        <!-- Main Content -->
        <div class="main-content">
            <% 
                String error = request.getParameter("error");
                if (error != null) { 
            %>
                <div class="alert alert-danger"><%= error %></div>
            <% } %>

            <div style="margin-bottom: 16px;">
                <h2 style="font-size: 18px; font-weight: bold;">Descriptive Statistics</h2>
                <p style="font-size: 12px; color: #666;">Compute 10 summary statistics for any numerical column</p>
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">Please upload a CSV file to calculate statistics.</p>
                    <a href="upload.jsp" class="btn btn-primary">Go to Upload</a>
                </div>
            <% } else if (numCols == null || numCols.isEmpty()) { %>
                <div class="alert alert-warning">
                    No numerical columns detected in the current dataset. Descriptive statistics require numerical columns.
                </div>
            <% } else { %>
                <!-- Column Select Box -->
                <div class="box">
                    <form action="Data" method="POST" style="display: flex; gap: 10px; align-items: flex-end;">
                        <input type="hidden" name="action" value="stats">
                        <div class="form-group" style="margin-bottom: 0; width: 300px;">
                            <label class="form-label" for="column">Select Numerical Column</label>
                            <select id="column" name="column" class="form-control" required>
                                <% for (String col : numCols) { %>
                                    <option value="<%= col %>" <%= col.equals(selectedCol) ? "selected" : "" %>><%= col %></option>
                                <% } %>
                            </select>
                        </div>
                        <button type="submit" class="btn btn-primary">Calculate Statistics</button>
                    </form>
                </div>

                <% if (stats != null && !stats.isEmpty()) { %>
                    <!-- Summary Metric Row -->
                    <div class="stat-row">
                        <div class="stat-item stat-blue">
                            <div class="stat-item-label">Count (N)</div>
                            <div class="stat-item-val" style="color: #2563eb;"><%= stats.get("Count") %></div>
                        </div>
                        <div class="stat-item stat-green">
                            <div class="stat-item-label">Mean</div>
                            <div class="stat-item-val" style="color: #059669;"><%= stats.get("Mean") %></div>
                        </div>
                        <div class="stat-item stat-amber">
                            <div class="stat-item-label">Median</div>
                            <div class="stat-item-val" style="color: #d97706;"><%= stats.get("Median") %></div>
                        </div>
                        <div class="stat-item stat-red">
                            <div class="stat-item-label">Std Deviation</div>
                            <div class="stat-item-val" style="color: #dc2626;"><%= stats.get("Standard Deviation") %></div>
                        </div>
                    </div>

                    <!-- 10 Metrics Table -->
                    <div class="box">
                        <div class="box-header">
                            <div class="box-title">Statistical Metrics for: <%= selectedCol %></div>
                        </div>

                        <div class="table-responsive">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>Metric</th>
                                        <th>Formula / Description</th>
                                        <th>Value</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr><td>Count</td><td>Number of valid numbers</td><td><strong><%= stats.get("Count") %></strong></td></tr>
                                    <tr><td>Sum</td><td>Sum of all values</td><td><%= stats.get("Sum") %></td></tr>
                                    <tr><td>Mean</td><td>Arithmetic average</td><td><strong><%= stats.get("Mean") %></strong></td></tr>
                                    <tr><td>Median</td><td>Middle value of sorted observations</td><td><strong><%= stats.get("Median") %></strong></td></tr>
                                    <tr><td>Mode</td><td>Most frequent value</td><td><%= stats.get("Mode") %></td></tr>
                                    <tr><td>Minimum</td><td>Lowest value</td><td><%= stats.get("Minimum") %></td></tr>
                                    <tr><td>Maximum</td><td>Highest value</td><td><%= stats.get("Maximum") %></td></tr>
                                    <tr><td>Range</td><td>Maximum - Minimum</td><td><%= stats.get("Range") %></td></tr>
                                    <tr><td>Variance</td><td>Sample variance (N - 1)</td><td><%= stats.get("Variance") %></td></tr>
                                    <tr><td>Standard Deviation</td><td>Square root of variance</td><td><strong><%= stats.get("Standard Deviation") %></strong></td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                <% } %>
            <% } %>
        </div>
    </div>

</body>
</html>
