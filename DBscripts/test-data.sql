-- ============================================================================
-- TEST DATA FOR ATTENDANCE AND SHIFT MANAGEMENT (CORRECTED)
-- ============================================================================
-- This script creates test data matching the actual database schema
-- ============================================================================

PRINT 'Starting test data creation...';
GO

-- ============================================================================
-- 1. CREATE TEST DEPARTMENTS
-- ============================================================================
DECLARE @ITDeptId INT, @SalesDeptId INT, @HRDeptId INT;

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'IT Department')
BEGIN
    INSERT INTO Department (department_name, purpose)
    VALUES ('IT Department', 'Information Technology');
    SET @ITDeptId = SCOPE_IDENTITY();
    PRINT 'Created IT Department';
END
ELSE
BEGIN
    SET @ITDeptId = (SELECT department_id FROM Department WHERE department_name = 'IT Department');
    PRINT 'IT Department already exists';
END

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'Sales Department')
BEGIN
    INSERT INTO Department (department_name, purpose)
    VALUES ('Sales Department', 'Sales and Marketing');
    SET @SalesDeptId = SCOPE_IDENTITY();
    PRINT 'Created Sales Department';
END
ELSE
BEGIN
    SET @SalesDeptId = (SELECT department_id FROM Department WHERE department_name = 'Sales Department');
    PRINT 'Sales Department already exists';
END

IF NOT EXISTS (SELECT 1 FROM Department WHERE department_name = 'HR Department')
BEGIN
    INSERT INTO Department (department_name, purpose)
    VALUES ('HR Department', 'Human Resources');
    SET @HRDeptId = SCOPE_IDENTITY();
    PRINT 'Created HR Department';
END
ELSE
BEGIN
    SET @HRDeptId = (SELECT department_id FROM Department WHERE department_name = 'HR Department');
    PRINT 'HR Department already exists';
END

-- ============================================================================
-- 2. CREATE TEST POSITIONS
-- ============================================================================
DECLARE @ManagerPosId INT, @DevPosId INT, @QAPosId INT, @SupportPosId INT;
DECLARE @SalesPosId INT, @MarketingPosId INT, @HRAdminPosId INT, @SysAdminPosId INT;

-- Manager Position
IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Manager')
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES ('Manager', 'Team management and oversight', 'Active');
    SET @ManagerPosId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SET @ManagerPosId = (SELECT position_id FROM Position WHERE position_title = 'Manager');
END

-- Developer Position
IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Software Developer')
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES ('Software Developer', 'Software development', 'Active');
    SET @DevPosId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SET @DevPosId = (SELECT position_id FROM Position WHERE position_title = 'Software Developer');
END

-- QA Position
IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'QA Engineer')
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES ('QA Engineer', 'Quality assurance and testing', 'Active');
    SET @QAPosId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SET @QAPosId = (SELECT position_id FROM Position WHERE position_title = 'QA Engineer');
END

-- Support Position
IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'IT Support')
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES ('IT Support', 'Technical support', 'Active');
    SET @SupportPosId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SET @SupportPosId = (SELECT position_id FROM Position WHERE position_title = 'IT Support');
END

-- Sales Position
IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Sales Representative')
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES ('Sales Representative', 'Sales and customer relations', 'Active');
    SET @SalesPosId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SET @SalesPosId = (SELECT position_id FROM Position WHERE position_title = 'Sales Representative');
END

-- Marketing Position
IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'Marketing Specialist')
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES ('Marketing Specialist', 'Marketing campaigns', 'Active');
    SET @MarketingPosId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SET @MarketingPosId = (SELECT position_id FROM Position WHERE position_title = 'Marketing Specialist');
END

-- HR Admin Position
IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'HR Administrator')
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES ('HR Administrator', 'HR administration', 'Active');
    SET @HRAdminPosId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SET @HRAdminPosId = (SELECT position_id FROM Position WHERE position_title = 'HR Administrator');
END

