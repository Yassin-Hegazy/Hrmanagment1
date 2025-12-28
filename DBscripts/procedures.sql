use HRFINAL;
DROP PROCEDURE IF EXISTS ViewEmployeeInfo;
GO
CREATE PROCEDURE ViewEmployeeInfo
    @EmployeeID INT
AS
BEGIN
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.full_name,
        e.national_id,
        e.date_of_birth,
        e.country_of_birth,
        e.phone,
        e.email,
        e.address,
        e.emergency_contact_name,
        e.emergency_contact_phone,
        e.relationship,
        e.biography,
        e.employment_progress,
        e.account_status,
        e.employment_status,
        e.hire_date,
        e.is_active,
        d.department_name,
        p.position_title,
        m.full_name AS manager_name
    FROM Employee e
    LEFT JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Position   p ON e.position_id   = p.position_id
    LEFT JOIN Employee   m ON e.manager_id    = m.employee_id
    WHERE e.employee_id = @EmployeeID;
END;
GO



IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'AddEmployee')
    DROP PROCEDURE AddEmployee;
GO

CREATE PROCEDURE AddEmployee
    @FullName           VARCHAR(200),
    @NationalID         VARCHAR(50),
    @DateOfBirth        DATE,
    @CountryOfBirth     VARCHAR(100),
    @Phone              VARCHAR(50),
    @Email              VARCHAR(255),
    @Address            VARCHAR(255),
    @EmergencyContactName  VARCHAR(100),
    @EmergencyContactPhone VARCHAR(50),
    @Relationship       VARCHAR(50),
    @Biography          VARCHAR(MAX),
    @EmploymentProgress VARCHAR(100),
    @AccountStatus      VARCHAR(50),
    @EmploymentStatus   VARCHAR(50),
    @HireDate           DATE        = NULL,
    @IsActive           BIT         = NULL,
    @ProfileCompletion  BIT         = NULL,
    @DepartmentID       INT         = NULL,
    @PositionID         INT         = NULL,
    @ManagerID          INT         = NULL,
    @ContractID         INT         = NULL,
    @TaxFormID          INT         = NULL,
    @SalaryTypeID       INT         = NULL,
    @PayGrade           INT         = NULL,
    -- New authentication parameters
    @PasswordHash       VARCHAR(MAX) = NULL,
    @PasswordSalt       VARCHAR(MAX) = NULL,
    @ProfileImage       VARCHAR(255) = NULL
AS
BEGIN
   
    IF @FullName IS NULL OR LTRIM(RTRIM(@FullName)) = ''
    BEGIN
        RAISERROR('Full name is required and cannot be empty', 16, 1);
        RETURN;
    END;

    IF @NationalID IS NULL OR LTRIM(RTRIM(@NationalID)) = ''
    BEGIN
        RAISERROR('National ID is required and cannot be empty', 16, 1);
        RETURN;
    END;

   
    IF EXISTS (SELECT 1 FROM Employee WHERE national_id = @NationalID)
    BEGIN
        RAISERROR('National ID already exists in the system', 16, 1);
        RETURN;
    END;

    IF @Email IS NOT NULL 
       AND EXISTS (SELECT 1 FROM Employee WHERE email = @Email)
    BEGIN
        RAISERROR('Email address already registered to another employee', 16, 1);
        RETURN;
    END;

    
    IF @DepartmentID IS NOT NULL 
       AND NOT EXISTS (SELECT 1 FROM Department WHERE department_id = @DepartmentID)
    BEGIN
        RAISERROR('Invalid Department ID - Department does not exist', 16, 1);
        RETURN;
    END;

    IF @PositionID IS NOT NULL 
       AND NOT EXISTS (SELECT 1 FROM Position WHERE position_id = @PositionID)
    BEGIN
        RAISERROR('Invalid Position ID - Position does not exist', 16, 1);
        RETURN;
    END;

    IF @ManagerID IS NOT NULL 
       AND NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ManagerID AND is_active = 1)
    BEGIN
        RAISERROR('Invalid Manager ID - Manager does not exist or is inactive', 16, 1);
        RETURN;
    END;

    
    DECLARE @FirstName VARCHAR(100), @LastName VARCHAR(100);

    IF CHARINDEX(' ', @FullName) > 0
    BEGIN
        SET @FirstName = SUBSTRING(@FullName, 1, CHARINDEX(' ', @FullName) - 1);
        SET @LastName  = SUBSTRING(@FullName, CHARINDEX(' ', @FullName) + 1, LEN(@FullName));
    END
    ELSE
    BEGIN
        SET @FirstName = @FullName;
        SET @LastName  = '';
    END;

    
    SET @HireDate          = ISNULL(@HireDate, CAST(GETDATE() AS DATE));
    SET @IsActive          = ISNULL(@IsActive, 1);
    SET @ProfileCompletion = ISNULL(@ProfileCompletion, 0);

   
    INSERT INTO Employee (
        first_name, last_name, national_id, date_of_birth, country_of_birth,
        phone, email, address, emergency_contact_name, emergency_contact_phone,
        relationship, biography, employment_progress, account_status,
        employment_status, hire_date, is_active, profile_completion,
        department_id, position_id, manager_id, contract_id, tax_form_id,
        salary_type_id, pay_grade,
        password_hash, password_salt, profile_image
    )
    VALUES (
        @FirstName, @LastName, @NationalID, @DateOfBirth, @CountryOfBirth,
        @Phone, @Email, @Address, @EmergencyContactName, @EmergencyContactPhone,
        @Relationship, @Biography, @EmploymentProgress, @AccountStatus,
        @EmploymentStatus, @HireDate, @IsActive, @ProfileCompletion,
        @DepartmentID, @PositionID, @ManagerID, @ContractID, @TaxFormID,
        @SalaryTypeID, @PayGrade,
        @PasswordHash, @PasswordSalt, @ProfileImage
    );

    DECLARE @NewEmployeeID INT = SCOPE_IDENTITY();

    SELECT @NewEmployeeID AS NewEmployeeID;
END;
GO

PRINT 'AddEmployee procedure updated with authentication fields.';
GO

    
DROP PROCEDURE IF EXISTS UpdateEmployeeInfo;
GO
CREATE PROCEDURE UpdateEmployeeInfo
    @EmployeeID INT,
    @Email VARCHAR(255) = NULL,
    @Phone VARCHAR(30) = NULL,
    @Address VARCHAR(255) = NULL,
    @EmergencyContactName VARCHAR(100) = NULL,
    @EmergencyContactPhone VARCHAR(30) = NULL
AS
BEGIN
    
    IF NOT EXISTS (
        SELECT 1 
        FROM Employee e
        WHERE e.employee_id = @EmployeeID
    )
    BEGIN
        RAISERROR('Employee not found - Cannot update non-existent employee', 16, 1);
        RETURN;
    END
    
    IF @Email IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM Employee e
            WHERE e.email = @Email AND e.employee_id != @EmployeeID
        )
        BEGIN
            RAISERROR('Email address already in use by another employee', 16, 1);
            RETURN;
        END
    END
    
    
    UPDATE Employee
    SET 
        email = COALESCE(@Email, email),
        phone = COALESCE(@Phone, phone),
        address = COALESCE(@Address, address),
        emergency_contact_name = COALESCE(@EmergencyContactName, emergency_contact_name),
        emergency_contact_phone = COALESCE(@EmergencyContactPhone, emergency_contact_phone)
    WHERE employee_id = @EmployeeID;
    
   
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('Update failed - No rows were modified', 16, 1);
    END
END;
GO
CREATE PROCEDURE AssignRole
    @EmployeeID INT,
    @RoleID INT
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM Employee e WHERE e.employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Employee does not exist', 16, 1);
        RETURN;
    END
    
 
    IF NOT EXISTS (SELECT 1 FROM Role r WHERE r.role_id = @RoleID)
    BEGIN
        RAISERROR('Role does not exist', 16, 1);
        RETURN;
    END
    
    IF EXISTS (
        SELECT 1 
        FROM Employee_Role er
        INNER JOIN Employee e ON er.employee_id = e.employee_id
        INNER JOIN Role r ON er.role_id = r.role_id
        WHERE er.employee_id = @EmployeeID AND er.role_id = @RoleID
    )
    BEGIN
       
        PRINT 'Role already assigned to this employee';
        RETURN;
    END
    
    
    INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
    VALUES (@EmployeeID, @RoleID, GETDATE());
    
    PRINT 'Role assigned successfully';
END;
GO
DROP PROCEDURE IF EXISTS GetDepartmentEmployeeStats;
GO

CREATE PROCEDURE GetDepartmentEmployeeStats
AS
BEGIN
    
    SELECT 
        d.department_name,
        COUNT(e.employee_id) AS number_of_employees
    FROM Department d
    LEFT JOIN Employee e ON d.department_id = e.department_id
    GROUP BY d.department_name;
END;
GO
DROP PROCEDURE IF EXISTS ReassignManager;
GO
CREATE PROCEDURE ReassignManager
    @EmployeeID INT,
    @NewManagerID INT
AS
BEGIN

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Employee does not exist', 16, 1);
        RETURN;
    END

    IF @NewManagerID IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @NewManagerID AND is_active = 1)
        BEGIN
            RAISERROR('Manager does not exist or is inactive', 16, 1);
            RETURN;
        END
    END
    
 
    IF @EmployeeID = @NewManagerID
    BEGIN
        RAISERROR('Employee cannot be their own manager', 16, 1);
        RETURN;
    END
    
    
    IF @NewManagerID IS NOT NULL
    BEGIN
        DECLARE @CircularCheck INT;
        
        WITH ManagerChain AS (
            
            SELECT employee_id, manager_id, 0 AS level
            FROM Employee
            WHERE employee_id = @NewManagerID
            
            UNION ALL
            
            
            SELECT e.employee_id, e.manager_id, mc.level + 1
            FROM Employee e
            INNER JOIN ManagerChain mc ON e.employee_id = mc.manager_id
            WHERE mc.level < 10 
        )
        SELECT @CircularCheck = employee_id
        FROM ManagerChain
        WHERE employee_id = @EmployeeID;
        
        IF @CircularCheck IS NOT NULL
        BEGIN
            RAISERROR('Cannot assign manager - would create circular hierarchy', 16, 1);
            RETURN;
        END
    END
    
   
    UPDATE Employee
    SET manager_id = @NewManagerID
    WHERE employee_id = @EmployeeID;
    
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('Update failed - no rows modified', 16, 1);
    END
    ELSE
    BEGIN
        PRINT 'Manager reassigned successfully';
    END
END;
GO
DROP PROCEDURE IF EXISTS ReassignHierarchy;
GO
CREATE PROCEDURE ReassignHierarchy
    @EmployeeID INT,
    @NewDepartmentID INT,
    @NewManagerID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Invalid Employee ID - Employee does not exist', 16, 1);
        RETURN;
    END

    IF @NewDepartmentID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Department WHERE department_id = @NewDepartmentID
    )
    BEGIN
        RAISERROR('Invalid Department ID - Department does not exist', 16, 1);
        RETURN;
    END
    
  
    IF @NewManagerID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Employee WHERE employee_id = @NewManagerID AND is_active = 1
    )
    BEGIN
        RAISERROR('Invalid Manager ID - Manager does not exist or is inactive', 16, 1);
        RETURN;
    END
    
  
    IF @EmployeeID = @NewManagerID
    BEGIN
        RAISERROR('Employee cannot be their own manager', 16, 1);
        RETURN;
    END
    
    BEGIN TRANSACTION;-- save progress from here 
    
    UPDATE Employee
    SET 
        department_id = @NewDepartmentID,
        manager_id = @NewManagerID
    WHERE employee_id = @EmployeeID;
    
    
    IF EXISTS (SELECT 1 FROM EmployeeHierarchy WHERE employee_id = @EmployeeID)
    BEGIN
        UPDATE EmployeeHierarchy
        SET manager_id = @NewManagerID
        WHERE employee_id = @EmployeeID;
    END
    ELSE IF @NewManagerID IS NOT NULL
    BEGIN
        INSERT INTO EmployeeHierarchy (employee_id, manager_id, hierarchy_level)
        VALUES (@EmployeeID, @NewManagerID, 1);
    END
    
    COMMIT TRANSACTION; -- like save the progress that has been done 
    
    PRINT 'Hierarchy reassignment completed successfully';
END;
GO
DROP PROCEDURE IF EXISTS NotifyStructureChange;
GO
CREATE PROCEDURE NotifyStructureChange
    @AffectedEmployees VARCHAR(500),
    @Message VARCHAR(200)
AS
BEGIN
    
    IF @Message IS NULL OR LTRIM(RTRIM(@Message)) = ''
    BEGIN
        RAISERROR('Message cannot be empty', 16, 1);
        RETURN;
    END
    
    -- Validate affected employees list
    IF @AffectedEmployees IS NULL OR LTRIM(RTRIM(@AffectedEmployees)) = ''
    BEGIN
        RAISERROR('Affected employees list cannot be empty', 16, 1);
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
    
    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
    VALUES (@Message, GETDATE(), 'High', 'Unread', 'StructureChange');
    
    DECLARE @NewNotificationID INT = SCOPE_IDENTITY();
    
    
    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT 
        CAST(value AS INT), -- CAST: Converts string to integer
        @NewNotificationID,
        'Sent',
        GETDATE()
    FROM STRING_SPLIT(@AffectedEmployees, ',') -- STRING_SPLIT: Splits comma-separated values
    WHERE ISNUMERIC(value) = 1 -- ISNUMERIC: Checks if value is numeric
      AND EXISTS (
          SELECT 1 
          FROM Employee e 
          WHERE e.employee_id = CAST(value AS INT) AND e.is_active = 1
      );
    
    DECLARE @NotifiedCount INT = @@ROWCOUNT;
    
    COMMIT TRANSACTION;
    
    
    PRINT CONCAT('Notification sent to ', CAST(@NotifiedCount AS VARCHAR), ' employees');
END;
GO
IF OBJECT_ID('vw_OrgHierarchy', 'V') IS NOT NULL
    DROP VIEW vw_OrgHierarchy;
GO

CREATE VIEW vw_OrgHierarchy
AS
WITH HierarchyCTE AS (
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.email,
        e.department_id,
        e.position_id,
        e.manager_id,
        0 AS hierarchy_level,
        CAST(e.employee_id AS VARCHAR(MAX)) AS hierarchy_path
    FROM Employee e
    WHERE e.manager_id IS NULL

    UNION ALL


    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.email,
        e.department_id,
        e.position_id,
        e.manager_id,
        h.hierarchy_level + 1,
        CAST(h.hierarchy_path + '/' + CAST(e.employee_id AS VARCHAR(20)) AS VARCHAR(MAX))
    FROM Employee e
    INNER JOIN HierarchyCTE h ON e.manager_id = h.employee_id
)
SELECT 
    h.employee_id,
    h.first_name + ' ' + h.last_name AS full_name,
    h.email,
    h.hierarchy_level,
    h.hierarchy_path,
    h.manager_id,
    m.first_name + ' ' + m.last_name AS manager_name,
    ISNULL(d.department_name, 'N/A') AS department_name,
    ISNULL(p.position_title, 'N/A') AS position_title
FROM HierarchyCTE h
LEFT JOIN Employee m ON h.manager_id = m.employee_id
LEFT JOIN Department d ON h.department_id = d.department_id
LEFT JOIN Position p ON h.position_id = p.position_id;
GO
DROP PROCEDURE IF EXISTS ViewOrgHierarchy;
GO

CREATE PROCEDURE ViewOrgHierarchy
AS
BEGIN
    
    SELECT 
        employee_id,
        full_name,
        email,
        hierarchy_level,
        hierarchy_path, 
        manager_id,
        manager_name,
        department_name,
        position_title
    FROM vw_OrgHierarchy
    ORDER BY hierarchy_level, department_name, full_name;
END;
GO
DROP PROCEDURE IF EXISTS AssignShiftToEmployee;
GO

CREATE PROCEDURE AssignShiftToEmployee
    @EmployeeID INT,
    @ShiftID INT,
    @StartDate DATE,
    @EndDate DATE = NULL
AS
BEGIN
    
    IF NOT EXISTS (
        SELECT 1 FROM Employee e
        WHERE e.employee_id = @EmployeeID AND e.is_active = 1
    )
    BEGIN
        RAISERROR('Employee does not exist or is inactive', 16, 1);
        RETURN;
    END
    
    IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE shift_id = @ShiftID)
    BEGIN
        RAISERROR('Shift does not exist', 16, 1);
        RETURN;
    END

    
    IF @EndDate IS NOT NULL AND @EndDate < @StartDate
    BEGIN
        RAISERROR('End Date cannot be before Start Date', 16, 1);
        RETURN;
    END
    
    
    IF EXISTS (
        SELECT 1
        FROM ShiftAssignment sa
        INNER JOIN ShiftSchedule ss ON sa.shift_id = ss.shift_id
        WHERE sa.employee_id = @EmployeeID
          AND sa.status IN ('Assigned', 'Active')
          AND (
             
              (@EndDate IS NULL) OR
              (sa.start_date <= @EndDate AND (sa.end_date IS NULL OR sa.end_date >= @StartDate))
          )
    )
    BEGIN
        RAISERROR('Employee already has a conflicting shift assignment for this period', 16, 1);
        RETURN;
    END
    
 
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@EmployeeID, @ShiftID, @StartDate, @EndDate, 'Assigned');
    
    PRINT 'Shift assigned successfully';
END;
DROP PROCEDURE IF EXISTS UpdateShiftStatus;
GO
CREATE PROCEDURE UpdateShiftStatus
    @ShiftAssignmentID INT,
    @Status VARCHAR(20)
AS
BEGIN
    -- 1. Validate assignment exists
    IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE assignment_id = @ShiftAssignmentID)
    BEGIN
        RAISERROR('Shift assignment does not exist', 16, 1);
        RETURN;
    END
    
    -- REMOVED: The status whitelist check. 
    -- Now accepts "Approved", "Accepted", "Done", etc.

    -- 2. Update shift status
    UPDATE ShiftAssignment
    SET status = @Status
    WHERE assignment_id = @ShiftAssignmentID;
    
    PRINT 'Shift status updated successfully';
END;
GO
DROP PROCEDURE IF EXISTS AssignShiftToDepartment;
GO
CREATE PROCEDURE AssignShiftToDepartment
    @DepartmentID INT,
    @ShiftID INT,
    @StartDate DATE,
    @EndDate DATE = NULL
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM Department WHERE department_id = @DepartmentID)
    BEGIN
        RAISERROR('Department does not exist', 16, 1);
        RETURN;
    END
    
  
    IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE shift_id = @ShiftID)
    BEGIN
        RAISERROR('Shift does not exist', 16, 1);
        RETURN;
    END
    
    
    DECLARE @EligibleCount INT;
    
    SELECT @EligibleCount = COUNT(*)
    FROM Employee e
    WHERE e.department_id = @DepartmentID AND e.is_active = 1;
    
    IF @EligibleCount = 0
    BEGIN
        RAISERROR('No active employees found in this department', 16, 1);
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
   
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    SELECT 
        e.employee_id,
        @ShiftID,
        @StartDate,
        @EndDate,
        'Assigned'
    FROM Employee e
    INNER JOIN Department d ON e.department_id = d.department_id
    WHERE e.department_id = @DepartmentID 
      AND e.is_active = 1
      
      AND NOT EXISTS (
          SELECT 1 
          FROM ShiftAssignment sa
          WHERE sa.employee_id = e.employee_id 
            AND sa.shift_id = @ShiftID
            AND sa.status IN ('Assigned', 'Active')
      );
    
    DECLARE @AssignedCount INT = @@ROWCOUNT;
    
    COMMIT TRANSACTION;
    
    PRINT CONCAT('Shift assigned to ', CAST(@AssignedCount AS VARCHAR), ' employees in department');
END;
GO
DROP PROCEDURE IF EXISTS AssignCustomShift;
GO

CREATE PROCEDURE AssignCustomShift
    @EmployeeID INT,
    @ShiftName VARCHAR(50),
    @ShiftType VARCHAR(50), 
    @StartTime TIME,
    @EndTime TIME,
    @StartDate DATE, 
    @EndDate DATE    
AS
BEGIN
   
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID AND is_active = 1)
    BEGIN
        RAISERROR('Employee does not exist or is inactive', 16, 1);
        RETURN;
    END
    
   
    IF @EndDate < @StartDate
    BEGIN
        RAISERROR('End Date cannot be before Start Date', 16, 1);
        RETURN;
    END

   
    IF @ShiftName IS NULL OR LTRIM(RTRIM(@ShiftName)) = ''
    BEGIN
        RAISERROR('Shift name cannot be empty', 16, 1);
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
  
    INSERT INTO ShiftSchedule (name, type, start_time, end_time, shift_date, status)
    VALUES (@ShiftName, @ShiftType, @StartTime, @EndTime, @StartDate, 1);
    
    DECLARE @NewShiftID INT = SCOPE_IDENTITY();
    
  
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@EmployeeID, @NewShiftID, @StartDate, @EndDate, 'Assigned'); 
    
    COMMIT TRANSACTION;
    
    PRINT 'Custom shift assigned successfully';
    SELECT @NewShiftID AS NewShiftID;
END;
GO
DROP PROCEDURE IF EXISTS ConfigureSplitShift;
GO

GO
CREATE PROC ConfigureSplitShift
@ShiftName varchar(50), @FirstSlotStart time, @FirstSlotEnd time, 
@SecondSlotStart time, @SecondSlotEnd time
AS
BEGIN
    SET NOCOUNT ON;
    IF @ShiftName IS NULL OR @FirstSlotStart IS NULL
        PRINT 'One of the inputs is null'
    ELSE
    BEGIN
        -- Insert Slot 1
        INSERT INTO ShiftSchedule (name, type, start_time, end_time, status)
        VALUES (@ShiftName + ' (Slot 1)', 'Split', @FirstSlotStart, @FirstSlotEnd, 1)

        -- Insert Slot 2
        INSERT INTO ShiftSchedule (name, type, start_time, end_time, status)
        VALUES (@ShiftName + ' (Slot 2)', 'Split', @SecondSlotStart, @SecondSlotEnd, 1)
        
        PRINT 'Split shift configured as two schedule entries.'
    END
END
GO
DROP PROCEDURE IF EXISTS EnableFirstInLastOut;
GO

CREATE PROCEDURE EnableFirstInLastOut
    @Enable BIT
AS
BEGIN

    IF NOT EXISTS (SELECT 1 FROM SystemAdministrator)
    BEGIN
 
        PRINT 'No System Administrator configuration record found.';
        RETURN;
    END

    
    UPDATE TOP (1) SystemAdministrator
    SET configurable_fields = CASE 
        WHEN @Enable = 1 THEN 'CalculationRule: FirstInLastOut=ENABLED'
        ELSE 'CalculationRule: FirstInLastOut=DISABLED'
    END;

    PRINT 'First In/Last Out attendance processing updated successfully';
END;
GO
DROP PROCEDURE IF EXISTS TagAttendanceSource;
GO
CREATE PROCEDURE TagAttendanceSource
    @AttendanceID INT,
    @SourceType VARCHAR(20),
    @DeviceID INT,
    @Latitude DECIMAL(10,7),
    @Longitude DECIMAL(10,7)
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM Attendance WHERE attendance_id = @AttendanceID)
    BEGIN
        RAISERROR('Attendance record does not exist', 16, 1);
        RETURN;
    END


    IF NOT EXISTS (SELECT 1 FROM Device WHERE device_id = @DeviceID)
    BEGIN
        RAISERROR('Device does not exist', 16, 1);
        RETURN;
    END
    

    IF @Latitude IS NOT NULL AND ABS(@Latitude) > 90
    BEGIN
        RAISERROR('Invalid latitude. Must be between -90 and 90', 16, 1);
        RETURN;
    END
    
    IF @Longitude IS NOT NULL AND ABS(@Longitude) > 180
    BEGIN
        RAISERROR('Invalid longitude. Must be between -180 and 180', 16, 1);
        RETURN;
    END
    
    INSERT INTO AttendanceSource (
        attendance_id, device_id, source_type, latitude, longitude, recorded_at
    )
    VALUES (
        @AttendanceID, @DeviceID, @SourceType, @Latitude, @Longitude, GETDATE()
    );
    
    PRINT 'Tagged the attendence source';
END;
GO
DROP PROCEDURE IF EXISTS SyncOfflineAttendance;
GO
CREATE PROCEDURE SyncOfflineAttendance
    @DeviceID INT,
    @EmployeeID INT,
    @ClockTime DATETIME,
    @Type VARCHAR(10),
    @ShiftID INT = NULL
AS
BEGIN
   
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Employee does not exist', 16, 1);
        RETURN;
    END
    
  
    IF @Type NOT IN ('IN', 'OUT')
    BEGIN
        RAISERROR('Type must be IN or OUT', 16, 1);
        RETURN;
    END
    
    DECLARE @AttendanceID INT;
    
 
    DECLARE @ClockTimeOnly TIME = CAST(@ClockTime AS TIME);
    
   
    DECLARE @ClockDate DATE = CAST(@ClockTime AS DATE);
    
   
    IF @Type = 'IN'
    BEGIN
        
        IF EXISTS (
            SELECT 1 
            FROM Attendance a
            INNER JOIN Employee e ON a.employee_id = e.employee_id
            WHERE a.employee_id = @EmployeeID
             
              AND CAST(DATEADD(MINUTE, 
                      DATEPART(HOUR, a.entry_time) * 60 + DATEPART(MINUTE, a.entry_time), 
                      @ClockDate) AS DATE) = @ClockDate
              AND a.exit_time IS NULL
        )
        BEGIN
            RAISERROR('Employee already clocked in for this date', 16, 1);
            RETURN;
        END
        
        INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
        VALUES (@EmployeeID, @ShiftID, @ClockTimeOnly, 'OfflineSync');
        
        SET @AttendanceID = SCOPE_IDENTITY();
    END
    
    
    IF @Type = 'OUT'
    BEGIN
        SELECT TOP 1 @AttendanceID = a.attendance_id
        FROM Attendance a
        INNER JOIN Employee e ON a.employee_id = e.employee_id
        WHERE a.employee_id = @EmployeeID
          AND CAST(DATEADD(MINUTE, 
                  DATEPART(HOUR, a.entry_time) * 60 + DATEPART(MINUTE, a.entry_time), 
                  @ClockDate) AS DATE) = @ClockDate
          AND a.exit_time IS NULL
        ORDER BY a.attendance_id DESC;
        
        IF @AttendanceID IS NULL
        BEGIN
            RAISERROR('No matching clock-in record found for this employee today', 16, 1);
            RETURN;
        END
        
        DECLARE @EntryTime TIME;
        SELECT @EntryTime = entry_time 
        FROM Attendance 
        WHERE attendance_id = @AttendanceID;
        
        
        DECLARE @Duration DECIMAL(20,2) = DATEDIFF(MINUTE, @EntryTime, @ClockTimeOnly) / 60.0;
        
        UPDATE Attendance
        SET 
            exit_time = @ClockTimeOnly,
            duration = @Duration,
            logout_method = 'OfflineSync'
        WHERE attendance_id = @AttendanceID;
    END
    
  
    IF @AttendanceID IS NOT NULL
    BEGIN
        INSERT INTO AttendanceSource (attendance_id, device_id, source_type, recorded_at)
        VALUES (@AttendanceID, @DeviceID, 'OfflineSync', @ClockTime);
    END
    
    PRINT CONCAT('Offline attendance synced successfully for employee ', CAST(@EmployeeID AS VARCHAR));
