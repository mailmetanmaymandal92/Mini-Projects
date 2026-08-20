-- ============================================================
--   SQL MINI PROJECT --
--   Database: Retail
--   Tables: customers, products, orders, order_items,
--           payments, product_reviews
-- ============================================================

CREATE DATABASE Retail;

USE Retail;

CREATE TABLE customers (
customer_id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(100) NOT NULL,
email VARCHAR(100) NOT NULL UNIQUE,
phone VARCHAR(15),
created_at DATETIME DEFAULT CURRENT_TIMESTAMP);

CREATE TABLE products (
product_id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(100) NOT NULL,
category VARCHAR(50) NOT NULL,
price DECIMAL(10,2) NOT NULL,
stock_quantity INT NOT NULL DEFAULT 0,
added_on DATETIME DEFAULT CURRENT_TIMESTAMP);


CREATE TABLE orders (
order_id INT PRIMARY KEY AUTO_INCREMENT,
customer_id INT,
order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
status VARCHAR(20) DEFAULT 'Pending',
total_amount DECIMAL(10,2),
FOREIGN KEY (customer_id) REFERENCES customers(customer_id));

CREATE TABLE order_items (
order_item_id INT PRIMARY KEY AUTO_INCREMENT,
order_id INT,
product_id INT,
quantity INT NOT NULL CHECK (quantity > 0),
item_price DECIMAL(10,2) NOT NULL,
FOREIGN KEY (order_id) REFERENCES orders(order_id),
FOREIGN KEY (product_id) REFERENCES products(product_id)

);

CREATE TABLE payments (
payment_id INT PRIMARY KEY AUTO_INCREMENT,
order_id INT,
payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
amount_paid DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0),
method VARCHAR(20) NOT NULL,
FOREIGN KEY (order_id) REFERENCES orders(order_id)

);

CREATE TABLE product_reviews (
review_id INT PRIMARY KEY AUTO_INCREMENT,
product_id INT,
customer_id INT,
rating INT NOT NULL,
review_text TEXT,
review_date DATETIME DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (product_id) REFERENCES products(product_id),
FOREIGN KEY (customer_id) REFERENCES customers(customer_id));

##-- Project Queries --##

-- Level 1: Basics

#1. Retrieve customer names and emails for email marketing
SELECT name, email FROM customers;

#2. View complete product catalogue with all available details
SELECT * FROM products;

#3. List all unique product categories
SELECT DISTINCT category FROM products;

#4. Show all products priced above ₹1,000
SELECT * FROM products WHERE price > 1000;

#5. Display products within a mid-range price bracket (₹2,000 to ₹5,000)
SELECT * FROM products WHERE price BETWEEN 2000 AND 5000;

#6. Fetch data for specific customer IDs (e.g., from loyalty program list)
SELECT * FROM customers WHERE customer_id IN (1, 5, 10);

#7. Identify customers whose names start with the letter ‘A’
SELECT name FROM customers WHERE name LIKE 'A%';

#8. List electronics products priced under ₹3,000
SELECT * FROM products
WHERE category = 'Electronics' AND price < 3000;

#9. Display product names and prices in descending order of price
SELECT name, price FROM products ORDER BY price DESC;

#10. Display product names and prices, sorted by price and then by name
SELECT name, price FROM products ORDER BY price DESC , name ASC;

-- Level 2: Filtering and Formatting

#1. Retrieve orders where customer information is missing (possibly due to data migration or deletion)

SELECT * FROM orders WHERE customer_id IS NULL;

#2. Display customer names and emails using column aliases for frontend readability

SELECT name AS "Customer Name", email AS "Email Address" FROM customers;

#3. Calculate total value per item ordered by multiplying quantity and item price

SELECT order_item_id,
       order_id,
       product_id,
       quantity,
       item_price,
       quantity * item_price AS total_item_value
FROM order_items;

#4. Combine customer name and phone number in a single column
SELECT CONCAT(name, ' - ', phone) AS customer_contact
FROM customers;

#5. Extract only the date part from order timestamps for date-wise reporting
SELECT order_id,
       customer_id,
       DATE(order_date) AS order_date_only,
       status,
       total_amount
FROM orders;


#6. List products that do not have any stock left

SELECT * FROM products WHERE stock_quantity = 0;

-- Level 3: Aggregations

#1. Count the total number of orders placed

SELECT COUNT(*) AS total_orders FROM orders;

#2. Calculate the total revenue collected from all orders

SELECT SUM(total_amount) AS total_revenue FROM orders;


#3. Calculate the average order value
SELECT ROUND(AVG(total_amount), 2) AS avg_order_value FROM orders;

#4. Count the number of customers who have placed at least one order
SELECT COUNT(DISTINCT customer_id) AS count_with_orders
FROM orders
WHERE customer_id IS NOT NULL;

#5. Find the number of orders placed by each customer

SELECT customer_id, COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
ORDER BY total_orders DESC;

#6. Find total sales amount made by each customer
SELECT customer_id,
       SUM(total_amount) AS total_sales
