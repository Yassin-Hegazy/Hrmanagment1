-- =============================================
-- COMPREHENSIVE ANALYTICS TEST SCRIPT (FIXED)
-- Creates full test data and generates all reports
-- =============================================

USE HRFINAL;
GO

PRINT '============================================='
PRINT 'COMPREHENSIVE ANALYTICS TEST DATA & REPORTS'
PRINT '============================================='
GO

-- =============================================
-- STEP 1: CREATE TEST DEPARTMENTS
-- =============================================
PRINT ''
PRINT '--- STEP 1: Creating Test Departments ---'

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Information Technology')
    INSERT INTO Department (department_name, purpose) VALUES ('Information Technology', 'Software development and IT infrastructure');

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Human Resources')
    INSERT INTO Department (department_name, purpose) VALUES ('Human Resources', 'Employee management and recruitment');

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Finance')
    INSERT INTO Department (department_name, purpose) VALUES ('Finance', 'Financial management and accounting');

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Marketing')
    INSERT INTO Department (department_name, purpose) VALUES ('Marketing', 'Brand management and promotions');

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Operations')
    INSERT INTO Department (department_name, purpose) VALUES ('Operations', 'Day-to-day business operations');

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Sales')
    INSERT INTO Department (department_name, purpose) VALUES ('Sales', 'Revenue generation and client relations');

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Legal')
    INSERT INTO Department (department_name, purpose) VALUES ('Legal', 'Legal compliance and contracts');

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Research and Development')
    INSERT INTO Department (department_name, purpose) VALUES ('Research and Development', 'Innovation and product development');

PRINT 'Departments created/verified.'
GO

-- =============================================
-- STEP 2: CREATE TEST POSITIONS
-- =============================================
PRINT ''
PRINT '--- STEP 2: Creating Test Positions ---'

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Software Developer')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('Software Developer', 'Develop software applications', 'Active');

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Senior Developer')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('Senior Developer', 'Lead development teams', 'Active');

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'HR Specialist')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('HR Specialist', 'Manage HR operations', 'Active');

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Finance Analyst')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('Finance Analyst', 'Analyze financial data', 'Active');

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Marketing Manager')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('Marketing Manager', 'Manage marketing campaigns', 'Active');

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Operations Manager')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('Operations Manager', 'Oversee operations', 'Active');

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Sales Representative')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('Sales Representative', 'Generate sales', 'Active');

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Legal Counsel')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('Legal Counsel', 'Provide legal advice', 'Active');

IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Research Scientist')
    INSERT INTO Position (position_title, responsibilities, status) VALUES ('Research Scientist', 'Conduct research', 'Active');

PRINT 'Positions created/verified.'
GO

-- =============================================
-- STEP 3: CREATE TAX FORMS AND SALARY TYPES
-- =============================================
PRINT ''
PRINT '--- STEP 3: Creating Tax Forms & Salary Types ---'

-- TaxForm uses: jurisdiction, validity_period, form_content
IF NOT EXISTS (SELECT 1 FROM TaxForm WHERE jurisdiction = 'Standard')
BEGIN
    INSERT INTO TaxForm (jurisdiction, validity_period, form_content) VALUES ('Standard', '1 Year', 'Standard tax form content');
END

-- SalaryType uses: type, payment_frequency, currency
IF NOT EXISTS (SELECT 1 FROM SalaryType WHERE type = 'Monthly')
BEGIN
    INSERT INTO SalaryType (type, payment_frequency, currency) VALUES ('Monthly', 'Monthly', 'USD');
END

PRINT 'Tax forms and salary types created/verified.'
GO

-- =============================================
-- STEP 4: CREATE SHIFT SCHEDULES
-- =============================================
PRINT ''
PRINT '--- STEP 4: Creating Shift Schedules ---'

-- ShiftSchedule uses: name, type, start_time, end_time, break_duration, shift_date, status
IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE name = 'Morning Shift')
BEGIN
    INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, shift_date, status)
    VALUES ('Morning Shift', 'Regular', '08:00:00', '16:00:00', 60, GETDATE(), 1);
END

IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE name = 'Afternoon Shift')
BEGIN
    INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, shift_date, status)
    VALUES ('Afternoon Shift', 'Regular', '12:00:00', '20:00:00', 60, GETDATE(), 1);
END

IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE name = 'Night Shift')
BEGIN
    INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, shift_date, status)
    VALUES ('Night Shift', 'Regular', '20:00:00', '04:00:00', 60, GETDATE(), 1);
END

PRINT 'Shift schedules created: Morning (8AM-4PM), Afternoon (12PM-8PM), Night (8PM-4AM)'
GO

-- =============================================
-- STEP 5: CREATE TEST CONTRACTS
-- =============================================
PRINT ''
PRINT '--- STEP 5: Creating Test Contracts ---'

-- Get IDs
DECLARE @TaxFormId INT = (SELECT TOP 1 tax_form_id FROM TaxForm);
DECLARE @SalaryTypeId INT = (SELECT TOP 1 salary_type_id FROM SalaryType);
DECLARE @ShiftId INT = (SELECT TOP 1 shift_id FROM ShiftSchedule WHERE name = 'Morning Shift');

-- Create contracts with different types and dates
-- FullTime Active (long term)
DECLARE @C1 INT, @C2 INT, @C3 INT, @C4 INT, @C5 INT, @C6 INT, @C7 INT, @C8 INT;
DECLARE @C9 INT, @C10 INT, @C11 INT, @C12 INT, @C13 INT, @C14 INT, @C15 INT;
DECLARE @CExp1 INT, @CExp2 INT, @CExp3 INT; -- Expired
DECLARE @CExpiring1 INT, @CExpiring2 INT, @CExpiring3 INT, @CExpiring4 INT; -- Expiring soon

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(year, -2, GETDATE()), DATEADD(year, 2, GETDATE()), 'Active');
SET @C1 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(year, -1, GETDATE()), DATEADD(year, 3, GETDATE()), 'Active');
SET @C2 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(month, -6, GETDATE()), DATEADD(year, 2, GETDATE()), 'Active');
SET @C3 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(year, -3, GETDATE()), DATEADD(year, 1, GETDATE()), 'Active');
SET @C4 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(month, -8, GETDATE()), DATEADD(year, 4, GETDATE()), 'Active');
SET @C5 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(month, -3, GETDATE()), DATEADD(year, 2, GETDATE()), 'Active');
SET @C6 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(month, -1, GETDATE()), DATEADD(year, 3, GETDATE()), 'Active');
SET @C7 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(year, -2, GETDATE()), DATEADD(year, 5, GETDATE()), 'Active');
SET @C8 = SCOPE_IDENTITY();

-- PartTime Contracts
INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('PartTime', DATEADD(month, -6, GETDATE()), DATEADD(year, 1, GETDATE()), 'Active');
SET @C9 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('PartTime', DATEADD(month, -3, GETDATE()), DATEADD(year, 2, GETDATE()), 'Active');
SET @C10 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('PartTime', DATEADD(month, -4, GETDATE()), DATEADD(month, 8, GETDATE()), 'Active');
SET @C11 = SCOPE_IDENTITY();

-- Temporary Contracts
INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('Temporary', DATEADD(month, -2, GETDATE()), DATEADD(month, 4, GETDATE()), 'Active');
SET @C12 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('Temporary', DATEADD(month, -1, GETDATE()), DATEADD(month, 5, GETDATE()), 'Active');
SET @C13 = SCOPE_IDENTITY();

-- Consultant Contracts
INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('Consultant', DATEADD(month, -6, GETDATE()), DATEADD(year, 1, GETDATE()), 'Active');
SET @C14 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('Consultant', DATEADD(month, -4, GETDATE()), DATEADD(month, 8, GETDATE()), 'Active');
SET @C15 = SCOPE_IDENTITY();

-- EXPIRED Contracts (for compliance reports)
INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(year, -3, GETDATE()), DATEADD(day, -30, GETDATE()), 'Active');
SET @CExp1 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(year, -2, GETDATE()), DATEADD(day, -15, GETDATE()), 'Active');
SET @CExp2 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('PartTime', DATEADD(year, -1, GETDATE()), DATEADD(day, -7, GETDATE()), 'Active');
SET @CExp3 = SCOPE_IDENTITY();

