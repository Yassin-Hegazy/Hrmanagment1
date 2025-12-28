// ============================================================================
// EMPLOYEE CONTROLLER - HANDLES ALL EMPLOYEE-RELATED HTTP REQUESTS
// ============================================================================
// In ASP.NET MVC, Controllers are the "C" in MVC (Model-View-Controller).
// Controllers receive HTTP requests, process them, and return responses.
//
// NAMING CONVENTION:
// - Controller names must end with "Controller" (e.g., EmployeeController)
// - The URL uses the name without "Controller" (e.g., /Employee/Index)
//
// KEY CONCEPTS:
// 1. Actions - Public methods that handle specific URLs
// 2. IActionResult - The return type for actions (can be View, Redirect, JSON, etc.)
// 3. Attributes - Decorators that add behavior ([Authorize], [HttpPost], etc.)
// 4. Model Binding - Automatic conversion of form data to C# objects
// ============================================================================

using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace HRMANGMANGMENT.Controllers
{
    // ========================================================================
    // [Authorize] ATTRIBUTE
    // ========================================================================
    // Applied at CLASS level = ALL actions in this controller require login.
    // Without this, anyone could access these pages without logging in.
    // 
    // How it works:
    // 1. User makes request → ASP.NET checks if they're authenticated
    // 2. If not logged in → Redirect to LoginPath (set in Program.cs)
    // 3. If logged in → Allow access to the action
    [Authorize]
    public class EmployeeController : Controller
    {
        // ====================================================================
        // DEPENDENCY INJECTION (CONSTRUCTOR INJECTION)
        // ====================================================================
        // These are "injected" by ASP.NET's DI container.
        // We don't create these objects ourselves - ASP.NET creates them
        // and passes them to us via the constructor.
        //
        // readonly = can only be assigned in constructor, prevents accidental changes
        // _ prefix = common naming convention for private fields
        private readonly IEmployeeService _employeeService;
        private readonly IRoleService _roleService;
        private readonly IAuthService _authService;
        private readonly IDepartmentService _departmentService;
        private readonly IContractService _contractService;
        private readonly IPositionService _positionService;

        // ====================================================================
        // CONSTRUCTOR
        // ====================================================================
        // This runs when ASP.NET creates the controller.
        // ASP.NET automatically provides the services (thanks to DI in Program.cs)
        public EmployeeController(
            IEmployeeService employeeService,
            IRoleService roleService,
            IAuthService authService,
            IDepartmentService departmentService,
            IContractService contractService,
            IPositionService positionService)
        {
            // Store the injected services in private fields
            _employeeService = employeeService;
            _roleService = roleService;
            _authService = authService;
            _departmentService = departmentService;
            _contractService = contractService;
            _positionService = positionService;
        }

        // ====================================================================
        // INDEX ACTION - LIST ALL EMPLOYEES
        // ====================================================================
        // URL: GET /Employee or /Employee/Index
        // 
        // [Authorize(Roles = "...")] = Only users with these roles can access
        // Multiple roles are comma-separated: "SuperAdmin,HRAdmin,Manager"
        //
        // async Task<IActionResult> = This is an ASYNC method
        // async/await allows the server to handle other requests while
        // waiting for database operations (improves scalability)
        //
        // Admins AND Managers can view all employee profiles
        // Managers also have an extra "My Team" feature
        [Authorize(Roles = "SuperAdmin,HRAdmin,Manager")]
        public async Task<IActionResult> Index(string searchTerm)
        {
            // IEnumerable<Employee> = A collection of Employee objects
            IEnumerable<Employee> employees;

            // ================================================================
            // GETTING THE CURRENT USER'S ID FROM CLAIMS
            // ================================================================
            // When user logs in, we store their info in "Claims" (see AccountController)
            // ClaimTypes.NameIdentifier = The user's unique ID
            // 
            // User.FindFirst() searches through the claims
            // ?.Value = safely get the Value (null if not found)
            // ?? "0" = if null, use "0" as default
            var currentUserId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            // ================================================================
            // ALL ADMINS (including Managers) SEE ALL EMPLOYEES
            // ================================================================
            // The separate "My Team" action is for Managers to see only their direct reports
            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                // User is searching - filter by search term
                employees = await _employeeService.SearchEmployeesAsync(searchTerm);
                ViewBag.SearchTerm = searchTerm;
            }
            else
            {
                // Get all employees
                employees = await _employeeService.GetAllEmployeesAsync();
            }

            // ================================================================
            // RETURNING A VIEW
            // ================================================================
            // View(employees) does the following:
            // 1. Looks for a view file: Views/Employee/Index.cshtml
            //    (matches Controller name / Action name)
            // 2. Passes 'employees' as the Model to the view
            // 3. Renders the HTML and sends it to the browser
            return View(employees);
        }

        // ====================================================================
        // MY TEAM ACTION - VIEW MANAGER'S DIRECT REPORTS
        // ====================================================================
        // URL: GET /Employee/MyTeam
        [Authorize(Roles = "Manager")]
        public async Task<IActionResult> MyTeam()
        {
            var currentUserId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var teamMembers = await _employeeService.GetEmployeesByManagerIdAsync(currentUserId);

            ViewBag.IsTeamView = true;

            // View("Index", teamMembers) = use the Index.cshtml view but with team data
            // This reuses the Index view instead of creating a separate MyTeam view
            return View("Index", teamMembers);
        }

        // ====================================================================
        // DETAILS ACTION - VIEW SINGLE EMPLOYEE
        // ====================================================================
        // URL: GET /Employee/Details/5 (where 5 is the employee ID)
        // 
        // The 'id' parameter is automatically populated from the URL
        // This is called "Model Binding" - ASP.NET matches URL parts to parameters
        public async Task<IActionResult> Details(int id)
        {
            // Get employee from database
            var employee = await _employeeService.GetEmployeeByIdAsync(id);

            // NotFound() returns HTTP 404 - resource not found
            if (employee == null)
            {
                return NotFound();
            }

            // ================================================================
            // AUTHORIZATION CHECK - WHO CAN VIEW THIS PROFILE?
            // ================================================================
            // Security rule: Regular employees can only view their OWN profile
            // Admins can view ANY profile
            var currentUserId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var isAdmin = User.IsInRole("SuperAdmin") || User.IsInRole("HRAdmin") || User.IsInRole("Manager");

            if (!isAdmin && currentUserId != id)
            {
                // RedirectToAction = redirect user to a different action
                // Parameters: (action name, controller name)
                return RedirectToAction("AccessDenied", "Account");
            }

            return View(employee);
        }

        // ====================================================================
        // CREATE ACTION (GET) - SHOW THE CREATE FORM
        // ====================================================================
        // URL: GET /Employee/Create
        // 
        // ONLY SuperAdmin can create new employees!
        // HRAdmin can edit but NOT create.
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> Create()
        {
            // Load roles for the dropdown in the form
            var roles = await _roleService.GetAllRolesAsync();
            ViewBag.Roles = roles;
            
            ViewBag.Positions = await _positionService.GetAllPositionsAsync();

            // Show empty form
            return View();
        }

        // ====================================================================
        // CREATE ACTION (POST) - PROCESS THE FORM SUBMISSION
        // ====================================================================
        // URL: POST /Employee/Create
        //
        // [HttpPost] = This action only responds to POST requests
        // (GET requests go to the action above)
        //
        // [ValidateAntiForgeryToken] = Security measure against CSRF attacks
        // It checks that the form submission came from our own website,
        // not from a malicious site trying to trick the user.
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin")]  // Only SuperAdmin can create employees
        public async Task<IActionResult> Create(Employee employee, string password, string confirmPassword, int roleId, string? newPositionTitle = null)
        {
            // ================================================================
            // MODEL BINDING MAGIC!
            // ================================================================
            // The 'employee' parameter is automatically populated from form data!
            // ASP.NET matches form field names to Employee properties:
            //   <input name="FirstName"> → employee.FirstName
            //   <input name="Email"> → employee.Email
            //   etc.

            var roles = await _roleService.GetAllRolesAsync();
            ViewBag.Roles = roles;
            ViewBag.Positions = await _positionService.GetAllPositionsAsync();

            try
            {
                // Handle new position logic
                if (!string.IsNullOrWhiteSpace(newPositionTitle))
                {
                     var newPos = new Position { PositionTitle = newPositionTitle, Status = "Active" };
                     var newPosId = await _positionService.AddPositionAsync(newPos);
                     employee.PositionId = newPosId;
                }
                // ============================================================
                // VALIDATION
                // ============================================================
                // Always validate user input on the server, even if you have
                // client-side (JavaScript) validation. Users can bypass JS!

                if (string.IsNullOrEmpty(password) || password != confirmPassword)
                {
                    // TempData = data that survives ONE redirect
                    // Used for showing messages after a redirect
                    TempData["ErrorMessage"] = "Passwords do not match.";
                    return View(employee); // Return form with error, keep user's input
                }

                if (string.IsNullOrEmpty(employee.Email))
                {
                    TempData["ErrorMessage"] = "Email is required.";
                    return View(employee);
                }

                // Check if email already exists (no duplicate accounts)
                var isUnique = await _authService.IsEmailUniqueAsync(employee.Email);
                if (!isUnique)
                {
                    TempData["ErrorMessage"] = "Email is already registered.";
                    return View(employee);
                }

                // Get who is creating this employee (for audit trail)
                var currentUserId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                // ============================================================
                // HASH THE PASSWORD
                // ============================================================
                // NEVER store plain text passwords!
                // BCrypt creates a secure hash that can't be reversed
                var hashedPassword = _authService.HashPassword(password);

                // Create the employee in the database
                var newId = await _employeeService.CreateEmployeeByAdminAsync(employee, hashedPassword, roleId, currentUserId);

                if (newId > 0)
                {
                    TempData["SuccessMessage"] = "Employee created successfully!";

                    // nameof(Details) = "Details" (type-safe way to reference action name)
                    // new { id = newId } = route parameter (creates URL like /Employee/Details/5)
                    return RedirectToAction(nameof(Details), new { id = newId });
                }

                TempData["ErrorMessage"] = "Failed to create employee.";
                return View(employee);
            }
            catch (Exception ex)
            {
                // Log the exception (in production, use proper logging)
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                return View(employee);
            }
        }

        // ====================================================================
        // EDIT ACTION (GET) - SHOW THE EDIT FORM
        // ====================================================================
        // URL: GET /Employee/Edit/5
        public async Task<IActionResult> Edit(int id)
        {
            var employee = await _employeeService.GetEmployeeWithRoleDetailsAsync(id);

            if (employee == null)
            {
                return NotFound();
            }

            // ================================================================
            // PERMISSION CHECK
            // ================================================================
            // Uses a service method to check permissions (cleaner than inline logic)
            var currentUserId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var canEdit = await _employeeService.CanEditEmployeeAsync(currentUserId, id);

            // RESTRICTION: SuperAdmin cannot edit OTHER employees' personal details
            // BUT they can now edit Admin Attributes.
            // We allow access but the View will disable personal fields.
            
            // Allow access if admin or self
            if (!canEdit) 
            {
               TempData["ErrorMessage"] = "You do not have permission to edit this profile.";
               return RedirectToAction("AccessDenied", "Account");
            }
            
            var isSuperAdmin = User.IsInRole("SuperAdmin");
            var isEditingOther = currentUserId != id;

            // RESTRICTION: SuperAdmin cannot edit OTHER employees' personal details via this view
            if (isSuperAdmin && isEditingOther)
            {
                // Redirect to ManageAttributes page instead
                return RedirectToAction("ManageAttributes", new { id = id });
            }

            var isHRAdmin = User.IsInRole("HRAdmin") || isSuperAdmin;
            ViewBag.IsHRAdmin = isHRAdmin;
            ViewBag.IsSuperAdmin = isSuperAdmin;
            ViewBag.CurrentUserId = currentUserId;

            if (isHRAdmin)
            {
                var roles = await _roleService.GetAllRolesAsync();
                ViewBag.Roles = roles;
            }

            return View(employee);
        }

        // ====================================================================
        // EDIT ACTION (POST) - PROCESS THE EDIT FORM
        // ====================================================================
        // URL: POST /Employee/Edit/5
        //
        // IFormFile? profilePicture = handles file uploads
        // The ? makes it nullable (optional - user might not upload a file)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Employee employee, IFormFile? profilePicture)
        {
            // Security check: ensure URL id matches form employee id
            if (id != employee.EmployeeId)
            {
                return BadRequest(); // HTTP 400 - Bad Request
            }

            // Permission check
            var currentUserId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var canEdit = await _employeeService.CanEditEmployeeAsync(currentUserId, id);

            // RESTRICTION: SuperAdmin can access but logic must respect disabled fields
            // Logic handled by binding: if fields are disabled, they might not bind or bind null?
            // Actually, HTML disabled fields are NOT submitted.
            // So we must fetch current values for personal fields if SuperAdmin is editing someone else.
            
            var isSuperAdmin = User.IsInRole("SuperAdmin");
            var isEditingOther = currentUserId != id;

            try
            {
                var currentEmployee = await _employeeService.GetEmployeeWithRoleDetailsAsync(id);

                if (isSuperAdmin && isEditingOther)
                {
                    // Restore personal fields from DB because they were disabled in UI
                    employee.FirstName = currentEmployee.FirstName;
                    employee.LastName = currentEmployee.LastName;
                    employee.Email = currentEmployee.Email; 
                    employee.Phone = currentEmployee.Phone;
                    employee.DateOfBirth = currentEmployee.DateOfBirth;
                    employee.CountryOfBirth = currentEmployee.CountryOfBirth;
                    employee.NationalId = currentEmployee.NationalId;
                    employee.Address = currentEmployee.Address;
                    employee.EmergencyContactName = currentEmployee.EmergencyContactName;
                    employee.EmergencyContactPhone = currentEmployee.EmergencyContactPhone;
                    employee.Relationship = currentEmployee.Relationship;
                    employee.Biography = currentEmployee.Biography;
                    // Keep existing profile image
                    employee.ProfileImage = currentEmployee.ProfileImage;
                }
                else 
                {
                    // Regular update logic for Profile Picture
                     if (profilePicture != null && profilePicture.Length > 0)
                    {
                        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "profiles");
                        Directory.CreateDirectory(uploadsFolder);
                        var uniqueFileName = $"{id}_{Guid.NewGuid()}{Path.GetExtension(profilePicture.FileName)}";
                        var filePath = Path.Combine(uploadsFolder, uniqueFileName);
                        using (var fileStream = new FileStream(filePath, FileMode.Create))
                        {
                            await profilePicture.CopyToAsync(fileStream);
                        }
                        employee.ProfileImage = uniqueFileName;
                    }
                    else
                    {
                        employee.ProfileImage = currentEmployee?.ProfileImage;
                    }
                }

                // Update the employee in the database
                await _employeeService.UpdateEmployeeProfileAsync(currentUserId, employee);

                // HR Admins can update additional Role data
                if (User.IsInRole("HRAdmin") || User.IsInRole("SuperAdmin"))
                {
                    await _employeeService.UpdateRoleSpecificDataAsync(currentUserId, employee);
                }

                TempData["SuccessMessage"] = "Profile updated successfully!";
                return RedirectToAction(nameof(Details), new { id });
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                return View(employee);
            }
        }

        // ====================================================================
        // MANAGE ROLES ACTION (GET) - SHOW ROLE ASSIGNMENT FORM
        // ====================================================================
        // URL: GET /Employee/ManageRoles/5
        // Only SuperAdmin can assign roles to employees
        [Authorize(Roles = "SuperAdmin,Super Admin")]
        public async Task<IActionResult> ManageRoles(int id)
        {
            var employee = await _employeeService.GetEmployeeWithRoleDetailsAsync(id);

            if (employee == null)
            {
                return NotFound();
            }

            // Get all available roles
            var allRoles = await _roleService.GetAllRolesAsync();
            ViewBag.AllRoles = allRoles;

            // Get current roles for this employee
            var currentRoleNames = await _employeeService.GetEmployeeRoleNamesAsync(id);
            ViewBag.CurrentRoles = currentRoleNames;

            return View(employee);
        }

        // ====================================================================
        // MANAGE ROLES ACTION (POST) - SAVE ROLE CHANGES
        // ====================================================================
        // URL: POST /Employee/ManageRoles/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,Super Admin")]
        public async Task<IActionResult> ManageRoles(int id, int[] selectedRoles)
        {
            var employee = await _employeeService.GetEmployeeWithRoleDetailsAsync(id);

            if (employee == null)
            {
                return NotFound();
            }

            try
            {
                // Get current role IDs
                var currentRoleIds = await _employeeService.GetEmployeeRolesAsync(id);
                var currentRoleIdList = currentRoleIds.ToList();

                // Remove roles that are no longer selected
                foreach (var roleId in currentRoleIdList)
                {
                    if (!selectedRoles.Contains(roleId))
                    {
                        await _employeeService.RemoveRoleAsync(id, roleId);
                    }
                }

                // Add newly selected roles
                foreach (var roleId in selectedRoles)
                {
                    if (!currentRoleIdList.Contains(roleId))
                    {
                        await _employeeService.AssignRoleAsync(id, roleId);

                        // Also insert into role subclass table
                        var role = (await _roleService.GetAllRolesAsync()).FirstOrDefault(r => r.RoleId == roleId);
                        if (role != null)
                        {
                            await _employeeService.InsertIntoRoleSubclassAsync(id, role.RoleName);
                        }
                    }
                }

                TempData["SuccessMessage"] = "Roles updated successfully!";
                return RedirectToAction(nameof(Details), new { id });
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error updating roles: {ex.Message}";

                var allRoles = await _roleService.GetAllRolesAsync();
                ViewBag.AllRoles = allRoles;
                var currentRoleNames = await _employeeService.GetEmployeeRoleNamesAsync(id);
                ViewBag.CurrentRoles = currentRoleNames;

                return View(employee);
            }
        }

        // ====================================================================
        // MANAGE ATTRIBUTES (GET) - SHOW ALL EDITABLE FIELDS
        // ====================================================================
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> ManageAttributes(int id)
        {
            var employee = await _employeeService.GetEmployeeByIdAsync(id);
            if (employee == null) return NotFound();

            ViewBag.Departments = await _departmentService.GetAllDepartmentsAsync();
            ViewBag.Contracts = await _contractService.GetAllContractsAsync();

            return View(employee);
        }

        // ====================================================================
        // UPDATE ATTRIBUTE (POST) - SINGLE FIELD UPDATE
        // ====================================================================
        [HttpPost]
        [Authorize(Roles = "HRAdmin")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateAttribute(int employeeId, string fieldName, string newValue)
        {
            try
            {
                await _employeeService.UpdateProfileFieldAsync(employeeId, fieldName, newValue);
                TempData["SuccessMessage"] = $"Updated {fieldName} successfully!";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error updating {fieldName}: {ex.Message}";
            }
            return RedirectToAction(nameof(ManageAttributes), new { id = employeeId });
        }
    }
}

