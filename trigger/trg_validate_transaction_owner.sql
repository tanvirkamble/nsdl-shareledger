DROP TRIGGER IF EXISTS trg_validate_transaction_owner ON data.transactions;

CREATE OR REPLACE FUNCTION data.validate_transaction_owner()
RETURNS TRIGGER AS $$
DECLARE
  cert_owner_id INT;
  from_kyc TEXT;
  from_active BOOLEAN;
  to_kyc TEXT;
  to_active BOOLEAN;
BEGIN
  -- Get the certificate's current owner
  SELECT shareholder_id INTO cert_owner_id
  FROM data.certificates
  WHERE id = NEW.certificate_id;

  -- Check that from_shareholder_id owns the certificate
  IF cert_owner_id IS NULL OR cert_owner_id != NEW.from_shareholder_id THEN
    RAISE EXCEPTION 'Invalid transaction: From_shareholder does not own the certificate';
  END IF;

  -- Validate FROM shareholder
  SELECT kyc_status, active INTO from_kyc, from_active
  FROM data.shareholders
  WHERE id = NEW.from_shareholder_id;

  IF from_kyc IS DISTINCT FROM 'verified' THEN
    RAISE EXCEPTION 'Invalid transaction: FROM Shareholder KYC is not verified';
  END IF;

  IF from_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Invalid transaction: FROM Shareholder is not active';
  END IF;

  -- Validate TO shareholder
  SELECT kyc_status, active INTO to_kyc, to_active
  FROM data.shareholders
  WHERE id = NEW.to_shareholder_id;

  IF to_kyc IS DISTINCT FROM 'verified' THEN
    RAISE EXCEPTION 'Invalid transaction: TO Shareholder KYC is not verified';
  END IF;

  IF to_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Invalid transaction: TO Shareholder is not active';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_transaction_owner
BEFORE INSERT ON data.transactions
FOR EACH ROW
EXECUTE FUNCTION data.validate_transaction_owner();
