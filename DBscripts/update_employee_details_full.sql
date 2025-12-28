USE HRFINAL;
GO

CREATE OR ALTER PROCEDURE UpdateEmployeeDetailsFull
    @EditorId INT,
    @EmployeeID INT,
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @NationalId VARCHAR(20),
    @DateOfBirth DATE,
    @CountryOfBirth VARCHAR(50),
    @Phone VARCHAR(20),
    @Email VARCHAR(100),
    @Address VARCHAR(255),
    @EmergencyContactName VARCHAR(100),
    @EmergencyContactPhone VARCHAR(20),
    @Relationship VARCHAR(50),
    @Biography VARCHAR(MAX),
    @ProfileImage VARCHAR(255),
    @DepartmentID INT,
    @PositionID INT,
    @ManagerID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
    BEGIN
        RAISERROR('Employee not found', 16, 1);
        RETURN;
    END

    UPDATE Employee
    SET 
        first_name = @FirstName,
        last_name = @LastName,
        national_id = @NationalId,
        date_of_birth = @DateOfBirth,
        country_of_birth = @CountryOfBirth,
        phone = @Phone,
        email = @Email,
        address = @Address,
        emergency_contact_name = @EmergencyContactName,
        emergency_contact_phone = @EmergencyContactPhone,
        relationship = @Relationship,
        biography = @Biography,
        profile_image = @ProfileImage,
        department_id = @DepartmentID,
        position_id = @PositionID,
        manager_id = @ManagerID
    WHERE employee_id = @EmployeeID;

END
GO
