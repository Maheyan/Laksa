-- =====================================================
-- MICRO:BIT LOAN MANAGEMENT SYSTEM DATABASE
-- Group 5 - Laksa
-- =====================================================

-- Drop existing database if exists
DROP DATABASE IF EXISTS microbit_loan_db;
CREATE DATABASE IF NOT EXISTS microbit_loan_db;
USE microbit_loan_db;

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Student Table
CREATE TABLE Student (
  student_id INT AUTO_INCREMENT PRIMARY KEY,
  matric_no  VARCHAR(20)  NOT NULL,
  full_name  VARCHAR(100) NOT NULL,
  email      VARCHAR(120) NOT NULL,
  phone      VARCHAR(20)  NULL,
  status     ENUM('ACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
             ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_student_matric_no UNIQUE (matric_no),
  CONSTRAINT uq_student_email     UNIQUE (email)
) ENGINE=InnoDB;

-- Staff Table
CREATE TABLE Staff (
  staff_id  INT AUTO_INCREMENT PRIMARY KEY,
  staff_no  VARCHAR(20)  NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  email     VARCHAR(120) NOT NULL,
  role      ENUM('ADMIN','LIBRARIAN','ASSISTANT') NOT NULL DEFAULT 'ASSISTANT',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
             ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_staff_staff_no UNIQUE (staff_no),
  CONSTRAINT uq_staff_email    UNIQUE (email)
) ENGINE=InnoDB;

-- DeviceModel (acts as DeviceType)
CREATE TABLE DeviceModel (
  model_id      INT AUTO_INCREMENT PRIMARY KEY,
  model_name    VARCHAR(80) NOT NULL,
  manufacturer  VARCHAR(80) NULL,
  kit_type      VARCHAR(80) NULL,
  max_loan_days INT NOT NULL DEFAULT 7,
  notes         VARCHAR(255) NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_model_name UNIQUE (model_name)
) ENGINE=InnoDB;

-- Location Table (for device locations)
CREATE TABLE Location (
  location_id   INT AUTO_INCREMENT PRIMARY KEY,
  location_code VARCHAR(20)  NOT NULL,
  name          VARCHAR(100) NOT NULL,
  description   VARCHAR(255) NULL,
  CONSTRAINT uq_location_code UNIQUE (location_code)
) ENGINE=InnoDB;

-- Device Table
CREATE TABLE Device (
  device_id   INT AUTO_INCREMENT PRIMARY KEY,
  model_id    INT NOT NULL,
  asset_tag   VARCHAR(30) NOT NULL,
  serial_no   VARCHAR(60) NOT NULL,
  `condition` ENUM('NEW','GOOD','FAIR','DAMAGED','LOST') NOT NULL DEFAULT 'GOOD',
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  location_id INT NULL,
  purchase_date DATE NULL,
  purchase_cost DECIMAL(10,2) NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP
              ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_device_asset_tag UNIQUE (asset_tag),
  CONSTRAINT uq_device_serial    UNIQUE (serial_no),
  CONSTRAINT fk_device_model
    FOREIGN KEY (model_id) REFERENCES DeviceModel(model_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_device_location
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
    ON UPDATE RESTRICT ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- RESERVATION SYSTEM (Student ↔ DeviceModel)
-- =====================================================

CREATE TABLE Reservation (
  reservation_id        INT AUTO_INCREMENT PRIMARY KEY,
  student_id            INT NOT NULL,
  model_id              INT NOT NULL,
  requested_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  priority              INT NOT NULL DEFAULT 1,
  status                ENUM('PENDING','FULFILLED','CANCELLED','EXPIRED')
                        NOT NULL DEFAULT 'PENDING',
  fulfilled_loan_id     BIGINT NULL, 
  expire_at             DATETIME NULL,
  notes                 VARCHAR(255) NULL,
  cancelled_by_staff_id INT NULL,
  cancelled_at          DATETIME NULL,
  CONSTRAINT fk_reservation_student
    FOREIGN KEY (student_id) REFERENCES Student(student_id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT fk_reservation_model
    FOREIGN KEY (model_id)   REFERENCES DeviceModel(model_id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT fk_reservation_cancelled_by
    FOREIGN KEY (cancelled_by_staff_id) REFERENCES Staff(staff_id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  CONSTRAINT ck_reservation_priority CHECK (priority BETWEEN 1 AND 10)
) ENGINE=InnoDB;

-- =====================================================
-- LOAN SYSTEM
-- Loan (header) + LoanItem (per device)
-- =====================================================

-- Loan header table (one per borrowing transaction)
CREATE TABLE Loan (
  loan_id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id           INT NOT NULL,
  reservation_id       INT NULL,
  approved_by_staff_id INT NOT NULL,
  closed_by_staff_id   INT NULL,
  loaned_at            DATETIME NOT NULL,
  due_at               DATETIME NOT NULL,
  status               ENUM('OPEN','CLOSED','OVERDUE')
                       NOT NULL DEFAULT 'OPEN',
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           DATETIME DEFAULT CURRENT_TIMESTAMP
                       ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_loan_student
    FOREIGN KEY (student_id) REFERENCES Student(student_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_loan_reservation
    FOREIGN KEY (reservation_id) REFERENCES Reservation(reservation_id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  CONSTRAINT fk_loan_approved_by
    FOREIGN KEY (approved_by_staff_id) REFERENCES Staff(staff_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_loan_closed_by
    FOREIGN KEY (closed_by_staff_id) REFERENCES Staff(staff_id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  CONSTRAINT ck_due_after_loan CHECK (due_at > loaned_at)
) ENGINE=InnoDB;

-- LoanItem (many devices per Loan)
CREATE TABLE LoanItem (
  loan_item_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  loan_id          BIGINT NOT NULL,
  device_id        INT NOT NULL,
  returned_at      DATETIME NULL,
  return_condition ENUM('GOOD','FAIR','DAMAGED','LOST') NULL,
  fine_amount      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  notes            VARCHAR(255) NULL,
  CONSTRAINT fk_loanitem_loan
    FOREIGN KEY (loan_id) REFERENCES Loan(loan_id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT fk_loanitem_device
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_return_cond_if_returned
    CHECK (returned_at IS NULL OR return_condition IS NOT NULL)
) ENGINE=InnoDB;

-- =====================================================
-- ACCESSORIES (Borrowable items + mapping to devices)
-- =====================================================

CREATE TABLE Accessory (
  accessory_id   INT AUTO_INCREMENT PRIMARY KEY,
  accessory_name VARCHAR(100) NOT NULL,
  description    VARCHAR(255) NULL,
  is_borrowable  BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT uq_accessory_name UNIQUE (accessory_name)
) ENGINE=InnoDB;

CREATE TABLE DeviceAccessory (
  device_id    INT NOT NULL,
  accessory_id INT NOT NULL,
  PRIMARY KEY (device_id, accessory_id),
  CONSTRAINT fk_da_device
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT fk_da_accessory
    FOREIGN KEY (accessory_id) REFERENCES Accessory(accessory_id)
    ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- MAINTENANCE WINDOWS
-- =====================================================

CREATE TABLE Maintenance (
  maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
  device_id      INT NOT NULL,
  maint_start    DATETIME NOT NULL,
  maint_end      DATETIME NOT NULL,
  description    VARCHAR(255) NULL,
  status         ENUM('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED')
                 NOT NULL DEFAULT 'SCHEDULED',
  CONSTRAINT fk_maintenance_device
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT ck_maint_interval CHECK (maint_end > maint_start)
) ENGINE=InnoDB;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Device indexes
CREATE INDEX ix_device_model_id    ON Device(model_id);
CREATE INDEX ix_device_condition   ON Device(`condition`);
CREATE INDEX ix_device_active      ON Device(is_active);
CREATE INDEX ix_device_location    ON Device(location_id);

-- Loan indexes
CREATE INDEX ix_loan_student       ON Loan(student_id);
CREATE INDEX ix_loan_status        ON Loan(status);
CREATE INDEX ix_loan_due_at        ON Loan(due_at);
CREATE INDEX ix_loan_loaned_at     ON Loan(loaned_at);

-- LoanItem indexes
CREATE INDEX ix_loanitem_device    ON LoanItem(device_id);
CREATE INDEX ix_loanitem_returned  ON LoanItem(returned_at);
CREATE INDEX ix_loanitem_condition ON LoanItem(return_condition);

-- Reservation indexes
CREATE INDEX ix_reservation_student  ON Reservation(student_id);
CREATE INDEX ix_reservation_model    ON Reservation(model_id);
CREATE INDEX ix_reservation_status   ON Reservation(status);
CREATE INDEX ix_reservation_priority ON Reservation(priority);

-- Maintenance indexes
CREATE INDEX ix_maintenance_device   ON Maintenance(device_id);
CREATE INDEX ix_maintenance_period   ON Maintenance(maint_start, maint_end);

-- =====================================================
-- SAMPLE DATA
-- =====================================================

-- Students
INSERT INTO Student (matric_no, full_name, email, phone, status) VALUES
('A25MJ4015','Md Maheyan Islam','mdmaheyanislam@graduate.utm.my','01126127425','ACTIVE'),
('A25MJ4014','Md Foysal','foysal@graduate.utm.my','01139652021','ACTIVE'),
('A25MJ4012','Mahmudul Hoque Sharif','mahmudulhoquesharif@graduate.utm.my','0175177491','ACTIVE'),
('A25MJ4009','Faiaz Nazeef','faiaznazeef@graduate.utm.my','0173215171','SUSPENDED'),
('A25MJ4016','Md Mridul Hasan Emon','mdemon@graduate.utm.my','0108899766','ACTIVE');

-- Staff
INSERT INTO Staff (staff_no, full_name, email, role) VALUES
('T-0001','Pn. Farah Karim','farah.karim@utm.my','LIBRARIAN'),
('T-0002','Encik Hafiz','hafiz@utm.my','ASSISTANT'),
('T-0003','Ms. Amanda Lee','amanda.lee@utm.my','ADMIN'),
('T-0004','Mr. Zulkifli','zulkifli@utm.my','ASSISTANT'),
('T-0005','Dr. Suresh','suresh@utm.my','LIBRARIAN');

-- DeviceModels (Device Types)
INSERT INTO DeviceModel (model_name, manufacturer, kit_type, max_loan_days, notes) VALUES
('micro:bit V2 Board','BBC','Board',7,'Basic standalone board'),
('micro:bit V2 Starter Pack','BBC','Starter Kit',7,'With battery holder & USB'),
('micro:bit V2 Inventor Kit','Kitronik','Inventor',14,'Includes components board'),
('micro:bit V1 Legacy','BBC','Legacy',7,'Older revision'),
('micro:bit V2 STEM Lab Kit','DFRobot','STEM Kit',21,'Extended lesson modules'),
('micro:bit V2 Smart Home Kit','Elecfreaks','IoT Kit',14,'IoT sensors included'),
('micro:bit V2 Robotics Kit','Waveshare','Robotics',14,'Motors and wheels included');

-- Locations
INSERT INTO Location (location_code, name, description) VALUES
('LAB-01','IoT Lab 1','Main teaching laboratory'),
('LAB-02','IoT Lab 2','Project laboratory'),
('STORE','Equipment Store','Central storage room');

-- Devices
INSERT INTO Device (model_id, asset_tag, serial_no, `condition`, is_active, location_id, purchase_date, purchase_cost) VALUES
(1,'MB-UTM-0001','SN-001','GOOD',   TRUE,  1,'2024-01-15',150.00),
(1,'MB-UTM-0002','SN-002','GOOD',   TRUE,  1,'2024-01-15',150.00),
(2,'MB-UTM-0003','SN-003','NEW',    TRUE,  2,'2024-02-20',250.00),
(3,'MB-UTM-0004','SN-004','FAIR',   TRUE,  1,'2023-12-10',450.00),
(4,'MB-UTM-0005','SN-005','DAMAGED',FALSE, 3,'2023-06-15',120.00),
(2,'MB-UTM-0006','SN-006','GOOD',   TRUE,  2,'2024-03-01',250.00),
(5,'MB-UTM-0007','SN-007','NEW',    TRUE,  2,'2024-04-10',550.00),
(6,'MB-UTM-0008','SN-008','GOOD',   TRUE,  3,'2024-04-15',380.00),
(7,'MB-UTM-0009','SN-009','NEW',    TRUE,  1,'2024-05-01',420.00),
(1,'MB-UTM-0010','SN-010','GOOD',   TRUE,  3,'2024-05-10',150.00);

-- Reservations
INSERT INTO Reservation (student_id, model_id, priority, status, notes) VALUES
-- Student 1 reserves multiple models
(1, 2, 1, 'PENDING',   'Need for upcoming project'),
(1, 3, 2, 'PENDING',   'Alternative if starter pack not available'),
(1, 6, 3, 'PENDING',   'For IoT experiments'),
-- Student 2 reserves multiple models
(2, 1, 1, 'FULFILLED', 'Basic board for learning'),
(2, 5, 2, 'PENDING',   'For STEM lab work'),
-- Student 3 reserves multiple models
(3, 2, 1, 'PENDING',   'Starter pack preferred'),
(3, 7, 2, 'PENDING',   'Robotics project requirement'),
-- Multiple students reserve same model
(5, 2, 1, 'PENDING',   'Group project need'),
(4, 2, 1, 'PENDING',   'Individual learning');

-- Loans (headers)
INSERT INTO Loan
(student_id, reservation_id, approved_by_staff_id, closed_by_staff_id, loaned_at, due_at, status) VALUES
-- Loan 1: Open, multi-device
(1, NULL, 1, NULL,
 NOW(),
 DATE_ADD(NOW(), INTERVAL 7 DAY),
 'OPEN'),

-- Loan 2: Overdue, multi-device
(2, 4, 2, NULL,
 DATE_SUB(NOW(), INTERVAL 10 DAY),
 DATE_SUB(NOW(), INTERVAL 3 DAY),
 'OVERDUE'),

-- Loan 3: Closed, multiple returned items with fines (GOOD)
(3, NULL, 5, 5,
 DATE_SUB(NOW(), INTERVAL 20 DAY),
 DATE_SUB(NOW(), INTERVAL 13 DAY),
 'CLOSED'),

-- Loan 4: Open, single device
(4, NULL, 4, NULL,
 DATE_SUB(NOW(), INTERVAL 5 DAY),
 DATE_ADD(NOW(), INTERVAL 2 DAY),
 'OPEN'),

-- Loan 5: Closed, damaged returns
(5, NULL, 1, 1,
 DATE_SUB(NOW(), INTERVAL 30 DAY),
 DATE_SUB(NOW(), INTERVAL 23 DAY),
 'CLOSED'),

-- Loan 6: Another closed loan with starter pack
(1, NULL, 2, 2,
 DATE_SUB(NOW(), INTERVAL 15 DAY),
 DATE_SUB(NOW(), INTERVAL 8 DAY),
 'CLOSED');

-- LoanItems (devices per loan)
INSERT INTO LoanItem
(loan_id, device_id, returned_at, return_condition, fine_amount, notes) VALUES

-- Loan 1: open, not returned yet
(1, 1, NULL, NULL, 0.00, 'Primary board'),
(1, 2, NULL, NULL, 0.00, 'Spare board'),

-- Loan 2: overdue, not returned yet
(2, 3, NULL, NULL, 0.00, 'Starter pack for project'),
(2, 4, NULL, NULL, 0.00, 'Inventor kit'),

-- Loan 3: closed, GOOD returns with fines
(3, 6, DATE_SUB(NOW(), INTERVAL 12 DAY), 'GOOD', 1.50, 'Returned slightly late'),
(3, 7, DATE_SUB(NOW(), INTERVAL 12 DAY), 'GOOD', 2.00, 'Late return'),
(3, 3, DATE_SUB(NOW(), INTERVAL 12 DAY), 'GOOD', 1.00, 'Late but in good condition'),

-- Loan 4: open, not returned
(4, 8, NULL, NULL, 0.00, 'Smart home kit in use'),

-- Loan 5: closed, damaged returns
(5, 5, DATE_SUB(NOW(), INTERVAL 25 DAY), 'DAMAGED', 10.00, 'Minor damage'),
(5, 2, DATE_SUB(NOW(), INTERVAL 24 DAY), 'DAMAGED', 15.00, 'Major damage to starter pack'),

-- Loan 6: closed, GOOD return for starter pack
(6, 6, DATE_SUB(NOW(), INTERVAL 7 DAY), 'GOOD', 0.75, 'Late return for starter pack');

-- Link fulfilled reservation (example)
UPDATE Reservation
SET fulfilled_loan_id = 2
WHERE reservation_id = 4;

-- Accessories
INSERT INTO Accessory (accessory_name, description, is_borrowable) VALUES
('USB Cable','Standard USB cable for micro:bit', TRUE),
('Battery Pack','AA battery holder pack', TRUE),
('Sensor Kit','Assorted sensors for experiments', TRUE),
('Mounting Plate','Mounting plate for robotics kit', TRUE);

-- DeviceAccessory mappings
INSERT INTO DeviceAccessory (device_id, accessory_id) VALUES
(1, 1), -- SN-001 with USB Cable
(1, 2), -- SN-001 with Battery Pack
(2, 2), -- SN-002 with Battery Pack
(3, 1), -- SN-003 with USB Cable
(3, 3), -- SN-003 with Sensor Kit
(7, 3), -- SN-007 with Sensor Kit
(9, 4); -- SN-009 with Mounting Plate

-- Maintenance windows
INSERT INTO Maintenance (device_id, maint_start, maint_end, description, status) VALUES
(3,
 DATE_SUB(NOW(), INTERVAL 4 DAY),
 DATE_ADD(NOW(), INTERVAL 1 DAY),
 'Check sensors and connections',
 'IN_PROGRESS'),

(1,
 DATE_SUB(NOW(), INTERVAL 30 DAY),
 DATE_SUB(NOW(), INTERVAL 25 DAY),
 'Initial inspection',
 'COMPLETED'),

(8,
 DATE_SUB(NOW(), INTERVAL 3 DAY),
 DATE_ADD(NOW(), INTERVAL 3 DAY),
 'Firmware update',
 'IN_PROGRESS');

-- =====================================================
-- DATABASE INTEGRITY REPORT
-- =====================================================

SELECT 'Database Statistics' AS Report;

SELECT 'Total Students'        AS Metric, COUNT(*) AS Count FROM Student
UNION ALL
SELECT 'Total Staff',                 COUNT(*) FROM Staff
UNION ALL
SELECT 'Total Device Models',         COUNT(*) FROM DeviceModel
UNION ALL
SELECT 'Total Devices',               COUNT(*) FROM Device
UNION ALL
SELECT 'Total Locations',             COUNT(*) FROM Location
UNION ALL
SELECT 'Active Loans (OPEN)',         COUNT(*) FROM Loan WHERE status = 'OPEN'
UNION ALL
SELECT 'Overdue Loans',               COUNT(*) FROM Loan WHERE status = 'OVERDUE'
UNION ALL
SELECT 'Pending Reservations',        COUNT(*) FROM Reservation WHERE status = 'PENDING'
UNION ALL
SELECT 'Total Accessories',           COUNT(*) FROM Accessory
UNION ALL
SELECT 'Total Maintenance Windows',   COUNT(*) FROM Maintenance;

-- =====================================================
-- TASK 2: WEEK 3–4 – BASIC SQL QUERIES
-- =====================================================

-- Q1: List all students with their status
SELECT 
    student_id,
    matric_no,
    full_name,
    email,
    status
FROM Student
ORDER BY full_name;

-- Q2: List all active devices with model, condition, and location
SELECT
    d.device_id,
    d.serial_no,
    d.asset_tag,
    dm.model_name,
    d.`condition`,
    d.is_active,
    loc.name AS location_name
FROM Device d
JOIN DeviceModel dm ON d.model_id = dm.model_id
LEFT JOIN Location loc ON d.location_id = loc.location_id
WHERE d.is_active = TRUE
ORDER BY dm.model_name, d.serial_no;

-- Q3: Show all pending reservations with student and model details
SELECT
    r.reservation_id,
    s.full_name AS student_name,
    dm.model_name AS device_model,
    r.requested_at,
    r.priority,
    r.status
FROM Reservation r
JOIN Student s    ON r.student_id = s.student_id
JOIN DeviceModel dm ON r.model_id = dm.model_id
WHERE r.status = 'PENDING'
ORDER BY r.requested_at DESC, r.priority ASC;

-- Q4: Count how many physical devices exist for each model
SELECT
    dm.model_name,
    COUNT(d.device_id) AS total_devices
FROM DeviceModel dm
LEFT JOIN Device d ON dm.model_id = d.model_id
GROUP BY dm.model_name
ORDER BY total_devices DESC, dm.model_name;

-- Q5: List all currently OPEN loans with borrower and due date
SELECT
    l.loan_id,
    s.full_name AS student_name,
    l.loaned_at,
    l.due_at,
    l.status
FROM Loan l
JOIN Student s ON l.student_id = s.student_id
WHERE l.status = 'OPEN'
ORDER BY l.due_at;

-- Q6: Find students who currently have more than one device on loan (open loans only)
SELECT
    s.full_name AS student_name,
    COUNT(DISTINCT li.loan_item_id) AS devices_on_loan
FROM Loan l
JOIN LoanItem li ON l.loan_id = li.loan_id
JOIN Student s   ON l.student_id = s.student_id
WHERE l.status = 'OPEN'
  AND li.returned_at IS NULL
GROUP BY s.student_id, s.full_name
HAVING COUNT(DISTINCT li.loan_item_id) > 1
ORDER BY devices_on_loan DESC;

-- Q7: Show total fines per student (for all returned items)
SELECT
    s.full_name AS student_name,
    SUM(li.fine_amount) AS total_fines
FROM Student s
JOIN Loan l     ON s.student_id = l.student_id
JOIN LoanItem li ON l.loan_id = li.loan_id
WHERE li.returned_at IS NOT NULL
GROUP BY s.student_id, s.full_name
HAVING SUM(li.fine_amount) > 0
ORDER BY total_fines DESC;

-- Q8: Find the most frequently loaned device models
SELECT
    dm.model_name,
    COUNT(li.loan_item_id) AS times_loaned
FROM LoanItem li
JOIN Device d      ON li.device_id = d.device_id
JOIN DeviceModel dm ON d.model_id = dm.model_id
GROUP BY dm.model_name
ORDER BY times_loaned DESC, dm.model_name;

-- =====================================================
-- TASK 3: WEEK 5–6 – RELATIONAL ALGEBRA → SQL QUERIES
-- =====================================================

-- 1. List all currently loaned devices with student, approving staff, due date, serial, device type
SELECT 
    s.full_name AS student_name,
    d.serial_no AS device_serial,
    dm.model_name AS device_type,
    l.due_at,
    st.full_name AS staff_name
FROM Loan l
JOIN LoanItem li   ON l.loan_id = li.loan_id
JOIN Device d      ON li.device_id = d.device_id
JOIN DeviceModel dm ON d.model_id = dm.model_id
JOIN Student s     ON l.student_id = s.student_id
JOIN Staff st      ON l.approved_by_staff_id = st.staff_id
WHERE l.status = 'OPEN';

-- 2. List overdue loans with devices (comma-separated) and days late
SELECT 
    s.full_name AS student_name,
    GROUP_CONCAT(DISTINCT d.serial_no ORDER BY d.serial_no SEPARATOR ', ') AS devices,
    l.due_at,
    DATEDIFF(CURDATE(), DATE(l.due_at)) AS days_late
FROM Loan l
JOIN LoanItem li ON l.loan_id = li.loan_id
JOIN Device d    ON li.device_id = d.device_id
JOIN Student s   ON l.student_id = s.student_id
WHERE l.due_at < NOW()
  AND li.returned_at IS NULL
GROUP BY l.loan_id, s.full_name, l.due_at;

-- 3. Produce one column item_name listing all borrowable items (devices + accessories)
SELECT
    d.serial_no AS item_name
FROM Device d
UNION
SELECT
    a.accessory_name AS item_name
FROM Accessory a
WHERE a.is_borrowable = TRUE;

-- 4. List device serial numbers that were never part of any loan
SELECT 
    d.serial_no
FROM Device d
LEFT JOIN LoanItem li ON d.device_id = li.device_id
WHERE li.device_id IS NULL;

-- 5. Find students who have borrowed at least one device and have at least one return with positive fine
SELECT 
    s.full_name,
    SUM(li.fine_amount) AS total_fines
FROM Student s
JOIN Loan l     ON s.student_id = l.student_id
JOIN LoanItem li ON l.loan_id = li.loan_id
WHERE li.returned_at IS NOT NULL
  AND li.fine_amount > 0
GROUP BY s.student_id, s.full_name;

-- 6. Generate all (device type × location) pairs with zero devices present
SELECT
    dm.model_name AS device_type,
    loc.name      AS location_name
FROM DeviceModel dm
CROSS JOIN Location loc
LEFT JOIN Device d 
       ON d.model_id    = dm.model_id
      AND d.location_id = loc.location_id
GROUP BY dm.model_name, loc.name
HAVING COUNT(d.device_id) = 0;

-- 7. For every device, show its serial, type, and comma-separated list of its accessories
SELECT
    d.serial_no AS serial,
    dm.model_name AS device_type,
    GROUP_CONCAT(a.accessory_name ORDER BY a.accessory_name SEPARATOR ', ') AS accessories
FROM Device d
JOIN DeviceModel dm ON d.model_id = dm.model_id
LEFT JOIN DeviceAccessory da ON d.device_id = da.device_id
LEFT JOIN Accessory a        ON da.accessory_id = a.accessory_id
GROUP BY d.device_id, d.serial_no, dm.model_name;

-- 8. List any device that has an active loan period overlapping a maintenance window
SELECT
    d.serial_no,
    l.loan_id,
    m.maintenance_id,
    l.loaned_at,
    l.due_at,
    m.maint_start,
    m.maint_end
FROM Loan l
JOIN LoanItem li ON l.loan_id = li.loan_id
JOIN Device d    ON li.device_id = d.device_id
JOIN Maintenance m ON d.device_id = m.device_id
WHERE l.status IN ('OPEN','OVERDUE','CLOSED')
  AND l.loaned_at <= m.maint_end
  AND l.due_at   >= m.maint_start;

-- 9. For each staff member, count the number of loans they approved/processed, sort by most first
SELECT
    st.full_name AS staff_name,
    COUNT(*) AS loan_actions
FROM Staff st
LEFT JOIN (
    SELECT approved_by_staff_id AS staff_id FROM Loan
    UNION ALL
    SELECT closed_by_staff_id AS staff_id FROM Loan WHERE closed_by_staff_id IS NOT NULL
) x ON st.staff_id = x.staff_id
GROUP BY st.staff_id, st.full_name
ORDER BY loan_actions DESC;

-- 10. Compute the average fine amount grouped by (device type, return condition), min 3 returns
SELECT
    dm.model_name AS device_type,
    li.return_condition,
    AVG(li.fine_amount) AS avg_fine,
    COUNT(*) AS total_returns
FROM LoanItem li
JOIN Loan l      ON li.loan_id = l.loan_id
JOIN Device d    ON li.device_id = d.device_id
JOIN DeviceModel dm ON d.model_id = dm.model_id
WHERE li.returned_at IS NOT NULL
GROUP BY dm.model_name, li.return_condition
HAVING COUNT(*) >= 3;