-- EXPIRING SOON Contracts (within 30 days)
INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(year, -2, GETDATE()), DATEADD(day, 5, GETDATE()), 'Active');
SET @CExpiring1 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('FullTime', DATEADD(year, -1, GETDATE()), DATEADD(day, 15, GETDATE()), 'Active');
SET @CExpiring2 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('PartTime', DATEADD(month, -6, GETDATE()), DATEADD(day, 25, GETDATE()), 'Active');
SET @CExpiring3 = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state)
VALUES ('Temporary', DATEADD(month, -3, GETDATE()), DATEADD(day, 10, GETDATE()), 'Active');
SET @CExpiring4 = SCOPE_IDENTITY();

PRINT 'Contracts created: 8 FullTime, 3 PartTime, 2 Temporary, 2 Consultant, 3 Expired, 4 Expiring Soon'

-- =============================================
-- STEP 6: CREATE TEST EMPLOYEES WITH GENDER DATA
-- =============================================
PRINT ''
PRINT '--- STEP 6: Creating Test Employees ---'

-- Get department IDs
DECLARE @DeptIT INT = (SELECT department_id FROM Department WHERE department_name = 'Information Technology');
DECLARE @DeptHR INT = (SELECT department_id FROM Department WHERE department_name = 'Human Resources');
DECLARE @DeptFinance INT = (SELECT department_id FROM Department WHERE department_name = 'Finance');
DECLARE @DeptMarketing INT = (SELECT department_id FROM Department WHERE department_name = 'Marketing');
DECLARE @DeptOps INT = (SELECT department_id FROM Department WHERE department_name = 'Operations');
DECLARE @DeptSales INT = (SELECT department_id FROM Department WHERE department_name = 'Sales');
DECLARE @DeptLegal INT = (SELECT department_id FROM Department WHERE department_name = 'Legal');
DECLARE @DeptRD INT = (SELECT department_id FROM Department WHERE department_name = 'Research and Development');

-- Get position IDs
DECLARE @PosDev INT = (SELECT position_id FROM Position WHERE position_title = 'Software Developer');
DECLARE @PosSeniorDev INT = (SELECT position_id FROM Position WHERE position_title = 'Senior Developer');
DECLARE @PosHR INT = (SELECT position_id FROM Position WHERE position_title = 'HR Specialist');
DECLARE @PosFinance INT = (SELECT position_id FROM Position WHERE position_title = 'Finance Analyst');
DECLARE @PosMarketing INT = (SELECT position_id FROM Position WHERE position_title = 'Marketing Manager');
DECLARE @PosOps INT = (SELECT position_id FROM Position WHERE position_title = 'Operations Manager');
DECLARE @PosSales INT = (SELECT position_id FROM Position WHERE position_title = 'Sales Representative');
DECLARE @PosLegal INT = (SELECT position_id FROM Position WHERE position_title = 'Legal Counsel');
DECLARE @PosResearch INT = (SELECT position_id FROM Position WHERE position_title = 'Research Scientist');

