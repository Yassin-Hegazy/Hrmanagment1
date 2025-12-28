using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IDepartmentService
    {
        Task<IEnumerable<Department>> GetAllDepartmentsAsync();
        Task<Department?> GetDepartmentByIdAsync(int departmentId);
        Task<int> AddDepartmentAsync(Department department);
        Task UpdateDepartmentAsync(Department department);
        Task AssignDepartmentHeadAsync(int departmentId, int employeeId);
        Task<IEnumerable<Employee>> GetDepartmentEmployeesAsync(int departmentId);
    }
}
