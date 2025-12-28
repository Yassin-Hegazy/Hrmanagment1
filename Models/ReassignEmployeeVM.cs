namespace HRMANGMANGMENT.Models
{
    /// <summary>
    /// ViewModel for reassigning an employee to a new manager and/or department
    /// </summary>
    public class ReassignEmployeeVM
    {
        public int EmployeeId { get; set; }
        public int? NewManagerId { get; set; }
        public int? NewDepartmentId { get; set; }
    }

    /// <summary>
    /// Extended model for displaying employee with reassignment options
    /// </summary>
    public class EmployeeReassignmentRow
    {
        public int EmployeeId { get; set; }
        public string EmployeeName { get; set; } = "";
        public int? CurrentManagerId { get; set; }
        public string CurrentManagerName { get; set; } = "";
        public int? CurrentDepartmentId { get; set; }
        public string CurrentDepartmentName { get; set; } = "";
        public int HierarchyLevel { get; set; }
        
        // For dropdown exclusion - list of subordinate IDs (to prevent circular hierarchy)
        public List<int> SubordinateIds { get; set; } = new();
    }

    /// <summary>
    /// ViewModel for the ManageLevels page
    /// </summary>
    public class ManageLevelsViewModel
    {
        public List<EmployeeReassignmentRow> Employees { get; set; } = new();
        public List<ManagerOption> AvailableManagers { get; set; } = new();
        public List<DepartmentOption> AvailableDepartments { get; set; } = new();
    }

    public class ManagerOption
    {
        public int EmployeeId { get; set; }
        public string FullName { get; set; } = "";
    }

    public class DepartmentOption
    {
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; } = "";
    }
}
