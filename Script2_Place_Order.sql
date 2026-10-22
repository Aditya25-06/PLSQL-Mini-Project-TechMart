-- ==================================================================
--  SCRIPT 2 OF 3 : PLACE AN ORDER  (can be run again and again)
--  Needs script 1 to be run first.
--  You will be asked 3 things: product ID, buyer account no, quantity.
-- ==================================================================

-- PART A : show the menu (run this first to see IDs and account numbers)
BEGIN
  show_products;
  DBMS_OUTPUT.PUT_LINE(' ');
  show_accounts(TRUE);
END;
/

-- PART B : place the order (a box will ask you for the 3 values)
BEGIN
  place_order(&Product_ID_to_order, &Buyer_Account_No, &Quantity);
END;
/

-- PART C : show what changed
BEGIN
  DBMS_OUTPUT.PUT_LINE(' ');
  show_receipts;
  DBMS_OUTPUT.PUT_LINE(' ');
  show_accounts;
  DBMS_OUTPUT.PUT_LINE(' ');
  show_products;
  DBMS_OUTPUT.PUT_LINE(' ');
  low_stock_report;
END;
/

SELECT audit_id, account_no, operation, old_balance, new_balance
FROM   account_audit ORDER BY audit_id;
