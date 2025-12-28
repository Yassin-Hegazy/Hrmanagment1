using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize(Roles = "SuperAdmin,SystemAdmin,HRAdmin")]
    public class ExceptionController : Controller
    {
        private readonly IExceptionService _exceptionService;
        private readonly IAttendanceService _attendanceService;

        public ExceptionController(
            IExceptionService exceptionService,
            IAttendanceService attendanceService)
        {
            _exceptionService = exceptionService;
            _attendanceService = attendanceService;
        }

        // GET: Exception
        public async Task<IActionResult> Index(string? category = null)
        {
            IEnumerable<ExceptionDay> exceptions;

            if (!string.IsNullOrEmpty(category))
            {
                exceptions = await _exceptionService.GetExceptionsByCategoryAsync(category);
                ViewBag.SelectedCategory = category;
            }
            else
            {
                exceptions = await _exceptionService.GetAllExceptionsAsync();
            }

            return View(exceptions);
        }

        // GET: Exception/Create
        public IActionResult Create()
        {
            return View();
        }

        // POST: Exception/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ExceptionDay exception)
        {
            try
            {
                if (ModelState.IsValid)
                {
                    var exceptionId = await _exceptionService.CreateExceptionAsync(exception);
                    
                    // Auto-apply to attendance records for that date
                    await _attendanceService.ApplyExceptionToAttendanceAsync(exceptionId, exception.Date);
                    
                    TempData["SuccessMessage"] = $"Exception '{exception.Name}' created and applied successfully!";
                    return RedirectToAction(nameof(Index));
                }
            }
            catch (System.Exception ex)
            {
                TempData["ErrorMessage"] = $"Error creating exception: {ex.Message}";
            }

            return View(exception);
        }

        // GET: Exception/Edit/5
        public async Task<IActionResult> Edit(int id)
        {
            var exception = await _exceptionService.GetExceptionByIdAsync(id);
            if (exception == null)
            {
                return NotFound();
            }

            return View(exception);
        }

        // POST: Exception/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, ExceptionDay exception)
        {
            if (id != exception.ExceptionId)
            {
                return BadRequest();
            }

            try
            {
                if (ModelState.IsValid)
                {
                    await _exceptionService.UpdateExceptionAsync(exception);
                    TempData["SuccessMessage"] = "Exception updated successfully!";
                    return RedirectToAction(nameof(Index));
                }
            }
            catch (System.Exception ex)
            {
                TempData["ErrorMessage"] = $"Error updating exception: {ex.Message}";
            }

            return View(exception);
        }

        // POST: Exception/Delete/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                await _exceptionService.DeleteExceptionAsync(id);
                TempData["SuccessMessage"] = "Exception deleted successfully!";
            }
            catch (System.Exception ex)
            {
                TempData["ErrorMessage"] = $"Error deleting exception: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // GET: Exception/Calendar
        public async Task<IActionResult> Calendar(int? year = null, int? month = null)
        {
            var currentYear = year ?? DateTime.Now.Year;
            var currentMonth = month ?? DateTime.Now.Month;

            var startDate = new DateTime(currentYear, currentMonth, 1);
            var endDate = startDate.AddMonths(1).AddDays(-1);

            var exceptions = await _exceptionService.GetExceptionsByDateRangeAsync(startDate, endDate);

            ViewBag.Year = currentYear;
            ViewBag.Month = currentMonth;
            ViewBag.MonthName = startDate.ToString("MMMM yyyy");

            return View(exceptions);
        }

        // POST: Exception/ApplyToDate
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ApplyToDate(int exceptionId, DateTime date)
        {
            try
            {
                await _attendanceService.ApplyExceptionToAttendanceAsync(exceptionId, date);
                TempData["SuccessMessage"] = "Exception applied to attendance records successfully!";
            }
            catch (System.Exception ex)
            {
                TempData["ErrorMessage"] = $"Error applying exception: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
