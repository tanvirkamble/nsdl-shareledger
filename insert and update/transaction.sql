INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES
(1, 1, 1, 2, 100.00, 1),
(1, 2, 1, 2, 100.00, 1); -- check transcations,certificate,shareholdings and shareholder
INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES
(2, 6, 3, 4, 100.00, 1),
(2, 7, 3, 4, 100.00, 1); -- check transcations,certificate,shareholdings and shareholder

transaction err handled in both case where if the shares are 0 and or more than it has
INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES
(1, 3, 1, 3, 100.00, 1); -- should throw err that : Invalid transaction: From_shareholder does not own the certificate
INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES
(2, 6, 3, 4, 100.00, 1),
(2, 7, 3, 4, 100.00, 1),
(2, 8, 3, 4, 100.00, 1); -- check transcations,certificate,shareholdings and shareholder
-- This should now fail (price is wrong)
INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES (1, 1, 1, 2, 99.00, 1);

-- after updating 1 shareholder to zero now again transfer the share and make it active
INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES
(1, 2, 2, 1, 100.00, 1); -- check transcations,certificate,shareholdings and shareholder

-- adding another company shar eto shareholder 2
INSERT INTO data.transactions 
(company_id, certificate_id, from_shareholder_id, to_shareholder_id, price_per_share, num_shares)
VALUES
(2, 6, 3, 2, 100.00, 1); -- check transcations,certificate,shareholdings and shareholder

