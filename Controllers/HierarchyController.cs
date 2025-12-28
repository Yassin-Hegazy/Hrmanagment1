using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize]
    public class HierarchyController : Controller
    {
        private readonly IHierarchyService _hierarchyService;
        private readonly IDepartmentService _departmentService;

        public HierarchyController(IHierarchyService hierarchyService, IDepartmentService departmentService)
        {
            _hierarchyService = hierarchyService;
            _departmentService = departmentService;
        }

        // ====================================================================
        // VIEW HIERARCHY (All authenticated users)
        // ====================================================================

        // GET: Hierarchy/Index - Organization overview
        public async Task<IActionResult> Index()
        {
            var chart = await _hierarchyService.GetOrganizationChartAsync();
            return View(chart);
        }

        // GET: Hierarchy/Department/5 - View department team
        public async Task<IActionResult> Department(int id)
        {
            var team = await _hierarchyService.GetDepartmentTeamAsync(id);
            if (team == null) return NotFound();

            return View(team);
        }

        // GET: Hierarchy/Manager/5 - View manager's team
        public async Task<IActionResult> Manager(int id)
        {
            var team = await _hierarchyService.GetManagerTeamAsync(id);
            if (team == null) return NotFound();

            return View(team);
        }

        // GET: Hierarchy/Tree - Visual hierarchy tree
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> Tree()
        {
            var nodes = await _hierarchyService.GetHierarchyTreeAsync();
            return View(nodes);
        }

        // ====================================================================
        // REASSIGNMENT (System Admin only)
        // ====================================================================

        // GET: Hierarchy/Reassign/5 - Reassign employee form
        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public async Task<IActionResult> Reassign(int id)
        {
            var departments = await _departmentService.GetAllDepartmentsAsync();
            var managers = await _hierarchyService.GetAllManagersAsync();

            ViewBag.Departments = departments;
            ViewBag.Managers = managers;
            ViewBag.EmployeeId = id;

            // Get current employee info
            var allTeams = await _hierarchyService.GetDepartmentTeamsAsync();
            foreach (var team in allTeams)
            {
                var fullTeam = await _hierarchyService.GetDepartmentTeamAsync(team.DepartmentId);
                if (fullTeam != null)
                {
                    var emp = fullTeam.Members.FirstOrDefault(m => m.EmployeeId == id);
                    if (emp != null)
                    {
                        ViewBag.Employee = emp;
                        break;
                    }
                }
            }

            return View();
        }

        // POST: Hierarchy/Reassign
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public async Task<IActionResult> Reassign(int employeeId, int? newDepartmentId, int? newManagerId)
        {
            try
            {
                await _hierarchyService.ReassignEmployeeAsync(employeeId, newDepartmentId, newManagerId);
                TempData["SuccessMessage"] = "Employee reassigned successfully!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error reassigning employee: {ex.Message}";
                return RedirectToAction(nameof(Reassign), new { id = employeeId });
            }
        }
        

        // ====================================================================
        // HIERARCHY TABLE MANAGEMENT (SuperAdmin only)
        // ====================================================================

        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public async Task<IActionResult> Rebuild()
        {
            try
            {
                await _hierarchyService.RebuildHierarchyTableAsync();
                TempData["SuccessMessage"] = "Hierarchy table rebuilt successfully based on current structure.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error rebuilding hierarchy: {ex.Message}";
            }
            return RedirectToAction(nameof(ManageLevels));
        }

        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public async Task<IActionResult> ManageLevels()
        {
            try
            {
                var viewModel = await _hierarchyService.GetManageLevelsDataAsync();
                ViewBag.DebugInfo = $"Loaded {viewModel.Employees.Count} entries";
                return View(viewModel);
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error loading data: {ex.Message}";
                return View(new ManageLevelsViewModel());
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public async Task<IActionResult> ReassignEmployee(ReassignEmployeeVM model)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    TempData["ErrorMessage"] = "Invalid input data.";
                    TempData["ErrorRowId"] = model.EmployeeId;
                    return RedirectToAction(nameof(ManageLevels));
                }

                if (model.NewManagerId.HasValue)
                {
                    // 1. Prevent assigning to self
                    if (model.EmployeeId == model.NewManagerId.Value)
                    {
                        TempData["ErrorMessage"] = "Cannot set employee as their own manager.";
                        TempData["ErrorRowId"] = model.EmployeeId;
                        return RedirectToAction(nameof(ManageLevels));
                    }

                    // 2. Prevent circular hierarchy
                    bool cycle = await _hierarchyService.WouldCreateCycleAsync(model.EmployeeId, model.NewManagerId.Value);
                    if (cycle)
                    {
                        TempData["ErrorMessage"] = "Cannot assign to a subordinate (Circular Hierarchy detected).";
                        TempData["ErrorRowId"] = model.EmployeeId;
                        return RedirectToAction(nameof(ManageLevels));
                    }
                }

                // If nothing changed
                if (!model.NewManagerId.HasValue && !model.NewDepartmentId.HasValue)
                {
                     TempData["ErrorMessage"] = "No changes selected.";
                     TempData["ErrorRowId"] = model.EmployeeId;
                     return RedirectToAction(nameof(ManageLevels));
                }

                // Update the employee's manager and department
                await _hierarchyService.ReassignEmployeeAsync(model.EmployeeId, model.NewDepartmentId, model.NewManagerId);
                
                // Rebuild hierarchy table to reflect changes
                await _hierarchyService.RebuildHierarchyTableAsync();
                
                TempData["SuccessMessage"] = "Employee updated successfully.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error reassigning employee: {ex.Message}";
                TempData["ErrorRowId"] = model.EmployeeId;
            }
            return RedirectToAction(nameof(ManageLevels));
        }
    }
}
