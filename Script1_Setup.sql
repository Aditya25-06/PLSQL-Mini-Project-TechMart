-- ==================================================================
--  MINI PROJECT : TECH MART - BANKING + ORDER MANAGEMENT (PL/SQL)
--  SCRIPT 1 OF 3 : SETUP  (run this ONCE, then run script 2)
--  Run with "Run Script". Read the messages in the DBMS Output tab.
-- ==================================================================

-- ---------- STEP 0: CLEAN UP (so the script can be re-run) --------
BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('ACCOUNTS','PRODUCTS','ORDERS',
                  'ORDER_DETAILS','FUND_TRANSACTIONS','ACCOUNT_AUDIT')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences
            WHERE sequence_name IN ('SEQ_ACCOUNT','SEQ_ORDER','SEQ_DETAIL',
                  'SEQ_TXN','SEQ_AUDIT')) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/

-- ---------- STEP 1: SEQUENCES AND TABLES --------------------------
CREATE SEQUENCE seq_account START WITH 1001 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_order   START WITH 5001 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_detail  START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_txn     START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_audit   START WITH 1    INCREMENT BY 1 NOCACHE;

CREATE TABLE accounts (
  account_no    NUMBER        PRIMARY KEY,
  holder_name   VARCHAR2(60)  NOT NULL,
  account_type  VARCHAR2(10)  NOT NULL
                CHECK (account_type IN ('SAVINGS','CURRENT')),
  balance       NUMBER(12,2)  NOT NULL CHECK (balance >= 0),
  opened_on     DATE          DEFAULT SYSDATE
);

CREATE TABLE products (
  product_id     NUMBER        PRIMARY KEY,
  product_name   VARCHAR2(60)  NOT NULL,
  category       VARCHAR2(30),
  unit_price     NUMBER(10,2)  NOT NULL CHECK (unit_price > 0),
  stock_qty      NUMBER        NOT NULL CHECK (stock_qty >= 0),
  reorder_level  NUMBER        DEFAULT 10 NOT NULL
);

CREATE TABLE orders (
  order_id         NUMBER       PRIMARY KEY,
  account_no       NUMBER       NOT NULL REFERENCES accounts(account_no),
  order_date       DATE         DEFAULT SYSDATE,
  total_amount     NUMBER(12,2),
  discount_amount  NUMBER(12,2),
  net_amount       NUMBER(12,2),
  payment_status   VARCHAR2(10)
);

CREATE TABLE order_details (
  detail_id   NUMBER        PRIMARY KEY,
  order_id    NUMBER        NOT NULL REFERENCES orders(order_id),
  product_id  NUMBER        NOT NULL REFERENCES products(product_id),
  quantity    NUMBER        NOT NULL CHECK (quantity > 0),
  unit_price  NUMBER(10,2)  NOT NULL,
  line_total  NUMBER(12,2)  NOT NULL
);

CREATE TABLE fund_transactions (
  txn_id        NUMBER        PRIMARY KEY,
  from_account  NUMBER,
  to_account    NUMBER,
  amount        NUMBER(12,2),
  txn_date      DATE          DEFAULT SYSDATE,
  status        VARCHAR2(10),
  remarks       VARCHAR2(100)
);

CREATE TABLE account_audit (
  audit_id     NUMBER        PRIMARY KEY,
  account_no   NUMBER,
  operation    VARCHAR2(10),
  old_balance  NUMBER(12,2),
  new_balance  NUMBER(12,2),
  changed_by   VARCHAR2(30),
  changed_on   DATE          DEFAULT SYSDATE
);

-- ---------- EXPERIMENT 6 : AUDIT TRIGGER --------------------------
CREATE OR REPLACE TRIGGER trg_account_audit
AFTER INSERT OR DELETE OR UPDATE OF balance ON accounts
FOR EACH ROW
DECLARE
  v_op VARCHAR2(10);
