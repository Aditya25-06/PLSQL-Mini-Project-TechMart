-- ==================================================================
--  SCRIPT 3 OF 3 : DIRECT FUND TRANSFER DEMO (Experiments 5 and 6)
-- ==================================================================
DECLARE
  v_ok BOOLEAN;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- 1. valid transfer ---');
  transfer_funds(1002, 1003, 2000, v_ok);
  DBMS_OUTPUT.PUT_LINE('--- 2. insufficient balance ---');
  transfer_funds(1004, 1002, 999999, v_ok);
  DBMS_OUTPUT.PUT_LINE('--- 3. invalid account number ---');
  transfer_funds(1002, 9999, 100, v_ok);
  DBMS_OUTPUT.PUT_LINE('--- 4. same account ---');
  transfer_funds(1002, 1002, 100, v_ok);
  DBMS_OUTPUT.PUT_LINE(' ');
  show_accounts;
END;
/

SELECT txn_id, from_account, to_account, amount, status, remarks
FROM   fund_transactions ORDER BY txn_id;

SELECT audit_id, account_no, operation, old_balance, new_balance
FROM   account_audit ORDER BY audit_id;
