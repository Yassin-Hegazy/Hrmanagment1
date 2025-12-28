USE HRFINAL;
GO

-- 1. Ensure Device ID 1 exists for Offline Sync Simulator
IF NOT EXISTS (SELECT 1 FROM Device WHERE device_id = 1)
BEGIN
    PRINT 'Creating default Device ID 1...';
    INSERT INTO Device (device_id, device_type, terminal_id, latitude, longitude, employee_id)
    VALUES (1, 'Mobile', 1001, 0.0, 0.0, NULL);
END
GO

-- 2. Fix SyncOfflineAttendance Stored Procedure
CREATE OR ALTER PROCEDURE SyncOfflineAttendance
    @DeviceID INT,
    @EmployeeID INT,
    @ClockTime DATETIME,
    @Type VARCHAR(10) -- 'IN' or 'OUT'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AttendanceID INT;
    DECLARE @ShiftID INT;
    DECLARE @Today DATE = CAST(@ClockTime AS DATE);

    -- Find active shift for that day
    SELECT TOP 1 @ShiftID = shift_id 
    FROM ShiftAssignment 
    WHERE employee_id = @EmployeeID 
      AND status = 'Active' 
      AND @ClockTime BETWEEN start_date AND ISNULL(end_date, '2099-12-31');

    IF @Type = 'IN'
    BEGIN
        -- Check if already clocked in today?
        SELECT TOP 1 @AttendanceID = attendance_id 
        FROM Attendance 
        WHERE employee_id = @EmployeeID 
          AND CAST(entry_time AS DATE) = @Today;

        IF @AttendanceID IS NULL
        BEGIN
            INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
            VALUES (@EmployeeID, @ShiftID, @ClockTime, 'Offline');
            
            SET @AttendanceID = SCOPE_IDENTITY();
            
            -- Lateness Check
            IF @ShiftID IS NOT NULL
            BEGIN
                DECLARE @ShiftStart TIME;
                DECLARE @GracePeriod INT = 15; -- Default value
                
                -- Get shift start
                SELECT @ShiftStart = start_time FROM ShiftSchedule WHERE shift_id = @ShiftID;
                
                -- Get grace period from rules if exists
                SELECT TOP 1 @GracePeriod = threshold_minutes FROM AttendanceRule WHERE rule_type = 'GracePeriod' AND is_active = 1;
                
                -- Correctly combine Date and Time for DATEADD
                -- Cast Time to DateTime (1900-01-01 + time) then subtract 1900-01-01?
                -- Easier: CAST(Today as DateTime) + CAST(Time as DateTime)
                -- Note: in SQL Server, CAST(@Time AS DATETIME) gives 1900-01-01 HH:MM:SS.
                -- So: CAST(@Today AS DATETIME) + CAST(@ShiftStart AS DATETIME) works correctly.
                
                DECLARE @ShiftStartDateTime DATETIME = CAST(@Today AS DATETIME) + CAST(@ShiftStart AS DATETIME);
                DECLARE @GraceLimit DATETIME = DATEADD(MINUTE, @GracePeriod, @ShiftStartDateTime);
                
                IF @ClockTime > @GraceLimit
                BEGIN
                     INSERT INTO AttendanceLog (attendance_id, actor, timestamp, reason)
                     VALUES (@AttendanceID, 'System', GETDATE(), 'Late arrival detected (Offline)');
                END
            END
        END
    END
    ELSE -- OUT
    BEGIN
        -- Find latest open attendance for today
        SELECT TOP 1 @AttendanceID = attendance_id 
        FROM Attendance 
        WHERE employee_id = @EmployeeID 
          AND CAST(entry_time AS DATE) = @Today
        ORDER BY entry_time DESC;

        IF @AttendanceID IS NOT NULL
        BEGIN
            -- Calculate duration
            DECLARE @EntryTime DATETIME;
            SELECT @EntryTime = entry_time FROM Attendance WHERE attendance_id = @AttendanceID;
            
            UPDATE Attendance
            SET exit_time = @ClockTime,
                logout_method = 'Offline',
                duration = DATEDIFF(MINUTE, @EntryTime, @ClockTime) / 60.0
            WHERE attendance_id = @AttendanceID;
        END
    END

    -- Insert into AttendanceSource
    IF @AttendanceID IS NOT NULL AND EXISTS(SELECT 1 FROM Device WHERE device_id = @DeviceID)
    BEGIN
        -- Use MERGE or Check exists to avoid dupes? 
        -- PK is (attendance_id, device_id). If multiple syncs, fail or ignore?
        -- Let's ignore if exists.
        IF NOT EXISTS (SELECT 1 FROM AttendanceSource WHERE attendance_id = @AttendanceID AND device_id = @DeviceID)
        BEGIN
            INSERT INTO AttendanceSource (attendance_id, device_id, source_type, recorded_at)
            VALUES (@AttendanceID, @DeviceID, 'OfflineSync', @ClockTime);
        END
    END
    
    PRINT 'Offline attendance synced successfully';
END
GO
