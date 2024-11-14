# Designing database to handle recipes in a restaurant

To design a database for managing recipes in a restaurant, we’d need to capture details about the dishes and beverages, ingredients, recipe instructions, and their relationship with other key entities. Here’s a potential design breakdown:

### 1. Entities and Relationships

The database can be organized around the following main entities:

- **Dishes**: Stores information about each dish or beverage served in the restaurant.
- **Ingredients**: Holds details of each ingredient used across recipes.
- **Recipes**: Contains instructions for making each dish or beverage, along with their serving sizes and any special preparation notes.
- **Measurements**: Defines the measurement units used for ingredients (e.g., grams, cups, teaspoons).
- **Categories**: Allows classification of dishes into types (e.g., appetizer, main course, dessert, beverage).
- **Suppliers**: Optional table for managing suppliers who provide each ingredient, if tracking sourcing is important.

### 2. Database Schema Design

Here’s how each table could be structured:

#### `Dishes`

| Column         | Type     | Description                                |
| -------------- | -------- | ------------------------------------------ |
| `dish_id`      | INT (PK) | Unique identifier for each dish            |
| `name`         | VARCHAR  | Name of the dish                           |
| `category_id`  | INT (FK) | Links to `Categories` table                |
| `serving_size` | VARCHAR  | Default serving size (e.g., 1 bowl, 1 cup) |
| `price`        | DECIMAL  | Price for the dish                         |
| `is_active`    | BOOLEAN  | Whether the dish is currently offered      |

#### `Ingredients`

| Column          | Type     | Description                               |
| --------------- | -------- | ----------------------------------------- |
| `ingredient_id` | INT (PK) | Unique identifier for each ingredient     |
| `name`          | VARCHAR  | Name of the ingredient                    |
| `cost_per_unit` | DECIMAL  | Cost per unit of measure (e.g., per gram) |
| `supplier_id`   | INT (FK) | Links to `Suppliers` table (if needed)    |

#### `Recipes`

| Column         | Type     | Description                              |
| -------------- | -------- | ---------------------------------------- |
| `recipe_id`    | INT (PK) | Unique identifier for each recipe        |
| `dish_id`      | INT (FK) | Links to `Dishes` table                  |
| `instructions` | TEXT     | Step-by-step instructions for the recipe |
| `prep_time`    | INT      | Preparation time in minutes              |
| `cook_time`    | INT      | Cooking time in minutes                  |
| `total_time`   | INT      | Total time (prep + cook) in minutes      |

#### `Recipe_Ingredients`

This table represents the many-to-many relationship between recipes and ingredients.

| Column           | Type     | Description                         |
| ---------------- | -------- | ----------------------------------- |
| `recipe_id`      | INT (FK) | Links to `Recipes` table            |
| `ingredient_id`  | INT (FK) | Links to `Ingredients` table        |
| `quantity`       | DECIMAL  | Quantity of the ingredient required |
| `measurement_id` | INT (FK) | Links to `Measurements` table       |

#### `Measurements`

| Column           | Type     | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `measurement_id` | INT (PK) | Unique identifier for each unit         |
| `unit`           | VARCHAR  | Unit of measurement (e.g., grams, cups) |
| `abbreviation`   | VARCHAR  | Abbreviated unit (e.g., g, c, tsp)      |

#### `Categories`

| Column        | Type     | Description                            |
| ------------- | -------- | -------------------------------------- |
| `category_id` | INT (PK) | Unique identifier for each category    |
| `name`        | VARCHAR  | Name of the category (e.g., appetizer) |

#### `Suppliers` (Optional)

| Column         | Type     | Description                         |
| -------------- | -------- | ----------------------------------- |
| `supplier_id`  | INT (PK) | Unique identifier for each supplier |
| `name`         | VARCHAR  | Name of the supplier                |
| `contact_info` | VARCHAR  | Contact details for the supplier    |

### 3. Example Queries

Here are some useful queries that could be run on this schema:

- **Find all ingredients for a specific dish**:
  
  ```sql
  SELECT i.name, ri.quantity, m.unit 
  FROM Recipe_Ingredients ri
  JOIN Ingredients i ON ri.ingredient_id = i.ingredient_id
  JOIN Measurements m ON ri.measurement_id = m.measurement_id
  WHERE ri.recipe_id = (SELECT recipe_id FROM Dishes WHERE name = 'Dish_Name');
  ```

- **Get recipe instructions and ingredient details for a dish**:
  
  ```sql
  SELECT d.name AS Dish, r.instructions AS Instructions, i.name AS Ingredient, ri.quantity, m.unit 
  FROM Dishes d
  JOIN Recipes r ON d.dish_id = r.dish_id
  JOIN Recipe_Ingredients ri ON r.recipe_id = ri.recipe_id
  JOIN Ingredients i ON ri.ingredient_id = i.ingredient_id
  JOIN Measurements m ON ri.measurement_id = m.measurement_id
  WHERE d.name = 'Dish_Name';
  ```

This schema is adaptable for tracking ingredients, costs, and recipe details, providing a clear, scalable structure for managing recipes in a restaurant.

---

# Handling fluctuating ingredients prices

---

To handle fluctuating ingredient prices, we’d introduce a mechanism to record and track the price history for each ingredient. This would involve creating a separate table for ingredient prices with timestamps to capture when each price becomes effective. Here’s how we could update the database schema to support this.

### Updated Schema

#### New Table: `Ingredient_Prices`

This table will log price changes for each ingredient, allowing us to store multiple prices over time and fetch the latest price as needed.

| Column           | Type     | Description                             |
| ---------------- | -------- | --------------------------------------- |
| `price_id`       | INT (PK) | Unique identifier for each price record |
| `ingredient_id`  | INT (FK) | Links to `Ingredients` table            |
| `price`          | DECIMAL  | Price per unit of measure               |
| `effective_date` | DATE     | Date the price became effective         |
| `supplier_id`    | INT (FK) | Links to `Suppliers` table              |

#### Modified Table: `Ingredients`

Remove the `cost_per_unit` column from the `Ingredients` table, as price will now be managed in `Ingredient_Prices`.

### Example Queries Using `Ingredient_Prices`

1. **Get the Current Price for an Ingredient**  
   This query finds the latest price for an ingredient based on the `effective_date`.
   
   ```sql
   SELECT ip.price
   FROM Ingredient_Prices ip
   WHERE ip.ingredient_id = (SELECT ingredient_id FROM Ingredients WHERE name = 'Ingredient_Name')
   ORDER BY ip.effective_date DESC
   LIMIT 1;
   ```

2. **Fetch All Prices Over Time for an Ingredient**
   This query shows the price history for a specific ingredient, sorted by date.
   
   ```sql
   SELECT ip.price, ip.effective_date
   FROM Ingredient_Prices ip
   WHERE ip.ingredient_id = (SELECT ingredient_id FROM Ingredients WHERE name = 'Ingredient_Name')
   ORDER BY ip.effective_date;
   ```

3. **Calculate the Cost of a Dish Using the Latest Prices for All Ingredients**
   
   ```sql
   SELECT SUM(ri.quantity * ip.price) AS total_cost
   FROM Recipe_Ingredients ri
   JOIN Ingredient_Prices ip ON ri.ingredient_id = ip.ingredient_id
   WHERE ri.recipe_id = (SELECT recipe_id FROM Dishes WHERE name = 'Dish_Name')
   AND ip.effective_date = (
       SELECT MAX(effective_date)
       FROM Ingredient_Prices
       WHERE ingredient_id = ri.ingredient_id
   );
   ```

### Additional Considerations

- **Price Updates**: When prices change, you would insert a new record into the `Ingredient_Prices` table instead of updating an existing one. This approach preserves historical price data.

- **Seasonal Costing**: The `effective_date` field enables tracking costs over different time periods, which is useful for analyzing price fluctuations and adjusting menu pricing or profitability analysis.

This design will make it easy to reference current prices for recipes while preserving historical price data for each ingredient.

---

# Handling difference in prices if the restaurant handles ingredients in batches

---

