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
    Map<String, Integer> missingMap = hasData ? ReadData.getMissingValueCounts(headers, rows) : null;
    int duplicateRows = hasData ? ReadData.getDuplicateRowCount(rows) : 0;
    List<List<String>> previewRows = hasData ? ReadData.getPreview(rows, 10) : null;

    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Upload Dataset — DataSci</title>
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
            <a href="upload.jsp" class="sidebar-link active">Upload Dataset</a>
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
        </div>

        <!-- Main Content -->
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
                <h2 style="font-size: 18px; font-weight: bold;">Upload CSV Dataset</h2>
                <p style="font-size: 12px; color: #666;">Upload a CSV file to parse headers, data rows, and summary information</p>
            </div>

            <!-- Upload Box -->
            <div class="box">
                <form action="Data?action=upload" method="POST" enctype="multipart/form-data">
                    <div class="form-group">
                        <label class="form-label" for="csvFile">Select CSV File (.csv)</label>
                        <input type="file" id="csvFile" name="csvFile" accept=".csv" class="form-control" required style="padding: 5px;">
                        <span style="font-size: 11px; color: #777; display: block; margin-top: 4px;">Only standard comma-delimited (.csv) files are supported.</span>
                    </div>
                    <button type="submit" class="btn btn-primary">Upload and Process CSV</button>
                    <% if (hasData) { %>
                        <a href="home.jsp" class="btn btn-secondary" style="margin-left: 8px;">Cancel</a>
                    <% } %>
                </form>
            </div>

            <% if (hasData) { %>
                <!-- Metadata Box -->
                <div class="box">
                    <div class="box-header">
                        <div>
                            <div class="box-title">Dataset Summary: <%= currentFileName %></div>
                        </div>
                        <a href="clean.jsp" class="btn btn-primary btn-sm">Proceed to Cleaning &rarr;</a>
                    </div>

                    <div class="stat-row">
                        <div class="stat-item stat-blue">
                            <div class="stat-item-label">Total Rows</div>
                            <div class="stat-item-val" style="color: #2563eb;"><%= totalRows %></div>
                        </div>
                        <div class="stat-item stat-green">
                            <div class="stat-item-label">Total Columns</div>
                            <div class="stat-item-val" style="color: #059669;"><%= totalCols %></div>
                        </div>
                        <div class="stat-item stat-amber">
                            <div class="stat-item-label">Numerical Columns</div>
                            <div class="stat-item-val" style="color: #d97706;"><%= numCols.size() %></div>
                        </div>
                        <div class="stat-item stat-red">
                            <div class="stat-item-label">Duplicate Rows</div>
                            <div class="stat-item-val" style="<%= duplicateRows > 0 ? "color: #dc2626;" : "color: #059669;" %>"><%= duplicateRows %></div>
                        </div>
                    </div>

                    <!-- Column Types & Missing Count -->
                    <div class="box-title" style="margin-bottom: 8px; font-size: 13px;">Column Classification &amp; Missing Counts</div>
                    <div class="table-responsive" style="margin-bottom: 16px;">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Column Name</th>
                                    <th>Data Type</th>
                                    <th>Missing Count</th>
                                    <th>Missing %</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                    for (int i = 0; i < headers.size(); i++) { 
                                        String col = headers.get(i);
                                        boolean isNum = numCols.contains(col);
                                        int missing = missingMap.getOrDefault(col, 0);
                                        double missingPct = totalRows > 0 ? (missing * 100.0 / totalRows) : 0;
                                %>
                                <tr>
                                    <td><%= (i + 1) %></td>
                                    <td><strong><%= col %></strong></td>
                                    <td>
                                        <% if (isNum) { %>
                                            <span class="badge badge-numeric">Numerical</span>
                                        <% } else { %>
                                            <span class="badge badge-cat">Categorical</span>
                                        <% } %>
                                    </td>
                                    <td style="<%= missing > 0 ? "color: #b06000; font-weight:bold;" : "" %>"><%= missing %></td>
                                    <td><%= String.format("%.1f%%", missingPct) %></td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>

                    <!-- Preview -->
                    <div class="box-title" style="margin-bottom: 8px; font-size: 13px;">Data Preview (First <%= previewRows.size() %> Rows)</div>
                    <div class="table-responsive">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <% for (String h : headers) { %>
                                        <th><%= h %></th>
                                    <% } %>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                    for (int r = 0; r < previewRows.size(); r++) { 
                                        List<String> row = previewRows.get(r);
                                %>
                                <tr>
                                    <td style="color: #888; font-size: 11px;"><%= (r + 1) %></td>
                                    <% 
                                        for (int c = 0; c < headers.size(); c++) { 
                                            String val = (c < row.size()) ? row.get(c) : "";
                                            boolean isMissing = ReadData.isValueMissing(val);
                                    %>
                                        <td style="<%= isMissing ? "background: #fff8e1; color: #b06000;" : "" %>">
                                            <%= isMissing ? "(missing)" : val %>
                                        </td>
                                    <% } %>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            <% } %>
        </div>
    </div>

</body>
</html>
