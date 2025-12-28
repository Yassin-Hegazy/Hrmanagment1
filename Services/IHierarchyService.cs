using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IHierarchyService
    {
        // View hierarchy
        Task<OrganizationChart> GetOrganizationChartAsync();
        Task<IEnumerable<DepartmentTeam>> GetDepartmentTeamsAsync();
        Task<DepartmentTeam?> GetDepartmentTeamAsync(int departmentId);
        Task<ManagerTeam?> GetManagerTeamAsync(int managerId);
        
        // Navigation
        Task<IEnumerable<HierarchyNode>> GetHierarchyTreeAsync();
        Task<IEnumerable<TeamMember>> GetEmployeesByDepartmentAsync(int departmentId);
        Task<IEnumerable<TeamMember>> GetDirectReportsAsync(int managerId);
        
        // Reassignment (System Admin only)
        Task ReassignEmployeeAsync(int employeeId, int? newDepartmentId, int? newManagerId);
        Task<IEnumerable<TeamMember>> GetAllManagersAsync();
        
        // Get all subordinates of an employee (for preventing circular hierarchy)
        Task<List<int>> GetAllSubordinatesAsync(int employeeId);
        
        // Check if assigning newManagerId to employeeId would create a cycle
        Task<bool> WouldCreateCycleAsync(int employeeId, int newManagerId);
        
        // Get full data for ManageLevels page
        Task<ManageLevelsViewModel> GetManageLevelsDataAsync();

        // Hierarchy Table Management
        Task RebuildHierarchyTableAsync();
        Task<IEnumerable<HierarchyTableEntry>> GetHierarchyTableEntriesAsync();
        Task UpdateHierarchyLevelAsync(int employeeId, int managerId, int newLevel);
    }
}
