<%@page import="com.datasci.OneHotEncoding"%>
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
    List<String> catCols = hasData ? ReadData.getCategoricalColumns(headers, rows) : null;

    OneHotEncoding.EncodingResult encodedResult = (OneHotEncoding.EncodingResult) session.getAttribute("encoded_result");
    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>One-Hot Encoding — DataSci</title>
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
            <a href="onehot.jsp" class="sidebar-link active">One-Hot Encoding</a>
            <a href="stats.jsp" class="sidebar-link">Statistics</a>
            <a href="filter.jsp" class="sidebar-link">Filter and Sort</a>
            <a href="group.jsp" class="sidebar-link">Group By</a>
            <a href="charts.jsp" class="sidebar-link">Visualize Charts</a>
            <a href="correlation.jsp" class="sidebar-link">Correlation</a>

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
                <h2 style="font-size: 18px; font-weight: bold;">One-Hot Encoding (Optional Transformation)</h2>
                <p style="font-size: 12px; color: #666;">Convert categorical variables into binary (0 or 1) indicator columns for numerical processing</p>
            </div>

            <!-- Beginner-friendly Guide Box -->
            <div class="box" style="background-color: #f8fafc; border-left: 4px solid #2563eb;">
                <div class="box-title" style="margin-bottom: 6px;">How One-Hot Encoding Works</div>
                <p style="font-size: 12.5px; color: #334155; line-height: 1.5; margin-bottom: 8px;">
                    Many algorithms and statistical methods require numbers rather than text strings. One-Hot Encoding replaces a categorical column with separate binary columns for each unique category.
                </p>
                <ul style="font-size: 12px; color: #475569; margin-left: 20px; line-height: 1.6;">
                    <li><strong>Present Category:</strong> Assigned a value of <code>1</code>.</li>
                    <li><strong>Absent Category:</strong> Assigned a value of <code>0</code>.</li>
                    <li><strong>Missing Value Policy:</strong> When a row has an empty or missing value, all indicator columns for that variable receive <code>0</code>.</li>
                    <li><strong>Safety Guard:</strong> Columns with more than 50 distinct categories are rejected to protect performance and avoid table explosion.</li>
                </ul>
            </div>

            <% if (!hasData) { %>
                <div class="box" style="text-align: center; padding: 40px 20px;">
                    <h3 style="font-size: 16px; margin-bottom: 8px;">No Dataset Loaded</h3>
                    <p style="font-size: 13px; color: #666; margin-bottom: 16px;">Please upload a CSV file to apply One-Hot Encoding.</p>
                    <a href="upload.jsp" class="btn btn-primary">Go to Upload</a>
                </div>
            <% } else if (catCols == null || catCols.isEmpty()) { %>
                <div class="alert alert-warning">
                    No categorical columns were detected in the active dataset. One-Hot Encoding requires text or categorical variables.
                </div>
            <% } else { %>
                <!-- Selection Box -->
                <div class="box">
                    <div class="box-header">
                        <div class="box-title">Select Categorical Columns to Encode</div>
                    </div>

                    <form action="Data" method="POST">
                        <input type="hidden" name="action" value="encode">

                        <p style="font-size: 12px; color: #64748b; margin-bottom: 12px;">
                            Select one or more categorical columns from the dataset below:
                        </p>

                        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px; margin-bottom: 16px;">
                            <% for (String c : catCols) { %>
                                <label style="display: flex; align-items: center; gap: 8px; font-size: 13px; background: #f8fafc; padding: 8px 12px; border: 1px solid #e2e8f0; border-radius: 4px; cursor: pointer;">
                                    <input type="checkbox" name="columns" value="<%= c %>">
                                    <span><strong><%= c %></strong></span>
                                </label>
                            <% } %>
                        </div>

                        <button type="submit" class="btn btn-primary">Generate One-Hot Encoded Columns</button>
                    </form>
                </div>

                <% if (encodedResult != null && encodedResult.success) { %>
                    <!-- Transformed Dataset Results Box -->
                    <div class="box">
                        <div class="box-header">
                            <div>
                                <div class="box-title">Transformed Dataset Preview</div>
                                <div class="box-desc"><%= encodedResult.message %></div>
                            </div>
                            <div style="display: flex; gap: 8px;">
                                <form action="Data" method="POST" style="display: inline;">
                                    <input type="hidden" name="action" value="saveEncoded">
                                    <button type="submit" class="btn btn-success btn-sm">Apply as Active Dataset</button>
                                </form>
                            </div>
                        </div>

                        <div class="stat-row">
                            <div class="stat-item stat-blue">
                                <div class="stat-item-label">Original Columns</div>
                                <div class="stat-item-val" style="color: #2563eb;"><%= encodedResult.originalColumnCount %></div>
                            </div>
                            <div class="stat-item stat-green">
                                <div class="stat-item-label">Encoded Columns</div>
                                <div class="stat-item-val" style="color: #059669;"><%= encodedResult.encodedColumnCount %></div>
                            </div>
                            <div class="stat-item stat-amber" style="grid-column: span 2;">
                                <div class="stat-item-label">Generated Indicator Columns</div>
                                <div class="stat-item-val" style="color: #d97706;"><%= encodedResult.newlyGeneratedColumns.size() %></div>
                                <div class="stat-item-sub"><%= String.join(", ", encodedResult.newlyGeneratedColumns) %></div>
                            </div>
                        </div>

                        <!-- Preview Table -->
                        <% 
                            List<List<String>> previewRows = ReadData.getPreview(encodedResult.encodedRows, 10);
                        %>
                        <div class="box-title" style="margin-bottom: 8px; font-size: 13px;">Encoded Data Preview (First <%= previewRows.size() %> Rows)</div>
                        <div class="table-responsive">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <% for (String h : encodedResult.encodedHeaders) { 
                                            boolean isNew = encodedResult.newlyGeneratedColumns.contains(h);
                                        %>
                                            <th style="<%= isNew ? "background-color: #dbeafe; color: #1e40af;" : "" %>">
                                                <%= h %> <%= isNew ? "★" : "" %>
                                            </th>
                                        <% } %>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (int r = 0; r < previewRows.size(); r++) { 
                                        List<String> row = previewRows.get(r);
                                    %>
                                    <tr>
                                        <td style="color: #888; font-size: 11px;"><%= (r + 1) %></td>
                                        <% for (int c = 0; c < encodedResult.encodedHeaders.size(); c++) { 
                                            String val = (c < row.size()) ? row.get(c) : "";
                                            boolean isNew = encodedResult.newlyGeneratedColumns.contains(encodedResult.encodedHeaders.get(c));
                                        %>
                                            <td style="<%= isNew ? "font-weight: 600; color: #1d4ed8;" : "" %>">
                                                <%= val %>
                                            </td>
                                        <% } %>
                                    </tr>
                                    <% } %>
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
