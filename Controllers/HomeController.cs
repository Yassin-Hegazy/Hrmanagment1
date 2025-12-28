using System.Diagnostics;
using HRMANGMANGMENT.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize] // Require authentication for all pages
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly Services.IEmployeeService _employeeService;

        public HomeController(ILogger<HomeController> logger, Services.IEmployeeService employeeService)
        {
            _logger = logger;
            _employeeService = employeeService;
        }

        public async Task<IActionResult> Index()
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (!string.IsNullOrEmpty(userId) && int.TryParse(userId, out int empId))
            {
                var employee = await _employeeService.GetEmployeeByIdAsync(empId);
                ViewBag.ProfileImage = employee?.ProfileImage;
            }
            return View();
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
