using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize(Roles = "SuperAdmin,SystemAdmin,HRAdmin,Manager")]
    public class ShiftController : Controller
    {
        private readonly IShiftService _shiftService;
        private readonly IEmployeeService _employeeService;
        private readonly IDepartmentService _departmentService;

        public ShiftController(
            IShiftService shiftService, 
            IEmployeeService employeeService,
            IDepartmentService departmentService)
        {
            _shiftService = shiftService;
            _employeeService = employeeService;
            _departmentService = departmentService;
        }

        // GET: Shift
        public async Task<IActionResult> Index()
        {
            var shifts = await _shiftService.GetAllShiftsAsync();
            return View(shifts);
        }

        // GET: Shift/Create
        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public IActionResult Create()
        {
            return View();
        }

        // POST: Shift/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public async Task<IActionResult> Create(ShiftSchedule shift)
        {
            try
            {
                if (ModelState.IsValid)
                {
                    await _shiftService.CreateShiftAsync(shift);
                    TempData["SuccessMessage"] = "Shift created successfully!";
                    return RedirectToAction(nameof(Index));
                }
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error creating shift: {ex.Message}";
            }
            return View(shift);
        }

        // GET: Shift/Assign
        [Authorize(Roles = "SuperAdmin,SystemAdmin,HRAdmin,Manager")]
        public async Task<IActionResult> Assign()
        {
            // Populate dropdowns
            var shifts = await _shiftService.GetAllShiftsAsync();
            var employees = await _employeeService.GetAllEmployeesAsync();
            var departments = await _departmentService.GetAllDepartmentsAsync();

            ViewBag.Shifts = shifts;
            ViewBag.Employees = employees;
            ViewBag.Departments = departments;

            return View();
        }

        // POST: Shift/Assign
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,SystemAdmin,HRAdmin,Manager")]
        public async Task<IActionResult> Assign(
            string assignmentType, 
            int? departmentId, 
            int? employeeId, 
            int shiftId, 
            DateTime startDate, 
            DateTime? endDate)
        {
            try
            {
                if (assignmentType == "Department" && departmentId.HasValue)
                {
                    await _shiftService.AssignShiftToDepartmentAsync(departmentId.Value, shiftId, startDate, endDate);
                    TempData["SuccessMessage"] = "Shift assigned to department successfully!";
                }
                else if (assignmentType == "Employee" && employeeId.HasValue)
                {
                    await _shiftService.AssignShiftToEmployeeAsync(employeeId.Value, shiftId, startDate, endDate);
                    TempData["SuccessMessage"] = "Shift assigned to employee successfully!";
                }
                else
                {
                    TempData["ErrorMessage"] = "Please select a valid department or employee.";
                }
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error assigning shift: {ex.Message}";
            }

            return RedirectToAction(nameof(Assign));
        }

        // ====================================================================
        // ADVANCED SHIFT FEATURES
        // ====================================================================

        // GET: Shift/ConfigureSplitShift
        [Authorize(Roles = "SuperAdmin,HRAdmin")]
        public IActionResult ConfigureSplitShift()
        {
            return View();
        }

        // POST: Shift/ConfigureSplitShift
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,HRAdmin")]
        public async Task<IActionResult> ConfigureSplitShift(
            string shiftName,
            TimeSpan firstSlotStart,
            TimeSpan firstSlotEnd,
            TimeSpan secondSlotStart,
            TimeSpan secondSlotEnd)
        {
            try
            {
                await _shiftService.ConfigureSplitShiftAsync(shiftName, firstSlotStart, firstSlotEnd, secondSlotStart, secondSlotEnd);
                TempData["SuccessMessage"] = "Split shift configured successfully!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error configuring split shift: {ex.Message}";
                return View();
            }
        }

        // GET: Shift/ConfigureRotational
        [Authorize(Roles = "SuperAdmin,HRAdmin")]
        public async Task<IActionResult> ConfigureRotational()
        {
            var employees = await _employeeService.GetAllEmployeesAsync();
            ViewBag.Employees = employees;
            return View();
        }

        // POST: Shift/ConfigureRotational
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,HRAdmin")]
        public async Task<IActionResult> ConfigureRotational(
            int employeeId,
            int shiftCycle,
            DateTime startDate,
            DateTime endDate,
            string status = "Active")
        {
            try
            {
                await _shiftService.AssignRotationalShiftAsync(employeeId, shiftCycle, startDate, endDate, status);
                TempData["SuccessMessage"] = "Rotational shift assigned successfully!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error assigning rotational shift: {ex.Message}";
                return RedirectToAction(nameof(ConfigureRotational));
            }
        }

        // GET: Shift/AssignCustom
        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public async Task<IActionResult> AssignCustom()
        {
            var employees = await _employeeService.GetAllEmployeesAsync();
            ViewBag.Employees = employees;
            return View();
        }

        // POST: Shift/AssignCustom
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,SystemAdmin")]
        public async Task<IActionResult> AssignCustom(
            int employeeId,
            string shiftName,
            string shiftType,
            TimeSpan startTime,
            TimeSpan endTime,
            DateTime startDate,
            DateTime endDate)
        {
            try
            {
                await _shiftService.AssignCustomShiftAsync(employeeId, shiftName, shiftType, startTime, endTime, startDate, endDate);
                TempData["SuccessMessage"] = "Custom shift assigned successfully!";
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error assigning custom shift: {ex.Message}";
                return RedirectToAction(nameof(AssignCustom));
            }
        }
    }
}