BEGIN
  IF INSERTING THEN
    v_op := 'INSERT';
  ELSIF UPDATING THEN
    v_op := 'UPDATE';
  ELSE
    v_op := 'DELETE';
  END IF;
  INSERT INTO account_audit (audit_id, account_no, operation,
                             old_balance, new_balance, changed_by, changed_on)
  VALUES (seq_audit.NEXTVAL, NVL(:NEW.account_no, :OLD.account_no),
          v_op, :OLD.balance, :NEW.balance, USER, SYSDATE);
END trg_account_audit;
/

-- ---------- EXPERIMENT 1 : CREATE ACCOUNT WITH VALIDATION ---------
CREATE OR REPLACE PROCEDURE create_account (
  p_name     IN VARCHAR2,
  p_type     IN VARCHAR2,
  p_initial  IN NUMBER
) IS
  v_min_balance  NUMBER;
  v_acc_no       accounts.account_no%TYPE;
  e_low_balance  EXCEPTION;
BEGIN
  IF UPPER(p_type) = 'SAVINGS' THEN
    v_min_balance := 1000;
  ELSIF UPPER(p_type) = 'CURRENT' THEN
    v_min_balance := 5000;
  ELSE
    RAISE_APPLICATION_ERROR(-20001, 'Invalid account type: ' || p_type);
  END IF;

  IF p_initial < v_min_balance THEN
    RAISE e_low_balance;
  END IF;

  v_acc_no := seq_account.NEXTVAL;
  INSERT INTO accounts (account_no, holder_name, account_type, balance)
  VALUES (v_acc_no, p_name, UPPER(p_type), p_initial);
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Account created  | A/C ' || v_acc_no || ' | ' ||
    RPAD(p_name, 20) || ' | ' || RPAD(UPPER(p_type), 8) ||
    ' | Rs.' || p_initial);
EXCEPTION
  WHEN e_low_balance THEN
    DBMS_OUTPUT.PUT_LINE('Account REJECTED | ' || p_name || ' | opening balance Rs.' ||
      p_initial || ' is below the minimum Rs.' || v_min_balance ||
      ' for a ' || UPPER(p_type) || ' account');
END create_account;
/

-- ---------- DISPLAY HELPERS ---------------------------------------
CREATE OR REPLACE PROCEDURE show_accounts (p_only_buyers IN BOOLEAN DEFAULT FALSE) IS
  v_skip NUMBER := CASE WHEN p_only_buyers THEN 1001 ELSE -1 END;
BEGIN
  DBMS_OUTPUT.PUT_LINE('-------------------- ACCOUNT LIST --------------------');
  DBMS_OUTPUT.PUT_LINE(RPAD('A/C NO', 9) || RPAD('HOLDER NAME', 26) ||
                       RPAD('TYPE', 10) || 'BALANCE (Rs.)');
  FOR r IN (SELECT account_no, holder_name, account_type, balance
            FROM accounts WHERE account_no <> v_skip ORDER BY account_no) LOOP
    DBMS_OUTPUT.PUT_LINE(RPAD(r.account_no, 9) || RPAD(r.holder_name, 26) ||
      RPAD(r.account_type, 10) || TO_CHAR(r.balance, 'FM9,99,999.00'));
  END LOOP;
END show_accounts;
/

CREATE OR REPLACE PROCEDURE show_products IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('------------------ AVAILABLE PRODUCTS ------------------');
  DBMS_OUTPUT.PUT_LINE(RPAD('ID', 5) || RPAD('PRODUCT', 20) ||
                       RPAD('PRICE (Rs.)', 14) || 'STOCK AVAILABLE');
  FOR r IN (SELECT product_id, product_name, unit_price, stock_qty
            FROM products ORDER BY product_id) LOOP
    DBMS_OUTPUT.PUT_LINE(RPAD(r.product_id, 5) || RPAD(r.product_name, 20) ||
      RPAD(TO_CHAR(r.unit_price, 'FM99,990.00'), 14) || r.stock_qty);
  END LOOP;
END show_products;
/

