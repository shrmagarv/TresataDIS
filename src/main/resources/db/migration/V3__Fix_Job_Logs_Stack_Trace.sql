-- Ensure stack_trace column in job_logs table is correctly using TEXT type
ALTER TABLE job_logs 
    ALTER COLUMN stack_trace TYPE TEXT;

-- Also fix the message column to ensure it's TEXT
ALTER TABLE job_logs 
    ALTER COLUMN message TYPE TEXT;
