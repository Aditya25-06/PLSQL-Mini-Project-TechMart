# Tech Mart: Integrated Banking and Order Management System (PL/SQL)

A PL/SQL mini project for the PL/SQL course. A shop and its customers share one Oracle database. Customers open bank accounts, view products and stock, place orders and pay from their account balance.

## Features
- Account creation with minimum-balance validation (Experiment 1)
- Low-stock report using an explicit cursor (Experiment 2)
- Discount calculation function (Experiment 3)
- Order processing and payment procedure (Experiment 4)
- Fund transfer with exception handling (Experiment 5)
- Audit trigger that logs balance changes (Experiment 6)

## Files
| File | Purpose |
|------|---------|
| `Script1_Setup.sql` | Creates tables, sequences, procedures, function and trigger. Creates the accounts and shows product stock. Run once. |
| `Script2_Place_Order.sql` | Places an order: asks for product ID, buyer account number and quantity. Run for each order. |
| `Script3_Fund_Transfer_Demo.sql` | Demonstrates fund transfers and error handling. Optional. |
| `docs/Project_Report.docx` | Project report with DFD, ER diagram, flowchart and results. |
| `screenshots/` | Output screenshots from Oracle FreeSQL. |

## How to Run (Oracle FreeSQL)
1. Sign in at https://freesql.oracle.com and click **Connect to the Database**.
2. Paste `Script1_Setup.sql` into the worksheet and click **Run Script**. Read the output in the **DBMS Output** tab.
3. Paste `Script2_Place_Order.sql`, click **Run Script** and enter the product ID, buyer account number and quantity when asked.
4. Optionally run `Script3_Fund_Transfer_Demo.sql`.

## Sample Data
- Shop account: **1001** (Tech Mart, cannot place orders)
- Customers: **1002** Rahul Sharma, **1003** Priya Verma, **1004** Neha Gupta
- Products: **1** Laptop, **2** Wireless Mouse, **3** Keyboard, **4** Pen Drive 64GB, **5** Monitor 24 inch, **6** HDMI Cable

## Author
Aditya Mangalam | UID: 26MCC20078 | Chandigarh University