END;
GO 
DROP PROCEDURE IF EXISTS LogAttendanceEdit;
GO
CREATE PROC LogAttendanceEdit
@AttendanceID int, @EditedBy int, @OldValue datetime, @NewValue datetime, @EditTimestamp datetime
AS
BEGIN
    SET NOCOUNT ON;
    IF @AttendanceID IS NULL
        PRINT 'One of the inputs is null'
    ELSE
    BEGIN
        INSERT INTO AttendanceLog (attendance_id, actor, timestamp, reason)
        VALUES (@AttendanceID, CAST(@EditedBy AS VARCHAR), @EditTimestamp, 
                'Edit: ' + CAST(@OldValue AS VARCHAR) + ' to ' + CAST(@NewValue AS VARCHAR))
        
        PRINT 'Attendance edit logged successfully.'
    END
END
GO
GO
DROP PROCEDURE IF EXISTS ApplyHolidayOverrides;
GO

CREATE PROCEDURE ApplyHolidayOverrides
    @HolidayID INT,
    @EmployeeID INT
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Employee not found', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Exception WHERE exception_id = @HolidayID)
    BEGIN
        RAISERROR('Holiday/Exception not found', 16, 1);
        RETURN;
    END


    IF EXISTS (
        SELECT 1 FROM Employee_Exception 
        WHERE employee_id = @EmployeeID AND exception_id = @HolidayID
    )
    BEGIN
        RAISERROR('This holiday override is already applied to this employee', 16, 1);
        RETURN;
    END

    INSERT INTO Employee_Exception (employee_id, exception_id)
    VALUES (@EmployeeID, @HolidayID);

    PRINT 'All Overrides applied succesfully'; 

END;
GO
DROP PROCEDURE IF EXISTS ManageUserAccounts;
GO
CREATE PROCEDURE ManageUserAccounts
    @UserID INT,
    @Role VARCHAR(50) = NULL,
    @Action VARCHAR(20)
AS
BEGIN

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @UserID)
    BEGIN
        RAISERROR('User does not exist', 16, 1);
        RETURN;
    END
    
    DECLARE @ActionUpper VARCHAR(20) = UPPER(@Action);
   
    IF @ActionUpper = 'LOCK'
    BEGIN
        UPDATE Employee 
        SET account_status = 'Locked' 
        WHERE employee_id = @UserID;
        
        PRINT CONCAT('Account locked for user ', CAST(@UserID AS VARCHAR));
    END
    ELSE IF @ActionUpper = 'UNLOCK'
    BEGIN
        UPDATE Employee 
        SET account_status = 'Active' 
        WHERE employee_id = @UserID;
        
        PRINT CONCAT('Account unlocked for user ', CAST(@UserID AS VARCHAR));
    END
    ELSE IF @ActionUpper = 'ASSIGN_ROLE'
    BEGIN
        IF @Role IS NULL OR LTRIM(RTRIM(@Role)) = ''
        BEGIN
            RAISERROR('Role parameter is required for ASSIGN_ROLE action', 16, 1);
            RETURN;
        END
        
     
        DECLARE @RoleID INT;
        
        SELECT @RoleID = r.role_id
        FROM Role r
        WHERE r.role_name = @Role;
        
        IF @RoleID IS NULL
        BEGIN
            RAISERROR('Role not found', 16, 1);
            RETURN;
        END
     
        IF EXISTS (
            SELECT 1 
            FROM Employee_Role er
            WHERE er.employee_id = @UserID AND er.role_id = @RoleID
        )
        BEGIN
            PRINT 'Role already assigned to user';
            RETURN;
        END
        
  
        INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
        VALUES (@UserID, @RoleID, GETDATE());
        
        PRINT CONCAT('Role "', @Role, '" assigned to user ', CAST(@UserID AS VARCHAR));
    END
    ELSE
    BEGIN
        RAISERROR('Invalid action. Must be: LOCK, UNLOCK, or ASSIGN_ROLE', 16, 1);
        RETURN;
    END
END;
GO
DROP PROCEDURE IF EXISTS CreateContract;
GO

CREATE PROCEDURE CreateContract
    @EmployeeID INT,
    @Type VARCHAR(50),
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    -- 1. Validate employee exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Employee does not exist', 16, 1);
        RETURN;
    END
    
    -- 2. Validate dates (This is the only logical constraint we keep)
    -- It is physically impossible for a contract to end before it starts.
    IF @StartDate >= @EndDate
    BEGIN
        RAISERROR('Contract end date must be after start date', 16, 1);
        RETURN;
    END
    
    
    BEGIN TRANSACTION;
    
   
    INSERT INTO Contract (
        contract_type, 
        contract_start_date, 
        contract_end_date, 
        contract_current_state
    )
    VALUES (
        @Type, 
        @StartDate, 
        @EndDate, 
        'Active'
    );
    
    DECLARE @ContractID INT = SCOPE_IDENTITY();
    
   
    UPDATE Employee 
    SET contract_id = @ContractID 
    WHERE employee_id = @EmployeeID;
    
    COMMIT TRANSACTION;
    
    PRINT 'Contract created and assigned successfully';
    SELECT @ContractID AS NewContractID;
END;
GO
DROP PROCEDURE IF EXISTS RenewContract;
GO

CREATE PROCEDURE RenewContract
    @ContractID INT,
    @NewEndDate DATE
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM Contract WHERE contract_id = @ContractID)
    BEGIN
        RAISERROR('Contract does not exist', 16, 1);
        RETURN;
    END
    
    DECLARE @StartDate DATE;
    SELECT @StartDate = contract_start_date FROM Contract WHERE contract_id = @ContractID;
    
  
    IF @NewEndDate <= @StartDate
    BEGIN
        RAISERROR('New end date must be after the contract start date', 16, 1);
        RETURN;
    END
    

    UPDATE Contract
    SET 
        contract_end_date = @NewEndDate,
        contract_current_state = 'Renewed' 
    WHERE contract_id = @ContractID;
    
    PRINT 'Contract renewed successfully';
END;
GO
/*
DROP PROCEDURE IF EXISTS ApproveLeaveRequest;
GO

GO
CREATE PROC ApproveLeaveRequest
@LeaveRequestID int,
@ApproverID int,
@Status varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    

    IF @LeaveRequestID IS NULL OR @ApproverID IS NULL OR @Status IS NULL
        PRINT 'One of the inputs is null'
    

    ELSE IF NOT EXISTS (SELECT 1 FROM LeaveRequest WHERE request_id = @LeaveRequestID)
        PRINT 'Error: Leave Request ID not found.'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ApproverID)
        PRINT 'Error: Approver ID not found.'
        
  
    ELSE IF @Status NOT IN ('Approved', 'Rejected')
        PRINT 'Error: Invalid status. Use "Approved" or "Rejected".'
        
   
    ELSE
    BEGIN
        UPDATE LeaveRequest
        SET status = @Status
        WHERE request_id = @LeaveRequestID

        PRINT 'Leave request status updated successfully.'
    END
END
*/
GO
DROP PROCEDURE IF EXISTS AssignMission;
GO

CREATE PROCEDURE AssignMission
    @EmployeeID INT,
    @ManagerID INT,
    @Destination VARCHAR(50),
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Employee not found', 16, 1);
        RETURN;
    END
    
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ManagerID)
    BEGIN
        RAISERROR('Manager not found', 16, 1);
        RETURN;
    END
    
    IF @EndDate < @StartDate
    BEGIN
        RAISERROR('End Date cannot be before Start Date', 16, 1);
        RETURN;
    END
    
    --

    -- 4. Create Mission
    INSERT INTO Mission (
        destination, 
        start_date, 
        end_date, 
        status, 
        employee_id, 
        manager_id
    )
    VALUES (
        @Destination, 
        @StartDate, 
        @EndDate, 
        'Assigned', 
        @EmployeeID, 
        @ManagerID
    );
    
  
    PRINT 'Mission assigned successfully';
END;
GO
DROP PROCEDURE IF EXISTS ReviewReimbursement;
GO
CREATE PROC ReviewReimbursement
@ClaimID int, 
@ApproverID int, 
@Decision varchar(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Check for NULLs
    IF @ClaimID IS NULL OR @ApproverID IS NULL OR @Decision IS NULL
        PRINT 'One of the inputs is null'
    
    -- 2. Validate IDs exist
    ELSE IF NOT EXISTS (SELECT 1 FROM Reimbursement WHERE reimbursement_id = @ClaimID)
        PRINT 'Error: Reimbursement Claim ID not found.'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ApproverID)
        PRINT 'Error: Approver ID not found.'
        
    -- 3. Validate Decision Input
    ELSE IF @Decision NOT IN ('Approved', 'Rejected')
        PRINT 'Error: Invalid decision. Use "Approved" or "Rejected".'

    ELSE
    BEGIN
        -- 4. Perform Update
        UPDATE Reimbursement
        SET current_status = @Decision,
            approval_date = GETDATE() -- Update the date to now
        WHERE reimbursement_id = @ClaimID

        PRINT 'Reimbursement claim has been ' + @Decision + ' successfully.'
    END
END
GO
GO
DROP PROCEDURE IF EXISTS GetActiveContracts;
GO

CREATE PROCEDURE GetActiveContracts
AS
BEGIN
    
    SELECT 
        c.contract_id,
        e.full_name AS EmployeeName,
        c.contract_type,
        c.contract_start_date,
        c.contract_end_date,
        c.contract_current_state,
        
        DATEDIFF(DAY, GETDATE(), c.contract_end_date) AS DaysRemaining
    FROM Contract c
    INNER JOIN Employee e ON c.contract_id = e.contract_id
    WHERE c.contract_current_state = 'Active' 
       OR c.contract_end_date >= GETDATE() -- Include contracts that haven't expired yet
    ORDER BY c.contract_end_date ASC;
END;
GO
DROP PROCEDURE IF EXISTS GetTeamByManager;
GO

CREATE PROCEDURE GetTeamByManager
    @ManagerID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ManagerID)
    BEGIN
        RAISERROR('Manager does not exist', 16, 1);
        RETURN;
    END
    
   
    SELECT 
        employee_id,
        first_name,
        last_name
    FROM Employee
    WHERE manager_id = @ManagerID;
END;
GO
DROP PROCEDURE IF EXISTS UpdateLeavePolicy;
GO

CREATE PROCEDURE UpdateLeavePolicy
    @PolicyID INT,
    @EligibilityRules VARCHAR(200), -- Added to match PDF
    @NoticePeriod INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM LeavePolicy WHERE policy_id = @PolicyID)
    BEGIN
        RAISERROR('Leave policy does not exist', 16, 1);
        RETURN;
    END
    
   
    IF @NoticePeriod < 0
    BEGIN
        RAISERROR('Notice period cannot be negative', 16, 1);
        RETURN;
    END
    
    
    UPDATE LeavePolicy
    SET 
        eligibility_rules = @EligibilityRules,
        notice_period = @NoticePeriod
    WHERE policy_id = @PolicyID;
    
    PRINT 'Confirmation message'; -- Matches PDF requirement
END;
go
DROP PROCEDURE IF EXISTS GetExpiringContracts;
GO
GO
CREATE PROC GetExpiringContracts
@DaysBefore int
AS
BEGIN
    SET NOCOUNT ON;


    IF @DaysBefore IS NULL
        PRINT 'One of the inputs is null'
    ELSE
    BEGIN
   
        SELECT 
            E.employee_id AS [Employee ID],
            E.first_name + ' ' + E.last_name AS [Employee Name],
            C.contract_id AS [Contract ID],
            C.contract_type AS [Type],
            C.contract_end_date AS [Expiration Date],
            DATEDIFF(DAY, GETDATE(), C.contract_end_date) AS [Days Until Expiry]
        FROM Contract C
        INNER JOIN Employee E ON C.contract_id = E.contract_id
        WHERE 
            C.contract_end_date IS NOT NULL 
            AND DATEDIFF(DAY, GETDATE(), C.contract_end_date) BETWEEN 0 AND @DaysBefore
        ORDER BY C.contract_end_date ASC
    END
END
GO

GO
DROP PROCEDURE IF EXISTS AssignDepartmentHead;
GO

CREATE PROCEDURE AssignDepartmentHead
    @DepartmentID INT,
    @ManagerID INT -- Renamed to match PDF 
AS
BEGIN
   
    IF NOT EXISTS (SELECT 1 FROM Department WHERE department_id = @DepartmentID)
    BEGIN
        RAISERROR('Department not found', 16, 1);
        RETURN;
    END
    
    
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ManagerID AND is_active = 1)
    BEGIN
        RAISERROR('Manager not found or inactive', 16, 1);
        RETURN;
    END
    
   
    UPDATE Department
    SET department_head_id = @ManagerID
    WHERE department_id = @DepartmentID;
    
    PRINT 'Department head assigend '; 
END;
GO
DROP PROCEDURE IF EXISTS CreateEmployeeProfile;
GO

CREATE PROCEDURE CreateEmployeeProfile
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @DepartmentID INT,
    @RoleID INT, -- Changed from PositionID to match PDF
    @HireDate DATE,
    @Email VARCHAR(100),
    @Phone VARCHAR(20),
    @NationalID VARCHAR(50),
    @DateOfBirth DATE,
    @CountryOfBirth VARCHAR(100)
AS
BEGIN
  
    IF @FirstName IS NULL OR @LastName IS NULL OR @NationalID IS NULL
    BEGIN
        RAISERROR('Name and National ID are required', 16, 1);
        RETURN;
    END
    
  
    IF EXISTS (SELECT 1 FROM Employee WHERE national_id = @NationalID)
    BEGIN
        RAISERROR('National ID already exists', 16, 1);
        RETURN;
    END
    
    IF @DepartmentID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Department WHERE department_id = @DepartmentID)
    BEGIN
        RAISERROR('Invalid Department ID', 16, 1);
        RETURN;
    END

    IF @RoleID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Role WHERE role_id = @RoleID)
    BEGIN
        RAISERROR('Invalid Role ID', 16, 1);
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
  
    INSERT INTO Employee (
        first_name, last_name, department_id, hire_date, 
        email, phone, national_id, date_of_birth, country_of_birth,
        is_active, profile_completion, account_status
    )
    VALUES (
        @FirstName, @LastName, @DepartmentID, @HireDate, 
        @Email, @Phone, @NationalID, @DateOfBirth, @CountryOfBirth,
        1, 0, 'Pending'
    );
    
    DECLARE @NewEmployeeID INT = SCOPE_IDENTITY();

   
    IF @RoleID IS NOT NULL
    BEGIN
        INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
        VALUES (@NewEmployeeID, @RoleID, GETDATE());
    END
    
    COMMIT TRANSACTION;
    
    PRINT 'Employee Profile Created. New ID: ' + CAST(@NewEmployeeID AS VARCHAR);
END;
GO

--Procedure 12
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

--Procedure 13
CREATE PROCEDURE SetProfileCompleteness
    @EmployeeID INT,
    @CompletenessPercentage INT
AS
BEGIN
    IF @CompletenessPercentage NOT BETWEEN 0 AND 100
    BEGIN
        PRINT 'Error: Completeness percentage must be between 0 and 100.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        PRINT 'Error: Employee not found.';
        RETURN;
    END

    UPDATE Employee
    SET profile_completion = @CompletenessPercentage
    WHERE employee_id = @EmployeeID;

    -- Confirmation message
    PRINT 'Profile completeness updated successfully.';
END;
GO

--Procedure 14
CREATE PROCEDURE GenerateProfileReport
    @FilterField VARCHAR(50),
    @FilterValue VARCHAR(100)
AS
BEGIN
    -- Text fields
    IF @FilterField = 'first_name'
    BEGIN
        SELECT * FROM Employee WHERE first_name = @FilterValue; RETURN;
    END
    IF @FilterField = 'last_name'
    BEGIN
        SELECT * FROM Employee WHERE last_name = @FilterValue; RETURN;
    END
    IF @FilterField = 'country_of_birth'
    BEGIN
        SELECT * FROM Employee WHERE country_of_birth = @FilterValue; RETURN;
    END
    IF @FilterField = 'phone'
    BEGIN
        SELECT * FROM Employee WHERE phone = @FilterValue; RETURN;
    END
    IF @FilterField = 'email'
    BEGIN
        SELECT * FROM Employee WHERE email = @FilterValue; RETURN;
    END
    IF @FilterField = 'address'
    BEGIN
        SELECT * FROM Employee WHERE address = @FilterValue; RETURN;
    END
    IF @FilterField = 'emergency_contact_name'
    BEGIN
        SELECT * FROM Employee WHERE emergency_contact_name = @FilterValue; RETURN;
    END
    IF @FilterField = 'emergency_contact_phone'
    BEGIN
        SELECT * FROM Employee WHERE emergency_contact_phone = @FilterValue; RETURN;
    END
    IF @FilterField = 'relationship'
    BEGIN
        SELECT * FROM Employee WHERE relationship = @FilterValue; RETURN;
    END
    IF @FilterField = 'biography'
    BEGIN
        SELECT * FROM Employee WHERE biography = @FilterValue; RETURN;
    END
    IF @FilterField = 'profile_image'
    BEGIN
        SELECT * FROM Employee WHERE profile_image = @FilterValue; RETURN;
    END
    IF @FilterField = 'employment_progress'
    BEGIN
        SELECT * FROM Employee WHERE employment_progress = @FilterValue; RETURN;
    END
    IF @FilterField = 'account_status'
    BEGIN
        SELECT * FROM Employee WHERE account_status = @FilterValue; RETURN;
    END
    IF @FilterField = 'employment_status'
    BEGIN
        SELECT * FROM Employee WHERE employment_status = @FilterValue; RETURN;
    END

    -- Integer fields
    DECLARE @IntValue INT;
    IF @FilterField IN ('department_id','position_id','manager_id','contract_id','tax_form_id','salary_type_id','pay_grade','profile_completion')
    BEGIN
        SET @IntValue = TRY_CONVERT(INT, @FilterValue);
        IF @IntValue IS NULL
        BEGIN
            PRINT 'Invalid value for ' + @FilterField + '. Must be an integer.';
            RETURN;
        END
        IF @FilterField = 'department_id' SELECT * FROM Employee WHERE department_id = @IntValue;
        IF @FilterField = 'position_id' SELECT * FROM Employee WHERE position_id = @IntValue;
        IF @FilterField = 'manager_id' SELECT * FROM Employee WHERE manager_id = @IntValue;
        IF @FilterField = 'contract_id' SELECT * FROM Employee WHERE contract_id = @IntValue;
        IF @FilterField = 'tax_form_id' SELECT * FROM Employee WHERE tax_form_id = @IntValue;
        IF @FilterField = 'salary_type_id' SELECT * FROM Employee WHERE salary_type_id = @IntValue;
        IF @FilterField = 'pay_grade' SELECT * FROM Employee WHERE pay_grade = @IntValue;
        IF @FilterField = 'profile_completion' SELECT * FROM Employee WHERE profile_completion = @IntValue;
        RETURN;
    END

    -- BIT fields
    DECLARE @BitValue BIT;
    IF @FilterField = 'is_active'
    BEGIN
        IF @FilterValue NOT IN ('0','1')
        BEGIN
            PRINT 'Invalid value for is_active. Must be 0 or 1.';
            RETURN;
        END
        SET @BitValue = CAST(@FilterValue AS BIT);
        SELECT * FROM Employee WHERE is_active = @BitValue;
        RETURN;
    END

    -- Date fields
    DECLARE @DateValue DATE;
    IF @FilterField = 'date_of_birth' OR @FilterField = 'hire_date'
    BEGIN
        SET @DateValue = TRY_CONVERT(DATE, @FilterValue);
        IF @DateValue IS NULL
        BEGIN
            PRINT 'Invalid date value for ' + @FilterField;
            RETURN;
        END
        IF @FilterField = 'date_of_birth' SELECT * FROM Employee WHERE date_of_birth = @DateValue;
        IF @FilterField = 'hire_date' SELECT * FROM Employee WHERE hire_date = @DateValue;
        RETURN;
    END

    PRINT 'Filter field not recognized.';
END
GO

--Procedure 15
CREATE PROCEDURE CreateShiftType
    @ShiftID INT,
    @Name VARCHAR(100),
    @Type VARCHAR(50),
    @Start_Time TIME,
    @End_Time TIME,
    @Break_Duration DECIMAL(20,2),
    @Shift_Date DATE,
    @Status BIT
AS
BEGIN
    IF @Start_Time >= @End_Time
    BEGIN
        PRINT 'Error: Start time must be earlier than end time.';
        RETURN;
    END

    IF @Break_Duration < 0
    BEGIN
        PRINT 'Error: Break duration cannot be negative.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM ShiftSchedule WHERE shift_id = @ShiftID)
    BEGIN
        PRINT 'Error: ShiftID already exists.';
        RETURN;
    END

    INSERT INTO ShiftSchedule (shift_id, name, type, start_time, end_time, break_duration, shift_date, status)
    VALUES (@ShiftID, @Name, @Type, @Start_Time, @End_Time, @Break_Duration, @Shift_Date, @Status);

    PRINT 'Shift type created successfully.';
END;
GO

--Procedure 16 (Removed)
--Procedure 17
CREATE PROCEDURE AssignRotationalShift
    @EmployeeID INT,
    @ShiftCycle INT,
    @StartDate DATE,
    @EndDate DATE,
    @Status VARCHAR(20)
AS
BEGIN
    -- 1. Validate Employee
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Employee not found', 16, 1);
        RETURN;
    END

    -- 2. Validate Shift Cycle Exists
    IF NOT EXISTS (SELECT 1 FROM ShiftCycle WHERE cycle_id = @ShiftCycle)
    BEGIN
        RAISERROR('Shift Cycle not found', 16, 1);
        RETURN;
    END

    -- 3. Logic: Find the Shift ID linked to this Cycle
    -- We use the ShiftCycleAssignment table to bridge the gap.
    -- We pick the first shift in the cycle to start with.
    DECLARE @TargetShiftID INT;
    
    SELECT TOP 1 @TargetShiftID = shift_id 
    FROM ShiftCycleAssignment 
    WHERE cycle_id = @ShiftCycle 
    ORDER BY order_number ASC;

    -- If the cycle exists but has no shifts linked to it, we can't assign anything.
    IF @TargetShiftID IS NULL
    BEGIN
        RAISERROR('No shifts defined for this cycle', 16, 1);
        RETURN;
    END

    -- 4. Validate Dates
    IF @EndDate < @StartDate
    BEGIN
        RAISERROR('End Date cannot be before Start Date', 16, 1);
        RETURN;
    END

    -- 5. Assign the RESOLVED Shift ID (Not the Cycle ID)
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@EmployeeID, @TargetShiftID, @StartDate, @EndDate, @Status);

    PRINT 'Assigning Rotational Shift has been Completed';
END;
GO

--Procedure 18 (Doesn’t Calculate Shift Expiry from End Date Js creates the notif)
CREATE PROCEDURE NotifyShiftExpiry
    @EmployeeID INT,
    @ShiftAssignmentID INT,
    @ExpiryDate DATE
AS
BEGIN
    DECLARE @MessageContent VARCHAR(1000);
    DECLARE @NotificationID INT;

    IF NOT EXISTS (SELECT 1 FROM ShiftAssignment WHERE assignment_id = @ShiftAssignmentID AND employee_id = @EmployeeID)
    BEGIN
        PRINT 'Shift assignment not found for this employee.';
        RETURN;
    END

    SET @MessageContent = 'Your shift assignment (ID: ' + CAST(@ShiftAssignmentID AS VARCHAR) + ') is nearing expiry on ' + CONVERT(VARCHAR, @ExpiryDate, 23) + '.';

    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
    VALUES (@MessageContent, GETDATE(), 'High', 'Unread', 'ShiftExpiry');

    SET @NotificationID = SCOPE_IDENTITY();

    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    VALUES (@EmployeeID, @NotificationID, 'Pending', GETDATE());

    PRINT 'Notification created and assigned to the employee successfully.';
END
GO

--Procedure 19
CREATE PROCEDURE DefineShortTimeRules
    @RuleName VARCHAR(50),
    @LateMinutes INT,
    @EarlyLeaveMinutes INT,
    @PenaltyType VARCHAR(50)
AS
BEGIN
    -- 1. Validate Inputs
    IF @RuleName IS NULL OR @RuleName = ''
    BEGIN
        RAISERROR('Rule Name cannot be empty', 16, 1);
        RETURN;
    END

    -- Physical Logic: Time cannot be negative
    IF @LateMinutes < 0 OR @EarlyLeaveMinutes < 0
    BEGIN
        RAISERROR('Minutes cannot be negative', 16, 1);
        RETURN;
    END

    -- 2. Insert Parent Policy (PayrollPolicy)
    INSERT INTO PayrollPolicy (type, description, effective_date)
    VALUES (
        'ShortTimeRule', 
        CONCAT(@RuleName, ' (Early Limit: ', @EarlyLeaveMinutes, 'm)'), 
        GETDATE()
    );

    -- REPLACED SCOPE_IDENTITY() WITH MAX SELECT
    -- This grabs the highest ID in the table (which is the one we just created)
    DECLARE @PolicyID INT;
    SELECT @PolicyID = MAX(policy_id) FROM PayrollPolicy;

    -- 3. Insert Specific Lateness Rule
    INSERT INTO LatenessPolicy (policy_id, grace_period_mins, deduction_rate)
    VALUES (@PolicyID, @LateMinutes, @PenaltyType);

    PRINT 'Short term rules have been defined';
