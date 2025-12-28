using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IAnalyticsService
    {
        // ====================================================================
        // DASHBOARD
        // ====================================================================
        Task<AnalyticsDashboard> GetDashboardAsync();
        Task<IEnumerable<DepartmentStatistics>> GetDepartmentOverviewAsync();
        
        // ====================================================================
        // DEPARTMENT STATISTICS
        // ====================================================================
        Task<IEnumerable<DepartmentStatistics>> GetDepartmentStatisticsAsync();
        Task<DepartmentStatistics?> GetDepartmentStatisticsAsync(int departmentId);
        Task<IEnumerable<DepartmentStatistics>> SearchDepartmentStatsAsync(string searchTerm);
        
        // ====================================================================
        // COMPLIANCE REPORTS
        // ====================================================================
        
        // Existing methods (kept for backward compatibility)
        Task<ComplianceReport> GenerateComplianceReportAsync();
        Task<ComplianceReport> GenerateComplianceReportAsync(int departmentId);
        
        // New: Contract Compliance Report
        Task<IEnumerable<ContractComplianceRow>> GetContractComplianceAsync(int? departmentId = null, int daysThreshold = 30);
        
        // New: Attendance Compliance Report
        Task<IEnumerable<AttendanceComplianceRow>> GetAttendanceComplianceAsync(
            DateTime dateFrom, DateTime dateTo, int? departmentId = null);
        
        // New: Combined Compliance Report Container
        Task<ComplianceReportContainer> GetComplianceReportAsync(
            int? departmentId = null, 
            DateTime? dateFrom = null, 
            DateTime? dateTo = null, 
            int daysThreshold = 30);
        
        // ====================================================================
        // DIVERSITY REPORTS
        // ====================================================================
        
        // Existing methods (kept for backward compatibility)
        Task<DiversityReport> GenerateDiversityReportAsync();
        Task<DiversityReport> GenerateDiversityReportAsync(int departmentId);
        
        // New: Gender Distribution
        Task<IEnumerable<GenderDistributionRow>> GetGenderDistributionAsync();
        
        // New: Employment Type Distribution
        Task<IEnumerable<EmploymentTypeRow>> GetEmploymentTypeDistributionAsync();
        
        // New: Combined Diversity Report Container
        Task<DiversityReportContainer> GetDiversityReportAsync();
    }
}
