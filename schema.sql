-- DROP EXISTING TABLES (clean reset)
DROP TABLE IF EXISTS data.transactions CASCADE;
DROP TABLE IF EXISTS data.certificates CASCADE;
DROP TABLE IF EXISTS data.shareholdings CASCADE;
DROP TABLE IF EXISTS data.shareholders CASCADE;
DROP TABLE IF EXISTS data.companies CASCADE;
DROP TABLE IF EXISTS data.applicants CASCADE;

CREATE TABLE: Companies
CREATE TABLE data.companies (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  isin_code CHAR(12) UNIQUE NOT NULL,
  sector TEXT,
  registered_on DATE,
  total_shares INT NOT NULL CHECK (total_shares >= 0)
);

-- CREATE TABLE: Shareholders
CREATE TABLE data.shareholders (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  pan_number VARCHAR(10) UNIQUE NOT NULL,
  email TEXT,
  kyc_status TEXT CHECK (kyc_status IN ('pending', 'verified', 'rejected')),
  total_shares int NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

-- CREATE TABLE: Applicants (public interested buyers)
CREATE TABLE data.applicants (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  pan_number VARCHAR(10) UNIQUE,
  request_date DATE DEFAULT CURRENT_DATE
);

-- CREATE TABLE: Certificates
CREATE TABLE data.certificates (
  id SERIAL PRIMARY KEY,
  certificate_number TEXT UNIQUE NOT NULL,
  company_id INT NOT NULL,
  shareholder_id INT NOT NULL,
  issued_on DATE DEFAULT CURRENT_DATE,
  status TEXT CHECK (status IN ('active', 'lost', 'cancelled')) DEFAULT 'active',
  origin_type TEXT CHECK (origin_type IN ('initial', 'transfer', 'reissue')) DEFAULT 'initial',
  reissue_of INT REFERENCES data.certificates(id),
  transaction_id INT,

  FOREIGN KEY (company_id) REFERENCES data.companies(id),
  FOREIGN KEY (shareholder_id) REFERENCES data.shareholders(id)
);

-- CREATE TABLE: Transactions
CREATE TABLE data.transactions (
  id SERIAL PRIMARY KEY,
  company_id INT NOT NULL,
  certificate_id INT NOT NULL,
  from_shareholder_id INT,
  to_shareholder_id INT NOT NULL,
  price_per_share DECIMAL(10,2),
  num_shares INT CHECK (num_shares > 0),
  txn_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (company_id) REFERENCES data.companies(id),
  FOREIGN KEY (certificate_id) REFERENCES data.certificates(id),
  FOREIGN KEY (from_shareholder_id) REFERENCES data.shareholders(id),
  FOREIGN KEY (to_shareholder_id) REFERENCES data.shareholders(id)
);

-- CREATE TABLE: Shareholdings (cache per shareholder per company)
CREATE TABLE data.shareholdings (
  shareholder_id INT NOT NULL,
  company_id INT NOT NULL,
  total_shares INT NOT NULL DEFAULT 0,
  assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (shareholder_id, company_id),
  FOREIGN KEY (shareholder_id) REFERENCES data.shareholders(id),
  FOREIGN KEY (company_id) REFERENCES data.companies(id)
);

ALTER TABLE data.certificates
ADD CONSTRAINT transaction_id
FOREIGN KEY (transaction_id) REFERENCES data.transactions(id);

-- add all the excel files now ,order : (company,shareholders,applicants,certificates,shareholdings)

UPDATE data.shareholders s
SET total_shares = COALESCE((
  SELECT SUM(sh.total_shares)
  FROM data.shareholdings sh
  WHERE sh.shareholder_id = s.id
), 0);


TEST SELECT STATEMENTS 
SELECT * FROM data.companies;
SELECT * FROM data.shareholders;
SELECT * FROM data.certificates;
SELECT * FROM data.transactions;
SELECT * FROM data.shareholdings;
SELECT * FROM data.applicants;

-- run trigger