FROM orders
GROUP BY customer_id
ORDER BY total_sales DESC;

#7. List the number of products sold per category

SELECT p.category,
       COUNT(oi.order_item_id) AS products_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY products_sold DESC;

#8. Find the average item price per category

SELECT p.category,
       ROUND(AVG(p.price), 2) AS avg_price
FROM products p
GROUP BY p.category
ORDER BY avg_price DESC;

#9. Show number of orders placed per day

SELECT 
    DATE(order_date) AS order_day,
    COUNT(order_id) AS orders_count
FROM
    orders
GROUP BY DATE(order_date)
ORDER BY order_day;

#10. List total payments received per payment method

SELECT method,
       ROUND(SUM(amount_paid), 2) AS total_received
FROM payments
GROUP BY method
ORDER BY total_received DESC;

-- Level 4: Multi-Table Queries (JOINS)

#1. Retrieve order details along with the customer name (INNER JOIN)

SELECT o.order_id,
       c.name AS customer_name,
       o.order_date,
       o.status,
       o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;

#2. Get list of products that have been sold (INNER JOIN with order_items)

SELECT DISTINCT p.product_id,
       p.name AS product_name,
       p.category,
       p.price
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id;

#3. List all orders with their payment method (INNER JOIN)
SELECT o.order_id,
       o.order_date,
       o.total_amount,
       pay.method,
       pay.amount_paid
FROM orders o
INNER JOIN payments pay ON o.order_id = pay.order_id;

#4. Get list of customers and their orders (LEFT JOIN)

SELECT c.customer_id,
       c.name,
       o.order_id,
       o.order_date,
       o.total_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id;

#5. List all products along with order item quantity (LEFT JOIN)

SELECT 
    p.product_id,
    p.name AS product_name,
    p.category,
    IFNULL(SUM(oi.quantity), 0) AS total_quantity_sold
FROM products p
LEFT JOIN order_items oi 
    ON p.product_id = oi.product_id
GROUP BY 
    p.product_id, p.name, p.category
ORDER BY 
    total_quantity_sold DESC;

#6. List all payments including those with no matching orders (RIGHT JOIN)
SELECT pay.payment_id,
       pay.order_id,
       pay.payment_date,
       pay.amount_paid,
       pay.method,
       o.status AS order_status
FROM orders o
RIGHT JOIN payments pay ON o.order_id = pay.order_id;

#7. Combine data from three tables: customer, order, and payment
#Used for detailed transaction reports.

SELECT c.name AS customer_name,
       c.email,
       o.order_id,
       o.order_date,
       o.status,
       o.total_amount,
       pay.method AS payment_method,
       pay.amount_paid,
       pay.payment_date
FROM customers c
INNER JOIN orders o   ON c.customer_id = o.customer_id
INNER JOIN payments pay ON o.order_id  = pay.order_id
ORDER BY o.order_date DESC;


-- Level 5: Subqueries (Inner Queries)

#1. List all products priced above the average product price

SELECT *
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;

#2. Find customers who have placed at least one order

SELECT *
FROM customers
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = customers.customer_id
);

#3. Show orders whose total amount is above the average for that customer

SELECT o.*
FROM orders o
WHERE o.total_amount > (
    SELECT AVG(o2.total_amount)
    FROM orders o2
    WHERE o2.customer_id = o.customer_id
);

#4. Display customers who haven’t placed any orders

SELECT *
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);

#5. Show products that were never ordered

SELECT *
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.product_id
);


#6. Show highest value order per customer

SELECT customer_id,
       order_id,
       total_amount
FROM (
    SELECT customer_id,
           order_id,
           total_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY total_amount DESC
           ) AS rn
    FROM orders
) t
WHERE rn = 1
ORDER BY customer_id;

#7. Highest Order Per Customer (Including Names)

SELECT c.name AS customer_name,
       o.order_id,
       o.total_amount AS highest_order_amount
FROM (
    SELECT customer_id,
           order_id,
           total_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY total_amount DESC
           ) AS rn
    FROM orders
) o
JOIN customers c 
    ON o.customer_id = c.customer_id
WHERE o.rn = 1
ORDER BY o.total_amount DESC;

#Level 6: Set Operations

#1. List all customers who have either placed an order or written a product review

SELECT customer_id, name, email
FROM customers
WHERE customer_id IN (SELECT DISTINCT customer_id FROM orders
                      WHERE customer_id IS NOT NULL)
UNION
SELECT customer_id, name, email
FROM customers
WHERE customer_id IN (SELECT DISTINCT customer_id FROM product_reviews);

#2. List all customers who have placed an order as well as reviewed a product [intersect not supported]

SELECT DISTINCT c.customer_id, c.name, c.email
FROM customers c
WHERE c.customer_id IN (SELECT DISTINCT customer_id
                        FROM orders
                        WHERE customer_id IS NOT NULL)
  AND c.customer_id IN (SELECT DISTINCT customer_id
                        FROM product_reviews);