If ingredients are stored in batches, and each batch can have a different price (due to price changes over time), we’ll need to add a `Batches` table to track each ingredient batch separately. Each batch would have its own quantity, purchase date, and price per unit. This setup enables the restaurant to maintain a precise inventory and handle price variations across batches, which can also aid in cost calculations based on batch-specific pricing.

Here’s how we can modify the schema to incorporate batches:

### Updated Schema with Batches

#### New Table: `Batches`

The `Batches` table will track individual batches of each ingredient. Each batch will have a unique price and quantity, along with details about when it was purchased and how much of it remains in stock.

| Column           | Type     | Description                            |
| ---------------- | -------- | -------------------------------------- |
| `batch_id`       | INT (PK) | Unique identifier for each batch       |
| `ingredient_id`  | INT (FK) | Links to `Ingredients` table           |
| `price_per_unit` | DECIMAL  | Price per unit for this specific batch |
| `quantity`       | DECIMAL  | Quantity purchased in this batch       |
| `remaining_qty`  | DECIMAL  | Remaining quantity available for use   |
| `purchase_date`  | DATE     | Date this batch was purchased          |
| `expiry_date`    | DATE     | Expiration date (if applicable)        |
| `supplier_id`    | INT (FK) | Links to `Suppliers` table             |

#### Modified Table: `Recipe_Ingredients`

Since we’ll now be tracking ingredient costs based on batches, we might not need to reference the `Ingredient_Prices` table directly when calculating costs, as we can use batch-specific prices instead.

### Example Queries

1. **Get the Latest Batch Price for an Ingredient**
   
   To fetch the most recent batch price for an ingredient, we can use the latest `purchase_date`:
   
   ```sql
   SELECT b.price_per_unit
   FROM Batches b
   WHERE b.ingredient_id = (SELECT ingredient_id FROM Ingredients WHERE name = 'Ingredient_Name')
   ORDER BY b.purchase_date DESC
   LIMIT 1;
   ```

2. **Calculate the Cost of a Dish Using Batch-Specific Pricing**
   
   To accurately cost a dish, you would use the most recently available batch price for each ingredient, while accounting for how much of each batch is used.
   
   ```sql
   SELECT SUM(ri.quantity * b.price_per_unit) AS total_cost
   FROM Recipe_Ingredients ri
   JOIN Batches b ON ri.ingredient_id = b.ingredient_id
   WHERE ri.recipe_id = (SELECT recipe_id FROM Dishes WHERE name = 'Dish_Name')
   AND b.remaining_qty >= ri.quantity
   ORDER BY b.purchase_date DESC
   LIMIT 1;
   ```

3. **Track Inventory Levels and Batch Usage**
   
   When ingredients are used in recipes, the `remaining_qty` in the `Batches` table would need to be decremented accordingly. If the required quantity exceeds the `remaining_qty` of a batch, multiple batches could be used to meet the need.

4. **Calculate Ingredient Cost by Weighted Average Across Multiple Batches**
   
   In cases where a dish uses quantities from multiple batches, you could calculate the weighted average cost based on quantities taken from each batch:
   
   ```sql
   SELECT SUM(ri.quantity * b.price_per_unit * (ri.quantity / b.remaining_qty)) AS weighted_cost
   FROM Recipe_Ingredients ri
   JOIN Batches b ON ri.ingredient_id = b.ingredient_id
   WHERE ri.recipe_id = (SELECT recipe_id FROM Dishes WHERE name = 'Dish_Name');
   ```

### Additional Considerations

- **FIFO or LIFO Usage**: If batches should be used in a particular order (e.g., First-In-First-Out), batch selection logic would need to account for this in queries.
- **Expiry Management**: Expired batches could be flagged in the `Batches` table by comparing the `expiry_date` with the current date.
- **Cost Analysis**: By storing all batch prices, the restaurant can perform historical cost analysis and calculate overall ingredient costs based on actual purchase data.

This structure allows the restaurant to manage both price fluctuations and batch-level inventory accurately.

---

# Final database structure and DDL

---

Certainly! Here’s a consolidated summary of the database structure, with DDL statements and example queries that cover managing recipes, tracking ingredient batches with fluctuating prices, and calculating costs effectively.

### Database Schema and Table Structures

#### 1. **Suppliers Table**

Stores information about suppliers of ingredients.

```sql
CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    name VARCHAR(100),
    contact_info VARCHAR(255)
);
```

#### 2. **Ingredients Table**

Holds basic information on each ingredient used in the restaurant's recipes.

```sql
CREATE TABLE Ingredients (
    ingredient_id INT PRIMARY KEY,
    name VARCHAR(100) UNIQUE,
    unit_of_measure VARCHAR(50)
);
```

#### 3. **Batches Table**

Tracks each batch of an ingredient, its purchase price, quantity, and supplier information.

```sql
CREATE TABLE Batches (
    batch_id INT PRIMARY KEY,
    ingredient_id INT REFERENCES Ingredients(ingredient_id),
    price_per_unit DECIMAL(10, 2),
    quantity DECIMAL(10, 2),
    remaining_qty DECIMAL(10, 2),
    purchase_date DATE,
    expiry_date DATE,
    supplier_id INT REFERENCES Suppliers(supplier_id)
);
```

#### 4. **Dishes Table**

Stores each dish served at the restaurant.

```sql
CREATE TABLE Dishes (
    dish_id INT PRIMARY KEY,
    name VARCHAR(100) UNIQUE,
    description TEXT
);
```

#### 5. **Recipe_Ingredients Table**

Links ingredients to dishes, specifying the quantity of each ingredient required for the recipe.

```sql
CREATE TABLE Recipe_Ingredients (
    recipe_ingredient_id INT PRIMARY KEY,
    dish_id INT REFERENCES Dishes(dish_id),
    ingredient_id INT REFERENCES Ingredients(ingredient_id),
    quantity DECIMAL(10, 2)
);
```

### Example Queries

#### 1. **Retrieve the Current Price for an Ingredient**

   Fetches the latest price per unit for a specific ingredient based on the most recent batch.

```sql
SELECT b.price_per_unit
FROM Batches b
WHERE b.ingredient_id = (SELECT ingredient_id FROM Ingredients WHERE name = 'Ingredient_Name')
ORDER BY b.purchase_date DESC
LIMIT 1;
```

#### 2. **Calculate Total Cost of a Dish Based on the Most Recent Batch Prices**

   This query calculates the total cost of a dish, using the latest batch prices for each ingredient in the recipe.

```sql
SELECT SUM(ri.quantity * b.price_per_unit) AS total_cost
FROM Recipe_Ingredients ri
JOIN Batches b ON ri.ingredient_id = b.ingredient_id
WHERE ri.dish_id = (SELECT dish_id FROM Dishes WHERE name = 'Dish_Name')
AND b.remaining_qty >= ri.quantity
ORDER BY b.purchase_date DESC
LIMIT 1;
```

#### 3. **Calculate Ingredient Cost by Weighted Average Across Multiple Batches**

   Calculates a weighted cost for an ingredient in a recipe when multiple batches are used to satisfy the required quantity.

```sql
SELECT SUM(ri.quantity * b.price_per_unit * (ri.quantity / b.remaining_qty)) AS weighted_cost
FROM Recipe_Ingredients ri
JOIN Batches b ON ri.ingredient_id = b.ingredient_id
WHERE ri.dish_id = (SELECT dish_id FROM Dishes WHERE name = 'Dish_Name');
```

#### 4. **Track Remaining Quantities in Batches After Usage**

   This query would be run after using ingredients in a recipe, updating `remaining_qty` in the `Batches` table accordingly.

```sql
UPDATE Batches
SET remaining_qty = remaining_qty - Used_Quantity
WHERE batch_id = (SELECT batch_id FROM Batches WHERE ingredient_id = 'Ingredient_ID' AND remaining_qty >= Used_Quantity
ORDER BY purchase_date ASC LIMIT 1);
```

### DDL Statements for Relationships

To enforce foreign key constraints, the following statements would link tables where appropriate:

```sql
ALTER TABLE Batches
ADD CONSTRAINT fk_ingredient
FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id);

ALTER TABLE Batches
ADD CONSTRAINT fk_supplier
FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id);

ALTER TABLE Recipe_Ingredients
ADD CONSTRAINT fk_dish
FOREIGN KEY (dish_id) REFERENCES Dishes(dish_id);

ALTER TABLE Recipe_Ingredients
ADD CONSTRAINT fk_ingredient
FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id);
```

