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
    List<String> numCols = hasData ? ReadData.getNumericalColumns(headers, rows) : null;

    @SuppressWarnings("unchecked")
    List<List<String>> displayRows = (List<List<String>>) session.getAttribute("filtered_rows");
    if (displayRows == null) {
        displayRows = rows;
    }

    String filterInfo = (String) session.getAttribute("filter_info");
    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Filter and Sort — DataSci</title>
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
            <a href="stats.jsp" class="sidebar-link">Statistics</a>
            <a href="filter.jsp" class="sidebar-link active">Filter and Sort</a>
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
                <h2 style="font-size: 18px; font-weight: bold;">Filter, Sort &amp; Slice</h2>
                <p style="font-size: 12px; color: #666;">Filter rows by numerical criteria, sort columns, or inspect Top and Bottom N records</p>
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">Please upload a CSV file to filter and sort.</p>
                    <a href="upload.jsp" class="btn btn-primary">Go to Upload</a>
                </div>
            <% } else { %>
                <!-- Controls Grid (Strict 3-column desktop layout) -->
                <div class="filter-grid">
                    <!-- 1. Filter -->
                    <div class="box">
                        <div class="box-title" style="margin-bottom: 10px;">1. Filter by Condition</div>
                        <form action="Data" method="POST">
                            <input type="hidden" name="action" value="filter">
                            <div class="form-group">
                                <label class="form-label" for="filterCol">Column</label>
                                <select id="filterCol" name="column" class="form-control" required>
                                    <% for (String c : numCols) { %>
                                        <option value="<%= c %>"><%= c %></option>
                                    <% } %>
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="operator">Operator</label>
                                <select id="operator" name="operator" class="form-control" required>
                                    <option value=">">&gt; (Greater Than)</option>
                                    <option value="<">&lt; (Less Than)</option>
                                    <option value="=">= (Equal To)</option>
                                    <option value="!=">!= (Not Equal To)</option>
                                    <option value=">=">&gt;= (Greater or Equal)</option>
                                    <option value="<=">&lt;= (Less or Equal)</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="targetValue">Value</label>
                                <input type="number" step="any" id="targetValue" name="targetValue" class="form-control" placeholder="e.g. 75.0" required>
                            </div>
                            <button type="submit" class="btn btn-primary" style="width: 100%;">Apply Filter</button>
                        </form>
                    </div>

                    <!-- 2. Sort -->
                    <div class="box">
                        <div class="box-title" style="margin-bottom: 10px;">2. Sort Records</div>
                        <form action="Data" method="POST">
                            <input type="hidden" name="action" value="sort">
                            <div class="form-group">
                                <label class="form-label" for="sortColumn">Column to Sort</label>
                                <select id="sortColumn" name="sortColumn" class="form-control" required>
                                    <% for (String c : headers) { %>
                                        <option value="<%= c %>"><%= c %> (<%= numCols.contains(c) ? "Num" : "Cat" %>)</option>
                                    <% } %>
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="sortOrder">Order</label>
                                <select id="sortOrder" name="sortOrder" class="form-control" required>
                                    <option value="asc">Ascending (Low to High / A to Z)</option>
                                    <option value="desc">Descending (High to Low / Z to A)</option>
                                </select>
                            </div>
                            <button type="submit" class="btn btn-secondary" style="width: 100%;">Sort Data</button>
                        </form>
                    </div>

                    <!-- 3. Top / Bottom N -->
                    <div class="box">
                        <div class="box-title" style="margin-bottom: 10px;">3. Top or Bottom N</div>
                        <form action="Data" method="POST">
                            <input type="hidden" name="action" value="topBottom">
                            <div class="form-group">
                                <label class="form-label" for="tbType">Type</label>
                                <select id="tbType" name="tbType" class="form-control" required>
                                    <option value="top">Top N Rows</option>
                                    <option value="bottom">Bottom N Rows</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="tbCount">Row Count (N)</label>
                                <input type="number" min="1" max="10000" id="tbCount" name="tbCount" class="form-control" value="10" required>
                            </div>
                            <button type="submit" class="btn btn-secondary" style="width: 100%;">Slice Rows</button>
                        </form>
                    </div>
                </div>

                <!-- Result Table Box -->
                <div class="box">
                    <div class="box-header">
                        <div>
                            <div class="box-title">
                                Result Table (<%= displayRows.size() %> total matching rows)
                            </div>
                            <div class="box-desc">
                                <% if (filterInfo != null) { %>
                                    <span style="color: #2563eb; font-weight: 600;">Active: <%= filterInfo %> &bull; </span>
                                <% } %>
                                Displaying all <%= displayRows.size() %> rows
                            </div>
                        </div>
                        <div>
                            <% if (session.getAttribute("filtered_rows") != null) { %>
                                <form action="Data" method="POST" style="display:inline;">
                                    <input type="hidden" name="action" value="saveFiltered">
                                    <button type="submit" class="btn btn-success btn-sm">Save View as Working Data</button>
                                </form>
                                <a href="filter.jsp" class="btn btn-secondary btn-sm" style="margin-left: 6px;">Clear Filter</a>
                            <% } %>
                        </div>
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
                                    if (displayRows.isEmpty()) {
                                %>
                                    <tr>
                                        <td colspan="<%= headers.size() + 1 %>" style="text-align: center; padding: 20px; color: #888;">
                                            No rows matched the criteria.
                                        </td>
                                    </tr>
                                <% 
                                    } else {
                                        for (int r = 0; r < displayRows.size(); r++) { 
                                            List<String> row = displayRows.get(r);
                                %>
                                <tr>
                                    <td style="color: #888; font-size: 11px;"><%= (r + 1) %></td>
                                    <% for (int c = 0; c < headers.size(); c++) { %>
                                        <td><%= (c < row.size()) ? row.get(c) : "" %></td>
                                    <% } %>
                                </tr>
                                <% 
                                        }
                                    }
                                %>
                            </tbody>
                        </table>
                    </div>
                </div>
            <% } %>
        </div>
    </div>

</body>
</html>
