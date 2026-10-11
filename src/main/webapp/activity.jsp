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

    String userRole = (String) session.getAttribute("user_role");
    if (!"ADMIN".equalsIgnoreCase(userRole)) {
        response.sendRedirect("home.jsp?error=Access denied. Administrator privileges required.");
        return;
    }

    String userName = (String) session.getAttribute("user_name");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dataset Activity Logs — DataSci Admin</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

    <div class="navbar">
        <div class="nav-brand">
            <a href="home.jsp" style="text-decoration:none; color:inherit;">DataSci Platform</a>
            <span class="badge-role role-admin" style="margin-left: 8px;">Admin Console</span>
        </div>
        <div class="nav-menu">
            <span class="nav-user">Admin: <%= userName %></span>
            <a href="home.jsp" class="btn btn-secondary btn-sm">User Workspace</a>
            <a href="Logout" class="btn btn-secondary btn-sm">Logout</a>
        </div>
    </div>

    <div class="app-container">
        <!-- Sidebar -->
        <div class="sidebar">
            <div class="sidebar-title">Admin Controls</div>
            <a href="admin.jsp" class="sidebar-link">Dashboard Overview</a>
            <a href="users.jsp" class="sidebar-link">User Management</a>
            <a href="activity.jsp" class="sidebar-link active">System Logs</a>

            <div class="sidebar-title">Platform Tools</div>
            <a href="home.jsp" class="sidebar-link">User Workspace</a>
            <a href="upload.jsp" class="sidebar-link">Upload Dataset</a>
            <a href="clean.jsp" class="sidebar-link">Clean Data</a>
            <a href="stats.jsp" class="sidebar-link">Statistics</a>
            <a href="charts.jsp" class="sidebar-link">Visualize Charts</a>
            <a href="correlation.jsp" class="sidebar-link">Correlation</a>
            <a href="regression.jsp" class="sidebar-link">Linear Regression</a>
            <a href="history.jsp" class="sidebar-link">History</a>
        </div>

        <!-- Main Content -->
        <div class="main-content">
            <div style="margin-bottom: 16px;">
                <h2 style="font-size: 18px; font-weight: bold;">Dataset Activity Logs</h2>
                <p style="font-size: 12px; color: #666;">Audit log of all uploaded datasets and file operations across the system</p>
            </div>

            <div class="box">
                <div class="box-header">
                    <div class="box-title">Dataset Activity Records</div>
                </div>

                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>User</th>
                                <th>Email</th>
                                <th>File Name</th>
                                <th>Operation</th>
                                <th>Date &amp; Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                String sql = "SELECT a.id, u.name, u.email, a.file_name, a.operation, a.date " +
                                             "FROM activity a JOIN users u ON a.user_id = u.id " +
                                             "ORDER BY a.id DESC";
                                boolean found = false;
                                try (Connection con = Database.getConnection();
                                     PreparedStatement ps = con.prepareStatement(sql);
                                     ResultSet rs = ps.executeQuery()) {
                                    int counter = 1;
                                    while (rs.next()) {
                                        found = true;
                            %>
                                <tr>
                                    <td><%= counter++ %></td>
                                    <td><strong><%= rs.getString("name") %></strong></td>
                                    <td><%= rs.getString("email") %></td>
                                    <td><%= rs.getString("file_name") %></td>
                                    <td><span class="badge badge-numeric"><%= rs.getString("operation") %></span></td>
                                    <td style="color: #666; font-size: 12px;"><%= rs.getString("date") %></td>
                                </tr>
                            <%
                                    }
                                } catch (Exception e) {
                            %>
                                <tr><td colspan="6" style="color: #c5221f;">Error loading activity logs: <%= e.getMessage() %></td></tr>
                            <% }
                               if (!found) { %>
                                <tr><td colspan="6" style="text-align: center; color: #888; padding: 20px;">No dataset activity recorded.</td></tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

</body>
</html>
