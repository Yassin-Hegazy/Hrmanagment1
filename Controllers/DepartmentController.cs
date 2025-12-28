using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize(Roles = "SuperAdmin,HRAdmin,Manager")] // Only admins can manage departments
    public class DepartmentController : Controller
    {
        private readonly IDepartmentService _departmentService;
        private readonly IEmployeeService _employeeService;

        public DepartmentController(IDepartmentService departmentService, IEmployeeService employeeService)
        {
            _departmentService = departmentService;
            _employeeService = employeeService;
        }

        // GET: Department
        public async Task<IActionResult> Index()
        {
            var departments = await _departmentService.GetAllDepartmentsAsync();
            return View(departments);
        }

        // GET: Department/Details/5
        public async Task<IActionResult> Details(int id)
        {
            var department = await _departmentService.GetDepartmentByIdAsync(id);

            if (department == null)
            {
                return NotFound();
            }

            // Get employees in this department
            var employees = await _departmentService.GetDepartmentEmployeesAsync(id);
            ViewBag.Employees = employees;

            return View(department);
        }

        // GET: Department/Create
        public async Task<IActionResult> Create()
        {
            // Populate employee dropdown for Department Head selection
            var employees = await _employeeService.GetAllEmployeesAsync();
            ViewBag.Employees = new Microsoft.AspNetCore.Mvc.Rendering.SelectList(
                employees.Select(e => new { 
                    Value = e.EmployeeId, 
                    Text = $"{e.FullName} (ID: {e.EmployeeId})" 
                }),
                "Value",
                "Text"
            );
            
            return View();
        }

        // POST: Department/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Department department)
        {
            try
            {
                if (ModelState.IsValid)
                {
                    var newId = await _departmentService.AddDepartmentAsync(department);
                    
                    if (newId > 0)
                    {
                        TempData["SuccessMessage"] = "Department created successfully!";
                        return RedirectToAction(nameof(Index));
                    }
                }

                TempData["ErrorMessage"] = "Failed to create department. Please check the form and try again.";
                return View(department);
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                return View(department);
            }
        }

        // GET: Department/Edit/5
        public async Task<IActionResult> Edit(int id)
        {
            var department = await _departmentService.GetDepartmentByIdAsync(id);

            if (department == null)
            {
                return NotFound();
            }

            // Populate employee dropdown for Department Head selection
            var employees = await _employeeService.GetAllEmployeesAsync();
            ViewBag.Employees = new Microsoft.AspNetCore.Mvc.Rendering.SelectList(
                employees.Select(e => new { 
                    Value = e.EmployeeId, 
                    Text = $"{e.FullName} (ID: {e.EmployeeId})" 
                }),
                "Value",
                "Text",
                department.DepartmentHeadId // Pre-select current head
            );

            return View(department);
        }

        // POST: Department/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Department department)
        {
            if (id != department.DepartmentId)
            {
                return BadRequest();
            }

            try
            {
                if (ModelState.IsValid)
                {
                    await _departmentService.UpdateDepartmentAsync(department);
                    TempData["SuccessMessage"] = "Department updated successfully!";
                    return RedirectToAction(nameof(Details), new { id });
                }

                return View(department);
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                return View(department);
            }
        }

        // POST: Department/AssignHead
        [HttpPost]
        public async Task<IActionResult> AssignHead(int departmentId, int employeeId)
        {
            try
            {
                await _departmentService.AssignDepartmentHeadAsync(departmentId, employeeId);
                TempData["SuccessMessage"] = "Department head assigned successfully!";
                return RedirectToAction(nameof(Details), new { id = departmentId });
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                return RedirectToAction(nameof(Details), new { id = departmentId });
            }
        }
    }
}
