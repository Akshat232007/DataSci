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
import java.sql.ResultSet;

@WebServlet("/Login")
public class Login extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || password == null || email.trim().isEmpty() || password.trim().isEmpty()) {
            response.sendRedirect("login.jsp?error=Please enter both email and password");
            return;
        }

        email = email.trim().toLowerCase();
        String hashedPassword = Database.hashPassword(password.trim());

        try (Connection con = Database.getConnection()) {
            String sql = "SELECT id, name, email, password, role, status FROM users WHERE email = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String dbPassword = rs.getString("password");
                        String status = rs.getString("status");
                        String role = rs.getString("role");
                        int id = rs.getInt("id");
                        String name = rs.getString("name");

                        if (!dbPassword.equals(hashedPassword)) {
                            response.sendRedirect("login.jsp?error=Invalid email or password");
                            return;
                        }

                        if (!"ACTIVE".equalsIgnoreCase(status)) {
                            response.sendRedirect("login.jsp?error=Your account is inactive. Please contact administrator.");
                            return;
                        }

                        // Rotate session ID to prevent session fixation attacks
                        request.changeSessionId();
                        HttpSession session = request.getSession(true);

                        // Clear any previous unauthenticated session data
                        session.removeAttribute("dataset_headers");
                        session.removeAttribute("dataset_rows");
                        session.removeAttribute("current_file_path");
                        session.removeAttribute("current_file_name");
                        session.removeAttribute("active_file_id");
                        session.removeAttribute("filtered_rows");
                        session.removeAttribute("filter_info");
                        session.removeAttribute("correlation_result");
                        session.removeAttribute("encoded_rows");
                        session.removeAttribute("encoded_headers");

                        session.setAttribute("user_id", id);
                        session.setAttribute("user_name", name);
                        session.setAttribute("user_email", email);
                        session.setAttribute("user_role", role);

                        Database.logHistory(id, "Logged In", "User successfully authenticated");

                        if ("ADMIN".equalsIgnoreCase(role)) {
                            response.sendRedirect("admin.jsp");
                        } else {
                            response.sendRedirect("home.jsp");
                        }
                    } else {
                        response.sendRedirect("login.jsp?error=Invalid email or password");
                    }
                }
            }
        } catch (Exception e) {
            response.sendRedirect("login.jsp?error=Database connection failed. Please ensure MySQL is running.");
        }
    }
}