-- ---------- EXPERIMENT 2 : LOW STOCK REPORT (EXPLICIT CURSOR) -----
CREATE OR REPLACE PROCEDURE low_stock_report IS
  CURSOR c_low IS
    SELECT product_id, product_name, stock_qty, reorder_level
    FROM   products
    WHERE  stock_qty <= reorder_level
    ORDER  BY stock_qty;
  v_rec    c_low%ROWTYPE;
  v_count  NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=========== LOW STOCK REPORT ===========');
  DBMS_OUTPUT.PUT_LINE(RPAD('ID', 5) || RPAD('PRODUCT', 22) ||
                       RPAD('STOCK', 8) || 'REORDER LEVEL');
  OPEN c_low;
  LOOP
    FETCH c_low INTO v_rec;
    EXIT WHEN c_low%NOTFOUND;
    v_count := v_count + 1;
    DBMS_OUTPUT.PUT_LINE(RPAD(v_rec.product_id, 5) ||
      RPAD(v_rec.product_name, 22) || RPAD(v_rec.stock_qty, 8) ||
      v_rec.reorder_level);
  END LOOP;
  CLOSE c_low;
  DBMS_OUTPUT.PUT_LINE('Total products to reorder: ' || v_count);
END low_stock_report;
/

-- ---------- EXPERIMENT 3 : DISCOUNT FUNCTION ----------------------
CREATE OR REPLACE FUNCTION calc_discount (p_amount IN NUMBER)
RETURN NUMBER IS
  v_rate NUMBER := 0;
BEGIN
  IF p_amount IS NULL OR p_amount < 0 THEN
    RETURN 0;
  END IF;
  IF    p_amount >= 10000 THEN v_rate := 0.15;
  ELSIF p_amount >= 5000  THEN v_rate := 0.10;
  ELSIF p_amount >= 1000  THEN v_rate := 0.05;
  END IF;
  RETURN ROUND(p_amount * v_rate, 2);
END calc_discount;
/

-- ---------- EXPERIMENT 5 : FUND TRANSFER WITH EXCEPTIONS ----------
CREATE OR REPLACE PROCEDURE transfer_funds (
  p_from    IN  NUMBER,
  p_to      IN  NUMBER,
  p_amount  IN  NUMBER,
  p_ok      OUT BOOLEAN,
  p_remark  IN  VARCHAR2 DEFAULT 'Transfer completed',
  p_commit  IN  BOOLEAN  DEFAULT TRUE
) IS
  v_from_bal        accounts.balance%TYPE;
  v_to_bal          accounts.balance%TYPE;
  e_insufficient    EXCEPTION;
  e_same_account    EXCEPTION;
  e_invalid_amount  EXCEPTION;

  PROCEDURE log_failure (p_msg IN VARCHAR2) IS
  BEGIN
    p_ok := FALSE;
    IF p_commit THEN
      ROLLBACK;
      INSERT INTO fund_transactions (txn_id, from_account, to_account,
                                     amount, status, remarks)
      VALUES (seq_txn.NEXTVAL, p_from, p_to, p_amount, 'FAILED', p_msg);
      COMMIT;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Transfer FAILED: ' || p_msg);
  END log_failure;
BEGIN
  p_ok := FALSE;
  IF p_amount <= 0 THEN RAISE e_invalid_amount; END IF;
  IF p_from = p_to  THEN RAISE e_same_account;  END IF;

  SELECT balance INTO v_from_bal FROM accounts
  WHERE  account_no = p_from FOR UPDATE;
  SELECT balance INTO v_to_bal FROM accounts
  WHERE  account_no = p_to FOR UPDATE;

  IF v_from_bal < p_amount THEN RAISE e_insufficient; END IF;

  UPDATE accounts SET balance = balance - p_amount WHERE account_no = p_from;
  UPDATE accounts SET balance = balance + p_amount WHERE account_no = p_to;

  INSERT INTO fund_transactions (txn_id, from_account, to_account,
                                 amount, status, remarks)
  VALUES (seq_txn.NEXTVAL, p_from, p_to, p_amount, 'SUCCESS', p_remark);
  p_ok := TRUE;

  IF p_commit THEN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transfer SUCCESSFUL: Rs.' || p_amount ||
      ' moved from A/C ' || p_from || ' to A/C ' || p_to);
  END IF;
