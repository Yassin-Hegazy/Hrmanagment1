USE HRFINAL;
GO

-- ==================================================================================
-- CONSOLIDATED LEAVE PROCEDURES FIXES
-- Includes:
-- 1. CancelLeaveRequest
-- 2. SubmitLeaveRequest
-- 3. ApproveLeaveRequest
-- 4. AddLeaveDocument
-- 5. AssignLeaveEntitlement
-- 6. ManageLeaveTypes (New: Adds ability to create leave types)
-- 7. ConfigureSpecialLeave (New: Adds special leave configuration)
-- ==================================================================================

-- =============================================
-- 1. PROCEDURE CancelLeaveRequest
-- =============================================
CREATE OR ALTER PROCEDURE CancelLeaveRequest
    @RequestID int,
    @EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus VARCHAR(50);
    DECLARE @OwnerID INT;

    -- Get status and owner
    SELECT 
        @CurrentStatus = status,
        @OwnerID = employee_id
    FROM LeaveRequest
    WHERE request_id = @RequestID;

    -- Check existence
    IF @CurrentStatus IS NULL
    BEGIN
        RETURN; 
    END

    -- Check ownership (Security)
    IF @OwnerID <> @EmployeeID
    BEGIN
        RAISERROR('Security Violation: You cannot cancel a leave request that does not belong to you.', 16, 1);
        RETURN;
    END

    -- Check status
    IF @CurrentStatus = 'Pending'
    BEGIN
        DELETE FROM LeaveRequest WHERE request_id = @RequestID;
    END
    ELSE
    BEGIN
        RAISERROR('Cannot cancel request: Only Pending requests can be cancelled.', 16, 1);
        RETURN;
    END
END
GO

-- =============================================
-- 2. PROCEDURE SubmitLeaveRequest
-- =============================================
CREATE OR ALTER PROCEDURE SubmitLeaveRequest
    @EmployeeID INT,
    @LeaveTypeID INT,
    @StartDate DATETIME,
    @EndDate DATETIME,
    @Reason VARCHAR(MAX),
    @RequestID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Duration INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;
    
    IF @Duration <= 0
    BEGIN
        RAISERROR('End date must be after start date.', 16, 1);
        RETURN;
    END

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

    INSERT INTO LeaveRequest (employee_id, leave_id, justification, duration, status, submission_date)
    VALUES (@EmployeeID, @LeaveTypeID, @Reason, @Duration, 'Pending', GETDATE());

    SET @RequestID = SCOPE_IDENTITY();
END
GO

-- =============================================
-- 3. PROCEDURE ApproveLeaveRequest
-- =============================================
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

-- =============================================
-- 4. PROCEDURE AddLeaveDocument
-- =============================================
CREATE OR ALTER PROCEDURE AddLeaveDocument
    @RequestID INT,
    @FilePath VARCHAR(260)
AS
BEGIN
    INSERT INTO LeaveDocument (leave_request_id, file_path, uploaded_at)
    VALUES (@RequestID, @FilePath, GETDATE());
END
GO

-- =============================================
-- 5. PROCEDURE AssignLeaveEntitlement
-- =============================================
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
    WHEN MATCHED THEN
        UPDATE SET entitlement = @Entitlement
    WHEN NOT MATCHED THEN
        INSERT (employee_id, leave_type_id, entitlement)
        VALUES (source.EmpID, source.TypeID, @Entitlement);
END
GO

-- =============================================
-- 6. PROCEDURE ManageLeaveTypes
-- =============================================
CREATE OR ALTER PROCEDURE ManageLeaveTypes
    @Action VARCHAR(10),
    @LeaveID INT = NULL,
    @LeaveType VARCHAR(50),
    @Description VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Action = 'INSERT' OR @Action = 'ADD'
    BEGIN
        INSERT INTO [Leave] (leave_type, leave_description) 
        VALUES (@LeaveType, @Description);
    END
END
GO

-- =============================================
-- 7. PROCEDURE ConfigureSpecialLeave
-- =============================================
CREATE OR ALTER PROCEDURE ConfigureSpecialLeave
    @LeaveType VARCHAR(50),
    @MaxDays INT,
    @EligibilityRules VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Insert into Policy table
    INSERT INTO LeavePolicy (name, purpose, eligibility_rules, special_leave_type, notice_period) 
    VALUES (@LeaveType, 'Special Leave', @EligibilityRules, @LeaveType, @MaxDays);

    -- Ensure Type exists in Leave table for dropdowns
    IF NOT EXISTS (SELECT 1 FROM [Leave] WHERE leave_type = @LeaveType)
    BEGIN
        INSERT INTO [Leave] (leave_type, leave_description) 
        VALUES (@LeaveType, 'Special Leave Type');
    END
END
GO
