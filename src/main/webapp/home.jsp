<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%@page import="com.datasci.ReadData"%>
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

    int totalRows = hasData ? rows.size() : 0;
    int totalCols = hasData ? headers.size() : 0;
    List<String> numCols = hasData ? ReadData.getNumericalColumns(headers, rows) : null;
    List<String> catCols = hasData ? ReadData.getCategoricalColumns(headers, rows) : null;
    int missingRows = hasData ? ReadData.getTotalMissingRows(rows, headers.size()) : 0;
    int duplicateRows = hasData ? ReadData.getDuplicateRowCount(rows) : 0;

    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dashboard — DataSci</title>
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
            <% if ("ADMIN".equalsIgnoreCase(userRole)) { %>
                <a href="admin.jsp" class="btn btn-secondary btn-sm">Admin Panel</a>
            <% } %>
            <a href="Logout" class="btn btn-secondary btn-sm">Logout</a>
        </div>
    </div>

    <div class="app-container">
        <!-- Sidebar with Chat-style Dataset Switcher -->
        <div class="sidebar">
            <a href="Data?action=newUpload" class="btn-new-chat">+ Upload New CSV File</a>

            <div class="sidebar-title">Pipeline</div>
            <a href="home.jsp" class="sidebar-link active">Dashboard</a>
            <a href="upload.jsp" class="sidebar-link">Upload Dataset</a>
            <a href="clean.jsp" class="sidebar-link">Clean Data</a>
            <a href="stats.jsp" class="sidebar-link">Statistics</a>
            <a href="filter.jsp" class="sidebar-link">Filter and Sort</a>
            <a href="group.jsp" class="sidebar-link">Group By</a>
            <a href="charts.jsp" class="sidebar-link">Visualize Charts</a>
            <a href="correlation.jsp" class="sidebar-link">Correlation</a>
            <a href="regression.jsp" class="sidebar-link">Linear Regression</a>

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

            <% if ("ADMIN".equalsIgnoreCase(userRole)) { %>
                <div class="sidebar-title">Admin</div>
                <a href="admin.jsp" class="sidebar-link">Admin Dashboard</a>
                <a href="users.jsp" class="sidebar-link">User Management</a>
                <a href="activity.jsp" class="sidebar-link">System Logs</a>
            <% } %>
        </div>

        <!-- Main Workspace -->
        <div class="main-content">
            <% 
                String error = request.getParameter("error");
                String msg = request.getParameter("msg");
                if (error != null) { 
            %>
                <div class="alert alert-danger"><%= error %></div>
            <% } %>

            <% if (msg != null) { %>
                <div class="alert alert-success"><%= msg %></div>
            <% } %>

            <div style="margin-bottom: 16px;">
                <h2 style="font-size: 18px; font-weight: bold;">Welcome, <%= userName %></h2>
                <p style="font-size: 12px; color: #666;">Data processing and analysis workspace</p>
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">
                        To begin processing and analyzing, please upload a CSV file or choose an existing dataset from your history.
                    </p>
                    <a href="upload.jsp" class="btn btn-primary">Upload CSV Dataset</a>
                    <% if (!fileHistory.isEmpty()) { %>
                        <a href="history.jsp" class="btn btn-secondary" style="margin-left: 8px;">Open from History</a>
                    <% } %>
                </div>
            <% } else { %>
                <!-- Active Dataset Box -->
                <div class="box">
                    <div class="box-header">
                        <div>
                            <div class="box-title">Active Dataset: <%= currentFileName %></div>
                            <div class="box-desc">Loaded in memory for operations</div>
                        </div>
                        <div>
                            <a href="Data?action=newUpload" class="btn btn-secondary btn-sm">+ Upload New File</a>
                            <a href="ExportData" class="btn btn-primary btn-sm">Export CSV</a>
                        </div>
                    </div>

                    <div class="stat-row">
                        <div class="stat-item stat-blue">
                            <div class="stat-item-label">Total Rows</div>
                            <div class="stat-item-val" style="color: #2563eb;"><%= totalRows %></div>
                            <div class="stat-item-sub">Records</div>
                        </div>
                        <div class="stat-item stat-green">
                            <div class="stat-item-label">Total Columns</div>
                            <div class="stat-item-val" style="color: #059669;"><%= totalCols %></div>
                            <div class="stat-item-sub"><%= numCols.size() %> Num, <%= catCols.size() %> Cat</div>
                        </div>
                        <div class="stat-item stat-amber">
                            <div class="stat-item-label">Missing Rows</div>
                            <div class="stat-item-val" style="<%= missingRows > 0 ? "color: #d97706;" : "color: #059669;" %>"><%= missingRows %></div>
                            <div class="stat-item-sub">Rows with empty values</div>
                        </div>
                        <div class="stat-item stat-red">
                            <div class="stat-item-label">Duplicate Rows</div>
                            <div class="stat-item-val" style="<%= duplicateRows > 0 ? "color: #dc2626;" : "color: #059669;" %>"><%= duplicateRows %></div>
                            <div class="stat-item-sub">Duplicate records</div>
                        </div>
                    </div>
                </div>

                <!-- Operations Navigation Grid -->
                <div class="box">
                    <div class="box-header">
                        <div class="box-title">Data Operations</div>
                    </div>

                    <div class="grid-3">
                        <div class="feature-item">
                            <h3><a href="clean.jsp">Data Cleaning</a></h3>
                            <p>Remove missing rows, impute with mean/median/mode, remove duplicates, or rename/delete columns.</p>
                        </div>
                        <div class="feature-item">
                            <h3><a href="stats.jsp">Statistics</a></h3>
                            <p>Calculate count, sum, mean, median, mode, minimum, maximum, range, variance, and standard deviation.</p>
                        </div>
                        <div class="feature-item">
                            <h3><a href="filter.jsp">Filter and Sort</a></h3>
                            <p>Filter numerical columns using comparison operators, sort ascending/descending, slice top or bottom N rows.</p>
                        </div>
                        <div class="feature-item">
                            <h3><a href="group.jsp">Group By</a></h3>
                            <p>Group records by categorical columns and calculate count, sum, average, min, or max.</p>
                        </div>
                        <div class="feature-item">
                            <h3><a href="charts.jsp">Visualize Charts</a></h3>
                            <p>Plot bar charts, line charts, pie charts, histograms, and scatter plots using Chart.js.</p>
                        </div>
                        <div class="feature-item">
                            <h3><a href="correlation.jsp">Correlation</a></h3>
                            <p>Compute Pearson correlation coefficient (r) between two numerical columns with scatter plots.</p>
                        </div>
                        <div class="feature-item">
                            <h3><a href="regression.jsp">Linear Regression</a></h3>
                            <p>Fit simple linear regression y = mx + c, compute slope, intercept, R², and live predictions.</p>
                        </div>
                        <div class="feature-item">
                            <h3><a href="history.jsp">History &amp; Datasets</a></h3>
                            <p>View uploaded datasets, open previously saved files, and review operation logs.</p>
                        </div>
                        <div class="feature-item">
                            <h3><a href="ExportData">Export CSV</a></h3>
                            <p>Download the current processed dataset to your computer as a standard CSV file.</p>
                        </div>
                    </div>
                </div>
            <% } %>
        </div>
    </div>

</body>
</html>
