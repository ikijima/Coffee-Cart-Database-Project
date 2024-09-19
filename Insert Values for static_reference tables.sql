-- Inserting values into the tables
INSERT INTO products (product_id, product_name, price, description, stock_level) VALUES
(001, 'Iced Americano',8000,'Espresso with iced water',60),
(002, 'Iced Latte',10000,'Espresso with milk and ice',60),
(003, 'Iced Vanilla Latte',13000,'Espresso with milk and vanilla syrup',60),
(004, 'Iced Hazelnut Latte',13000,'Espresso with milk and hazelnut syrup',60),
(005, 'Iced Aren Latte',13000,'Espresso with milk and brown sugar syrup',60);

-- Inserting values into raw_materials
insert into raw_materials (material_name, unit) VALUES
('Coffee beans','grams'),
('UHT milk','liters'),
('Condensed milk','liters'),
('Ice','kg'),
('Vanilla Syrup','ml'),
('Hazelnut Syrup','ml'),
('Aren syrup','ml');

-- Inserting values into recipes
INSERT INTO recipes (product_id, material_id, quantity_required) VALUES
(1, 1, 18.0),  -- Iced Americano uses 18g of coffee beans
(1, 4, 0.15),  -- Iced Americano uses 150g of ice
(2, 1, 18.0),  -- Iced Latte uses 18g of coffee beans
(2, 2, 0.25),  -- Iced Latte uses 250ml of UHT milk
(2, 4, 0.15),  -- Iced Latte uses 150g of ice
(3, 1, 18.0),  -- Iced Vanilla Latte uses 18g of coffee beans
(3, 2, 0.25),  -- Iced Vanilla Latte uses 250ml of UHT milk
(3, 5, 10.0),  -- Iced Vanilla Latte uses 10ml of vanilla syrup
(3, 4, 0.15),  -- Iced Vanilla Latte uses 150g of ice
(4, 1, 18.0),  -- Iced Hazelnut Latte uses 18g of coffee beans
(4, 2, 0.25),  -- Iced Hazelnut Latte uses 250ml of UHT milk
(4, 6, 10.0),  -- Iced Hazelnut Latte uses 10ml of hazelnut syrup
(4, 4, 0.15),  -- Iced Hazelnut Latte uses 150g of ice
(5, 1, 18.0),  -- Iced Aren Latte uses 18g of coffee beans
(5, 2, 0.25),  -- Iced Aren Latte uses 250ml of UHT milk
(5, 7, 10.0),  -- Iced Aren Latte uses 10ml of aren syrup
(5, 4, 0.15);  -- Iced Aren Latte uses 150g of ice

-- Inserting values into raw materials purchases
INSERT INTO raw_materials_purchases (material_id, purchase_date, supplier_name, quantity, price_per_unit) VALUES
(1, '2023-01-02', 'Coffee Beans Supplier A', 5000, 1000),   -- 5000g at 1000 IDR/g
(2, '2023-01-02', 'Dairy Supplier B', 100, 5000),           -- 100L at 5000 IDR/L
(4, '2023-01-02', 'Ice Supplier C', 50, 2000),              -- 50kg at 2000 IDR/kg
(5, '2023-01-03', 'Syrup Supplier D', 1000, 300),           -- 1000ml vanilla syrup at 300 IDR/ml
(6, '2023-01-03', 'Syrup Supplier D', 1000, 300),           -- 1000ml hazelnut syrup at 300 IDR/ml
(7, '2023-01-03', 'Syrup Supplier D', 1000, 350);           -- 1000ml aren syrup at 350 IDR/ml