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

    int totalUsers = 0;
    int activeUsers = 0;
    int inactiveUsers = 0;
    int totalActivities = 0;

    try (Connection con = Database.getConnection()) {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM users");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalUsers = rs.getInt(1);
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM users WHERE status = 'ACTIVE'");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) activeUsers = rs.getInt(1);
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM users WHERE status = 'INACTIVE'");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) inactiveUsers = rs.getInt(1);
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM activity");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalActivities = rs.getInt(1);
        }
    } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard — DataSci</title>
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
            <a href="admin.jsp" class="sidebar-link active">Dashboard Overview</a>
            <a href="users.jsp" class="sidebar-link">User Management</a>
            <a href="activity.jsp" class="sidebar-link">System Logs</a>

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
                <h2 style="font-size: 18px; font-weight: bold;">Administrator Dashboard</h2>
                <p style="font-size: 12px; color: #666;">System overview, user accounts, and platform activity records</p>
            </div>

            <!-- Stats Row -->
            <div class="stat-row">
                <div class="stat-item stat-blue">
                    <div class="stat-item-label">Total Users</div>
                    <div class="stat-item-val" style="color: #2563eb;"><%= totalUsers %></div>
                </div>
                <div class="stat-item stat-green">
                    <div class="stat-item-label">Active Users</div>
                    <div class="stat-item-val" style="color: #059669;"><%= activeUsers %></div>
                </div>
                <div class="stat-item stat-red">
                    <div class="stat-item-label">Inactive Users</div>
                    <div class="stat-item-val" style="<%= inactiveUsers > 0 ? "color: #dc2626;" : "color: #059669;" %>"><%= inactiveUsers %></div>
                </div>
                <div class="stat-item stat-amber">
                    <div class="stat-item-label">Dataset Activities</div>
                    <div class="stat-item-val" style="color: #d97706;"><%= totalActivities %></div>
                </div>
            </div>

            <div class="grid-2" style="margin-bottom: 16px;">
                <div class="box">
                    <div class="box-title">User Management</div>
                    <p style="font-size: 12px; color: #666; margin: 8px 0 12px 0;">
                        View user accounts, activate pending registrations, suspend inactive users, or remove records.
                    </p>
                    <a href="users.jsp" class="btn btn-primary btn-sm">Manage Users &rarr;</a>
                </div>

                <div class="box">
                    <div class="box-title">Dataset Activity Logs</div>
                    <p style="font-size: 12px; color: #666; margin: 8px 0 12px 0;">
                        View dataset uploads across all accounts, inspect file names, operations, and timestamps.
                    </p>
                    <a href="activity.jsp" class="btn btn-secondary btn-sm">View Activity Logs &rarr;</a>
                </div>
            </div>

            <!-- Recent Operations -->
            <div class="box">
                <div class="box-header">
                    <div class="box-title">Recent System Operations (Last 10)</div>
                </div>

                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>User</th>
                                <th>Email</th>
                                <th>Operation</th>
                                <th>Details</th>
                                <th>Date &amp; Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                String auditSql = "SELECT h.id, u.name, u.email, h.operation, h.details, h.date " +
                                                  "FROM history h JOIN users u ON h.user_id = u.id " +
                                                  "ORDER BY h.id DESC LIMIT 10";
                                boolean found = false;
                                try (Connection con = Database.getConnection();
                                     PreparedStatement ps = con.prepareStatement(auditSql);
                                     ResultSet rs = ps.executeQuery()) {
                                    int counter = 1;
                                    while (rs.next()) {
                                        found = true;
                            %>
                                <tr>
                                    <td><%= counter++ %></td>
                                    <td><strong><%= rs.getString("name") %></strong></td>
                                    <td><%= rs.getString("email") %></td>
                                    <td><span class="badge badge-numeric"><%= rs.getString("operation") %></span></td>
                                    <td><%= rs.getString("details") %></td>
                                    <td style="color: #666; font-size: 12px;"><%= rs.getString("date") %></td>
                                </tr>
                            <%
                                    }
                                } catch (Exception e) {
                            %>
                                <tr><td colspan="6" style="color: #c5221f;">Error loading operations: <%= e.getMessage() %></td></tr>
                            <% }
                               if (!found) { %>
                                <tr><td colspan="6" style="text-align: center; color: #888; padding: 20px;">No operations recorded.</td></tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

</body>
</html>
