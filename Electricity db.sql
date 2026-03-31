CREATE DATABASE IF NOT EXISTS electricity_db;
USE electricity_db;
CREATE TABLE consumers (
    consumer_id     INT AUTO_INCREMENT PRIMARY KEY,
    consumer_no     VARCHAR(20)  NOT NULL UNIQUE,      
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(100) UNIQUE,
    phone           VARCHAR(15)  NOT NULL,
    address         VARCHAR(255) NOT NULL,
    city            VARCHAR(50)  NOT NULL,
    connection_type ENUM('Domestic', 'Commercial', 'Industrial') DEFAULT 'Domestic',
    status          ENUM('Active', 'Disconnected') DEFAULT 'Active',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
desc consumers;
 INSERT INTO consumers (consumer_no, full_name, email, phone, address, city, connection_type) VALUES
('CON-001', 'Rahul Sharma',  'rahul@gmail.com',  '9811001100', '12 Lajpat Nagar', 'Delhi',  'Domestic'),
('CON-002', 'Priya Mehta',   'priya@gmail.com',  '9822002200', '5 Bandra West',   'Mumbai', 'Domestic'),
('CON-003', 'Arjun Traders', 'arjun@biz.com',    '9833003300', '78 CP Road',      'Delhi',  'Commercial');
select * from consumers;
CREATE TABLE meters (
    meter_id          INT AUTO_INCREMENT PRIMARY KEY,
    meter_number      VARCHAR(20) NOT NULL UNIQUE,
    consumer_id       INT NOT NULL,
    meter_type        ENUM('Single Phase', 'Three Phase') DEFAULT 'Single Phase',
    installation_date DATE NOT NULL,
    status            ENUM('Active', 'Faulty', 'Replaced') DEFAULT 'Active',
    FOREIGN KEY (consumer_id) REFERENCES consumers(consumer_id) ON DELETE CASCADE
);
desc meters;
INSERT INTO meters (meter_number, consumer_id, meter_type, installation_date) VALUES
('MTR-101', 1, 'Single Phase', '2022-01-10'),
('MTR-102', 2, 'Single Phase', '2021-06-15'),
('MTR-103', 3, 'Three Phase',  '2023-03-20');
select * from meters;
CREATE TABLE tariff (
    tariff_id       INT AUTO_INCREMENT PRIMARY KEY,
    connection_type ENUM('Domestic', 'Commercial', 'Industrial') NOT NULL,
    rate_per_unit   DECIMAL(6,2) NOT NULL,    -- ₹ per kWh
    fixed_charge    DECIMAL(8,2) NOT NULL,    -- monthly fixed ₹
    tax_percent     DECIMAL(5,2) DEFAULT 18   -- GST %
);

INSERT INTO tariff (connection_type, rate_per_unit, fixed_charge, tax_percent) VALUES
('Domestic',    4.50, 50.00,  18),
('Commercial',  7.00, 150.00, 18),
('Industrial',  6.50, 500.00, 18);
desc tariff;
select * from tariff;
CREATE TABLE meter_readings (
    reading_id       INT AUTO_INCREMENT PRIMARY KEY,
    meter_id         INT  NOT NULL,
    consumer_id      INT  NOT NULL,
    reading_date     DATE NOT NULL,
    previous_reading DECIMAL(10,2) NOT NULL,
    current_reading  DECIMAL(10,2) NOT NULL,
    units_consumed   DECIMAL(10,2) AS (current_reading - previous_reading) STORED,
    FOREIGN KEY (meter_id)    REFERENCES meters(meter_id),
    FOREIGN KEY (consumer_id) REFERENCES consumers(consumer_id)
);
INSERT INTO meter_readings (meter_id, consumer_id, reading_date, previous_reading, current_reading)
VALUES
(1, 1, '2025-03-01', 1000.00, 1180.00),   -- 180 units consumed
(2, 2, '2025-03-01', 2500.00, 2650.00),   -- 150 units consumed
(3, 3, '2025-03-01',  500.00,  680.00);   -- 180 units consumed
desc meter_readings;
select * from meter_readings;
CREATE TABLE bills (
    bill_id        INT AUTO_INCREMENT PRIMARY KEY,
    bill_number    VARCHAR(20) NOT NULL UNIQUE,
    consumer_id    INT         NOT NULL,
    reading_id     INT         NOT NULL,
    bill_month     TINYINT     NOT NULL,   -- 1 to 12
    bill_year      YEAR        NOT NULL,
    units_consumed DECIMAL(10,2) NOT NULL,
    energy_charge  DECIMAL(10,2) NOT NULL, -- units × rate_per_unit
    fixed_charge   DECIMAL(10,2) NOT NULL,
    tax_amount     DECIMAL(10,2) NOT NULL,
    total_amount   DECIMAL(10,2) NOT NULL,
    due_date       DATE        NOT NULL,
    status         ENUM('Unpaid', 'Paid', 'Overdue') DEFAULT 'Unpaid',
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (consumer_id) REFERENCES consumers(consumer_id),
    FOREIGN KEY (reading_id)  REFERENCES meter_readings(reading_id)
);
INSERT INTO bills (bill_number, consumer_id, reading_id, bill_month, bill_year, units_consumed, energy_charge, fixed_charge, tax_amount, total_amount, due_date, status) 
VALUES
('BILL-001', 1, 1, 3, 2025, 180, 810.00,  50.00, 154.80, 1014.80, '2025-03-20', 'Paid'),
('BILL-002', 2, 2, 3, 2025, 150, 675.00,  50.00, 129.60,  854.60, '2025-03-20', 'Unpaid'),
('BILL-003', 3, 3, 3, 2025, 180,1260.00, 150.00, 254.88, 1664.88, '2025-03-20', 'Overdue');
desc bills;
select * from bills;
CREATE TABLE payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    bill_id         INT          NOT NULL,
    consumer_id     INT          NOT NULL,
    amount_paid     DECIMAL(10,2) NOT NULL,
    payment_date    DATETIME     DEFAULT CURRENT_TIMESTAMP,
    payment_mode    ENUM('Cash', 'UPI', 'Net Banking', 'Card') NOT NULL,
    transaction_ref VARCHAR(100),           -- UPI / bank transaction ID
    status          ENUM('Success', 'Failed', 'Pending') DEFAULT 'Success',
    FOREIGN KEY (bill_id)     REFERENCES bills(bill_id),
    FOREIGN KEY (consumer_id) REFERENCES consumers(consumer_id)
);
 INSERT INTO payments (bill_id, consumer_id, amount_paid, payment_mode, transaction_ref) 
 VALUES (1, 1, 1014.80, 'UPI', 'UPI20250310001');
 desc payments;
