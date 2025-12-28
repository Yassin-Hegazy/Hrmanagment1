-- =============================================
-- FIX ORGANIZATION HIERARCHY (ROBUST VERSION V2)
-- Seeds ALL lookup data & builds 7-level hierarchy
-- =============================================

USE HRFINAL;
GO

SET NOCOUNT ON;

PRINT 'Starting Hierarchy Repair V2...';

-- 0. SEED CURRENCY (Root Dependency)
IF NOT EXISTS (SELECT 1 FROM Currency)
BEGIN
    INSERT INTO Currency (CurrencyCode, CurrencyName, ExchangeRate) VALUES ('USD', 'US Dollar', 1.0);
    PRINT 'Seeded Currency';
END

-- 1. SEED LOOKUP DATA
-- =============================================

-- SalaryType
IF NOT EXISTS (SELECT 1 FROM SalaryType)
BEGIN
    INSERT INTO SalaryType (type, payment_frequency, currency) VALUES ('Monthly', 'Monthly', 'USD');
    PRINT 'Seeded SalaryType';
END
DECLARE @SalaryTypeId INT = (SELECT TOP 1 salary_type_id FROM SalaryType);

-- TaxForm
IF NOT EXISTS (SELECT 1 FROM TaxForm)
BEGIN
    INSERT INTO TaxForm (jurisdiction, validity_period, form_content) VALUES ('Federal', '2025', 'Standard Content');
    PRINT 'Seeded TaxForm';
END
DECLARE @TaxFormId INT = (SELECT TOP 1 tax_form_id FROM TaxForm);

-- PayGrade
IF NOT EXISTS (SELECT 1 FROM PayGrade)
BEGIN
    INSERT INTO PayGrade (grade_name, min_salary, max_salary) VALUES ('Standard Grade', 30000, 100000);
    PRINT 'Seeded PayGrade';
END
DECLARE @PayGradeId INT = (SELECT TOP 1 pay_grade_id FROM PayGrade);

-- Contract
IF NOT EXISTS (SELECT 1 FROM Contract)
BEGIN
    INSERT INTO Contract (contract_type, contract_start_date, contract_current_state) VALUES ('Permanent', GETDATE(), 'Active');
    PRINT 'Seeded Contract';
END
DECLARE @ContractId INT = (SELECT TOP 1 contract_id FROM Contract);

-- Department (Ensure at least one)
IF NOT EXISTS (SELECT 1 FROM Department)
BEGIN
    INSERT INTO Department (department_name) VALUES ('Headquarters');
    PRINT 'Seeded Department';
END
DECLARE @DefaultDeptId INT = (SELECT TOP 1 department_id FROM Department);


-- 2. ENSURE POSITIONS EXIST (Level 0-6)
-- =============================================
DECLARE @Positions TABLE (Title NVARCHAR(100), Level INT);
INSERT INTO @Positions (Title, Level) VALUES
('Chief Executive Officer', 0),
('Chief Technology Officer', 1), ('Chief Operating Officer', 1), ('Chief Financial Officer', 1), ('Chief Marketing Officer', 1),
('IT Manager', 2), ('HR Manager', 2), ('Finance Manager', 2), ('Marketing Manager', 2),
('Senior Software Engineer', 3), ('Senior HR Specialist', 3), ('Senior Accountant', 3),
('Software Engineer', 4), ('HR Specialist', 4), ('Accountant', 4),
('Junior Developer', 5), ('Junior HR Associate', 5), ('Junior Accountant', 5),
('Intern', 6);

INSERT INTO Position (position_title, responsibilities, status)
SELECT Title, ' Hierarchy Position', 'Active'
FROM @Positions p
WHERE NOT EXISTS (SELECT 1 FROM Position WHERE position_title = p.Title);


-- 3. HIERARCHY BUILDER
-- =============================================

-- A) CEO
DECLARE @CEO_Id INT;
SELECT @CEO_Id = employee_id FROM Employee WHERE first_name = 'Khaled' AND last_name = 'Waleed';

IF @CEO_Id IS NULL
BEGIN
    INSERT INTO Employee (first_name, last_name, email, hire_date, position_id, department_id, salary_type_id, tax_form_id, is_active, employment_status, national_id, phone, gender, contract_id, pay_grade)
    VALUES ('Khaled', 'Waleed', 'ceo@company.com', GETDATE(), (SELECT TOP 1 position_id FROM Position WHERE position_title = 'Chief Executive Officer'), @DefaultDeptId, @SalaryTypeId, @TaxFormId, 1, 'Active', 'CEO-001', '000-000', 'Male', @ContractId, @PayGradeId);
    SET @CEO_Id = SCOPE_IDENTITY();
END
ELSE
BEGIN
    UPDATE Employee SET 
        position_id = (SELECT TOP 1 position_id FROM Position WHERE position_title = 'Chief Executive Officer'),
        manager_id = NULL,
        salary_type_id = @SalaryTypeId, -- Fix potential nulls
        contract_id = @ContractId,
        pay_grade = @PayGradeId
    WHERE employee_id = @CEO_Id;
