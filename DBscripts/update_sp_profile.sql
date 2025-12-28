use HRFINAL;

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateEmployeeProfile')
    DROP PROCEDURE UpdateEmployeeProfile;
GO

CREATE PROC UpdateEmployeeProfile
    @EmployeeID INT,
    @FieldName VARCHAR(50),
    @NewValue VARCHAR(255)
AS
BEGIN
    -- employee must exist
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Error: Employee does not exist.', 16, 1);
        RETURN;
    END

    -- Basic text fields
    IF @FieldName = 'first_name'
        UPDATE Employee SET first_name = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'last_name'
        UPDATE Employee SET last_name = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'national_id'
        UPDATE Employee SET national_id = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'country_of_birth'
        UPDATE Employee SET country_of_birth = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'phone'
        UPDATE Employee SET phone = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'email'
        UPDATE Employee SET email = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'address'
        UPDATE Employee SET address = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'emergency_contact_name'
        UPDATE Employee SET emergency_contact_name = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'emergency_contact_phone'
        UPDATE Employee SET emergency_contact_phone = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'relationship'
        UPDATE Employee SET relationship = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'biography'
        UPDATE Employee SET biography = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'profile_image'
        UPDATE Employee SET profile_image = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'employment_progress'
        UPDATE Employee SET employment_progress = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'account_status'
        UPDATE Employee SET account_status = @NewValue WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'employment_status'
        UPDATE Employee SET employment_status = @NewValue WHERE employee_id = @EmployeeID;

    -- Date fields
    ELSE IF @FieldName = 'date_of_birth'
        UPDATE Employee SET date_of_birth = TRY_CONVERT(DATE, @NewValue)
        WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'hire_date'
        UPDATE Employee SET hire_date = TRY_CONVERT(DATE, @NewValue)
        WHERE employee_id = @EmployeeID;

    -- Bit field
    ELSE IF @FieldName = 'is_active'
        UPDATE Employee SET is_active = TRY_CONVERT(BIT, @NewValue)
        WHERE employee_id = @EmployeeID;

    -- Int fields
    ELSE IF @FieldName = 'pay_grade'
        UPDATE Employee SET pay_grade = TRY_CONVERT(INT, @NewValue)
        WHERE employee_id = @EmployeeID;
    ELSE IF @FieldName = 'profile_completion'
    BEGIN
        DECLARE @NewCompletion INT = TRY_CONVERT(INT, @NewValue);
        IF @NewCompletion IS NULL OR @NewCompletion < 0 OR @NewCompletion > 100
        BEGIN
            RAISERROR('Invalid value for profile_completion. Must be between 0 and 100.', 16, 1);
            RETURN;
        END
        UPDATE Employee
        SET profile_completion = @NewCompletion
        WHERE employee_id = @EmployeeID;
        PRINT 'Employee profile_completion updated successfully.';
        RETURN;
    END

    -- FK: department
    ELSE IF @FieldName = 'department_id'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Department WHERE department_id = TRY_CONVERT(INT, @NewValue))
        BEGIN RAISERROR('Error: Department does not exist.', 16, 1); RETURN; END
        UPDATE Employee SET department_id = TRY_CONVERT(INT, @NewValue)
        WHERE employee_id = @EmployeeID;
        PRINT 'Employee department updated successfully.';
    END

    -- FK: position
    ELSE IF @FieldName = 'position_id'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Position WHERE position_id = TRY_CONVERT(INT, @NewValue))
        BEGIN RAISERROR('Error: Position does not exist.', 16, 1); RETURN; END
        UPDATE Employee SET position_id = TRY_CONVERT(INT, @NewValue)
        WHERE employee_id = @EmployeeID;
        PRINT 'Employee position updated successfully.';
    END

    -- FK: manager
    ELSE IF @FieldName = 'manager_id'
    BEGIN
        IF TRY_CONVERT(INT, @NewValue) = @EmployeeID
        BEGIN RAISERROR('Error: Employee cannot manage themselves.', 16, 1); RETURN; END
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = TRY_CONVERT(INT, @NewValue))
        BEGIN RAISERROR('Error: Manager does not exist.', 16, 1); RETURN; END
        UPDATE Employee SET manager_id = TRY_CONVERT(INT, @NewValue)
        WHERE employee_id = @EmployeeID;
        PRINT 'Employee manager updated successfully.';
    END

    -- FK: contract
    ELSE IF @FieldName = 'contract_id'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Contract WHERE contract_id = TRY_CONVERT(INT, @NewValue))
        BEGIN RAISERROR('Error: Contract does not exist.', 16, 1); RETURN; END
        UPDATE Employee SET contract_id = TRY_CONVERT(INT, @NewValue)
        WHERE employee_id = @EmployeeID;
        PRINT 'Employee contract updated successfully.';
    END

    -- FK: tax_form
    ELSE IF @FieldName = 'tax_form_id'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM TaxForm WHERE tax_form_id = TRY_CONVERT(INT, @NewValue))
        BEGIN RAISERROR('Error: Tax form does not exist.', 16, 1); RETURN; END
        UPDATE Employee SET tax_form_id = TRY_CONVERT(INT, @NewValue)
        WHERE employee_id = @EmployeeID;
        PRINT 'Employee tax form updated successfully.';
    END

    ELSE
        RAISERROR('Error: Invalid field name.', 16, 1);
END
GO