-- System Admin Position
IF NOT EXISTS (SELECT 1 FROM Position WHERE position_title = 'System Administrator')
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES ('System Administrator', 'System administration', 'Active');
    SET @SysAdminPosId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SET @SysAdminPosId = (SELECT position_id FROM Position WHERE position_title = 'System Administrator');
END

PRINT 'Positions created/verified';

-- ============================================================================
-- 3. CREATE TEST EMPLOYEES (Simplified - no contracts/tax forms required)
-- ============================================================================

-- Note: Employee table requires department_id, position_id, contract_id, tax_form_id, salary_type_id
-- For test data, we'll make these nullable or use default values

-- Manager 1 (IT Manager)
DECLARE @JohnManagerId INT;
IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'john.manager@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, is_active, account_status, employment_status)
    VALUES ('John', 'Manager', 'NID-MGR-001', 'john.manager@test.com', '555-0101', GETDATE(), 
           @ITDeptId, @ManagerPosId, 1, 'Active', 'Active');
    SET @JohnManagerId = SCOPE_IDENTITY();
    PRINT 'Created John Manager';
END
ELSE
BEGIN
    SET @JohnManagerId = (SELECT employee_id FROM Employee WHERE email = 'john.manager@test.com');
    PRINT 'John Manager already exists';
END

-- Manager 2 (Sales Manager)
DECLARE @SarahManagerId INT;
IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'sarah.manager@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, is_active, account_status, employment_status)
    VALUES ('Sarah', 'Manager', 'NID-MGR-002', 'sarah.manager@test.com', '555-0102', GETDATE(), 
           @SalesDeptId, @ManagerPosId, 1, 'Active', 'Active');
    SET @SarahManagerId = SCOPE_IDENTITY();
    PRINT 'Created Sarah Manager';
END
ELSE
BEGIN
    SET @SarahManagerId = (SELECT employee_id FROM Employee WHERE email = 'sarah.manager@test.com');
    PRINT 'Sarah Manager already exists';
END

-- IT Employees
DECLARE @AliceId INT, @BobId INT, @CharlieId INT, @DianaId INT;

IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'alice.developer@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, manager_id, is_active, account_status, employment_status)
    VALUES ('Alice', 'Developer', 'NID-DEV-001', 'alice.developer@test.com', '555-0201', GETDATE(), 
           @ITDeptId, @DevPosId, @JohnManagerId, 1, 'Active', 'Active');
    SET @AliceId = SCOPE_IDENTITY();
    PRINT 'Created Alice Developer';
END
ELSE
BEGIN
    SET @AliceId = (SELECT employee_id FROM Employee WHERE email = 'alice.developer@test.com');
END

IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'bob.developer@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, manager_id, is_active, account_status, employment_status)
    VALUES ('Bob', 'Developer', 'NID-DEV-002', 'bob.developer@test.com', '555-0202', GETDATE(), 
           @ITDeptId, @DevPosId, @JohnManagerId, 1, 'Active', 'Active');
    SET @BobId = SCOPE_IDENTITY();
    PRINT 'Created Bob Developer';
END
ELSE
BEGIN
    SET @BobId = (SELECT employee_id FROM Employee WHERE email = 'bob.developer@test.com');
END

IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'charlie.qa@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, manager_id, is_active, account_status, employment_status)
    VALUES ('Charlie', 'QA', 'NID-QA-001', 'charlie.qa@test.com', '555-0203', GETDATE(), 
           @ITDeptId, @QAPosId, @JohnManagerId, 1, 'Active', 'Active');
    SET @CharlieId = SCOPE_IDENTITY();
    PRINT 'Created Charlie QA';
END
ELSE
BEGIN
    SET @CharlieId = (SELECT employee_id FROM Employee WHERE email = 'charlie.qa@test.com');
END

IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'diana.support@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, manager_id, is_active, account_status, employment_status)
    VALUES ('Diana', 'Support', 'NID-SUP-001', 'diana.support@test.com', '555-0204', GETDATE(), 
           @ITDeptId, @SupportPosId, @JohnManagerId, 1, 'Active', 'Active');
    SET @DianaId = SCOPE_IDENTITY();
    PRINT 'Created Diana Support';
END
ELSE
BEGIN
    SET @DianaId = (SELECT employee_id FROM Employee WHERE email = 'diana.support@test.com');
END

-- Sales Employees
DECLARE @EmmaId INT, @FrankId INT, @GraceId INT;

IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'emma.sales@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, manager_id, is_active, account_status, employment_status)
    VALUES ('Emma', 'Sales', 'NID-SAL-001', 'emma.sales@test.com', '555-0301', GETDATE(), 
           @SalesDeptId, @SalesPosId, @SarahManagerId, 1, 'Active', 'Active');
    SET @EmmaId = SCOPE_IDENTITY();
    PRINT 'Created Emma Sales';
END
ELSE
BEGIN
    SET @EmmaId = (SELECT employee_id FROM Employee WHERE email = 'emma.sales@test.com');
END

IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'frank.sales@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, manager_id, is_active, account_status, employment_status)
    VALUES ('Frank', 'Sales', 'NID-SAL-002', 'frank.sales@test.com', '555-0302', GETDATE(), 
           @SalesDeptId, @SalesPosId, @SarahManagerId, 1, 'Active', 'Active');
    SET @FrankId = SCOPE_IDENTITY();
    PRINT 'Created Frank Sales';
END
ELSE
BEGIN
    SET @FrankId = (SELECT employee_id FROM Employee WHERE email = 'frank.sales@test.com');
END

IF NOT EXISTS (SELECT 1 FROM Employee WHERE email = 'grace.marketing@test.com')
BEGIN
    INSERT INTO Employee (first_name, last_name, national_id, email, phone, hire_date, 
                         department_id, position_id, manager_id, is_active, account_status, employment_status)
    VALUES ('Grace', 'Marketing', 'NID-MKT-001', 'grace.marketing@test.com', '555-0303', GETDATE(), 
           @SalesDeptId, @MarketingPosId, @SarahManagerId, 1, 'Active', 'Active');
    SET @GraceId = SCOPE_IDENTITY();
    PRINT 'Created Grace Marketing';
END
ELSE
BEGIN
    SET @GraceId = (SELECT employee_id FROM Employee WHERE email = 'grace.marketing@test.com');
END

PRINT 'Test employees created';

-- ============================================================================
-- 4. CREATE TEST SHIFTS
-- ============================================================================
DECLARE @MorningShiftId INT, @FlexibleShiftId INT;

IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE name = 'Morning Shift')
BEGIN
    INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, shift_date, status)
    VALUES ('Morning Shift', 'Normal', '09:00:00', '17:00:00', 60, GETDATE(), 1);
    SET @MorningShiftId = SCOPE_IDENTITY();
    PRINT 'Created Morning Shift';
END
ELSE
BEGIN
    SET @MorningShiftId = (SELECT shift_id FROM ShiftSchedule WHERE name = 'Morning Shift');
END

IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE name = 'Flexible Shift')
BEGIN
    INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, shift_date, status)
    VALUES ('Flexible Shift', 'Custom', '10:00:00', '18:00:00', 60, GETDATE(), 1);
    SET @FlexibleShiftId = SCOPE_IDENTITY();
    PRINT 'Created Flexible Shift';
END
ELSE
BEGIN
    SET @FlexibleShiftId = (SELECT shift_id FROM ShiftSchedule WHERE name = 'Flexible Shift');
END

-- ============================================================================
-- 5. ASSIGN SHIFTS TO EMPLOYEES
-- ============================================================================

-- IT employees to morning shift
IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE employee_id = @AliceId)
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@AliceId, @MorningShiftId, GETDATE(), DATEADD(MONTH, 6, GETDATE()), 'Active');

IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE employee_id = @BobId)
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@BobId, @MorningShiftId, GETDATE(), DATEADD(MONTH, 6, GETDATE()), 'Active');

IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE employee_id = @CharlieId)
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@CharlieId, @MorningShiftId, GETDATE(), DATEADD(MONTH, 6, GETDATE()), 'Active');

IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE employee_id = @DianaId)
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@DianaId, @MorningShiftId, GETDATE(), DATEADD(MONTH, 6, GETDATE()), 'Active');

-- Sales employees to flexible shift
IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE employee_id = @EmmaId)
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@EmmaId, @FlexibleShiftId, GETDATE(), DATEADD(MONTH, 6, GETDATE()), 'Active');

IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE employee_id = @FrankId)
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@FrankId, @FlexibleShiftId, GETDATE(), DATEADD(MONTH, 6, GETDATE()), 'Active');

IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE employee_id = @GraceId)
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@GraceId, @FlexibleShiftId, GETDATE(), DATEADD(MONTH, 6, GETDATE()), 'Active');

PRINT 'Shift assignments created';

-- ============================================================================
-- 6. CREATE SAMPLE ATTENDANCE RECORDS FOR TODAY
-- ============================================================================

-- Alice - On time, completed
IF NOT EXISTS (SELECT 1 FROM Attendance WHERE employee_id = @AliceId AND CAST(entry_time AS DATE) = CAST(GETDATE() AS DATE))
BEGIN
    INSERT INTO Attendance (employee_id, shift_id, entry_time, exit_time, duration, login_method, logout_method)
    VALUES (@AliceId, @MorningShiftId, 
            CAST(CAST(GETDATE() AS DATE) AS DATETIME) + CAST('09:00:00' AS DATETIME),
            CAST(CAST(GETDATE() AS DATE) AS DATETIME) + CAST('17:05:00' AS DATETIME),
            8, 'Web', 'Web');
    PRINT 'Created attendance for Alice';
END

-- Bob - Late (9:20 AM), still working
IF NOT EXISTS (SELECT 1 FROM Attendance WHERE employee_id = @BobId AND CAST(entry_time AS DATE) = CAST(GETDATE() AS DATE))
BEGIN
    INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
    VALUES (@BobId, @MorningShiftId,
            CAST(CAST(GETDATE() AS DATE) AS DATETIME) + CAST('09:20:00' AS DATETIME),
            'Web');
    PRINT 'Created attendance for Bob';
END

-- Charlie - On time, still working
IF NOT EXISTS (SELECT 1 FROM Attendance WHERE employee_id = @CharlieId AND CAST(entry_time AS DATE) = CAST(GETDATE() AS DATE))
BEGIN
    INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
    VALUES (@CharlieId, @MorningShiftId,
            CAST(CAST(GETDATE() AS DATE) AS DATETIME) + CAST('08:55:00' AS DATETIME),
            'Web');
    PRINT 'Created attendance for Charlie';
END

-- Emma - On time
IF NOT EXISTS (SELECT 1 FROM Attendance WHERE employee_id = @EmmaId AND CAST(entry_time AS DATE) = CAST(GETDATE() AS DATE))
BEGIN
    INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
    VALUES (@EmmaId, @FlexibleShiftId,
            CAST(CAST(GETDATE() AS DATE) AS DATETIME) + CAST('10:05:00' AS DATETIME),
            'Web');
    PRINT 'Created attendance for Emma';
END

-- Frank - Late
IF NOT EXISTS (SELECT 1 FROM Attendance WHERE employee_id = @FrankId AND CAST(entry_time AS DATE) = CAST(GETDATE() AS DATE))
BEGIN
    INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
    VALUES (@FrankId, @FlexibleShiftId,
            CAST(CAST(GETDATE() AS DATE) AS DATETIME) + CAST('10:30:00' AS DATETIME),
            'Web');
    PRINT 'Created attendance for Frank';
END

PRINT 'Sample attendance records created';

