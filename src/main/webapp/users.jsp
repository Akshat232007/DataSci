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
    int currentAdminId = (int) session.getAttribute("user_id");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>User Management — DataSci Admin</title>
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
            <a href="users.jsp" class="sidebar-link active">User Management</a>
            <a href="activity.jsp" class="sidebar-link">System Logs</a>

            <div class="sidebar-title">Platform Tools</div>
            <a href="home.jsp" class="sidebar-link">User Workspace</a>
            <a href="upload.jsp" class="sidebar-link">Upload Dataset</a>
            <a href="clean.jsp" class="sidebar-link">Clean Data</a>
            <a href="stats.jsp" class="sidebar-link">Statistics</a>
            <a href="charts.jsp" class="sidebar-link">Visualize Charts</a>
            <a href="correlation.jsp" class="sidebar-link">Correlation</a>
            <a href="onehot.jsp" class="sidebar-link">One-Hot Encoding</a>
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
                <h2 style="font-size: 18px; font-weight: bold;">User Management</h2>
                <p style="font-size: 12px; color: #666;">View registered accounts, modify access status, or delete accounts</p>
            </div>

            <div class="box">
                <div class="box-header">
                    <div class="box-title">Registered User Accounts</div>
                </div>

                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Full Name</th>
                                <th>Email</th>
                                <th>Role</th>
                                <th>Status</th>
                                <th>Created Date</th>
                                <th style="text-align: right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                String sql = "SELECT id, name, email, role, status, created_at FROM users ORDER BY id ASC";
                                try (Connection con = Database.getConnection();
                                     PreparedStatement ps = con.prepareStatement(sql);
                                     ResultSet rs = ps.executeQuery()) {
                                    while (rs.next()) {
                                        int uid = rs.getInt("id");
                                        String uname = rs.getString("name");
                                        String uemail = rs.getString("email");
                                        String urole = rs.getString("role");
                                        String ustatus = rs.getString("status");
                                        String udate = rs.getString("created_at");
                                        boolean isSelf = (uid == currentAdminId);
                                        boolean isAdmin = "ADMIN".equalsIgnoreCase(urole);
                            %>
                                <tr>
                                    <td><%= uid %></td>
                                    <td><strong><%= uname %></strong> <%= isSelf ? "(You)" : "" %></td>
                                    <td><%= uemail %></td>
                                    <td>
                                        <span class="badge-role <%= isAdmin ? "role-admin" : "role-user" %>">
                                            <%= urole %>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge <%= "ACTIVE".equalsIgnoreCase(ustatus) ? "badge-active" : "badge-inactive" %>">
                                            <%= ustatus %>
                                        </span>
                                    </td>
                                    <td style="color: #666; font-size: 12px;"><%= udate %></td>
                                    <td style="text-align: right; white-space: nowrap;">
                                        <% if (!isAdmin) { %>
                                            <% if ("ACTIVE".equalsIgnoreCase(ustatus)) { %>
                                                <a href="Admin?action=deactivate&id=<%= uid %>" class="btn btn-secondary btn-sm" onclick="return confirm('Deactivate account for <%= uname %>?');">Deactivate</a>
                                            <% } else { %>
                                                <a href="Admin?action=activate&id=<%= uid %>" class="btn btn-success btn-sm" onclick="return confirm('Activate account for <%= uname %>?');">Activate</a>
                                            <% } %>
                                            <a href="Admin?action=delete&id=<%= uid %>" class="btn btn-danger btn-sm" onclick="return confirm('Permanently delete account for <%= uname %>?');">Delete</a>
                                        <% } else { %>
                                            <span style="color: #888; font-size: 11px;">Protected Admin</span>
                                        <% } %>
                                    </td>
                                </tr>
                            <%
                                    }
                                } catch (Exception e) {
                            %>
                                <tr><td colspan="7" style="color: #c5221f;">Error loading users: <%= e.getMessage() %></td></tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

</body>
</html>
