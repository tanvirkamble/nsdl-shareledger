-- update a shareholder to not verified and do a transaction
UPDATE data.shareholders
SET kyc_status = 'rejected'
where id = 7;
INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES
(1, 3, 2, 7, 100.00, 1),
(1, 4, 2, 7, 100.00, 1); -- check transcations,certificate,shareholdings and shareholder