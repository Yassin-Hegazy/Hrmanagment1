using HRMANGMANGMENT.Data;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    public class DiagnosticsController : Controller
    {
        private readonly IConfiguration _configuration;

        public DiagnosticsController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public async Task<IActionResult> TestConnection()
        {
            var connectionString = _configuration.GetConnectionString("HRDatabase");
            
            if (string.IsNullOrEmpty(connectionString))
            {
                ViewBag.Error = "Connection string 'HRDatabase' not found in configuration.";
                return View();
            }

            ViewBag.ConnectionString = MaskPassword(connectionString);

            // Test basic connection
            var (success, message) = await ConnectionTester.TestConnectionAsync(connectionString);
            ViewBag.ConnectionSuccess = success;
            ViewBag.ConnectionMessage = message;

            if (success)
            {
                // Test if HRFINAL database exists
                var (dbExists, dbMessage) = await ConnectionTester.TestDatabaseExistsAsync(connectionString, "HRFINAL");
                ViewBag.DatabaseExists = dbExists;
                ViewBag.DatabaseMessage = dbMessage;
            }

            return View();
        }

        private string MaskPassword(string connectionString)
        {
            // Mask password in connection string for display
            if (connectionString.Contains("Password=", StringComparison.OrdinalIgnoreCase))
            {
                var parts = connectionString.Split(';');
                for (int i = 0; i < parts.Length; i++)
                {
                    if (parts[i].Trim().StartsWith("Password=", StringComparison.OrdinalIgnoreCase))
                    {
                        parts[i] = "Password=*****";
                    }
                }
                return string.Join(";", parts);
            }
            return connectionString;
        }
    }
}