END;
GO

--Procedure 20
CREATE PROCEDURE SetGracePeriod
    @Minutes INT
AS
BEGIN
    IF @Minutes < 0
    BEGIN
        PRINT 'Invalid value. Grace period must be zero or positive.';
        RETURN;
    END

    UPDATE LatenessPolicy
    SET grace_period_mins = @Minutes;

    PRINT 'Grace period updated successfully to ' + CAST(@Minutes AS VARCHAR(10)) + ' minutes.';
END;
GO

--Procedure 21
CREATE PROCEDURE DefinePenaltyThreshold
    @LateMinutes INT,
    @DeductionType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @ExistingPolicyID INT;

        -- 1. Check if a lateness policy for this threshold already exists
        SELECT @ExistingPolicyID = policy_id
        FROM LatenessPolicy
        WHERE grace_period_mins = @LateMinutes;

        IF @ExistingPolicyID IS NOT NULL
        BEGIN
            -- 2a. Update existing policy's deduction rate
            UPDATE LatenessPolicy
            SET deduction_rate = @DeductionType
            WHERE policy_id = @ExistingPolicyID;
        END
        ELSE
        BEGIN
            -- 2b. Insert a new lateness policy
            INSERT INTO LatenessPolicy (grace_period_mins, deduction_rate)
            VALUES (@LateMinutes, @DeductionType);
        END

        -- 3. Return confirmation message
        SELECT 'Penalty threshold defined successfully for ' 
               + CAST(@LateMinutes AS VARCHAR(10)) 
               + ' minutes late as ' + @DeductionType AS ConfirmationMessage;

    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Failed to define penalty threshold: %s', 16, 1, @ErrorMessage);
    END CATCH
END
GO

--Procedure 22 (Review, where should I place max and min)
CREATE PROCEDURE DefinePermissionLimits
    @MinHours INT,   -- mapped to LatenessPolicy.grace_period_mins
    @MaxHours INT    -- mapped to OvertimePolicy.max_hours_per_month
AS
BEGIN
    SET NOCOUNT ON;
    -- 1. Update minimum allowed lateness (grace period)
    UPDATE LatenessPolicy
    SET grace_period_mins = @MinHours;
    -- 2. Update maximum allowed overtime hours
    UPDATE OvertimePolicy
    SET max_hours_per_month = @MaxHours;
    -- 3. Confirm completion
    SELECT 'Permission limits updated successfully.' AS ConfirmationMessage;
END;
GO

--Procedure 23
CREATE PROCEDURE EscalatePendingRequests
    @Deadline DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME = GETDATE();

    -- 1. Check if any pending requests need escalation
    IF NOT EXISTS (
        SELECT 1
        FROM LeaveRequest
        WHERE status = 'Pending'
          AND (approval_timing IS NULL OR approval_timing < @Deadline)
    )
    BEGIN
        PRINT 'No pending leave requests to escalate.';
        RETURN;
    END;

    -- 2. Create a notification for each overdue request for its manager
    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
    SELECT
        'Leave Request #' + CAST(LR.request_id AS VARCHAR(10)) +
        ' has exceeded the decision deadline and has been escalated.' AS message_content,
        @Now AS timestamp,
        'High' AS urgency,
        'Unread' AS read_status,
        'Escalation' AS notification_type
    FROM LeaveRequest LR
    INNER JOIN EmployeeHierarchy EH
        ON EH.employee_id = LR.employee_id     -- find employee
       AND EH.hierarchy_level = 1              -- direct manager
    WHERE LR.status = 'Pending'
      AND (LR.approval_timing IS NULL OR LR.approval_timing < @Deadline);

    -- 3. Deliver the notification to the corresponding manager
    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT
        EH.manager_id AS employee_id,
        N.notification_id,
        'Delivered' AS delivery_status,
        @Now AS delivered_at
    FROM Notification N
    INNER JOIN LeaveRequest LR
        ON N.message_content LIKE 
            'Leave Request #' + CAST(LR.request_id AS VARCHAR(10)) + '%'
    INNER JOIN EmployeeHierarchy EH
        ON EH.employee_id = LR.employee_id
       AND EH.hierarchy_level = 1
    WHERE N.timestamp = @Now
      AND LR.status = 'Pending'
      AND (LR.approval_timing IS NULL OR LR.approval_timing < @Deadline);

    -- 4. Update the request’s status to "Escalated"
    UPDATE LeaveRequest
    SET status = 'Escalated'
    WHERE status = 'Pending'
      AND (approval_timing IS NULL OR approval_timing < @Deadline);


    -- 5. Confirmation
    PRINT 'All overdue pending leave requests have been escalated.';
END;
GO

--Procedure 24
CREATE PROCEDURE LinkVacationToShift
    @VacationPackageID INT,
    @EmployeeID INT
AS
BEGIN
    -- Check if the employee exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        PRINT 'Employee does not exist.';
        RETURN;
    END

    -- Check if the vacation package exists
    IF NOT EXISTS (SELECT 1 FROM VacationLeave WHERE leave_id = @VacationPackageID)
    BEGIN
        PRINT 'Vacation package does not exist.';
        RETURN;
    END

    -- Update all future shift assignments for this employee to "On Leave"
    UPDATE ShiftAssignment
    SET status = 'On Leave'
    WHERE employee_id = @EmployeeID
      AND start_date >= GETDATE();

    -- Optionally, we could also log the vacation linkage if needed
    PRINT 'Vacation package linked to employee schedule successfully.';