-- IT Department (8 employees: 5 Male, 3 Female)
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('John', 'Smith', 'NID-TEST-IT001', '1990-05-15', '555-0101', 'john.smith.test@company.com', 'Male', DATEADD(year, -2, GETDATE()), 1, 'Active', @DeptIT, @PosSeniorDev, @C1, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Sarah', 'Johnson', 'NID-TEST-IT002', '1992-08-20', '555-0102', 'sarah.johnson.test@company.com', 'Female', DATEADD(month, -18, GETDATE()), 1, 'Active', @DeptIT, @PosDev, @C2, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Michael', 'Williams', 'NID-TEST-IT003', '1988-03-10', '555-0103', 'michael.williams.test@company.com', 'Male', DATEADD(year, -3, GETDATE()), 1, 'Active', @DeptIT, @PosDev, @C3, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Emily', 'Brown', 'NID-TEST-IT004', '1995-11-25', '555-0104', 'emily.brown.test@company.com', 'Female', DATEADD(month, -8, GETDATE()), 1, 'Active', @DeptIT, @PosDev, @C9, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('David', 'Davis', 'NID-TEST-IT005', '1991-07-08', '555-0105', 'david.davis.test@company.com', 'Male', DATEADD(month, -12, GETDATE()), 1, 'Active', @DeptIT, @PosDev, @C4, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('James', 'Miller', 'NID-TEST-IT006', '1993-02-14', '555-0106', 'james.miller.test@company.com', 'Male', DATEADD(month, -6, GETDATE()), 1, 'Active', @DeptIT, @PosDev, @C12, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Jessica', 'Wilson', 'NID-TEST-IT007', '1994-09-30', '555-0107', 'jessica.wilson.test@company.com', 'Female', DATEADD(day, -10, GETDATE()), 1, 'Active', @DeptIT, @PosDev, @C13, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Robert', 'Taylor', 'NID-TEST-IT008', '1987-04-22', '555-0108', 'robert.taylor.test@company.com', 'Male', DATEADD(year, -4, GETDATE()), 1, 'Active', @DeptIT, @PosSeniorDev, @CExpiring1, @TaxFormId, @SalaryTypeId);

-- HR Department (5 employees: 2 Male, 3 Female)
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Jennifer', 'Anderson', 'NID-TEST-HR001', '1989-06-18', '555-0201', 'jennifer.anderson.test@company.com', 'Female', DATEADD(year, -3, GETDATE()), 1, 'Active', @DeptHR, @PosHR, @C5, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Amanda', 'Thomas', 'NID-TEST-HR002', '1991-12-05', '555-0202', 'amanda.thomas.test@company.com', 'Female', DATEADD(month, -18, GETDATE()), 1, 'Active', @DeptHR, @PosHR, @C6, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Christopher', 'Jackson', 'NID-TEST-HR003', '1990-09-22', '555-0203', 'christopher.jackson.test@company.com', 'Male', DATEADD(month, -10, GETDATE()), 1, 'Active', @DeptHR, @PosHR, @C10, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Michelle', 'White', 'NID-TEST-HR004', '1993-03-15', '555-0204', 'michelle.white.test@company.com', 'Female', DATEADD(day, -5, GETDATE()), 1, 'Active', @DeptHR, @PosHR, @C14, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Daniel', 'Harris', 'NID-TEST-HR005', '1988-08-28', '555-0205', 'daniel.harris.test@company.com', 'Male', DATEADD(year, -5, GETDATE()), 1, 'Active', @DeptHR, @PosHR, @CExpiring2, @TaxFormId, @SalaryTypeId);

-- Finance Department (6 employees: 3 Male, 3 Female)
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Matthew', 'Martin', 'NID-TEST-FIN001', '1985-01-30', '555-0301', 'matthew.martin.test@company.com', 'Male', DATEADD(year, -6, GETDATE()), 1, 'Active', @DeptFinance, @PosFinance, @C7, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Elizabeth', 'Garcia', 'NID-TEST-FIN002', '1990-04-12', '555-0302', 'elizabeth.garcia.test@company.com', 'Female', DATEADD(year, -2, GETDATE()), 1, 'Active', @DeptFinance, @PosFinance, @C8, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Andrew', 'Martinez', 'NID-TEST-FIN003', '1992-07-25', '555-0303', 'andrew.martinez.test@company.com', 'Male', DATEADD(month, -14, GETDATE()), 1, 'Active', @DeptFinance, @PosFinance, @C11, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Stephanie', 'Robinson', 'NID-TEST-FIN004', '1994-10-08', '555-0304', 'stephanie.robinson.test@company.com', 'Female', DATEADD(month, -8, GETDATE()), 1, 'Active', @DeptFinance, @PosFinance, @C15, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Kevin', 'Clark', 'NID-TEST-FIN005', '1989-02-18', '555-0305', 'kevin.clark.test@company.com', 'Male', DATEADD(year, -3, GETDATE()), 1, 'Active', @DeptFinance, @PosFinance, @CExp1, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Nicole', 'Rodriguez', 'NID-TEST-FIN006', '1991-06-14', '555-0306', 'nicole.rodriguez.test@company.com', 'Female', DATEADD(month, -20, GETDATE()), 1, 'Active', @DeptFinance, @PosFinance, @CExpiring3, @TaxFormId, @SalaryTypeId);

