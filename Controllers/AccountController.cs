// ============================================================================
// ACCOUNT CONTROLLER - HANDLES USER AUTHENTICATION (LOGIN/REGISTER/LOGOUT)
// ============================================================================
// This controller manages user authentication - how users prove who they are.
// It handles:
// - Login (sign in)
// - Logout (sign out)
// - Register (create new admin accounts)
// - Activate Account (for existing employees to set their password)
// - Access Denied (when user doesn't have permission)
//
// KEY CONCEPTS:
// - Claims: Pieces of information about the logged-in user
// - Cookie Authentication: Storing login state in browser cookies
// - [AllowAnonymous]: Allows access without being logged in
// ============================================================================

using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HRMANGMANGMENT.Controllers
{
    // ========================================================================
    // [AllowAnonymous] ATTRIBUTE
    // ========================================================================
    // This is the opposite of [Authorize].
    // Normally our app requires login for all pages (see Program.cs FallbackPolicy)
    // [AllowAnonymous] says "anyone can access this controller, even without logging in"
    // 
    // This makes sense because:
    // - Users need to access Login page BEFORE they're logged in!
    // - Same for Register and ActivateAccount
    [AllowAnonymous]
    public class AccountController : Controller
    {
        // ====================================================================
        // DEPENDENCY INJECTION
        // ====================================================================
        // These services are injected by ASP.NET's DI container
        private readonly IAuthService _authService;        // Handles password hashing, verification
        private readonly IEmployeeService _employeeService; // Handles employee data
        private readonly IRoleService _roleService;         // Handles roles

        public AccountController(
            IAuthService authService,
            IEmployeeService employeeService,
            IRoleService roleService)
        {
            _authService = authService;
            _employeeService = employeeService;
            _roleService = roleService;
        }

        // ====================================================================
        // LOGIN (GET) - SHOW THE LOGIN FORM
        // ====================================================================
        // URL: GET /Account/Login
        //
        // [HttpGet] = only responds to GET requests (browser navigating to page)
        // 
        // returnUrl parameter: When user tries to access a protected page while
        // not logged in, ASP.NET adds ?returnUrl=/that/page to the login URL.
        // After successful login, we redirect them back to that page.
        [HttpGet]
        public IActionResult Login(string? returnUrl = null)
        {
            // ViewData = dictionary for passing data to the View
            // Similar to ViewBag but uses string keys
            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        // ====================================================================
        // LOGIN (POST) - PROCESS LOGIN FORM SUBMISSION
        // ====================================================================
        // URL: POST /Account/Login
        //
        // [HttpPost] = only responds to POST requests (form submissions)
        // [ValidateAntiForgeryToken] = security against CSRF attacks
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(string email, string password, bool rememberMe, string? returnUrl = null)
        {
            ViewData["ReturnUrl"] = returnUrl;

            // Validate input
            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
            {
                TempData["ErrorMessage"] = "Email and password are required.";
                return View();
            }

            // ================================================================
            // AUTHENTICATE THE USER
            // ================================================================
            // AuthenticateAsync checks:
            // 1. Does this email exist?
            // 2. Is the account locked?
            // 3. Does the password match?
            // Returns the employee if successful, null if not
            var employee = await _authService.AuthenticateAsync(email, password);

            if (employee == null)
            {
                TempData["ErrorMessage"] = "Invalid email or password, or account is locked.";
                return View();
            }

            // ================================================================
            // CREATE CLAIMS
            // ================================================================
            // Claims are pieces of information about the user that we want to
            // remember after they log in. They're stored in the auth cookie.
            //
            // IMPORTANT: An employee can have MULTIPLE roles!
            // We add a separate Role claim for EACH role they have.
            // User.IsInRole("Manager") will check if ANY of their roles match.
            var claims = new List<Claim>
            {
                // Unique identifier - used to know which employee this is
                new Claim(ClaimTypes.NameIdentifier, employee.EmployeeId.ToString()),
                
                // Display name - shown in UI "Welcome, John Doe"
                new Claim(ClaimTypes.Name, employee.FullName ?? $"{employee.FirstName} {employee.LastName}"),
                
                // Email - for reference
                new Claim(ClaimTypes.Email, employee.Email ?? string.Empty)
            };
            
            // ================================================================
            // ADD MULTIPLE ROLE CLAIMS
            // ================================================================
            // Get ALL roles for this employee from the Employee_Role table
            // An employee might be both "Manager" AND "HRAdmin"
            var roleNames = await _employeeService.GetEmployeeRoleNamesAsync(employee.EmployeeId);
            foreach (var roleName in roleNames)
            {
                claims.Add(new Claim(ClaimTypes.Role, roleName));
            }

            // ================================================================
            // CREATE CLAIMS IDENTITY AND AUTHENTICATION PROPERTIES
            // ================================================================
            // ClaimsIdentity = the collection of claims for this user
            // CookieAuthenticationDefaults.AuthenticationScheme = we're using cookies
            var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            
            // Authentication properties = how the cookie behaves
            var authProperties = new AuthenticationProperties
            {
                // IsPersistent = should cookie survive browser restart?
                // If "Remember Me" is checked, cookie lasts 30 days
                // If not checked, cookie is deleted when browser closes
                IsPersistent = rememberMe,
                
                // When does the cookie expire?
                ExpiresUtc = rememberMe ? DateTimeOffset.UtcNow.AddDays(30) : DateTimeOffset.UtcNow.AddHours(8)
            };

            // ================================================================
            // SIGN IN THE USER
            // ================================================================
            // HttpContext.SignInAsync() creates the authentication cookie
            // and sends it to the user's browser.
            // After this, User.Identity.IsAuthenticated will be true!
            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,  // Which auth scheme
                new ClaimsPrincipal(claimsIdentity),               // The user's identity
                authProperties);                                    // Cookie settings

            TempData["SuccessMessage"] = $"Welcome back, {employee.FirstName}!";

            // ================================================================
            // REDIRECT AFTER LOGIN
            // ================================================================
            // If user was trying to access a specific page, send them there
            // Url.IsLocalUrl() = security check to prevent redirect attacks
            if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }

            // Default: go to home page
            return RedirectToAction("Index", "Home");
        }

        // ====================================================================
        // LOGOUT
        // ====================================================================
        // URL: POST /Account/Logout
        //
        // [Authorize] = must be logged in to log out (makes sense!)
        // [HttpPost] = POST only - prevents accidental logout via link click
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize]
        public async Task<IActionResult> Logout()
        {
            // SignOutAsync() removes the authentication cookie
            // After this, User.Identity.IsAuthenticated will be false
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            
            TempData["SuccessMessage"] = "You have been logged out successfully.";
            return RedirectToAction("Login");
        }

        // ====================================================================
        // REGISTER (GET) - SHOW REGISTRATION FORM
        // ====================================================================
        // URL: GET /Account/Register
        //
        // This is for creating ADMIN accounts (SuperAdmin, HRAdmin, Manager)
        // Regular employees are created by admins, not self-registration
        [HttpGet]
        public async Task<IActionResult> Register()
        {
            // Get all roles from database
            var allRoles = await _roleService.GetAllRolesAsync();
            
            // ================================================================
            // FILTER TO ADMIN ROLES ONLY
            // ================================================================
            // We don't want people to register as regular "Employee"
            // That would bypass HR's control over employee creation
            //
            // LINQ .Where() filters the list
            // .Contains() checks if string contains a substring
            // StringComparison.OrdinalIgnoreCase = ignore case
            var adminRoles = allRoles.Where(r => 
                r.RoleName != null && (
                    r.RoleName.Contains("System", StringComparison.OrdinalIgnoreCase) ||
                    r.RoleName.Contains("Super", StringComparison.OrdinalIgnoreCase) ||
                    r.RoleName.Contains("HR", StringComparison.OrdinalIgnoreCase) ||
                    r.RoleName.Contains("Line", StringComparison.OrdinalIgnoreCase) ||
                    r.RoleName.Contains("Manager", StringComparison.OrdinalIgnoreCase)
                )).ToList();
            
            ViewBag.Roles = adminRoles;
            return View();
        }

        // ====================================================================
        // REGISTER (POST) - PROCESS REGISTRATION
        // ====================================================================
        // URL: POST /Account/Register
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(Employee employee, string password, string confirmPassword, int roleId)
        {
            // Reload roles for the form (in case of validation error)
            var allRoles = await _roleService.GetAllRolesAsync();
            var adminRoles = allRoles.Where(r => 
                r.RoleName != null && (
                    r.RoleName.Contains("System", StringComparison.OrdinalIgnoreCase) ||
                    r.RoleName.Contains("Super", StringComparison.OrdinalIgnoreCase) ||
                    r.RoleName.Contains("HR", StringComparison.OrdinalIgnoreCase) ||
                    r.RoleName.Contains("Line", StringComparison.OrdinalIgnoreCase) ||
                    r.RoleName.Contains("Manager", StringComparison.OrdinalIgnoreCase)
                )).ToList();
            ViewBag.Roles = adminRoles;

            // ================================================================
            // SERVER-SIDE VALIDATION
            // ================================================================
            // Always validate on server! Client-side JS can be bypassed.
            
            if (string.IsNullOrEmpty(password) || password != confirmPassword)
            {
                TempData["ErrorMessage"] = "Passwords do not match.";
                return View(employee); // Re-show form with error
            }

            if (string.IsNullOrEmpty(employee.Email))
            {
                TempData["ErrorMessage"] = "Email is required.";
                return View(employee);
            }

            // Check for duplicate email
            var isUnique = await _authService.IsEmailUniqueAsync(employee.Email);
            if (!isUnique)
            {
                TempData["ErrorMessage"] = "Email is already registered.";
                return View(employee);
            }

            // ================================================================
            // HASH PASSWORD AND SET DEFAULTS
            // ================================================================
            employee.PasswordHash = _authService.HashPassword(password);
            employee.IsActive = true;
            employee.ProfileCompletion = 30; // Basic profile (more fields = higher %)

            try
            {
                // Create the employee record
                var newEmployeeId = await _employeeService.AddEmployeeAsync(employee);
                
                if (newEmployeeId > 0)
                {
                    // ========================================================
                    // ASSIGN ROLE
                    // ========================================================
                    // Our database has a many-to-many relationship:
                    // Employee <--> Employee_Role <--> Role
                    // One employee can have multiple roles (though usually just one)
                    await _employeeService.AssignRoleAsync(newEmployeeId, roleId);
                    
                    // Also insert into the role-specific subclass table
                    // (HRAdministrator, LineManager, etc.)
                    var selectedRole = allRoles.FirstOrDefault(r => r.RoleId == roleId);
                    if (selectedRole != null)
                    {
                        await _employeeService.InsertIntoRoleSubclassAsync(newEmployeeId, selectedRole.RoleName);
                    }
                    
                    TempData["SuccessMessage"] = "Account created successfully! You can now log in.";
                    return RedirectToAction("Login");
                }
                else
                {
                    TempData["ErrorMessage"] = "Failed to create account. Please try again.";
                    return View(employee);
                }
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error creating account: {ex.Message}";
                return View(employee);
            }
        }

        // ====================================================================
        // ACCESS DENIED PAGE
        // ====================================================================
        // URL: GET /Account/AccessDenied
        //
        // Shown when a logged-in user tries to access something they
        // don't have permission for. For example, an Employee trying
        // to access /Employee/Create (admin only)
        [HttpGet]
        public IActionResult AccessDenied()
        {
            return View();
        }

        // ====================================================================
        // ACTIVATE ACCOUNT (GET) - SHOW THE FORM
        // ====================================================================
        // URL: GET /Account/ActivateAccount
        //
        // For EXISTING employees who don't have a password yet.
        // Maybe they were added to the system before we had password hashing.
        [HttpGet]
        public IActionResult ActivateAccount()
        {
            return View();
        }

        // ====================================================================
        // ACTIVATE ACCOUNT (POST) - SET PASSWORD FOR EXISTING EMPLOYEE
        // ====================================================================
        // URL: POST /Account/ActivateAccount
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ActivateAccount(string email, string password, string confirmPassword)
        {
            // Validate input
            if (string.IsNullOrEmpty(email))
            {
                TempData["ErrorMessage"] = "Email is required.";
                return View();
            }

            if (string.IsNullOrEmpty(password) || password.Length < 6)
            {
                TempData["ErrorMessage"] = "Password must be at least 6 characters.";
                return View();
            }

            if (password != confirmPassword)
            {
                TempData["ErrorMessage"] = "Passwords do not match.";
                return View();
            }

            try
            {
                // Find the employee by email
                var employee = await _employeeService.GetEmployeeByEmailAsync(email);
                
                if (employee == null)
                {
                    TempData["ErrorMessage"] = "No employee found with this email address.";
                    return View();
                }

                // ============================================================
                // CHECK IF ALREADY HAS PASSWORD
                // ============================================================
                // BCrypt hashes start with "$2" (e.g., "$2a$12$...")
                // If they already have a BCrypt hash, they should use login instead
                if (!string.IsNullOrEmpty(employee.PasswordHash) && employee.PasswordHash.StartsWith("$2"))
                {
                    TempData["ErrorMessage"] = "This account already has a password. Please use the login page.";
                    return View();
                }

                // Hash the new password and save it
                var hashedPassword = _authService.HashPassword(password);
                await _authService.SetPasswordAsync(employee.EmployeeId, hashedPassword);

                TempData["SuccessMessage"] = "Account activated successfully! You can now log in.";
                return RedirectToAction("Login");
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error activating account: {ex.Message}";
                return View();
            }
        }
    }
}
