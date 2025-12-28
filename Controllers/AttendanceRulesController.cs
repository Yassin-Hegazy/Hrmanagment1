using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize(Roles = "SuperAdmin,SystemAdmin,HRAdmin")]
    public class AttendanceRulesController : Controller
    {
        private readonly IAttendanceService _attendanceService;

        public AttendanceRulesController(IAttendanceService attendanceService)
        {
            _attendanceService = attendanceService;
        }

        // GET: AttendanceRules
        public IActionResult Index()
        {
            return View();
        }

        // POST: AttendanceRules/SetGracePeriod
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SetGracePeriod(int gracePeriodMinutes)
        {
            try
            {
                await _attendanceService.SetGracePeriodAsync(gracePeriodMinutes);
                TempData["SuccessMessage"] = $"Grace period updated to {gracePeriodMinutes} minutes successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error updating grace period: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // POST: AttendanceRules/SetPenaltyThreshold
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SetPenaltyThreshold(int lateThresholdMinutes, decimal penaltyAmount)
        {
            try
            {
                await _attendanceService.DefinePenaltyThresholdAsync(lateThresholdMinutes, penaltyAmount);
                TempData["SuccessMessage"] = $"Penalty threshold set to {lateThresholdMinutes} min = ${penaltyAmount} deduction!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error setting penalty threshold: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // POST: AttendanceRules/SetShortTimeRules
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SetShortTimeRules(int shortTimeThresholdMinutes)
        {
            try
            {
                await _attendanceService.DefineShortTimeRulesAsync(shortTimeThresholdMinutes);
                TempData["SuccessMessage"] = $"Short-time rules configured for {shortTimeThresholdMinutes} minutes!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error configuring short-time rules: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // POST: AttendanceRules/SyncLeaveWithAttendance
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SyncLeaveWithAttendance(int vacationPackageId, int employeeId)
        {
            try
            {
                await _attendanceService.SyncLeaveWithAttendanceAsync(vacationPackageId, employeeId);
                TempData["SuccessMessage"] = "Leave synced with attendance successfully! Shift assignments updated.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error syncing leave: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
