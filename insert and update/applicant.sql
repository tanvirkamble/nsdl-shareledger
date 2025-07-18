-- checking if th eapplicants add in the shareholder file or no
UPDATE data.applicants
SET kyc_status = 'verified'
WHERE id IN (2);
