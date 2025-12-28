using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize]
    public class LeaveController : Controller
    {
        private readonly ILeaveService _leaveService;
        private readonly IEmployeeService _employeeService;
        private readonly IWebHostEnvironment _webHostEnvironment;

        public LeaveController(ILeaveService leaveService, IEmployeeService employeeService, IWebHostEnvironment webHostEnvironment)
        {
            _leaveService = leaveService;
            _employeeService = employeeService;
            _webHostEnvironment = webHostEnvironment;
        }

        // ====================================================================
        // EMPLOYEE ACTIONS
        // ====================================================================

        // GET: Leave/MyLeave - Employee Dashboard
        public async Task<IActionResult> MyLeave()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            var balances = await _leaveService.GetLeaveBalanceAsync(employeeId.Value);
            var history = await _leaveService.GetLeaveHistoryAsync(employeeId.Value);

            ViewBag.Balances = balances;
            ViewBag.RecentRequests = history.Take(5);

            return View();
        }

        // GET: Leave/Submit
        public async Task<IActionResult> Submit()
        {
            var leaveTypes = await _leaveService.GetLeaveTypesAsync();
            ViewBag.LeaveTypes = leaveTypes;
            return View();
        }

        // POST: Leave/Submit
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Submit(int leaveTypeId, DateTime startDate, DateTime endDate, string reason, IFormFile? document)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            try
            {
                int requestId = await _leaveService.SubmitLeaveRequestAsync(employeeId.Value, leaveTypeId, startDate, endDate, reason);
                
                if (document != null && document.Length > 0)
                {
                    // Ensure directory exists
                    var uploadsFolder = Path.Combine(_webHostEnvironment.WebRootPath, "uploads", "leave_docs");
                    Directory.CreateDirectory(uploadsFolder);
                    
                    // Unique filename
                    var uniqueFileName = Guid.NewGuid().ToString() + "_" + document.FileName;
                    var filePath = Path.Combine(uploadsFolder, uniqueFileName);
                    
                    using (var fileStream = new FileStream(filePath, FileMode.Create))
                    {
                        await document.CopyToAsync(fileStream);
                    }
                    
                    // Save relative path
                    await _leaveService.AttachDocumentAsync(requestId, "/uploads/leave_docs/" + uniqueFileName);
                }

                TempData["SuccessMessage"] = "Leave request submitted successfully!";
                return RedirectToAction(nameof(MyLeave));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error submitting request: {ex.Message}";
                var leaveTypes = await _leaveService.GetLeaveTypesAsync();
                ViewBag.LeaveTypes = leaveTypes;
                return View();
            }
        }

        [Authorize(Roles = "SuperAdmin,HRAdmin")]
        public async Task<IActionResult> Details(int id)
        {
            var requests = await _leaveService.GetAllLeaveRequestsAsync();
            var request = requests.FirstOrDefault(r => r.RequestId == id);
            
            if (request == null) return NotFound();

            return View(request);
        }

        // GET: Leave/History
        public async Task<IActionResult> History()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            var history = await _leaveService.GetLeaveHistoryAsync(employeeId.Value);
            return View(history);
        }

        // GET: Leave/Balance
        public async Task<IActionResult> Balance()
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            var balances = await _leaveService.GetLeaveBalanceAsync(employeeId.Value);
            return View(balances);
        }

        // POST: Leave/Cancel
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Cancel(int requestId)
        {
            var employeeId = GetCurrentEmployeeId();
            if (!employeeId.HasValue) return Unauthorized();

            try
            {
                await _leaveService.CancelLeaveRequestAsync(requestId, employeeId.Value);
                TempData["SuccessMessage"] = "Leave request cancelled successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error cancelling request: {ex.Message}";
            }

            return RedirectToAction(nameof(History));
        }

        // ====================================================================
        // MANAGER ACTIONS
        // ====================================================================

        // GET: Leave/TeamRequests
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> TeamRequests()
        {
            var managerId = GetCurrentEmployeeId();
            if (!managerId.HasValue) return Unauthorized();

            var pendingRequests = await _leaveService.GetPendingRequestsAsync(managerId.Value);
            return View(pendingRequests);
        }

        // POST: Leave/Approve
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Manager,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> Approve(int requestId, string? comments)
        {
            var approverId = GetCurrentEmployeeId();
            if (!approverId.HasValue) return Unauthorized();

            try
            {
                await _leaveService.ApproveRequestAsync(requestId, approverId.Value, comments);
                TempData["SuccessMessage"] = "Leave request approved successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error approving request: {ex.Message}";
            }

            if (User.IsInRole("SuperAdmin") || User.IsInRole("HRAdmin"))
            {
                return RedirectToAction(nameof(AllRequests));
            }
            return RedirectToAction(nameof(TeamRequests));
        }

        // POST: Leave/Reject
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Manager,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> Reject(int requestId, string reason)
        {
            var approverId = GetCurrentEmployeeId();
            if (!approverId.HasValue) return Unauthorized();

            try
            {
                await _leaveService.RejectRequestAsync(requestId, approverId.Value, reason);
                TempData["SuccessMessage"] = "Leave request rejected.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error rejecting request: {ex.Message}";
            }

            if (User.IsInRole("SuperAdmin") || User.IsInRole("HRAdmin"))
            {
                return RedirectToAction(nameof(AllRequests));
            }
            return RedirectToAction(nameof(TeamRequests));
        }

        // POST: Leave/FlagIrregular
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "Manager,HRAdmin,SystemAdmin")]
        public async Task<IActionResult> FlagIrregular(int employeeId, string reason)
        {
            var flaggedBy = GetCurrentEmployeeId();
            if (!flaggedBy.HasValue) return Unauthorized();

            try
            {
                await _leaveService.FlagIrregularLeaveAsync(employeeId, flaggedBy.Value, reason);
                TempData["SuccessMessage"] = "Irregular leave pattern flagged successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error flagging pattern: {ex.Message}";
            }

            return RedirectToAction(nameof(TeamRequests));
        }

        // ====================================================================
        // HR ADMIN ACTIONS
        // ====================================================================

        // GET: Leave/Policies
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Policies()
        {
            var policies = await _leaveService.GetAllPoliciesAsync();
            return View(policies);
        }

        // GET: Leave/CreatePolicy
        [Authorize(Roles = "HRAdmin")]
        public IActionResult CreatePolicy()
        {
            return View();
        }

        // POST: Leave/CreatePolicy
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> CreatePolicy(LeavePolicy policy)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    await _leaveService.CreatePolicyAsync(policy);
                    TempData["SuccessMessage"] = "Policy created successfully!";
                    return RedirectToAction(nameof(Policies));
                }
                catch (Exception ex)
                {
                    TempData["ErrorMessage"] = ex.Message;
                }
            }
            return View(policy);
        }

        // GET: Leave/EditPolicy/5
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> EditPolicy(int id)
        {
            var policy = await _leaveService.GetPolicyByIdAsync(id);
            if (policy == null) return NotFound();
            return View(policy);
        }

        // POST: Leave/EditPolicy/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> EditPolicy(int id, LeavePolicy policy)
        {
            if (id != policy.PolicyId) return NotFound();

            if (ModelState.IsValid)
            {
                try
                {
                    await _leaveService.UpdatePolicyAsync(policy.PolicyId, policy.Name, policy.Purpose, policy.EligibilityRules, policy.NoticePeriod, policy.ResetOnNewYear);
                    TempData["SuccessMessage"] = "Policy updated successfully!";
                    return RedirectToAction(nameof(Policies));
                }
                catch (Exception ex)
                {
                    TempData["ErrorMessage"] = ex.Message;
                }
            }
            return View(policy);
        }

        // POST: Leave/DeletePolicy/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> DeletePolicy(int id)
        {
            try
            {
                await _leaveService.DeletePolicyAsync(id);
                TempData["SuccessMessage"] = "Policy deleted successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = ex.Message;
            }
            return RedirectToAction(nameof(Policies));
        }

        // GET: Leave/CreateType
        [Authorize(Roles = "HRAdmin")]
        public IActionResult CreateType()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> CreateType(string leaveTypeName, string description)
        {
            try
            {
                await _leaveService.ManageLeaveTypeAsync("INSERT", null, leaveTypeName, description);
                TempData["SuccessMessage"] = "Leave type created successfully!";
                return RedirectToAction(nameof(LeaveTypes));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = ex.Message;
                return View();
            }
        }



        // GET: Leave/LeaveTypes
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> LeaveTypes()
        {
            var types = await _leaveService.GetLeaveTypesAsync();
            return View(types);
        }

        // POST: Leave/ManageType
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> ManageType(string action, int? leaveId, string leaveType, string? description)
        {
            try
            {
                await _leaveService.ManageLeaveTypeAsync(action, leaveId, leaveType, description);
                TempData["SuccessMessage"] = $"Leave type {action.ToLower()}d successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error managing leave type: {ex.Message}";
            }

            return RedirectToAction(nameof(LeaveTypes));
        }

        // GET: Leave/Entitlements
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Entitlements()
        {
            var employees = await _employeeService.GetAllEmployeesAsync();
            var leaveTypes = await _leaveService.GetLeaveTypesAsync();
            
            ViewBag.Employees = employees;
            ViewBag.LeaveTypes = leaveTypes;
            
            return View();
        }

        // POST: Leave/AssignEntitlement
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> AssignEntitlement(int employeeId, int leaveTypeId, decimal entitlement)
        {
            try
            {
                await _leaveService.AssignEntitlementAsync(employeeId, leaveTypeId, entitlement);
                TempData["SuccessMessage"] = "Leave entitlement assigned successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error assigning entitlement: {ex.Message}";
            }

            return RedirectToAction(nameof(Entitlements));
        }

        // POST: Leave/AdjustBalance
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> AdjustBalance(int employeeId, int leaveTypeId, string operation, decimal amount, string reason)
        {
            try
            {
                await _leaveService.AdjustBalanceAsync(employeeId, leaveTypeId, operation, amount, reason);
                TempData["SuccessMessage"] = "Leave balance adjusted successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error adjusting balance: {ex.Message}";
            }

            return RedirectToAction(nameof(Entitlements));
        }

        // GET: Leave/AllRequests (Admin view of all requests)
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> AllRequests()
        {
            var requests = await _leaveService.GetAllLeaveRequestsAsync();
            return View(requests);
        }

        // GET: Leave/OverrideRequest/5
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> OverrideRequest(int id)
        {
            var requests = await _leaveService.GetAllLeaveRequestsAsync();
            var request = requests.FirstOrDefault(r => r.RequestId == id);
            
            if (request == null) return NotFound();

            return View(request);
        }

        // POST: Leave/Override
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Override(int requestId, string newStatus, string reason)
        {
            var adminId = GetCurrentEmployeeId();
            if (!adminId.HasValue) return Unauthorized();

            try
            {
                await _leaveService.OverrideDecisionAsync(requestId, adminId.Value, newStatus, reason);
                TempData["SuccessMessage"] = $"Leave decision overridden to {newStatus}!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error overriding decision: {ex.Message}";
            }

            return RedirectToAction(nameof(AllRequests));
        }

        // GET: Leave/SpecialLeave
        [Authorize(Roles = "HRAdmin")]
        public IActionResult SpecialLeave()
        {
            return View();
        }

        // POST: Leave/ConfigureSpecialLeave
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> ConfigureSpecialLeave(string leaveType, int maxDays, string eligibilityRules)
        {
            try
            {
                await _leaveService.ConfigureSpecialLeaveAsync(leaveType, maxDays, eligibilityRules);
                TempData["SuccessMessage"] = "Special leave configured successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error configuring special leave: {ex.Message}";
            }

            return RedirectToAction(nameof(SpecialLeave));
        }

        // POST: Leave/SyncAttendance
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> SyncAttendance(int requestId)
        {
            try
            {
                await _leaveService.SyncWithAttendanceAsync(requestId);
                TempData["SuccessMessage"] = "Leave synced with attendance successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error syncing with attendance: {ex.Message}";
            }

            return RedirectToAction(nameof(AllRequests));
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
