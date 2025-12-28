namespace HRMANGMANGMENT.Models
{
    public class AttendanceCorrectionRequest
    {
        public int RequestId { get; set; }
        public int EmployeeId { get; set; }
        public DateTime Date { get; set; }
        public string CorrectionType { get; set; } = string.Empty; // "CheckIn", "CheckOut", "Both"
        public string Reason { get; set; } = string.Empty;
        public string Status { get; set; } = "Pending"; // Pending, Approved, Rejected
        public int? RecordedBy { get; set; }
        
        // Navigation properties
        public string? EmployeeName { get; set; }
        public DateTime? CorrectTime { get; set; } // For the correction
    }
}
