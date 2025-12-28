using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize]
    public class NotificationController : Controller
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        // ====================================================================
        // EMPLOYEE ACTIONS - All Users
        // ====================================================================

        // GET: Notification/Index - View all notifications
        public async Task<IActionResult> Index()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            var notifications = await _notificationService.GetMyNotificationsAsync(employeeId.Value);
            ViewBag.UnreadCount = await _notificationService.GetUnreadCountAsync(employeeId.Value);
            
            return View(notifications);
        }

        // POST: Notification/MarkAsRead
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> MarkAsRead(int notificationId)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            try
            {
                await _notificationService.MarkAsReadAsync(notificationId, employeeId.Value);
                TempData["SuccessMessage"] = "Notification marked as read.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // POST: Notification/MarkAllRead
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> MarkAllRead()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            try
            {
                await _notificationService.MarkAllAsReadAsync(employeeId.Value);
                TempData["SuccessMessage"] = "All notifications marked as read.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // GET: Notification/GetUnreadCount (API for navbar badge)
        [HttpGet]
        public async Task<IActionResult> GetUnreadCount()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Json(new { count = 0 });

            var count = await _notificationService.GetUnreadCountAsync(employeeId.Value);
            return Json(new { count });
        }

        // ====================================================================
        // MANAGER ACTIONS
        // ====================================================================

        // GET: Notification/SendToTeam
        [Authorize(Roles = "Manager,SuperAdmin,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> SendToTeam()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            try
            {
                // Check if user is admin (HRAdmin or SuperAdmin see ALL employees)
                var isAdmin = User.IsInRole("HRAdmin") || User.IsInRole("SuperAdmin");
                
                var teamMembers = await _notificationService.GetTeamMembersAsync(employeeId.Value, isAdmin);
                ViewBag.TeamMembers = teamMembers;
                ViewBag.IsAdmin = isAdmin;
                
                if (!teamMembers.Any())
                {
                    if (isAdmin)
                    {
                        TempData["WarningMessage"] = "No active employees found in the system.";
                    }
                    else
                    {
                        TempData["WarningMessage"] = "You don't have any team members to send notifications to.";
                    }
                }
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error loading team members: {ex.Message}";
                ViewBag.TeamMembers = Enumerable.Empty<TeamMemberInfo>();
            }

            return View();
        }

        // POST: Notification/SendToTeam
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Manager,SuperAdmin,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> SendToTeam(string message, string urgency, string selectedEmployees)
        {
            var managerId = GetCurrentEmployeeId();
            if (!managerId.HasValue) return Unauthorized();

            if (string.IsNullOrWhiteSpace(selectedEmployees))
            {
                TempData["ErrorMessage"] = "Please select at least one team member.";
                return await SendToTeam(); // Reload with team members
            }

            if (string.IsNullOrWhiteSpace(message))
            {
                TempData["ErrorMessage"] = "Message content is required.";
                return await SendToTeam();
            }

            try
            {
                var result = await _notificationService.SendNotificationToEmployeesAsync(
                    managerId.Value, 
                    selectedEmployees, 
                    message, 
                    urgency ?? "Normal"
                );
                
                TempData["SuccessMessage"] = $"Notification sent to {result.recipientCount} team member(s) successfully!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error sending notification: {ex.Message}";
                return await SendToTeam();
            }
        }


        // ====================================================================
        // ADMIN ACTIONS - Broadcast to ALL employees
        // ====================================================================

        // GET: Notification/Broadcast
        [Authorize(Roles = "SuperAdmin,HRAdmin")]
        public IActionResult Broadcast()
        {
            return View();
        }

        // POST: Notification/Broadcast
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,HRAdmin")]
        public async Task<IActionResult> Broadcast(string message, string urgency, string notificationType)
        {
            var senderId = GetCurrentEmployeeId();
            if (!senderId.HasValue) return Unauthorized();

            if (string.IsNullOrWhiteSpace(message))
            {
                TempData["ErrorMessage"] = "Message content is required.";
                return View();
            }

            try
            {
                var result = await _notificationService.SendBroadcastNotificationAsync(
                    senderId.Value, 
                    message, 
                    urgency ?? "Normal", 
                    notificationType ?? "Announcement"
                );
                
                TempData["SuccessMessage"] = $"Broadcast notification sent to {result.recipientCount} employees!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error sending broadcast: {ex.Message}";
                return View();
            }
        }

        // ====================================================================
        // HISTORY ACTIONS - View sent notifications
        // ====================================================================

        // GET: Notification/History
        [Authorize(Roles = "Manager,SuperAdmin,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> History()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            try
            {
                var sentHistory = await _notificationService.GetSentHistoryAsync(employeeId.Value);
                return View(sentHistory);
            }
            catch (Exception ex)
            {
                // Provide friendly error message for database setup issues
                if (ex.Message.Contains("Could not find stored procedure"))
                {
                    TempData["ErrorMessage"] = "Database update required. Please run the latest notification_procedures.sql script on your database.";
                }
                else
                {
                    TempData["ErrorMessage"] = $"Unable to load sent history. Please try again later.";
                }
                return View(Enumerable.Empty<SentNotificationInfo>());
            }
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
