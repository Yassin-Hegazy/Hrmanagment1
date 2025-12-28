using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize]
    public class AttendanceController : Controller
    {
        private readonly IAttendanceService _attendanceService;
        private readonly IEmployeeService _employeeService;

        public AttendanceController(
            IAttendanceService attendanceService,
            IEmployeeService employeeService)
        {
            _attendanceService = attendanceService;
            _employeeService = employeeService;
        }

        // GET: Attendance/MyAttendance
        public async Task<IActionResult> MyAttendance()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            // Get current attendance status
            var currentAttendance = await _attendanceService.GetCurrentAttendanceAsync(employeeId.Value);
            ViewBag.CurrentAttendance = currentAttendance;
            
            // Determine if clocked in
            ViewBag.IsClockedIn = currentAttendance != null && 
                                  currentAttendance.EntryTime.HasValue && 
                                  !currentAttendance.ExitTime.HasValue;

            // Get last 30 days attendance history
            var attendanceHistory = await _attendanceService.GetEmployeeAttendanceAsync(employeeId.Value, 30);

            return View(attendanceHistory);
        }

        // POST: Attendance/ClockIn
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ClockIn()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            try
            {
                await _attendanceService.RecordAttendanceAsync(employeeId.Value, DateTime.Now, "Web");
                TempData["SuccessMessage"] = "Clocked in successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error clocking in: {ex.Message}";
            }

            return RedirectToAction(nameof(MyAttendance));
        }

        // POST: Attendance/ClockOut
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ClockOut()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            try
            {
                await _attendanceService.RecordAttendanceAsync(employeeId.Value, DateTime.Now, "Web");
                TempData["SuccessMessage"] = "Clocked out successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error clocking out: {ex.Message}";
            }

            return RedirectToAction(nameof(MyAttendance));
        }

        // GET: Attendance/CorrectionRequest
        public IActionResult CorrectionRequest()
        {
            return View();
        }

        // POST: Attendance/CorrectionRequest
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CorrectionRequest(DateTime date, DateTime correctTime, string reason, string correctionType)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            try
            {
                var request = new AttendanceCorrectionRequest
                {
                    EmployeeId = employeeId.Value,
                    Date = date.Date,
                    CorrectionType = correctionType,
                    Reason = reason,
                    Status = "Pending",
                    RecordedBy = employeeId.Value,
                    CorrectTime = correctTime
                };

                await _attendanceService.SubmitCorrectionRequestAsync(request);
                TempData["SuccessMessage"] = "Correction request submitted successfully!";
                return RedirectToAction(nameof(MyAttendance));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error submitting correction request: {ex.Message}";
                return View();
            }
        }

        // GET: Attendance/TeamSummary
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> TeamSummary(DateTime? startDate, DateTime? endDate)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            // Default to last 7 days if no dates provided
            var start = startDate ?? DateTime.Today.AddDays(-7);
            var end = endDate ?? DateTime.Today;

            ViewBag.StartDate = start;
            ViewBag.EndDate = end;

            var teamAttendance = await _attendanceService.GetTeamAttendanceAsync(employeeId.Value, start, end);
            
            return View(teamAttendance);
        }

        // GET: Attendance/Dashboard
        [Authorize(Roles = "Manager,SuperAdmin,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> Dashboard()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            // Get today's attendance for the team
            var today = DateTime.Today;
            var teamAttendance = await _attendanceService.GetTeamAttendanceAsync(employeeId.Value, today, today);
            
            return View(teamAttendance);
        }

        // GET: Attendance/PendingCorrections
        [Authorize(Roles = "Manager,SuperAdmin,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> PendingCorrections()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            var pendingCorrections = await _attendanceService.GetPendingCorrectionsForManagerAsync(employeeId.Value);
            
            return View(pendingCorrections);
        }

        // POST: Attendance/ApproveCorrection
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Manager,SuperAdmin,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> ApproveCorrection(int requestId, DateTime? correctTime)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            try
            {
                await _attendanceService.ApproveCorrectionRequestAsync(requestId, employeeId.Value, correctTime);
                TempData["SuccessMessage"] = "Correction request approved successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error approving correction: {ex.Message}";
            }

            return RedirectToAction(nameof(PendingCorrections));
        }

        // POST: Attendance/RejectCorrection
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Manager,SuperAdmin,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> RejectCorrection(int requestId, string reason)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            try
            {
                await _attendanceService.RejectCorrectionRequestAsync(requestId, employeeId.Value, reason);
                TempData["SuccessMessage"] = "Correction request rejected.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error rejecting correction: {ex.Message}";
            }

            return RedirectToAction(nameof(PendingCorrections));
        }

        // GET: Attendance/ExportTeamAttendance
        [Authorize(Roles = "Manager,SuperAdmin,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> ExportTeamAttendance(DateTime? startDate = null, DateTime? endDate = null)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue)
            {
                return Unauthorized();
            }

            var start = startDate ?? DateTime.Today.AddDays(-30);
            var end = endDate ?? DateTime.Today;

            var teamAttendance = await _attendanceService.GetTeamAttendanceAsync(employeeId.Value, start, end);

            // Generate CSV
            var csv = new System.Text.StringBuilder();
            csv.AppendLine("Employee ID,Employee Name,Date,Check In,Check Out,Duration,Status,Shift");

            foreach (var attendance in teamAttendance)
            {
                csv.AppendLine($"{attendance.EmployeeId}," +
                              $"\"{attendance.EmployeeName}\"," +
                              $"{(attendance.EntryTime?.ToString("yyyy-MM-dd") ?? "")}," +
                              $"{(attendance.EntryTime?.ToString("HH:mm") ?? "")}," +
                              $"{(attendance.ExitTime?.ToString("HH:mm") ?? "")}," +
                              $"{attendance.DurationFormatted}," +
                              $"{attendance.Status}," +
                              $"\"{attendance.ShiftName}\"");
            }

            var fileName = $"TeamAttendance_{start:yyyyMMdd}_{end:yyyyMMdd}.csv";
            var bytes = System.Text.Encoding.UTF8.GetBytes(csv.ToString());
            
            return File(bytes, "text/csv", fileName);
        }

        private int? GetCurrentEmployeeId()
        {
            var employeeIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(employeeIdClaim, out int employeeId))
            {
                return employeeId;
            }
            return null;
        }

        // GET: Attendance/OfflineSyncTool
        public IActionResult OfflineSyncTool()
        {
            return View();
        }

        // POST: Attendance/SyncOffline (API endpoint for offline sync)
        [HttpPost]
        public async Task<IActionResult> SyncOffline([FromBody] OfflineSyncRequest request)
        {
            if (request == null || request.EmployeeId <= 0)
            {
                return BadRequest(new { success = false, message = "Invalid request" });
            }

            try
            {
                var clockTime = DateTime.Parse(request.ClockTime);
                await _attendanceService.SyncOfflineAttendanceAsync(request.EmployeeId, clockTime, request.Type);
                return Ok(new { success = true, message = "Record synced successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }
    }

    // Request model for offline sync
    public class OfflineSyncRequest
    {
        public int EmployeeId { get; set; }
        public string ClockTime { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty; // IN or OUT
    }
}