END;
GO
--Procedure 25
CREATE PROCEDURE ConfigureLeavePolicies
AS
BEGIN
    DECLARE @msg VARCHAR(255);

    -- 1. Check if all required leave policies already exist
    IF NOT EXISTS (
        SELECT 1 FROM LeavePolicy
        WHERE name IN (
            'Vacation Leave Policy',
            'Sick Leave Policy',
            'Probation Leave Policy',
            'Holiday Leave Policy'
        )
        GROUP BY name
        HAVING COUNT(*) = 4
    )

    BEGIN
        -- 2. Insert ONLY missing policies
        IF NOT EXISTS (SELECT 1 FROM LeavePolicy WHERE name = 'Vacation Leave Policy')
        BEGIN
            INSERT INTO LeavePolicy (name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
            VALUES ('Vacation Leave Policy', 'Annual paid leave for employees', 'All full-time employees eligible', 14, 'Vacation', 1);
        END

        IF NOT EXISTS (SELECT 1 FROM LeavePolicy WHERE name = 'Sick Leave Policy')
        BEGIN
            INSERT INTO LeavePolicy (name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
            VALUES ('Sick Leave Policy', 'Paid leave for medical reasons', 'All employees eligible immediately', 0, 'Sick', 0);
        END

        IF NOT EXISTS (SELECT 1 FROM LeavePolicy WHERE name = 'Probation Leave Policy')
        BEGIN
            INSERT INTO LeavePolicy (name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
            VALUES ('Probation Leave Policy', 'Leave during probation', 'Employees on probation eligible after 1 month', 0, 'Probation', 0);
        END

        IF NOT EXISTS (SELECT 1 FROM LeavePolicy WHERE name = 'Holiday Leave Policy')
        BEGIN
            INSERT INTO LeavePolicy (name, purpose, eligibility_rules, notice_period, special_leave_type, reset_on_new_year)
            VALUES ('Holiday Leave Policy', 'Official holidays recognized by company', 'All employees eligible', 0, 'Holiday', 1);
        END

        SET @msg = 'Missing leave policies have been added successfully.';
    END
    ELSE
    BEGIN
        -- 3. All policies exist ? no need to configure again
        SET @msg = 'All leave policies are already fully configured.';
    END

    -- 4. Return confirmation message
    SELECT @msg AS ConfirmationMessage;
END
GO


--Procedure 26
CREATE PROCEDURE AuthenticateLeaveAdmin
    @AdminID INT,
    @Password VARCHAR(100)
AS
BEGIN
    DECLARE @msg NVARCHAR(255);

    -- Check if the administrator exists and password matches
    IF EXISTS (
        SELECT 1
        FROM HRAdministrator
        WHERE employee_id = @AdminID
          AND password = @Password  -- Plain text for now; hashing recommended
    )
    BEGIN
        SET @msg = 'Authentication successful. Welcome, Administrator!';
    END
    ELSE
    BEGIN
        SET @msg = 'Authentication failed. Invalid Admin ID or password.';
    END

    -- Return confirmation message
    SELECT @msg AS ConfirmationMessage;
END
GO
--Procedure 27
CREATE PROCEDURE ApplyLeaveConfiguration
AS
BEGIN
    DECLARE @msg VARCHAR(255);
    DECLARE @VacationID INT, @SickID INT, @ProbationID INT, @HolidayID INT;

    -- 1. Ensure all required leave policies exist before applying
    IF NOT EXISTS (
        SELECT 1 
        FROM LeavePolicy
        WHERE name IN (
            'Vacation Leave Policy',
            'Sick Leave Policy',
            'Probation Leave Policy',
            'Holiday Leave Policy'
        )
        GROUP BY name
        HAVING COUNT(*) = 4
    )
    BEGIN
        RAISERROR('Cannot apply configuration. One or more required leave policies are missing.', 16, 1);
        RETURN;
    END;

    -- 2. Insert Leave base records ONLY if they do not already exist
    -- Vacation Leave
    IF NOT EXISTS (SELECT 1 FROM Leave WHERE leave_type = 'Vacation')
    BEGIN
        INSERT INTO Leave (leave_type, leave_description)
        VALUES ('Vacation', 'Paid annual leave');
        SET @VacationID = SCOPE_IDENTITY();
    END
    ELSE
        SELECT @VacationID = leave_id FROM Leave WHERE leave_type = 'Vacation';

    -- Sick Leave
    IF NOT EXISTS (SELECT 1 FROM Leave WHERE leave_type = 'Sick')
    BEGIN
        INSERT INTO Leave (leave_type, leave_description)
        VALUES ('Sick', 'Medical sick leave');
        SET @SickID = SCOPE_IDENTITY();
    END
    ELSE
        SELECT @SickID = leave_id FROM Leave WHERE leave_type = 'Sick';

    -- Probation Leave
    IF NOT EXISTS (SELECT 1 FROM Leave WHERE leave_type = 'Probation')
    BEGIN
        INSERT INTO Leave (leave_type, leave_description)
        VALUES ('Probation', 'Leave during employee probation period');
        SET @ProbationID = SCOPE_IDENTITY();
    END
    ELSE
        SELECT @ProbationID = leave_id FROM Leave WHERE leave_type = 'Probation';

    -- Holiday Leave
    IF NOT EXISTS (SELECT 1 FROM Leave WHERE leave_type = 'Holiday')
    BEGIN
        INSERT INTO Leave (leave_type, leave_description)
        VALUES ('Holiday', 'Public or official holidays');
        SET @HolidayID = SCOPE_IDENTITY();
    END
    ELSE
        SELECT @HolidayID = leave_id FROM Leave WHERE leave_type = 'Holiday';

    -- 3. Insert subtype records ONLY if missing
    -- VacationLeave subtype
    IF NOT EXISTS (SELECT 1 FROM VacationLeave WHERE leave_id = @VacationID)
    BEGIN
        INSERT INTO VacationLeave (leave_id, carry_over_days, approving_manager)
        VALUES (@VacationID, 5, 'Department Manager');
    END

    -- SickLeave subtype
    IF NOT EXISTS (SELECT 1 FROM SickLeave WHERE leave_id = @SickID)
    BEGIN
        INSERT INTO SickLeave (leave_id, medical_cert_required, physician_id)
        VALUES (@SickID, 1, NULL);
    END

    -- ProbationLeave subtype
    IF NOT EXISTS (SELECT 1 FROM ProbationLeave WHERE leave_id = @ProbationID)
    BEGIN
        INSERT INTO ProbationLeave (leave_id, eligibility_start_date, probation_period)
        VALUES (@ProbationID, GETDATE(), 90);
    END

    -- HolidayLeave subtype
    IF NOT EXISTS (SELECT 1 FROM HolidayLeave WHERE leave_id = @HolidayID)
    BEGIN
        INSERT INTO HolidayLeave (leave_id, holiday_name, official_recognition, regional_scope)
        VALUES (@HolidayID, 'General Holiday', 1, 'National');
    END

    -- 4. Finish
    SET @msg = 'Leave configuration has been successfully applied.';
    SELECT @msg AS ConfirmationMessage;

END
GO

--Procedure 28
CREATE PROCEDURE UpdateLeaveEntitlements
    @EmployeeID INT
AS
BEGIN
    -- 0. Determine approving manager from EmployeeHierarchy
    DECLARE @ApprovingManagerID INT;

    SELECT TOP 1 @ApprovingManagerID = manager_id
    FROM EmployeeHierarchy
    WHERE employee_id = @EmployeeID
    ORDER BY hierarchy_level ASC;  -- closest manager first

    -- Convert manager_id to text for VacationLeave.approving_manager
    DECLARE @ApprovingManager VARCHAR(100);
    SET @ApprovingManager = 
        CASE 
            WHEN @ApprovingManagerID IS NULL THEN 'No Manager Assigned'
            ELSE CAST(@ApprovingManagerID AS VARCHAR(100))
        END;


    -- 1. VACATION LEAVE
    INSERT INTO Leave (leave_type, leave_description)
    VALUES ('Vacation', 'Standard annual vacation leave');
    DECLARE @VacationID INT = SCOPE_IDENTITY();

    INSERT INTO VacationLeave (leave_id, carry_over_days, approving_manager)
    VALUES (
        @VacationID,
        5,                   -- assumed
        @ApprovingManager    -- derived from hierarchy
    );

    INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
    VALUES (@EmployeeID, @VacationID, 21);   -- assumed annual entitlement

    -- 2. SICK LEAVE
    INSERT INTO Leave (leave_type, leave_description)
    VALUES ('Sick', 'Sick leave for medical conditions');
    DECLARE @SickID INT = SCOPE_IDENTITY();

    INSERT INTO SickLeave (leave_id, medical_cert_required, physician_id)
    VALUES (
        @SickID,
        1,        -- assumed certificate required
        NULL      -- no physician assigned yet
    );

    INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
    VALUES (@EmployeeID, @SickID, 14);  -- assumed sick days


    -- 3. PROBATION LEAVE (Scheduling Logic)
    INSERT INTO Leave (leave_type, leave_description)
    VALUES ('Probation', 'Leave logic for probationary employment period');
    DECLARE @ProbationID INT = SCOPE_IDENTITY();

    INSERT INTO ProbationLeave (leave_id, eligibility_start_date, probation_period)
    VALUES (
        @ProbationID,
        GETDATE(),   -- assumed start
        90           -- assumed 90-day probation
    );

    INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
    VALUES (@EmployeeID, @ProbationID, 0);   -- no entitlement for probation


    -- 4. HOLIDAY LEAVE
    INSERT INTO Leave (leave_type, leave_description)
    VALUES ('Holiday', 'Official public holidays leave');
    DECLARE @HolidayID INT = SCOPE_IDENTITY();

    INSERT INTO HolidayLeave (leave_id, holiday_name, official_recognition, regional_scope)
    VALUES (
        @HolidayID,
        'National Holiday',   -- assumed placeholder
        1,                    -- assumed official
        'Country-wide'        -- assumed scope
    );

    INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
    VALUES (@EmployeeID, @HolidayID, 0);   -- holiday leave does not accumulate entitlement


    -- 5. Confirmation Message
    SELECT 'All leave types have been updated and scheduled successfully.' AS ConfirmationMessage;

END;
GO

--Procedure 29
CREATE PROCEDURE ConfigureLeaveEligibility
    @LeaveType VARCHAR(50),
    @MinTenure INT,
    @EmployeeType VARCHAR(50)
AS
BEGIN
    DECLARE @leave_id INT;
    DECLARE @msg NVARCHAR(255);

    -- Get the leave_id from the Leave table
    SELECT @leave_id = leave_id
    FROM [Leave]
    WHERE leave_type = @LeaveType;

    IF @leave_id IS NULL
    BEGIN
        SET @msg = 'Error: Leave type ' + @LeaveType + ' does not exist.';
        SELECT @msg AS ConfirmationMessage;
        RETURN;
    END

    -- Check if a policy already exists for this leave type
    IF EXISTS (SELECT 1 FROM LeavePolicy WHERE special_leave_type = @LeaveType)
    BEGIN
        -- Update existing policy
        UPDATE LeavePolicy
        SET eligibility_rules = 'Minimum Tenure: ' + CAST(@MinTenure AS VARCHAR(10)) 
                               + '; Employee Type: ' + @EmployeeType
        WHERE special_leave_type = @LeaveType;

        SET @msg = 'Eligibility rules updated successfully for ' + @LeaveType + '.';
    END
    ELSE
    BEGIN
        -- Insert a new policy
        INSERT INTO LeavePolicy (name, eligibility_rules, special_leave_type)
        VALUES (
            @LeaveType + ' Policy',
            'Minimum Tenure: ' + CAST(@MinTenure AS VARCHAR(10)) 
            + '; Employee Type: ' + @EmployeeType,
            @LeaveType
        );

        SET @msg = 'Eligibility rules set successfully for ' + @LeaveType + '.';
    END

    -- Return confirmation message
    SELECT @msg AS ConfirmationMessage;
END
GO

--Procedure 30
CREATE PROCEDURE ManageLeaveTypes
    @LeaveType VARCHAR(50),
    @Description VARCHAR(200)
AS
BEGIN
    DECLARE @leave_id INT;
    DECLARE @msg VARCHAR(255);

    -- Check if leave type exists
    SELECT @leave_id = leave_id
    FROM [Leave]
    WHERE leave_type = @LeaveType;

    IF @leave_id IS NOT NULL
    BEGIN
        -- Update existing leave type
        UPDATE [Leave]
        SET leave_description = @Description
        WHERE leave_id = @leave_id;

        SET @msg = 'Leave type "' + @LeaveType + '" updated successfully.';
    END
    ELSE
    BEGIN
        -- Insert new leave type
        INSERT INTO [Leave] (leave_type, leave_description)
        VALUES (@LeaveType, @Description);

        SET @msg = 'Leave type "' + @LeaveType + '" created successfully.';
    END

    -- Return confirmation
    SELECT @msg AS ConfirmationMessage;
END
GO

--Procedure 31
CREATE PROCEDURE AssignLeaveEntitlement
    @EmployeeID INT,
    @LeaveType VARCHAR(50),
    @Entitlement DECIMAL(5,2)
AS
BEGIN
    DECLARE @LeaveTypeID INT;
    DECLARE @msg VARCHAR(255);

    -- Validate employee
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        SELECT 'Error: Employee does not exist.' AS ConfirmationMessage;
        RETURN;
    END

    -- Validate leave type and retrieve its ID
    SELECT @LeaveTypeID = leave_id 
    FROM [Leave] 
    WHERE leave_type = @LeaveType;

    IF @LeaveTypeID IS NULL
    BEGIN
        SELECT 'Error: Leave type does not exist.' AS ConfirmationMessage;
        RETURN;
    END

    -- Check if entitlement already exists
    IF EXISTS (
        SELECT 1 FROM LeaveEntitlement 
        WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveTypeID
    )
    BEGIN
        -- Update entitlement
        UPDATE LeaveEntitlement
        SET entitlement = @Entitlement
        WHERE employee_id = @EmployeeID AND leave_type_id = @LeaveTypeID;

        SET @msg = 'Leave entitlement updated successfully.';
    END
    ELSE
    BEGIN
        -- Insert new entitlement
        INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
        VALUES (@EmployeeID, @LeaveTypeID, @Entitlement);

        SET @msg = 'Leave entitlement assigned successfully.';
    END

    SELECT @msg AS ConfirmationMessage;
END
GO

--Procedure 32 (Skipped, how does workflow type related to the other ones)
CREATE PROC ConfigureLeaveRules
    @LeaveType VARCHAR(50),
    @MaxDuration INT,
    @NoticePeriod INT,
    @WorkflowType VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @LeaveType IS NULL OR @MaxDuration IS NULL OR @NoticePeriod IS NULL
    BEGIN
        PRINT 'Leave type, max duration, and notice period are required.';
        RETURN;
    END
    
    IF NOT EXISTS (SELECT 1 FROM Leave WHERE leave_type = @LeaveType)
    BEGIN
        PRINT 'Leave type "' + @LeaveType + '" not found.';
        RETURN;
    END
    
    INSERT INTO LeavePolicy (
        name, 
        purpose, 
        eligibility_rules, 
        notice_period, 
        special_leave_type, 
        reset_on_new_year
    )
    VALUES (
        @LeaveType + ' Policy',
        'Approver Role: ' + ISNULL(@WorkflowType, 'Line Manager'),
        'Max Duration: ' + CAST(@MaxDuration AS VARCHAR) + ' days',
        @NoticePeriod,
        @LeaveType,
        1
    );
    
    PRINT 'Leave rules for "' + @LeaveType + '" configured successfully.';
    PRINT 'Approval required from: ' + ISNULL(@WorkflowType, 'Line Manager');
END
GO
--Procedure 33 (Assumption according to TA, rule represents eligibility rules)
CREATE PROCEDURE ConfigureSpecialLeave
    @LeaveType VARCHAR(50),
    @Rules VARCHAR(200)
AS
BEGIN
    DECLARE @msg VARCHAR(255);

    -- 1. Validate inputs
    IF (@LeaveType IS NULL OR @LeaveType = '')
    BEGIN
        RAISERROR('LeaveType is required.', 16, 1);
        RETURN;
    END;

    IF (@Rules IS NULL OR @Rules = '')
    BEGIN
        RAISERROR('Rules (eligibility) are required.', 16, 1);
        RETURN;
    END;

    -- 2. Check if the special leave already exists
    IF EXISTS (SELECT 1 FROM LeavePolicy WHERE special_leave_type = @LeaveType)
    BEGIN
        -- Update rules only
        UPDATE LeavePolicy
        SET eligibility_rules = @Rules
        WHERE special_leave_type = @LeaveType;

        SET @msg = CONCAT('Special leave "', @LeaveType, '" updated successfully.');
    END
    ELSE
    BEGIN
        -- 3. Insert new special leave policy
        INSERT INTO LeavePolicy (
            name,
            purpose,
            eligibility_rules,
            notice_period,
            special_leave_type,
            reset_on_new_year
        )
        VALUES (
            CONCAT(@LeaveType, ' Leave Policy'),
            CONCAT('Special leave type: ', @LeaveType),
            @Rules,
            0,          -- Special leaves usually require no notice period
            @LeaveType,
            0           -- Special leaves typically do not reset yearly
        );

        SET @msg = CONCAT('Special leave "', @LeaveType, '" configured successfully.');
    END;

    -- 4. Return confirmation
    SELECT @msg AS ConfirmationMessage;
END;
GO

--Procedure 34
CREATE PROCEDURE SetLeaveYearRules
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    -- 1. Reject ONLY leave requests submitted OUTSIDE the legal year
    UPDATE LeaveRequest
    SET status = 'Rejected'
    WHERE submission_date < @StartDate
       OR submission_date > @EndDate;

    -- 2. Return confirmation
    SELECT 'Leave year rules applied successfully.' AS ConfirmationMessage;

END;
GO
--Procedure 35 (Assumes Leave Balance = Entitlement)
CREATE PROCEDURE AdjustLeaveBalance
    @EmployeeID INT,
    @LeaveType VARCHAR(50),
    @Adjustment DECIMAL(5,2)
AS
BEGIN
    DECLARE @LeaveTypeID INT;

    -- Validate employee exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        PRINT 'Error: Employee does not exist.';
        RETURN;
    END

    -- Get leave_type_id
    SELECT @LeaveTypeID = leave_id
    FROM [Leave]
    WHERE leave_type = @LeaveType;

    IF @LeaveTypeID IS NULL
    BEGIN
        PRINT 'Error: Leave type does not exist.';
        RETURN;
    END

    -- Validate entitlement exists
    IF NOT EXISTS (
        SELECT 1
        FROM LeaveEntitlement
        WHERE employee_id = @EmployeeID
          AND leave_type_id = @LeaveTypeID
    )
    BEGIN
        PRINT 'Error: Employee does not have entitlement for this leave type.';
        RETURN;
    END

    -- Ensure balance doesn't go negative
    DECLARE @Current DECIMAL(5,2);

    SELECT @Current = entitlement
    FROM LeaveEntitlement
    WHERE employee_id = @EmployeeID
      AND leave_type_id = @LeaveTypeID;

    IF @Current + @Adjustment < 0
    BEGIN
        PRINT 'Error: Adjustment would result in a negative leave balance.';
        RETURN;
    END

    -- Apply adjustment
    UPDATE LeaveEntitlement
    SET entitlement = entitlement + @Adjustment
    WHERE employee_id = @EmployeeID
      AND leave_type_id = @LeaveTypeID;

    PRINT 'Leave balance adjusted successfully.';
END;
GO

--Procedure 36 (Assumes Permission = PermissionName and just updates it)
CREATE PROCEDURE ManageLeaveRoles
    @RoleID INT,
    @NewPermissionName VARCHAR(200)
AS
BEGIN
    DECLARE @msg VARCHAR(255);

    -- 1. Validate inputs
    IF (@RoleID IS NULL)
    BEGIN
        RAISERROR('RoleID is required.', 16, 1);
        RETURN;
    END;

    IF (@NewPermissionName IS NULL OR @NewPermissionName = '')
    BEGIN
        RAISERROR('New permission name is required.', 16, 1);
        RETURN;
    END;

    -- 2. Update the permission(s) for the role if available
    UPDATE RolePermission
    SET permission_name = @NewPermissionName
    WHERE role_id = @RoleID;

    -- 3. Return confirmation message
    SET @msg = CONCAT('Permissions for RoleID ', @RoleID, ' have been updated to "', @NewPermissionName, '".');
    SELECT @msg AS ConfirmationMessage;
END;
GO


--Procedure 37
CREATE PROCEDURE FinalizeLeaveRequest
    @LeaveRequestID INT
AS
BEGIN
    -- 1. Validate leave request exists
    IF NOT EXISTS (SELECT 1 FROM LeaveRequest WHERE request_id = @LeaveRequestID)
    BEGIN
        RAISERROR('Leave request does not exist', 16, 1);
        RETURN;
    END
    
    -- 2. Update to Finalized
    UPDATE LeaveRequest
    SET status = 'Finalized'
    WHERE request_id = @LeaveRequestID;
    
    PRINT 'Leave request finalized successfully';
END;
GO

--Procedure 38 (Review, should I raise an error if not approved or rejected)
CREATE PROCEDURE OverrideLeaveDecision
    @LeaveRequestID INT,
    @Reason VARCHAR(200)
AS
BEGIN
    -- 1. Validate Request
    IF NOT EXISTS (SELECT 1 FROM LeaveRequest WHERE request_id = @LeaveRequestID)
    BEGIN
        RAISERROR('Leave request does not exist', 16, 1);
        RETURN;
    END;
    
    -- 2. Validate Reason
    IF @Reason IS NULL OR @Reason = ''
    BEGIN
        RAISERROR('Reason is required', 16, 1);
        RETURN;
    END;

    -- 3. Get Current Status
    DECLARE @CurrentStatus VARCHAR(20);
    SELECT @CurrentStatus = status 
    FROM LeaveRequest 
    WHERE request_id = @LeaveRequestID;

    DECLARE @NewStatus VARCHAR(20);

    -- 4. Apply 3-Branch Logic
    IF (@CurrentStatus = 'Approved')
    BEGIN
        -- Case 1: Changing Approved ? Rejected
        SET @NewStatus = 'Rejected';
    END
    ELSE IF (@CurrentStatus = 'Rejected')
    BEGIN
        -- Case 2: Changing Rejected ? Approved
        SET @NewStatus = 'Approved';
    END
    ELSE
    BEGIN
        -- Case 3: Request not previously decided
        RAISERROR('No decision override possible: request is not Approved or Rejected', 16, 1);
        RETURN;
    END;

    -- 5. Update Leave Request (Set justification = @Reason)
    UPDATE LeaveRequest
    SET 
        status = @NewStatus,
        approval_timing = GETDATE(),
        justification = @Reason     -- ? NEW as requested
    WHERE request_id = @LeaveRequestID;

    PRINT CONCAT(
        'Leave decision overridden: ',
        @CurrentStatus, ' ? ', @NewStatus,
        '. Reason: ', @Reason
    );
END;
GO


--Procedure 39 (Review but overall good)
CREATE PROCEDURE BulkProcessLeaveRequests
    @LeaveRequestIDs VARCHAR(500)
AS
BEGIN
    -- 1. Validate Input
    IF @LeaveRequestIDs IS NULL OR @LeaveRequestIDs = ''
    BEGIN
        RAISERROR('Leave request IDs list cannot be empty', 16, 1);
        RETURN;
    END
    
    -- 2. Bulk Update
    -- Updates all matching pending requests to 'Approved'
    UPDATE LeaveRequest
    SET 
        status = 'Approved',
        approval_timing = GETDATE()
    WHERE request_id IN (
        SELECT CAST(value AS INT) 
        FROM STRING_SPLIT(@LeaveRequestIDs, ',')
        WHERE ISNUMERIC(value) = 1
    )
    AND status = 'Pending';
    
    PRINT 'Bulk processing completed successfully';
END;
GO
--Procedure 40
CREATE PROCEDURE VerifyMedicalLeave
    @LeaveRequestID INT,
    @DocumentID INT
AS
BEGIN
    DECLARE @LeaveID INT;
    DECLARE @IsSickLeave BIT;

    -- Check if leave request exists
    IF NOT EXISTS (SELECT 1 FROM LeaveRequest WHERE request_id = @LeaveRequestID)
    BEGIN
        SELECT 'Error: Leave request does not exist.' AS ConfirmationMessage;
        RETURN;
    END

    -- Get the leave_id linked with the request
    SELECT @LeaveID = leave_id 
    FROM LeaveRequest
    WHERE request_id = @LeaveRequestID;

    -- Check if the leave type is Sick Leave
    IF EXISTS (SELECT 1 FROM SickLeave WHERE leave_id = @LeaveID)
        SET @IsSickLeave = 1;
    ELSE
        SET @IsSickLeave = 0;

    IF @IsSickLeave = 0
    BEGIN
        SELECT 'Error: This leave request is not a Sick Leave and does not require medical verification.' AS ConfirmationMessage;
        RETURN;
    END

    -- Validate document exists and belongs to this leave request
    IF NOT EXISTS (
        SELECT 1 
        FROM LeaveDocument
        WHERE document_id = @DocumentID 
          AND leave_request_id = @LeaveRequestID
    )
    BEGIN
        SELECT 'Error: Document does not exist or does not belong to the specified leave request.' AS ConfirmationMessage;
        RETURN;
    END

    -- If all checks pass, verification is successful
    SELECT 'Medical leave document verified successfully.' AS ConfirmationMessage;
END
GO

--Procedure 41:
CREATE PROCEDURE SyncLeaveBalances
    @LeaveRequestID INT
AS
BEGIN
    DECLARE 
        @EmployeeID INT,
        @LeaveTypeID INT,
        @Duration DECIMAL(5,2),
        @Status VARCHAR(10),
        @CurrentEntitlement DECIMAL(5,2);

    -- 1. Get the leave request information
    SELECT 
        @EmployeeID = employee_id,
        @LeaveTypeID = leave_id,
        @Duration = duration,
        @Status = status
    FROM LeaveRequest
    WHERE request_id = @LeaveRequestID;

    -- If request does not exist
    IF @EmployeeID IS NULL
    BEGIN
        PRINT 'Leave request not found.';
        RETURN;
    END

    -- 2. Only process if approved
    IF @Status <> 'Approved'
    BEGIN
        PRINT 'Leave request is not fully approved. Balance not updated.';
        RETURN;
    END

    -- 3. Fetch current entitlement
    SELECT @CurrentEntitlement = entitlement
    FROM LeaveEntitlement
    WHERE employee_id = @EmployeeID
      AND leave_type_id = @LeaveTypeID;

    -- If entitlement record does not exist
    IF @CurrentEntitlement IS NULL
    BEGIN
        PRINT 'No entitlement record found for this employee and leave type.';
        RETURN;
    END

    -- 4. Validate sufficient entitlement
    IF @CurrentEntitlement < @Duration
    BEGIN
        PRINT 'Insufficient leave balance. Cannot deduct.';
        RETURN;
    END

    -- 5. Deduct leave
    UPDATE LeaveEntitlement
    SET entitlement = entitlement - @Duration
    WHERE employee_id = @EmployeeID
      AND leave_type_id = @LeaveTypeID;

    PRINT 'Leave balance updated successfully.';
END;
GO

--Procedure 42
CREATE PROC ProcessLeaveCarryForward
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @PreviousYear INT = @Year - 1;
    DECLARE @ProcessedCount INT = 0;
    
    -- Validation
    IF @Year IS NULL OR @Year < 1900
    BEGIN
        PRINT 'Invalid year provided.';
        RETURN;
    END
    
    -- Update each employee's leave entitlement with carry-forward amount
    UPDATE le
    SET le.entitlement = 
        CASE 
            -- Calculate remaining from previous year
            WHEN (le.entitlement - ISNULL(used.total_used, 0)) > ISNULL(vl.carry_over_days, 5)
            THEN ISNULL(vl.carry_over_days, 5)  -- Cap at max carry-over limit
            WHEN (le.entitlement - ISNULL(used.total_used, 0)) > 0
            THEN (le.entitlement - ISNULL(used.total_used, 0))  -- Actual remaining
            ELSE 0  -- No carry-over
        END
    FROM LeaveEntitlement le
    INNER JOIN VacationLeave vl ON le.leave_type_id = vl.leave_id
    LEFT JOIN (
        SELECT 
            employee_id,
            leave_id,
            SUM(duration) AS total_used
        FROM LeaveRequest
        WHERE status = 'Approved'
        AND YEAR(approval_timing) = @PreviousYear
        GROUP BY employee_id, leave_id
    ) used ON le.employee_id = used.employee_id AND vl.leave_id = used.leave_id;
    
    SET @ProcessedCount = @@ROWCOUNT;
    
    PRINT 'Carry-forward processing completed for year ' + CAST(@Year AS VARCHAR);
    PRINT 'Previous year (' + CAST(@PreviousYear AS VARCHAR) + ') vacation leaves calculated.';
    PRINT CAST(@ProcessedCount AS VARCHAR) + ' employee vacation entitlements updated with carry-forward.';
    
    -- Show results
    PRINT '';
    PRINT 'Carry-forward results:';
    SELECT 
        e.employee_id,
        e.first_name + ' ' + e.last_name AS employee_name,
        le.entitlement AS carry_forward_days,
        vl.carry_over_days AS max_allowed
    FROM LeaveEntitlement le
    INNER JOIN Employee e ON le.employee_id = e.employee_id
    INNER JOIN VacationLeave vl ON le.leave_type_id = vl.leave_id;
END
GO
    
--Procedure 43 (Check)
CREATE PROCEDURE SyncLeaveToAttendance
    @LeaveRequestID INT
AS
BEGIN
    DECLARE @EmployeeID INT;
    DECLARE @LeaveID INT;
    DECLARE @Duration INT;
    DECLARE @StartDate DATETIME;
    DECLARE @EndDate DATETIME;

    BEGIN TRY
        -- 1. Retrieve leave request details
        SELECT 
            @EmployeeID = employee_id,
            @LeaveID = leave_id,
            @Duration = duration,
            @StartDate = approval_timing
        FROM LeaveRequest
        WHERE request_id = @LeaveRequestID
          AND status = 'Approved';

        IF @EmployeeID IS NULL
        BEGIN
            RAISERROR('Leave request not found or not approved.', 16, 1);
            RETURN;
        END

        -- 2. Compute leave end date (assuming duration in days)
        SET @EndDate = DATEADD(DAY, @Duration - 1, @StartDate);

        -- 3. Insert attendance exceptions for each day of leave
        DECLARE @CurrentDate DATETIME = @StartDate;
        WHILE @CurrentDate <= @EndDate
        BEGIN
            INSERT INTO Attendance (employee_id, shift_id, entry_time, exit_time, duration, login_method, logout_method, exception_id)
            VALUES (@EmployeeID, NULL, @CurrentDate, @CurrentDate, 0, 'Leave', 'Leave', 1);  -- exception_id = 1 for leave

            -- Optional: log the attendance change
            INSERT INTO AttendanceLog (attendance_id, actor, timestamp, reason)
            VALUES (SCOPE_IDENTITY(), 'LeaveSystem', GETDATE(), 'Leave synced for LeaveRequestID ' + CAST(@LeaveRequestID AS VARCHAR(10)));

            SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
        END

        -- 4. Return confirmation
        SELECT 'Attendance successfully synced for LeaveRequestID ' + CAST(@LeaveRequestID AS VARCHAR(10)) AS ConfirmationMessage;

    END TRY
    BEGIN CATCH
        -- Handle errors and log exception
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Failed to sync attendance: %s', 16, 1, @ErrorMessage);
    END CATCH
END
GO

CREATE PROCEDURE UpdateInsuranceBrackets
    @BracketID INT,
    @MinSalary DECIMAL(10,2),
    @MaxSalary DECIMAL(10,2),
    @EmployeeContribution DECIMAL(5,2),
    @EmployerContribution DECIMAL(5,2)
AS
BEGIN
    UPDATE pg
    SET 
        min_salary = @MinSalary,
        max_salary = @MaxSalary
    FROM PayGrade pg
    INNER JOIN Employee e ON e.pay_grade = pg.pay_grade_id
    INNER JOIN Contract c ON e.contract_id = c.contract_id
    WHERE c.insurance_id = @BracketID;

    UPDATE Insurance
    SET contribution_rate = @EmployeeContribution,
        coverage = CONCAT('Employer Contribution: ', @EmployerContribution)
    WHERE insurance_id = @BracketID;

    DECLARE @Message NVARCHAR(500);
    SET @Message = CONCAT('Insurance bracket ID ', @BracketID, 
                          ' updated successfully. MinSalary: ', @MinSalary,
                          ', MaxSalary: ', @MaxSalary,
                          ', EmployeeContribution: ', @EmployeeContribution,
                          ', EmployerContribution: ', @EmployerContribution);

    PRINT @Message;
END;
GO

CREATE PROCEDURE ApprovePolicyUpdate
    @PolicyID INT,
    @ApprovedBy INT
AS
BEGIN
if exists( select 1 from PayrollPolicy where  policy_id = @PolicyID)
 begin
    UPDATE PayrollPolicy
    SET description = description + ' Approved', 
        effective_date = GETDATE()
    WHERE policy_id = @PolicyID;
    print('Payroll policy ID ' + CAST(@PolicyID AS VARCHAR(10)) + ' approved by Employee ID '+CAST(@ApprovedBy AS VARCHAR(10)));
 end;
else
print('Error');
END;
go


create procedure GeneratePayroll
@StartDate date,
@EndDate date
as
begin
select* from Payroll where period_start>=@StartDate AND period_end<=@EndDate;
end;
go

create procedure AdjustPayrollItem
@PayrollID int, 
@Type varchar(50), 
@Amount decimal(10,2),
@duration int,
@timezone varchar(20)
as 
begin
if not exists(select 1 from AllowanceDeduction where payroll_id=@PayrollID)
begin
print'Payroll ID not found';
return;
end;
update AllowanceDeduction
set type=@Type,
amount=@Amount,
duration=@duration,
timezone=@timezone 
where payroll_id=@PayrollID;
print('Payroll item adjusted');
end;
go


create procedure CalculateNetSalary
@PayrollID int,
@NetSalary decimal(10,2) output
as
begin
select @NetSalary=p.base_amount-p.contributions-p.taxes from Payroll p where p.payroll_id=@PayrollID;
select @NetSalary=@NetSalary+sum(amount) from AllowanceDeduction where payroll_id=@PayrollID And type='Allowance';
select @NetSalary=@NetSalary-sum(amount) from AllowanceDeduction where payroll_id=@PayrollID And type='Deduction';
end;
go


CREATE PROCEDURE ApplyPayrollPolicy
    @PolicyID INT,
    @PayrollID INT,
    @type VARCHAR(20),
    @description VARCHAR(50)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM PayrollPolicy WHERE policy_id = @PolicyID AND type = @type AND description = @description)
    BEGIN
        print'Error: Policy not found or does not match type/description.';
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM Payroll WHERE payroll_id = @PayrollID)
    BEGIN
        print'Error: Payroll record not found.';
        RETURN;
    END
    IF EXISTS (SELECT 1 FROM PayrollPolicy_ID WHERE payroll_id = @PayrollID AND policy_id = @PolicyID)
    BEGIN
        print'Policy already applied to this payroll.';
        RETURN;
    END
    INSERT INTO PayrollPolicy_ID (payroll_id, policy_id)
    VALUES (@PayrollID, @PolicyID);
    print'Payroll policy applied successfully.';
END;
go


create procedure GetMonthlyPayrollSummary
@Month int, 
@Year int
as
begin
select sum(net_salary) AS 'Total Salary' from Payroll where Month(period_start)=@Month AND Month(period_end)=@Month 
And Year(period_start)=@Year AND Year(period_end)=@Year;
end;
go


create procedure GetEmployeePayrollHistory
@EmployeeID int
as
begin
if not exists(select 1 from Payroll where employee_id=@EmployeeID)
begin
print('Employee not found');
return;
end;
select* from Payroll where employee_id=@EmployeeID;
end;
go


create procedure GetBonusEligibleEmployees
@Eligibility_criteria varchar(max)
as
begin
select e.full_name,e.employee_id from Employee e 
inner join Payroll p on p.employee_id=e.employee_id
inner join PayrollPolicy_ID pp on pp.payroll_id=p.payroll_id
inner join BonusPolicy bp on bp.policy_id=pp.policy_id
where bp.eligibility_criteria=@Eligibility_criteria
end;
go



create proc UpdateSalaryType
@EmployeeID int,
@SalaryTypeID int
as
begin
if not exists(select 1 from Employee where employee_id=@EmployeeID)
begin
print ('Emloyee not found');
return;
end;
if not exists(select 1 from SalaryType where salary_type_id= @SalaryTypeID)
begin
print ('Salary Type not found');
return;
end;
update Employee 
set salary_type_id=@SalaryTypeID
where employee_id=@EmployeeID;
print ('Salary Type Updated');
end;
go


create proc GetPayrollByDepartment
@DepartmentID int,
@Month int,
@Year int
as
begin
SELECT d.department_name,SUM(p.net_salary) AS [Payroll Summary]FROM Employee e
INNER JOIN Department d ON e.department_id = d.department_id
INNER JOIN Payroll p ON p.employee_id = e.employee_id
WHERE e.department_id = @DepartmentID AND MONTH(p.period_start) = @Month AND MONTH(p.period_end) = @Month
AND YEAR(p.period_start) = @Year AND YEAR(p.period_end) = @Year
GROUP BY d.department_name;
END;
go


CREATE PROCEDURE ValidateAttendanceBeforePayroll
    @PayrollPeriodID INT
AS
BEGIN
    DECLARE @StartDate DATE, @EndDate DATE;

    SELECT @StartDate = start_date, @EndDate = end_date
    FROM PayrollPeriod
    WHERE payroll_period_id = @PayrollPeriodID;

    IF @StartDate IS NULL
    BEGIN
        PRINT 'Payroll period not found';
        RETURN;
    END

    SELECT DISTINCT e.employee_id,e.first_name,e.last_name,a.attendance_id,a.entry_time,a.exit_time,a.shift_id
    FROM PayrollPeriod pp
    INNER JOIN Payroll p ON pp.payroll_id = p.payroll_id
    INNER JOIN Employee e ON p.employee_id = e.employee_id
    INNER JOIN Attendance a ON a.employee_id = e.employee_id
    WHERE pp.payroll_period_id = @PayrollPeriodID
      AND (a.entry_time IS NULL OR a.exit_time IS NULL
           OR a.entry_time < CAST(@StartDate AS DATETIME)
           OR a.entry_time >= DATEADD(DAY, 1, CAST(@EndDate AS DATETIME)))
    ;
END;
go


CREATE PROCEDURE SyncAttendanceToPayroll
    @SyncDate DATE
AS
BEGIN
    ;WITH DailyAttendance AS (
        SELECT a.*
        FROM Attendance a
        WHERE a.entry_time >= CAST(@SyncDate AS DATETIME)
          AND a.entry_time < DATEADD(DAY, 1, CAST(@SyncDate AS DATETIME))
          AND a.employee_id IS NOT NULL
    )
    UPDATE P
    SET P.base_amount = ISNULL(P.base_amount,0) + (ISNULL(D.duration,0) * H.hourly_rate)
    FROM Payroll P
    INNER JOIN DailyAttendance D ON P.employee_id = D.employee_id
    INNER JOIN Employee E ON D.employee_id = E.employee_id
    INNER JOIN SalaryType ST ON E.salary_type_id = ST.salary_type_id
    INNER JOIN HourlySalaryType H ON ST.salary_type_id = H.salary_type_id
    WHERE ST.type = 'Hourly'
      AND P.period_start <= CAST(@SyncDate AS DATE) AND P.period_end >= CAST(@SyncDate AS DATE);
    UPDATE P
    SET P.adjustments = ISNULL(P.adjustments,0) + 
        CASE 
            WHEN D.duration > 8 THEN ((D.duration - 8) * ISNULL(H.hourly_rate,0) * 1.5)
            ELSE 0 
        END
    FROM Payroll P
    INNER JOIN DailyAttendance D ON P.employee_id = D.employee_id
    INNER JOIN Employee E ON D.employee_id = E.employee_id
    INNER JOIN SalaryType ST ON E.salary_type_id = ST.salary_type_id
    LEFT JOIN HourlySalaryType H ON ST.salary_type_id = H.salary_type_id
    WHERE ST.type = 'Monthly'
      AND P.period_start <= CAST(@SyncDate AS DATE) AND P.period_end >= CAST(@SyncDate AS DATE); 
    UPDATE AD
    SET AD.amount = AD.amount + ISNULL(AD.amount,0)
    FROM AllowanceDeduction AD
    INNER JOIN DailyAttendance D ON AD.employee_id = D.employee_id
    INNER JOIN ShiftSchedule S ON D.shift_id = S.shift_id
    WHERE AD.type = 'ShiftDifferential'
      AND S.shift_date = @SyncDate;

    PRINT 'Attendance records for ' + CONVERT(VARCHAR(10), @SyncDate, 120) + ' processed. Hourly pay and overtime adjustments updated where applicable.';
END;
GO



CREATE PROCEDURE SyncApprovedPermissionsToPayroll
    @PayrollPeriodID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PeriodStart DATE, @PeriodEnd DATE;

    SELECT @PeriodStart = start_date, @PeriodEnd = end_date
    FROM PayrollPeriod
    WHERE payroll_period_id = @PayrollPeriodID;

    IF @PeriodStart IS NULL
    BEGIN
        PRINT 'Error: Payroll period not found.';
        RETURN;
    END

    ;WITH ApprovedPermissions AS (
        SELECT DISTINCT er.employee_id, rp.permission_name
        FROM Employee_Role er
        INNER JOIN RolePermission rp ON er.role_id = rp.role_id
        WHERE rp.allowed_action = 'Approved'
    )
    UPDATE P
    SET P.base_amount = ISNULL(P.base_amount,0) + ISNULL(B.Amount,0)
    FROM Payroll P
    INNER JOIN ApprovedPermissions AP ON P.employee_id = AP.employee_id
    OUTER APPLY (
        SELECT SUM(AD.amount) AS Amount
        FROM AllowanceDeduction AD
        WHERE AD.employee_id = P.employee_id
          AND AD.type LIKE '%Bonus%'
          AND AD.payroll_id = P.payroll_id
    ) B
    WHERE P.period_start <= @PeriodEnd
      AND P.period_end >= @PeriodStart
      AND AP.permission_name IN ('BonusEligible','OvertimeApproved');
    PRINT 'Payroll synced with approved permissions for PayrollPeriodID ' + CAST(@PayrollPeriodID AS VARCHAR(10)) + '.';
END;
go


CREATE PROCEDURE ConfigurePayGrades
    @GradeName VARCHAR(50),
    @MinSalary DECIMAL(10,2),
    @MaxSalary DECIMAL(10,2)
AS
BEGIN
DECLARE @ExistingPayGradeId INT;
SELECT @ExistingPayGradeId = pay_grade_id
        FROM PayGrade
        WHERE grade_name = @GradeName;
        IF @ExistingPayGradeId IS NOT NULL
        BEGIN
            UPDATE PayGrade
            SET 
                min_salary = @MinSalary,
                max_salary = @MaxSalary
            WHERE pay_grade_id = @ExistingPayGradeId;
        PRINT 'paygrade configured';
        END
        ELSE
        BEGIN
            INSERT INTO PayGrade (grade_name, min_salary, max_salary)
            VALUES (@GradeName, @MinSalary, @MaxSalary);
            print'paygrade created'
        END
end;
go


CREATE PROCEDURE ConfigureShiftAllowances
    @ShiftType VARCHAR(50),
    @AllowanceName VARCHAR(50),
    @Amount DECIMAL(10,2)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE type = @ShiftType)
    BEGIN
        PRINT 'Shift type does not exist';
        RETURN;
    END;
    IF EXISTS (
        SELECT 1
        FROM AllowanceDeduction
        WHERE type = @AllowanceName
          AND employee_id IS NULL
    )
    BEGIN
        UPDATE AllowanceDeduction
        SET amount = @Amount
        WHERE type = @AllowanceName
          AND employee_id IS NULL;

        PRINT 'Shift allowance updated successfully.';
    END
    ELSE
    BEGIN
        INSERT INTO AllowanceDeduction (payroll_id, employee_id, type, amount)
        VALUES (NULL, NULL, @AllowanceName, @Amount);

        PRINT 'Shift allowance created successfully.';
    END
END;
go

CREATE PROCEDURE EnableMultiCurrencyPayroll
    @CurrencyCode varchar(10),
    @ExchangeRate decimal(10,4)
AS
BEGIN
IF NOT EXISTS (SELECT 1 FROM Currency WHERE CurrencyCode = @CurrencyCode)
    BEGIN
        print('Currency code not found');
        RETURN;
    END
    UPDATE Currency
    SET ExchangeRate = @ExchangeRate,LastUpdated = GETDATE()
    WHERE CurrencyCode = @CurrencyCode;

    print ('Exchange rate updated successfully');
END
go
CREATE PROCEDURE ManageTaxRules
    @TaxRuleName VARCHAR(50),
    @CountryCode VARCHAR(10),
    @Rate DECIMAL(5,2),
    @Exemption DECIMAL(10,2)
AS
BEGIN
IF EXISTS (
        SELECT 1
        FROM PayrollPolicy
        WHERE type = 'TaxRule'
          AND description LIKE @TaxRuleName + ' (' + @CountryCode + ')%'
    )
    BEGIN
        UPDATE PayrollPolicy
        SET description = @TaxRuleName + ' (' + @CountryCode 
                          + ') - Rate: ' + CAST(@Rate AS VARCHAR(10)) 
                          + ', Exemption: ' + CAST(@Exemption AS VARCHAR(20)),
            effective_date = GETDATE()
        WHERE type = 'TaxRule'
          AND description LIKE @TaxRuleName + ' (' + @CountryCode + ')%';

        SELECT 'Tax rule updated successfully.' AS Message;
        RETURN;
    END;
    INSERT INTO PayrollPolicy (effective_date, type, description)
    VALUES (
        GETDATE(),
        'TaxRule',
        @TaxRuleName + ' (' + @CountryCode 
        + ') - Rate: ' + CAST(@Rate AS VARCHAR(10)) 
        + ', Exemption: ' + CAST(@Exemption AS VARCHAR(20))
    );SELECT 'Tax rule created successfully.' AS Message;
