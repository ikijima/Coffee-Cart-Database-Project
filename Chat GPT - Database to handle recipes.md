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
