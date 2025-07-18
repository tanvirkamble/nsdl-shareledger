-- Cancel a certificate 
UPDATE data.certificates
SET status = 'cancelled'
WHERE id = 4;

-- Add a new certificate with similar values
INSERT INTO data.certificates (
  certificate_number, company_id, shareholder_id, issued_on, status, origin_type, reissue_of, transaction_id
) VALUES (
  'CERTASTRO004-REISSUE', 1, 2, CURRENT_DATE, 'active', 'reissue', 4, 500
);

-- Check if the err is raised or no
INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES
(1, 4, 2, 3, 100.00, 1);
