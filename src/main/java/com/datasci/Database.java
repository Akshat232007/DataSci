package com.datasci;

import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class Database {

    public static Connection getConnection() throws SQLException, ClassNotFoundException {
        String url = System.getenv("DB_URL");
        String user = System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD");

        if (url == null || url.trim().isEmpty()
                || user == null || user.trim().isEmpty()
                || password == null || password.isEmpty()) {
            throw new SQLException(
                    "Database configuration missing. Set DB_URL, DB_USER and DB_PASSWORD in the environment."
            );
        }

        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(url, user, password);
    }

    public static String hashPassword(String password) {
        if (password == null) {
            return "";
        }
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes("UTF-8"));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            return password;
        }
    }

    public static void logHistory(int userId, String operation, String details) {
        String query = "INSERT INTO history (user_id, operation, details) VALUES (?, ?, ?)";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setString(2, operation);
            ps.setString(3, details);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("Error logging history: " + e.getMessage());
        }
    }

    public static void logActivity(int userId, String fileName, String operation) {
        logActivity(userId, fileName, null, 0, 0, operation);
    }

    public static void logActivity(int userId, String fileName, String filePath, int rowCount, int colCount, String operation) {
        String query = "INSERT INTO activity (user_id, file_name, file_path, row_count, col_count, operation) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setString(2, fileName);
            ps.setString(3, filePath);
            ps.setInt(4, rowCount);
            ps.setInt(5, colCount);
            ps.setString(6, operation);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("Error logging activity: " + e.getMessage());
        }
    }

    public static class UploadedFile {
        public int id;
        public String fileName;
        public String filePath;
        public int rowCount;
        public int colCount;
        public String date;
    }

    public static java.util.List<UploadedFile> getUploadedFiles(int userId) {
        java.util.List<UploadedFile> list = new java.util.ArrayList<>();
        String sql = "SELECT id, file_name, file_path, row_count, col_count, date FROM activity WHERE user_id = ? AND file_path IS NOT NULL ORDER BY id DESC";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    UploadedFile uf = new UploadedFile();
                    uf.id = rs.getInt("id");
                    uf.fileName = rs.getString("file_name");
                    uf.filePath = rs.getString("file_path");
                    uf.rowCount = rs.getInt("row_count");
                    uf.colCount = rs.getInt("col_count");
                    uf.date = rs.getString("date");
                    list.add(uf);
                }
            }
        } catch (Exception e) {
            System.err.println("Error fetching files: " + e.getMessage());
        }
        return list;
    }

    public static UploadedFile getUploadedFileById(int id, int userId) {
        String sql = "SELECT id, file_name, file_path, row_count, col_count, date FROM activity WHERE id = ? AND user_id = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.setInt(2, userId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    UploadedFile uf = new UploadedFile();
                    uf.id = rs.getInt("id");
                    uf.fileName = rs.getString("file_name");
                    uf.filePath = rs.getString("file_path");
                    uf.rowCount = rs.getInt("row_count");
                    uf.colCount = rs.getInt("col_count");
                    uf.date = rs.getString("date");
                    return uf;
                }
            }
        } catch (Exception e) {
            System.err.println("Error fetching file by ID: " + e.getMessage());
        }
        return null;
    }

    public static void deleteUploadedFile(int id, int userId) {
        String sql = "DELETE FROM activity WHERE id = ? AND user_id = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.setInt(2, userId);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("Error deleting file record: " + e.getMessage());
        }
    }

    public static void updateFilePath(int id, int userId, String newPath) {
        String sql = "UPDATE activity SET file_path = ? WHERE id = ? AND user_id = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newPath);
            ps.setInt(2, id);
            ps.setInt(3, userId);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("Error updating file path: " + e.getMessage());
        }
    }
}