EXCEPTION
  WHEN e_invalid_amount THEN
    log_failure('Amount must be greater than zero');
  WHEN e_same_account THEN
    log_failure('Source and destination accounts cannot be same');
  WHEN e_insufficient THEN
    log_failure('Insufficient balance in account ' || p_from);
  WHEN NO_DATA_FOUND THEN
    log_failure('Invalid account number');
  WHEN OTHERS THEN
    log_failure('Unexpected error: ' || SUBSTR(SQLERRM, 1, 70));
END transfer_funds;
/

-- ---------- EXPERIMENT 4 : ORDER PROCESSING + PAYMENT -------------
CREATE OR REPLACE PROCEDURE place_order (
  p_product_id  IN NUMBER,
  p_account_no  IN NUMBER,
  p_qty         IN NUMBER
) IS
  c_shop_acc  CONSTANT NUMBER := 1001;           -- shop's own account
  v_step      VARCHAR2(20);
  v_holder    accounts.holder_name%TYPE;
  v_balance   accounts.balance%TYPE;
  v_pname     products.product_name%TYPE;
  v_price     products.unit_price%TYPE;
  v_stock     products.stock_qty%TYPE;
  v_total     NUMBER(12,2);
  v_discount  NUMBER(12,2);
  v_net       NUMBER(12,2);
  v_order_id  orders.order_id%TYPE;
  v_ok        BOOLEAN;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=============== PROCESSING ORDER ===============');
  IF p_qty IS NULL OR p_qty <= 0 THEN
    RAISE_APPLICATION_ERROR(-20010, 'Quantity must be greater than zero');
  END IF;
  IF p_account_no = c_shop_acc THEN
    RAISE_APPLICATION_ERROR(-20012, 'The shop account cannot place orders');
  END IF;

  v_step := 'Account';
  SELECT holder_name, balance INTO v_holder, v_balance
  FROM   accounts WHERE account_no = p_account_no;

  v_step := 'Product';
  SELECT product_name, unit_price, stock_qty INTO v_pname, v_price, v_stock
  FROM   products WHERE product_id = p_product_id FOR UPDATE;

  IF v_stock < p_qty THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ORDER REJECTED: only ' || v_stock || ' unit(s) of ' ||
      v_pname || ' in stock, you asked for ' || p_qty);
    RETURN;
  END IF;

  v_total    := v_price * p_qty;
  v_discount := calc_discount(v_total);          -- function of Experiment 3
  v_net      := v_total - v_discount;

  DBMS_OUTPUT.PUT_LINE('Customer        : ' || v_holder || ' (A/C ' || p_account_no || ')');
  DBMS_OUTPUT.PUT_LINE('Item ordered    : ' || v_pname || ' x ' || p_qty ||
                       ' @ Rs.' || v_price);
  DBMS_OUTPUT.PUT_LINE('Total value     : Rs.' || v_total);
  DBMS_OUTPUT.PUT_LINE('Discount        : Rs.' || v_discount);
  DBMS_OUTPUT.PUT_LINE('Amount payable  : Rs.' || v_net);
  DBMS_OUTPUT.PUT_LINE('Account balance : Rs.' || v_balance);

  IF v_balance < v_net THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ORDER REJECTED: insufficient balance. Short by Rs.' ||
                         (v_net - v_balance));
    RETURN;
  END IF;

  v_order_id := seq_order.NEXTVAL;
  INSERT INTO orders (order_id, account_no, total_amount, discount_amount,
                      net_amount, payment_status)
  VALUES (v_order_id, p_account_no, v_total, v_discount, v_net, 'PAID');

  INSERT INTO order_details (detail_id, order_id, product_id, quantity,
                             unit_price, line_total)
  VALUES (seq_detail.NEXTVAL, v_order_id, p_product_id, p_qty, v_price, v_total);

  UPDATE products SET stock_qty = stock_qty - p_qty
  WHERE  product_id = p_product_id;

  -- payment: customer account -> shop account (Experiment 5 procedure)
  transfer_funds(p_account_no, c_shop_acc, v_net, v_ok,
                 'Payment for order ' || v_order_id, FALSE);
  IF NOT v_ok THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ORDER CANCELLED: payment could not be processed');
    RETURN;
  END IF;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('PAYMENT SUCCESSFUL - Order ' || v_order_id || ' confirmed.');
  DBMS_OUTPUT.PUT_LINE('Rs.' || v_net || ' paid to shop. New balance of ' ||
                       v_holder || ': Rs.' || (v_balance - v_net));
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ORDER REJECTED: invalid ' || v_step || ' number');
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ORDER FAILED: ' || SQLERRM);
END place_order;
/

