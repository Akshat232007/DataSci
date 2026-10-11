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
    List<List<String>> previewRows = hasData ? ReadData.getPreview(rows, 10) : null;

    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Clean Data — DataSci</title>
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
            <a href="clean.jsp" class="sidebar-link active">Clean Data</a>
            <a href="stats.jsp" class="sidebar-link">Statistics</a>
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
                String msg = request.getParameter("msg");
                if (error != null) { 
            %>
                <div class="alert alert-danger"><%= error %></div>
            <% } %>

            <% if (msg != null) { %>
                <div class="alert alert-success"><%= msg %></div>
            <% } %>

            <div style="margin-bottom: 16px;">
                <h2 style="font-size: 18px; font-weight: bold;">Data Cleaning</h2>
                <p style="font-size: 12px; color: #666;">Handle missing values, remove duplicate records, or modify columns</p>
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">Please upload a CSV file to clean data.</p>
                    <a href="upload.jsp" class="btn btn-primary">Go to Upload</a>
                </div>
            <% } else { %>
                <!-- Overview Row -->
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
                        <div class="stat-item-label">Rows with Missing Values</div>
                        <div class="stat-item-val" style="<%= missingRows > 0 ? "color: #d97706;" : "color: #059669;" %>"><%= missingRows %></div>
                    </div>
                    <div class="stat-item stat-red">
                        <div class="stat-item-label">Duplicate Rows</div>
                        <div class="stat-item-val" style="<%= duplicateRows > 0 ? "color: #dc2626;" : "color: #059669;" %>"><%= duplicateRows %></div>
                    </div>
                </div>

                <!-- Cleaning Form Box -->
                <div class="box">
                    <div class="box-header">
                        <div class="box-title">Perform Cleaning Operation</div>
                    </div>

                    <form action="Data" method="POST" onsubmit="return confirm('Execute this data cleaning operation?');">
                        <input type="hidden" name="action" value="clean">

                        <div class="form-group">
                            <label class="form-label" for="cleanOp">Operation</label>
                            <select id="cleanOp" name="cleanOp" class="form-control" onchange="handleCleanOpChange();" required>
                                <option value="" disabled selected>-- Select an operation --</option>
                                <optgroup label="Missing Values Handling">
                                    <option value="removeMissing">1. Remove rows containing missing values</option>
                                    <option value="fillMean">2. Fill missing numerical values with Mean</option>
                                    <option value="fillMedian">3. Fill missing numerical values with Median</option>
                                    <option value="fillMode">4. Fill missing categorical values with Mode</option>
                                </optgroup>
                                <optgroup label="Deduplication">
                                    <option value="removeDuplicates">5. Remove duplicate rows</option>
                                </optgroup>
                                <optgroup label="Columns">
                                    <option value="renameColumn">6. Rename column</option>
                                    <option value="deleteColumn">7. Delete selected column</option>
                                </optgroup>
                            </select>
                        </div>

                        <!-- Column selector -->
                        <div class="form-group" id="colGroup" style="display: none;">
                            <label class="form-label" for="column">Target Column</label>
                            <select id="column" name="column" class="form-control">
                                <option value="" disabled selected>-- Select target column --</option>
                                <% for (String col : headers) { %>
                                    <option value="<%= col %>"><%= col %> (<%= numCols.contains(col) ? "Numeric" : "Categorical" %>)</option>
                                <% } %>
                            </select>
                        </div>

                        <!-- Rename input -->
                        <div class="form-group" id="renameGroup" style="display: none;">
                            <label class="form-label" for="newColumnName">New Column Name</label>
                            <input type="text" id="newColumnName" name="newColumnName" class="form-control" placeholder="Enter new column name">
                        </div>

                        <div style="margin-top: 15px;">
                            <button type="submit" class="btn btn-primary">Apply Cleaning</button>
                        </div>
                    </form>
                </div>

                <!-- Preview Box -->
                <div class="box">
                    <div class="box-header">
                        <div class="box-title">Working Dataset Preview (First <%= previewRows.size() %> Rows)</div>
                    </div>

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

    <script src="js/script.js"></script>
</body>
</html>
