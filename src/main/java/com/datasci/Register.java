package com.datasci;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/Register")
public class Register extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (name == null || email == null || password == null ||
            name.trim().isEmpty() || email.trim().isEmpty() || password.trim().isEmpty()) {
            response.sendRedirect("register.jsp?error=All fields are required");
            return;
        }

        name = name.trim();
        email = email.trim().toLowerCase();

        try (Connection con = Database.getConnection()) {
            // Check if email already exists
            String checkSql = "SELECT id FROM users WHERE email = ?";
            try (PreparedStatement checkPs = con.prepareStatement(checkSql)) {
                checkPs.setString(1, email);
                try (ResultSet rs = checkPs.executeQuery()) {
                    if (rs.next()) {
                        response.sendRedirect("register.jsp?error=Email is already registered");
                        return;
                    }
                }
            }

            // Insert new user
            String hashedPassword = Database.hashPassword(password.trim());
            String insertSql = "INSERT INTO users (name, email, password, role, status) VALUES (?, ?, ?, 'USER', 'ACTIVE')";
            try (PreparedStatement insertPs = con.prepareStatement(insertSql)) {
                insertPs.setString(1, name);
                insertPs.setString(2, email);
                insertPs.setString(3, hashedPassword);
                insertPs.executeUpdate();
            }

            response.sendRedirect("login.jsp?msg=Registration successful! Please login.");
        } catch (Exception e) {
            response.sendRedirect("register.jsp?error=Registration failed: " + e.getMessage());
        }
    }
}
