using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IEmployeeService
    {
        Task<Employee?> GetEmployeeByIdAsync(int employeeId);
        Task<List<Employee>> GetAllEmployeesAsync();
        Task<int> AddEmployeeAsync(Employee employee);
        Task UpdateEmployeeAsync(Employee employee);
        Task DeleteEmployeeAsync(int employeeId);
        Task<IEnumerable<Employee>> SearchEmployeesAsync(string searchTerm);
        Task AssignRoleAsync(int employeeId, int roleId);
        Task RemoveRoleAsync(int employeeId, int roleId);
        Task<IEnumerable<int>> GetEmployeeRolesAsync(int employeeId);
        Task ReassignManagerAsync(int employeeId, int newManagerId);
        Task<int> SetProfileCompletenessAsync(int employeeId, int completeness);
        Task<Employee?> GetEmployeeByEmailAsync(string email);
        Task UpdateProfilePictureAsync(int employeeId, string imagePath);
        Task<int> AddEmployeeWithPasswordAsync(Employee employee, string password);
        
        // Role-based operations
        Task<Employee?> GetEmployeeWithRoleDetailsAsync(int employeeId);
        Task<int> CreateAdminAccountAsync(Employee employee, string password, int roleId);
        Task<int> CreateEmployeeByAdminAsync(Employee employee, string password, int roleId, int creatorId);
        Task<bool> CanEditEmployeeAsync(int editorId, int targetEmployeeId);
        Task UpdateEmployeeProfileAsync(int editorId, Employee employee);
        Task UpdateRoleSpecificDataAsync(int editorId, Employee employee);
        Task InsertIntoRoleSubclassAsync(int employeeId, string roleName);
        
        // Manager team operations
        Task<List<Employee>> GetEmployeesByManagerIdAsync(int managerId);
        
        // Get all role NAMES for an employee (for multiple roles support)
        // Get all role NAMES for an employee (for multiple roles support)
        Task<List<string>> GetEmployeeRoleNamesAsync(int employeeId);
        
        // Update specific profile field using SP
        Task UpdateProfileFieldAsync(int employeeId, string fieldName, string newValue);
    }
}
