-- Fetch all shareholder details
SELECT id, name, email, pan_number, kyc_status, total_shares, active
FROM data.shareholders
ORDER BY id;

-- List all shareholdings with company and shareholder info
SELECT 
  s.name AS shareholder_name,
  c.name AS company_name,
  sh.total_shares,
  sh.assigned_at
FROM data.shareholdings sh
JOIN data.shareholders s ON sh.shareholder_id = s.id
JOIN data.companies c ON sh.company_id = c.id
ORDER BY s.name;

-- Show all transactions with company, seller, buyer details
SELECT 
  t.id AS transaction_id,
  c.name AS company_name,
  from_s.name AS seller,
  to_s.name AS buyer,
  t.num_shares,
  t.price_per_share,
  t.txn_date
FROM data.transactions t
JOIN data.companies c ON t.company_id = c.id
LEFT JOIN data.shareholders from_s ON t.from_shareholder_id = from_s.id
JOIN data.shareholders to_s ON t.to_shareholder_id = to_s.id
ORDER BY t.txn_date DESC;

-- Fetch all certificates with shareholder and company info
SELECT 
  cert.id AS certificate_id,
  cert.certificate_number,
  s.name AS shareholder,
  c.name AS company,
  cert.issued_on,
  cert.status,
  cert.origin_type
FROM data.certificates cert
JOIN data.shareholders s ON cert.shareholder_id = s.id
JOIN data.companies c ON cert.company_id = c.id
ORDER BY cert.issued_on DESC;

-- Find applicants who are not yet shareholders
SELECT 
  id, name, email, pan_number, request_date
FROM data.applicants
WHERE pan_number NOT IN (
  SELECT pan_number FROM data.shareholders
)
ORDER BY request_date;

-- Total shares held by each shareholder
SELECT 
  s.name AS shareholder_name,
  SUM(sh.total_shares) AS total_shares
FROM data.shareholders s
JOIN data.shareholdings sh ON s.id = sh.shareholder_id
GROUP BY s.name
ORDER BY total_shares DESC;

-- Count of shareholders per company
SELECT 
  c.name AS company_name,
  COUNT(DISTINCT sh.shareholder_id) AS shareholder_count
FROM data.shareholdings sh
JOIN data.companies c ON sh.company_id = c.id
GROUP BY c.name
ORDER BY shareholder_count DESC;

-- Transactions that do not have a certificate issued
SELECT 
  t.id AS transaction_id,
  c.name AS company,
  to_s.name AS buyer,
  t.num_shares,
  t.txn_date
FROM data.transactions t
LEFT JOIN data.certificates cert ON t.id = cert.transaction_id
JOIN data.companies c ON c.id = t.company_id
JOIN data.shareholders to_s ON to_s.id = t.to_shareholder_id
WHERE cert.id IS NULL;

-- Shareholder activity log: transactions and certificate issuances
SELECT 
  s.name AS shareholder_name,
  'Transaction' AS activity_type,
  t.txn_date AS date,
  t.num_shares
FROM data.transactions t
JOIN data.shareholders s ON s.id = t.to_shareholder_id

UNION ALL

SELECT 
  s.name AS shareholder_name,
  'Certificate' AS activity_type,
  cert.issued_on AS date,
  NULL AS num_shares
FROM data.certificates cert
JOIN data.shareholders s ON s.id = cert.shareholder_id

ORDER BY shareholder_name, date DESC;
