namespace HRMANGMANGMENT.Models
{
    public class Department
    {
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; } = string.Empty;
        public string? Purpose { get; set; }
        public int? DepartmentHeadId { get; set; }
        public string? DepartmentHeadName { get; set; }
        public int EmployeeCount { get; set; }
    }
}