### Summary of Features

This design allows for:

- **Tracking Ingredient Batches**: Each batch has its own price and quantity, capturing pricing fluctuations over time.
- **Detailed Recipe Costing**: Costs are calculated based on batch prices, enabling accurate cost analysis per dish.
- **Price History**: The schema stores historical pricing for each batch, enabling analysis of price trends over time.
- **Inventory Management**: `remaining_qty` allows for real-time inventory tracking, facilitating better stock management.

This database structure supports both operational needs (inventory and cost management) and strategic analysis (price fluctuations and supplier tracking), making it well-suited for restaurant management.

---

# Database design to handle menus (meals and beverages) of a coffee shop

---

For managing a coffee shop that sells both coffee-based beverages and meals, we need a database schema that handles menus, recipes, ingredients (inventory) in batches, and fluctuating prices. This design will incorporate tables for storing information about the ingredients, batches, suppliers, recipes, and menu items. Let’s go through each aspect step-by-step.

### Database Schema Design

We’ll use the following tables:

1. **Suppliers**: Stores supplier information.
2. **Ingredients**: Contains the ingredients used in recipes.
3. **Batches**: Tracks each batch of an ingredient with its purchase price, quantity, and supplier information.
4. **Dishes**: Stores the menu items for meals and beverages.
5. **Recipe_Ingredients**: Links ingredients to specific recipes, specifying required quantities.
6. **Menu_Items**: Lists all menu items and the type (e.g., meal or beverage).

---

### Table Structures and DDL Statements

#### 1. `Suppliers` Table

Stores information about suppliers.

```sql
CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_info VARCHAR(255)
);
```

#### 2. `Ingredients` Table

Contains the basic information of each ingredient, including unit of measure (e.g., grams, liters).

```sql
CREATE TABLE Ingredients (
    ingredient_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    unit_of_measure VARCHAR(50) NOT NULL
);
```

#### 3. `Batches` Table

Tracks each ingredient batch with price, quantity, purchase date, expiry, and supplier information.

```sql
CREATE TABLE Batches (
    batch_id INT PRIMARY KEY,
    ingredient_id INT NOT NULL REFERENCES Ingredients(ingredient_id),
    price_per_unit DECIMAL(10, 2) NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    remaining_qty DECIMAL(10, 2) NOT NULL,
    purchase_date DATE NOT NULL,
    expiry_date DATE,
    supplier_id INT NOT NULL REFERENCES Suppliers(supplier_id)
);
```

#### 4. `Dishes` Table

Holds each dish (meal or beverage) served in the coffee shop.

```sql
CREATE TABLE Dishes (
    dish_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    type VARCHAR(50) CHECK (type IN ('Meal', 'Beverage'))
);
```

#### 5. `Recipe_Ingredients` Table

Associates ingredients with dishes, defining how much of each ingredient is required for a recipe.

```sql
CREATE TABLE Recipe_Ingredients (
    recipe_ingredient_id INT PRIMARY KEY,
    dish_id INT NOT NULL REFERENCES Dishes(dish_id),
    ingredient_id INT NOT NULL REFERENCES Ingredients(ingredient_id),
    quantity DECIMAL(10, 2) NOT NULL
);
```

#### 6. `Menu_Items` Table

Lists all items on the menu, including price for each item served.

```sql
CREATE TABLE Menu_Items (
    menu_item_id INT PRIMARY KEY,
    dish_id INT NOT NULL REFERENCES Dishes(dish_id),
    price DECIMAL(10, 2) NOT NULL
);
```

---

### Dummy Data to Populate Tables

```sql
-- Suppliers
INSERT INTO Suppliers (supplier_id, name, contact_info) VALUES
(1, 'ABC Coffee Beans', '123-456-7890'),
(2, 'Fresh Dairy Supplies', '234-567-8901');

-- Ingredients
INSERT INTO Ingredients (ingredient_id, name, unit_of_measure) VALUES
(1, 'Coffee Beans', 'grams'),
(2, 'Milk', 'liters'),
(3, 'Sugar', 'grams'),
(4, 'Flour', 'grams'),
(5, 'Butter', 'grams');

-- Batches
INSERT INTO Batches (batch_id, ingredient_id, price_per_unit, quantity, remaining_qty, purchase_date, expiry_date, supplier_id) VALUES
(1, 1, 0.05, 5000, 5000, '2024-01-01', '2024-06-01', 1),
(2, 2, 1.20, 100, 100, '2024-01-02', '2024-02-02', 2),
(3, 3, 0.01, 2000, 2000, '2024-01-05', '2024-07-01', 1);

-- Dishes
INSERT INTO Dishes (dish_id, name, description, type) VALUES
(1, 'Latte', 'A creamy coffee with milk', 'Beverage'),
(2, 'Croissant', 'A flaky buttery pastry', 'Meal');

-- Recipe_Ingredients
INSERT INTO Recipe_Ingredients (recipe_ingredient_id, dish_id, ingredient_id, quantity) VALUES
(1, 1, 1, 18),   -- 18g Coffee Beans for Latte
(2, 1, 2, 0.25), -- 0.25L Milk for Latte
(3, 2, 4, 100),  -- 100g Flour for Croissant
(4, 2, 5, 50);   -- 50g Butter for Croissant

-- Menu_Items
INSERT INTO Menu_Items (menu_item_id, dish_id, price) VALUES
(1, 1, 3.50),  -- Latte priced at $3.50
(2, 2, 2.50);  -- Croissant priced at $2.50
```

---

### Example Queries Using Dummy Data

#### 1. Retrieve the Current Price for a Latte

This query calculates the latest cost of making a Latte by summing the required quantity of each ingredient’s price from the most recent batch.

```sql
SELECT SUM(ri.quantity * b.price_per_unit) AS latte_cost
FROM Recipe_Ingredients ri
JOIN Batches b ON ri.ingredient_id = b.ingredient_id
WHERE ri.dish_id = (SELECT dish_id FROM Dishes WHERE name = 'Latte')
AND b.remaining_qty >= ri.quantity
ORDER BY b.purchase_date DESC
LIMIT 1;
```

#### 2. Retrieve Menu with Prices

Lists all items available on the menu with their respective prices.

```sql
SELECT m.menu_item_id, d.name AS dish_name, m.price
FROM Menu_Items m
JOIN Dishes d ON m.dish_id = d.dish_id;
```

#### 3. Calculate Inventory Cost for Remaining Stock

Finds the total cost of all remaining ingredients by multiplying each batch’s remaining quantity by its unit price.

```sql
SELECT i.name AS ingredient_name, SUM(b.remaining_qty * b.price_per_unit) AS total_cost
FROM Batches b
JOIN Ingredients i ON b.ingredient_id = i.ingredient_id
GROUP BY i.name;
```

#### 4. Determine Ingredient Costs for a Croissant

Calculates the cost of ingredients for a croissant using the latest batch prices.

```sql
SELECT SUM(ri.quantity * b.price_per_unit) AS croissant_cost
FROM Recipe_Ingredients ri
JOIN Batches b ON ri.ingredient_id = b.ingredient_id
WHERE ri.dish_id = (SELECT dish_id FROM Dishes WHERE name = 'Croissant')
AND b.remaining_qty >= ri.quantity
ORDER BY b.purchase_date DESC
LIMIT 1;
```

#### 5. Decrease Inventory After a Dish is Made

After making a dish, this query updates `remaining_qty` for the batches used. For example, making a Latte:

```sql
UPDATE Batches
SET remaining_qty = remaining_qty - 18
WHERE batch_id = (SELECT batch_id FROM Batches WHERE ingredient_id = 1 ORDER BY purchase_date DESC LIMIT 1);

UPDATE Batches
SET remaining_qty = remaining_qty - 0.25
WHERE batch_id = (SELECT batch_id FROM Batches WHERE ingredient_id = 2 ORDER BY purchase_date DESC LIMIT 1);
```

---

### Summary

This schema supports:

