namespace HRMANGMANGMENT.Models
{
    // Department Statistics
    public class DepartmentStatistics
    {
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; } = "";
        public int TotalEmployees { get; set; }
        public int ActiveEmployees { get; set; }
        public int OnLeave { get; set; }
        public int OnMission { get; set; }
        public decimal AverageAttendanceRate { get; set; }
        public int ContractsExpiringThisMonth { get; set; }
        
        // Gender breakdown
        public int MaleCount { get; set; }
        public int FemaleCount { get; set; }
        
        // Age distribution
        public int Under25 { get; set; }
        public int Age25to34 { get; set; }
        public int Age35to44 { get; set; }
        public int Age45to54 { get; set; }
        public int Over55 { get; set; }
    }

    // Compliance Report
    public class ComplianceReport
    {
        public DateTime ReportDate { get; set; } = DateTime.Now;
        public int TotalEmployees { get; set; }
        public int ActiveContracts { get; set; }
        public int ExpiredContracts { get; set; }
        public int ExpiringIn30Days { get; set; }
        public int MissingDocuments { get; set; }
        public int PendingLeaveRequests { get; set; }
        public int PendingMissionApprovals { get; set; }
        public decimal OverallAttendanceRate { get; set; }
        public int LateArrivals { get; set; }
        public int AbsentEmployees { get; set; }
        
        public List<ComplianceIssue> Issues { get; set; } = new();
    }

    public class ComplianceIssue
    {
        public string Category { get; set; } = "";
        public string Description { get; set; } = "";
        public string Severity { get; set; } = "Low"; // Low, Medium, High
        public int EmployeeId { get; set; }
        public string EmployeeName { get; set; } = "";
        public string SeverityBadgeClass => Severity switch
        {
            "High" => "bg-danger",
            "Medium" => "bg-warning",
            _ => "bg-info"
        };
    }

    // Diversity Report
    public class DiversityReport
    {
        public DateTime ReportDate { get; set; } = DateTime.Now;
        public int TotalEmployees { get; set; }
        
        // Gender Distribution
        public int MaleCount { get; set; }
        public int FemaleCount { get; set; }
        public int OtherGenderCount { get; set; }
        public decimal MalePercentage => TotalEmployees > 0 ? Math.Round((decimal)MaleCount / TotalEmployees * 100, 1) : 0;
        public decimal FemalePercentage => TotalEmployees > 0 ? Math.Round((decimal)FemaleCount / TotalEmployees * 100, 1) : 0;
        
        // Age Distribution
        public int Under25 { get; set; }
        public int Age25to34 { get; set; }
        public int Age35to44 { get; set; }
        public int Age45to54 { get; set; }
        public int Over55 { get; set; }
        
        // Department Distribution
        public List<DepartmentBreakdown> DepartmentBreakdowns { get; set; } = new();
        
        // Position Level Distribution
        public int EntryLevel { get; set; }
        public int MidLevel { get; set; }
        public int SeniorLevel { get; set; }
        public int ManagementLevel { get; set; }
        
        // Contract Type Distribution
        public int PermanentContracts { get; set; }
        public int TemporaryContracts { get; set; }
        public int ContractorContracts { get; set; }
    }

    public class DepartmentBreakdown
    {
        public string DepartmentName { get; set; } = "";
        public int EmployeeCount { get; set; }
        public decimal Percentage { get; set; }
        public int MaleCount { get; set; }
        public int FemaleCount { get; set; }
    }

    // Overall Analytics Dashboard
    public class AnalyticsDashboard
    {
        public int TotalEmployees { get; set; }
        public int TotalDepartments { get; set; }
        public int ActiveContracts { get; set; }
        public decimal AttendanceRate { get; set; }
        public int PendingLeaveRequests { get; set; }
        public int ActiveMissions { get; set; }
        public int ContractsExpiringThisMonth { get; set; }
        public int NewHiresThisMonth { get; set; }
        
        public List<DepartmentStatistics> DepartmentStats { get; set; } = new();
    }

    // ====================================================================
    // NEW DTOs FOR COMPLIANCE AND DIVERSITY REPORTS
    // ====================================================================

    // Contracts Compliance Report Row
    public class ContractComplianceRow
    {
        public int EmployeeId { get; set; }
        public string EmployeeName { get; set; } = "";
        public string DepartmentName { get; set; } = "";
        public DateTime ContractEndDate { get; set; }
        public int DaysRemaining { get; set; }
        public string Status { get; set; } = ""; // Expired or Expiring
        
        public string StatusBadgeClass => Status switch
        {
            "Expired" => "bg-danger",
            "Expiring" => "bg-warning text-dark",
            _ => "bg-info"
        };
    }

    // Attendance Compliance Report Row
    public class AttendanceComplianceRow
    {
        public int EmployeeId { get; set; }
        public string EmployeeName { get; set; } = "";
        public string DepartmentName { get; set; } = "";
        public int LateCount { get; set; }
        public int ShortTimeCount { get; set; }
        public int TotalDays { get; set; }
        public string ComplianceFlag { get; set; } = "OK"; // OK or Attention
        
        public string ComplianceBadgeClass => ComplianceFlag switch
        {
            "Attention" => "bg-warning text-dark",
            _ => "bg-success"
        };
    }

    // Gender Distribution Row
    public class GenderDistributionRow
    {
        public string DepartmentName { get; set; } = "";
        public int MaleCount { get; set; }
        public int FemaleCount { get; set; }
        public int OtherCount { get; set; }
        public int Total { get; set; }
        public decimal MalePercent { get; set; }
        public decimal FemalePercent { get; set; }
    }

    // Employment Type Distribution Row
    public class EmploymentTypeRow
    {
        public string DepartmentName { get; set; } = "";
        public string ContractType { get; set; } = "";
        public int Count { get; set; }
        public decimal Percent { get; set; }
    }

    // Container for Compliance Report with filters
    public class ComplianceReportContainer
    {
        public DateTime ReportDate { get; set; } = DateTime.Now;
        public int? DepartmentId { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
        public int DaysThreshold { get; set; } = 30;
        
        public List<ContractComplianceRow> ContractRows { get; set; } = new();
        public List<AttendanceComplianceRow> AttendanceRows { get; set; } = new();
    }

    // Container for Diversity Report
    public class DiversityReportContainer
    {
        public DateTime ReportDate { get; set; } = DateTime.Now;
        public List<GenderDistributionRow> GenderRows { get; set; } = new();
        public List<EmploymentTypeRow> EmploymentTypeRows { get; set; } = new();
    }
}

