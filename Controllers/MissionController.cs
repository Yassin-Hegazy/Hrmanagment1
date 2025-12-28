using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize]
    public class MissionController : Controller
    {
        private readonly IMissionService _missionService;
        private readonly IEmployeeService _employeeService;

        public MissionController(IMissionService missionService, IEmployeeService employeeService)
        {
            _missionService = missionService;
            _employeeService = employeeService;
        }

        // ====================================================================
        // EMPLOYEE ACTIONS
        // ====================================================================

        // GET: Mission/MyMissions - View assigned missions
        public async Task<IActionResult> MyMissions()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            var missions = await _missionService.GetMyMissionsAsync(employeeId.Value);
            return View(missions);
        }

        // GET: Mission/Details/5
        public async Task<IActionResult> Details(int id)
        {
            var mission = await _missionService.GetMissionByIdAsync(id);
            if (mission == null) return NotFound();

            return View(mission);
        }

        // ====================================================================
        // MANAGER ACTIONS
        // ====================================================================

        // GET: Mission/PendingApprovals
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> PendingApprovals()
        {
            var managerId = GetCurrentEmployeeId();
            if (!managerId.HasValue) return Unauthorized();

            var pendingMissions = await _missionService.GetPendingMissionsAsync(managerId.Value);
            return View(pendingMissions);
        }

        // POST: Mission/Approve
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> Approve(int missionId)
        {
            var approverId = GetCurrentEmployeeId();
            if (!approverId.HasValue) return Unauthorized();

            try
            {
                await _missionService.ApproveMissionAsync(missionId, approverId.Value);
                TempData["SuccessMessage"] = "Mission approved successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error approving mission: {ex.Message}";
            }

            return RedirectToAction(nameof(PendingApprovals));
        }

        // POST: Mission/Reject
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> Reject(int missionId, string reason)
        {
            var approverId = GetCurrentEmployeeId();
            if (!approverId.HasValue) return Unauthorized();

            try
            {
                await _missionService.RejectMissionAsync(missionId, approverId.Value, reason);
                TempData["SuccessMessage"] = "Mission rejected.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error rejecting mission: {ex.Message}";
            }

            return RedirectToAction(nameof(PendingApprovals));
        }

        // ====================================================================
        // HR ADMIN ACTIONS
        // ====================================================================

        // GET: Mission/Index (All missions)
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Index()
        {
            var missions = await _missionService.GetAllMissionsAsync();
            return View(missions);
        }

        // GET: Mission/Assign
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Assign()
        {
            var employees = await _employeeService.GetAllEmployeesAsync();
            ViewBag.Employees = employees;
            return View();
        }

        // POST: Mission/Assign
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Assign(int employeeId, int managerId, string destination, DateTime startDate, DateTime endDate)
        {
            try
            {
                await _missionService.AssignMissionAsync(employeeId, managerId, destination, startDate, endDate);
                TempData["SuccessMessage"] = "Mission assigned successfully!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error assigning mission: {ex.Message}";
                var employees = await _employeeService.GetAllEmployeesAsync();
                ViewBag.Employees = employees;
                return View();
            }
        }

        // GET: Mission/Edit/5
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Edit(int id)
        {
            var mission = await _missionService.GetMissionByIdAsync(id);
            if (mission == null) return NotFound();

            return View(mission);
        }

        // POST: Mission/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Edit(int id, string status)
        {
            try
            {
                await _missionService.UpdateMissionStatusAsync(id, status);
                TempData["SuccessMessage"] = $"Mission status updated to {status}!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error updating status: {ex.Message}";
                var mission = await _missionService.GetMissionByIdAsync(id);
                return View(mission);
            }
        }

        // POST: Mission/UpdateStatus (kept for backwards compatibility)
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> UpdateStatus(int missionId, string status)
        {
            try
            {
                await _missionService.UpdateMissionStatusAsync(missionId, status);
                TempData["SuccessMessage"] = $"Mission status updated to {status}!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error updating status: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // ====================================================================
        // HELPER METHODS
        // ====================================================================

        private int? GetCurrentEmployeeId()
        {
            var employeeIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(employeeIdClaim, out int employeeId))
            {
                return employeeId;
            }
            return null;
        }
    }
}
