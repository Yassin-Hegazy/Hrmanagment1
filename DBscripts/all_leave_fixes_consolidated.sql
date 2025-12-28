USE HRFINAL;
GO

-- ==================================================================================
-- CONSOLIDATED LEAVE FIXES SCRIPT
-- Contains all Database Table Changes and Stored Procedures for Leave Management
-- ==================================================================================

-- =============================================
-- 1. TABLE CHANGES & CREATION
-- =============================================

-- 1.1 Add LeaveFlag Table (For Irregular Patterns)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LeaveFlag')
BEGIN
    CREATE TABLE LeaveFlag (
        flag_id INT IDENTITY(1,1) PRIMARY KEY,
        employee_id INT NOT NULL,
        manager_id INT NOT NULL,
        pattern_description VARCHAR(MAX),
        flag_date DATETIME DEFAULT GETDATE(),
        is_resolved BIT DEFAULT 0,
        resolved_at DATETIME NULL,
        FOREIGN KEY (employee_id) REFERENCES Employee(employee_id),
        FOREIGN KEY (manager_id) REFERENCES Employee(employee_id)
    );
END
GO

-- 1.2 Add Start/End Date to LeaveRequest (For Sync & Duration)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[LeaveRequest]') AND name = 'start_date')
BEGIN
    ALTER TABLE LeaveRequest ADD start_date DATE;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[LeaveRequest]') AND name = 'end_date')
BEGIN
    ALTER TABLE LeaveRequest ADD end_date DATE;
END
GO

-- =============================================
-- 2. CORE WORKFLOW PROCEDURES
-- =============================================

-- 2.1 SubmitLeaveRequest (Updated with Date Logic)
CREATE OR ALTER PROCEDURE SubmitLeaveRequest
    @EmployeeID INT,
    @LeaveTypeID INT,
    @StartDate DATE,
    @EndDate DATE,
    @Reason VARCHAR(MAX),
    @RequestID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Duration INT;

    SET @Duration = DATEDIFF(day, @StartDate, @EndDate) + 1;
    
    IF @Duration <= 0 
    BEGIN
        RAISERROR('End Date must be after Start Date', 16, 1);
        RETURN;
    END

    -- Balance Check
    DECLARE @CurrentBalance DECIMAL(5,2);
    SELECT @CurrentBalance = entitlement 
    FROM LeaveEntitlement 
    WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveTypeID;

    SET @CurrentBalance = ISNULL(@CurrentBalance, 0);

    IF @CurrentBalance < @Duration
    BEGIN
        RAISERROR('Insufficient leave balance for this request.', 16, 1);
        RETURN;
    END

    INSERT INTO LeaveRequest (
        employee_id, leave_id, start_date, end_date, duration, justification, status, submission_date
    )
    VALUES (
        @EmployeeID, @LeaveTypeID, @StartDate, @EndDate, @Duration, @Reason, 'Pending', GETDATE()
    );

    SET @RequestID = SCOPE_IDENTITY();
END
GO

-- 2.2 ApproveLeaveRequest (Original Logic)
CREATE OR ALTER PROCEDURE ApproveLeaveRequest
    @LeaveRequestID INT,
    @ApproverID INT,
    @Status VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentStatus VARCHAR(10);
    SELECT @CurrentStatus = status FROM LeaveRequest WHERE request_id = @LeaveRequestID;

    UPDATE LeaveRequest 
    SET status = @Status, 
        approval_timing = GETDATE()
    WHERE request_id = @LeaveRequestID;

    IF @@ROWCOUNT = 0 RETURN;

    -- If Approved, Deduct Balance
    IF @Status = 'Approved' AND @CurrentStatus <> 'Approved'
    BEGIN
        DECLARE @EmpID INT, @TypeID INT, @Dur INT;
        
        SELECT @EmpID = employee_id, @TypeID = leave_id, @Dur = duration 
        FROM LeaveRequest 
        WHERE request_id = @LeaveRequestID;

        UPDATE LeaveEntitlement 
        SET entitlement = entitlement - @Dur 
        WHERE employee_id = @EmpID AND leave_type_id = @TypeID;
    END
END
GO

