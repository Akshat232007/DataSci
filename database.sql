-- ============================================================
-- DataSci — Visual Data Processing and Analysis Platform
-- Database Initialization Script
-- Compatible with: MySQL 8.0+, TiDB Cloud Serverless
-- Target Database: datasci
-- ============================================================

-- 1. Create and select the database
CREATE DATABASE IF NOT EXISTS datasci
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE datasci;

-- 2. Users Table
-- Stores credentials, role (ADMIN or USER), and status (ACTIVE or INACTIVE)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. History Table
-- Audit trail of major analytical actions and operations per user
CREATE TABLE IF NOT EXISTS history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    operation VARCHAR(100) NOT NULL,
    details TEXT,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_history_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 4. Activity Table
-- Stores metadata of uploaded datasets, operations, and row/column counts
CREATE TABLE IF NOT EXISTS activity (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    file_name VARCHAR(255),
    file_path VARCHAR(500),
    row_count INT DEFAULT 0,
    col_count INT DEFAULT 0,
    operation VARCHAR(100) NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_activity_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 5. Default Administrator Account (Safe / Idempotent Provisioning)
-- Email: admin@datasci.com
-- Initial Default Password: Admin@12345
-- SHA-256 Hash of Admin@12345: 6f2cb9dd8f4b65e24e1c3f3fa5bc57982349237f11abceacd45bbcb74d621c25
INSERT IGNORE INTO users (name, email, password, role, status)
VALUES (
    'Administrator',
    'admin@datasci.com',
    '6f2cb9dd8f4b65e24e1c3f3fa5bc57982349237f11abceacd45bbcb74d621c25',
    'ADMIN',
    'ACTIVE'
);

-- ============================================================
-- Verification Queries (Run manually to confirm setup):
-- SHOW TABLES;
-- SELECT id, name, email, role, status FROM users;
-- ============================================================
