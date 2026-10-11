<%@page import="com.datasci.Correlation"%>
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

    Correlation.CorrelationResult result = (Correlation.CorrelationResult) session.getAttribute("correlation_result");
    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Correlation — DataSci</title>
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
            <a href="group.jsp" class="sidebar-link">Group By</a>
            <a href="charts.jsp" class="sidebar-link">Visualize Charts</a>
            <a href="correlation.jsp" class="sidebar-link active">Correlation</a>

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
                <h2 style="font-size: 18px; font-weight: bold;">Pearson Correlation Analysis</h2>
                <p style="font-size: 12px; color: #666;">Measure the strength and direction of the linear relationship between two numerical variables</p>
            </div>

            <div class="warning-box">
                <strong>User Responsibility:</strong>
                Correlation is calculated for the two selected columns. DataSci does not determine whether the relationship is meaningful. The interpretation of the result is up to the user.
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">Please upload a CSV file to calculate correlation.</p>
                    <a href="upload.jsp" class="btn btn-primary">Go to Upload</a>
                </div>
            <% } else if (numCols == null || numCols.size() < 2) { %>
                <div class="alert alert-warning">
                    At least two numerical columns are required to calculate correlation.
                </div>
            <% } else { %>
                <!-- Form Box -->
                <div class="box">
                    <form action="Data" method="POST" style="display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) auto; gap: 12px; align-items: flex-end;">
                        <input type="hidden" name="action" value="correlation">

                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="colX">Variable X (Numerical)</label>
                            <select id="colX" name="colX" class="form-control" required>
                                <% for (int i = 0; i < numCols.size(); i++) { 
                                    String c = numCols.get(i);
                                    boolean sel = (result != null && c.equals(result.colX)) || (result == null && i == 0);
                                %>
                                    <option value="<%= c %>" <%= sel ? "selected" : "" %>><%= c %></option>
                                <% } %>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="colY">Variable Y (Numerical)</label>
                            <select id="colY" name="colY" class="form-control" required>
                                <% for (int i = 0; i < numCols.size(); i++) { 
                                    String c = numCols.get(i);
                                    boolean sel = (result != null && c.equals(result.colY)) || (result == null && i == 1);
                                %>
                                    <option value="<%= c %>" <%= sel ? "selected" : "" %>><%= c %></option>
                                <% } %>
                            </select>
                        </div>

                        <div>
                            <button type="submit" class="btn btn-primary" style="white-space: nowrap;">Calculate Correlation</button>
                        </div>
                    </form>
                </div>

                <% if (result != null) { %>
                    <!-- Result Box -->
                    <div class="box">
                        <div class="box-header">
                            <div class="box-title">Correlation Result: <%= result.colX %> vs <%= result.colY %></div>
                            <span class="box-desc"><%= result.validCount %> valid pairs used &bull; <%= result.excludedCount %> invalid/missing pairs excluded</span>
                        </div>

                        <div class="stat-row">
                            <div class="stat-item <%= result.isDefined ? "stat-blue" : "stat-red" %>">
                                <div class="stat-item-label">Pearson r</div>
                                <div class="stat-item-val" style="<%= result.isDefined ? "color: #2563eb;" : "color: #dc2626;" %>">
                                    <%= result.isDefined ? String.format("%.4f", result.correlation) : "Undefined" %>
                                </div>
                                <div class="stat-item-sub"><%= result.isDefined ? "Range: -1.0 to +1.0" : "Non-computable" %></div>
                            </div>
                            <div class="stat-item stat-green" style="grid-column: span 2;">
                                <div class="stat-item-label">Interpretation</div>
                                <div class="stat-item-val" style="font-size: 14px; margin-top: 6px; color: #059669;"><%= result.rangeDescription %></div>
                                <div class="stat-item-sub">Mathematical linear pattern only</div>
                            </div>
                            <div class="stat-item stat-amber">
                                <div class="stat-item-label">Shared Variance (r²)</div>
                                <div class="stat-item-val" style="color: #d97706;">
                                    <%= result.isDefined ? String.format("%.4f", Math.pow(result.correlation, 2)) : "N/A" %>
                                </div>
                                <div class="stat-item-sub">
                                    <%= result.isDefined ? String.format("%.1f%%", Math.pow(result.correlation, 2) * 100) : "N/A" %>
                                </div>
                            </div>
                        </div>

                        <div class="alert alert-info" style="margin-top: 10px; margin-bottom: 14px;">
                            <strong>Statistical Association Note:</strong>
                            Pearson correlation evaluates linear association between two variables. <em>Correlation does not establish, prove, or imply cause and effect.</em>
                        </div>

                        <div class="box-title" style="margin-bottom: 8px; font-size: 13px;">Scatter Plot</div>
                        <div style="height: 360px;">
                            <canvas id="correlationScatter"></canvas>
                        </div>
                    </div>

                    <script>
                        // ========================================================
                        // STEP 1: PREPARE (X, Y) SCATTER DATA POINTS
                        // ========================================================
                        <% 
                            int totalPts = result.xPoints.size();
                            int step = Math.max(1, totalPts / 600);
                        %>
                        const correlationPoints = [
                            <% for (int i = 0; i < totalPts; i += step) { %>
                                { x: <%= result.xPoints.get(i) %>, y: <%= result.yPoints.get(i) %> }<%= (i + step < totalPts ? "," : "") %>
                            <% } %>
                        ];

                        // ========================================================
                        // STEP 2: DRAW SCATTER PLOT USING CHART.JS
                        // ========================================================
                        const canvasElement = document.getElementById('correlationScatter');
                        const ctx = canvasElement.getContext('2d');

                        new Chart(ctx, {
                            type: 'scatter',
                            data: {
                                datasets: [{
                                    label: '<%= result.colX %> vs <%= result.colY %> (<%= result.isDefined ? ("r = " + String.format("%.4f", result.correlation)) : "Undefined" %>)',
                                    data: correlationPoints,
                                    backgroundColor: '#2563eb'
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    x: { title: { display: true, text: '<%= result.colX %>' } },
                                    y: { title: { display: true, text: '<%= result.colY %>' } }
                                }
                            }
                        });
                    </script>
                <% } %>

                <!-- Matrix Box -->
                <div class="box">
                    <div class="box-header">
                        <div class="box-title">Correlation Matrix</div>
                    </div>

                    <div class="table-responsive">
                        <table class="table" style="text-align: center;">
                            <thead>
                                <tr>
                                    <th style="text-align: left;">Variable</th>
                                    <% for (String c : numCols) { %>
                                        <th><%= c %></th>
                                    <% } %>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                    for (String rCol : numCols) { 
                                %>
                                <tr>
                                    <td style="text-align: left;"><strong><%= rCol %></strong></td>
                                    <% 
                                        for (String cCol : numCols) { 
                                            if (rCol.equals(cCol)) {
                                    %>
                                        <td style="background-color: #f1f3f4; font-weight:bold;">1.000</td>
                                    <% 
                                            } else {
                                                Correlation.CorrelationResult pair = Correlation.calculate(headers, rows, rCol, cCol);
                                    %>
                                        <td>
                                            <%= pair.isDefined ? String.format("%.3f", pair.correlation) : "Undefined" %>
                                        </td>
                                    <%      }
                                        } 
                                    %>
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