-- 2.3 CancelLeaveRequest (Original Logic)
CREATE OR ALTER PROCEDURE CancelLeaveRequest
    @RequestID int,
    @EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentStatus VARCHAR(50);
    DECLARE @OwnerID INT;

    SELECT @CurrentStatus = status, @OwnerID = employee_id FROM LeaveRequest WHERE request_id = @RequestID;

    IF @CurrentStatus IS NULL RETURN; 
    
    IF @OwnerID <> @EmployeeID
    BEGIN
        RAISERROR('Security Violation: Does not belong to you.', 16, 1);
        RETURN;
    END

    IF @CurrentStatus = 'Pending'
    BEGIN
        DELETE FROM LeaveRequest WHERE request_id = @RequestID;
    END
    ELSE
    BEGIN
        RAISERROR('Cannot cancel request: Only Pending requests can be cancelled.', 16, 1);
    END
END
GO

-- =============================================
-- 3. ADMIN & BALANCE MANAGEMENT PROCEDURES
-- =============================================

-- 3.1 OverrideLeaveDecision (Fixed Parameter Error)
CREATE OR ALTER PROCEDURE OverrideLeaveDecision
    @RequestID INT,
    @AdminID INT,
    @NewStatus VARCHAR(50),
    @Reason VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldStatus VARCHAR(50);
    DECLARE @EmpID INT, @LeaveID INT, @Duration INT;

    SELECT @OldStatus = status, @EmpID = employee_id, @LeaveID = leave_id, @Duration = duration
    FROM LeaveRequest WHERE request_id = @RequestID;

    UPDATE LeaveRequest SET status = @NewStatus, approval_timing = GETDATE() WHERE request_id = @RequestID;

    -- Adjust Balance based on status flip
    IF @NewStatus = 'Approved' AND @OldStatus <> 'Approved'
    BEGIN
        UPDATE LeaveEntitlement SET entitlement = entitlement - @Duration WHERE employee_id = @EmpID AND leave_type_id = @LeaveID;
    END
    ELSE IF @NewStatus <> 'Approved' AND @OldStatus = 'Approved'
    BEGIN
        UPDATE LeaveEntitlement SET entitlement = entitlement + @Duration WHERE employee_id = @EmpID AND leave_type_id = @LeaveID;
    END
END
GO

-- 3.2 AdjustLeaveBalance (Fixed Safety Check)
CREATE OR ALTER PROCEDURE AdjustLeaveBalance
    @EmployeeID INT,
    @LeaveTypeID INT,
    @Adjustment DECIMAL(5,2),
    @Reason VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentBalance DECIMAL(5,2);

    SELECT @CurrentBalance = entitlement FROM LeaveEntitlement WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveTypeID;

    IF @CurrentBalance IS NULL
    BEGIN
        RAISERROR ('Employee does not have an assigned entitlement.', 16, 1);
        RETURN;
    END

    IF @Adjustment < 0 AND (@CurrentBalance + @Adjustment) < 0
    BEGIN
        DECLARE @Msg NVARCHAR(255) = 'Insufficient balance. Cannot deduct ' + CAST(ABS(@Adjustment) AS VARCHAR(10)) + ' days from ' + CAST(@CurrentBalance AS VARCHAR(10)) + ' days.';
        RAISERROR (@Msg, 16, 1);
        RETURN;
    END

    UPDATE LeaveEntitlement SET entitlement = entitlement + @Adjustment WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveTypeID;
END
GO

-- 3.3 AssignLeaveEntitlement
CREATE OR ALTER PROCEDURE AssignLeaveEntitlement
    @EmployeeID INT,
    @LeaveTypeID INT,
    @Entitlement DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    MERGE LeaveEntitlement AS target
    USING (SELECT @EmployeeID AS EmpID, @LeaveTypeID AS TypeID) AS source
    ON (target.employee_id = source.EmpID AND target.leave_type_id = source.TypeID)
    WHEN MATCHED THEN UPDATE SET entitlement = @Entitlement
    WHEN NOT MATCHED THEN INSERT (employee_id, leave_type_id, entitlement) VALUES (source.EmpID, source.TypeID, @Entitlement);
END
GO

-- =============================================
-- 4. ATTENDANCE SYNC PROCEDURES
-- =============================================

