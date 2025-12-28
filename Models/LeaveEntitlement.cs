namespace HRMANGMANGMENT.Models
{
    public class LeaveEntitlement
    {
        public int EmployeeId { get; set; }
        public int LeaveTypeId { get; set; }
        public decimal Entitlement { get; set; }
        public decimal Used { get; set; }
        public decimal Remaining => Entitlement - Used;
        
        // Navigation properties
        public string? EmployeeName { get; set; }
        public string? LeaveTypeName { get; set; }
    }
}