END;
go

CREATE PROCEDURE ApprovePayrollConfigChanges
    @ConfigID INT,
    @ApproverID INT,
    @Status VARCHAR(20)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM PayrollPolicy WHERE policy_id = @ConfigID)
    BEGIN
        SELECT 'Error: Configuration policy not found.' AS Message;
        RETURN;
    END;
    UPDATE PayrollPolicy
    SET description = description 
                      + ' | Status: ' + @Status
                      + ' | Approved By: ' + CAST(@ApproverID AS VARCHAR(10))
                      + ' | Approved At: ' + CONVERT(VARCHAR(19), GETDATE(), 120),
        effective_date = GETDATE()
    WHERE policy_id = @ConfigID;
    SELECT 'Configuration ID ' + CAST(@ConfigID AS VARCHAR(10))
           + ' updated with status: ' + @Status AS Message;
END;
go

CREATE PROCEDURE ConfigureSigningBonus
    @EmployeeID INT,
    @BonusAmount DECIMAL(10,2),
    @EffectiveDate DATE
AS
BEGIN
    DECLARE @PayrollID INT;
    SELECT TOP 1 @PayrollID = payroll_id
    FROM Payroll
    WHERE employee_id = @EmployeeID AND @EffectiveDate BETWEEN period_start AND period_end ORDER BY period_start DESC;
    IF @PayrollID IS NULL
    BEGIN
        print('Error No payroll record found for this employee');
        RETURN;
    END
    INSERT INTO AllowanceDeduction
        (payroll_id, employee_id, type, amount)
    VALUES
        (@PayrollID, @EmployeeID, 'Bonus', @BonusAmount);
    print('Signing bonus configured successfully');
END;
go



CREATE PROCEDURE ConfigureTerminationBenefits
    @EmployeeID INT,
    @CompensationAmount DECIMAL(10,2),
    @EffectiveDate DATE,
    @Reason VARCHAR(50)
AS
BEGIN
DECLARE @ContractID INT;
SELECT @ContractID = contract_id FROM Employee WHERE employee_id = @EmployeeID;
IF @ContractID IS NULL
    BEGIN
        print('Employee has no contract');
        RETURN;
    END;
    INSERT INTO Termination (date, reason, contract_id)
    VALUES (@EffectiveDate, @Reason, @ContractID);
    DECLARE @PayrollID INT;

SELECT top 1  @PayrollID = payroll_id FROM Payroll WHERE employee_id = @EmployeeID AND @EffectiveDate BETWEEN period_start AND period_end ORDER BY period_start DESC;
    IF @PayrollID IS NULL
    BEGIN
       print('Employee has no payroll')
       RETURN; 
    END;
    INSERT INTO AllowanceDeduction
        (payroll_id, employee_id, type, amount)
    VALUES
        (@PayrollID, @EmployeeID, 'TerminationCompensation', @CompensationAmount);
    print('Termination compensation configured successfully');
END;
GO

CREATE PROCEDURE ConfigureInsuranceBrackets
    @InsuranceType VARCHAR(50),
    @MinSalary DECIMAL(10,2),
    @MaxSalary DECIMAL(10,2),
    @EmployeeContribution DECIMAL(5,2),
    @EmployerContribution DECIMAL(5,2)
AS
BEGIN
    INSERT INTO Insurance(type, contribution_rate)
    VALUES (@InsuranceType, @EmployeeContribution);

    INSERT INTO PayGrade(grade_name, min_salary, max_salary)
    VALUES (@InsuranceType + ' Bracket', @MinSalary, @MaxSalary);


    PRINT ('Insurance bracket configured succesfully');
END;
GO
    
create procedure ConfigurePayrollPolicies
@PolicyType varchar(50), @PolicyDetails nvarchar(max), @effectivedate date
as
begin
insert into PayrollPolicy(effective_date, type, description) values(@effectivedate,@PolicyType,@PolicyDetails);
print('payroll policy configured');
end;
go

create procedure DefinePayGrades
@GradeName varchar(50), @MinSalary decimal(10,2), @MaxSalary decimal(10,2), @CreatedBy int
as
begin
IF @MinSalary > @MaxSalary
BEGIN
PRINT 'Error: MinSalary cannot be greater than MaxSalary';
RETURN;
END
insert into PayGrade(grade_name, min_salary, max_salary) values (@GradeName,@MinSalary,@MaxSalary);
print('PayGrade defined by ' + @CreatedBy);
end;
go

CREATE PROCEDURE ConfigureEscalationWorkflow
@ThresholdAmount decimal(10,2),
@ApproverRole varchar(50),
@CreatedBy int
AS
BEGIN
IF @ThresholdAmount < 0
BEGIN
PRINT 'Error: ThresholdAmount cannot be negative';
RETURN;
END
INSERT INTO ApprovalWorkflow (workflow_type,threshold_amount,approver_role,created_by)
VALUES ('Escalation',@ThresholdAmount,@ApproverRole,@CreatedBy);
PRINT('Escalation Workflow configured successfully');
END;
go

CREATE PROCEDURE DefinePayType
@EmployeeID int,
@PayType varchar(50),
@EffectiveDate date
AS
BEGIN
IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id=@EmployeeID)
BEGIN
PRINT('Employee not found');
RETURN;
END

DECLARE @SalaryTypeID int;
SELECT @SalaryTypeID = salary_type_id
FROM SalaryType
WHERE type = @PayType;

IF @SalaryTypeID IS NULL
BEGIN
    PRINT('Error: Pay type not found in SalaryType table.');
    RETURN;
END

UPDATE Employee
SET salary_type_id = @SalaryTypeID
WHERE employee_id=@EmployeeID;

PRINT('Pay type assigned to Employee');

END;
go

CREATE PROCEDURE ConfigureOvertimeRules
@DayType varchar(20),
@Multiplier decimal(3,2),
@HoursPerMonth int
AS
BEGIN
IF @DayType NOT IN ('Weekday','Weekend')
BEGIN
PRINT('DayType must be Weekday or Weekend');
RETURN;
END
IF @Multiplier <= 0
BEGIN
PRINT('Multiplier must be greater than 0');
RETURN;
END
IF @HoursPerMonth <= 0
BEGIN
PRINT('HoursPerMonth must be greater than 0');
RETURN;
END

IF @DayType='Weekday'
BEGIN
    UPDATE OvertimePolicy
    SET weekday_rate_multiplier=@Multiplier,
        max_hours_per_month=@HoursPerMonth;
END
ELSE
BEGIN
    UPDATE OvertimePolicy
    SET weekend_rate_multiplier=@Multiplier,
        max_hours_per_month=@HoursPerMonth;
END

PRINT('Overtime rule updated successfully');

END;
go


CREATE PROCEDURE ConfigureShiftAllowance
@ShiftType VARCHAR(20),
@AllowanceAmount DECIMAL(10,2),
@CreatedBy INT
AS
BEGIN
WITH AssignedEmployees AS (
    SELECT DISTINCT e.employee_id
    FROM Employee e
    INNER JOIN ShiftAssignment sa ON e.employee_id = sa.employee_id
    INNER JOIN ShiftSchedule s ON sa.shift_id = s.shift_id
    WHERE s.type = @ShiftType
)
UPDATE AD
SET amount = amount + @AllowanceAmount
FROM AllowanceDeduction AD
INNER JOIN AssignedEmployees AE ON AD.employee_id = AE.employee_id
WHERE AD.type = @ShiftType;
IF @@ROWCOUNT = 0
    PRINT 'Cannot configure shift allowance: no existing allowances found for this shift type.';
ELSE
    PRINT 'Configured shift allowance successfully for existing allowances.';
END;
GO



-- Amr procedures START
--===============================================1

GO
CREATE PROC ReviewLeaveRequest
    @LeaveRequestID INT,
    @ManagerID      INT,
    @Decision       VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM LeaveRequest LR
                       INNER JOIN Employee E ON LR.employee_id = E.employee_id
                       WHERE LR.request_id = @LeaveRequestID
                         AND E.manager_id = @ManagerID)
        BEGIN
            PRINT 'Leave request not found or you are not authorized.';
            RETURN;
        END

        UPDATE LeaveRequest
        SET status = @Decision,
            approval_timing = GETDATE()
        WHERE request_id = @LeaveRequestID;

        PRINT 'Leave request #' + CAST(@LeaveRequestID AS VARCHAR) + ' ' + @Decision + ' by manager #' + CAST(@ManagerID AS VARCHAR) + '.';
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END




GO
CREATE PROC AssignShift
    @ManagerID   INT,
    @EmployeeID  INT,
    @ShiftID     INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN 
        PRINT 'Manager not authorized.'; 
        RETURN; 
    END

    IF NOT EXISTS (SELECT 1 FROM Employee E 
                   WHERE E.employee_id = @EmployeeID AND E.manager_id = @ManagerID)
    BEGIN 
        PRINT 'Unauthorized or employee not found.'; 
        RETURN; 
    END

    IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE shift_id = @ShiftID)
    BEGIN 
        PRINT 'Shift not found.'; 
        RETURN; 
    END

    DECLARE @NextAssignmentID INT = (SELECT ISNULL(MAX(assignment_id), 0) + 1 FROM ShiftAssignment);

    INSERT INTO ShiftAssignment (assignment_id, employee_id, shift_id, start_date, status)
    VALUES (@NextAssignmentID, @EmployeeID, @ShiftID, GETDATE(), 'Active');

    PRINT 'Shift assigned successfully to employee #' + CAST(@EmployeeID AS VARCHAR) + '.';
END




GO
CREATE PROC ViewTeamAttendance
    @ManagerID        INT,
    @DateRangeStart   DATE,
    @DateRangeEnd     DATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN PRINT 'Manager not authorized.'; RETURN; END

    SELECT
        E.employee_id,
        E.full_name,
        A.attendance_id,
        SS.shift_date,
        A.entry_time,
        A.exit_time,
        A.duration,
        A.login_method,
        A.logout_method,
        EX.name AS exception_name
    FROM Employee E
    INNER JOIN Attendance A      ON E.employee_id = A.employee_id
    INNER JOIN ShiftSchedule SS  ON A.shift_id = SS.shift_id
    LEFT  JOIN Exception EX      ON A.exception_id = EX.exception_id
    WHERE E.manager_id = @ManagerID
      AND SS.shift_date BETWEEN @DateRangeStart AND @DateRangeEnd
    ORDER BY SS.shift_date, E.full_name;
END






GO
CREATE PROC SendTeamNotification
    @ManagerID INT,
    @MessageContent VARCHAR(255),
    @UrgencyLevel VARCHAR(50)
AS
BEGIN
    IF @ManagerID IS NULL OR @MessageContent IS NULL OR @UrgencyLevel IS NULL
    BEGIN
    PRINT 'Please provide all required inputs.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN
        PRINT 'Manager not found.'
        RETURN
    END

    DECLARE @NotificationID INT

    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
    VALUES (@MessageContent, GETDATE(), @UrgencyLevel, 'Unread', 'Team Message')

    SET @NotificationID = SCOPE_IDENTITY()

    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT 
        employee_id,
        @NotificationID,
        'Sent',
        GETDATE()
    FROM Employee
    WHERE manager_id = @ManagerID

    PRINT 'Notification sent to all team members of manager #' + CAST(@ManagerID AS VARCHAR) + '.'
END








GO
CREATE PROC ApproveMissionCompletion
    @MissionID INT,
    @ManagerID INT,
    @Remarks VARCHAR(200)
AS
BEGIN
    IF @MissionID IS NULL OR @ManagerID IS NULL OR @Remarks IS NULL
    BEGIN
    PRINT 'Please provide all required inputs.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Mission WHERE mission_id = @MissionID)
    BEGIN
        PRINT 'Mission not found.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Mission WHERE mission_id = @MissionID AND manager_id = @ManagerID)
    BEGIN
        PRINT 'Manager not authorized for this mission.'
        RETURN
    END

    UPDATE Mission
    SET status = 'Completed - ' + @Remarks,
        end_date = CASE WHEN end_date IS NULL THEN GETDATE() ELSE end_date END
    WHERE mission_id = @MissionID

    PRINT 'Mission #' + CAST(@MissionID AS VARCHAR) + ' has been marked as completed by manager #' + CAST(@ManagerID AS VARCHAR) + '.'
END






GO
CREATE PROC RequestReplacement
    @EmployeeID INT,
    @Reason VARCHAR(150)
AS
BEGIN
    IF @EmployeeID IS NULL OR @Reason IS NULL
    BEGIN
    PRINT 'Employee ID and reason cannot be null.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        PRINT 'Employee not found.'
        RETURN
    END

    DECLARE @NotificationID INT
    DECLARE @MessageContent VARCHAR(1000)

    SET @MessageContent = 'Replacement requested for employee #' + CAST(@EmployeeID AS VARCHAR) + '. Reason: ' + @Reason

    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
    VALUES (@MessageContent, GETDATE(), 'High', 'Unread', 'Replacement Request')

    SET @NotificationID = SCOPE_IDENTITY()

    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT 
        employee_id,
        @NotificationID,
        'Sent',
        GETDATE()
    FROM HRAdministrator

    PRINT 'Replacement request submitted for employee #' + CAST(@EmployeeID AS VARCHAR) + '.'
END






GO
CREATE PROC ViewDepartmentSummary
    @DepartmentID INT
AS
BEGIN
    IF @DepartmentID IS NULL
    BEGIN
    PRINT 'Department ID cannot be null.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Department WHERE department_id = @DepartmentID)
    BEGIN
        PRINT 'Department not found.'
        RETURN
    END

    SELECT 
        D.department_id,
        D.department_name,
        D.purpose,
        DH.full_name AS department_head,
        COUNT(DISTINCT E.employee_id) AS employee_count,
        COUNT(DISTINCT M.mission_id) AS active_missions
    FROM Department D
    LEFT JOIN Employee DH ON D.department_head_id = DH.employee_id
    LEFT JOIN Employee E ON E.department_id = D.department_id AND E.is_active = 1
    LEFT JOIN Mission M ON M.employee_id = E.employee_id AND M.status LIKE '%Active%'
    WHERE D.department_id = @DepartmentID
    GROUP BY 
        D.department_id,
        D.department_name,
        D.purpose,
        DH.full_name
END








GO
CREATE PROC ReassignShift
    @EmployeeID INT,
    @OldShiftID INT,
    @NewShiftID INT
AS
BEGIN
    IF @EmployeeID IS NULL OR @OldShiftID IS NULL OR @NewShiftID IS NULL
    BEGIN
    PRINT 'Please provide all required inputs.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        PRINT 'Employee not found.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE shift_id = @OldShiftID)
    BEGIN
        PRINT 'Old shift not found.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM ShiftSchedule WHERE shift_id = @NewShiftID)
    BEGIN
        PRINT 'New shift not found.'
        RETURN
    END

    UPDATE ShiftAssignment
    SET shift_id = @NewShiftID,
        status = 'Reassigned'
    WHERE employee_id = @EmployeeID AND shift_id = @OldShiftID

    PRINT 'Employee #' + CAST(@EmployeeID AS VARCHAR) + ' has been reassigned from shift #' + CAST(@OldShiftID AS VARCHAR) + ' to shift #' + CAST(@NewShiftID AS VARCHAR) + '.'
END









GO
CREATE PROC GetPendingLeaveRequests
    @ManagerID INT
AS
BEGIN
    IF @ManagerID IS NULL
    BEGIN
    PRINT 'Manager ID cannot be null.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN
        PRINT 'Manager not found.'
        RETURN
    END

    SELECT 
        LR.request_id,
        E.employee_id,
        E.full_name,
        L.leave_type,
        LR.justification,
        LR.duration,
        LR.status
    FROM LeaveRequest LR
    INNER JOIN Employee E ON LR.employee_id = E.employee_id
    INNER JOIN [Leave] L ON LR.leave_id = L.leave_id
    WHERE E.manager_id = @ManagerID
        AND LR.status = 'Pending'
    ORDER BY LR.request_id
END











GO
CREATE PROC GetTeamStatistics
    @ManagerID INT   
AS
BEGIN
    IF @ManagerID IS NULL
    BEGIN
    PRINT 'Manager ID cannot be null.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN
        PRINT 'Manager not found.'
        RETURN
    END

    SELECT 
        @ManagerID AS manager_id,
        LM.team_size,
        COUNT(E.employee_id) AS actual_team_count,
        AVG(P.net_salary) AS average_salary,
        LM.supervised_departments,
        LM.approval_limit
    FROM LineManager LM
    LEFT JOIN Employee E ON E.manager_id = @ManagerID AND E.is_active = 1
    LEFT JOIN Payroll P ON P.employee_id = E.employee_id
    WHERE LM.employee_id = @ManagerID
    GROUP BY 
        LM.team_size,
        LM.supervised_departments,
        LM.approval_limit
END








GO
CREATE PROC ViewTeamProfiles
    @ManagerID INT
AS
BEGIN
    IF @ManagerID IS NULL
    BEGIN
        PRINT 'Manager ID cannot be null.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ManagerID)
    BEGIN
        PRINT 'Manager not found.'
        RETURN
    END

    SELECT 
        E.employee_id,
        E.full_name,
        D.department_name,
        P.position_title,
        E.hire_date,
        E.employment_status,
        CASE WHEN E.is_active = 1 THEN 'Active' ELSE 'Inactive' END AS status
    FROM Employee E
    INNER JOIN Department D ON E.department_id = D.department_id
    INNER JOIN Position P ON E.position_id = P.position_id
    WHERE E.manager_id = @ManagerID
      AND E.is_active = 1
    ORDER BY E.full_name
END







GO
CREATE PROC GetTeamSummary
    @ManagerID INT
AS
BEGIN
    IF @ManagerID IS NULL
    BEGIN
    PRINT 'Manager ID cannot be null.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN
        PRINT 'Manager not found.'
        RETURN
    END

    SELECT 
        R.role_name,
        D.department_name,
        COUNT(E.employee_id) AS employee_count,
        AVG(DATEDIFF(YEAR, E.hire_date, GETDATE())) AS average_tenure_years
    FROM Employee E
    INNER JOIN Employee_Role ER ON E.employee_id = ER.employee_id
    INNER JOIN Role R ON ER.role_id = R.role_id
    INNER JOIN Department D ON E.department_id = D.department_id
    WHERE E.manager_id = @ManagerID AND E.is_active = 1
    GROUP BY R.role_name, D.department_name
    ORDER BY D.department_name, R.role_name
END

GO
CREATE PROC FilterTeamProfiles
    @ManagerID INT,
    @Skill VARCHAR(50),
    @RoleID INT
AS
BEGIN
    IF @ManagerID IS NULL
    BEGIN
    PRINT 'Manager ID cannot be null.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN
        PRINT 'Manager not found.'
        RETURN
    END

    SELECT DISTINCT
        E.employee_id,
        E.full_name,
        D.department_name,
        P.position_title,
        R.role_name,
        S.skill_name,
        ES.proficiency_level
    FROM Employee E
    INNER JOIN Department D ON E.department_id = D.department_id
    INNER JOIN Position P ON E.position_id = P.position_id
    LEFT JOIN Employee_Role ER ON E.employee_id = ER.employee_id
    LEFT JOIN Role R ON ER.role_id = R.role_id
    LEFT JOIN Employee_Skill ES ON E.employee_id = ES.employee_id
    LEFT JOIN Skill S ON ES.skill_id = S.skill_id
    WHERE E.manager_id = @ManagerID
        AND E.is_active = 1
        AND (@Skill IS NULL OR S.skill_name = @Skill)
        AND (@RoleID IS NULL OR R.role_id = @RoleID)
    ORDER BY E.full_name
END







GO
CREATE PROC ViewTeamCertifications
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN PRINT 'Manager not authorized.'; RETURN; END

    SELECT
        E.employee_id,
        E.full_name,
        'Skill' AS type,
        S.skill_name AS name,
        ES.proficiency_level AS details,
        NULL AS issuer,
        NULL AS issue_date,
        NULL AS expiry_period
    FROM Employee E
    LEFT JOIN Employee_Skill ES ON E.employee_id = ES.employee_id
    LEFT JOIN Skill S ON ES.skill_id = S.skill_id
    WHERE E.manager_id = @ManagerID AND E.is_active = 1

    UNION ALL

    SELECT
        E.employee_id,
        E.full_name,
        'Certification' AS type,
        V.verification_type AS name,
        NULL AS details,
        V.issuer,
        V.issue_date,
        V.expiry_period
    FROM Employee E
    LEFT JOIN Employee_Verification EV ON E.employee_id = EV.employee_id
    LEFT JOIN Verification V ON EV.verification_id = V.verification_id
    WHERE E.manager_id = @ManagerID AND E.is_active = 1
    ORDER BY employee_id, type, name;
END

GO
CREATE PROC AddManagerNotes
    @EmployeeID INT,
    @ManagerID  INT,
    @Note       VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID 
                   AND manager_id = @ManagerID)
    BEGIN PRINT 'Unauthorized or employee not in your team.'; RETURN; END

    INSERT INTO ManagerNotes (employee_id, manager_id, note_content, created_at)
    VALUES (@EmployeeID, @ManagerID, @Note, GETDATE());

    PRINT 'Note added.';
END










GO
CREATE PROC RecordManualAttendance
    @EmployeeID  INT,
    @Date        DATE,
    @ClockIn     TIME,
    @ClockOut    TIME,
    @Reason      VARCHAR(200),
    @RecordedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @Entry DATETIME = CAST(@Date AS DATETIME) + CAST(@ClockIn AS DATETIME);
        DECLARE @Exit  DATETIME = CAST(@Date AS DATETIME) + CAST(@ClockOut AS DATETIME);
        DECLARE @Duration DECIMAL(8,2) = DATEDIFF(MINUTE, @Entry, @Exit) / 60.0;

        DECLARE @ShiftID INT;
        SELECT TOP 1 @ShiftID = SA.shift_id
        FROM ShiftAssignment SA
        WHERE SA.employee_id = @EmployeeID
          AND @Date BETWEEN SA.start_date AND ISNULL(SA.end_date, @Date)
          AND SA.status = 'Active';

        INSERT INTO Attendance (employee_id, shift_id, entry_time, exit_time, duration, login_method, logout_method)
        VALUES (@EmployeeID, @ShiftID, @Entry, @Exit, @Duration, 'Manual', 'Manual');

        DECLARE @AttID INT = SCOPE_IDENTITY();

        INSERT INTO AttendanceLog (attendance_id, actor, timestamp, reason)
        VALUES (@AttID, (SELECT full_name FROM Employee WHERE employee_id = @RecordedBy), GETDATE(), 'Manual Entry: ' + @Reason);

        PRINT 'Manual attendance recorded.';
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END









GO
CREATE PROC ReviewMissedPunches
    @ManagerID INT,
    @Date      DATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN PRINT 'Manager not authorized.'; RETURN; END

    SELECT
        E.employee_id,
        E.full_name,
        SS.shift_date,
        A.entry_time,
        A.exit_time
    FROM Employee E
    INNER JOIN ShiftAssignment SA ON E.employee_id = SA.employee_id
    INNER JOIN ShiftSchedule SS   ON SA.shift_id = SS.shift_id
    LEFT  JOIN Attendance A      ON E.employee_id = A.employee_id 
                                     AND CAST(A.entry_time AS DATE) = @Date
    WHERE E.manager_id = @ManagerID
      AND SS.shift_date = @Date
      AND (A.entry_time IS NULL OR A.exit_time IS NULL)
    ORDER BY E.full_name;
END






GO
CREATE PROC ApproveTimeRequest
    @RequestID  INT,
    @ManagerID  INT,
    @Decision   VARCHAR(20), 
    @Comments   VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Decision NOT IN ('Approved', 'Rejected')
    BEGIN PRINT 'Decision must be Approved or Rejected.'; RETURN; END

    IF NOT EXISTS (SELECT 1 FROM AttendanceCorrectionRequest ACR
                   INNER JOIN Employee E ON ACR.employee_id = E.employee_id
                   WHERE ACR.request_id = @RequestID AND E.manager_id = @ManagerID)
    BEGIN PRINT 'Request not found or unauthorized.'; RETURN; END

    UPDATE AttendanceCorrectionRequest
    SET status = @Decision,
        reason = reason + ISNULL(' | Manager comment: ' + @Comments, '')
    WHERE request_id = @RequestID;

    PRINT 'Correction request ' + @Decision + '.';
END









GO
CREATE PROC ViewLeaveRequest
    @LeaveRequestID INT,
    @ManagerID INT
AS
BEGIN
    IF @LeaveRequestID IS NULL OR @ManagerID IS NULL
    BEGIN
    PRINT 'Leave request ID and manager ID cannot be null.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN
        PRINT 'Manager not found.'
        RETURN
    END

    SELECT 
        LR.request_id,
        E.employee_id,
        E.full_name,
        L.leave_type,
        L.leave_description,
        LR.justification,
        LR.duration,
        LR.approval_timing,
        LR.status
    FROM LeaveRequest LR
    INNER JOIN Employee E ON LR.employee_id = E.employee_id
    INNER JOIN [Leave] L ON LR.leave_id = L.leave_id
    WHERE LR.request_id = @LeaveRequestID
        AND E.manager_id = @ManagerID
END





/*
GO
CREATE PROC ApproveLeaveRequest
    @LeaveRequestID INT,
    @ManagerID INT
AS
BEGIN
    IF @LeaveRequestID IS NULL OR @ManagerID IS NULL
    BEGIN
    PRINT 'Leave request ID and manager ID cannot be null.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM LeaveRequest WHERE request_id = @LeaveRequestID)
    BEGIN
        PRINT 'Leave request not found.'
        RETURN
    END

    IF NOT EXISTS (
        SELECT 1 
        FROM LeaveRequest LR
        INNER JOIN Employee E ON LR.employee_id = E.employee_id
        WHERE LR.request_id = @LeaveRequestID AND E.manager_id = @ManagerID
    )
    BEGIN
        PRINT 'Manager not authorized for this request.'
        RETURN
    END

    UPDATE LeaveRequest
    SET status = 'Approved',
        approval_timing = GETDATE()
    WHERE request_id = @LeaveRequestID

    PRINT 'Leave request #' + CAST(@LeaveRequestID AS VARCHAR) + ' has been approved by manager #' + CAST(@ManagerID AS VARCHAR) + '.'
END


*/

