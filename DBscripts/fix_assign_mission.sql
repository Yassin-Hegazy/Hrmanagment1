USE HRFINAL;
GO

-- Fix AssignMission to set status to 'Pending' so managers can approve/reject
CREATE OR ALTER PROCEDURE AssignMission
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
        RAISERROR('End date cannot be before start date', 16, 1);
        RETURN;
    END
    
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
        'Pending',  -- Changed from 'Assigned' to 'Pending' so managers can approve
        @EmployeeID, 
        @ManagerID
    );
END
GO