-- ============================================================================
-- 8. ASSIGN ROLES TO TEST USERS
-- ============================================================================
-- Note: This assumes you have a Role table and Employee_Role junction table

-- Check if Role table exists
IF OBJECT_ID('Role', 'U') IS NOT NULL AND OBJECT_ID('Employee_Role', 'U') IS NOT NULL
BEGIN
    DECLARE @ManagerRoleId INT, @EmployeeRoleId INT, @HRAdminRoleId INT, @SysAdminRoleId INT;
    
    -- Get or create Manager role
    IF NOT EXISTS (SELECT 1 FROM Role WHERE role_name = 'Manager')
    BEGIN
        INSERT INTO Role (role_name, purpose) VALUES ('Manager', 'Team management');
        SET @ManagerRoleId = SCOPE_IDENTITY();
    END
    ELSE
        SET @ManagerRoleId = (SELECT role_id FROM Role WHERE role_name = 'Manager');
    
    -- Get or create Employee role
    IF NOT EXISTS (SELECT 1 FROM Role WHERE role_name = 'Employee')
    BEGIN
        INSERT INTO Role (role_name, purpose) VALUES ('Employee', 'Regular employee');
        SET @EmployeeRoleId = SCOPE_IDENTITY();
    END
    ELSE
        SET @EmployeeRoleId = (SELECT role_id FROM Role WHERE role_name = 'Employee');
    
    -- Get or create HRAdmin role
    IF NOT EXISTS (SELECT 1 FROM Role WHERE role_name = 'HRAdmin')
    BEGIN
        INSERT INTO Role (role_name, purpose) VALUES ('HRAdmin', 'HR Administration');
        SET @HRAdminRoleId = SCOPE_IDENTITY();
    END
    ELSE
        SET @HRAdminRoleId = (SELECT role_id FROM Role WHERE role_name = 'HRAdmin');
    
    -- Get or create SystemAdmin role
    IF NOT EXISTS (SELECT 1 FROM Role WHERE role_name = 'SystemAdmin')
    BEGIN
        INSERT INTO Role (role_name, purpose) VALUES ('SystemAdmin', 'System Administration');
        SET @SysAdminRoleId = SCOPE_IDENTITY();
    END
    ELSE
        SET @SysAdminRoleId = (SELECT role_id FROM Role WHERE role_name = 'SystemAdmin');
    
    -- Assign Manager role to managers
    IF NOT EXISTS (SELECT 1 FROM Employee_Role WHERE employee_id = @JohnManagerId AND role_id = @ManagerRoleId)
        INSERT INTO Employee_Role (employee_id, role_id) VALUES (@JohnManagerId, @ManagerRoleId);
    
    IF NOT EXISTS (SELECT 1 FROM Employee_Role WHERE employee_id = @SarahManagerId AND role_id = @ManagerRoleId)
        INSERT INTO Employee_Role (employee_id, role_id) VALUES (@SarahManagerId, @ManagerRoleId);
    
    -- Assign Employee role to regular employees
    DECLARE @EmployeeIds TABLE (employee_id INT);
    INSERT INTO @EmployeeIds VALUES (@AliceId), (@BobId), (@CharlieId), (@DianaId), (@EmmaId), (@FrankId), (@GraceId);
    
    INSERT INTO Employee_Role (employee_id, role_id)
    SELECT e.employee_id, @EmployeeRoleId
    FROM @EmployeeIds e
    WHERE NOT EXISTS (SELECT 1 FROM Employee_Role WHERE employee_id = e.employee_id AND role_id = @EmployeeRoleId);
    
    PRINT 'Roles assigned to test users';
END
ELSE
BEGIN
    PRINT 'Role tables not found - skipping role assignment';
    PRINT 'You may need to manually assign roles through your application';
END

-- ============================================================================
-- 9. CREATE ATTENDANCE RULES (if AttendanceRule table exists)
-- ============================================================================

