-- Creating the tables needed

CREATE TABLE carts (
cart_id serial PRIMARY KEY,
cart_name varchar(50),
location varchar(100),
status varchar(20) -- Active, Inactive
);

CREATE TABLE products (
product_id serial PRIMARY KEY,
product_name varchar(50),
price decimal(6,2),
description TEXT,
stock_level int
);

CREATE TABLE orders (
    order_id UUID PRIMARY KEY,
    customer_id UUID,  -- Optional if you want to track customers
    sale_timestamp TIMESTAMP,
    payment_method VARCHAR(20),  -- e.g., 'Cash', 'Card', 'E-wallet'
    cart_id INT REFERENCES carts(cart_id),
    location VARCHAR(100)
);

CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY,
    order_id UUID REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT DEFAULT 1,  -- Quantity of the product sold
    price DECIMAL(10, 2)
);

CREATE TABLE sales (
sale_id serial PRIMARY KEY,
cart_id INT REFERENCES carts(cart_id),
product_id INT REFERENCES products(product_id),
quantity int,
total_price decimal(10,2),
sale_timestamp timestamp DEFAULT current_timestamp,
payment_method varchar(20) -- cash, gopay, ovo, qris bank
);

CREATE TABLE inventory (
inventory_id serial PRIMARY KEY,
cart_id int REFERENCES carts(cart_id),
product_id int REFERENCES products(product_id),
stock_level int,
last_restock timestamp
);

CREATE TABLE employees (
employee_id serial PRIMARY KEY,
employee_name varchar(100),
emp_call_name varchar(20),
cart_id int REFERENCES carts(cart_id),
ROLE varchar(20)
);

CREATE TABLE raw_materials (
raw_mat_id serial PRIMARY KEY,
material_name varchar(50), -- coffee beans, uht, milk, etc
unit varchar(20), -- kg, liter, etc
stock_level decimal(10,2) -- amount OF material IN stock
reorder_threshold decimal(10,2) -- LEVEL OF material TO be restocked
);

CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(100),
    contact_info TEXT
);

CREATE TABLE raw_materials_purchases (
purchase_id serial PRIMARY KEY,
raw_mat_id int REFERENCES raw_materials(raw_mat_id),
supplier_id int REFERENCES suppliers(supplier_id),
quantity decimal(10,2),
unit_price decimal(10,2),
purchase_date date,
total_cost AS (quantity * unit_price),
received_date date
);

CREATE TABLE raw_material_consumption (
    consumption_id SERIAL PRIMARY KEY,
    raw_material_id INT REFERENCES raw_materials(raw_material_id),
    cart_id INT REFERENCES carts(cart_id), -- Optional: Track consumption per cart
    quantity_used DECIMAL(10,2),
    consumption_date DATE
);

CREATE TABLE recipes (
    recipe_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id),
    raw_material_id INT REFERENCES raw_materials(raw_material_id),
    quantity_per_unit DECIMAL(10,2) -- Amount of raw material used per product unit
);

-- Daily production calculation
-- Example query to calculate raw material consumption for a product
SELECT r.raw_material_id, SUM(s.quantity * r.quantity_per_unit) AS total_consumed
FROM sales s
JOIN recipes r ON s.product_id = r.product_id
WHERE s.sale_timestamp::DATE = CURRENT_DATE
GROUP BY r.raw_material_id;

--Handling variying prices for raw mat purchases
-- Example to calculate the average price of coffee beans on hand
SELECT raw_material_id, SUM(quantity * unit_price) / SUM(quantity) AS avg_price
FROM raw_material_purchases
WHERE raw_material_id = 1 -- For coffee beans
GROUP BY raw_material_id;

-- Periodic raw material purchases
-- Example query to find materials below reorder threshold
SELECT material_name, stock_level, reorder_threshold
FROM raw_materials
WHERE stock_level < reorder_threshold;

-- Cost Per Cup
-- Example query to calculate production cost per product
SELECT p.product_name, SUM(r.quantity_per_unit * rp.unit_price) AS cost_per_unit
FROM recipes r
JOIN raw_material_purchases rp ON r.raw_material_id = rp.raw_material_id
JOIN products p ON r.product_id = p.product_id
WHERE rp.purchase_date <= CURRENT_DATE -- Ensure we use only received stock
GROUP BY p.product_name;


