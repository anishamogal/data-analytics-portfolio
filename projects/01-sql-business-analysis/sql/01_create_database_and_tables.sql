-- ============================================================
-- Project: Revenue Leakage and Business Performance Analysis
-- File: 01_create_database_and_tables.sql
-- Author: Anisha Mogal
-- Description:
-- This script creates the database and tables for the SQL portfolio project.
-- ============================================================

CREATE DATABASE IF NOT EXISTS revenue_leakage_analysis;

USE revenue_leakage_analysis;

DROP TABLE IF EXISTS billing_adjustments;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS locations;

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_segment VARCHAR(50),
    signup_date DATE,
    city VARCHAR(50),
    state VARCHAR(10)
);

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100),
    product_category VARCHAR(50),
    standard_price DECIMAL(10,2)
);

CREATE TABLE locations (
    location_id VARCHAR(10) PRIMARY KEY,
    location_name VARCHAR(100),
    region VARCHAR(50),
    manager_name VARCHAR(100)
);

CREATE TABLE transactions (
    transaction_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    product_id VARCHAR(10),
    location_id VARCHAR(10),
    transaction_date DATE,
    quantity INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    payment_status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

CREATE TABLE billing_adjustments (
    adjustment_id VARCHAR(10) PRIMARY KEY,
    transaction_id VARCHAR(10),
    adjustment_date DATE,
    adjustment_type VARCHAR(50),
    adjustment_amount DECIMAL(10,2),
    reason VARCHAR(255),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);