-- Marketing Department (4 employees: 1 Male, 3 Female)
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Ashley', 'Lewis', 'NID-TEST-MKT001', '1993-05-22', '555-0401', 'ashley.lewis.test@company.com', 'Female', DATEADD(year, -2, GETDATE()), 1, 'Active', @DeptMarketing, @PosMarketing, @C1, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Brian', 'Lee', 'NID-TEST-MKT002', '1990-08-16', '555-0402', 'brian.lee.test@company.com', 'Male', DATEADD(month, -16, GETDATE()), 1, 'Active', @DeptMarketing, @PosMarketing, @C2, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Melissa', 'Walker', 'NID-TEST-MKT003', '1995-01-28', '555-0403', 'melissa.walker.test@company.com', 'Female', DATEADD(month, -6, GETDATE()), 1, 'Active', @DeptMarketing, @PosMarketing, @C3, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Lauren', 'Hall', 'NID-TEST-MKT004', '1992-11-10', '555-0404', 'lauren.hall.test@company.com', 'Female', DATEADD(day, -15, GETDATE()), 1, 'Active', @DeptMarketing, @PosMarketing, @CExpiring4, @TaxFormId, @SalaryTypeId);

-- Sales Department (5 employees: 3 Male, 2 Female)
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Ryan', 'Allen', 'NID-TEST-SAL001', '1988-09-05', '555-0501', 'ryan.allen.test@company.com', 'Male', DATEADD(year, -4, GETDATE()), 1, 'Active', @DeptSales, @PosSales, @C4, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Rachel', 'Young', 'NID-TEST-SAL002', '1991-04-18', '555-0502', 'rachel.young.test@company.com', 'Female', DATEADD(month, -22, GETDATE()), 1, 'Active', @DeptSales, @PosSales, @CExp2, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Tyler', 'King', 'NID-TEST-SAL003', '1994-12-22', '555-0503', 'tyler.king.test@company.com', 'Male', DATEADD(month, -10, GETDATE()), 1, 'Active', @DeptSales, @PosSales, @CExp3, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Samantha', 'Wright', 'NID-TEST-SAL004', '1990-03-08', '555-0504', 'samantha.wright.test@company.com', 'Female', DATEADD(year, -1, GETDATE()), 1, 'Active', @DeptSales, @PosSales, @C5, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Brandon', 'Lopez', 'NID-TEST-SAL005', '1993-07-14', '555-0505', 'brandon.lopez.test@company.com', 'Male', DATEADD(month, -8, GETDATE()), 1, 'Active', @DeptSales, @PosSales, @C6, @TaxFormId, @SalaryTypeId);

-- R&D Department (3 employees: 2 Male, 1 Female)
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Dr William', 'Scott', 'NID-TEST-RD001', '1982-06-30', '555-0601', 'william.scott.test@company.com', 'Male', DATEADD(year, -5, GETDATE()), 1, 'Active', @DeptRD, @PosResearch, @C7, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Dr Patricia', 'Green', 'NID-TEST-RD002', '1984-10-12', '555-0602', 'patricia.green.test@company.com', 'Female', DATEADD(year, -4, GETDATE()), 1, 'Active', @DeptRD, @PosResearch, @C8, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Dr Richard', 'Adams', 'NID-TEST-RD003', '1980-02-28', '555-0603', 'richard.adams.test@company.com', 'Male', DATEADD(year, -6, GETDATE()), 1, 'Active', @DeptRD, @PosResearch, @C9, @TaxFormId, @SalaryTypeId);

-- Legal Department (2 employees: 1 Male, 1 Female)
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Victoria', 'Baker', 'NID-TEST-LEG001', '1986-08-20', '555-0701', 'victoria.baker.test@company.com', 'Female', DATEADD(year, -3, GETDATE()), 1, 'Active', @DeptLegal, @PosLegal, @C10, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Charles', 'Nelson', 'NID-TEST-LEG002', '1983-05-14', '555-0702', 'charles.nelson.test@company.com', 'Male', DATEADD(year, -4, GETDATE()), 1, 'Active', @DeptLegal, @PosLegal, @C11, @TaxFormId, @SalaryTypeId);

