# week-8-database-project
Database project for week 8
# 🧶 Crochet Marketplace Database

A relational database schema for a local Etsy-style crochet marketplace.  
This project is **Part 1** of a larger system — it focuses on the **database design** and SQL implementation.

---

## 📌 Features

- **Users** (Buyers & Sellers) with roles  
- **Products** with images, categories, tags  
- **Orders** with multiple items and transactional safety  
- **Payments** (basic log: Mpesa, Card, Cash)  
- **Reviews** (1 per buyer per product)  
- **Addresses** (shipping info)  
- Full-text search on product names and descriptions  
- Proper constraints (`PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, `CHECK`)  

---

## 🗂️ Schema Overview

**Main Entities:**
- `Users`  
- `Categories`, `Tags`  
- `Products`, `ProductImages`, `ProductTags`  
- `Orders`, `OrderItems`, `Payments`  
- `Addresses`  
- `Reviews`  

Relationships:
- One seller → Many products  
- One product → Many images  
- Products ↔ Tags (many-to-many)  
- One buyer → Many orders  
- One order → Many order items  
- One buyer → Many reviews (but only one per product)  

---

## 🚀 Getting Started

### 1. Requirements
- MySQL 8.0+ (or MariaDB 10.4+)  
- Docker (optional, if you don’t want to install MySQL locally)

### 2. Clone & Setup
```bash
git clone https://github.com/your-username/crochet-marketplace-db.git
cd crochet-marketplace-db
**### 3. Run Sql**
mysql -u root -p < crochet_marketplace.sql
### 4. Usage
mysql -u root -p
USE crochet_marketplace;

###5. some example tests
-- List products with seller names
SELECT p.name, p.price, u.first_name AS seller
FROM Products p
JOIN Users u ON p.seller_id = u.user_id;

-- Full-text search
SELECT product_id, name
FROM Products
WHERE MATCH(name, description) AGAINST('sweater');

