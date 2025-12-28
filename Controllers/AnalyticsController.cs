using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize(Roles = "SuperAdmin,HRAdmin")]
    public class AnalyticsController : Controller
    {
        private readonly IAnalyticsService _analyticsService;
        private readonly IDepartmentService _departmentService;

        public AnalyticsController(IAnalyticsService analyticsService, IDepartmentService departmentService)
        {
            _analyticsService = analyticsService;
            _departmentService = departmentService;
        }

        // ====================================================================
        // A) ANALYTICS DASHBOARD
        // ====================================================================
        
        // GET: Analytics/Index - Dashboard with KPI cards
        public async Task<IActionResult> Index()
        {
            var dashboard = await _analyticsService.GetDashboardAsync();
            return View(dashboard);
        }

        // ====================================================================
        // B) DEPARTMENT STATISTICS
        // ====================================================================
        
        // GET: Analytics/DepartmentStats - Search departments
        public async Task<IActionResult> DepartmentStats(string? search)
        {
            var stats = string.IsNullOrEmpty(search)
                ? await _analyticsService.GetDepartmentStatisticsAsync()
                : await _analyticsService.SearchDepartmentStatsAsync(search);

            ViewBag.SearchTerm = search;
            return View(stats);
        }

        // GET: Analytics/DepartmentDetails/5
        public async Task<IActionResult> DepartmentDetails(int id)
        {
            var stats = await _analyticsService.GetDepartmentStatisticsAsync(id);
            if (stats == null) return NotFound();

            return View(stats);
        }

        // ====================================================================
        // C) COMPLIANCE REPORT
        // ====================================================================
        
        // GET: Analytics/ComplianceReport - Contracts and Attendance compliance
        public async Task<IActionResult> ComplianceReport(
            int? departmentId, 
            DateTime? dateFrom, 
            DateTime? dateTo, 
            int daysThreshold = 30)
        {
            // Load departments for dropdown
            var departments = await _departmentService.GetAllDepartmentsAsync();
            ViewBag.Departments = departments;
            ViewBag.SelectedDepartment = departmentId;
            ViewBag.DateFrom = dateFrom ?? DateTime.Now.AddDays(-30);
            ViewBag.DateTo = dateTo ?? DateTime.Now;
            ViewBag.DaysThreshold = daysThreshold;

            var report = await _analyticsService.GetComplianceReportAsync(
                departmentId, dateFrom, dateTo, daysThreshold);

            return View(report);
        }

        // Legacy Compliance action (redirect to new)
        public async Task<IActionResult> Compliance(int? departmentId)
        {
            return RedirectToAction(nameof(ComplianceReport), new { departmentId });
        }

        // ====================================================================
        // D) DIVERSITY REPORT
        // ====================================================================
        
        // GET: Analytics/DiversityReport - Gender and Employment Type distribution
        public async Task<IActionResult> DiversityReport()
        {
            var report = await _analyticsService.GetDiversityReportAsync();
            return View(report);
        }

        // Legacy Diversity action (redirect to new)
        public async Task<IActionResult> Diversity(int? departmentId)
        {
            return RedirectToAction(nameof(DiversityReport));
        }
    }
}