-- Operations Department (4 employees: 2 Male, 2 Female - 1 inactive)
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Timothy', 'Carter', 'NID-TEST-OPS001', '1987-11-25', '555-0801', 'timothy.carter.test@company.com', 'Male', DATEADD(year, -2, GETDATE()), 1, 'Active', @DeptOps, @PosOps, @C12, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Kimberly', 'Mitchell', 'NID-TEST-OPS002', '1992-03-18', '555-0802', 'kimberly.mitchell.test@company.com', 'Female', DATEADD(month, -18, GETDATE()), 1, 'Active', @DeptOps, @PosOps, @C13, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Jason', 'Roberts', 'NID-TEST-OPS003', '1989-07-08', '555-0803', 'jason.roberts.test@company.com', 'Male', DATEADD(month, -12, GETDATE()), 1, 'Active', @DeptOps, @PosOps, @C14, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Christina', 'Turner', 'NID-TEST-OPS004', '1994-09-30', '555-0804', 'christina.turner.test@company.com', 'Female', DATEADD(month, -6, GETDATE()), 0, 'Inactive', @DeptOps, @PosOps, @C15, @TaxFormId, @SalaryTypeId);

PRINT 'Employees created: 37 total'
PRINT '  Gender: 20 Male, 17 Female'
PRINT '  IT: 8, HR: 5, Finance: 6, Marketing: 4, Sales: 5, R&D: 3, Legal: 2, Operations: 4'

-- =============================================
-- STEP 6b: BOOST AGE & STATUS DIVERSITY (RICH DATA)
-- =============================================
PRINT ''
PRINT '--- STEP 6b: Boosting Age & Status Diversity ---'

-- IT: Add Under 25 and Over 55
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Zachary', 'Young', 'NID-TEST-IT-GENZ', DATEADD(year, -22, GETDATE()), '555-9001', 'zach.young@company.com', 'Male', DATEADD(month, -3, GETDATE()), 1, 'Active', @DeptIT, @PosDev, @C15, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Arthur', 'Cobb', 'NID-TEST-IT-SENIOR', DATEADD(year, -58, GETDATE()), '555-9002', 'art.cobb@company.com', 'Male', DATEADD(year, -10, GETDATE()), 1, 'Active', @DeptIT, @PosSeniorDev, @C8, @TaxFormId, @SalaryTypeId);

-- Finance: Add Under 25 (Female) + Inactive Over 55
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Sofia', 'Martinez', 'NID-TEST-FIN-GENZ', DATEADD(year, -23, GETDATE()), '555-9003', 'sofia.martinez@company.com', 'Female', DATEADD(month, -6, GETDATE()), 1, 'Active', @DeptFinance, @PosFinance, @C13, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Robert', 'Oldman', 'NID-TEST-FIN-RET', DATEADD(year, -62, GETDATE()), '555-9004', 'bob.oldman@company.com', 'Male', DATEADD(year, -15, GETDATE()), 0, 'Inactive', @DeptFinance, @PosFinance, @CExp1, @TaxFormId, @SalaryTypeId);

-- HR: Add 45-54 and Under 25
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Nancy', 'Reagan', 'NID-TEST-HR-MID', DATEADD(year, -48, GETDATE()), '555-9005', 'nancy.reagan@company.com', 'Female', DATEADD(year, -5, GETDATE()), 1, 'Active', @DeptHR, @PosHR, @C4, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Kyle', 'Intern', 'NID-TEST-HR-GENZ', DATEADD(year, -21, GETDATE()), '555-9006', 'kyle.intern@company.com', 'Male', DATEADD(month, -1, GETDATE()), 1, 'Active', @DeptHR, @PosHR, @C12, @TaxFormId, @SalaryTypeId);