-- 4.1 SyncLeaveToAttendance (Updated with Loop Logic)
CREATE OR ALTER PROCEDURE SyncLeaveToAttendance
    @LeaveRequestID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmpID INT, @StartDate DATE, @EndDate DATE, @CurrentDate DATE;

    SELECT @EmpID = employee_id, @StartDate = start_date, @EndDate = end_date FROM LeaveRequest WHERE request_id = @LeaveRequestID;

    IF @EmpID IS NULL OR @StartDate IS NULL RETURN; 

    SET @CurrentDate = @StartDate;

    WHILE @CurrentDate <= @EndDate
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Attendance WHERE employee_id = @EmpID AND CAST(entry_time AS DATE) = @CurrentDate)
        BEGIN
            INSERT INTO Attendance (employee_id, entry_time, exit_time, duration, login_method, logout_method)
            VALUES (@EmpID, DATEADD(hour, 9, CAST(@CurrentDate AS DATETIME)), DATEADD(hour, 17, CAST(@CurrentDate AS DATETIME)), 8, 'Leave', 'Leave');
        END
        SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
    END
END
GO

-- =============================================
-- 5. FLAGGING & POLICY PROCEDURES
-- =============================================

-- 5.1 FlagIrregularLeave
CREATE OR ALTER PROCEDURE FlagIrregularLeave
    @EmployeeID INT,
    @ManagerID INT,
    @PatternDescription VARCHAR(MAX)
AS
BEGIN
    INSERT INTO LeaveFlag (employee_id, manager_id, pattern_description, flag_date) VALUES (@EmployeeID, @ManagerID, @PatternDescription, GETDATE());
END
GO

-- 5.2 ResolveLeaveFlag
CREATE OR ALTER PROCEDURE ResolveLeaveFlag
    @FlagID INT
AS
BEGIN
    UPDATE LeaveFlag SET is_resolved = 1, resolved_at = GETDATE() WHERE flag_id = @FlagID;
END
GO

-- 5.3 ConfigureSpecialLeave (Policies)
CREATE OR ALTER PROCEDURE ConfigureSpecialLeave
    @LeaveType VARCHAR(50),
    @MaxDays INT,
    @EligibilityRules VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LeavePolicy (name, purpose, eligibility_rules, special_leave_type, notice_period) 
    VALUES (@LeaveType, 'Special Leave', @EligibilityRules, @LeaveType, @MaxDays);
    IF NOT EXISTS (SELECT 1 FROM [Leave] WHERE leave_type = @LeaveType)
    BEGIN
        INSERT INTO [Leave] (leave_type, leave_description) VALUES (@LeaveType, 'Special Leave Type');
    END
END
GO

-- 5.4 CreateLeavePolicy
CREATE OR ALTER PROCEDURE CreateLeavePolicy
    @Name VARCHAR(100), @Purpose VARCHAR(MAX), @EligibilityRules VARCHAR(MAX), @NoticePeriod INT, @SpecialLeaveType VARCHAR(50) = NULL, @ResetOnNewYear BIT
AS
BEGIN
    INSERT INTO LeavePolicy (name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
    VALUES (@Name, @Purpose, @EligibilityRules, @NoticePeriod, @SpecialLeaveType, @ResetOnNewYear);
END
GO

-- 5.5 UpdateLeavePolicy
CREATE OR ALTER PROCEDURE UpdateLeavePolicy
    @PolicyID INT, @Name VARCHAR(100), @Purpose VARCHAR(MAX), @EligibilityRules VARCHAR(MAX), @NoticePeriod INT, @ResetOnNewYear BIT
AS
BEGIN
    UPDATE LeavePolicy SET name = @Name, purpose = @Purpose, eligibility_rules = @EligibilityRules, notice_period = @NoticePeriod, reset_on_new_year = @ResetOnNewYear WHERE policy_id = @PolicyID;
END
GO

-- 5.6 DeleteLeavePolicy
CREATE OR ALTER PROCEDURE DeleteLeavePolicy
    @PolicyID INT
AS
BEGIN
    DELETE FROM LeavePolicy WHERE policy_id = @PolicyID;
END
GO

-- 5.7 ManageLeaveTypes
CREATE OR ALTER PROCEDURE ManageLeaveTypes
    @Action VARCHAR(10), @LeaveID INT = NULL, @LeaveType VARCHAR(50), @Description VARCHAR(255) = NULL
AS
BEGIN
    IF @Action = 'INSERT' OR @Action = 'ADD'
    BEGIN
        INSERT INTO [Leave] (leave_type, leave_description) VALUES (@LeaveType, @Description);
    END
END
GO

-- 5.8 AddLeaveDocument
CREATE OR ALTER PROCEDURE AddLeaveDocument
    @RequestID INT, @FilePath VARCHAR(260)
AS
BEGIN
    INSERT INTO LeaveDocument (leave_request_id, file_path, uploaded_at) VALUES (@RequestID, @FilePath, GETDATE());
END
GO
