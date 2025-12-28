namespace HRMANGMANGMENT.Models
{
    public class Attendance
    {
        public int AttendanceId { get; set; }
        public int EmployeeId { get; set; }
        public int? ShiftId { get; set; }
        public DateTime? EntryTime { get; set; }
        public DateTime? ExitTime { get; set; }
        public decimal? Duration { get; set; }
        public string? LoginMethod { get; set; }
        public string? LogoutMethod { get; set; }
        public int? ExceptionId { get; set; }
        
        // Navigation properties
        public string? EmployeeName { get; set; }
        public string? ShiftName { get; set; }
        
        public bool IsLate { get; set; } // Populated from Service/DB

        // Computed properties
        public string Status
        {
            get
            {
                if (!EntryTime.HasValue) return "Absent";
                if (!ExitTime.HasValue) return "Clocked In";
                
                if (IsLate) return "Late";
                
                return "Present";
            }
        }
        
        public string DurationFormatted
        {
            get
            {
                if (Duration.HasValue)
                {
                    var hours = (int)Duration.Value;
                    var minutes = (int)((Duration.Value - hours) * 60);
                    return $"{hours}h {minutes}m";
                }
                return "-";
            }
        }
    }
}
