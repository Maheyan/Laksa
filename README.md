# 🔌 Micro:bit IoT Device Loan Management System

[![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue.svg)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-Academic-green.svg)](#license)
[![UTM](https://img.shields.io/badge/UTM-SCST1143-red.svg)](https://www.utm.my/)

A comprehensive relational database solution for managing the borrowing and inventory tracking of Micro:bit IoT devices within an academic faculty environment.

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Database Schema](#-database-schema)
- [Entity Relationship Diagram](#-entity-relationship-diagram)
- [Installation](#-installation)
- [Usage](#-usage)
- [Sample Queries](#-sample-queries)
- [User Roles & Access Control](#-user-roles--access-control)
- [Project Structure](#-project-structure)
- [Team Members](#-team-members)
- [License](#-license)

## 🎯 Overview

The **Micro:bit Loan Management System** (Laksa) is a relational database designed to automate the borrowing lifecycle of IoT devices within an academic institution. It replaces manual logbook-based tracking with a centralized, normalized database that ensures data integrity, reduces administrative workload, and provides accurate reporting capabilities.

### Problem Statement

The manual/semi-automated loan management process faces several challenges:

- **Data Redundancy**: Student information repeated across multiple transactions
- **Inconsistency**: Device statuses recorded inconsistently (e.g., 'GOOD' vs 'Good')
- **Slow Retrieval**: Time-consuming searches for device history
- **Missing Audit Trail**: Difficulty tracking staff approvals and actions

### Solution

This system provides:

- ✅ Centralized device inventory management
- ✅ Automated loan tracking with due date management
- ✅ Priority-based reservation system
- ✅ Fine calculation for overdue returns
- ✅ Maintenance scheduling and tracking
- ✅ Complete audit trail for all transactions

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Student Management** | Register and manage student profiles with status tracking |
| **Device Inventory** | Track physical devices with model specifications, conditions, and locations |
| **Loan Processing** | Create, approve, and close loan transactions with multiple devices |
| **Reservation System** | Priority-based booking for specific device models |
| **Fine Management** | Automatic fine tracking for late returns and damaged items |
| **Maintenance Tracking** | Schedule and monitor device maintenance windows |
| **Accessory Management** | Track accessories bundled with devices |
| **Reporting** | Generate comprehensive reports on inventory, loans, and fines |

## 🗄️ Database Schema

The database consists of **11 interconnected tables** following Third Normal Form (3NF) and BCNF:

### Core Tables

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `Student` | Student registration and status | `student_id` |
| `Staff` | Staff members and their roles | `staff_id` |
| `DeviceModel` | Device type specifications | `model_id` |
| `Device` | Physical device instances | `device_id` |
| `Location` | Storage locations | `location_id` |

### Transaction Tables

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `Loan` | Loan transaction headers | `loan_id` |
| `LoanItem` | Individual devices in a loan | `loan_item_id` |
| `Reservation` | Device model reservations | `reservation_id` |

### Supporting Tables

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `Accessory` | Borrowable accessories | `accessory_id` |
| `DeviceAccessory` | Device-Accessory mapping | `(device_id, accessory_id)` |
| `Maintenance` | Maintenance schedules | `maintenance_id` |

## 📊 Entity Relationship Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   STUDENT   │────────▶│    LOAN     │◀────────│    STAFF    │
│             │   1:N   │             │   N:1   │             │
└─────────────┘         └──────┬──────┘         └─────────────┘
      │                        │                       │
      │ 1:N                    │ 1:N                   │
      ▼                        ▼                       │
┌─────────────┐         ┌─────────────┐                │
│ RESERVATION │         │  LOANITEM   │                │
│             │         │             │                │
└──────┬──────┘         └──────┬──────┘                │
       │                       │                       │
       │ N:1                   │ N:1                   │
       ▼                       ▼                       │
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ DEVICEMODEL │◀────────│   DEVICE    │────────▶│  LOCATION   │
│             │   1:N   │             │   N:1   │             │
└─────────────┘         └──────┬──────┘         └─────────────┘
                               │
              ┌────────────────┼────────────────┐
              │ 1:N            │ M:N            │
              ▼                ▼                │
       ┌─────────────┐  ┌─────────────┐         │
       │ MAINTENANCE │  │DEVICEACCESS.│─────────┘
       │             │  │             │
       └─────────────┘  └──────┬──────┘
                               │ N:1
                               ▼
                        ┌─────────────┐
                        │  ACCESSORY  │
                        │             │
                        └─────────────┘
```

## 🚀 Installation

### Prerequisites

- MySQL 8.0 or higher
- MySQL Workbench (recommended) or any MySQL client

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/Maheyan/Laksa.git
   cd Laksa
   ```

2. **Create the database**
   ```bash
   mysql -u root -p < Group_5_Laksa.sql
   ```

   Or using MySQL Workbench:
   - Open MySQL Workbench
   - Connect to your MySQL server
   - File → Open SQL Script → Select `Group_5_Laksa.sql`
   - Execute the script (⚡ icon)

3. **Verify installation**
   ```sql
   USE microbit_loan_db;
   
   SELECT 'Total Students' AS Metric, COUNT(*) AS Count FROM Student
   UNION ALL
   SELECT 'Total Devices', COUNT(*) FROM Device
   UNION ALL
   SELECT 'Active Loans', COUNT(*) FROM Loan WHERE status = 'OPEN';
   ```

## 📖 Usage

### Connecting to the Database

```sql
mysql -u root -p microbit_loan_db
```

### Common Operations

**Register a new student:**
```sql
INSERT INTO Student (matric_no, full_name, email, phone, status)
VALUES ('A25MJ9999', 'New Student', 'new.student@graduate.utm.my', '+60123456789', 'ACTIVE');
```

**Add a new device:**
```sql
INSERT INTO Device (model_id, asset_tag, serial_no, `condition`, is_active, location_id)
VALUES (1, 'UTM-IOT-011', 'SN-011', 'NEW', TRUE, 1);
```

**Create a loan:**
```sql
INSERT INTO Loan (student_id, approved_by_staff_id, loaned_at, due_at, status)
VALUES (1, 1, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), 'OPEN');
```

## 🔍 Sample Queries

### List all active devices with their model and location

```sql
SELECT
    d.serial_no,
    dm.model_name,
    d.`condition`,
    loc.name AS location_name
FROM Device d
JOIN DeviceModel dm ON d.model_id = dm.model_id
LEFT JOIN Location loc ON d.location_id = loc.location_id
WHERE d.is_active = TRUE;
```

### Show pending reservations with priority

```sql
SELECT
    s.full_name AS student_name,
    dm.model_name,
    r.requested_at,
    r.priority
FROM Reservation r
JOIN Student s ON r.student_id = s.student_id
JOIN DeviceModel dm ON r.model_id = dm.model_id
WHERE r.status = 'PENDING'
ORDER BY r.priority ASC;
```

### List students with overdue loans

```sql
SELECT
    s.full_name,
    l.due_at,
    l.status
FROM Loan l
JOIN Student s ON l.student_id = s.student_id
WHERE l.status = 'OVERDUE';
```

### Calculate total fines for each student

```sql
SELECT
    s.full_name,
    SUM(li.fine_amount) AS total_fines
FROM Student s
JOIN Loan l ON s.student_id = l.student_id
JOIN LoanItem li ON l.loan_id = li.loan_id
GROUP BY s.student_id, s.full_name
HAVING total_fines > 0;
```

### Find the most frequently loaned device models

```sql
SELECT
    dm.model_name,
    COUNT(li.loan_item_id) AS times_loaned
FROM LoanItem li
JOIN Device d ON li.device_id = d.device_id
JOIN DeviceModel dm ON d.model_id = dm.model_id
GROUP BY dm.model_name
ORDER BY times_loaned DESC;
```

## 👥 User Roles & Access Control

| Role | Description | Access Rights |
|------|-------------|---------------|
| **Administrator** | Full system control | CRUD on all data |
| **Librarian** | Inventory & Reporting | Maintain inventory, View reports |
| **Assistant** | Counter operations | Process loans, returns, reservations |
| **Student** | End-user | Read own profile, Request reservations |

### Access Matrix

| User Role | Student Data | Device Inventory | Loan Records | Reservations | Staff Data |
|-----------|--------------|------------------|--------------|--------------|------------|
| Administrator | Full CRUD | Full CRUD | Full CRUD | Full CRUD | Full CRUD |
| Librarian | Query/Report | Full CRUD | Query/Report | Query/Update | No Access |
| Assistant | Query/Update | Query/Update | Create/Update | Process/Update | No Access |
| Student | Read Own | Query Only | Read Own | Create/Read Own | No Access |

## 📁 Project Structure

```
Laksa/
├── README.md                           # This file
├── Group_5_Laksa.sql                   # Complete SQL script
├── Database_Group_Project_Final.pdf    # Project documentation
├── ER Diagram group-5(laksa).mwb       # Workbench File
└── docs/
    ├── ERD_Conceptual.png              # Conceptual ERD
    ├── ERD_Logical.png                 # Logical ERD
    └── screenshots/                    # Query output screenshots
```

## 👨‍💻 Team Members

| Name | Matric No | Role |
|------|-----------|------|
| MD MAHEYAN ISLAM | A25MJ4015 | Team Lead |
| MD FOYSAL | A25MJ4014 | Database Designer |
| MAHMUDUL HOQUE SHARIF | A25MJ4012 | SQL Developer |
| FAIAZ NAZEEF | A25MJ4009 | Documentation |
| MD MRIDUL HASAN EMON | A25MJ4016 | Testing & QA |

## 📚 Course Information

- **Course**: SCST1143-15 Database Engineering (Kejuruteraan Pengkalan Data)
- **Session**: 2025/2026 – Semester 1
- **Institution**: Universiti Teknologi Malaysia (UTM)

## 📄 License

This project is developed for academic purposes as part of the SCST1143 Database Engineering course at Universiti Teknologi Malaysia.

---

<p align="center">
  <strong>Group 5 - Laksa</strong><br>
  <em>Micro:bit IoT Device Loan Management System</em><br>
  <br>
  Made with ❤️ at UTM
</p>
