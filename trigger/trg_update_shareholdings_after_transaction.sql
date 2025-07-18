-- "AFTER INSERT on data.transactions
--   1. Update the certificate → new owner + mark transfer
--   2. Decrease from_shareholder shareholding (and delete row if 0)
--   3. Increase to_shareholder shareholding (insert if missing)
--   4. Recalculate total_shares for both
--   5. If total_shares = 0 → set active = false"

DROP TRIGGER IF EXISTS trg_update_shareholdings_after_transaction ON data.transactions;

CREATE OR REPLACE FUNCTION data.update_shareholdings_after_transaction()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN

    -- 1. Update certificate to new owner
    UPDATE data.certificates
    SET shareholder_id = NEW.to_shareholder_id,
        origin_type = 'transfer',
        transaction_id = NEW.id
    WHERE id = NEW.certificate_id;

    -- 2. Decrease from_shareholder
    IF NEW.from_shareholder_id IS NOT NULL THEN
      UPDATE data.shareholdings
      SET total_shares = COALESCE(total_shares, 0) - NEW.num_shares
      WHERE shareholder_id = NEW.from_shareholder_id AND company_id = NEW.company_id;

      DELETE FROM data.shareholdings
      WHERE shareholder_id = NEW.from_shareholder_id AND company_id = NEW.company_id AND total_shares <= 0;
    END IF;

    -- 3. Increase to_shareholder
    UPDATE data.shareholdings
    SET total_shares = COALESCE(total_shares, 0) + NEW.num_shares
    WHERE shareholder_id = NEW.to_shareholder_id AND company_id = NEW.company_id;

    IF NOT FOUND THEN
      INSERT INTO data.shareholdings (shareholder_id, company_id, total_shares)
      VALUES (NEW.to_shareholder_id, NEW.company_id, NEW.num_shares);
    END IF;

    -- 4. Recalculate total_shares
    UPDATE data.shareholders s
    SET total_shares = COALESCE((
      SELECT SUM(sh.total_shares)
      FROM data.shareholdings sh
      WHERE sh.shareholder_id = s.id
    ), 0)
    WHERE s.id IN (NEW.from_shareholder_id, NEW.to_shareholder_id);

    -- 5. Update active status in one query
    UPDATE data.shareholders
    SET active = CASE
      WHEN total_shares <= 0 THEN FALSE
      ELSE TRUE
    END
    WHERE id IN (NEW.from_shareholder_id, NEW.to_shareholder_id);

  ELSE
    RAISE EXCEPTION 'Only INSERT operations are supported on data.transactions for this trigger';
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_shareholdings_after_transaction
AFTER INSERT ON data.transactions
FOR EACH ROW
EXECUTE FUNCTION data.update_shareholdings_after_transaction();
