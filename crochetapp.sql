-- crochet_marketplace.sql
-- MySQL schema for local crochet marketplace
-- Run: mysql -u root -p < crochet_marketplace.sql
CREATE DATABASE IF NOT EXISTS crochet_marketplace
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_unicode_ci;
USE crochet_marketplace;

-- USERS
CREATE TABLE IF NOT EXISTS Users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('Buyer','Seller') NOT NULL DEFAULT 'Buyer',
  bio TEXT,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- CATEGORIES
CREATE TABLE IF NOT EXISTS Categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- TAGS (for many-to-many product tagging)
CREATE TABLE IF NOT EXISTS Tags (
  tag_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- PRODUCTS
CREATE TABLE IF NOT EXISTS Products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  seller_id INT NOT NULL,
  category_id INT NULL,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  stock INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (seller_id) REFERENCES Users(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ProductImages (multiple images per product)
CREATE TABLE IF NOT EXISTS ProductImages (
  image_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  url VARCHAR(1024) NOT NULL,
  alt_text VARCHAR(255),
  is_primary TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ProductTags (many-to-many)
CREATE TABLE IF NOT EXISTS ProductTags (
  product_id INT NOT NULL,
  tag_id INT NOT NULL,
  PRIMARY KEY (product_id, tag_id),
  FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES Tags(tag_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ADDRESSES (shipping addresses for users)
CREATE TABLE IF NOT EXISTS Addresses (
  address_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  line1 VARCHAR(255) NOT NULL,
  line2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  country VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20),
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ORDERS
CREATE TABLE IF NOT EXISTS Orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  buyer_id INT NOT NULL,
  shipping_address_id INT NULL,
  total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('Pending','Paid','Shipped','Delivered','Cancelled','Refunded') DEFAULT 'Pending',
  notes TEXT,
  FOREIGN KEY (buyer_id) REFERENCES Users(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (shipping_address_id) REFERENCES Addresses(address_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ORDER ITEMS (store snapshot of product name & price to preserve history)
CREATE TABLE IF NOT EXISTS OrderItems (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NULL,
  product_name VARCHAR(255) NOT NULL,
  product_price DECIMAL(10,2) NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- PAYMENTS (basic payment log)
CREATE TABLE IF NOT EXISTS Payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  method ENUM('Card','Mpesa','Cash','Other') DEFAULT 'Card',
  status ENUM('Pending','Completed','Failed','Refunded') DEFAULT 'Pending',
  transaction_ref VARCHAR(255),
  paid_at TIMESTAMP NULL,
  FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- REVIEWS (one per buyer per product)
CREATE TABLE IF NOT EXISTS Reviews (
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  buyer_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (buyer_id) REFERENCES Users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY one_review_per_user_product (product_id, buyer_id)
) ENGINE=InnoDB;

-- INDEXES & FULLTEXT for search
CREATE INDEX idx_products_seller ON Products(seller_id);
CREATE INDEX idx_products_category ON Products(category_id);
CREATE INDEX idx_orders_buyer ON Orders(buyer_id);
CREATE INDEX idx_orderitems_order ON OrderItems(order_id);
CREATE INDEX idx_reviews_product ON Reviews(product_id);

-- Fulltext index (MySQL 5.6+ InnoDB supports fulltext)
ALTER TABLE Products ADD FULLTEXT INDEX ft_products_name_desc (name, description);

-- SAMPLE DATA (small seed)
INSERT INTO Users (first_name, last_name, email, password_hash, role) VALUES
('Alice','Maker','alice@example.com','<bcrypt_hash_here>','Seller'),
('Bob','Buyer','bob@example.com','<bcrypt_hash_here>','Buyer'),
('Carol','Seller','carol@example.com','<bcrypt_hash_here>','Seller');

INSERT INTO Categories (name) VALUES ('Clothing'),('Home Decor'),('Accessories');
INSERT INTO Tags (name) VALUES ('handmade'),('organic'),('gift'),('baby'),('winter');

INSERT INTO Products (seller_id, category_id, name, slug, description, price, stock) VALUES
(1, 1, 'Chunky Knit Sweater','chunky-knit-sweater','Cozy hand-stitched chunky sweater', 55.00, 5),
(1, 2, 'Crochet Pillow Cover','crochet-pillow-cover','Boho crochet pillow cover', 18.50, 12),
(3, 3, 'Cute Baby Booties','baby-booties','Soft cotton baby booties', 12.00, 20);

INSERT INTO ProductImages (product_id, url, alt_text, is_primary) VALUES
(1, 'https://example.com/images/sweater1.jpg','Chunky sweater front',1),
(2, 'https://example.com/images/pillow1.jpg','Pillow cover',1),
(3, 'https://example.com/images/booties1.jpg','Baby booties',1);

INSERT INTO ProductTags (product_id, tag_id) VALUES
(1,1),(1,5),(2,1),(2,3),(3,1),(3,4);

-- done