-- Note: AttendanceRule table may not exist in schema, skip if not found
IF OBJECT_ID('AttendanceRule', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM AttendanceRule WHERE rule_type = 'GracePeriod')
    BEGIN
        INSERT INTO AttendanceRule (rule_type, rule_name, threshold_minutes, penalty_amount, description, is_active, created_date)
        VALUES ('GracePeriod', 'Standard Grace Period', 15, 0, 'Employees have 15 minutes grace period', 1, GETDATE());
        PRINT 'Created Grace Period rule';
    END
END
ELSE
BEGIN
    PRINT 'AttendanceRule table not found - skipping rules creation';
END

-- ============================================================================
-- 10. CREATE SAMPLE EXCEPTIONS (HOLIDAYS)
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM Exception WHERE name = 'Christmas Day' AND YEAR(date) = YEAR(GETDATE()))
BEGIN
    INSERT INTO Exception (name, category, date, status)
    VALUES ('Christmas Day', 'Holiday', DATEFROMPARTS(YEAR(GETDATE()), 12, 25), 'Active');
    PRINT 'Created Christmas exception';
END

IF NOT EXISTS (SELECT 1 FROM Exception WHERE name = 'New Year''s Day' AND YEAR(date) = YEAR(GETDATE()) + 1)
BEGIN
    INSERT INTO Exception (name, category, date, status)
    VALUES ('New Year''s Day', 'Holiday', DATEFROMPARTS(YEAR(GETDATE()) + 1, 1, 1), 'Active');
    PRINT 'Created New Year exception';
END

-- ============================================================================
-- 11. CREATE SAMPLE CORRECTION REQUEST
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM AttendanceCorrectionRequest WHERE employee_id = @BobId AND CAST(date AS DATE) = CAST(GETDATE() AS DATE))
BEGIN
    -- Get the next request_id
    DECLARE @NextRequestId INT = ISNULL((SELECT MAX(request_id) FROM AttendanceCorrectionRequest), 0) + 1;
    
    INSERT INTO AttendanceCorrectionRequest (request_id, employee_id, date, correction_type, reason, status, recorded_by)
    VALUES (@NextRequestId, @BobId, GETDATE(), 'CheckIn', 'Traffic jam on the highway', 'Pending', @BobId);
    PRINT 'Created correction request for Bob';
END

-- ============================================================================
-- SUMMARY
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT 'TEST DATA CREATED SUCCESSFULLY';
PRINT '============================================================================';
PRINT '';
PRINT 'LOGIN CREDENTIALS:';
PRINT '  Email: [employee-email]@test.com';
PRINT '  Password: Test123! (same for all test accounts)';
PRINT '';
PRINT 'MANAGERS:';
PRINT '  - john.manager@test.com (IT Manager)';
PRINT '  - sarah.manager@test.com (Sales Manager)';
PRINT '';
PRINT 'IT EMPLOYEES (Manager: John):';
PRINT '  - alice.developer@test.com (Present, On Time)';
PRINT '  - bob.developer@test.com (Present, Late - has correction request)';
PRINT '  - charlie.qa@test.com (Clocked In)';
PRINT '  - diana.support@test.com (Absent)';
PRINT '';
PRINT 'SALES EMPLOYEES (Manager: Sarah):';
PRINT '  - emma.sales@test.com (Clocked In)';
PRINT '  - frank.sales@test.com (Clocked In, Late)';
PRINT '  - grace.marketing@test.com (No attendance today)';
PRINT '';
PRINT 'ROLES ASSIGNED:';
PRINT '  - Managers: Manager role';
PRINT '  - Regular employees: Employee role';
PRINT '';
PRINT '============================================================================';

-- Display counts
SELECT 'Total Test Employees' AS Info, COUNT(*) AS Count
FROM Employee 
WHERE email LIKE '%@test.com';

SELECT 'Today''s Attendance Records' AS Info, COUNT(*) AS Count
FROM Attendance 
WHERE CAST(entry_time AS DATE) = CAST(GETDATE() AS DATE);

PRINT 'Test data script completed!';