GO
DROP PROCEDURE IF EXISTS ApproveLeaveRequest;
GO

CREATE PROC ApproveLeaveRequest
    @LeaveRequestID INT,
    @ApproverID INT,
    @Status VARCHAR(20) = 'Approved'
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @LeaveRequestID IS NULL OR @ApproverID IS NULL
    BEGIN
        RAISERROR('Leave request ID and approver ID cannot be null.', 16, 1);
        RETURN;
    END
    
    IF NOT EXISTS (SELECT 1 FROM LeaveRequest WHERE request_id = @LeaveRequestID)
    BEGIN
        RAISERROR('Leave request not found.', 16, 1);
        RETURN;
    END
    
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ApproverID)
    BEGIN
        RAISERROR('Approver not found.', 16, 1);
        RETURN;
    END
    
    DECLARE @IsHRAdmin BIT = 0;
    DECLARE @IsManager BIT = 0;
    
    IF EXISTS (SELECT 1 FROM HRAdministrator WHERE employee_id = @ApproverID)
        SET @IsHRAdmin = 1;
    
    IF EXISTS (
        SELECT 1 
        FROM LeaveRequest LR
        INNER JOIN Employee E ON LR.employee_id = E.employee_id
        WHERE LR.request_id = @LeaveRequestID 
          AND E.manager_id = @ApproverID
    )
        SET @IsManager = 1;
    
    IF @IsHRAdmin = 0 AND @IsManager = 0
    BEGIN
        RAISERROR('Approver not authorized for this request. Must be HR Admin or employee manager.', 16, 1);
        RETURN;
    END
    
    UPDATE LeaveRequest
    SET 
        status = @Status,
        approval_timing = GETDATE()
    WHERE request_id = @LeaveRequestID;
    
    DECLARE @ApproverType VARCHAR(20) = CASE WHEN @IsHRAdmin = 1 THEN 'HR Admin' ELSE 'Manager' END;
    PRINT CONCAT('Leave request #', @LeaveRequestID, ' has been ', @Status, 
                 ' by ', @ApproverType, ' #', @ApproverID, '.');
END
GO



GO
CREATE PROC RejectLeaveRequest
@LeaveRequestID INT,
    @ManagerID      INT,
    @Reason         VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM LeaveRequest LR
                   INNER JOIN Employee E ON LR.employee_id = E.employee_id
                   WHERE LR.request_id = @LeaveRequestID AND E.manager_id = @ManagerID)
    BEGIN PRINT 'Unauthorized or request not found.'; RETURN; END

    UPDATE LeaveRequest
    SET status = 'Rejected',
        approval_timing = GETDATE(),
        justification = justification + ' | Rejection: ' + @Reason
    WHERE request_id = @LeaveRequestID;

    PRINT 'Leave request rejected.';
END






GO
CREATE PROC DelegateLeaveApproval
    @ManagerID INT,
    @DelegateID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    IF @ManagerID IS NULL OR @DelegateID IS NULL OR @StartDate IS NULL OR @EndDate IS NULL
    BEGIN
    PRINT 'Please provide all required inputs.'
    RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
    BEGIN
        PRINT 'Manager not found.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @DelegateID)
    BEGIN
        PRINT 'Delegate employee not found.'
        RETURN
    END

    IF @StartDate > @EndDate
    BEGIN
        PRINT 'Start date must be before end date.'
        RETURN
    END

    DECLARE @NotificationID INT
    DECLARE @MessageContent VARCHAR(1000)

    SET @MessageContent = 'Leave approval authority delegated from manager #' + CAST(@ManagerID AS VARCHAR) + 
                         ' to employee #' + CAST(@DelegateID AS VARCHAR) + 
                         ' from ' + CAST(@StartDate AS VARCHAR) + ' to ' + CAST(@EndDate AS VARCHAR) + '.'

    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
    VALUES (@MessageContent, GETDATE(), 'Medium', 'Unread', 'Delegation Notice')

    SET @NotificationID = SCOPE_IDENTITY()

    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    VALUES (@DelegateID, @NotificationID, 'Sent', GETDATE())

    PRINT 'Leave approval authority delegated from manager #' + CAST(@ManagerID AS VARCHAR) + 
          ' to employee #' + CAST(@DelegateID AS VARCHAR) + '.'
END








GO
CREATE PROC FlagIrregularLeave
@EmployeeID        INT,
    @ManagerID         INT,
    @PatternDescription VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID AND manager_id = @ManagerID)
    BEGIN PRINT 'Unauthorized.'; RETURN; END

    INSERT INTO Exception (name, category, date, status)
    VALUES ('Irregular Leave - Emp #' + CAST(@EmployeeID AS VARCHAR), 'Leave Pattern', GETDATE(), 'Flagged');

    INSERT INTO Employee_Exception (employee_id, exception_id)
    VALUES (@EmployeeID, SCOPE_IDENTITY());

    DECLARE @NotifID INT;
    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
    VALUES ('Irregular leave flagged for emp #' + CAST(@EmployeeID AS VARCHAR) + ': ' + @PatternDescription,
            GETDATE(), 'High', 'Unread', 'Leave Alert');
    SET @NotifID = SCOPE_IDENTITY();

    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT employee_id, @NotifID, 'Sent', GETDATE()
    FROM HRAdministrator;

    PRINT 'Irregular leave flagged and HR notified.';
END







GO
CREATE PROC NotifyNewLeaveRequest
@ManagerID INT,
@RequestID INT
AS
BEGIN
IF @ManagerID IS NULL OR @RequestID IS NULL
BEGIN
PRINT 'Manager ID and request ID cannot be null.'
RETURN
END

IF NOT EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @ManagerID)
BEGIN
    PRINT 'Manager not found.'
    RETURN
END

IF NOT EXISTS (SELECT 1 FROM LeaveRequest WHERE request_id = @RequestID)
BEGIN
    PRINT 'Leave request not found.'
    RETURN
END

DECLARE @EmployeeID INT
DECLARE @LeaveType VARCHAR(50)
DECLARE @Duration INT

SELECT 
    @EmployeeID = LR.employee_id,
    @LeaveType = L.leave_type,
    @Duration = LR.duration
FROM LeaveRequest LR
INNER JOIN [Leave] L ON LR.leave_id = L.leave_id
WHERE LR.request_id = @RequestID

DECLARE @NotificationID INT
DECLARE @MessageContent VARCHAR(1000)

SET @MessageContent = 'New leave request #' + CAST(@RequestID AS VARCHAR) + 
                     ' from employee #' + CAST(@EmployeeID AS VARCHAR) + 
                     ' - Type: ' + @LeaveType + 
                     ' - Duration: ' + CAST(@Duration AS VARCHAR) + ' days.'

INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
VALUES (@MessageContent, GETDATE(), 'Medium', 'Unread', 'Leave Request')

SET @NotificationID = SCOPE_IDENTITY()

INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
VALUES (@ManagerID, @NotificationID, 'Sent', GETDATE())

SELECT @MessageContent AS notification_message
END








GO
CREATE OR ALTER PROC ConfigureSigningBonusPolicy
    @BonusType VARCHAR(50),
    @Amount DECIMAL(10,2),
    @EligibilityCriteria NVARCHAR(MAX)
AS
BEGIN
    IF @BonusType IS NULL OR @Amount IS NULL
    BEGIN
        PRINT 'Bonus type and amount are required.'
        RETURN
    END

    INSERT INTO PayrollPolicy (effective_date, type, description)
    VALUES (GETDATE(), 'Bonus', 'Signing Bonus: ' + @BonusType + ' - Amount: ' + CAST(@Amount AS VARCHAR));
    
    DECLARE @PolicyID INT = SCOPE_IDENTITY();

    INSERT INTO BonusPolicy (policy_id, bonus_type, eligibility_criteria)
    VALUES (@PolicyID, @BonusType, @EligibilityCriteria);

    PRINT 'Signing bonus policy "' + @BonusType + '" configured successfully with amount ' + 
          FORMAT(@Amount, 'C') + '.';
END















GO

CREATE PROC GenerateTaxStatement
    @EmployeeID INT,
    @TaxYear INT
AS
BEGIN
    IF @EmployeeID IS NULL OR @TaxYear IS NULL
    BEGIN
        PRINT 'Employee ID and tax year are required.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        PRINT 'Employee not found.'
        RETURN
    END

    IF @TaxYear < 2000 OR @TaxYear > YEAR(GETDATE())
    BEGIN
        PRINT 'Please enter a valid tax year.'
        RETURN
    END

    SELECT 
        E.employee_id,
        E.full_name,
        E.national_id,
        TF.jurisdiction,
        P.period_start,
        P.period_end,
        P.base_amount,
        P.taxes,
        P.contributions,
        P.adjustments,
        P.net_salary AS paid_amount,
        SUM(P.net_salary) OVER (PARTITION BY P.employee_id) AS total_taxable_income_annual,
        SUM(P.taxes) OVER (PARTITION BY P.employee_id) AS total_tax_withheld
    FROM Employee E
    INNER JOIN Payroll P ON E.employee_id = P.employee_id
    LEFT JOIN TaxForm TF ON E.tax_form_id = TF.tax_form_id
    WHERE E.employee_id = @EmployeeID
      AND YEAR(P.period_end) = @TaxYear
    ORDER BY P.period_end

    PRINT 'Tax statement generated for employee #' + CAST(@EmployeeID AS VARCHAR) + ' for year ' + CAST(@TaxYear AS VARCHAR) + '.'
END











GO
CREATE PROC ApprovePayrollConfiguration
    @ConfigID INT,
    @ApprovedBy INT
AS
BEGIN
    IF @ConfigID IS NULL OR @ApprovedBy IS NULL
    BEGIN
        PRINT 'Configuration ID and approver ID are required.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM PayrollPolicy WHERE policy_id = @ConfigID)
    BEGIN
        PRINT 'Payroll configuration not found.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM HRAdministrator WHERE employee_id = @ApprovedBy)
       AND NOT EXISTS (SELECT 1 FROM SystemAdministrator WHERE employee_id = @ApprovedBy)
    BEGIN
        PRINT 'Only HR or System Administrators can approve configurations.'
        RETURN
    END

    UPDATE PayrollPolicy
    SET effective_date = GETDATE()
    WHERE policy_id = @ConfigID

    PRINT 'Payroll configuration #' + CAST(@ConfigID AS VARCHAR) + 
          ' has been approved and is now effective (approved by #' + CAST(@ApprovedBy AS VARCHAR) + ').'
END











GO
CREATE PROC ModifyPastPayroll
    @PayrollRunID INT,
    @EmployeeID INT,
    @FieldName VARCHAR(50),
    @NewValue DECIMAL(10,2),
    @ModifiedBy INT
AS
BEGIN
    IF @PayrollRunID IS NULL OR @EmployeeID IS NULL OR @FieldName IS NULL OR @ModifiedBy IS NULL
    BEGIN
        PRINT 'All fields are required.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM Payroll WHERE payroll_id = @PayrollRunID AND employee_id = @EmployeeID)
    BEGIN
        PRINT 'Payroll record not found for this employee.'
        RETURN
    END

    IF NOT EXISTS (SELECT 1 FROM HRAdministrator WHERE employee_id = @ModifiedBy)
       AND NOT EXISTS (SELECT 1 FROM PayrollSpecialist WHERE employee_id = @ModifiedBy)
    BEGIN
        PRINT 'You are not authorized to modify payroll records.'
        RETURN
    END

    IF @FieldName = 'base_amount'
        UPDATE Payroll SET base_amount = @NewValue, adjustments = adjustments WHERE payroll_id = @PayrollRunID
    ELSE IF @FieldName = 'taxes'
        UPDATE Payroll SET taxes = @NewValue WHERE payroll_id = @PayrollRunID
    ELSE IF @FieldName = 'contributions'
        UPDATE Payroll SET contributions = @NewValue WHERE payroll_id = @PayrollRunID
    ELSE IF @FieldName = 'adjustments'
        UPDATE Payroll SET adjustments = @NewValue WHERE payroll_id = @PayrollRunID
    ELSE
    BEGIN
        PRINT 'Invalid field name. Allowed: base_amount, taxes, contributions, adjustments.'
        RETURN
    END

    INSERT INTO Payroll_Log (payroll_id, actor, change_date, modification_type)
    VALUES (@PayrollRunID, @ModifiedBy, GETDATE(), 'Manual Correction - ' + @FieldName + ' changed to ' + CAST(@NewValue AS VARCHAR))

    PRINT 'Payroll record #' + CAST(@PayrollRunID AS VARCHAR) + 
          ' for employee #' + CAST(@EmployeeID AS VARCHAR) + 
          ' updated successfully (' + @FieldName + ' to ' + FORMAT(@NewValue, 'N2') + ').'
END



--Khaled part 5 Employee procedures
--===============================================1
GO
CREATE PROC SubmitLeaveRequest
@EmployeeID int,
@LeaveTypeID int,
@StartDate date,
@EndDate date,
@Reason varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @LeaveTypeID IS NULL OR @StartDate IS NULL OR @EndDate IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF @EndDate < @StartDate
        PRINT 'End date cannot be earlier than start date'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @Duration INT
        SET @Duration = DATEDIFF(DAY, @StartDate, @EndDate) + 1
        
        INSERT INTO LeaveRequest (employee_id, leave_id, justification, duration, status, submission_date)
        VALUES (@EmployeeID, @LeaveTypeID, @Reason, @Duration, 'Pending', GETDATE())
        
        PRINT 'Leave request submitted successfully.'
    END
END
GO

--===============================================2
GO
CREATE PROC GetLeaveBalance
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'input is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @RemainingBalance int

        SELECT @RemainingBalance = ISNULL(SUM(entitlement), 0)
        FROM LeaveEntitlement
        WHERE employee_id = @EmployeeID

        PRINT 'Employee with id ' + CAST(@EmployeeID AS VARCHAR(10)) + ' has ' + CAST(@RemainingBalance AS VARCHAR(10)) + ' remaining leave days'
    END
END
GO

--===============================================3
GO
CREATE PROC RecordAttendance
@EmployeeID int,
@ShiftID int,
@EntryTime time,
@ExitTime time
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @ShiftID IS NULL OR @EntryTime IS NULL OR @ExitTime IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF @ExitTime < @EntryTime
        PRINT 'Exit time cannot be earlier than Entry time'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @Duration decimal(10,2)
        
        IF @ExitTime IS NOT NULL
            SET @Duration = DATEDIFF(MINUTE, @EntryTime, @ExitTime) / 60.0
        ELSE
            SET @Duration = 0

        INSERT INTO Attendance (employee_id, shift_id, entry_time, exit_time, duration, login_method)
        VALUES (@EmployeeID, @ShiftID, @EntryTime, @ExitTime, @Duration, 'Manual')

        PRINT 'Attendance recorded successfully.'
    END
END
GO

--===============================================4
GO
CREATE PROC SubmitReimbursement
@EmployeeID int,
@ExpenseType varchar(50),
@Amount decimal(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @ExpenseType IS NULL OR @Amount IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        INSERT INTO Reimbursement (employee_id, type, claim_type, amount, approval_date, current_status)
        VALUES (@EmployeeID, @ExpenseType, 'General', @Amount, GETDATE(), 'Pending')

        PRINT 'Reimbursement request submitted successfully.'
    END
END
GO

--===============================================5
GO
CREATE PROC AddEmployeeSkill
@EmployeeID int,
@SkillName varchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @SkillName IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @SkillID int

        SELECT @SkillID = skill_id FROM Skill WHERE skill_name = @SkillName

        IF @SkillID IS NULL
        BEGIN
            INSERT INTO Skill (skill_name, description) VALUES (@SkillName, 'User Added')
            SET @SkillID = SCOPE_IDENTITY()
        END

        IF EXISTS (SELECT 1 FROM Employee_Skill WHERE employee_id = @EmployeeID AND skill_id = @SkillID)
        BEGIN
            PRINT 'Employee already possesses this skill.'
        END
        ELSE
        BEGIN
            INSERT INTO Employee_Skill (employee_id, skill_id, proficiency_level)
            VALUES (@EmployeeID, @SkillID, 'Beginner')

            PRINT 'Skill added successfully.'
        END
    END
END
GO

--===============================================6
GO
CREATE PROC ViewAssignedShifts
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT 
            SS.shift_date AS [Shift Date],
            SS.start_time AS [Start Time],
            SS.end_time AS [End Time],
            SS.name AS [Assigned Location/Shift]
        FROM ShiftAssignment SA
        INNER JOIN ShiftSchedule SS ON SA.shift_id = SS.shift_id
        WHERE SA.employee_id = @EmployeeID
    END
END
GO

--===============================================7
GO
CREATE PROC ViewMyContracts
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT 
            C.contract_id AS [Contract ID],
            C.contract_type AS [Type],
            C.contract_start_date AS [Start Date],
            C.contract_end_date AS [End Date],
            C.contract_current_state AS [Status]
        FROM Employee E
        INNER JOIN Contract C ON E.contract_id = C.contract_id
        WHERE E.employee_id = @EmployeeID
    END
END
GO

--===============================================8
GO
CREATE PROC ViewMyPayroll
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'Employee id is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT 
            period_start AS [Period Start],
            period_end AS [Period End],
            payment_date AS [Payment Date],
            base_amount AS [Base Salary],
            net_salary AS [Net Pay],
            taxes AS [Tax Deducted]
        FROM Payroll
        WHERE employee_id = @EmployeeID
        ORDER BY payment_date DESC
    END
END
GO

--===============================================9
GO
CREATE PROC UpdatePersonalDetails
    @EmployeeID int,
    @Phone varchar(20),    
    @Address varchar(150)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @Phone IS NULL OR @Address IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        UPDATE Employee
        SET 
            phone = @Phone,
            address = @Address
        WHERE employee_id = @EmployeeID;

        PRINT 'Details updated successfully';
    END
END
GO

--===============================================10
GO
CREATE PROC ViewMyMissions
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT *
        FROM Mission
        WHERE employee_id = @EmployeeID
    END
END
GO

--===============================================11
GO
CREATE PROC ViewEmployeeProfile
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'EmployeeID is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT 
            E.first_name AS [First Name],
            E.last_name AS [Last Name],
            E.email AS [Email],
            E.phone AS [Phone],
            E.address AS [Address],
            D.department_name AS [Department],
            P.position_title AS [Job Title],
            E.employment_status AS [Status],
            E.hire_date AS [Date Hired]
        FROM Employee E
        INNER JOIN Department D ON E.department_id = D.department_id
        INNER JOIN Position P ON E.position_id = P.position_id
        WHERE E.employee_id = @EmployeeID
    END
END
GO

--===============================================12
GO
CREATE PROC UpdateContactInformation
@EmployeeID int,
@RequestType varchar(50),
@NewValue varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @RequestType IS NULL OR @NewValue IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        IF LOWER(@RequestType) = 'phone'
        BEGIN
            UPDATE Employee 
            SET phone = @NewValue 
            WHERE employee_id = @EmployeeID;
            PRINT 'Phone number updated successfully.';
        END
        ELSE IF LOWER(@RequestType) = 'address'
        BEGIN
            UPDATE Employee 
            SET address = @NewValue 
            WHERE employee_id = @EmployeeID;
            PRINT 'Address updated successfully.';
        END
        ELSE
        BEGIN
            PRINT 'Invalid Request Type. Please specify "Phone" or "Address".';
        END
    END
END
GO

--===============================================13
GO
CREATE PROC ViewEmploymentTimeline
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT 
            hire_date AS [Event Date],
            'Hired' AS [Event Type],
            'Joined the company' AS [Description]
        FROM Employee
        WHERE employee_id = @EmployeeID
        
        UNION ALL
        
        SELECT 
            ER.assigned_date,
            'Role Assigned',
            R.role_name
        FROM Employee_Role ER
        INNER JOIN Role R ON ER.role_id = R.role_id
        WHERE ER.employee_id = @EmployeeID

        UNION ALL

        SELECT 
            C.contract_start_date,
            'Contract Started',
            C.contract_type + ' (' + C.contract_current_state + ')'
        FROM Contract C
        INNER JOIN Employee E ON E.contract_id = C.contract_id
        WHERE E.employee_id = @EmployeeID

        UNION ALL

        SELECT 
            T.date,
            'Terminated',
            ISNULL(T.reason, 'End of Contract')
        FROM Termination T
        INNER JOIN Contract C ON T.contract_id = C.contract_id
        INNER JOIN Employee E ON E.contract_id = C.contract_id
        WHERE E.employee_id = @EmployeeID

        UNION ALL

        SELECT 
            start_date,
            'Mission Started',
            'Trip to ' + destination
        FROM Mission
        WHERE employee_id = @EmployeeID

        ORDER BY [Event Date] ASC
    END
END
GO

--===============================================14
GO
CREATE PROC UpdateEmergencyContact
@EmployeeID int, 
@ContactName varchar(100), 
@Relation varchar(50), 
@Phone varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @ContactName IS NULL OR @Relation IS NULL OR @Phone IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        UPDATE Employee
        SET emergency_contact_name = @ContactName,
            relationship = @Relation,
            emergency_contact_phone = @Phone
        WHERE employee_id = @EmployeeID

        PRINT 'Emergency contact details updated successfully.'
    END
END
GO

--===============================================15
GO
CREATE PROC RequestHRDocument
@EmployeeID int, 
@DocumentType varchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @DocumentType IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @Msg VARCHAR(1000)
        SET @Msg = 'Employee ' + CAST(@EmployeeID AS VARCHAR) + ' has requested: ' + @DocumentType

        INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
        VALUES (@Msg, GETDATE(), 'Medium', 'Unread', 'HR Document Request')

        DECLARE @NotifID INT = SCOPE_IDENTITY()
        INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
        VALUES (@EmployeeID, @NotifID, 'Sent', GETDATE())

        PRINT 'HR Document request submitted successfully.'
    END
END
GO

--===============================================16
GO
CREATE PROC NotifyProfileUpdate
@EmployeeID int,
@notificationType varchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @notificationType IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @Message VARCHAR(1000)
        SET @Message = 'Your profile has been updated. Update Type: ' + @notificationType

        INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
        VALUES (@Message, GETDATE(), 'Low', 'Unread', 'Profile Alert')

        DECLARE @NewNotifID INT = SCOPE_IDENTITY()
        INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
        VALUES (@EmployeeID, @NewNotifID, 'Delivered', GETDATE())

        PRINT 'Profile update notification sent successfully.'
    END
END
GO

--===============================================17
GO
CREATE PROC LogFlexibleAttendance
@EmployeeID int, 
@Date date, 
@CheckIn time, 
@CheckOut time
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @Date IS NULL OR @CheckIn IS NULL OR @CheckOut IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF @CheckOut < @CheckIn
        PRINT 'Check-Out time cannot be earlier than Check-In time'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @ShiftID INT
        DECLARE @Duration DECIMAL(20,2)

        SELECT @ShiftID = SS.shift_id
        FROM ShiftAssignment SA
        JOIN ShiftSchedule SS ON SA.shift_id = SS.shift_id
        WHERE SA.employee_id = @EmployeeID AND SS.shift_date = @Date

        IF @ShiftID IS NULL
        BEGIN
            PRINT 'No shift assigned for this date. Cannot log attendance.'
        END
        ELSE
        BEGIN
            SET @Duration = DATEDIFF(MINUTE, @CheckIn, @CheckOut) / 60.0

            INSERT INTO Attendance (employee_id, shift_id, entry_time, exit_time, duration, login_method)
            VALUES (@EmployeeID, @ShiftID, @CheckIn, @CheckOut, @Duration, 'Flexible')

            PRINT 'Flexible attendance logged. Total Hours: ' + CAST(@Duration AS VARCHAR(20))
        END
    END
END
GO

--===============================================18
GO
CREATE PROC NotifyMissedPunch
@EmployeeID int, 
@Date date
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @Date IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM Attendance A
            JOIN ShiftSchedule SS ON A.shift_id = SS.shift_id
            WHERE A.employee_id = @EmployeeID 
              AND SS.shift_date = @Date
              AND A.exit_time IS NULL
        )
        BEGIN
            PRINT 'Missed Punch Detected: You have not clocked out for ' + CAST(@Date AS VARCHAR(20))
            
            INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
            VALUES ('Missed Punch Detected for ' + CAST(@Date AS VARCHAR(20)), GETDATE(), 'High', 'Unread', 'Attendance Alert')
            
            INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
            VALUES (@EmployeeID, SCOPE_IDENTITY(), 'Delivered', GETDATE())
        END
        ELSE
        BEGIN
            PRINT 'No missed punches found for this date.'
        END
    END
END
GO

--===============================================19
GO
CREATE PROC RecordMultiplePunches
@EmployeeID int,
@ClockInOutTime datetime,
@Type varchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @ClockInOutTime IS NULL OR @Type IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @TimePart TIME = CAST(@ClockInOutTime AS TIME)
        DECLARE @DatePart DATE = CAST(@ClockInOutTime AS DATE)
        DECLARE @ShiftID INT

        SELECT @ShiftID = SS.shift_id
        FROM ShiftAssignment SA
        JOIN ShiftSchedule SS ON SA.shift_id = SS.shift_id
        WHERE SA.employee_id = @EmployeeID AND SS.shift_date = @DatePart

        IF UPPER(@Type) = 'IN'
        BEGIN
            INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
            VALUES (@EmployeeID, @ShiftID, @TimePart, 'Manual/Multi')
            
            PRINT 'Clock IN recorded successfully.'
        END
        ELSE IF UPPER(@Type) = 'OUT'
        BEGIN
            DECLARE @AttendanceID INT
            
            SELECT TOP 1 @AttendanceID = attendance_id
            FROM Attendance
            WHERE employee_id = @EmployeeID 
              AND exit_time IS NULL 
            ORDER BY attendance_id DESC

            IF @AttendanceID IS NOT NULL
            BEGIN
                DECLARE @EntryTime TIME
                SELECT @EntryTime = entry_time FROM Attendance WHERE attendance_id = @AttendanceID
                
                DECLARE @Duration DECIMAL(10,2) = DATEDIFF(MINUTE, @EntryTime, @TimePart) / 60.0

                UPDATE Attendance
                SET exit_time = @TimePart,
                    duration = @Duration,
                    logout_method = 'Manual/Multi'
                WHERE attendance_id = @AttendanceID

                PRINT 'Clock OUT recorded successfully.'
            END
            ELSE
            BEGIN
                PRINT 'Error: No open Clock-IN record found to close.'
            END
        END
        ELSE
        BEGIN
            PRINT 'Invalid Type. Please use "IN" or "OUT".'
        END
    END
