package com.datasci;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebServlet("/Admin")
public class Admin extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        processAdminAction(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        processAdminAction(request, response);
    }

    private void processAdminAction(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user_id") == null) {
            response.sendRedirect("login.jsp?error=Please login first");
            return;
        }

        String role = (String) session.getAttribute("user_role");
        if (!"ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect("home.jsp?error=Access denied. Admin rights required.");
            return;
        }

        String action = request.getParameter("action");
        String idStr = request.getParameter("id");

        if (action == null || idStr == null) {
            response.sendRedirect("users.jsp");
            return;
        }

        try {
            int targetUserId = Integer.parseInt(idStr);
            int currentAdminId = (int) session.getAttribute("user_id");

            // Prevent admin from deleting or deactivating themselves
            if (targetUserId == currentAdminId) {
                response.sendRedirect("users.jsp?error=Cannot modify your own administrator account");
                return;
            }

            try (Connection con = Database.getConnection()) {
                if ("activate".equalsIgnoreCase(action)) {
                    String sql = "UPDATE users SET status = 'ACTIVE' WHERE id = ? AND role != 'ADMIN'";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setInt(1, targetUserId);
                        ps.executeUpdate();
                    }
                    Database.logHistory(currentAdminId, "Admin Action", "Activated user ID: " + targetUserId);
                    response.sendRedirect("users.jsp?msg=User activated successfully");
                } else if ("deactivate".equalsIgnoreCase(action)) {
                    String sql = "UPDATE users SET status = 'INACTIVE' WHERE id = ? AND role != 'ADMIN'";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setInt(1, targetUserId);
                        ps.executeUpdate();
                    }
                    Database.logHistory(currentAdminId, "Admin Action", "Deactivated user ID: " + targetUserId);
                    response.sendRedirect("users.jsp?msg=User deactivated successfully");
                } else if ("delete".equalsIgnoreCase(action)) {
                    String sql = "DELETE FROM users WHERE id = ? AND role != 'ADMIN'";
                    try (PreparedStatement ps = con.prepareStatement(sql)) {
                        ps.setInt(1, targetUserId);
                        ps.executeUpdate();
                    }
                    Database.logHistory(currentAdminId, "Admin Action", "Deleted user ID: " + targetUserId);
                    response.sendRedirect("users.jsp?msg=User deleted successfully");
                } else {
                    response.sendRedirect("users.jsp");
                }
            }
        } catch (Exception e) {
            response.sendRedirect("users.jsp?error=Error performing action: " + e.getMessage());
        }
    }
}
