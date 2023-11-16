CREATE DATABASE IF NOT EXISTS <mysql_database>;
CREATE DATABASE IF NOT EXISTS <mysql_database>;

-- Create a user if it doesn't already exist
CREATE USER IF NOT EXISTS '<mysql_user>'@'%' IDENTIFIED BY '<mysql_password>';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '<mysql_root_password>';

-- Grant privileges if the user exists
GRANT ALL PRIVILEGES ON <mysql_database>.* TO '<mysql_user>'@'%';
GRANT ALL PRIVILEGES ON <mysql_database>.* TO 'root'@'%';

-- Use the database
USE <mysql_database>;