-- Marketing: Add Over 55 + Inactive
INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Eleanor', 'Rigby', 'NID-TEST-MKT-SEN', DATEADD(year, -56, GETDATE()), '555-9007', 'eleanor.rigby@company.com', 'Female', DATEADD(year, -8, GETDATE()), 1, 'Active', @DeptMarketing, @PosMarketing, @C1, @TaxFormId, @SalaryTypeId);

INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, tax_form_id, salary_type_id)
VALUES ('Gary', 'Quit', 'NID-TEST-MKT-INACT', DATEADD(year, -30, GETDATE()), '555-9008', 'gary.quit@company.com', 'Male', DATEADD(year, -2, GETDATE()), 0, 'Inactive', @DeptMarketing, @PosMarketing, @CExp2, @TaxFormId, @SalaryTypeId);

PRINT 'Added 8 diversity boost employees.'

-- =============================================
-- STEP 7: CREATE ATTENDANCE RECORDS
-- =============================================
PRINT ''
PRINT '--- STEP 7: Creating Attendance Records ---'

-- Create attendance for all test employees (last 20 days)
INSERT INTO Attendance (employee_id, shift_id, entry_time, exit_time, duration, login_method, logout_method)
SELECT 
    e.employee_id,
    @ShiftId,
    DATEADD(minute, 480 + (ABS(CHECKSUM(NEWID())) % 120), CAST(DATEADD(day, -d.n, CAST(GETDATE() AS DATE)) AS DATETIME)),
    DATEADD(minute, 960 + (ABS(CHECKSUM(NEWID())) % 60), CAST(DATEADD(day, -d.n, CAST(GETDATE() AS DATE)) AS DATETIME)),
    7.0 + (CAST(ABS(CHECKSUM(NEWID())) % 20 AS DECIMAL) / 10),
    'Biometric',
    'Biometric'
FROM Employee e
CROSS JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
            UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
            UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
            UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20) d
WHERE e.national_id LIKE 'NID-TEST-%'
  AND e.is_active = 1;

PRINT 'Attendance records created for last 20 days'

-- =============================================
-- STEP 8: CREATE LEAVE REQUESTS
-- =============================================
PRINT ''
PRINT '--- STEP 8: Creating Leave Requests ---'

DECLARE @LeaveTypeId INT = (SELECT TOP 1 leave_id FROM [Leave]);
IF @LeaveTypeId IS NULL
BEGIN
    INSERT INTO [Leave] (leave_type, leave_description) VALUES ('Annual Leave', 'Paid annual leave');
    SET @LeaveTypeId = SCOPE_IDENTITY();
END

-- Pending Leave Requests
INSERT INTO LeaveRequest (employee_id, leave_id, justification, duration, status, submission_date)
SELECT TOP 8 employee_id, @LeaveTypeId, 'Vacation request', 5, 'Pending', DATEADD(day, -3, GETDATE())
FROM Employee WHERE national_id LIKE 'NID-TEST-%' AND is_active = 1 ORDER BY NEWID();

-- Approved Leave Requests
INSERT INTO LeaveRequest (employee_id, leave_id, justification, duration, status, submission_date, approval_timing)
SELECT TOP 10 employee_id, @LeaveTypeId, 'Annual leave', 10, 'Approved', DATEADD(day, -15, GETDATE()), DATEADD(day, -10, GETDATE())
FROM Employee WHERE national_id LIKE 'NID-TEST-%' AND is_active = 1 ORDER BY NEWID();

PRINT 'Leave requests created: 8 Pending, 10 Approved'

-- =============================================
-- STEP 9: CREATE MISSIONS
-- =============================================
PRINT ''
PRINT '--- STEP 9: Creating Missions ---'

-- PendingApproval Missions
INSERT INTO Mission (destination, start_date, end_date, status, employee_id)
SELECT TOP 7 'Client Site', DATEADD(day, 10, GETDATE()), DATEADD(day, 15, GETDATE()), 'PendingApproval', employee_id
FROM Employee WHERE national_id LIKE 'NID-TEST-%' AND is_active = 1 ORDER BY NEWID();

