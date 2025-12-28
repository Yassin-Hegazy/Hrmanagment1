using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class AnalyticsService : IAnalyticsService
    {
        private readonly SqlHelper _sqlHelper;

        public AnalyticsService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        // ====================================================================
        // DASHBOARD
        // ====================================================================

        public async Task<AnalyticsDashboard> GetDashboardAsync()
        {
            var dashboard = new AnalyticsDashboard();

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetAnalyticsDashboard");
            
            if (result.Rows.Count > 0)
            {
                var row = result.Rows[0];
                dashboard.TotalEmployees = row["TotalEmployees"] != DBNull.Value ? Convert.ToInt32(row["TotalEmployees"]) : 0;
                dashboard.TotalDepartments = row["TotalDepartments"] != DBNull.Value ? Convert.ToInt32(row["TotalDepartments"]) : 0;
                dashboard.ActiveContracts = row["ActiveContracts"] != DBNull.Value ? Convert.ToInt32(row["ActiveContracts"]) : 0;
                dashboard.NewHiresThisMonth = row["NewHiresThisMonth"] != DBNull.Value ? Convert.ToInt32(row["NewHiresThisMonth"]) : 0;
                dashboard.PendingLeaveRequests = row["PendingLeaveRequests"] != DBNull.Value ? Convert.ToInt32(row["PendingLeaveRequests"]) : 0;
                dashboard.ActiveMissions = row["ActiveMissions"] != DBNull.Value ? Convert.ToInt32(row["ActiveMissions"]) : 0;
                dashboard.ContractsExpiringThisMonth = row["ExpiringContracts"] != DBNull.Value ? Convert.ToInt32(row["ExpiringContracts"]) : 0;
            }

            dashboard.DepartmentStats = (await GetDepartmentOverviewAsync()).ToList();
            return dashboard;
        }

        public async Task<IEnumerable<DepartmentStatistics>> GetDepartmentOverviewAsync()
        {
            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetDepartmentOverview");
            var stats = new List<DepartmentStatistics>();

            foreach (DataRow row in result.Rows)
            {
                stats.Add(new DepartmentStatistics
                {
                    DepartmentId = Convert.ToInt32(row["DepartmentId"]),
                    DepartmentName = row["DepartmentName"]?.ToString() ?? "",
                    TotalEmployees = row["TotalEmployees"] != DBNull.Value ? Convert.ToInt32(row["TotalEmployees"]) : 0,
                    ActiveEmployees = row["ActiveEmployees"] != DBNull.Value ? Convert.ToInt32(row["ActiveEmployees"]) : 0
                });
            }
            return stats;
        }

        // ====================================================================
        // DEPARTMENT STATISTICS
        // ====================================================================

        public async Task<IEnumerable<DepartmentStatistics>> GetDepartmentStatisticsAsync()
        {
            return await SearchDepartmentStatsAsync(null!);
        }

        public async Task<DepartmentStatistics?> GetDepartmentStatisticsAsync(int departmentId)
        {
            var stats = await GetDepartmentStatisticsAsync();
            return stats.FirstOrDefault(s => s.DepartmentId == departmentId);
        }

        public async Task<IEnumerable<DepartmentStatistics>> SearchDepartmentStatsAsync(string searchTerm)
        {
            var parameters = new[]
            {
                new SqlParameter("@SearchTerm", string.IsNullOrEmpty(searchTerm) ? (object)DBNull.Value : searchTerm)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_SearchDepartmentStats", parameters);
            var stats = new List<DepartmentStatistics>();

            foreach (DataRow row in result.Rows)
            {
                stats.Add(new DepartmentStatistics
                {
                    DepartmentId = Convert.ToInt32(row["DepartmentId"]),
                    DepartmentName = row["DepartmentName"]?.ToString() ?? "",
                    TotalEmployees = row["TotalEmployees"] != DBNull.Value ? Convert.ToInt32(row["TotalEmployees"]) : 0,
                    ActiveEmployees = row["ActiveEmployees"] != DBNull.Value ? Convert.ToInt32(row["ActiveEmployees"]) : 0,
                    // Age Distribution
                    Under25 = row.Table.Columns.Contains("Under25") && row["Under25"] != DBNull.Value ? Convert.ToInt32(row["Under25"]) : 0,
                    Age25to34 = row.Table.Columns.Contains("Age25to34") && row["Age25to34"] != DBNull.Value ? Convert.ToInt32(row["Age25to34"]) : 0,
                    Age35to44 = row.Table.Columns.Contains("Age35to44") && row["Age35to44"] != DBNull.Value ? Convert.ToInt32(row["Age35to44"]) : 0,
                    Age45to54 = row.Table.Columns.Contains("Age45to54") && row["Age45to54"] != DBNull.Value ? Convert.ToInt32(row["Age45to54"]) : 0,
                    Over55 = row.Table.Columns.Contains("Over55") && row["Over55"] != DBNull.Value ? Convert.ToInt32(row["Over55"]) : 0
                });
            }
            return stats;
        }

        // ====================================================================
        // COMPLIANCE REPORTS
        // ====================================================================

        public async Task<IEnumerable<ContractComplianceRow>> GetContractComplianceAsync(
            int? departmentId = null, int daysThreshold = 30)
        {
            var parameters = new[]
            {
                new SqlParameter("@DepartmentId", departmentId.HasValue ? departmentId.Value : DBNull.Value),
                new SqlParameter("@DaysThreshold", daysThreshold)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetContractsComplianceReport", parameters);
            var rows = new List<ContractComplianceRow>();

            foreach (DataRow row in result.Rows)
            {
                rows.Add(new ContractComplianceRow
                {
                    EmployeeId = Convert.ToInt32(row["EmployeeId"]),
                    EmployeeName = row["EmployeeName"]?.ToString() ?? "",
                    DepartmentName = row["DepartmentName"]?.ToString() ?? "",
                    ContractEndDate = Convert.ToDateTime(row["ContractEndDate"]),
                    DaysRemaining = row["DaysRemaining"] != DBNull.Value ? Convert.ToInt32(row["DaysRemaining"]) : 0,
                    Status = row["Status"]?.ToString() ?? ""
                });
            }
            return rows;
        }

        public async Task<IEnumerable<AttendanceComplianceRow>> GetAttendanceComplianceAsync(
            DateTime dateFrom, DateTime dateTo, int? departmentId = null)
        {
            var parameters = new[]
            {
                new SqlParameter("@DepartmentId", departmentId.HasValue ? departmentId.Value : DBNull.Value),
                new SqlParameter("@DateFrom", dateFrom),
                new SqlParameter("@DateTo", dateTo)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetAttendanceComplianceReport", parameters);
            var rows = new List<AttendanceComplianceRow>();

            foreach (DataRow row in result.Rows)
            {
                rows.Add(new AttendanceComplianceRow
                {
                    EmployeeId = Convert.ToInt32(row["EmployeeId"]),
                    EmployeeName = row["EmployeeName"]?.ToString() ?? "",
                    DepartmentName = row["DepartmentName"]?.ToString() ?? "",
                    LateCount = row["LateCount"] != DBNull.Value ? Convert.ToInt32(row["LateCount"]) : 0,
                    ShortTimeCount = row["ShortTimeCount"] != DBNull.Value ? Convert.ToInt32(row["ShortTimeCount"]) : 0,
                    TotalDays = row["TotalDays"] != DBNull.Value ? Convert.ToInt32(row["TotalDays"]) : 0,
                    ComplianceFlag = row["ComplianceFlag"]?.ToString() ?? "OK"
                });
            }
            return rows;
        }

        public async Task<ComplianceReportContainer> GetComplianceReportAsync(
            int? departmentId = null, DateTime? dateFrom = null, DateTime? dateTo = null, int daysThreshold = 30)
        {
            var container = new ComplianceReportContainer
            {
                DepartmentId = departmentId,
                DateFrom = dateFrom,
                DateTo = dateTo,
                DaysThreshold = daysThreshold
            };

            // Get contract compliance
            container.ContractRows = (await GetContractComplianceAsync(departmentId, daysThreshold)).ToList();

            // Get attendance compliance if dates provided
            if (dateFrom.HasValue && dateTo.HasValue)
            {
                container.AttendanceRows = (await GetAttendanceComplianceAsync(dateFrom.Value, dateTo.Value, departmentId)).ToList();
            }

            return container;
        }

        // Legacy methods for backward compatibility
        public async Task<ComplianceReport> GenerateComplianceReportAsync()
        {
            var report = new ComplianceReport();
            var contractRows = await GetContractComplianceAsync();
            
            report.TotalEmployees = (await GetDepartmentStatisticsAsync()).Sum(d => d.TotalEmployees);
            report.ExpiredContracts = contractRows.Count(r => r.Status == "Expired");
            report.ExpiringIn30Days = contractRows.Count(r => r.Status == "Expiring");
            report.Issues = contractRows.Select(r => new ComplianceIssue
            {
                Category = "Contract",
                Description = r.Status == "Expired" ? "Contract expired" : $"Contract expiring in {r.DaysRemaining} days",
                Severity = r.Status == "Expired" ? "High" : (r.DaysRemaining <= 7 ? "High" : "Medium"),
                EmployeeId = r.EmployeeId,
                EmployeeName = r.EmployeeName
            }).ToList();

            return report;
        }

        public async Task<ComplianceReport> GenerateComplianceReportAsync(int departmentId)
        {
            return await GenerateComplianceReportAsync();
        }

        // ====================================================================
        // DIVERSITY REPORTS
        // ====================================================================

        public async Task<IEnumerable<GenderDistributionRow>> GetGenderDistributionAsync()
        {
            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetGenderDistributionByDepartment");
            var rows = new List<GenderDistributionRow>();

            foreach (DataRow row in result.Rows)
            {
                rows.Add(new GenderDistributionRow
                {
                    DepartmentName = row["DepartmentName"]?.ToString() ?? "",
                    MaleCount = row["MaleCount"] != DBNull.Value ? Convert.ToInt32(row["MaleCount"]) : 0,
                    FemaleCount = row["FemaleCount"] != DBNull.Value ? Convert.ToInt32(row["FemaleCount"]) : 0,
                    OtherCount = row["OtherCount"] != DBNull.Value ? Convert.ToInt32(row["OtherCount"]) : 0,
                    Total = row["Total"] != DBNull.Value ? Convert.ToInt32(row["Total"]) : 0,
                    MalePercent = row["MalePercent"] != DBNull.Value ? Convert.ToDecimal(row["MalePercent"]) : 0,
                    FemalePercent = row["FemalePercent"] != DBNull.Value ? Convert.ToDecimal(row["FemalePercent"]) : 0
                });
            }
            return rows;
        }

        public async Task<IEnumerable<EmploymentTypeRow>> GetEmploymentTypeDistributionAsync()
        {
            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetEmploymentTypeDistribution");
            var rows = new List<EmploymentTypeRow>();

            foreach (DataRow row in result.Rows)
            {
                rows.Add(new EmploymentTypeRow
                {
                    DepartmentName = row["DepartmentName"]?.ToString() ?? "",
                    ContractType = row["ContractType"]?.ToString() ?? "",
                    Count = row["Count"] != DBNull.Value ? Convert.ToInt32(row["Count"]) : 0,
                    Percent = row["Percent"] != DBNull.Value ? Convert.ToDecimal(row["Percent"]) : 0
                });
            }
            return rows;
        }

        public async Task<DiversityReportContainer> GetDiversityReportAsync()
        {
            return new DiversityReportContainer
            {
                GenderRows = (await GetGenderDistributionAsync()).ToList(),
                EmploymentTypeRows = (await GetEmploymentTypeDistributionAsync()).ToList()
            };
        }

        // Legacy methods for backward compatibility
        public async Task<DiversityReport> GenerateDiversityReportAsync()
        {
            var report = new DiversityReport();
            var genderRows = await GetGenderDistributionAsync();
            
            report.TotalEmployees = genderRows.Sum(g => g.Total);
            report.MaleCount = genderRows.Sum(g => g.MaleCount);
            report.FemaleCount = genderRows.Sum(g => g.FemaleCount);
            report.OtherGenderCount = genderRows.Sum(g => g.OtherCount);
            
            report.DepartmentBreakdowns = genderRows.Select(g => new DepartmentBreakdown
            {
                DepartmentName = g.DepartmentName,
                EmployeeCount = g.Total,
                MaleCount = g.MaleCount,
                FemaleCount = g.FemaleCount,
                Percentage = report.TotalEmployees > 0 ? Math.Round((decimal)g.Total / report.TotalEmployees * 100, 1) : 0
            }).ToList();

            return report;
        }

        public async Task<DiversityReport> GenerateDiversityReportAsync(int departmentId)
        {
            return await GenerateDiversityReportAsync();
        }
    }
}