select * from payments;
 CREATE TABLE employees (
    employee_id   INT AUTO_INCREMENT PRIMARY KEY,
    emp_code      VARCHAR(20)  NOT NULL UNIQUE,
    full_name     VARCHAR(100) NOT NULL,
    role          ENUM('Admin', 'Meter Reader', 'Billing Officer') NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(15)  NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 INSERT INTO employees (emp_code, full_name, role, email, phone, password_hash) VALUES
('EMP-01', 'Suresh Admin',   'Admin',          'suresh@eb.in', '9000000001', SHA2('admin123', 256)),
('EMP-02', 'Manoj Reader',   'Meter Reader',   'manoj@eb.in',  '9000000002', SHA2('read123',  256)),
('EMP-03', 'Kavita Billing', 'Billing Officer','kavita@eb.in', '9000000003', SHA2('bill123',  256));
desc employees;
select * from employees;

CREATE TABLE complaints (
    complaint_id   INT AUTO_INCREMENT PRIMARY KEY,
    consumer_id    INT  NOT NULL,
    subject        VARCHAR(150) NOT NULL,
    description    TEXT,
    status         ENUM('Open', 'In Progress', 'Resolved') DEFAULT 'Open',
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at    DATETIME,
    FOREIGN KEY (consumer_id) REFERENCES consumers(consumer_id)
);
INSERT INTO complaints (consumer_id, subject, description) VALUES
(2, 'High bill amount', 'My bill is way higher than usual this month.'),
(3, 'No power supply', 'No electricity since 8am today.');
 desc complaints;
select * from complaints;

-- Q1: All unpaid / overdue bills with consumer name
SELECT b.bill_number,
    c.full_name,
    c.phone,
    b.units_consumed,
    b.total_amount,
    b.due_date,
    b.status
FROM bills b
JOIN consumers c ON b.consumer_id = c.consumer_id
WHERE b.status IN ('Unpaid', 'Overdue');
 
 
-- Q2: Total collection this month
SELECT
    SUM(amount_paid) AS total_collected,
    COUNT(*)         AS total_payments
FROM payments
WHERE status = 'Success'    
  AND MONTH(payment_date) = MONTH(CURDATE())
  AND YEAR(payment_date)  = YEAR(CURDATE());
 
-- Q3: Consumer's full bill history
SELECT
    b.bill_number,
    b.bill_month,
    b.bill_year,
    b.units_consumed,
    b.total_amount,
    b.status,
    p.amount_paid,
    p.payment_mode
FROM bills b
LEFT JOIN payments p ON b.bill_id = p.bill_id
WHERE b.consumer_id = 1 
ORDER BY b.bill_year DESC, b.bill_month DESC;
 
 
-- Q4: Consumers who have NOT paid this month
SELECT
    c.consumer_no,
    c.full_name,
    c.phone,
    b.total_amount,
    b.due_date
FROM bills b
JOIN consumers c ON b.consumer_id = c.consumer_id
WHERE b.bill_month = MONTH(CURDATE())
  AND b.bill_year  = 2025
  AND b.status != 'Paid';
 
 -- Q5: Top consumers by units consumed (highest first)
SELECT
    c.consumer_no,
    c.full_name,
    c.city,
    c.connection_type,
    SUM(b.units_consumed) AS total_units
FROM bills b
JOIN consumers c ON b.consumer_id = c.consumer_id
GROUP BY b.consumer_id
ORDER BY total_units DESC
LIMIT 10;
 
-- Q6: Monthly revenue report (how much was collected each month)
SELECT
    bill_year AS year,
    bill_month AS month,
    COUNT(*)   AS total_bills,
    SUM(total_amount) AS total_billed,
    SUM(CASE WHEN status = 'Paid' THEN total_amount ELSE 0 END) AS total_collected,
    SUM(CASE WHEN status != 'Paid' THEN total_amount ELSE 0 END) AS total_pending
FROM bills
GROUP BY bill_year, bill_month
ORDER BY bill_year, bill_month DESC;