- **Cost Calculation by Batch**: Costs for recipes reflect current ingredient batch prices.
- **Inventory Tracking by Batch**: `remaining_qty` allows precise management.
- **Menu and Recipe Management**: Recipes link ingredients and quantities needed, with a table for easy menu pricing.

This setup covers cost, inventory, and price fluctuation management for the coffee shop’s meals and beverages.

---

# Adjustments to the overall table structure

---

Given your requirements, the existing schema is close but could use a few enhancements for tracking users, handling promotions, and managing inventory production for each cart. Here are the adjustments I’d recommend:

---

### Suggested Adjustments to the Schema

1. **Add a `users` table**:
   
   - This table would store information on recurring users, allowing you to track user-specific data such as promotional discounts and loyalty points.
   - **Columns**:
     - `user_id`: Unique identifier for the user
     - `name`: Name of the user
     - `email`: User’s email for notifications or promotions
     - `loyalty_points`: Track points for promotions or discounts
     - `discount_eligibility`: Boolean or percentage to apply discounts

2. **Update `sales` to link with `users` and apply discounts**:
   
   - Include a column in the `sales` table to store discounts applied to the total sale amount, if applicable.
   - **Columns to add**:
     - `user_id` (FK): Link sales to a user for tracking purposes
     - `discount_amount`: Discount applied to the sale, if any

3. **Enhance `products` to handle product costs from ingredients**:
   
   - To track costs based on ingredient fluctuations, we could calculate the cost per product dynamically in reports (or use a `cost_per_unit` column if needed).
   - Optionally, add `production_cost` to store the total calculated cost of ingredients per batch for ready reference.
   - **Columns to consider**:
     - `production_cost`: Calculated as a sum of the latest ingredient costs for each product unit, if pre-computed

4. **Track `production_batches` for daily replenishments**:
   
   - To manage inventory for each cart, add a `production_batches` table to record the quantities produced and distributed to each cart.
   - **Columns**:
     - `batch_id`: Unique identifier for each production batch
     - `product_id` (FK): Product being produced
     - `production_date`: Date of production
     - `quantity_produced`: Total units produced
     - `distribution`: JSON or separate `production_distribution` table for cart-specific distribution details

5. **Add `promotions` table for discounts**:
   
   - Define promotions that can be applied to users based on loyalty points, sales amounts, or special events.
   - **Columns**:
     - `promotion_id`: Unique promotion identifier
     - `description`: Brief description of the promotion
     - `discount_percent`: Discount percentage to be applied
     - `eligibility_criteria`: JSON field or defined rules (e.g., min_points or min_purchase)

---

### Updated Table Structures (DDL)

#### 1. `users` Table

```sql
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    loyalty_points INT DEFAULT 0,
    discount_eligibility BOOLEAN DEFAULT FALSE
);
```

#### 2. `sales` Table (Updated)

```sql
CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    cart_id INT REFERENCES carts(cart_id),
    user_id INT REFERENCES users(user_id),
    sale_amount DECIMAL(10, 2),
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    sale_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50)
);
```

#### 3. `production_batches` Table

```sql
CREATE TABLE production_batches (
    batch_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id),
    production_date DATE,
    quantity_produced INT,
    distribution JSONB  -- OR use a production_distribution table for cart-specific details
);
```

#### 4. `promotions` Table

```sql
CREATE TABLE promotions (
    promotion_id SERIAL PRIMARY KEY,
    description TEXT,
    discount_percent DECIMAL(5, 2),
    eligibility_criteria JSONB  -- Could store rules like {"min_points": 100, "min_purchase": 50}
);
```

---

### Example Dummy Data

Here's some sample data you could use:

#### `users` Table

| user_id | name  | email           | loyalty_points | discount_eligibility |
| ------- | ----- | --------------- | -------------- | -------------------- |
| 1       | Alice | alice@email.com | 150            | TRUE                 |
| 2       | Bob   | bob@email.com   | 50             | FALSE                |

#### `production_batches` Table

| batch_id | product_id | production_date | quantity_produced | distribution                 |
| -------- | ---------- | --------------- | ----------------- | ---------------------------- |
| 1        | 101        | 2024-11-11      | 50                | {"cart_1": 20, "cart_2": 30} |

---

### Example Queries

1. **Get all sales for a specific user, including any discounts applied:**
   
   ```sql
   SELECT s.sale_id, s.sale_amount, s.discount_amount, s.sale_timestamp, s.payment_method
   FROM sales s
   JOIN users u ON s.user_id = u.user_id
   WHERE u.user_id = 1;
   ```

2. **Calculate total production costs for a product based on current ingredient batch prices:**
   
   ```sql
   SELECT p.product_id, p.product_name, SUM(ib.price_per_unit * r.quantity) AS production_cost
   FROM products p
   JOIN recipes r ON p.product_id = r.product_id
   JOIN ingr_batch ib ON r.ingredient_id = ib.ingredient_id
   WHERE p.product_id = 101
   GROUP BY p.product_id;
   ```

3. **List all carts and their current stock of each product based on recent production batches:**
   
   ```sql
   SELECT pb.batch_id, pb.product_id, pb.production_date, pb.quantity_produced, pb.distribution
   FROM production_batches pb
   WHERE pb.production_date >= CURRENT_DATE - INTERVAL '7 days';
   ```

4. **Identify users eligible for promotions based on loyalty points or previous purchases:**
   
   ```sql
   SELECT u.user_id, u.name, u.loyalty_points, p.discount_percent
   FROM users u
   JOIN promotions p ON u.loyalty_points >= p.eligibility_criteria->>'min_points'::int
   WHERE p.promotion_id = 1;
   ```

---

This setup should cover your requirements for tracking users, managing fluctuating ingredient costs, handling production, and managing discounts efficiently! Let me know if you need further customization.

---

# Establishing `production_distribution` table

---

Certainly! The `production_distribution` table would provide a detailed breakdown of how many units of each product are distributed to each cart for each production batch. Here’s what the structure could look like:

---

### `production_distribution` Table Structure

| Column                 | Description                                                            |
| ---------------------- | ---------------------------------------------------------------------- |
| `distribution_id`      | Unique identifier for each distribution entry                          |
| `batch_id`             | Foreign key linking to the `production_batches` table                  |
| `product_id`           | Foreign key linking to the `products` table                            |
| `cart_id`              | Foreign key linking to the `carts` table                               |
| `quantity_distributed` | Quantity of the product distributed to the specified cart in the batch |

---

This table would allow you to easily query the amount of each product that was sent to each cart per production batch, making it simpler to track and manage inventory across multiple carts.

---

# Tracking production cost per batch

---

To track production costs per batch and then calculate a per-product cost, you’ll need to adjust the schema slightly to ensure you capture the total production cost in each batch. Here’s how to approach this:

### Changes to Track Production Cost Per Batch

1. **Add a `total_cost` Column in the `production_batches` Table**:
   
   - This column will store the total cost of all ingredients used in a particular batch. This way, you can calculate the per-product cost simply by dividing `total_cost` by `quantity_produced`.

2. **Calculate and Store Ingredient Costs for Each Batch**:
   
   - To accurately calculate `total_cost`, you’d need to track the cost of each ingredient used in the batch at the time of production. This could be done dynamically in queries, or stored in a new table if you want historical records of ingredient costs per batch.

3. **Optional: Track Ingredient Costs for Each Production Batch (Using a `production_ingredient_costs` Table)**:
   
   - If you want more granularity or to see a breakdown of which ingredients contributed to each batch’s cost, you could use an additional table to log the quantity and cost of each ingredient used per batch.

---

### Revised Table Structures

#### 1. Updated `production_batches` Table

| Column              | Description                                  |
| ------------------- | -------------------------------------------- |
| `batch_id`          | Unique identifier for each production batch  |
| `product_id`        | Foreign key linking to the `products` table  |
| `production_date`   | Date of production                           |
| `quantity_produced` | Total quantity produced in this batch        |
| `total_cost`        | Total cost of ingredients used in this batch |

#### 2. Optional `production_ingredient_costs` Table (for Detailed Cost Tracking)

