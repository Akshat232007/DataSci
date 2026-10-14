package com.datasci;

import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Database {

    private static volatile boolean initialized = false;

    public static Connection getConnection() throws SQLException, ClassNotFoundException {
        String url = System.getenv("DB_URL");
        if (url == null || url.trim().isEmpty()) {
            url = System.getProperty("DB_URL");
        }

        String user = System.getenv("DB_USER");
        if (user == null || user.trim().isEmpty()) {
            user = System.getProperty("DB_USER");
        }

        String password = System.getenv("DB_PASSWORD");
        if (password == null) {
            password = System.getProperty("DB_PASSWORD");
        }

        // Safe fallback for local development if DB_URL is not set
        if (url == null || url.trim().isEmpty()) {
            url = "jdbc:mysql://localhost:3306/datasci?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
            if (user == null || user.trim().isEmpty()) {
                user = "root";
            }
            if (password == null) {
                password = "";
            }
        }

        // Ensure database points to 'datasci', not MySQL internal system DB 'sys'
        if (url.contains("/sys?")) {
            url = url.replace("/sys?", "/datasci?");
        } else if (url.endsWith("/sys")) {
            url = url.substring(0, url.length() - 4) + "/datasci";
        }

        // If connecting to TiDB Cloud and sslMode is not explicitly set, enforce SSL
        if (url.contains("tidbcloud.com") && !url.contains("sslMode")) {
            if (url.contains("?")) {
                url = url + "&sslMode=VERIFY_IDENTITY";
            } else {
                url = url + "?sslMode=VERIFY_IDENTITY";
            }
        }

        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(url, user, password);

        if (!initialized) {
            synchronized (Database.class) {
                if (!initialized) {
                    initializeDatabase(con);
                    initialized = true;
                }
            }
        }

        return con;
    }

    public static synchronized void initializeDatabase(Connection con) {
        try (Statement stmt = con.createStatement()) {
            // Create users table
            stmt.executeUpdate("CREATE TABLE IF NOT EXISTS users ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY, "
                    + "name VARCHAR(100) NOT NULL, "
                    + "email VARCHAR(150) NOT NULL UNIQUE, "
                    + "password VARCHAR(255) NOT NULL, "
                    + "role VARCHAR(20) NOT NULL DEFAULT 'USER', "
                    + "status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', "
                    + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
                    + ")");

            // Create history table
            stmt.executeUpdate("CREATE TABLE IF NOT EXISTS history ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY, "
                    + "user_id INT NOT NULL, "
                    + "operation VARCHAR(100) NOT NULL, "
                    + "details TEXT, "
                    + "date TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
                    + ")");

            // Create activity table with file_content for resilient cloud persistence
            stmt.executeUpdate("CREATE TABLE IF NOT EXISTS activity ("
                    + "id INT AUTO_INCREMENT PRIMARY KEY, "
                    + "user_id INT NOT NULL, "
                    + "file_name VARCHAR(255), "
                    + "file_path VARCHAR(500), "
                    + "row_count INT DEFAULT 0, "
                    + "col_count INT DEFAULT 0, "
                    + "operation VARCHAR(100) NOT NULL, "
                    + "file_content LONGTEXT, "
                    + "date TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
                    + ")");

            // Ensure file_content exists if table was created in an earlier migration
            try {
                stmt.executeUpdate("ALTER TABLE activity ADD COLUMN file_content LONGTEXT");
            } catch (Exception ignored) {}
        } catch (Exception e) {
            System.err.println("Database auto-init note: " + e.getMessage());
        }

        // Provision initial admin if no ADMIN exists
        try {
            String checkAdminSql = "SELECT COUNT(*) FROM users WHERE role = 'ADMIN'";
            boolean adminExists = false;
            try (PreparedStatement ps = con.prepareStatement(checkAdminSql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    adminExists = true;
                }
            }

            if (!adminExists) {
                String adminEmail = System.getenv("ADMIN_EMAIL");
                if (adminEmail == null || adminEmail.trim().isEmpty()) {
                    adminEmail = "admin@datasci.com";
                }
                String adminPass = System.getenv("ADMIN_PASSWORD");
                if (adminPass == null || adminPass.trim().isEmpty()) {
                    adminPass = "Admin@12345";
                }

                String insertAdminSql = "INSERT INTO users (name, email, password, role, status) VALUES (?, ?, ?, 'ADMIN', 'ACTIVE')";
                try (PreparedStatement ps = con.prepareStatement(insertAdminSql)) {
                    ps.setString(1, "Administrator");
                    ps.setString(2, adminEmail.trim().toLowerCase());
                    ps.setString(3, hashPassword(adminPass.trim()));
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) {
            System.err.println("Admin provisioning check note: " + e.getMessage());
        }
    }

    public static String hashPassword(String password) {
        if (password == null) {
            return "";
        }
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes(java.nio.charset.StandardCharsets.UTF_8));
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
            throw new RuntimeException("SHA-256 algorithm not available", e);
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
        logActivity(userId, fileName, filePath, rowCount, colCount, operation, null);
    }

    public static void logActivity(int userId, String fileName, String filePath, int rowCount, int colCount, String operation, String fileContent) {
        String query = "INSERT INTO activity (user_id, file_name, file_path, row_count, col_count, operation, file_content) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setString(2, fileName);
            ps.setString(3, filePath);
            ps.setInt(4, rowCount);
            ps.setInt(5, colCount);
            ps.setString(6, operation);
            ps.setString(7, fileContent);
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
        public String fileContent;
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
        String sql = "SELECT id, file_name, file_path, row_count, col_count, date, file_content FROM activity WHERE id = ? AND user_id = ?";
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
                    uf.fileContent = rs.getString("file_content");
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

    public static void updateFileContent(int id, int userId, String newPath, String newContent) {
        String sql = "UPDATE activity SET file_path = ?, file_content = ? WHERE id = ? AND user_id = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newPath);
            ps.setString(2, newContent);
            ps.setInt(3, id);
            ps.setInt(4, userId);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("Error updating file content: " + e.getMessage());
        }
    }
}