END
GO

--===============================================20
GO
CREATE PROC SubmitCorrectionRequest
@EmployeeID int,
@Date date,
@CorrectionType varchar(50),
@Reason varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @Date IS NULL OR @CorrectionType IS NULL OR @Reason IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        INSERT INTO AttendanceCorrectionRequest (employee_id, date, correction_type, reason, status, recorded_by)
        VALUES (@EmployeeID, @Date, @CorrectionType, @Reason, 'Pending', @EmployeeID)

        PRINT 'Correction request submitted successfully.'
    END
END
GO

--===============================================21
GO
CREATE PROC ViewRequestStatus
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT 
            request_id AS [Request ID],
            'Attendance Correction' AS [Request Type],
            correction_type AS [Sub Type],
            reason AS [Description],
            date AS [Related Date],
            status AS [Status]
        FROM AttendanceCorrectionRequest
        WHERE employee_id = @EmployeeID

        UNION ALL

        SELECT 
            request_id,
            'Leave Request',
            'Time Off',
            justification,
            NULL,
            status
        FROM LeaveRequest
        WHERE employee_id = @EmployeeID
    END
END
GO

--===============================================23
GO
CREATE PROC AttachLeaveDocuments
@LeaveRequestID int,
@FilePath varchar(200)
AS
BEGIN
    SET NOCOUNT ON;
    IF @LeaveRequestID IS NULL OR @FilePath IS NULL
        PRINT 'One of the inputs is null'
    ELSE
    BEGIN
        INSERT INTO LeaveDocument (leave_request_id, file_path, uploaded_at)
        VALUES (@LeaveRequestID, @FilePath, GETDATE())

        PRINT 'Document attached successfully.'
    END
END
GO

--===============================================24
GO
CREATE PROC ModifyLeaveRequest
@LeaveRequestID int,
@StartDate date,
@EndDate date,
@Reason varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF @LeaveRequestID IS NULL OR @StartDate IS NULL OR @EndDate IS NULL OR @Reason IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF @EndDate < @StartDate
        PRINT 'End date cannot be earlier than start date'
    ELSE
    BEGIN
        DECLARE @CurrentStatus VARCHAR(10)
        
        SELECT @CurrentStatus = status FROM LeaveRequest WHERE request_id = @LeaveRequestID

        IF @CurrentStatus = 'Pending'
        BEGIN
            DECLARE @NewDuration INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1

            UPDATE LeaveRequest
            SET duration = @NewDuration,
                justification = @Reason
            WHERE request_id = @LeaveRequestID

            PRINT 'Leave request modified successfully.'
        END
        ELSE
        BEGIN
            PRINT 'Cannot modify request. It has already been processed (Approved/Rejected).'
        END
    END
END
GO

--===============================================25
GO
CREATE PROC CancelLeaveRequest
@LeaveRequestID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @LeaveRequestID IS NULL
        PRINT 'Leave id is null'
    ELSE
    BEGIN
        DECLARE @Status VARCHAR(10)

        SELECT @Status = status FROM LeaveRequest WHERE request_id = @LeaveRequestID

        IF @Status = 'Pending'
        BEGIN
            DELETE FROM LeaveRequest WHERE request_id = @LeaveRequestID
            
            PRINT 'Leave request cancelled successfully.'
        END
        ELSE
        BEGIN
            PRINT 'Cannot cancel request. It has already been processed.'
        END
    END
END
GO

--===============================================26
GO
CREATE PROC ViewLeaveBalance
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT 
            L.leave_type AS [Leave Type],
            LE.entitlement AS [Remaining Balance]
        FROM LeaveEntitlement LE
        INNER JOIN [Leave] L ON LE.leave_type_id = L.leave_id
        WHERE LE.employee_id = @EmployeeID
    END
END
GO

--===============================================27
GO
CREATE PROC ViewLeaveHistory
@EmployeeID int
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        SELECT 
            LR.request_id AS [Request ID],
            L.leave_type AS [Leave Type],
            LR.justification AS [Reason],
            LR.duration AS [Days],
            LR.submission_date AS [Date Submitted],
            LR.approval_timing AS [Date Approved/Rejected],
            LR.status AS [Current Status]
        FROM LeaveRequest LR
        INNER JOIN [Leave] L ON LR.leave_id = L.leave_id
        WHERE LR.employee_id = @EmployeeID
        ORDER BY LR.approval_timing DESC
    END
END
GO

--===============================================28
GO
CREATE PROC SubmitLeaveAfterAbsence
@EmployeeID int,
@LeaveTypeID int,
@StartDate date,
@EndDate date,
@Reason varchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @LeaveTypeID IS NULL OR @StartDate IS NULL OR @EndDate IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF @EndDate < @StartDate
        PRINT 'End date cannot be earlier than start date'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @Duration INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1

        INSERT INTO LeaveRequest (employee_id, leave_id, justification, duration, submission_date, status)
        VALUES (@EmployeeID, @LeaveTypeID, @Reason + '(Submitted after absence)', @Duration, GETDATE(), 'Pending')

        PRINT 'Leave request submitted successfully after absence (Late request).'
    END
END
GO

--===============================================29
GO
CREATE PROC NotifyLeaveStatusChange
@EmployeeID int,
@RequestID int,
@Status varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF @EmployeeID IS NULL OR @RequestID IS NULL OR @Status IS NULL
        PRINT 'One of the inputs is null'
    ELSE IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
        PRINT 'Error: Employee ID not found.'
    ELSE
    BEGIN
        DECLARE @Msg VARCHAR(1000)
        SET @Msg = 'Your Leave Request #' + CAST(@RequestID AS VARCHAR) + ' has been ' + @Status

        INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type)
        VALUES (@Msg, GETDATE(), 'Medium', 'Unread', 'Leave Status Update')

        DECLARE @NotifID INT = SCOPE_IDENTITY()
        INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
        VALUES (@EmployeeID, @NotifID, 'Delivered', GETDATE())

        PRINT 'Notification sent to employee.'
    END
END
GO
--extra needed procedures
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetEmployeeByEmail')
    DROP PROCEDURE GetEmployeeByEmail;
GO

CREATE PROCEDURE GetEmployeeByEmail
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.full_name,
        e.national_id,
        e.date_of_birth,
        e.country_of_birth,
        e.phone,
        e.email,
        e.address,
        e.emergency_contact_name,
        e.emergency_contact_phone,
        e.relationship,
        e.biography,
        e.profile_image,
        e.employment_progress,
        e.account_status,
        e.employment_status,
        e.hire_date,
        e.is_active,
        e.profile_completion,
        e.department_id,
        e.position_id,
        e.manager_id,
        e.contract_id,
        e.tax_form_id,
        e.salary_type_id,
        e.pay_grade,
        e.password_hash,
        e.password_salt,
        e.last_login,
        e.is_locked,
        -- Get primary role (first role assigned, or role with highest priority)
        (SELECT TOP 1 r.role_name 
         FROM Employee_Role er 
         JOIN Role r ON er.role_id = r.role_id 
         WHERE er.employee_id = e.employee_id 
         ORDER BY er.assigned_date ASC) AS role_name,
        d.department_name,
        p.position_title,
        m.full_name AS manager_name
    FROM Employee e
    LEFT JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Position p ON e.position_id = p.position_id
    LEFT JOIN Employee m ON e.manager_id = m.employee_id
    WHERE e.email = @Email;
END
GO

-- Procedure: UpdateLastLogin
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateLastLogin')
    DROP PROCEDURE UpdateLastLogin;
GO

CREATE PROCEDURE UpdateLastLogin
    @EmployeeID INT,
    @LastLogin DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Employee
    SET last_login = @LastLogin
    WHERE employee_id = @EmployeeID;
END
GO

-- Procedure: UpdateProfilePicture
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateProfilePicture')
    DROP PROCEDURE UpdateProfilePicture;
GO

CREATE PROCEDURE UpdateProfilePicture
    @EmployeeID INT,
    @ProfileImage NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Employee
    SET profile_image = @ProfileImage
    WHERE employee_id = @EmployeeID;
END
GO

-- Procedure: GetAllRoles
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetAllRoles')
    DROP PROCEDURE GetAllRoles;
GO

CREATE PROCEDURE GetAllRoles
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        role_id,
        role_name,
        purpose
    FROM Role
    ORDER BY role_id;
END
GO

-- Procedure: GetRoleById
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetRoleById')
    DROP PROCEDURE GetRoleById;
GO

CREATE PROCEDURE GetRoleById
    @RoleID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        role_id,
        role_name,
        purpose
    FROM Role
    WHERE role_id = @RoleID;
END
GO

-- Procedure: GetRoleByName
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetRoleByName')
    DROP PROCEDURE GetRoleByName;
GO

CREATE PROCEDURE GetRoleByName
    @RoleName VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        role_id,
        role_name,
        purpose
    FROM Role
    WHERE role_name = @RoleName;
END
GO

-- =============================================
-- Employee_Role Management Procedures
-- =============================================

-- Procedure: AssignEmployeeRole
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'AssignEmployeeRole')
    DROP PROCEDURE AssignEmployeeRole;
GO

CREATE PROCEDURE AssignEmployeeRole
    @EmployeeID INT,
    @RoleID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if assignment already exists
    IF NOT EXISTS (SELECT 1 FROM Employee_Role WHERE employee_id = @EmployeeID AND role_id = @RoleID)
    BEGIN
        INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
        VALUES (@EmployeeID, @RoleID, GETDATE());
        
        PRINT 'Role assigned successfully.';
    END
    ELSE
    BEGIN
        PRINT 'Employee already has this role.';
    END
END
GO

-- Procedure: RemoveEmployeeRole
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'RemoveEmployeeRole')
    DROP PROCEDURE RemoveEmployeeRole;
GO

CREATE PROCEDURE RemoveEmployeeRole
    @EmployeeID INT,
    @RoleID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DELETE FROM Employee_Role
    WHERE employee_id = @EmployeeID AND role_id = @RoleID;
    
    PRINT 'Role removed successfully.';
END
GO

-- Procedure: GetEmployeeRoles
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetEmployeeRoles')
    DROP PROCEDURE GetEmployeeRoles;
GO

CREATE PROCEDURE GetEmployeeRoles
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        er.role_id,
        r.role_name,
        r.purpose,
        er.assigned_date
    FROM Employee_Role er
    JOIN Role r ON er.role_id = r.role_id
    WHERE er.employee_id = @EmployeeID
    ORDER BY er.assigned_date ASC;
END
GO

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GenerateProfileReport')
    DROP PROCEDURE GenerateProfileReport;
GO