CREATE OR REPLACE PROCEDURE show_receipts IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('-------------------- ORDERS PLACED --------------------');
  DBMS_OUTPUT.PUT_LINE(RPAD('ORDER', 8) || RPAD('CUSTOMER', 22) ||
    RPAD('PRODUCT', 18) || RPAD('QTY', 5) || RPAD('PAID (Rs.)', 12) || 'STATUS');
  FOR r IN (SELECT o.order_id, a.holder_name, p.product_name, d.quantity,
                   o.net_amount, o.payment_status
            FROM orders o JOIN accounts a ON a.account_no = o.account_no
                 JOIN order_details d ON d.order_id = o.order_id
                 JOIN products p ON p.product_id = d.product_id
            ORDER BY o.order_id) LOOP
    DBMS_OUTPUT.PUT_LINE(RPAD(r.order_id, 8) || RPAD(r.holder_name, 22) ||
      RPAD(r.product_name, 18) || RPAD(r.quantity, 5) ||
      RPAD(r.net_amount, 12) || r.payment_status);
  END LOOP;
END show_receipts;
/

-- ---------- STEP 2 : INITIAL DATA ---------------------------------
INSERT INTO products VALUES (1, 'Laptop',          'Electronics', 55000,  8,  5);
INSERT INTO products VALUES (2, 'Wireless Mouse',  'Accessories',   700,  4, 10);
INSERT INTO products VALUES (3, 'Keyboard',        'Accessories',  1200, 25, 10);
INSERT INTO products VALUES (4, 'Pen Drive 64GB',  'Storage',       550,  6, 15);
INSERT INTO products VALUES (5, 'Monitor 24 inch', 'Electronics',  9500, 12,  5);
INSERT INTO products VALUES (6, 'HDMI Cable',      'Accessories',   250,  3, 10);
COMMIT;

-- ---------- STEP 3 : SHOW INITIAL ACCOUNT CREATION + PRODUCTS -----
BEGIN
  DBMS_OUTPUT.PUT_LINE('*********** STEP 1 : CREATING ACCOUNTS ***********');
  create_account('Tech Mart (Shop)', 'CURRENT', 5000);   -- A/C 1001 = shop
  create_account('Aditya Mangalam',     'SAVINGS', 25000);
  create_account('Anushka',      'CURRENT', 50000);
  create_account('Adarsh Raj',       'SAVINGS',   500);   -- rejected: below minimum
  create_account('Harsh Raj',       'SAVINGS', 10000);
  DBMS_OUTPUT.PUT_LINE(' ');
  show_accounts;
  DBMS_OUTPUT.PUT_LINE(' ');
  DBMS_OUTPUT.PUT_LINE('*********** STEP 2 : PRODUCT DETAILS ***********');
  show_products;
  DBMS_OUTPUT.PUT_LINE(' ');
  DBMS_OUTPUT.PUT_LINE('Setup complete');
END;
/
