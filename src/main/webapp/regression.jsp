<%@page import="com.datasci.Regression"%>
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

    Regression.RegressionResult reg = (Regression.RegressionResult) session.getAttribute("regression_result");
    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Linear Regression — DataSci</title>
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
                <h2 style="font-size: 18px; font-weight: bold;">Simple Linear Regression</h2>
                <p style="font-size: 12px; color: #666;">Model linear relationships between predictor X and response Y (y = mx + c)</p>
            </div>

            <div class="alert alert-warning" style="margin-bottom: 16px;">
                <strong>Feature Postponed:</strong> Linear Regression analysis has been postponed in this release. Please use <a href="correlation.jsp" style="font-weight: bold; text-decoration: underline;">Correlation (Pearson r)</a> or <a href="onehot.jsp" style="font-weight: bold; text-decoration: underline;">One-Hot Encoding</a> for statistical relationship analysis and data preprocessing.
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">Please upload a CSV file to fit a regression line.</p>
                    <a href="upload.jsp" class="btn btn-primary">Go to Upload</a>
                </div>
            <% } else if (numCols == null || numCols.size() < 2) { %>
                <div class="alert alert-warning">
                    At least two numerical columns are required for linear regression.
                </div>
            <% } else { %>
                <!-- Configuration Box -->
                <div class="box">
                    <form action="Data" method="POST" style="display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) auto; gap: 12px; align-items: flex-end;">
                        <input type="hidden" name="action" value="regression">

                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="colX">Independent Variable X (Predictor)</label>
                            <select id="colX" name="colX" class="form-control" required>
                                <% for (int i = 0; i < numCols.size(); i++) { 
                                    String c = numCols.get(i);
                                    boolean sel = (reg != null && c.equals(reg.colX)) || (reg == null && i == 0);
                                %>
                                    <option value="<%= c %>" <%= sel ? "selected" : "" %>><%= c %></option>
                                <% } %>
                            </select>
                        </div>

                        <div class="form-group" style="margin-bottom: 0;">
                            <label class="form-label" for="colY">Dependent Variable Y (Target)</label>
                            <select id="colY" name="colY" class="form-control" required>
                                <% for (int i = 0; i < numCols.size(); i++) { 
                                    String c = numCols.get(i);
                                    boolean sel = (reg != null && c.equals(reg.colY)) || (reg == null && i == 1);
                                %>
                                    <option value="<%= c %>" <%= sel ? "selected" : "" %>><%= c %></option>
                                <% } %>
                            </select>
                        </div>

                        <div>
                            <button type="submit" class="btn btn-primary" style="white-space: nowrap;">Fit Regression Line</button>
                        </div>
                    </form>
                </div>

                <% if (reg != null && reg.validCount >= 2) { %>
                    <!-- Model Summary Box -->
                    <div class="box">
                        <div class="box-header">
                            <div class="box-title">Model: X = <%= reg.colX %>, Y = <%= reg.colY %></div>
                            <span class="box-desc">Sample size: <%= reg.validCount %> pairs</span>
                        </div>

                        <!-- Equation Header -->
                        <div style="background-color: #f8fafc; border: 1px solid #cbd5e1; border-radius: 4px; padding: 12px; text-align: center; margin-bottom: 15px;">
                            <span style="font-size: 11px; text-transform: uppercase; color: #64748b; font-weight: bold;">Regression Equation</span><br>
                            <span style="font-size: 20px; font-weight: bold; color: #2563eb; font-family: monospace;"><%= reg.equation %></span>
                        </div>

                        <div class="stat-row">
                            <div class="stat-item stat-blue">
                                <div class="stat-item-label">Slope (m)</div>
                                <div class="stat-item-val" style="color: #2563eb;"><%= String.format("%.4f", reg.slope) %></div>
                                <div class="stat-item-sub">Change in Y per unit X</div>
                            </div>
                            <div class="stat-item stat-green">
                                <div class="stat-item-label">Intercept (c)</div>
                                <div class="stat-item-val" style="color: #059669;"><%= String.format("%.4f", reg.intercept) %></div>
                                <div class="stat-item-sub">Value of Y when X = 0</div>
                            </div>
                            <div class="stat-item stat-amber" style="grid-column: span 2;">
                                <div class="stat-item-label">R-Squared (R²)</div>
                                <div class="stat-item-val" style="color: #d97706;"><%= String.format("%.4f", reg.rSquared) %></div>
                                <div class="stat-item-sub"><%= String.format("%.1f%%", reg.rSquared * 100) %> explained variance</div>
                            </div>
                        </div>

                        <!-- Predictor Tool -->
                        <div class="box" style="background-color: #fafbfc; margin-bottom: 15px;">
                            <div class="box-title" style="font-size: 13px; margin-bottom: 6px;">Value Predictor Tool</div>
                            <p style="font-size: 12px; color: #666; margin-bottom: 8px;">
                                Enter any value for <%= reg.colX %> to calculate predicted <%= reg.colY %>:
                            </p>
                            <div style="display: flex; gap: 8px; align-items: center; max-width: 400px;">
                                <input type="number" step="any" id="predictX" class="form-control" placeholder="Enter X value">
                                <button type="button" class="btn btn-secondary" onclick="calculatePrediction(<%= reg.slope %>, <%= reg.intercept %>);">Calculate</button>
                            </div>
                            <div id="predictionResult" style="margin-top: 8px; font-size: 13px; color: #0b57d0; font-weight: bold;"></div>
                        </div>

                        <!-- Chart -->
                        <div class="box-title" style="margin-bottom: 8px; font-size: 13px;">Regression Scatter Plot &amp; Fitted Line</div>
                        <div style="height: 400px; margin-bottom: 15px;">
                            <canvas id="regressionChart"></canvas>
                        </div>

                        <!-- Observed vs Predicted Table -->
                        <div class="box-title" style="margin-bottom: 8px; font-size: 13px;">Observed vs Predicted (First 15 Observations)</div>
                        <div class="table-responsive">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>Actual <%= reg.colX %> (X)</th>
                                        <th>Actual <%= reg.colY %> (Y)</th>
                                        <th>Predicted Y</th>
                                        <th>Residual (y - ŷ)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% 
                                        for (int i = 0; i < reg.xPoints.size(); i++) { 
                                            double actX = reg.xPoints.get(i);
                                            double actY = reg.yPoints.get(i);
                                            double predY = reg.predictedPoints.get(i);
                                            double residual = actY - predY;
                                    %>
                                    <tr>
                                        <td><%= (i + 1) %></td>
                                        <td><%= actX %></td>
                                        <td><strong><%= actY %></strong></td>
                                        <td><%= String.format("%.2f", predY) %></td>
                                        <td style="<%= residual >= 0 ? "color: #137333;" : "color: #c5221f;" %>">
                                            <%= String.format("%+.2f", residual) %>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <script>
                        // ========================================================
                        // STEP 1: PREPARE ALL OBSERVED (X, Y) SCATTER DATA POINTS
                        // ========================================================
                        <% int ptCount = reg.xPoints.size(); %>
                        const observedPoints = [
                            <% for (int i = 0; i < ptCount; i++) { %>
                                { x: <%= reg.xPoints.get(i) %>, y: <%= reg.yPoints.get(i) %> }<%= (i < ptCount - 1 ? "," : "") %>
                            <% } %>
                        ];

                        // ========================================================
                        // STEP 2: PREPARE TWO END-POINTS FOR THE FITTED LINE
                        // ========================================================
                        const fittedLinePoints = [
                            { x: <%= reg.minX %>, y: <%= reg.predAtMinX %> },
                            { x: <%= reg.maxX %>, y: <%= reg.predAtMaxX %> }
                        ];

                        // ========================================================
                        // STEP 3: DRAW SCATTER POINTS & REGRESSION LINE
                        // ========================================================
                        const canvasElement = document.getElementById('regressionChart');
                        const ctx = canvasElement.getContext('2d');

                        new Chart(ctx, {
                            type: 'scatter',
                            data: {
                                datasets: [
                                    {
                                        label: 'Observed Data Points',
                                        data: observedPoints,
                                        backgroundColor: '#2563eb'
                                    },
                                    {
                                        label: 'Fitted Line: <%= reg.equation.replace("'", "\\'") %>',
                                        data: fittedLinePoints,
                                        type: 'line',
                                        borderColor: '#dc2626',
                                        borderWidth: 2,
                                        pointRadius: 0,
                                        fill: false
                                    }
                                ]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                scales: {
                                    x: { title: { display: true, text: '<%= reg.colX %>' } },
                                    y: { title: { display: true, text: '<%= reg.colY %>' } }
                                }
                            }
                        });
                    </script>
                <% } %>
            <% } %>
        </div>
    </div>

    <script src="js/script.js"></script>
</body>
</html>