| Column          | Description                                           |
| --------------- | ----------------------------------------------------- |
| `cost_id`       | Unique identifier for each ingredient cost entry      |
| `batch_id`      | Foreign key linking to the `production_batches` table |
| `ingredient_id` | Foreign key linking to the `ingredients` table        |
| `quantity_used` | Quantity of the ingredient used in the batch          |
| `cost_per_unit` | Cost per unit at the time of production               |
| `total_cost`    | Calculated as `quantity_used * cost_per_unit`         |

This `production_ingredient_costs` table would enable you to sum up costs for each batch and record the specific cost of each ingredient at production time. 

---

### Example Queries for Production Cost Calculations

1. **Calculate Per-Product Cost Based on `production_batches`**:
   
   ```sql
   SELECT
       pb.batch_id,
       pb.product_id,
       pb.quantity_produced,
       pb.total_cost,
       pb.total_cost / NULLIF(pb.quantity_produced, 0) AS cost_per_unit
   FROM production_batches pb
   WHERE pb.product_id = 101;  -- Example product ID
   ```

2. **Calculate Total Batch Cost Using `production_ingredient_costs` (If Using This Table)**:
   
   ```sql
   SELECT
       pic.batch_id,
       SUM(pic.total_cost) AS total_batch_cost
   FROM production_ingredient_costs pic
   WHERE pic.batch_id = 1  -- Example batch ID
   GROUP BY pic.batch_id;
   ```

3. **Update `total_cost` in `production_batches` from `production_ingredient_costs`**:
   
   ```sql
   UPDATE production_batches pb
   SET total_cost = (
       SELECT SUM(total_cost)
       FROM production_ingredient_costs pic
       WHERE pic.batch_id = pb.batch_id
   );
   ```

This setup will let you easily track production costs on a per-batch basis, then calculate a per-product cost by dividing the `total_cost` by `quantity_produced`.

---

# Final table structure

---

Your table structure looks well-organized and addresses all key requirements for tracking users, carts, sales, inventory, production, and costs. Here are a few minor suggestions and clarifications:

### Suggested Adjustments

1. **`production_batches` Table**:
   
   - Add `total_cost` column: This will store the total production cost of each batch, calculated by summing `total_cost` values in the `prod_ingr_cost` table. It allows easy retrieval of total cost per batch.
   - Consider renaming `distribution_detail` to `total_distributed` or `quantity_distributed` if it’s meant to track the amount produced for distribution. 

2. **`recipes` Table**:
   
   - If the `cost_per_use` is dynamic (based on batch prices), consider calculating this on demand in queries rather than storing it. If you still want to store it, ensure it's updated each time ingredient costs fluctuate.

3. **`users` Table**:
   
   - Consider adding fields for `phone_number` and `address` if needed for personalized marketing or delivery.

4. **`sales` Table**:
   
   - Add a `total_sale_cost` column to reflect the total cost (based on ingredients) of the products sold. This allows you to analyze profitability directly by comparing `sale_amount` and `total_sale_cost`.

### Final Revised Structure

```markdown
| users |     |     |
| --- | --- | --- |
| user_id |
| name |
| email |
| loyalty_points |
| discount_eligibility |
| phone_number |
| address |

<br>

| carts |     |     |
| ---  | --- | --- |
| cart_id |
| location |
| employee_id |

<br>

| products |     |     |
| --- | --- | --- |
| product_id |
| product_name |
| price | 
| product_cost |
| description |

<br>

| cart_products |     |     |
| --- | --- | --- |
| cart_id |
| product_id |
| quantity |

<br>

| ingredients |     |     |
| --- | --- | --- |
| ingredient_id |
| ingredient_name |
| metrics |

<br>

| ingr_batch |    |    |
| --- | --- | --- |
| ingr_batch_id |
| ingredient_id |
| price_per_unit |
| quantity |
| remaining_qty |
| purchase_date |
| expiry_date |
| supplier_id |

<br>

| production_batches |     |     |
| --- | --- | --- |
| prod_batch_id |
| product_id |
| prod_date |
| qty_produced |
| total_cost |
| quantity_distributed |

<br>

| prod_ingr_cost |     |     |
| --- | --- | --- |
| prod_ingr_cost_id | 
| prod_batch_id |
| ingredient_id |
| quantity_used |
| cost_per_unit |
| total_cost |

<br>

| production_distribution |     |     |
| --- | --- | --- |
| prod_batch_id |
| product_id |
| cart_id |
| quantity |

<br>

| recipes |     |     |
| --- | --- | --- |
| recipe_id |
| product_id |
| ingredient_id |
| quantity |

<br>

| sales |     |     |
| --- | --- | --- |
| sale_id |
| cart_id |
| user_id |
| sale_amount |
| discount_percentage |
| discount_amount |
| total_sale_cost |
| sale_timestamp |
| payment_method |

<br>

| sales_details |     |     |
| --- | --- | --- |
| sales_details_id |
| sale_id |
| product_id |
| quantity |
| price_amount |

<br>

| promotions |     |     |
| --- | --- | --- |
| promo_id |
| description |
| discount_percent |
| eligibility_criteria | JSON field |
```

This refined structure should provide the flexibility and detail you need to track production costs, sales, distribution, and promotional activities across multiple carts. It will also facilitate reporting and analysis of profit margins, inventory costs, and customer loyalty programs.

---

# DDL of the final table structure

---

Certainly! Below is the DDL for each table in PostgreSQL, incorporating constraints such as primary keys, foreign keys, and some additional constraints to maintain data integrity. 

```sql
-- Users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    loyalty_points INT DEFAULT 0,
    discount_eligibility BOOLEAN DEFAULT FALSE,
    phone_number VARCHAR(20),
    address TEXT
);

-- Carts table
CREATE TABLE carts (
    cart_id SERIAL PRIMARY KEY,
    location VARCHAR(100) NOT NULL,
    employee_id INT
);

-- Products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    product_cost NUMERIC(10, 2) NOT NULL,
    description TEXT
);

-- Cart_Products table for tracking inventory in carts
CREATE TABLE cart_products (
    cart_id INT REFERENCES carts(cart_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    quantity INT DEFAULT 0 CHECK (quantity >= 0),
    PRIMARY KEY (cart_id, product_id)
);

-- Ingredients table
CREATE TABLE ingredients (
    ingredient_id SERIAL PRIMARY KEY,
    ingredient_name VARCHAR(100) NOT NULL,
    metrics VARCHAR(50) NOT NULL
);

-- Ingredient Batches table for ingredient inventory management
CREATE TABLE ingr_batch (
    ingr_batch_id SERIAL PRIMARY KEY,
    ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    price_per_unit NUMERIC(10, 2) NOT NULL CHECK (price_per_unit > 0),
    quantity NUMERIC(10, 2) NOT NULL CHECK (quantity > 0),
    remaining_qty NUMERIC(10, 2) NOT NULL CHECK (remaining_qty >= 0),
    purchase_date DATE NOT NULL,
    expiry_date DATE,
    supplier_id INT NOT NULL
);

-- Production Batches table for tracking product batches produced
CREATE TABLE production_batches (
    prod_batch_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    prod_date DATE NOT NULL,
    qty_produced NUMERIC(10, 2) NOT NULL CHECK (qty_produced > 0),
    total_cost NUMERIC(10, 2) GENERATED ALWAYS AS (SELECT COALESCE(SUM(total_cost), 0) FROM prod_ingr_cost WHERE prod_batch_id = production_batches.prod_batch_id) STORED,
    quantity_distributed NUMERIC(10, 2) DEFAULT 0 CHECK (quantity_distributed >= 0)
);

-- Production Ingredient Cost table for tracking ingredient costs per production batch
CREATE TABLE prod_ingr_cost (
    prod_ingr_cost_id SERIAL PRIMARY KEY,
    prod_batch_id INT REFERENCES production_batches(prod_batch_id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    quantity_used NUMERIC(10, 2) NOT NULL CHECK (quantity_used > 0),
    cost_per_unit NUMERIC(10, 2) NOT NULL CHECK (cost_per_unit > 0),
    total_cost NUMERIC(10, 2) GENERATED ALWAYS AS (quantity_used * cost_per_unit) STORED
);

-- Production Distribution table for tracking distribution of produced products to carts
CREATE TABLE production_distribution (
    prod_batch_id INT REFERENCES production_batches(prod_batch_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    cart_id INT REFERENCES carts(cart_id) ON DELETE CASCADE,
    quantity NUMERIC(10, 2) NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (prod_batch_id, cart_id, product_id)
);

-- Recipes table for product recipes
CREATE TABLE recipes (
    recipe_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    quantity NUMERIC(10, 2) NOT NULL CHECK (quantity > 0)
);

-- Sales table for recording sales transactions
CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    cart_id INT REFERENCES carts(cart_id) ON DELETE SET NULL,
    user_id INT REFERENCES users(user_id) ON DELETE SET NULL,
    sale_amount NUMERIC(10, 2) NOT NULL CHECK (sale_amount >= 0),
    discount_percentage NUMERIC(5, 2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    discount_amount NUMERIC(10, 2) GENERATED ALWAYS AS (sale_amount * discount_percentage / 100) STORED,
    total_sale_cost NUMERIC(10, 2),
    sale_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50) NOT NULL
);

-- Sales Details table for detailed sale line items
CREATE TABLE sales_details (
    sales_details_id SERIAL PRIMARY KEY,
    sale_id INT REFERENCES sales(sale_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE SET NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price_amount NUMERIC(10, 2) NOT NULL CHECK (price_amount >= 0)
);

-- Promotions table
CREATE TABLE promotions (
    promo_id SERIAL PRIMARY KEY,
    description TEXT,
    discount_percent NUMERIC(5, 2) NOT NULL CHECK (discount_percent >= 0 AND discount_percent <= 100),
    eligibility_criteria JSON
);
```

