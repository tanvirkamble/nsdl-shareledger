/*
  0. Validation: Reject transfer if the certificate is marked 'cancelled'.
  1. Certificate update: Assign new owner (shareholder), set origin to 'transfer',
     and link the transaction ID.
  2. Decrease shares from the from_shareholder; remove shareholding row if shares
     drop to zero or below.
  3. Increase shares for the to_shareholder; insert new shareholding row if none exists.
  4. Recalculate total shares for both involved shareholders.
  5. Update the active status flag for both shareholders based on their total shares.
*/

DROP TRIGGER IF EXISTS trg_update_shareholdings_after_transaction ON data.transactions;

CREATE OR REPLACE FUNCTION data.update_shareholdings_after_transaction()
RETURNS TRIGGER AS $$
DECLARE
  cert_status TEXT;
BEGIN
  IF TG_OP = 'INSERT' THEN

    -- 0. Validation: Check if the certificate is cancelled to block invalid transfers
    SELECT status INTO cert_status
    FROM data.certificates
    WHERE id = NEW.certificate_id;

    IF cert_status = 'cancelled' THEN
      RAISE EXCEPTION 'Transaction rejected: Certificate ID % is cancelled and cannot be transferred.', NEW.certificate_id;
    END IF;

    -- 1. Update certificate owner to 'to_shareholder_id', mark origin as 'transfer',
    --    and link this transaction ID
    UPDATE data.certificates
    SET shareholder_id = NEW.to_shareholder_id,
        origin_type = 'transfer',
        transaction_id = NEW.id
    WHERE id = NEW.certificate_id;

    -- 2. Decrease shares from 'from_shareholder_id', delete shareholding if shares <= 0
    IF NEW.from_shareholder_id IS NOT NULL THEN
      UPDATE data.shareholdings
      SET total_shares = COALESCE(total_shares, 0) - NEW.num_shares
      WHERE shareholder_id = NEW.from_shareholder_id
        AND company_id = NEW.company_id;

      DELETE FROM data.shareholdings
      WHERE shareholder_id = NEW.from_shareholder_id
        AND company_id = NEW.company_id
        AND total_shares <= 0;
    END IF;

    -- 3. Increase shares for 'to_shareholder_id'; insert shareholding row if missing
    UPDATE data.shareholdings
    SET total_shares = COALESCE(total_shares, 0) + NEW.num_shares
    WHERE shareholder_id = NEW.to_shareholder_id
      AND company_id = NEW.company_id;

    IF NOT FOUND THEN
      INSERT INTO data.shareholdings (shareholder_id, company_id, total_shares)
      VALUES (NEW.to_shareholder_id, NEW.company_id, NEW.num_shares);
    END IF;

    -- 4. Recalculate total shares for both shareholders (from and to)
    UPDATE data.shareholders s
    SET total_shares = COALESCE((
      SELECT SUM(sh.total_shares)
      FROM data.shareholdings sh
      WHERE sh.shareholder_id = s.id
    ), 0)
    WHERE s.id IN (NEW.from_shareholder_id, NEW.to_shareholder_id);

    -- 5. Update active status flag for both shareholders based on total_shares
    UPDATE data.shareholders
    SET active = CASE
      WHEN total_shares <= 0 THEN FALSE
      ELSE TRUE
    END
    WHERE id IN (NEW.from_shareholder_id, NEW.to_shareholder_id);

  ELSE
    -- Exception for unsupported operations
    RAISE EXCEPTION 'Only INSERT operations are supported on data.transactions for this trigger';
  END IF;

  RETURN NULL;  -- AFTER trigger does not modify data row, so NULL
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_shareholdings_after_transaction
AFTER INSERT ON data.transactions
FOR EACH ROW
EXECUTE FUNCTION data.update_shareholdings_after_transaction();
