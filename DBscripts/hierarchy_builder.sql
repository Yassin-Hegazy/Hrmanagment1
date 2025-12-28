USE HRFINAL;
GO

-- =============================================
-- Procedure: BuildEmployeeHierarchy
-- Description: Rebuilds the EmployeeHierarchy table
--              Each employee gets ONE row with their direct manager
--              and their absolute hierarchy level (0=CEO, 1=C-Suite, etc.)
-- =============================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'BuildEmployeeHierarchy')
    DROP PROCEDURE BuildEmployeeHierarchy;
GO

CREATE PROCEDURE BuildEmployeeHierarchy
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Clear existing table
    DELETE FROM EmployeeHierarchy;

    -- 2. Recursive CTE to calculate Absolute Levels
    ;WITH HierarchyCTE AS (
        -- Anchor: Root employees (CEO - no manager)
        SELECT 
            employee_id,
            manager_id,
            0 AS hierarchy_level  -- Level 0 = CEO
        FROM Employee
        WHERE manager_id IS NULL
          AND is_active = 1

        UNION ALL

        -- Recursive: Employees who report to someone
        SELECT 
            e.employee_id,
            e.manager_id,
            h.hierarchy_level + 1  -- Increment level
        FROM Employee e
        INNER JOIN HierarchyCTE h ON e.manager_id = h.employee_id
        WHERE e.is_active = 1
    )
    
    -- 3. Insert ONE row per employee with their direct manager
    INSERT INTO EmployeeHierarchy (employee_id, manager_id, hierarchy_level)
    SELECT 
        employee_id,
        ISNULL(manager_id, employee_id),  -- Self-reference for CEO (to satisfy PK)
        hierarchy_level
    FROM HierarchyCTE;

    -- 4. Report results
    DECLARE @Count INT = (SELECT COUNT(*) FROM EmployeeHierarchy);
    PRINT 'EmployeeHierarchy rebuilt. Total rows: ' + CAST(@Count AS VARCHAR);
    
    -- Show level distribution
    SELECT 
        hierarchy_level AS [Level],
        CASE hierarchy_level
            WHEN 0 THEN 'CEO'
            WHEN 1 THEN 'C-Suite'
            WHEN 2 THEN 'Manager'
            WHEN 3 THEN 'Senior'
            WHEN 4 THEN 'Mid-Level'
            WHEN 5 THEN 'Junior'
            WHEN 6 THEN 'Intern'
            ELSE 'Other'
        END AS LevelName,
        COUNT(*) AS EmployeeCount
    FROM EmployeeHierarchy
    GROUP BY hierarchy_level
    ORDER BY hierarchy_level;
END
GO

PRINT 'BuildEmployeeHierarchy procedure created successfully!';
GO
