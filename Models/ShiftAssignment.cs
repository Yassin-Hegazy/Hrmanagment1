namespace HRMANGMANGMENT.Models
{
    public class ShiftAssignment
    {
        public int AssignmentId { get; set; }
        public int EmployeeId { get; set; }
        public int ShiftId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string Status { get; set; } = "Active";
        
        // Navigation properties
        public string? EmployeeName { get; set; }
        public string? ShiftName { get; set; }
    }
}
