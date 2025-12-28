namespace HRMANGMANGMENT.Models
{
    public class ShiftSchedule
    {
        public int ShiftId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty; // Normal, Split, Rotational, Custom
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public decimal BreakDuration { get; set; }
        public TimeSpan? BreakStartTime { get; set; } // For Split Shifts
        public DateTime? ShiftDate { get; set; }
        public bool Status { get; set; } = true; // Active/Inactive
        public int? CycleId { get; set; } // For rotational shifts
        public bool IsRotational { get; set; } = false;
        
        // Computed properties
        public decimal ShiftDurationHours
        {
            get
            {
                var duration = EndTime - StartTime;
                if (duration.TotalHours < 0) // Shift crosses midnight
                {
                    duration = duration.Add(TimeSpan.FromHours(24));
                }
                return (decimal)duration.TotalHours - BreakDuration;
            }
        }
        
        public string TypeBadge
        {
            get
            {
                return Type switch
                {
                    "Normal" => "badge bg-primary",
                    "Split" => "badge bg-info",
                    "Rotational" => "badge bg-warning",
                    "Custom" => "badge bg-secondary",
                    _ => "badge bg-light"
                };
            }
        }
        
        public string StatusBadge
        {
            get
            {
                return Status ? "badge bg-success" : "badge bg-danger";
            }
        }
    }
}