-- Approved Missions
INSERT INTO Mission (destination, start_date, end_date, status, employee_id)
SELECT TOP 5 'Conference', DATEADD(day, 5, GETDATE()), DATEADD(day, 7, GETDATE()), 'Approved', employee_id
FROM Employee WHERE national_id LIKE 'NID-TEST-%' AND is_active = 1 ORDER BY NEWID();

PRINT 'Missions created: 7 PendingApproval, 5 Approved'
GO

-- =============================================
-- STEP 10: GENERATE ALL ANALYTICS REPORTS
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'GENERATING ANALYTICS REPORTS'
PRINT '============================================='
GO

PRINT ''
PRINT '========== REPORT 1: DASHBOARD KPIs =========='
EXEC sp_GetAnalyticsDashboard;
GO

PRINT ''
PRINT '========== REPORT 2: DEPARTMENT OVERVIEW =========='
EXEC sp_GetDepartmentOverview;
GO

PRINT ''
PRINT '========== REPORT 3: SEARCH DEPARTMENTS (IT) =========='
EXEC sp_SearchDepartmentStats @SearchTerm = 'Information';
GO

PRINT ''
PRINT '========== REPORT 3b: ALL DEPARTMENTS =========='
EXEC sp_SearchDepartmentStats @SearchTerm = NULL;
GO

PRINT ''
PRINT '========== REPORT 4: CONTRACTS COMPLIANCE (30 days) =========='
EXEC sp_GetContractsComplianceReport @DepartmentId = NULL, @DaysThreshold = 30;
GO

PRINT ''
PRINT '========== REPORT 4b: CONTRACTS COMPLIANCE (90 days) =========='
EXEC sp_GetContractsComplianceReport @DepartmentId = NULL, @DaysThreshold = 90;
GO

PRINT ''
PRINT '========== REPORT 5: ATTENDANCE COMPLIANCE =========='
DECLARE @DateFrom DATE = DATEADD(day, -30, GETDATE());
DECLARE @DateTo DATE = GETDATE();
EXEC sp_GetAttendanceComplianceReport @DepartmentId = NULL, @DateFrom = @DateFrom, @DateTo = @DateTo;
GO

PRINT ''
PRINT '========== REPORT 6: GENDER DISTRIBUTION =========='
EXEC sp_GetGenderDistributionByDepartment;
GO

PRINT ''
PRINT '========== REPORT 7: EMPLOYMENT TYPE DISTRIBUTION =========='
EXEC sp_GetEmploymentTypeDistribution;
GO

-- =============================================
-- SUMMARY
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'TEST DATA SUMMARY'
PRINT '============================================='

SELECT 'Departments' AS Category, COUNT(*) AS [Count] FROM Department
UNION ALL
SELECT 'Employees (Total)', COUNT(*) FROM Employee
UNION ALL
SELECT 'Employees (Active)', COUNT(*) FROM Employee WHERE is_active = 1
UNION ALL
SELECT 'Test Employees', COUNT(*) FROM Employee WHERE national_id LIKE 'NID-TEST-%'
UNION ALL
SELECT 'Male Employees', COUNT(*) FROM Employee WHERE gender = 'Male'
UNION ALL
SELECT 'Female Employees', COUNT(*) FROM Employee WHERE gender = 'Female'
UNION ALL
SELECT 'Contracts', COUNT(*) FROM Contract
UNION ALL
SELECT 'Attendance Records', COUNT(*) FROM Attendance
UNION ALL
SELECT 'Leave Requests (Pending)', COUNT(*) FROM LeaveRequest WHERE status = 'Pending'
UNION ALL
SELECT 'Missions (PendingApproval)', COUNT(*) FROM Mission WHERE status = 'PendingApproval'
UNION ALL
SELECT 'Expiring Contracts (30 days)', COUNT(*) FROM Contract 
    WHERE contract_end_date BETWEEN GETDATE() AND DATEADD(day, 30, GETDATE()) AND contract_current_state = 'Active'
UNION ALL
SELECT 'Expired Contracts', COUNT(*) FROM Contract 
    WHERE contract_end_date < GETDATE() AND contract_current_state = 'Active';

PRINT ''
PRINT '============================================='
PRINT 'ALL TESTS COMPLETED!'
PRINT '============================================='
GO
