-- Inserting values into the tables
INSERT INTO products (product_id, product_name, price, description, stock_level) VALUES
(001, 'Iced Americano',8000,'Espresso with iced water',60),
(002, 'Iced Latte',10000,'Espresso with milk and ice',60),
(003, 'Iced Vanilla Latte',13000,'Espresso with milk and vanilla syrup',60),
(004, 'Iced Hazelnut Latte',13000,'Espresso with milk and hazelnut syrup',60),
(005, 'Iced Aren Latte',13000,'Espresso with milk and brown sugar syrup',60);

-- Inserting values into raw_materials
insert into raw_materials (raw_mat_id, material_name, unit, stock_level, reorder_threshold) VALUES
('RM001','Coffee beans','grams',50000, 16200 ),
('RM011','UHT milk','liters',500, 225),
('RM002','Ice','kg',270,135),
('RM021','Vanilla Syrup','ml', 27000, 9000),
('RM022','Hazelnut Syrup','ml',27000, 9000),
('RM023','Aren syrup','ml',27000,9000);

-- Inserting values into recipes
INSERT INTO recipes (product_id, material_id, quantity_required) VALUES
('RC001001', 001, 'RM001', 18.0),  -- Iced Americano uses 18g of coffee beans
('RC001004', 001, 'RM002', 0.15),  -- Iced Americano uses 150g of ice
('RC002001', 002, 'RM001', 18.0),  -- Iced Latte uses 18g of coffee beans
('RC002002', 002, 'RM011', 0.25),  -- Iced Latte uses 250ml of UHT milk
('RC002002', 002, 'RM004', 0.15),  -- Iced Latte uses 150g of ice
(003, 1, 18.0),  -- Iced Vanilla Latte uses 18g of coffee beans
(003, 2, 0.25),  -- Iced Vanilla Latte uses 250ml of UHT milk
(003, 5, 10.0),  -- Iced Vanilla Latte uses 10ml of vanilla syrup
(003, 4, 0.15),  -- Iced Vanilla Latte uses 150g of ice
(004, 1, 18.0),  -- Iced Hazelnut Latte uses 18g of coffee beans
(004, 2, 0.25),  -- Iced Hazelnut Latte uses 250ml of UHT milk
(004, 6, 10.0),  -- Iced Hazelnut Latte uses 10ml of hazelnut syrup
(004, 4, 0.15),  -- Iced Hazelnut Latte uses 150g of ice
(005, 1, 18.0),  -- Iced Aren Latte uses 18g of coffee beans
(005, 2, 0.25),  -- Iced Aren Latte uses 250ml of UHT milk
(005, 7, 10.0),  -- Iced Aren Latte uses 10ml of aren syrup
(005, 4, 0.15);  -- Iced Aren Latte uses 150g of ice

-- Inserting values into raw materials purchases
INSERT INTO raw_materials_purchases (material_id, purchase_date, supplier_name, quantity, price_per_unit) VALUES
(1, '2023-01-02', 'Coffee Beans Supplier A', 5000, 1000),   -- 5000g at 1000 IDR/g
(2, '2023-01-02', 'Dairy Supplier B', 100, 5000),           -- 100L at 5000 IDR/L
(4, '2023-01-02', 'Ice Supplier C', 50, 2000),              -- 50kg at 2000 IDR/kg
(5, '2023-01-03', 'Syrup Supplier D', 1000, 300),           -- 1000ml vanilla syrup at 300 IDR/ml
(6, '2023-01-03', 'Syrup Supplier D', 1000, 300),           -- 1000ml hazelnut syrup at 300 IDR/ml
(7, '2023-01-03', 'Syrup Supplier D', 1000, 350);           -- 1000ml aren syrup at 350 IDR/ml