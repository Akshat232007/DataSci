<%@page import="com.datasci.GroupData"%>
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
    List<String> catCols = hasData ? ReadData.getCategoricalColumns(headers, rows) : null;

    GroupData.GroupResult groupResult = (GroupData.GroupResult) session.getAttribute("group_result");
    String lastGroupCol = (String) session.getAttribute("last_group_col");
    String lastGroupOp = (String) session.getAttribute("last_group_op");
    String lastGroupNum = (String) session.getAttribute("last_group_num");

    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Group By — DataSci</title>
    <link rel="stylesheet" href="css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
            <a href="filter.jsp" class="sidebar-link">Filter and Sort</a>
            <a href="group.jsp" class="sidebar-link active">Group By</a>
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
                if (error != null) { 
            %>
                <div class="alert alert-danger"><%= error %></div>
            <% } %>

            <div style="margin-bottom: 16px;">
                <h2 style="font-size: 18px; font-weight: bold;">Group By Aggregation</h2>
                <p style="font-size: 12px; color: #666;">Aggregate numerical columns across categorical dimensions</p>
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">Please upload a CSV file to perform grouping.</p>
                    <a href="upload.jsp" class="btn btn-primary">Go to Upload</a>
                </div>
            <% } else { %>
                <!-- Configuration Box -->
                <div class="box">
                    <form action="Data" method="POST" style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)) 120px; gap: 12px; align-items: flex-end;">
                        <input type="hidden" name="action" value="group">

                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="groupCol">Group By Column</label>
                            <select id="groupCol" name="groupCol" class="form-control" required>
                                <% for (String c : headers) { %>
                                    <option value="<%= c %>" <%= c.equals(lastGroupCol) ? "selected" : "" %>>
                                        <%= c %> <%= catCols.contains(c) ? "(Cat)" : "(Num)" %>
                                    </option>
                                <% } %>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="operation">Aggregate Operation</label>
                            <select id="operation" name="operation" class="form-control" required>
                                <option value="COUNT" <%= "COUNT".equalsIgnoreCase(lastGroupOp) ? "selected" : "" %>>COUNT (Frequency)</option>
                                <option value="SUM" <%= "SUM".equalsIgnoreCase(lastGroupOp) ? "selected" : "" %>>SUM</option>
                                <option value="AVERAGE" <%= "AVERAGE".equalsIgnoreCase(lastGroupOp) ? "selected" : "" %>>AVERAGE</option>
                                <option value="MINIMUM" <%= "MINIMUM".equalsIgnoreCase(lastGroupOp) ? "selected" : "" %>>MINIMUM</option>
                                <option value="MAXIMUM" <%= "MAXIMUM".equalsIgnoreCase(lastGroupOp) ? "selected" : "" %>>MAXIMUM</option>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="numCol">Numerical Target Column</label>
                            <select id="numCol" name="numCol" class="form-control">
                                <option value="">-- None (For Count) --</option>
                                <% for (String c : numCols) { %>
                                    <option value="<%= c %>" <%= c.equals(lastGroupNum) ? "selected" : "" %>><%= c %></option>
                                <% } %>
                            </select>
                        </div>

                        <div>
                            <button type="submit" class="btn btn-primary" style="width: 100%;">Group Data</button>
                        </div>
                    </form>
                </div>

                <% if (groupResult != null && groupResult.resultRows != null) { %>
                    <!-- Table Box -->
                    <div class="box">
                        <div class="box-header">
                            <div class="box-title">
                                Result: <%= groupResult.resultHeaders.get(0) %> &amp; <%= groupResult.resultHeaders.get(1) %>
                                (<%= groupResult.resultRows.size() %> groups)
                            </div>
                        </div>

                        <div class="table-responsive" style="margin-bottom: 16px;">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th><%= groupResult.resultHeaders.get(0) %></th>
                                        <th><%= groupResult.resultHeaders.get(1) %></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% 
                                        for (int i = 0; i < groupResult.resultRows.size(); i++) { 
                                            List<String> r = groupResult.resultRows.get(i);
                                    %>
                                    <tr>
                                        <td><%= (i + 1) %></td>
                                        <td><strong><%= r.get(0) %></strong></td>
                                        <td><%= r.get(1) %></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>

                        <div class="box-title" style="margin-bottom: 8px; font-size: 13px;">Group Summary Chart</div>
                        <div style="height: 320px;">
                            <canvas id="groupChart"></canvas>
                        </div>
                    </div>

                    <script>
                        const groupLabels = [
                            <% for (int i = 0; i < groupResult.resultRows.size(); i++) { %>
                                "<%= groupResult.resultRows.get(i).get(0).replace("\"", "\\\"") %>"<%= (i < groupResult.resultRows.size() - 1 ? "," : "") %>
                            <% } %>
                        ];
                        const groupValues = [
                            <% for (int i = 0; i < groupResult.resultRows.size(); i++) { 
                                String val = groupResult.resultRows.get(i).get(1);
                                double parsed = 0;
                                try { parsed = Double.parseDouble(val); } catch (Exception e) {}
                            %>
                                <%= parsed %><%= (i < groupResult.resultRows.size() - 1 ? "," : "") %>
                            <% } %>
                        ];

                        const ctx = document.getElementById('groupChart').getContext('2d');
                        new Chart(ctx, {
                            type: 'bar',
                            data: {
                                labels: groupLabels,
                                datasets: [{
                                    label: "<%= groupResult.resultHeaders.get(1) %>",
                                    data: groupValues,
                                    backgroundColor: '#0b57d0'
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    y: { beginAtZero: true }
                                }
                            }
                        });
                    </script>
                <% } %>
            <% } %>
        </div>
    </div>

</body>
</html>
