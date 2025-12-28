namespace HRMANGMANGMENT.Models
{
    public class Mission
    {
        public int MissionId { get; set; }
        public string Destination { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; } = "Pending";
        public int EmployeeId { get; set; }
        public int? ManagerId { get; set; }
        
        // Navigation properties
        public string? EmployeeName { get; set; }
        public string? ManagerName { get; set; }
        
        // Computed properties
        public int Duration => (EndDate - StartDate).Days + 1;
        
        public string StatusBadgeClass => Status switch
        {
            "Approved" => "bg-success",
            "Rejected" => "bg-danger",
            "Pending" => "bg-warning",
            "Completed" => "bg-info",
            "Cancelled" => "bg-secondary",
            _ => "bg-primary"
        };
    }
}
