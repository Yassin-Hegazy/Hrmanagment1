namespace HRMANGMANGMENT.Models
{
    public class Contract
    {
        public int ContractId { get; set; }
        public int EmployeeId { get; set; }
        public string ContractType { get; set; } = string.Empty; // Full-time, Part-time, Consultant, Internship
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal Salary { get; set; }
        public string? Terms { get; set; }
        public string Status { get; set; } = "Active"; // Active, Expired, Terminated
        public DateTime? RenewalDate { get; set; }
        
        // Navigation properties
        public string? EmployeeName { get; set; }
        public string? DepartmentName { get; set; }
        public string? PositionTitle { get; set; }
        public string? ProfileImage { get; set; }
        
        // Computed properties
        public int? DaysRemaining
        {
            get
            {
                if (EndDate.HasValue && EndDate.Value > DateTime.Now)
                {
                    return (EndDate.Value - DateTime.Now).Days;
                }
                return null;
            }
        }
        
        public bool IsExpiringSoon
        {
            get
            {
                return DaysRemaining.HasValue && DaysRemaining.Value <= 30 && DaysRemaining.Value > 0;
            }
        }
    }
}
