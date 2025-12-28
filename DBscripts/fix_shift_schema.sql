USE HRFINAL;
GO

-- =============================================
-- SCHEMA UPDATES
-- =============================================
PRINT 'Updating Schema...';

-- 1. Add break_start_time to ShiftSchedule (for Split Shifts)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ShiftSchedule') AND name = 'break_start_time')
BEGIN
    ALTER TABLE ShiftSchedule ADD break_start_time time NULL;
    PRINT 'Added break_start_time to ShiftSchedule';
END

-- 2. Add cycle_id to ShiftSchedule (for Rotational Shifts)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ShiftSchedule') AND name = 'cycle_id')
BEGIN
    ALTER TABLE ShiftSchedule ADD cycle_id int NULL;
    PRINT 'Added cycle_id to ShiftSchedule';
END
GO

-- =============================================
-- STORED PROCEDURE UPDATES
-- =============================================
PRINT 'Updating Stored Procedures...';
GO

-- 1. Ensure AssignShiftToEmployee exists (Dependency)
CREATE OR ALTER PROCEDURE AssignShiftToEmployee
    @EmployeeID INT,
    @ShiftID INT,
    @StartDate DATE,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Deactivate current active assignment
    UPDATE ShiftAssignment
    SET status = 'Inactive', end_date = DATEADD(day, -1, @StartDate)
    WHERE employee_id = @EmployeeID AND status = 'Active';

    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@EmployeeID, @ShiftID, @StartDate, @EndDate, 'Active');
END
GO

-- 2. ConfigureSplitShift (New/Update)
CREATE OR ALTER PROCEDURE ConfigureSplitShift
    @ShiftName NVARCHAR(50),
    @FirstSlotStart TIME,
    @FirstSlotEnd TIME,
    @SecondSlotStart TIME,
    @SecondSlotEnd TIME
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BreakDuration DECIMAL(20, 2);
    SET @BreakDuration = DATEDIFF(MINUTE, @FirstSlotEnd, @SecondSlotStart) / 60.0;

    INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_start_time, break_duration, status)
    VALUES (@ShiftName, 'Split', @FirstSlotStart, @SecondSlotEnd, @FirstSlotEnd, @BreakDuration, 1);
END
GO

-- 3. AssignRotationalShift (Fixing logic to link Cycle)
CREATE OR ALTER PROCEDURE AssignRotationalShift
    @EmployeeID INT,
    @ShiftCycle INT,
    @StartDate DATE,
    @EndDate DATE,
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ShiftID INT;
    -- Find existing Rotational Shift wrapper for this cycle
    SELECT TOP 1 @ShiftID = shift_id FROM ShiftSchedule WHERE type = 'Rotational' AND cycle_id = @ShiftCycle;
    
    IF @ShiftID IS NULL
    BEGIN
        -- Create if not exists
        INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, status, cycle_id)
        VALUES ('Rotational Shift Cycle ' + CAST(@ShiftCycle AS NVARCHAR(10)), 'Rotational', '00:00', '00:00', 0, 1, @ShiftCycle);
        SET @ShiftID = SCOPE_IDENTITY();
    END

    EXEC AssignShiftToEmployee @EmployeeID, @ShiftID, @StartDate, @EndDate;
END
GO

PRINT 'Database updates completed successfully.';
