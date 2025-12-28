// ============================================================================
// PROGRAM.CS - THE ENTRY POINT OF YOUR ASP.NET CORE APPLICATION
// ============================================================================
// This file is the starting point of your web application. Think of it as the
// "main()" function in traditional programming. It sets up everything your
// application needs to run.
//
// KEY CONCEPTS IN THIS FILE:
// 1. Dependency Injection (DI) - How services are registered and shared
// 2. Middleware Pipeline - How HTTP requests flow through your app
// 3. Authentication/Authorization - How users are verified and permissions checked
// ============================================================================

using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authentication.Cookies;

// ============================================================================
// PART 1: CREATING THE APPLICATION BUILDER
// ============================================================================
// WebApplication.CreateBuilder() creates a builder object that we use to 
// configure our application before it starts running.
// "args" are command-line arguments passed to the application.
var builder = WebApplication.CreateBuilder(args);

// ============================================================================
// PART 2: REGISTERING SERVICES (DEPENDENCY INJECTION)
// ============================================================================
// Dependency Injection (DI) is a design pattern where objects receive their
// dependencies rather than creating them. This makes code more testable and 
// maintainable.
//
// Think of it like a restaurant: Instead of the chef going to buy ingredients,
// the ingredients are delivered to the kitchen. The chef just works with what's
// provided.

// AddControllersWithViews() registers the MVC framework:
// - Controllers: C# classes that handle HTTP requests (like EmployeeController)
// - Views: Razor (.cshtml) files that generate HTML
builder.Services.AddControllersWithViews();

// ============================================================================
// AUTHORIZATION POLICIES
// ============================================================================
// Authorization determines WHAT a user can do after they've logged in.
// FallbackPolicy = what happens when no specific policy is set
// RequireAuthenticatedUser() = user must be logged in to access ANY page
// This means: if someone tries to access any page without logging in,
// they'll be redirected to the login page.
builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new Microsoft.AspNetCore.Authorization.AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()  // Every page requires login by default
        .Build();
});

// ============================================================================
// SESSION CONFIGURATION
// ============================================================================
// Sessions store user data on the SERVER between HTTP requests.
// HTTP is "stateless" - each request is independent. Sessions add state.
// Example: Shopping cart contents, user preferences, etc.
builder.Services.AddDistributedMemoryCache();  // Store session data in memory
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(8);  // Session expires after 8 hours of inactivity
    options.Cookie.HttpOnly = true;               // JavaScript cannot access this cookie (security)
    options.Cookie.IsEssential = true;            // Cookie works even if user doesn't accept cookies
});

// ============================================================================
// AUTHENTICATION CONFIGURATION
// ============================================================================
// Authentication determines WHO the user is (login/logout).
// "Cookie Authentication" means we store a cookie in the user's browser
// that proves they've logged in successfully.
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        // Where to redirect if user is not logged in:
        options.LoginPath = "/Account/Login";
        
        // Where to redirect when user logs out:
        options.LogoutPath = "/Account/Logout";
        
        // Where to redirect if user is logged in but doesn't have permission:
        options.AccessDeniedPath = "/Account/AccessDenied";
        
        // How long the login cookie lasts:
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        
        // SlidingExpiration = reset the timer each time user makes a request:
        options.SlidingExpiration = true;
        
        // Name of the cookie stored in browser:
        options.Cookie.Name = "HRManagement.Auth";
        
        // HttpOnly = JavaScript cannot read this cookie (prevents XSS attacks):
        options.Cookie.HttpOnly = true;
        
        // Essential = cookie is required for site to work:
        options.Cookie.IsEssential = true;
    });

// ============================================================================
// REGISTERING CUSTOM SERVICES (DEPENDENCY INJECTION)
// ============================================================================
// AddScoped<Interface, Implementation>() tells ASP.NET:
// "When someone asks for IEmployeeService, give them an EmployeeService object"
//
// Scoped = a new instance is created for each HTTP request, then disposed.
// This is perfect for database operations - one connection per request.
//
// Other lifetimes:
// - Singleton: One instance for the entire application
// - Transient: New instance every time it's requested

