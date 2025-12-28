-- =============================================
-- ANALYTICS STORED PROCEDURES
-- For HR Management System Analytics Module
-- =============================================

USE HRFINAL;
GO

-- =============================================
-- PROCEDURE: sp_GetAnalyticsDashboard
-- Purpose: Get all KPI data for dashboard
-- =============================================
IF OBJECT_ID('sp_GetAnalyticsDashboard', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetAnalyticsDashboard;
GO

CREATE PROCEDURE sp_GetAnalyticsDashboard
AS
BEGIN
    SELECT 
        -- Total Employees (active)
        (SELECT COUNT(*) FROM Employee WHERE is_active = 1) AS TotalEmployees,
        
        -- Total Departments
        (SELECT COUNT(*) FROM Department) AS TotalDepartments,
        
        -- Active Contracts (end date >= today AND state = Active)
        (SELECT COUNT(*) FROM Contract 
         WHERE contract_current_state = 'Active' 
           AND (contract_end_date IS NULL OR contract_end_date >= GETDATE())) AS ActiveContracts,
        
        -- New Hires This Month (hire_date within current month)
        (SELECT COUNT(*) FROM Employee 
         WHERE MONTH(hire_date) = MONTH(GETDATE()) 
           AND YEAR(hire_date) = YEAR(GETDATE())) AS NewHiresThisMonth,
        
        -- Pending Leave Requests
        (SELECT COUNT(*) FROM LeaveRequest WHERE status = 'Pending') AS PendingLeaveRequests,
        
        -- Active Missions (PendingApproval status)
        (SELECT COUNT(*) FROM Mission WHERE status = 'PendingApproval') AS ActiveMissions,
        
        -- Expiring Contracts (within next 30 days)
        (SELECT COUNT(*) FROM Contract 
         WHERE contract_end_date BETWEEN GETDATE() AND DATEADD(day, 30, GETDATE())
           AND contract_current_state = 'Active') AS ExpiringContracts;
END
GO

-- =============================================
-- PROCEDURE: sp_GetDepartmentOverview
-- Purpose: Get department overview for dashboard table
-- =============================================
IF OBJECT_ID('sp_GetDepartmentOverview', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetDepartmentOverview;
GO

CREATE PROCEDURE sp_GetDepartmentOverview
AS
BEGIN
    SELECT 
        d.department_id AS DepartmentId,
        d.department_name AS DepartmentName,
        COUNT(e.employee_id) AS TotalEmployees,
        SUM(CASE WHEN e.is_active = 1 THEN 1 ELSE 0 END) AS ActiveEmployees
    FROM Department d
    LEFT JOIN Employee e ON d.department_id = e.department_id
    GROUP BY d.department_id, d.department_name
    ORDER BY d.department_name;
END
GO

-- =============================================
-- PROCEDURE: sp_SearchDepartmentStats
-- Purpose: Search departments by name with stats
-- =============================================
IF OBJECT_ID('sp_SearchDepartmentStats', 'P') IS NOT NULL
    DROP PROCEDURE sp_SearchDepartmentStats;
GO

CREATE PROCEDURE sp_SearchDepartmentStats
    @SearchTerm VARCHAR(100) = NULL
AS
BEGIN
    SELECT 
        d.department_id AS DepartmentId,
        d.department_name AS DepartmentName,
        COUNT(e.employee_id) AS TotalEmployees,
        SUM(CASE WHEN e.is_active = 1 THEN 1 ELSE 0 END) AS ActiveEmployees,
        SUM(CASE WHEN e.is_active = 0 THEN 1 ELSE 0 END) AS InactiveEmployees,
        -- Age Distribution based on date_of_birth
        SUM(CASE WHEN DATEDIFF(year, e.date_of_birth, GETDATE()) < 25 THEN 1 ELSE 0 END) AS Under25,
        SUM(CASE WHEN DATEDIFF(year, e.date_of_birth, GETDATE()) BETWEEN 25 AND 34 THEN 1 ELSE 0 END) AS Age25to34,
        SUM(CASE WHEN DATEDIFF(year, e.date_of_birth, GETDATE()) BETWEEN 35 AND 44 THEN 1 ELSE 0 END) AS Age35to44,
        SUM(CASE WHEN DATEDIFF(year, e.date_of_birth, GETDATE()) BETWEEN 45 AND 54 THEN 1 ELSE 0 END) AS Age45to54,
        SUM(CASE WHEN DATEDIFF(year, e.date_of_birth, GETDATE()) >= 55 THEN 1 ELSE 0 END) AS Over55
    FROM Department d
    LEFT JOIN Employee e ON d.department_id = e.department_id
    WHERE @SearchTerm IS NULL 
       OR d.department_name LIKE '%' + @SearchTerm + '%'
    GROUP BY d.department_id, d.department_name
    ORDER BY d.department_name;
END
GO

-- =============================================
-- PROCEDURE: sp_GetContractsComplianceReport
-- Purpose: Get expired and expiring contracts
-- =============================================
IF OBJECT_ID('sp_GetContractsComplianceReport', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetContractsComplianceReport;
GO

CREATE PROCEDURE sp_GetContractsComplianceReport
    @DepartmentId INT = NULL,
    @DaysThreshold INT = 30
AS
BEGIN
    SELECT 
        e.employee_id AS EmployeeId,
        e.full_name AS EmployeeName,
        d.department_name AS DepartmentName,
        c.contract_end_date AS ContractEndDate,
        DATEDIFF(day, GETDATE(), c.contract_end_date) AS DaysRemaining,
        CASE 
            WHEN c.contract_end_date < GETDATE() THEN 'Expired'
            ELSE 'Expiring'
        END AS Status
    FROM Employee e
    INNER JOIN Contract c ON e.contract_id = c.contract_id
    INNER JOIN Department d ON e.department_id = d.department_id
    WHERE (c.contract_end_date <= DATEADD(day, @DaysThreshold, GETDATE())
           OR c.contract_end_date < GETDATE())
      AND (@DepartmentId IS NULL OR e.department_id = @DepartmentId)
    ORDER BY c.contract_end_date ASC;
END
GO

-- =============================================
-- PROCEDURE: sp_GetAttendanceComplianceReport
-- Purpose: Get late count and short-time per employee
-- =============================================
IF OBJECT_ID('sp_GetAttendanceComplianceReport', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetAttendanceComplianceReport;
GO

CREATE PROCEDURE sp_GetAttendanceComplianceReport
    @DepartmentId INT = NULL,
    @DateFrom DATE,
    @DateTo DATE
AS
BEGIN
    SELECT 
        e.employee_id AS EmployeeId,
        e.full_name AS EmployeeName,
        d.department_name AS DepartmentName,
        -- Late count: entry_time > shift start_time
        SUM(CASE 
            WHEN a.entry_time IS NOT NULL 
             AND s.start_time IS NOT NULL 
             AND CAST(a.entry_time AS TIME) > DATEADD(minute, 10, CAST(s.start_time AS TIME))
            THEN 1 ELSE 0 
        END) AS LateCount,
        -- Short time: duration < expected hours (assuming 8 hours standard)
        SUM(CASE 
            WHEN a.duration IS NOT NULL AND a.duration < 7.5 
            THEN 1 ELSE 0 
        END) AS ShortTimeCount,
        -- Total attendance days
        COUNT(a.attendance_id) AS TotalDays,
        -- Compliance flag
        CASE 
            WHEN SUM(CASE WHEN a.entry_time IS NOT NULL AND s.start_time IS NOT NULL 
                          AND CAST(a.entry_time AS TIME) > DATEADD(minute, 10, CAST(s.start_time AS TIME))
                     THEN 1 ELSE 0 END) > 3 
              OR SUM(CASE WHEN a.duration IS NOT NULL AND a.duration < 7.5 THEN 1 ELSE 0 END) > 3
            THEN 'Attention'
            ELSE 'OK'
        END AS ComplianceFlag
    FROM Employee e
    INNER JOIN Department d ON e.department_id = d.department_id
    LEFT JOIN Attendance a ON e.employee_id = a.employee_id
        AND CAST(a.entry_time AS DATE) BETWEEN @DateFrom AND @DateTo
    LEFT JOIN ShiftSchedule s ON a.shift_id = s.shift_id
    WHERE (@DepartmentId IS NULL OR e.department_id = @DepartmentId)
      AND e.is_active = 1
    GROUP BY e.employee_id, e.full_name, d.department_name
    ORDER BY e.full_name;
END
GO

-- =============================================
-- PROCEDURE: sp_GetGenderDistributionByDepartment
-- Purpose: Get gender counts per department
-- =============================================
IF OBJECT_ID('sp_GetGenderDistributionByDepartment', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetGenderDistributionByDepartment;
GO

CREATE PROCEDURE sp_GetGenderDistributionByDepartment
AS
BEGIN
    SELECT 
        d.department_name AS DepartmentName,
        SUM(CASE WHEN e.gender = 'Male' THEN 1 ELSE 0 END) AS MaleCount,
        SUM(CASE WHEN e.gender = 'Female' THEN 1 ELSE 0 END) AS FemaleCount,
        SUM(CASE WHEN e.gender IS NULL OR e.gender NOT IN ('Male', 'Female') THEN 1 ELSE 0 END) AS OtherCount,
        COUNT(e.employee_id) AS Total,
        CASE WHEN COUNT(e.employee_id) > 0 
            THEN ROUND(CAST(SUM(CASE WHEN e.gender = 'Male' THEN 1 ELSE 0 END) AS DECIMAL) / COUNT(e.employee_id) * 100, 1)
            ELSE 0 
        END AS MalePercent,
        CASE WHEN COUNT(e.employee_id) > 0 
            THEN ROUND(CAST(SUM(CASE WHEN e.gender = 'Female' THEN 1 ELSE 0 END) AS DECIMAL) / COUNT(e.employee_id) * 100, 1)
            ELSE 0 
        END AS FemalePercent
    FROM Department d
    LEFT JOIN Employee e ON d.department_id = e.department_id AND e.is_active = 1
    GROUP BY d.department_id, d.department_name
    ORDER BY d.department_name;
END
GO

-- =============================================
-- PROCEDURE: sp_GetEmploymentTypeDistribution
-- Purpose: Get contract type distribution per department
-- =============================================
IF OBJECT_ID('sp_GetEmploymentTypeDistribution', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetEmploymentTypeDistribution;
GO

CREATE PROCEDURE sp_GetEmploymentTypeDistribution
AS
BEGIN
    ;WITH DeptTotals AS (
        SELECT 
            d.department_id,
            d.department_name,
            COUNT(e.employee_id) AS DeptTotal
        FROM Department d
        LEFT JOIN Employee e ON d.department_id = e.department_id AND e.is_active = 1
        GROUP BY d.department_id, d.department_name
    )
    SELECT 
        d.department_name AS DepartmentName,
        c.contract_type AS ContractType,
        COUNT(e.employee_id) AS [Count],
        CASE WHEN dt.DeptTotal > 0 
            THEN ROUND(CAST(COUNT(e.employee_id) AS DECIMAL) / dt.DeptTotal * 100, 1)
            ELSE 0 
        END AS [Percent]
    FROM Department d
    LEFT JOIN Employee e ON d.department_id = e.department_id AND e.is_active = 1
    LEFT JOIN Contract c ON e.contract_id = c.contract_id
    INNER JOIN DeptTotals dt ON d.department_id = dt.department_id
    WHERE c.contract_type IS NOT NULL
    GROUP BY d.department_id, d.department_name, c.contract_type, dt.DeptTotal
    ORDER BY d.department_name, c.contract_type;
END
GO

PRINT '=============================================';
PRINT 'All Analytics Stored Procedures Created!';
PRINT '=============================================';
GO
