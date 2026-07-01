-- ============================================================================
-- PROJECT: CUNY Cohort Data Processing & Autonomous Auditing Pipeline
-- ENGINE: PostgreSQL (PL/pgSQL)
-- MODULE: Schema Definition, Calculation Engine, and Trigger Security Audit
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DATABASE DDL: CORE ARCHITECTURE SETUP
-- ----------------------------------------------------------------------------

DROP TABLE IF EXISTS system_audit_log CASCADE;
DROP TABLE IF EXISTS cohort_analytics CASCADE;
DROP TABLE IF EXISTS student_registrations CASCADE;

-- Transactional ingestion layer (Source data landing)
CREATE TABLE student_registrations (
    registration_id SERIAL PRIMARY KEY,
    college_name VARCHAR(150) NOT NULL,
    student_id INT NOT NULL,
    term_code VARCHAR(20) NOT NULL,       
    is_full_time VARCHAR(1) NOT NULL,     
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Production target analytics layer (Dashboard consumption grain)
CREATE TABLE cohort_analytics (
    college_name VARCHAR(150),
    term_code VARCHAR(20),
    cohort_type VARCHAR(50),
    total_headcount INT NOT NULL,
    processed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (college_name, term_code, cohort_type)
);

-- Secure system governance ledger (Append-only)
CREATE TABLE system_audit_log (
    log_id SERIAL PRIMARY KEY,
    operation_type VARCHAR(50) NOT NULL,
    log_message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 2. PROCEDURAL EXTENSIONS: TRANSFORMATION & ETL ENGINE
-- ----------------------------------------------------------------------------

-- Deterministic String Parsing Component
CREATE OR REPLACE FUNCTION clean_term_label(p_term_code VARCHAR) 
RETURNS VARCHAR AS $$
BEGIN
    IF UPPER(p_term_code) LIKE '%FALL%' THEN
        RETURN 'Fall ' || SUBSTRING(p_term_code FROM '[0-9]+');
    ELSE
        RETURN UPPER(p_term_code);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Automated Aggregation Pipeline with Boundary Rule Enforcement (Idempotent Upsert)
CREATE OR REPLACE FUNCTION compile_cohort_metrics(target_term VARCHAR)
RETURNS VOID AS $$
BEGIN
    INSERT INTO cohort_analytics (college_name, term_code, cohort_type, total_headcount)
    SELECT 
        college_name,
        clean_term_label(term_code) AS term_code,
        'First-Time Full-Time Freshmen' AS cohort_type,
        COUNT(student_id) AS total_headcount
    FROM student_registrations
    WHERE UPPER(is_full_time) = 'Y' 
      AND LOWER(term_code) = LOWER(target_term)
    GROUP BY college_name, term_code
    ON CONFLICT (college_name, term_code, cohort_type) 
    DO UPDATE SET 
        total_headcount = EXCLUDED.total_headcount,
        processed_date = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 3. DATA GOVERNANCE LAYER: TRANSACTION INTERCEPTOR & EVENT TRIGGER
-- ----------------------------------------------------------------------------

-- Trigger Log Handler Function
CREATE OR REPLACE FUNCTION log_cohort_deletes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO system_audit_log (operation_type, log_message)
    VALUES (
        'DELETE_EVENT',
        'Warning: Cohort deleted for College: ' || OLD.college_name || 
        ' | Term: ' || OLD.term_code || 
        ' | Previous Headcount: ' || OLD.total_headcount
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Event-Driven Binding
CREATE TRIGGER trg_audit_cohort_deletes
AFTER DELETE ON cohort_analytics
FOR EACH ROW
EXECUTE FUNCTION log_cohort_deletes();

-- ----------------------------------------------------------------------------
-- 4. PORTFOLIO TEST HARNESS: FULL LIFE-CYCLE DEPLOYMENT MATRIX
-- ----------------------------------------------------------------------------

-- Execution Step 1: Seed messy incoming transactional logs
INSERT INTO student_registrations (college_name, student_id, term_code, is_full_time) VALUES 
('CUNY Baruch College', 1001, 'fall2026', 'Y'),
('CUNY Baruch College', 1002, 'fall2026', 'Y'),
('CUNY Baruch College', 1003, 'fall2026', 'N'); -- Shunt test: Out of bounds (Part-time)

-- Execution Step 2: Execute Processing Core (Aggregates base data and handles formatting)
SELECT compile_cohort_metrics('fall2026');

-- Execution Step 3: Enforce Interception Trigger via Admin Deletion
DELETE FROM cohort_analytics WHERE college_name = 'CUNY Baruch College';

-- Execution Step 4: Pull Compliance Ledger Output to Verify Pass Status
SELECT operation_type, log_message FROM system_audit_log;
