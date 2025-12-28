USE HRFINAL;
GO

-- =============================================
-- Procedure: GetAllPositions
-- Description: Returns all positions
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'GetAllPositions')
    DROP PROCEDURE GetAllPositions;
GO

CREATE PROCEDURE GetAllPositions
AS
BEGIN
    SELECT position_id, position_title, responsibilities, status
    FROM Position
    ORDER BY position_title;
END
GO

-- =============================================
-- Procedure: AddPosition
-- Description: Adds a new position and returns its ID
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'AddPosition')
    DROP PROCEDURE AddPosition;
GO

CREATE PROCEDURE AddPosition
    @PositionTitle VARCHAR(150),
    @Responsibilities VARCHAR(1000) = NULL,
    @Status VARCHAR(50) = 'Active'
AS
BEGIN
    INSERT INTO Position (position_title, responsibilities, status)
    VALUES (@PositionTitle, @Responsibilities, @Status);
    
    SELECT CAST(SCOPE_IDENTITY() AS INT);
END
GO
