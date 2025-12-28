// ============================================================================
// AUTHENTICATION SERVICE - HANDLES USER LOGIN/PASSWORD OPERATIONS
// ============================================================================
// This service is responsible for:
// - Authenticating users (checking email + password)
// - Hashing passwords securely (using BCrypt)
// - Verifying passwords
// - Managing account status (locked, last login, etc.)
//
// SERVICE LAYER PATTERN:
// Controllers don't talk to the database directly. Instead, they use Services.
// This separation makes code:
// - Easier to test (you can mock services)
// - More organized (each service handles one area)
// - More maintainable (change database logic without touching controllers)
// ============================================================================

using HRMANGMANGMENT.Data;        // Our database helper
using HRMANGMANGMENT.Models;      // Our data models (Employee, etc.)
using Microsoft.Data.SqlClient;   // SQL Server data access
using System.Data;               // DataTable, DataRow
using BCrypt.Net;                // Password hashing library

namespace HRMANGMANGMENT.Services
{
    // ========================================================================
    // AuthService Class
    // ========================================================================
    // This implements IAuthService interface (see IAuthenticationService.cs)
    // Interfaces define WHAT a class can do, the implementation defines HOW
    public class AuthService : IAuthService
    {
        // ====================================================================
        // DEPENDENCY INJECTION
        // ====================================================================
        // SqlHelper is injected via constructor (registered in Program.cs)
        // readonly = can only be set in constructor
        private readonly SqlHelper _sqlHelper;

        // Constructor - receives SqlHelper from DI container
        public AuthService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        // ====================================================================
        // AUTHENTICATE USER
        // ====================================================================
        // This is the main login method. It:
        // 1. Finds the employee by email
        // 2. Checks if account is locked
        // 3. Verifies the password
        // 4. Updates last login time
        //
        // Returns: Employee object if successful, null if failed
        //
        // async Task<Employee?> means:
        // - async = this method can pause while waiting for database
        // - Task = represents the async operation
        // - Employee? = the ? means it can return null (nullable)
        public async Task<Employee?> AuthenticateAsync(string email, string password)
        {
            // Step 1: Find employee by email
            var employee = await GetEmployeeByEmailAsync(email);
            
            // If no employee found, authentication fails
            if (employee == null)
                return null;

            // Step 2: Check if account is locked (too many failed attempts, etc.)
            if (employee.IsLocked)
                return null;

            // Step 3: Verify the password
            // We compare the plain text password against the stored hash
            if (string.IsNullOrEmpty(employee.PasswordHash) || !VerifyPassword(password, employee.PasswordHash))
                return null;

            // Step 4: Update last login timestamp
            await UpdateLastLoginAsync(employee.EmployeeId);
            employee.LastLogin = DateTime.Now;

            // Success! Return the employee
            return employee;
        }

        // ====================================================================
        // HASH PASSWORD
        // ====================================================================
        // This creates a secure hash of a password using BCrypt.
        //
        // WHY HASH PASSWORDS?
        // - Never store plain text passwords in database
        // - If database is stolen, passwords are still protected
        // - BCrypt is slow on purpose (makes brute force attacks harder)
        //
        // HOW BCRYPT WORKS:
        // 1. Generate a random "salt" (random data added to password)
        // 2. Hash the password + salt together
        // 3. Store the hash (includes the salt)
        //
        // IMPORTANT: Same password = different hash each time (because of salt)
        // Example: "password123" might hash to:
        //   $2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/AwKY7HQ...
        //   $2a$12$N9qo8uLOickgx2ZMRZoMye/GKHGgjsXd5ENrG5G1Zb...
        // Both are valid hashes of the same password!
        public string HashPassword(string password)
        {
            // GenerateSalt(12) = work factor of 12 (2^12 iterations)
            // Higher = more secure but slower
            // 12 is a good balance for 2024
            return BCrypt.Net.BCrypt.HashPassword(password, BCrypt.Net.BCrypt.GenerateSalt(12));
        }

        // ====================================================================
        // VERIFY PASSWORD
        // ====================================================================
        // Checks if a plain text password matches a stored hash.
        //
        // How it works:
        // 1. BCrypt extracts the salt from the stored hash
        // 2. Hashes the input password with that salt
        // 3. Compares the result with the stored hash
        // 4. Returns true if they match
        public bool VerifyPassword(string password, string hash)
        {
            try
            {
                // BCrypt.Verify does all the work for us
                return BCrypt.Net.BCrypt.Verify(password, hash);
            }
            catch
            {
                // If hash is invalid or corrupted, return false
                return false;
            }
        }

