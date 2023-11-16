CREATE DATABASE IF NOT EXISTS testingD;
CREATE DATABASE IF NOT EXISTS testingD;

-- Create a user if it doesn't already exist
CREATE USER IF NOT EXISTS 'testingU'@'%' IDENTIFIED BY 'dghRGElDbHUHU3chhuud';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'bIcrydeojr93Ux0BdmJH';

-- Grant privileges if the user exists
GRANT ALL PRIVILEGES ON testingD.* TO 'testingU'@'%';
GRANT ALL PRIVILEGES ON testingD.* TO 'root'@'%';

-- Use the database
USE testingD;

-- Create the table if it doesn't already exist
CREATE TABLE IF NOT EXISTS tblBooks (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    publication_year INT,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create the table if it doesn't already exist
CREATE TABLE IF NOT EXISTS tblAccounts (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create the table if it doesn't already exist
CREATE TABLE IF NOT EXISTS tblOrders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    checkout_date DATE,
    required_checkin_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES tblAccounts(user_id)
);

-- Create the table if it doesn't already exist
CREATE TABLE IF NOT EXISTS tblOrderDetails (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    book_id INT NOT NULL,
    quantity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES tblOrders(order_id),
    FOREIGN KEY (book_id) REFERENCES tblBooks(book_id)
);

-- Create the table if it doesn't already exist
CREATE TABLE IF NOT EXISTS tblAuditLogs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(255),
    table_name VARCHAR(255),
    record_id INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
