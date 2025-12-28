namespace HRMANGMANGMENT.Models
{
    public class LeaveRequest
    {
        public int RequestId { get; set; }
        public int EmployeeId { get; set; }
        public int LeaveId { get; set; }
        public string? Justification { get; set; }
        public int Duration { get; set; }
        public DateTime? ApprovalTiming { get; set; }
        public string Status { get; set; } = "Pending";
        public DateTime SubmissionDate { get; set; } = DateTime.Now;
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        
        // Navigation properties
        public string? EmployeeName { get; set; }
        public string? LeaveTypeName { get; set; }
        public string? ApproverName { get; set; }
        public string? DocumentPath { get; set; }
        public bool IsFlagged { get; set; }
        public string? FlagReason { get; set; }
        
        // Computed properties
        public string StatusBadgeClass => Status switch
        {
            "Approved" => "bg-success",
            "Rejected" => "bg-danger",
            "Pending" => "bg-warning",
            "Cancelled" => "bg-secondary",
            _ => "bg-info"
        };
    }
}