        // ====================================================================
        // CHECK IF EMAIL IS UNIQUE
        // ====================================================================
        // Used during registration to prevent duplicate accounts
        public async Task<bool> IsEmailUniqueAsync(string email)
        {
            var employee = await GetEmployeeByEmailAsync(email);
            return employee == null; // True if no employee found (email is unique)
        }

        // ====================================================================
        // UPDATE LAST LOGIN TIMESTAMP
        // ====================================================================
        // Records when the user last logged in
        // Useful for: security audits, inactive account detection
        public async Task UpdateLastLoginAsync(int employeeId)
        {
            // SqlParameter prevents SQL injection attacks
            // Never concatenate user input directly into SQL!
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@LastLogin", DateTime.Now)
            };

            // ExecuteNonQueryAsync = runs SQL that doesn't return data
            // (INSERT, UPDATE, DELETE statements)
            await _sqlHelper.ExecuteNonQueryAsync("UpdateLastLogin", parameters);
        }

        // ====================================================================
        // CHECK IF ACCOUNT IS LOCKED
        // ====================================================================
        // Accounts might be locked for security reasons:
        // - Too many failed login attempts
        // - Admin manually locked the account
        // - Suspicious activity detected
        public async Task<bool> IsAccountLockedAsync(int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId)
            };

            // ExecuteStoredProcedureAsync = runs a stored procedure
            // Returns a DataTable with the results
            var result = await _sqlHelper.ExecuteStoredProcedureAsync("ViewEmployeeInfo", parameters);
            
            // If no rows returned, treat as locked (employee doesn't exist)
            if (result.Rows.Count == 0)
                return true;

            // Get the is_locked value from the first row
            var row = result.Rows[0];
            
            // DBNull.Value represents NULL in database
            // Convert.ToBoolean converts the value to true/false
            return row["is_locked"] != DBNull.Value && Convert.ToBoolean(row["is_locked"]);
        }

        // ====================================================================
        // GET EMPLOYEE BY EMAIL
        // ====================================================================
        // Looks up an employee using their email address
        public async Task<Employee?> GetEmployeeByEmailAsync(string email)
        {
            var parameters = new[]
            {
                new SqlParameter("@Email", email)
            };

            // Execute the stored procedure
            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetEmployeeByEmail", parameters);

            // No results = employee not found
            if (dataTable.Rows.Count == 0)
                return null;

            // Convert the DataRow to an Employee object
            var row = dataTable.Rows[0];
            return MapToEmployee(row);
        }

        // ====================================================================
        // MAP DATABASE ROW TO EMPLOYEE OBJECT
        // ====================================================================
        // Converts a DataRow (from database) to an Employee object (C# class)
        // This is called "mapping" or "projection"
        //
        // Why do this?
        // - Database returns raw data (strings, numbers)
        // - We want strongly-typed C# objects
        // - Makes code easier to work with
        private Employee MapToEmployee(DataRow row)
        {
            return new Employee
            {
                // Convert.ToInt32 converts the value to an integer
                EmployeeId = Convert.ToInt32(row["employee_id"]),
                
                // .ToString() converts to string
                // ?? string.Empty = if null, use empty string
                FirstName = row["first_name"].ToString() ?? string.Empty,
                LastName = row["last_name"].ToString() ?? string.Empty,
                FullName = row["full_name"].ToString(),
                NationalId = row["national_id"].ToString() ?? string.Empty,
                Email = row["email"].ToString(),
                Phone = row["phone"].ToString(),
                PasswordHash = row["password_hash"].ToString(),
                PasswordSalt = row["password_salt"].ToString(),
                
                // Handle nullable boolean - check for DBNull first
                IsLocked = row["is_locked"] != DBNull.Value && Convert.ToBoolean(row["is_locked"]),
                
                // Handle nullable DateTime
                // If database value is NULL, use null in C#
                LastLogin = row["last_login"] != DBNull.Value ? Convert.ToDateTime(row["last_login"]) : null,
                
                // Check if column exists before accessing
                // Some queries might not include all columns
                RoleName = row.Table.Columns.Contains("role_name") ? row["role_name"].ToString() : null,
                
                IsActive = row["is_active"] != DBNull.Value && Convert.ToBoolean(row["is_active"])
            };
        }

        // ====================================================================
        // SET PASSWORD FOR EXISTING USER
        // ====================================================================
        // Used by the "Activate Account" feature for existing employees
        // who don't have a password yet
        public async Task SetPasswordAsync(int employeeId, string hashedPassword)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId),
                new SqlParameter("@PasswordHash", hashedPassword)
            };

            // Update the password in the database
            await _sqlHelper.ExecuteNonQueryAsync("SetEmployeePassword", parameters);
        }
    }
}