CREATE PROCEDURE GenerateProfileReport
    @FilterField VARCHAR(50),
    @FilterValue VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Base query with JOINs to get department_name, position_title, manager_name
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = '
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.full_name,
        e.national_id,
        e.date_of_birth,
        e.country_of_birth,
        e.phone,
        e.email,
        e.address,
        e.emergency_contact_name,
        e.emergency_contact_phone,
        e.relationship,
        e.biography,
        e.profile_image,
        e.employment_progress,
        e.account_status,
        e.employment_status,
        e.hire_date,
        e.is_active,
        e.profile_completion,
        e.department_id,
        e.position_id,
        e.manager_id,
        e.contract_id,
        e.tax_form_id,
        e.salary_type_id,
        e.pay_grade,
        e.password_hash,
        e.password_salt,
        e.last_login,
        e.is_locked,
        d.department_name,
        p.position_title,
        m.full_name AS manager_name
    FROM Employee e
    LEFT JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Position p ON e.position_id = p.position_id
    LEFT JOIN Employee m ON e.manager_id = m.employee_id
    WHERE 1=1';

    -- Text fields
    IF @FilterField = 'first_name'
        SET @SQL = @SQL + ' AND e.first_name = @FilterValue';
    ELSE IF @FilterField = 'last_name'
        SET @SQL = @SQL + ' AND e.last_name = @FilterValue';
    ELSE IF @FilterField = 'country_of_birth'
        SET @SQL = @SQL + ' AND e.country_of_birth = @FilterValue';
    ELSE IF @FilterField = 'phone'
        SET @SQL = @SQL + ' AND e.phone = @FilterValue';
    ELSE IF @FilterField = 'email'
        SET @SQL = @SQL + ' AND e.email = @FilterValue';
    ELSE IF @FilterField = 'address'
        SET @SQL = @SQL + ' AND e.address = @FilterValue';
    ELSE IF @FilterField = 'emergency_contact_name'
        SET @SQL = @SQL + ' AND e.emergency_contact_name = @FilterValue';
    ELSE IF @FilterField = 'emergency_contact_phone'
        SET @SQL = @SQL + ' AND e.emergency_contact_phone = @FilterValue';
    ELSE IF @FilterField = 'relationship'
        SET @SQL = @SQL + ' AND e.relationship = @FilterValue';
    ELSE IF @FilterField = 'biography'
        SET @SQL = @SQL + ' AND e.biography = @FilterValue';
    ELSE IF @FilterField = 'profile_image'
        SET @SQL = @SQL + ' AND e.profile_image = @FilterValue';
    ELSE IF @FilterField = 'employment_progress'
        SET @SQL = @SQL + ' AND e.employment_progress = @FilterValue';
    ELSE IF @FilterField = 'account_status'
        SET @SQL = @SQL + ' AND e.account_status = @FilterValue';
    ELSE IF @FilterField = 'employment_status'
        SET @SQL = @SQL + ' AND e.employment_status = @FilterValue';
    
    -- Integer fields
    ELSE IF @FilterField IN ('department_id','position_id','manager_id','contract_id','tax_form_id','salary_type_id','pay_grade','profile_completion')
    BEGIN
        DECLARE @IntValue INT = TRY_CONVERT(INT, @FilterValue);
        IF @IntValue IS NULL
        BEGIN
            PRINT 'Invalid value for ' + @FilterField + '. Must be an integer.';
            RETURN;
        END
        
        IF @FilterField = 'department_id'
            SET @SQL = @SQL + ' AND e.department_id = ' + CAST(@IntValue AS VARCHAR(10));
        ELSE IF @FilterField = 'position_id'
            SET @SQL = @SQL + ' AND e.position_id = ' + CAST(@IntValue AS VARCHAR(10));
        ELSE IF @FilterField = 'manager_id'
            SET @SQL = @SQL + ' AND e.manager_id = ' + CAST(@IntValue AS VARCHAR(10));
        ELSE IF @FilterField = 'contract_id'
            SET @SQL = @SQL + ' AND e.contract_id = ' + CAST(@IntValue AS VARCHAR(10));
        ELSE IF @FilterField = 'tax_form_id'
            SET @SQL = @SQL + ' AND e.tax_form_id = ' + CAST(@IntValue AS VARCHAR(10));
        ELSE IF @FilterField = 'salary_type_id'
            SET @SQL = @SQL + ' AND e.salary_type_id = ' + CAST(@IntValue AS VARCHAR(10));
        ELSE IF @FilterField = 'pay_grade'
            SET @SQL = @SQL + ' AND e.pay_grade = ' + CAST(@IntValue AS VARCHAR(10));
        ELSE IF @FilterField = 'profile_completion'
            SET @SQL = @SQL + ' AND e.profile_completion = ' + CAST(@IntValue AS VARCHAR(10));
    END
    
    -- BIT fields
    ELSE IF @FilterField = 'is_active'
    BEGIN
        IF @FilterValue NOT IN ('0','1')
        BEGIN
            PRINT 'Invalid value for is_active. Must be 0 or 1.';
            RETURN;
        END
        SET @SQL = @SQL + ' AND e.is_active = ' + @FilterValue;
    END
    
    -- Date fields
    ELSE IF @FilterField IN ('date_of_birth', 'hire_date')
    BEGIN
        DECLARE @DateValue DATE = TRY_CONVERT(DATE, @FilterValue);
        IF @DateValue IS NULL
        BEGIN
            PRINT 'Invalid date value for ' + @FilterField;
            RETURN;
        END
        
        IF @FilterField = 'date_of_birth'
            SET @SQL = @SQL + ' AND e.date_of_birth = ''' + CONVERT(VARCHAR(10), @DateValue, 120) + '''';
        ELSE IF @FilterField = 'hire_date'
            SET @SQL = @SQL + ' AND e.hire_date = ''' + CONVERT(VARCHAR(10), @DateValue, 120) + '''';
    END

    -- Execute the dynamic SQL
    EXEC sp_executesql @SQL, N'@FilterValue VARCHAR(100)', @FilterValue;
END
GO

PRINT 'GenerateProfileReport procedure updated with JOINs for department_name, position_title, and manager_name.';
GO
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateEmployeeInfo')
    DROP PROCEDURE UpdateEmployeeInfo;
GO

CREATE PROCEDURE UpdateEmployeeInfo
    @EmployeeID INT,
    @Email VARCHAR(255),
    @Phone VARCHAR(30),
    @Address VARCHAR(255),
    @EmergencyContactName VARCHAR(100),
    @EmergencyContactPhone VARCHAR(30),
    @Relationship VARCHAR(50) = NULL,
    @ProfileImage VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Employee
    SET 
        email = @Email,
        phone = @Phone,
        address = @Address,
        emergency_contact_name = @EmergencyContactName,
        emergency_contact_phone = @EmergencyContactPhone,
        relationship = @Relationship,
        profile_image = @ProfileImage
    WHERE employee_id = @EmployeeID;
    
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('Employee not found', 16, 1);
    END
END
GO


IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'ViewEmployeeInfo')
    DROP PROCEDURE ViewEmployeeInfo;
GO

CREATE PROCEDURE ViewEmployeeInfo
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.full_name,
        e.national_id,
        e.date_of_birth,
        e.country_of_birth,
        e.phone,
        e.email,
        e.address,
        e.emergency_contact_name,
        e.emergency_contact_phone,
        e.relationship,
        e.biography,
        e.profile_image,
        e.employment_progress,
        e.account_status,
        e.employment_status,
        e.hire_date,
        e.is_active,
        e.profile_completion,
        e.department_id,
        e.position_id,
        e.manager_id,
        e.contract_id,
        e.tax_form_id,
        e.salary_type_id,
        e.pay_grade,
        e.password_hash,
        e.password_salt,
        e.last_login,
        e.is_locked,
        d.department_name,
        p.position_title,
        m.full_name AS manager_name
    FROM Employee e
    LEFT JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Position p ON e.position_id = p.position_id
    LEFT JOIN Employee m ON e.manager_id = m.employee_id
    WHERE e.employee_id = @EmployeeID;
END
GO
select * from Employee;
Select * from HRAdministrator

PRINT 'Starting Role-Based Stored Procedures Setup...';
GO

-- =============================================
-- Procedure: CreateAdminAccount
-- Description: Allows HR Admins, System Admins, and Line Managers to self-register
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'CreateAdminAccount')
    DROP PROCEDURE CreateAdminAccount;
GO

CREATE PROCEDURE CreateAdminAccount
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Email VARCHAR(255),
    @Password VARCHAR(100),
    @RoleId INT,
    @Phone VARCHAR(30) = NULL,
    @NationalId VARCHAR(30) = NULL,
    -- Role-specific parameters
    @ApprovalLevel VARCHAR(50) = NULL,
    @RecordAccessScope VARCHAR(100) = NULL,
    @DocumentValidationRights VARCHAR(100) = NULL,
    @SystemPrivilegeLevel VARCHAR(50) = NULL,
    @ConfigurableFields VARCHAR(200) = NULL,
    @AuditVisibilityScope VARCHAR(100) = NULL,
    @AssignedRegion VARCHAR(50) = NULL,
    @ProcessingFrequency VARCHAR(50) = NULL,
    @TeamSize INT = NULL,
    @SupervisedDepartments VARCHAR(200) = NULL,
    @ApprovalLimit VARCHAR(50) = NULL,
    @NewEmployeeID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate role is admin type (HR Admin, System Admin, or Line Manager)
        DECLARE @RoleName VARCHAR(50);
        SELECT @RoleName = role_name FROM Role WHERE role_id = @RoleId;
        
        IF @RoleName NOT IN ('HRAdministrator', 'SystemAdministrator', 'LineManager', 'PayrollSpecialist')
        BEGIN
            RAISERROR('Only admin roles can self-register (HR Admin, System Admin, Line Manager, Payroll Specialist)', 16, 1);
            RETURN;
        END
        
        -- Check if email already exists
        IF EXISTS (SELECT 1 FROM Employee WHERE email = @Email)
        BEGIN
            RAISERROR('Email already exists', 16, 1);
            RETURN;
        END
        
        -- Insert into Employee table
        INSERT INTO Employee (
            first_name, last_name, email, phone, national_id,
            password_hash, is_active, profile_completion, hire_date,
            department_id, position_id, contract_id, tax_form_id, salary_type_id
        )
        VALUES (
            @FirstName, @LastName, @Email, @Phone, @NationalId,
            @Password, 1, 30, GETDATE(),
            NULL, NULL, NULL, NULL, NULL
        );
        
        SET @NewEmployeeID = SCOPE_IDENTITY();
        
        -- Assign role
        INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
        VALUES (@NewEmployeeID, @RoleId, GETDATE());
        
        -- Insert role-specific data
        IF @RoleName = 'HRAdministrator'
        BEGIN
            INSERT INTO HRAdministrator (employee_id, approval_level, record_access_scope, document_validation_rights)
            VALUES (@NewEmployeeID, @ApprovalLevel, @RecordAccessScope, @DocumentValidationRights);
        END
        ELSE IF @RoleName = 'SystemAdministrator'
        BEGIN
            INSERT INTO SystemAdministrator (employee_id, system_privilege_level, configurable_fields, audit_visibility_scope)
            VALUES (@NewEmployeeID, @SystemPrivilegeLevel, @ConfigurableFields, @AuditVisibilityScope);
        END
        ELSE IF @RoleName = 'PayrollSpecialist'
        BEGIN
            INSERT INTO PayrollSpecialist (employee_id, assigned_region, processing_frequency, last_processed_period)
            VALUES (@NewEmployeeID, @AssignedRegion, @ProcessingFrequency, NULL);
        END
        ELSE IF @RoleName = 'LineManager'
        BEGIN
            INSERT INTO LineManager (employee_id, team_size, supervised_departments, approval_limit)
            VALUES (@NewEmployeeID, @TeamSize, @SupervisedDepartments, @ApprovalLimit);
        END
        
        COMMIT TRANSACTION;
        PRINT 'Admin account created successfully with ID: ' + CAST(@NewEmployeeID AS VARCHAR);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Procedure: CreateEmployeeByAdmin
-- Description: System Admin creates new employee account
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'CreateEmployeeByAdmin')
    DROP PROCEDURE CreateEmployeeByAdmin;
GO

CREATE PROCEDURE CreateEmployeeByAdmin
    @CreatorId INT,
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Email VARCHAR(255),
    @Password VARCHAR(100),
    @RoleId INT,
    @Phone VARCHAR(30) = NULL,
    @NationalId VARCHAR(30) = NULL,
    @DateOfBirth DATE = NULL,
    @CountryOfBirth VARCHAR(100) = NULL,
    @Address VARCHAR(255) = NULL,
    @DepartmentId INT = NULL,
    @PositionId INT = NULL,
    @ManagerId INT = NULL,
    @NewEmployeeID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verify creator is System Admin
        DECLARE @CreatorRole VARCHAR(50);
        SELECT TOP 1 @CreatorRole = r.role_name 
        FROM Employee_Role er 
        JOIN Role r ON er.role_id = r.role_id 
        WHERE er.employee_id = @CreatorId;
        
        IF @CreatorRole != 'SystemAdministrator'
        BEGIN
            RAISERROR('Only System Administrators can create employee accounts', 16, 1);
            RETURN;
        END
        
        -- Check if email already exists
        IF EXISTS (SELECT 1 FROM Employee WHERE email = @Email)
        BEGIN
            RAISERROR('Email already exists', 16, 1);
            RETURN;
        END
        
        -- Insert into Employee table
        INSERT INTO Employee (
            first_name, last_name, email, phone, national_id,
            date_of_birth, country_of_birth, address,
            password_hash, is_active, profile_completion, hire_date,
            department_id, position_id, manager_id,
            contract_id, tax_form_id, salary_type_id
        )
        VALUES (
            @FirstName, @LastName, @Email, @Phone, @NationalId,
            @DateOfBirth, @CountryOfBirth, @Address,
            @Password, 1, 40, GETDATE(),
            @DepartmentId, @PositionId, @ManagerId,
            NULL, NULL, NULL
        );
        
        SET @NewEmployeeID = SCOPE_IDENTITY();
        
        -- Assign role
        INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
        VALUES (@NewEmployeeID, @RoleId, GETDATE());
        
        COMMIT TRANSACTION;
        PRINT 'Employee account created successfully with ID: ' + CAST(@NewEmployeeID AS VARCHAR);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Procedure: CheckEditPermission
-- Description: Checks if a user can edit another employee's profile
-- Returns: 1 if allowed, 0 if denied
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'CheckEditPermission')
    DROP PROCEDURE CheckEditPermission;
GO

CREATE PROCEDURE CheckEditPermission
    @EditorId INT,
    @TargetEmployeeId INT,
    @CanEdit BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @CanEdit = 0;
    
    -- Check if editor is HR Administrator
    DECLARE @EditorRole VARCHAR(50);
    SELECT TOP 1 @EditorRole = r.role_name 
    FROM Employee_Role er 
    JOIN Role r ON er.role_id = r.role_id 
    WHERE er.employee_id = @EditorId
    ORDER BY er.assigned_date ASC;
    
    -- HR Admins can edit any profile
    IF @EditorRole = 'HRAdministrator'
    BEGIN
        SET @CanEdit = 1;
        RETURN;
    END
    
    -- Users can edit their own profile
    IF @EditorId = @TargetEmployeeId
    BEGIN
        SET @CanEdit = 1;
        RETURN;
    END
    
    -- Otherwise, no permission
    SET @CanEdit = 0;
END
GO

-- =============================================
-- Procedure: GetEmployeeWithRoleDetails
-- Description: Retrieves employee with role-specific information
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetEmployeeWithRoleDetails')
    DROP PROCEDURE GetEmployeeWithRoleDetails;
GO

CREATE PROCEDURE GetEmployeeWithRoleDetails
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get employee basic info
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.full_name,
        e.national_id,
        e.date_of_birth,
        e.country_of_birth,
        e.phone,
        e.email,
        e.address,
        e.emergency_contact_name,
        e.emergency_contact_phone,
        e.relationship,
        e.biography,
        e.profile_image,
        e.employment_progress,
        e.account_status,
        e.employment_status,
        e.hire_date,
        e.is_active,
        e.profile_completion,
        e.department_id,
        e.position_id,
        e.manager_id,
        e.contract_id,
        e.tax_form_id,
        e.salary_type_id,
        e.pay_grade,
        e.password_hash,
        e.is_locked,
        -- Get primary role
        (SELECT TOP 1 r.role_name 
         FROM Employee_Role er 
         JOIN Role r ON er.role_id = r.role_id 
         WHERE er.employee_id = e.employee_id 
         ORDER BY er.assigned_date ASC) AS role_name,
        d.department_name,
        p.position_title,
        m.full_name AS manager_name,
        -- HR Admin specific fields
        hr.approval_level,
        hr.record_access_scope,
        hr.document_validation_rights,
        -- System Admin specific fields
        sa.system_privilege_level,
        sa.configurable_fields,
        sa.audit_visibility_scope,
        -- Payroll Specialist specific fields
        ps.assigned_region,
        ps.processing_frequency,
        ps.last_processed_period,
        -- Line Manager specific fields
        lm.team_size,
        lm.supervised_departments,
        lm.approval_limit
    FROM Employee e
    LEFT JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Position p ON e.position_id = p.position_id
    LEFT JOIN Employee m ON e.manager_id = m.employee_id
    LEFT JOIN HRAdministrator hr ON e.employee_id = hr.employee_id
    LEFT JOIN SystemAdministrator sa ON e.employee_id = sa.employee_id
    LEFT JOIN PayrollSpecialist ps ON e.employee_id = ps.employee_id
    LEFT JOIN LineManager lm ON e.employee_id = lm.employee_id
    WHERE e.employee_id = @EmployeeID;
END
GO

-- =============================================
-- Procedure: UpdateEmployeeProfile
-- Description: Updates employee profile with permission check
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateEmployeeProfile')
    DROP PROCEDURE UpdateEmployeeProfile;
GO

CREATE PROCEDURE UpdateEmployeeProfile
    @EditorId INT,
    @EmployeeID INT,
    @FirstName VARCHAR(100) = NULL,
    @LastName VARCHAR(100) = NULL,
    @Email VARCHAR(255) = NULL,
    @Phone VARCHAR(30) = NULL,
    @NationalId VARCHAR(30) = NULL,
    @DateOfBirth DATE = NULL,
    @CountryOfBirth VARCHAR(100) = NULL,
    @Address VARCHAR(255) = NULL,
    @EmergencyContactName VARCHAR(100) = NULL,
    @EmergencyContactPhone VARCHAR(30) = NULL,
    @Relationship VARCHAR(50) = NULL,
    @Biography VARCHAR(1000) = NULL,
    @ProfileImage VARCHAR(255) = NULL,
    @DepartmentId INT = NULL,
    @PositionId INT = NULL,
    @ManagerId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check permission
        DECLARE @CanEdit BIT;
        EXEC CheckEditPermission @EditorId, @EmployeeID, @CanEdit OUTPUT;
        
        IF @CanEdit = 0
        BEGIN
            RAISERROR('You do not have permission to edit this employee profile', 16, 1);
            RETURN;
        END
        
        -- Update employee record
        UPDATE Employee
        SET 
            first_name = ISNULL(@FirstName, first_name),
            last_name = ISNULL(@LastName, last_name),
            email = ISNULL(@Email, email),
            phone = ISNULL(@Phone, phone),
            national_id = ISNULL(@NationalId, national_id),
            date_of_birth = ISNULL(@DateOfBirth, date_of_birth),
            country_of_birth = ISNULL(@CountryOfBirth, country_of_birth),
            address = ISNULL(@Address, address),
            emergency_contact_name = ISNULL(@EmergencyContactName, emergency_contact_name),
            emergency_contact_phone = ISNULL(@EmergencyContactPhone, emergency_contact_phone),
            relationship = ISNULL(@Relationship, relationship),
            biography = ISNULL(@Biography, biography),
            profile_image = ISNULL(@ProfileImage, profile_image),
            department_id = ISNULL(@DepartmentId, department_id),
            position_id = ISNULL(@PositionId, position_id),
            manager_id = ISNULL(@ManagerId, manager_id)
        WHERE employee_id = @EmployeeID;
        
        COMMIT TRANSACTION;
        PRINT 'Employee profile updated successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Procedure: UpdateRoleSpecificData
-- Description: Updates role-specific data (HR Admin only)
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateRoleSpecificData')
    DROP PROCEDURE UpdateRoleSpecificData;
GO

CREATE PROCEDURE UpdateRoleSpecificData
    @EditorId INT,
    @EmployeeID INT,
    @RoleName VARCHAR(50),
    -- HR Admin fields
    @ApprovalLevel VARCHAR(50) = NULL,
    @RecordAccessScope VARCHAR(100) = NULL,
    @DocumentValidationRights VARCHAR(100) = NULL,
    -- System Admin fields
    @SystemPrivilegeLevel VARCHAR(50) = NULL,
    @ConfigurableFields VARCHAR(200) = NULL,
    @AuditVisibilityScope VARCHAR(100) = NULL,
    -- Payroll Specialist fields
    @AssignedRegion VARCHAR(50) = NULL,
    @ProcessingFrequency VARCHAR(50) = NULL,
    -- Line Manager fields
    @TeamSize INT = NULL,
    @SupervisedDepartments VARCHAR(200) = NULL,
    @ApprovalLimit VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Only HR Admins can update role-specific data
        DECLARE @EditorRole VARCHAR(50);
        SELECT TOP 1 @EditorRole = r.role_name 
        FROM Employee_Role er 
        JOIN Role r ON er.role_id = r.role_id 
        WHERE er.employee_id = @EditorId;
        
        IF @EditorRole != 'HRAdministrator'
        BEGIN
            RAISERROR('Only HR Administrators can update role-specific data', 16, 1);
            RETURN;
        END
        
        -- Update based on role
        IF @RoleName = 'HRAdministrator'
        BEGIN
            IF EXISTS (SELECT 1 FROM HRAdministrator WHERE employee_id = @EmployeeID)
            BEGIN
                UPDATE HRAdministrator
                SET 
                    approval_level = ISNULL(@ApprovalLevel, approval_level),
                    record_access_scope = ISNULL(@RecordAccessScope, record_access_scope),
                    document_validation_rights = ISNULL(@DocumentValidationRights, document_validation_rights)
                WHERE employee_id = @EmployeeID;
            END
        END
        ELSE IF @RoleName = 'SystemAdministrator'
        BEGIN
            IF EXISTS (SELECT 1 FROM SystemAdministrator WHERE employee_id = @EmployeeID)
            BEGIN
                UPDATE SystemAdministrator
                SET 
                    system_privilege_level = ISNULL(@SystemPrivilegeLevel, system_privilege_level),
                    configurable_fields = ISNULL(@ConfigurableFields, configurable_fields),
                    audit_visibility_scope = ISNULL(@AuditVisibilityScope, audit_visibility_scope)
                WHERE employee_id = @EmployeeID;
            END
        END
        ELSE IF @RoleName = 'PayrollSpecialist'
        BEGIN
            IF EXISTS (SELECT 1 FROM PayrollSpecialist WHERE employee_id = @EmployeeID)
            BEGIN
                UPDATE PayrollSpecialist
                SET 
                    assigned_region = ISNULL(@AssignedRegion, assigned_region),
                    processing_frequency = ISNULL(@ProcessingFrequency, processing_frequency)
                WHERE employee_id = @EmployeeID;
            END
        END
        ELSE IF @RoleName = 'LineManager'
        BEGIN
            IF EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @EmployeeID)
            BEGIN
                UPDATE LineManager
                SET 
                    team_size = ISNULL(@TeamSize, team_size),
                    supervised_departments = ISNULL(@SupervisedDepartments, supervised_departments),
                    approval_limit = ISNULL(@ApprovalLimit, approval_limit)
                WHERE employee_id = @EmployeeID;
            END
        END
        
        COMMIT TRANSACTION;
        PRINT 'Role-specific data updated successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

GO
SELECT e.employee_id, e.email, e.first_name, r.role_name
FROM Employee e
JOIN Employee_Role er ON e.employee_id = er.employee_id
JOIN Role r ON er.role_id = r.role_id
WHERE e.email = 'admin@admin.com';
SELECT * FROM Role;

-- =============================================
-- Fix Stored Procedures to Match Your Role Names
-- =============================================
-- Your Role table has: SuperAdmin, HRAdmin, Manager, Employee
-- This script updates stored procedures to use YOUR role names
-- =============================================

PRINT 'Updating stored procedures to match your role names...';
GO

-- =============================================
-- Fix CheckEditPermission
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'CheckEditPermission')
    DROP PROCEDURE CheckEditPermission;
GO

CREATE PROCEDURE CheckEditPermission
    @EditorId INT,
    @TargetEmployeeId INT,
    @CanEdit BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @CanEdit = 0;
    
    -- Check editor role
    DECLARE @EditorRole VARCHAR(50);
    SELECT TOP 1 @EditorRole = r.role_name 
    FROM Employee_Role er 
    JOIN Role r ON er.role_id = r.role_id 
    WHERE er.employee_id = @EditorId
    ORDER BY er.assigned_date ASC;
    
    -- HR Admins and SuperAdmins can edit any profile
    IF @EditorRole IN ('HRAdmin', 'SuperAdmin')
    BEGIN
        SET @CanEdit = 1;
        RETURN;
    END
    
    -- Users can edit their own profile
    IF @EditorId = @TargetEmployeeId
    BEGIN
        SET @CanEdit = 1;
        RETURN;
    END
    
    -- Otherwise, no permission
    SET @CanEdit = 0;
END
GO

-- =============================================
-- Fix CreateAdminAccount
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'CreateAdminAccount')
    DROP PROCEDURE CreateAdminAccount;
GO

CREATE PROCEDURE CreateAdminAccount
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Email VARCHAR(255),
    @Password VARCHAR(100),
    @RoleId INT,
    @Phone VARCHAR(30) = NULL,
    @NationalId VARCHAR(30) = NULL,
    @NewEmployeeID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate role is admin type
        DECLARE @RoleName VARCHAR(50);
        SELECT @RoleName = role_name FROM Role WHERE role_id = @RoleId;
        
        -- Allow SuperAdmin, HRAdmin, Manager to self-register
        IF @RoleName NOT IN ('SuperAdmin', 'HRAdmin', 'Manager')
        BEGIN
            RAISERROR('Only admin roles can self-register (SuperAdmin, HRAdmin, Manager)', 16, 1);
            RETURN;
        END
        
        -- Check if email already exists
        IF EXISTS (SELECT 1 FROM Employee WHERE email = @Email)
        BEGIN
            RAISERROR('Email already exists', 16, 1);
            RETURN;
        END
        
        -- Insert into Employee table
        INSERT INTO Employee (
            first_name, last_name, email, phone, national_id,
            password_hash, is_active, profile_completion, hire_date,
            department_id, position_id, contract_id, tax_form_id, salary_type_id
        )
        VALUES (
            @FirstName, @LastName, @Email, @Phone, @NationalId,
            @Password, 1, 30, GETDATE(),
            NULL, NULL, NULL, NULL, NULL
        );
        
        SET @NewEmployeeID = SCOPE_IDENTITY();
        
        -- Assign role
        INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
        VALUES (@NewEmployeeID, @RoleId, GETDATE());
        
        -- Insert into role-specific subclass table
        IF @RoleName = 'HRAdmin' AND EXISTS (SELECT * FROM sys.tables WHERE name = 'HRAdministrator')
        BEGIN
            INSERT INTO HRAdministrator (employee_id, approval_level, record_access_scope, document_validation_rights)
            VALUES (@NewEmployeeID, NULL, NULL, NULL);
        END
        ELSE IF @RoleName = 'SuperAdmin' AND EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemAdministrator')
        BEGIN
            INSERT INTO SystemAdministrator (employee_id, system_privilege_level, configurable_fields, audit_visibility_scope)
            VALUES (@NewEmployeeID, NULL, NULL, NULL);
        END
        ELSE IF @RoleName = 'Manager' AND EXISTS (SELECT * FROM sys.tables WHERE name = 'LineManager')
        BEGIN
            INSERT INTO LineManager (employee_id, team_size, supervised_departments, approval_limit)
            VALUES (@NewEmployeeID, NULL, NULL, NULL);
        END
        
        COMMIT TRANSACTION;
        PRINT 'Admin account created successfully with ID: ' + CAST(@NewEmployeeID AS VARCHAR);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Fix CreateEmployeeByAdmin
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'CreateEmployeeByAdmin')
    DROP PROCEDURE CreateEmployeeByAdmin;
GO

CREATE PROCEDURE CreateEmployeeByAdmin
    @CreatorId INT,
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Email VARCHAR(255),
    @Password VARCHAR(100),
    @RoleId INT,
    @Phone VARCHAR(30) = NULL,
    @NationalId VARCHAR(30) = NULL,
    @DateOfBirth DATE = NULL,
    @CountryOfBirth VARCHAR(100) = NULL,
    @Address VARCHAR(255) = NULL,
    @DepartmentId INT = NULL,
    @PositionId INT = NULL,
    @ManagerId INT = NULL,
    @NewEmployeeID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verify creator has permission
        DECLARE @CreatorRole VARCHAR(50);
        SELECT TOP 1 @CreatorRole = r.role_name 
        FROM Employee_Role er 
        JOIN Role r ON er.role_id = r.role_id 
        WHERE er.employee_id = @CreatorId;
        
        -- SuperAdmin, HRAdmin, or Manager can create employees
        IF @CreatorRole NOT IN ('SuperAdmin', 'HRAdmin', 'Manager')
        BEGIN
            RAISERROR('You do not have permission to create employee accounts', 16, 1);
            RETURN;
        END
        
        -- Check if email already exists
        IF EXISTS (SELECT 1 FROM Employee WHERE email = @Email)
        BEGIN
            RAISERROR('Email already exists', 16, 1);
            RETURN;
        END
        
        -- Get role name for new employee
        DECLARE @RoleName VARCHAR(50);
        SELECT @RoleName = role_name FROM Role WHERE role_id = @RoleId;
        
        -- Insert into Employee table
        INSERT INTO Employee (
            first_name, last_name, email, phone, national_id,
            date_of_birth, country_of_birth, address,
            password_hash, is_active, profile_completion, hire_date,
            department_id, position_id, manager_id,
            contract_id, tax_form_id, salary_type_id
        )
        VALUES (
            @FirstName, @LastName, @Email, @Phone, @NationalId,
            @DateOfBirth, @CountryOfBirth, @Address,
            @Password, 1, 40, GETDATE(),
            @DepartmentId, @PositionId, @ManagerId,
            NULL, NULL, NULL
        );
        
        SET @NewEmployeeID = SCOPE_IDENTITY();
        
        -- Assign role
        INSERT INTO Employee_Role (employee_id, role_id, assigned_date)
        VALUES (@NewEmployeeID, @RoleId, GETDATE());
        
        -- Insert into role-specific subclass table
        IF @RoleName = 'HRAdmin' AND EXISTS (SELECT * FROM sys.tables WHERE name = 'HRAdministrator')
        BEGIN
            INSERT INTO HRAdministrator (employee_id, approval_level, record_access_scope, document_validation_rights)
            VALUES (@NewEmployeeID, NULL, NULL, NULL);
        END
        ELSE IF @RoleName = 'SuperAdmin' AND EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemAdministrator')
        BEGIN
            INSERT INTO SystemAdministrator (employee_id, system_privilege_level, configurable_fields, audit_visibility_scope)
            VALUES (@NewEmployeeID, NULL, NULL, NULL);
        END
        ELSE IF @RoleName = 'Manager' AND EXISTS (SELECT * FROM sys.tables WHERE name = 'LineManager')
        BEGIN
            INSERT INTO LineManager (employee_id, team_size, supervised_departments, approval_limit)
            VALUES (@NewEmployeeID, NULL, NULL, NULL);
        END
        -- Employee role doesn't need subclass table
        
        COMMIT TRANSACTION;
        PRINT 'Employee account created successfully with ID: ' + CAST(@NewEmployeeID AS VARCHAR);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- =============================================
-- Fix UpdateRoleSpecificData
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateRoleSpecificData')
    DROP PROCEDURE UpdateRoleSpecificData;
GO

CREATE PROCEDURE UpdateRoleSpecificData
    @EditorId INT,
    @EmployeeID INT,
    @RoleName VARCHAR(50),
    @ApprovalLevel VARCHAR(50) = NULL,
    @RecordAccessScope VARCHAR(100) = NULL,
    @DocumentValidationRights VARCHAR(100) = NULL,
    @SystemPrivilegeLevel VARCHAR(50) = NULL,
    @ConfigurableFields VARCHAR(200) = NULL,
    @AuditVisibilityScope VARCHAR(100) = NULL,
    @TeamSize INT = NULL,
    @SupervisedDepartments VARCHAR(200) = NULL,
    @ApprovalLimit VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Only HRAdmin can update role-specific data
        DECLARE @EditorRole VARCHAR(50);
        SELECT TOP 1 @EditorRole = r.role_name 
        FROM Employee_Role er 
        JOIN Role r ON er.role_id = r.role_id 
        WHERE er.employee_id = @EditorId;
        
        IF @EditorRole NOT IN ('HRAdmin', 'SuperAdmin')
        BEGIN
            RAISERROR('Only HR Admins and SuperAdmins can update role-specific data', 16, 1);
            RETURN;
        END
        
        -- Update based on role
        IF @RoleName = 'HRAdmin'
        BEGIN
            IF EXISTS (SELECT 1 FROM HRAdministrator WHERE employee_id = @EmployeeID)
            BEGIN
                UPDATE HRAdministrator
                SET 
                    approval_level = ISNULL(@ApprovalLevel, approval_level),
                    record_access_scope = ISNULL(@RecordAccessScope, record_access_scope),
                    document_validation_rights = ISNULL(@DocumentValidationRights, document_validation_rights)
                WHERE employee_id = @EmployeeID;
            END
        END
        ELSE IF @RoleName = 'SuperAdmin'
        BEGIN
            IF EXISTS (SELECT 1 FROM SystemAdministrator WHERE employee_id = @EmployeeID)
            BEGIN
                UPDATE SystemAdministrator
                SET 
                    system_privilege_level = ISNULL(@SystemPrivilegeLevel, system_privilege_level),
                    configurable_fields = ISNULL(@ConfigurableFields, configurable_fields),
                    audit_visibility_scope = ISNULL(@AuditVisibilityScope, audit_visibility_scope)
                WHERE employee_id = @EmployeeID;
            END
        END
        ELSE IF @RoleName = 'Manager'
        BEGIN
            IF EXISTS (SELECT 1 FROM LineManager WHERE employee_id = @EmployeeID)
            BEGIN
                UPDATE LineManager
                SET 
                    team_size = ISNULL(@TeamSize, team_size),
                    supervised_departments = ISNULL(@SupervisedDepartments, supervised_departments),
                    approval_limit = ISNULL(@ApprovalLimit, approval_limit)
                WHERE employee_id = @EmployeeID;
            END
        END
        
        COMMIT TRANSACTION;
        PRINT 'Role-specific data updated successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

PRINT '';
PRINT '=============================================';
PRINT 'Stored Procedures Updated Successfully!';
PRINT '=============================================';
PRINT 'Now using YOUR role names:';
PRINT '  - SuperAdmin (All Access)';
PRINT '  - HRAdmin (HR Access)';
PRINT '  - Manager (Approval)';
PRINT '  - Employee (Self Service)';
PRINT '';
PRINT 'IMPORTANT: Log out and log back in for changes to take effect!';
PRINT '=============================================';
GO
CREATE PROCEDURE SetEmployeePassword
    @EmployeeId INT,
    @PasswordHash NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the password hash for the employee
    UPDATE Employee
    SET password_hash = @PasswordHash,
        is_active = 1  -- Ensure account is active
    WHERE employee_id = @EmployeeId;

    -- Return success
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetEmployeeRoles')
    DROP PROCEDURE GetEmployeeRoles
GO

CREATE PROCEDURE GetEmployeeRoles
    @EmployeeId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get all roles for this employee from the junction table
    SELECT 
        r.role_id,
        r.role_name,
        r.purpose
    FROM Employee_Role er
    INNER JOIN Role r ON er.role_id = r.role_id
    WHERE er.employee_id = @EmployeeId
    ORDER BY r.role_name;
END
GO
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'UpdateEmployeeAdminControls')
    DROP PROCEDURE UpdateEmployeeAdminControls
GO

CREATE PROCEDURE UpdateEmployeeAdminControls
    @EmployeeID INT,
    @ProfileCompletion INT = NULL,
    @IsActive BIT = NULL,
    @EmploymentStatus NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Employee
    SET 
        profile_completion = COALESCE(@ProfileCompletion, profile_completion),
        is_active = COALESCE(@IsActive, is_active),
        employment_status = COALESCE(@EmploymentStatus, employment_status)
    WHERE employee_id = @EmployeeID;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'ViewEmployeeInfo')
    DROP PROCEDURE ViewEmployeeInfo
GO

CREATE PROCEDURE ViewEmployeeInfo
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.first_name + ' ' + e.last_name AS full_name,
        e.national_id,
        e.date_of_birth,
        e.country_of_birth,
        e.phone,
        e.email,
        e.address,
        e.emergency_contact_name,
        e.emergency_contact_phone,
        e.relationship,
        e.biography,
        e.profile_image,
        e.employment_progress,
        e.account_status,
        e.employment_status,
        e.hire_date,
        e.is_active,
        e.profile_completion,  -- IMPORTANT: Make sure this is included!
        e.is_locked,
        e.password_hash,
        e.password_salt,
        e.last_login,
        e.department_id,
        e.position_id,
        e.manager_id,
        e.contract_id,
        d.department_name,
        p.position_title,
        m.first_name + ' ' + m.last_name AS manager_name,
        r.role_name
    FROM Employee e
    LEFT JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Position p ON e.position_id = p.position_id
    LEFT JOIN Employee m ON e.manager_id = m.employee_id
    LEFT JOIN Employee_Role er ON e.employee_id = er.employee_id
    LEFT JOIN Role r ON er.role_id = r.role_id
    WHERE e.employee_id = @EmployeeID
END
GO

GO

-- =============================================
-- PROCEDURE: ConfigureSplitShift
-- =============================================
CREATE PROCEDURE ConfigureSplitShift
    @ShiftName NVARCHAR(50),
    @FirstSlotStart TIME,
    @FirstSlotEnd TIME,
    @SecondSlotStart TIME,
    @SecondSlotEnd TIME
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calculate break duration in hours (decimal)
    DECLARE @BreakDuration DECIMAL(20, 2);
    SET @BreakDuration = DATEDIFF(MINUTE, @FirstSlotEnd, @SecondSlotStart) / 60.0;

    INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_start_time, break_duration, status)
    VALUES (@ShiftName, 'Split', @FirstSlotStart, @SecondSlotEnd, @FirstSlotEnd, @BreakDuration, 1);
END
GO

-- =============================================
-- PROCEDURE: AssignShiftToDepartment
-- =============================================
CREATE PROCEDURE AssignShiftToDepartment
    @DepartmentID INT,
    @ShiftID INT,
    @StartDate DATE,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Deactivate current active assignments for these employees
    UPDATE ShiftAssignment
    SET status = 'Inactive', end_date = DATEADD(day, -1, @StartDate)
    WHERE employee_id IN (SELECT employee_id FROM Employee WHERE department_id = @DepartmentID)
      AND status = 'Active';

    -- Insert new assignments
    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    SELECT employee_id, @ShiftID, @StartDate, @EndDate, 'Active'
    FROM Employee
    WHERE department_id = @DepartmentID;
END
GO

-- =============================================
-- PROCEDURE: AssignShiftToEmployee
-- =============================================
CREATE PROCEDURE AssignShiftToEmployee
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

-- =============================================
-- PROCEDURE: AssignCustomShift
-- =============================================
CREATE PROCEDURE AssignCustomShift
    @EmployeeID INT,
    @ShiftName NVARCHAR(50),
    @ShiftType NVARCHAR(50),
    @StartTime TIME,
    @EndTime TIME,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create the Custom Shift first
    DECLARE @ShiftID INT;
    
    INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, status)
    VALUES (@ShiftName + ' (Custom)', 'Custom', @StartTime, @EndTime, 0, 1);
    
    SET @ShiftID = SCOPE_IDENTITY();

    -- Assign to Employee
    EXEC AssignShiftToEmployee @EmployeeID, @ShiftID, @StartDate, @EndDate;
END
GO

-- =============================================
-- PROCEDURE: AssignRotationalShift
-- =============================================
CREATE PROCEDURE AssignRotationalShift
    @EmployeeID INT,
    @ShiftCycle INT, -- Assume this maps to a cycle_id or logic
    @StartDate DATE,
    @EndDate DATE,
    @Status NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- For MVP, we might assign a generic 'Rotational' shift wrapper
    -- Check if a generic Rotational shift exists, if not create one
    DECLARE @ShiftID INT;
    SELECT TOP 1 @ShiftID = shift_id FROM ShiftSchedule WHERE type = 'Rotational';
    
    IF @ShiftID IS NULL
    BEGIN
        INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, status)
        VALUES ('Rotational Shift', 'Rotational', '00:00', '00:00', 0, 1);
        SET @ShiftID = SCOPE_IDENTITY();
    END

    -- Assign it
    EXEC AssignShiftToEmployee @EmployeeID, @ShiftID, @StartDate, @EndDate;
    
    -- NOTE: The actual rotation logic (which shift on which day) 
    -- must be handled by the application service layer or a daily job.
END
GO