### Key Details

- **Foreign Key Constraints**: Ensure relationships between tables are maintained. 
- **Default Values**: For timestamp and calculated discount fields, ensuring proper default calculations where appropriate.
- **Constraints on Numeric Fields**: For `quantity`, `price_per_unit`, `total_cost`, etc., limits are set to maintain data integrity.
- **Generated Columns**: Use calculated fields for values like `discount_amount` in `sales` and `total_cost` in `prod_ingr_cost`.

This structure should allow for accurate tracking of production costs per batch, inventory management, and sales tracking for the coffee cart business. Let me know if you'd like further customization.

---

# Which data to be inserted first

---

To avoid constraint errors when inserting data into this database, you should populate the tables in an order that respects their dependencies, starting with tables that have no foreign key constraints and proceeding to those with the most dependencies. Here's the suggested order:

1. **`users`**: Since there are no dependencies on other tables, this can be populated first.

2. **`carts`**: Independent of other tables, so you can insert values here next.

3. **`products`**: Populate the products table early, as other tables will reference it.

4. **`ingredients`**: This table is required by `ingr_batch`, `recipes`, and `prod_ingr_cost`, so populate it before any tables that depend on it.

5. **`promotions`**: Independent of any other tables.

6. **`ingr_batch`**: This table references `ingredients`, so insert ingredients first before creating ingredient batches.

7. **`production_batches`**: This table references `products`, so ensure that `products` is populated first.

8. **`prod_ingr_cost`**: This table references both `production_batches` and `ingredients`, so make sure those two tables are populated before inserting data here.

9. **`recipes`**: This table references `products` and `ingredients`, so both need to be populated before adding recipes.

10. **`production_distribution`**: This table references `production_batches`, `products`, and `carts`, so all three need to be populated first.

11. **`sales`**: References `carts` and `users`, so both should be populated before inserting sales records.

12. **`sales_details`**: This table references `sales` and `products`, so both need to be populated before adding detailed sale records.

13. **`cart_products`**: This table references both `carts` and `products`, so they need to be populated before adding cart inventory information.

### Summary of Insertion Order:

1. `users`
2. `carts`
3. `products`
4. `ingredients`
5. `promotions`
6. `ingr_batch`
7. `production_batches`
8. `prod_ingr_cost`
9. `recipes`
10. `production_distribution`
11. `sales`
12. `sales_details`
13. `cart_products`

Following this order ensures that all foreign key dependencies are respected, minimizing the risk of constraint errors during data insertion.

---

# Revision to the DDL

---

Your DDL has some errors and adjustments needed to work correctly in PostgreSQL. Here are the issues I identified and corrected:

1. **Syntax Issues**:
   
   - Missing commas in several places.
   - The constraint on `prod_ingr_cost.cost_per_unit` is incorrect.

2. **Incorrect Foreign Key References**:
   
   - `FOREIGN KEY (cost_per_unit) REFERENCES ingr_batch(price_per_unit) ON DELETE RESTRICT` in `prod_ingr_cost` is incorrect. Foreign keys should reference primary or unique key columns, so referencing a non-unique column is not allowed.

3. **ON DELETE Clause in `cart_products` Table**:
   
   - `ON DELETE RESTRICT` should be in the `FOREIGN KEY` clauses, not directly after the column definitions.

4. **References to `price` in `sales_details`**:
   
   - Referencing `products(price)` as a foreign key in `sales_details` doesn’t make sense because `price` is not unique.

Here's the corrected DDL:

```sql
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    loyalty_points INTEGER DEFAULT 0,
    discount_eligibility BOOLEAN DEFAULT FALSE,
    phone_number VARCHAR(20)
);

CREATE TABLE carts (
    cart_id SERIAL PRIMARY KEY,
    location VARCHAR(100) NOT NULL,
    employee_id INTEGER,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    product_cost NUMERIC(10, 2) NOT NULL,
    description TEXT
);

CREATE TABLE cart_products (
    cart_id INTEGER,
    product_id INTEGER,
    quantity INTEGER DEFAULT 0 CHECK (quantity >= 0),
    PRIMARY KEY (cart_id, product_id),
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

CREATE TABLE ingredients (
    ingredient_id SERIAL PRIMARY KEY,
    ingredient_name VARCHAR(100) NOT NULL,
    metrics VARCHAR(50) NOT NULL
);

CREATE TABLE ingr_batch (
    ingr_batch_id SERIAL PRIMARY KEY,
    ingredient_id INTEGER,
    price_per_unit NUMERIC(10,2) NOT NULL CHECK (price_per_unit > 0),
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    remaining_qty NUMERIC(10,2) NOT NULL CHECK (remaining_qty >= 0),
    purchase_date DATE NOT NULL,
    expiry_date DATE,
    supplier_id INTEGER,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE RESTRICT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE RESTRICT
);

CREATE TABLE production_batches (
    prod_batch_id SERIAL PRIMARY KEY,
    product_id INTEGER,
    prod_date DATE NOT NULL,
    qty_produced NUMERIC(10,2) NOT NULL CHECK (qty_produced > 0),
    quantity_distributed NUMERIC(10,2) DEFAULT 0 CHECK (quantity_distributed >= 0),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

CREATE TABLE prod_ingr_cost (
    prod_ingr_cost_id SERIAL PRIMARY KEY,
    prod_batch_id INTEGER,
    ingredient_id INTEGER,
    ingr_batch_id INTEGER,
    quantity_used NUMERIC(10,2) NOT NULL CHECK (quantity_used > 0),
    cost_per_unit NUMERIC(10,2) NOT NULL CHECK (cost_per_unit > 0),
    ingr_cost NUMERIC(10,2) GENERATED ALWAYS AS (quantity_used * cost_per_unit) STORED,
    FOREIGN KEY (prod_batch_id) REFERENCES production_batches(prod_batch_id) ON DELETE RESTRICT,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE RESTRICT,
    FOREIGN KEY (ingr_batch_id) REFERENCES ingr_batch(ingr_batch_id) ON DELETE RESTRICT
);

CREATE TABLE production_distribution (
    prod_batch_id INTEGER,
    product_id INTEGER,
    cart_id INTEGER,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (prod_batch_id, product_id, cart_id),
    FOREIGN KEY (prod_batch_id) REFERENCES production_batches(prod_batch_id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE RESTRICT
);

CREATE TABLE recipes (
    recipe_id SERIAL PRIMARY KEY,
    product_id INTEGER,
    ingredient_id INTEGER,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE RESTRICT
);

CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    cart_id INTEGER,
    user_id INTEGER,
    sale_amount NUMERIC(10,2) NOT NULL CHECK (sale_amount >= 0),
    discount_percentage NUMERIC(5,2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    discount_amount NUMERIC(10,2) GENERATED ALWAYS AS (sale_amount * discount_percentage / 100) STORED,
    total_sale_cost NUMERIC(10,2),
    sale_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50) NOT NULL,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT
);

CREATE TABLE sales_details (
    sales_details_id SERIAL PRIMARY KEY,
    sale_id INTEGER,
    product_id INTEGER,
    price NUMERIC(10,2),
    quantity INTEGER NOT NULL,
    price_amount NUMERIC(10,2) GENERATED ALWAYS AS (price * quantity) STORED,
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

CREATE TABLE promotions (
    promo_id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    discount_percent NUMERIC(5,2) NOT NULL CHECK (discount_percent >= 0 AND discount_percent <= 100),
    eligibility_criteria JSONB
);
```

