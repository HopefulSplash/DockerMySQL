-- Insert test data into tblBooks
INSERT INTO tblBooks (isbn, title, author, publication_year, price, description)
VALUES
    ('978-0451526342', 'Fahrenheit 451', 'Ray Bradbury', 1953, 11.49, 'Dystopian novel'),
    ('978-0062561023', 'The Road', 'Cormac McCarthy', 2006, 13.99, 'Post-apocalyptic fiction'),
    ('978-1400032730', 'Animal Farm', 'George Orwell', 1945, 8.99, 'Political allegory'),
    ('978-0345391803', 'The Hitchhiker''s Guide to the Galaxy', 'Douglas Adams', 1979, 9.49, 'Science fiction comedy'),
    ('978-0062315021', 'The Lord of the Rings', 'J.R.R. Tolkien', 1954, 19.99, 'Epic fantasy'),
    ('978-0451526343', 'The Shining', 'Stephen King', 1977, 12.99, 'Horror novel'),
    ('978-0062561024', 'The Hunger Games', 'Suzanne Collins', 2008, 10.99, 'Young adult dystopian'),
    ('978-0316769174', 'The Catcher in the Rye', 'J.D. Salinger', 1951, 11.99, 'Coming-of-age novel'),
    ('978-0062315007', 'The Hobbit', 'J.R.R. Tolkien', 1937, 14.99, 'Fantasy adventure'),
    ('978-0060850524', 'The Alchemist', 'Paulo Coelho', 1988, 10.49, 'Philosophical novel');

-- Insert test data into tblAccounts
INSERT INTO tblAccounts (username, password_hash, full_name)
VALUES
    ('alice123', 'hashed_password1', 'Alice Johnson'),
    ('bob456', 'hashed_password2', 'Bob Smith'),
    ('carol789', 'hashed_password3', 'Carol Davis');

-- Insert test data into tblOrders
INSERT INTO tblOrders (user_id, checkout_date, required_checkin_date)
VALUES
    (1, '2023-09-23', '2023-10-05'),
    (2, '2023-09-24', '2023-10-06'),
    (3, '2023-09-25', '2023-10-07');

-- Insert test data into tblOrderDetails
INSERT INTO tblOrderDetails (order_id, book_id, quantity)
VALUES
    (1, 1, 2),
    (1, 2, 1),
    (2, 2, 3),
    (3, 3, 2);

-- Insert test data into tblAuditLogs
INSERT INTO tblAuditLogs (user_id, action, table_name, record_id)
VALUES
    (1, 'INSERT', 'tblBooks', 1),
    (2, 'UPDATE', 'tblAccounts', 2),
    (3, 'DELETE', 'tblOrders', 3);