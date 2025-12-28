namespace HRMANGMANGMENT.Models
{
    // Represents a node in the organizational hierarchy
    public class HierarchyNode
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string Type { get; set; } = ""; // "Department", "Manager", "Employee"
        public string? Title { get; set; }
        public string? ProfileImage { get; set; }
        public int? ParentId { get; set; }
        public int Level { get; set; }
        public int ChildCount { get; set; }
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public List<HierarchyNode> Children { get; set; } = new();

        // Display helpers
        public string TypeIcon => Type switch
        {
            "Department" => "bi-building",
            "Manager" => "bi-person-badge",
            "Employee" => "bi-person",
            _ => "bi-diagram-3"
        };

        public string TypeColor => Type switch
        {
            "Department" => "primary",
            "Manager" => "success",
            "Employee" => "secondary",
            _ => "info"
        };
    }

    // Department with its team
    public class DepartmentTeam
    {
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; } = "";
        public int? HeadEmployeeId { get; set; }
        public string? HeadName { get; set; }
        public int EmployeeCount { get; set; }
        public List<TeamMember> Members { get; set; } = new();
    }

    // Team member in hierarchy
    public class TeamMember
    {
        public int EmployeeId { get; set; }
        public string FullName { get; set; } = "";
        public string? Position { get; set; }
        public string? ProfileImage { get; set; }
        public int? ManagerId { get; set; }
        public string? ManagerName { get; set; }
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public bool IsManager { get; set; }
        public int DirectReports { get; set; }
    }

    // For reassignment
    public class ReassignmentRequest
    {
        public int EmployeeId { get; set; }
        public int? NewDepartmentId { get; set; }
        public int? NewManagerId { get; set; }
    }

    // Manager with their direct reports
    public class ManagerTeam
    {
        public int ManagerId { get; set; }
        public string ManagerName { get; set; } = "";
        public string? Position { get; set; }
        public string? ProfileImage { get; set; }
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public List<TeamMember> DirectReports { get; set; } = new();
    }

    // Full organizational chart
    public class OrganizationChart
    {
        public int TotalEmployees { get; set; }
        public int TotalDepartments { get; set; }
        public int TotalManagers { get; set; }
        public List<DepartmentTeam> Departments { get; set; } = new();
        public List<HierarchyNode> RootNodes { get; set; } = new();
    }

    // Represents a row in the EmployeeHierarchy table
    public class HierarchyTableEntry
    {
        public int EmployeeId { get; set; }
        public string EmployeeName { get; set; } = "";
        public int ManagerId { get; set; }
        public string ManagerName { get; set; } = "";
        public int HierarchyLevel { get; set; }
    }
}
