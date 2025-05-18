-- Change ID columns from SERIAL (INT) to BIGSERIAL (BIGINT)
ALTER TABLE data_statistics 
    ALTER COLUMN id TYPE BIGINT;

-- Update the sequence to use bigint
ALTER SEQUENCE data_statistics_id_seq AS BIGINT;