### Key Changes

1. **Fixed Missing Commas** and syntax issues.
2. **Removed Foreign Key Reference to Non-Unique Column**: Removed `FOREIGN KEY (cost_per_unit) REFERENCES ingr_batch(price_per_unit) ON DELETE RESTRICT` in `prod_ingr_cost` table since it cannot reference a non-unique column.
3. **Adjusted Constraints**: Moved constraints like `ON DELETE RESTRICT` within the `FOREIGN KEY` clause in tables like `cart_products`.

These changes should allow the DDL to run without syntax errors and enforce the correct constraints.

---

# Referencing a non-key column in other table

---

In relational databases, you generally cannot create a foreign key reference to a column that isn’t a primary key or doesn’t have a unique constraint. This means that while you can reference `product_id` in `sales_details` as a foreign key from `products` because `product_id` is a primary key, you can’t directly reference the `price` column from `products` as a foreign key since it isn’t unique or a primary key.

However, there are a few ways to achieve similar functionality:

1. **Copy the `price` value into `sales_details` using a trigger**:
   
   - You could use a trigger to automatically set the `price` in `sales_details` when a new row is inserted, or whenever `product_id` in `sales_details` is updated. The trigger would pull the price from `products` based on the `product_id`.
   
   Here’s a simple example of such a trigger:
   
   ```sql
   CREATE OR REPLACE FUNCTION set_price_from_product()
   RETURNS TRIGGER AS $$
   BEGIN
       NEW.price := (SELECT price FROM products WHERE product_id = NEW.product_id);
       RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
   
   CREATE TRIGGER set_price_trigger
   BEFORE INSERT OR UPDATE ON sales_details
   FOR EACH ROW
   EXECUTE FUNCTION set_price_from_product();
   ```
   
   This trigger sets `price` in `sales_details` based on the `product_id` whenever a new row is inserted or updated.

2. **Use a view to join data from both tables**:
   
   - Instead of duplicating the `price` in `sales_details`, you could create a view that joins `sales_details` and `products` to include `price` from `products` in a combined result. For example:
   
   ```sql
   CREATE VIEW sales_details_with_price AS
   SELECT sd.sales_details_id, sd.sale_id, sd.product_id, p.price, sd.quantity, sd.price_amount
   FROM sales_details sd
   JOIN products p ON sd.product_id = p.product_id;
   ```

3. **Add `price` in `sales_details` without foreign key constraint**:
   
   - If you don’t require referential integrity enforcement on `price`, you can include it in `sales_details` as a regular column and manually ensure that it matches the value in `products` when necessary (e.g., through application logic).

Each approach has trade-offs, so the best choice depends on your use case:

- **Triggers** ensure data consistency but may have a slight performance impact.
- **Views** are efficient for reading data but do not store it in `sales_details`.
- **Direct addition** without a constraint gives flexibility but requires manual consistency management.

---

## Updated schema to track location history to analyze location-based sales

---

To effectively track the sales performance of each coffee cart by both *location* and *time-of-day*, we'll need to capture additional data on the cart’s *location history*, *time spent at each location*, and *sales transactions* tied to each specific location and time-of-day period. Here's a breakdown of how to approach this:

### 1. Capturing the Necessary Data

We need to gather information on:

- **Location and Time of Day**: Each time a cart arrives at and leaves a location, capturing timestamps and specific locations (subdistricts).
- **Sales Transactions**: Each sale’s timestamp, amount, and associated cart/location.
- **Operational Hours**: Defining parts of the day (e.g., morning, afternoon) to better understand sales performance in those specific periods.

### 2. Database Schema / DDL Improvements

To accommodate these needs, we can add two new tables:

1. **`cart_location_history`**: Logs each cart’s location and time period.
2. **`cart_sales`**: Tracks each sale with details on location, cart, and the time period it was made in.

### Suggested Updated Schema

Here’s an example schema incorporating these tables and the necessary relationships:

```sql
CREATE TABLE cart_location_history (
    location_history_id SERIAL PRIMARY KEY,
    cart_id INT NOT NULL,
    location VARCHAR(100) NOT NULL,
    subdistrict VARCHAR(100) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    part_of_day VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN EXTRACT(hour FROM start_time) BETWEEN 6 AND 11 THEN 'morning'
            WHEN EXTRACT(hour FROM start_time) BETWEEN 12 AND 15 THEN 'afternoon'
            WHEN EXTRACT(hour FROM start_time) BETWEEN 16 AND 18 THEN 'late afternoon'
            WHEN EXTRACT(hour FROM start_time) BETWEEN 19 AND 23 THEN 'evening'
            ELSE 'night'
        END
    ) STORED,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE
);

-- Log each sale, tying it to a cart, location, and part of the day
CREATE TABLE cart_sales (
    sale_id SERIAL PRIMARY KEY,
    cart_id INT NOT NULL,
    location VARCHAR(100) NOT NULL,
    subdistrict VARCHAR(100) NOT NULL,
    sale_time TIMESTAMP NOT NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    part_of_day VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN EXTRACT(hour FROM sale_time) BETWEEN 6 AND 11 THEN 'morning'
            WHEN EXTRACT(hour FROM sale_time) BETWEEN 12 AND 15 THEN 'afternoon'
            WHEN EXTRACT(hour FROM sale_time) BETWEEN 16 AND 18 THEN 'late afternoon'
            WHEN EXTRACT(hour FROM sale_time) BETWEEN 19 AND 23 THEN 'evening'
            ELSE 'night'
        END
    ) STORED,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE
);

-- Track time spent by carts in each area for performance insights
CREATE VIEW cart_location_duration AS
SELECT
    cart_id,
    location,
    subdistrict,
    part_of_day,
    SUM(EXTRACT(epoch FROM (end_time - start_time))/3600) AS hours_spent
FROM cart_location_history
GROUP BY cart_id, location, subdistrict, part_of_day;
```

### Explanation of the New Tables and View

1. **`cart_location_history`**:
   
   - This table records each time a cart arrives and leaves a location.
   - *`start_time`* and *`end_time`* are timestamps to track the time spent in a specific area.
   - *`part_of_day`* is a generated column that categorizes the start time into morning, afternoon, late afternoon, evening, or night.

2. **`cart_sales`**:
   
   - This table records each sale, its timestamp, and amount.
   - *`part_of_day`* is a generated column similar to `cart_location_history`, based on the sale’s time.

3. **`cart_location_duration` (View)**:
   
   - This view calculates the total hours each cart spends in each location/subdistrict during each part of the day.
   - Using this view, you can track how long carts spend in specific areas and correlate that with sales data to analyze sales performance by location and time-of-day.

### Benefits of This Structure

This setup will allow you to:

- Track the time each cart spends at specific locations and during which parts of the day.
- Analyze sales based on location and time-of-day, which provides valuable insights into peak periods and high-performing locations.
- Simplify querying for performance analysis since `part_of_day` is automatically computed.

With this structure, you can easily query to find, for instance, sales performance in specific locations during different times of the day or examine the impact of location on sales trends.

---

## The explanations for `locations` in `cart_location_history` and `cart_sales`

---

In this scenario, we want `location` and `subdistrict` in `cart_location_history` to represent where each cart is at a given time. The `cart_sales` table also has a `location` column, which should match the cart’s current location when the sale occurs. To manage this, we need to ensure consistent and accurate data entry and consider a design that reduces redundancy.