END
PRINT 'CEO ID: ' + CAST(@CEO_Id AS VARCHAR);

-- B) Officers (Level 1) - Assign UNIQUE C-Suite positions
DECLARE @OfficerList TABLE (Id INT);
;WITH OfficerCandidates AS (
    SELECT employee_id, ROW_NUMBER() OVER (ORDER BY hire_date) AS rn
    FROM Employee
    WHERE employee_id != @CEO_Id
),
CPositions AS (
    SELECT position_id, ROW_NUMBER() OVER (ORDER BY position_title) AS rn
    FROM Position
    WHERE position_title IN ('Chief Technology Officer', 'Chief Operating Officer', 'Chief Financial Officer', 'Chief Marketing Officer')
)
UPDATE E
SET manager_id = @CEO_Id,
    position_id = P.position_id
OUTPUT INSERTED.employee_id INTO @OfficerList
FROM Employee E
INNER JOIN OfficerCandidates OC ON E.employee_id = OC.employee_id
INNER JOIN CPositions P ON OC.rn = P.rn
WHERE OC.rn <= 4;

-- C) Managers (Level 2)
DECLARE @MgrList TABLE (Id INT);
UPDATE Employee
SET manager_id = O.Id,
    position_id = (SELECT TOP 1 position_id FROM Position WHERE position_title LIKE '%Manager%')
OUTPUT INSERTED.employee_id INTO @MgrList
FROM Employee E
CROSS APPLY (SELECT TOP 1 Id FROM @OfficerList ORDER BY NEWID()) O
WHERE E.employee_id IN (SELECT TOP 8 employee_id FROM Employee WHERE employee_id != @CEO_Id AND employee_id NOT IN (SELECT Id FROM @OfficerList) ORDER BY NEWID());

-- D) Seniors (Level 3)
DECLARE @SeniorList TABLE (Id INT);
UPDATE Employee
SET manager_id = M.Id,
    position_id = (SELECT TOP 1 position_id FROM Position WHERE position_title LIKE 'Senior%')
OUTPUT INSERTED.employee_id INTO @SeniorList
FROM Employee E
CROSS APPLY (SELECT TOP 1 Id FROM @MgrList ORDER BY NEWID()) M
WHERE E.employee_id IN (SELECT TOP 15 employee_id FROM Employee WHERE employee_id != @CEO_Id 
    AND employee_id NOT IN (SELECT Id FROM @OfficerList)
    AND employee_id NOT IN (SELECT Id FROM @MgrList)
    ORDER BY NEWID());

-- E) Mid-Levels (Level 4)
DECLARE @MidList TABLE (Id INT);
UPDATE Employee
SET manager_id = S.Id,
    position_id = (SELECT TOP 1 position_id FROM Position WHERE position_title IN ('Software Engineer', 'HR Specialist', 'Accountant'))
OUTPUT INSERTED.employee_id INTO @MidList
FROM Employee E
CROSS APPLY (SELECT TOP 1 Id FROM @SeniorList ORDER BY NEWID()) S
WHERE E.employee_id IN (SELECT TOP 20 employee_id FROM Employee WHERE employee_id != @CEO_Id 
    AND employee_id NOT IN (SELECT Id FROM @OfficerList)
    AND employee_id NOT IN (SELECT Id FROM @MgrList)
    AND employee_id NOT IN (SELECT Id FROM @SeniorList)
    ORDER BY NEWID());

-- F) Juniors (Level 5)
DECLARE @JrList TABLE (Id INT);
UPDATE Employee
SET manager_id = M.Id,
    position_id = (SELECT TOP 1 position_id FROM Position WHERE position_title LIKE 'Junior%')
OUTPUT INSERTED.employee_id INTO @JrList
FROM Employee E
CROSS APPLY (SELECT TOP 1 Id FROM @MidList ORDER BY NEWID()) M
WHERE E.employee_id IN (SELECT TOP 20 employee_id FROM Employee WHERE employee_id != @CEO_Id 
    AND employee_id NOT IN (SELECT Id FROM @OfficerList)
    AND employee_id NOT IN (SELECT Id FROM @MgrList)
    AND employee_id NOT IN (SELECT Id FROM @SeniorList)
    AND employee_id NOT IN (SELECT Id FROM @MidList)
    ORDER BY NEWID());

-- G) Interns (Level 6) -> Everyone Else
UPDATE Employee
SET manager_id = J.Id,
    position_id = (SELECT TOP 1 position_id FROM Position WHERE position_title = 'Intern')
FROM Employee E
CROSS APPLY (SELECT TOP 1 Id FROM @JrList ORDER BY NEWID()) J
WHERE E.employee_id != @CEO_Id 
    AND E.employee_id NOT IN (SELECT Id FROM @OfficerList)
    AND E.employee_id NOT IN (SELECT Id FROM @MgrList)
    AND E.employee_id NOT IN (SELECT Id FROM @SeniorList)
    AND E.employee_id NOT IN (SELECT Id FROM @MidList)
    AND E.employee_id NOT IN (SELECT Id FROM @JrList);

PRINT 'Hierarchy Setup & Seeding Complete.';
