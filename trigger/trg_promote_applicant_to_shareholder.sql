DROP TRIGGER IF EXISTS trg_promote_applicant_to_shareholder ON data.applicants;

CREATE OR REPLACE FUNCTION data.promote_applicant_to_shareholder()
RETURNS TRIGGER AS $$
BEGIN
  -- Only proceed if kyc_status changed to 'verified' and PAN doesn't exist already
  IF NEW.kyc_status = 'verified' AND
     NOT EXISTS (SELECT 1 FROM data.shareholders WHERE pan_number = NEW.pan_number) THEN

    INSERT INTO data.shareholders (name, email, pan_number, kyc_status, total_shares, active)
    VALUES (NEW.name, NEW.email, NEW.pan_number, NEW.kyc_status, 0, FALSE);

  END IF;

  -- Now, delete applicant anyway (assuming you want to clean house)
  DELETE FROM data.applicants WHERE id = NEW.id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trg_promote_applicant_to_shareholder
AFTER UPDATE OF kyc_status ON data.applicants
FOR EACH ROW
WHEN (NEW.kyc_status = 'verified')
EXECUTE FUNCTION data.promote_applicant_to_shareholder();
