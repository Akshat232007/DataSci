<%@page import="java.util.List"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.Connection"%>
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
    String activeFileName = (String) session.getAttribute("current_file_name");

    List<Database.UploadedFile> fileHistory = Database.getUploadedFiles(userId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>History — DataSci</title>
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
                    boolean isCurr = uf.fileName.equals(activeFileName);
            %>
                <a href="Data?action=openFile&id=<%= uf.id %>" class="sidebar-history-item <%= isCurr ? "current" : "" %>" title="Click to open <%= uf.fileName %>">
                    <%= isCurr ? "&bull; " : "" %><%= uf.fileName %>
                </a>
            <% } } %>

            <div class="sidebar-title">Workspace</div>
            <a href="ExportData" class="sidebar-link">Export CSV</a>
            <a href="history.jsp" class="sidebar-link active">History</a>
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

            <div class="box-header" style="border: none; margin-bottom: 8px;">
                <div>
                    <h2 style="font-size: 18px; font-weight: bold;">History and Saved Datasets</h2>
                    <p style="font-size: 12px; color: #666;">Switch between uploaded datasets or review operation history</p>
                </div>
                <div>
                    <a href="Data?action=newUpload" class="btn btn-primary">+ Upload New CSV File</a>
                </div>
            </div>

            <!-- Section 1: Uploaded Files History (Chat-style datasets) -->
            <div class="box">
                <div class="box-header">
                    <div>
                        <div class="box-title">Uploaded Datasets</div>
                        <div class="box-desc">Click "Open Dataset" to load and switch active workspace to that file</div>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Dataset File Name</th>
                                <th>Rows</th>
                                <th>Columns</th>
                                <th>Upload Timestamp</th>
                                <th>Status</th>
                                <th style="text-align: right;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                if (fileHistory.isEmpty()) {
                            %>
                                <tr>
                                    <td colspan="7" style="text-align: center; padding: 20px; color: #888;">
                                        No datasets uploaded yet. Click "+ Upload New CSV File" to get started.
                                    </td>
                                </tr>
                            <%
                                } else {
                                    int count = 1;
                                    for (Database.UploadedFile uf : fileHistory) {
                                        boolean isCurr = uf.fileName.equals(activeFileName);
                            %>
                                <tr style="<%= isCurr ? "background-color: #eef4fe;" : "" %>">
                                    <td><%= count++ %></td>
                                    <td>
                                        <a href="Data?action=openFile&id=<%= uf.id %>" style="font-weight: bold;">
                                            <%= uf.fileName %>
                                        </a>
                                    </td>
                                    <td><%= uf.rowCount %></td>
                                    <td><%= uf.colCount %></td>
                                    <td style="color: #666; font-size: 12px;"><%= uf.date %></td>
                                    <td>
                                        <% if (isCurr) { %>
                                            <span class="badge badge-active">Active in Workspace</span>
                                        <% } else { %>
                                            <span class="badge">Saved</span>
                                        <% } %>
                                    </td>
                                    <td style="text-align: right;">
                                        <a href="Data?action=openFile&id=<%= uf.id %>" class="btn btn-primary btn-sm">Open Dataset</a>
                                        <a href="Data?action=deleteFile&id=<%= uf.id %>" class="btn btn-danger btn-sm" onclick="return confirm('Remove this dataset from history?');">Delete</a>
                                    </td>
                                </tr>
                            <%
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Section 2: Operations Log -->
            <div class="box">
                <div class="box-header">
                    <div>
                        <div class="box-title">Operations Audit Log</div>
                        <div class="box-desc">Log of data processing, cleaning, and analysis actions performed</div>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Operation</th>
                                <th>Details</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                String sql = "SELECT id, operation, details, date FROM history WHERE user_id = ? ORDER BY id DESC";
                                boolean hasEntries = false;
                                try (Connection con = Database.getConnection();
                                     PreparedStatement ps = con.prepareStatement(sql)) {
                                    ps.setInt(1, userId);
                                    try (ResultSet rs = ps.executeQuery()) {
                                        int counter = 1;
                                        while (rs.next()) {
                                            hasEntries = true;
                                            String op = rs.getString("operation");
                                            String details = rs.getString("details");
                                            String date = rs.getString("date");
                            %>
                                <tr>
                                    <td><%= counter++ %></td>
                                    <td><span class="badge badge-numeric"><%= op %></span></td>
                                    <td><%= details != null ? details : "-" %></td>
                                    <td style="color: #666; font-size: 12px;"><%= date %></td>
                                </tr>
                            <%
                                        }
                                    }
                                } catch (Exception e) {
                            %>
                                <tr>
                                    <td colspan="4" style="color: #c5221f; text-align: center;">
                                        Error loading history: <%= e.getMessage() %>
                                    </td>
                                </tr>
                            <%
                                }
                                if (!hasEntries) {
                            %>
                                <tr>
                                    <td colspan="4" style="text-align: center; padding: 20px; color: #888;">
                                        No operations logged yet.
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

</body>
</html>
