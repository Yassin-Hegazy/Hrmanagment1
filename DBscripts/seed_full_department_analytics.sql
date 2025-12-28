-- =============================================
-- SCRIPT: seed_full_department_analytics.sql
-- PURPOSE: Populates ALL departments with diverse data for Age, Gender, Status, and Contract Type
--          Ensures hierarchy integrity by assigning new employees to existing Department Heads.
-- =============================================

USE HRFINAL;
GO

PRINT '============================================='
PRINT 'SEEDING FULL DEPARTMENT ANALYTICS'
PRINT '============================================='
GO

-- 1. GET COMMON LOOKUP IDs
DECLARE @TaxFormId INT = (SELECT TOP 1 tax_form_id FROM TaxForm);
IF @TaxFormId IS NULL 
BEGIN
    INSERT INTO TaxForm (jurisdiction, validity_period, form_content) VALUES ('Standard', '1 Year', 'Content');
    SET @TaxFormId = SCOPE_IDENTITY();
END

DECLARE @SalaryTypeId INT = (SELECT TOP 1 salary_type_id FROM SalaryType);
IF @SalaryTypeId IS NULL
BEGIN
    INSERT INTO SalaryType (type, payment_frequency, currency) VALUES ('Monthly', 'Monthly', 'USD');
    SET @SalaryTypeId = SCOPE_IDENTITY();
END

-- Create specific contracts for diversity
-- FullTime, PartTime, Temporary, Consultant
DECLARE @CFullTime INT, @CPartTime INT, @CTemp INT, @CConsultant INT;

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state) VALUES ('FullTime', GETDATE(), DATEADD(year, 1, GETDATE()), 'Active');
SET @CFullTime = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state) VALUES ('PartTime', GETDATE(), DATEADD(year, 1, GETDATE()), 'Active');
SET @CPartTime = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state) VALUES ('Temporary', GETDATE(), DATEADD(month, 3, GETDATE()), 'Active');
SET @CTemp = SCOPE_IDENTITY();

INSERT INTO Contract (contract_type, contract_start_date, contract_end_date, contract_current_state) VALUES ('Consultant', GETDATE(), DATEADD(month, 6, GETDATE()), 'Active');
SET @CConsultant = SCOPE_IDENTITY();


-- 2. HELPER TO ADD EMPLOYEE
-- We will use a cursor or just repeated blocks for each department to ensure control.

DECLARE @DeptName NVARCHAR(100);
DECLARE @PositionTitle NVARCHAR(100); -- Added missing declaration
DECLARE @DeptID INT;
DECLARE @ManagerID INT;
DECLARE @PositionID INT;

-- LIST OF DEPARTMENTS TO PROCESS
DECLARE DeptCursor CURSOR FOR 
SELECT 'Information Technology', 'Software Developer' UNION ALL
SELECT 'Human Resources', 'HR Specialist' UNION ALL
SELECT 'Finance', 'Finance Analyst' UNION ALL
SELECT 'Marketing', 'Marketing Manager' UNION ALL
SELECT 'Sales', 'Sales Representative' UNION ALL
SELECT 'Operations', 'Operations Manager' UNION ALL
SELECT 'Legal', 'Legal Counsel' UNION ALL
SELECT 'Research and Development', 'Research Scientist';

