USE HRFINAL;
GO

PRINT 'Fixing AttendanceCorrectionRequest schema...';

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Check if table needs fixing (check if request_id is NOT identity)
    IF EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('AttendanceCorrectionRequest') 
               AND name = 'request_id' 
               AND is_identity = 0)
    BEGIN
        PRINT 'Recreating AttendanceCorrectionRequest table with IDENTITY...';

        -- 2. Drop Foreign Keys referencing this table (None found, but good practice to check/handle if existed)
        
        -- 3. Drop Foreign Keys originating from this table
        IF OBJECT_ID('FK_AttendanceCorrectionRequest_Employee', 'F') IS NOT NULL
            ALTER TABLE AttendanceCorrectionRequest DROP CONSTRAINT FK_AttendanceCorrectionRequest_Employee;
            
        IF OBJECT_ID('FK_AttendanceCorrectionRequest_RecordedBy', 'F') IS NOT NULL
            ALTER TABLE AttendanceCorrectionRequest DROP CONSTRAINT FK_AttendanceCorrectionRequest_RecordedBy;

        -- 4. Create Temp Table to hold data
        SELECT * INTO #TempRequests FROM AttendanceCorrectionRequest;
        
        -- 5. Drop Old Table
        DROP TABLE AttendanceCorrectionRequest;
        
        -- 6. Create New Table
        CREATE TABLE AttendanceCorrectionRequest (
            request_id INT PRIMARY KEY IDENTITY(1,1),
            employee_id INT,
            date DATE,
            correction_type VARCHAR(50),
            reason VARCHAR(200),
            status VARCHAR(20),
            recorded_by INT
        );
        
        -- 7. Restore Data
        SET IDENTITY_INSERT AttendanceCorrectionRequest ON;
        INSERT INTO AttendanceCorrectionRequest (request_id, employee_id, date, correction_type, reason, status, recorded_by)
        SELECT request_id, employee_id, date, correction_type, reason, status, recorded_by FROM #TempRequests;
        SET IDENTITY_INSERT AttendanceCorrectionRequest OFF;
        
        DROP TABLE #TempRequests;
        
        -- 8. Restore Foreign Keys
        ALTER TABLE AttendanceCorrectionRequest ADD CONSTRAINT FK_AttendanceCorrectionRequest_Employee 
            FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
            
        ALTER TABLE AttendanceCorrectionRequest ADD CONSTRAINT FK_AttendanceCorrectionRequest_RecordedBy 
            FOREIGN KEY (recorded_by) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION;

        PRINT 'AttendanceCorrectionRequest table fixed successfully.';
    END
    ELSE
    BEGIN
        PRINT 'AttendanceCorrectionRequest table already has IDENTITY property. No changes needed.';
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error occurred: ' + ERROR_MESSAGE();
END CATCH;
GO

USE HRFINAL;
-- 1. Create a Leave Type
INSERT INTO [Leave] (leave_type, leave_description) 
VALUES ('Annual Vacation', 'Standard yearly vacation');
DECLARE @LeaveID INT = SCOPE_IDENTITY();

-- 2. Create the Vacation Package linking to it
INSERT INTO VacationLeave (leave_id, carry_over_days, approving_manager)
VALUES (@LeaveID, 5, 'System Admin');

-- 3. Note the Leave ID
PRINT 'Use Vacation Package ID: ' + CAST(@LeaveID AS VARCHAR(10));