### Option 1: Reference `cart_location_history` in `cart_sales`

To avoid duplicating location details across tables, we could relate `cart_sales` to `cart_location_history` by including a foreign key reference. This way, each sale record would reference the location history entry that was current at the sale time. Here’s how it could work:

1. **Modify `cart_sales` to include a reference to `cart_location_history`**:
   
   - Add a column `location_history_id` to `cart_sales`, which points to the relevant entry in `cart_location_history`.
   - This allows each sale to be directly associated with a specific `location` and `subdistrict` through `cart_location_history`.

2. **Update Schema**:
   Here’s how the tables might look with this change:
   
   ```sql
   CREATE TABLE cart_location_history (
       location_history_id SERIAL PRIMARY KEY,
       cart_id INT NOT NULL,
       location VARCHAR(100) NOT NULL,
       subdistrict VARCHAR(100) NOT NULL,
       start_time TIMESTAMP NOT NULL,
       end_time TIMESTAMP,
       part_of_day VARCHAR(20) GENERATED ALWAYS AS (
           CASE
               WHEN EXTRACT(hour FROM start_time) BETWEEN 6 AND 11 THEN 'morning'
               WHEN EXTRACT(hour FROM start_time) BETWEEN 12 AND 15 THEN 'afternoon'
               WHEN EXTRACT(hour FROM start_time) BETWEEN 16 AND 18 THEN 'late afternoon'
               WHEN EXTRACT(hour FROM start_time) BETWEEN 19 AND 23 THEN 'evening'
               ELSE 'night'
           END
       ) STORED,
       FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE
   );
   
   CREATE TABLE cart_sales (
       sale_id SERIAL PRIMARY KEY,
       cart_id INT NOT NULL,
       location_history_id INT NOT NULL,
       sale_time TIMESTAMP NOT NULL,
       amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
       part_of_day VARCHAR(20) GENERATED ALWAYS AS (
           CASE
               WHEN EXTRACT(hour FROM sale_time) BETWEEN 6 AND 11 THEN 'morning'
               WHEN EXTRACT(hour FROM sale_time) BETWEEN 12 AND 15 THEN 'afternoon'
               WHEN EXTRACT(hour FROM sale_time) BETWEEN 16 AND 18 THEN 'late afternoon'
               WHEN EXTRACT(hour FROM sale_time) BETWEEN 19 AND 23 THEN 'evening'
               ELSE 'night'
           END
       ) STORED,
       FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
       FOREIGN KEY (location_history_id) REFERENCES cart_location_history(location_history_id) ON DELETE CASCADE
   );
   ```

3. **Data Entry Process**:
   
   - When a cart arrives at a new location, a new record is added to `cart_location_history`.
   - When a sale is recorded, the `location_history_id` is referenced in `cart_sales`, linking each sale to the cart’s current location and time period.

This approach ensures data consistency and avoids storing redundant `location` and `subdistrict` information directly in `cart_sales`.

### Option 2: Store `location` and `subdistrict` Separately in `cart_sales`

Alternatively, you could keep the `location` and `subdistrict` columns directly in `cart_sales` and populate them based on the active location in `cart_location_history` when each sale occurs. This approach might be simpler but has downsides, such as:

- **Data Redundancy**: `location` and `subdistrict` data could be duplicated across multiple records if the same cart makes multiple sales at a location.
- **Data Integrity**: Any updates to a location’s name or subdistrict would require updating all `cart_sales` records, making maintenance more difficult.

### Recommended Approach

**Option 1** is generally preferable because:

- It normalizes the data, reducing redundancy and keeping locations consistent.
- Updates to a cart’s location only affect the records in `cart_location_history`, leaving `cart_sales` clean and linked.

This setup will provide an efficient structure for querying sales data by location, subdistrict, or time period without having to duplicate information unnecessarily.

### Whether the `GENERATED ALWAYS AS ()` work in PostgreSQL

Yes, the `GENERATED ALWAYS AS` syntax is supported in PostgreSQL, specifically for creating **generated (computed) columns** in tables starting from PostgreSQL 12. This feature allows you to define a column's value based on a calculation involving other columns or expressions without needing to write triggers or manage these columns manually.

### Example of `GENERATED ALWAYS AS` in PostgreSQL

In the code provided, the following structure is used for generating the `part_of_day` column based on `start_time` or `sale_time`:

```sql
part_of_day VARCHAR(20) GENERATED ALWAYS AS (
    CASE
        WHEN EXTRACT(hour FROM start_time) BETWEEN 6 AND 11 THEN 'morning'
        WHEN EXTRACT(hour FROM start_time) BETWEEN 12 AND 15 THEN 'afternoon'
        WHEN EXTRACT(hour FROM start_time) BETWEEN 16 AND 18 THEN 'late afternoon'
        WHEN EXTRACT(hour FROM start_time) BETWEEN 19 AND 23 THEN 'evening'
        ELSE 'night'
    END
) STORED
```

### Important Notes

1. **Stored vs. Virtual Columns**: PostgreSQL only supports **stored** generated columns. The `STORED` keyword ensures that the column value is calculated when a row is inserted or updated and is then physically stored in the table. In contrast, **virtual (computed on read)** columns are recalculated each time they’re queried, but PostgreSQL does not support this for generated columns.

2. **Constraints**: Generated columns can be used in `SELECT` statements and indexes but cannot be modified directly, as they are recalculated based on the defined expression.

3. **Compatibility**: This syntax works in PostgreSQL 12 and later. If you're using an earlier version, you would need to use a workaround, such as creating the value via a `BEFORE INSERT` or `BEFORE UPDATE` trigger instead.

### Example Table Creation with `GENERATED ALWAYS AS`

Here’s a complete example for `cart_location_history` using `GENERATED ALWAYS AS`:

```sql
CREATE TABLE cart_location_history (
    location_history_id SERIAL PRIMARY KEY,
    cart_id INT NOT NULL,
    location VARCHAR(100) NOT NULL,
    subdistrict VARCHAR(100) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    part_of_day VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN EXTRACT(hour FROM start_time) BETWEEN 6 AND 11 THEN 'morning'
            WHEN EXTRACT(hour FROM start_time) BETWEEN 12 AND 15 THEN 'afternoon'
            WHEN EXTRACT(hour FROM start_time) BETWEEN 16 AND 18 THEN 'late afternoon'
            WHEN EXTRACT(hour FROM start_time) BETWEEN 19 AND 23 THEN 'evening'
            ELSE 'night'
        END
    ) STORED,
    FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE
);
```

This will automatically set `part_of_day` based on the `start_time` value when each record is inserted or updated.

---

## Changes from `sales` and `sales_detail` to `cart_sales` and modification in `sales_detail`

---

Yes, given that the original `sales` table has been restructured as `cart_sales` with updated references to `location_history_id` and new time-based tracking, you’ll need a few adjustments in the `sales_details` table to ensure consistency with the new `cart_sales` schema. However, if the core structure of `sales_details` remains the same (storing item-level details like `product_id`, `price`, and `quantity`), only a minor change is required:

### Updated `sales_details` Table

Here’s what needs to be updated:

1. **Rename the `sale_id` foreign key** to reference `cart_sales(sale_id)`.
2. Ensure `sales_details` remains linked to the correct primary key from the restructured `cart_sales`.

Here's the modified `sales_details` table DDL statement:

```sql
CREATE TABLE sales_details (
    sales_details_id SERIAL PRIMARY KEY,
    sale_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_amount NUMERIC(10,2) GENERATED ALWAYS AS (price * quantity) STORED,
    FOREIGN KEY (sale_id) REFERENCES cart_sales(sale_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);
```

### Explanation of Changes:

- **Foreign Key `sale_id`**: This now references `cart_sales(sale_id)` instead of `sales(sale_id)`.
- **Column Integrity Checks**: The `quantity` column now has a `CHECK` constraint to ensure that quantity values are always positive.

This revised schema aligns `sales_details` with the `cart_sales` table structure, allowing for efficient tracking of product-level sales data linked to cart location and time-of-day data. 

Let me know if you need additional modifications or any more information!