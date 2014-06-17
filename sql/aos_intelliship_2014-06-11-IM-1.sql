ALTER TABLE contact ALTER COLUMN username TYPE VARCHAR(100);
UPDATE contact SET username = email;