// SqlHelper talks to the database using stored procedures:
builder.Services.AddScoped<SqlHelper>();

// Business logic services - each handles a specific area:
builder.Services.AddScoped<IEmployeeService, EmployeeService>();    // Employee CRUD operations
builder.Services.AddScoped<IDepartmentService, DepartmentService>();// Department management
builder.Services.AddScoped<IContractService, ContractService>();    // Contract management
builder.Services.AddScoped<IAuthService, AuthService>();            // Login/password handling
builder.Services.AddScoped<IRoleService, RoleService>();            // Role management
builder.Services.AddScoped<IShiftService, ShiftService>();          // Shift management
builder.Services.AddScoped<IAttendanceService, AttendanceService>();// Attendance tracking
builder.Services.AddScoped<ILeaveService, LeaveService>();          // Leave management
builder.Services.AddScoped<IMissionService, MissionService>();      // Mission management
builder.Services.AddScoped<INotificationService, NotificationService>(); // Notification system
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();       // Analytics & reporting
builder.Services.AddScoped<IHierarchyService, HierarchyService>();       // Org hierarchy
builder.Services.AddScoped<IPositionService, PositionService>();         // Position management
builder.Services.AddScoped<IExceptionService, ExceptionService>();       // Exception management

// ============================================================================
// PART 3: BUILDING THE APPLICATION
// ============================================================================
// After configuring all services, we "build" the application.
// This creates the actual WebApplication object we'll run.
var app = builder.Build();

// ============================================================================
// PART 4: CONFIGURING THE MIDDLEWARE PIPELINE
// ============================================================================
// Middleware are components that process HTTP requests in a specific ORDER.
// Think of it like a conveyor belt in a factory - each station does something
// to the request before passing it to the next.
//
// REQUEST → [Middleware 1] → [Middleware 2] → [Middleware 3] → RESPONSE
//
// ORDER MATTERS! Authentication must come before Authorization, for example.

// Different behavior for Development vs Production:
if (!app.Environment.IsDevelopment())
{
    // In production: show user-friendly error pages
    app.UseExceptionHandler("/Home/Error");
    
    // HSTS = HTTP Strict Transport Security 
    // Tells browsers to only use HTTPS for this site
    app.UseHsts();
}
// In development: detailed error pages are shown automatically

// Force HTTPS (secure connections):
app.UseHttpsRedirection();

// Serve static files from wwwroot folder (CSS, JS, images):
// This is why your CSS files work without a controller!
app.UseStaticFiles();

// Enable URL routing to match requests to controllers:
app.UseRouting();

// SESSION MIDDLEWARE - must be AFTER UseRouting:
app.UseSession();

// AUTHENTICATION AND AUTHORIZATION - ORDER MATTERS!
// First: check WHO the user is (authentication)
app.UseAuthentication();
// Then: check WHAT they can do (authorization)
app.UseAuthorization();

// ============================================================================
// PART 5: CONFIGURING ROUTES
// ============================================================================
// Routes tell ASP.NET how to map URLs to controllers and actions.
// Pattern: {controller}/{action}/{id?}
//
// Examples:
// /Employee/Details/5  → EmployeeController.Details(5)
// /Account/Login       → AccountController.Login()
// /                    → HomeController.Index() (default)
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");
    // {controller=Home} means: if no controller specified, use HomeController
    // {action=Index} means: if no action specified, use Index method
    // {id?} means: id parameter is optional (the ? makes it optional)

// ============================================================================
// PART 6: RUN THE APPLICATION
// ============================================================================
// This starts the web server and begins listening for HTTP requests.
// The application runs until you stop it (Ctrl+C or close the window).
app.Run();