OPEN DeptCursor;
FETCH NEXT FROM DeptCursor INTO @DeptName, @PositionTitle;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing Department: ' + @DeptName;

    -- Get Dept ID
    SELECT @DeptID = department_id FROM Department WHERE department_name = @DeptName;
    
    -- Ensure Position Exists
    IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = @PositionTitle)
    BEGIN
        INSERT INTO Position (position_title, responsibilities, status) VALUES (@PositionTitle, 'General Duties', 'Active');
    END
    SELECT @PositionID = position_id FROM Position WHERE position_title = @PositionTitle;

    -- Find a Manager (The Department Head)
    -- Strategy: Find the highest ranking person in this dept to be the parent
    -- Start with CEO as default fallback
    SELECT @ManagerID = employee_id FROM Employee WHERE manager_id IS NULL; 
    
    -- Try to find a local manager in the department
    SELECT TOP 1 @ManagerID = employee_id 
    FROM Employee 
    WHERE department_id = @DeptID AND manager_id IS NOT NULL -- Avoid picking the CEO if he happens to be in a dept
    ORDER BY hire_date ASC; 

    PRINT '  > Manager ID found: ' + CAST(@ManagerID AS VARCHAR);

    -- ===========================================
    -- INSERT DIVERSE EMPLOYEES (Idempotent Checks)
    -- ===========================================

    -- 1. UNDER 25 (Gen Z) - Female - PartTime - Active
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'genz.f.' + REPLACE(@DeptName,' ','') + '@test.com')
    BEGIN
        INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, manager_id, tax_form_id, salary_type_id)
        VALUES ('GenZ', 'Female_' + LEFT(@DeptName, 3), 'NID-' + LEFT(@DeptName, 3) + '-01', DATEADD(year, -22, GETDATE()), '555-0001', 'genz.f.' + REPLACE(@DeptName,' ','') + '@test.com', 'Female', GETDATE(), 1, 'Active', @DeptID, @PositionID, @CPartTime, @ManagerID, @TaxFormId, @SalaryTypeId);
    END

    -- 2. OVER 55 (Senior) - Male - FullTime - Active
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'senior.m.' + REPLACE(@DeptName,' ','') + '@test.com')
    BEGIN
        INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, manager_id, tax_form_id, salary_type_id)
        VALUES ('Senior', 'Male_' + LEFT(@DeptName, 3), 'NID-' + LEFT(@DeptName, 3) + '-02', DATEADD(year, -60, GETDATE()), '555-0002', 'senior.m.' + REPLACE(@DeptName,' ','') + '@test.com', 'Male', GETDATE(), 1, 'Active', @DeptID, @PositionID, @CFullTime, @ManagerID, @TaxFormId, @SalaryTypeId);
    END

    -- 3. MIDDLE AGED (35-44) - Female - Consultant - Inactive
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'mid.f.' + REPLACE(@DeptName,' ','') + '@test.com')
    BEGIN
        INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, manager_id, tax_form_id, salary_type_id)
        VALUES ('Mid', 'Consultant_' + LEFT(@DeptName, 3), 'NID-' + LEFT(@DeptName, 3) + '-03', DATEADD(year, -40, GETDATE()), '555-0003', 'mid.f.' + REPLACE(@DeptName,' ','') + '@test.com', 'Female', GETDATE(), 0, 'Inactive', @DeptID, @PositionID, @CConsultant, @ManagerID, @TaxFormId, @SalaryTypeId);
    END

    -- 4. YOUNG PRO (25-34) - Male - Temporary - Active
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'young.m.' + REPLACE(@DeptName,' ','') + '@test.com')
    BEGIN
        INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, manager_id, tax_form_id, salary_type_id)
        VALUES ('Young', 'Temp_' + LEFT(@DeptName, 3), 'NID-' + LEFT(@DeptName, 3) + '-04', DATEADD(year, -28, GETDATE()), '555-0004', 'young.m.' + REPLACE(@DeptName,' ','') + '@test.com', 'Male', GETDATE(), 1, 'Active', @DeptID, @PositionID, @CTemp, @ManagerID, @TaxFormId, @SalaryTypeId);
    END

    -- 5. EXPERIENCED (45-54) - Female - FullTime - Active
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'exp.f.' + REPLACE(@DeptName,' ','') + '@test.com')
    BEGIN
        INSERT INTO Employee (first_name, last_name, national_id, date_of_birth, phone, email, gender, hire_date, is_active, employment_status, department_id, position_id, contract_id, manager_id, tax_form_id, salary_type_id)
        VALUES ('Exp', 'Pro_' + LEFT(@DeptName, 3), 'NID-' + LEFT(@DeptName, 3) + '-05', DATEADD(year, -50, GETDATE()), '555-0005', 'exp.f.' + REPLACE(@DeptName,' ','') + '@test.com', 'Female', GETDATE(), 1, 'Active', @DeptID, @PositionID, @CFullTime, @ManagerID, @TaxFormId, @SalaryTypeId);
    END

    PRINT '  > Added 5 diverse employees to ' + @DeptName;

    FETCH NEXT FROM DeptCursor INTO @DeptName, @PositionTitle;
END

CLOSE DeptCursor;
DEALLOCATE DeptCursor;

PRINT '============================================='
PRINT 'SEEDING COMPLETE. HIERARCHY PRESERVED.'
PRINT '============================================='
GO
