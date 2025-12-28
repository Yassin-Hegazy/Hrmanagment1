namespace HRMANGMANGMENT.Models
{
    public class ExceptionDay
    {
        public int ExceptionId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty; // Holiday, Special Event, Company Closure
        public DateTime Date { get; set; }
        public string Status { get; set; } = "Active"; // Active, Inactive
        public bool IsRecurring { get; set; } = false; // For annual holidays
        
        // Navigation properties
        public string CategoryDisplay
        {
            get
            {
                return Category switch
                {
                    "Holiday" => "🎉 Holiday",
                    "Special Event" => "⭐ Special Event",
                    "Company Closure" => "🔒 Company Closure",
                    _ => Category
                };
            }
        }
        
        public string StatusBadgeClass
        {
            get
            {
                return Status == "Active" ? "badge bg-success" : "badge bg-secondary";
            }
        }
    }
}
