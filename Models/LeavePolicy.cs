namespace HRMANGMANGMENT.Models
{
    public class LeavePolicy
    {
        public int PolicyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Purpose { get; set; }
        public string? EligibilityRules { get; set; }
        public int NoticePeriod { get; set; }
        public string? SpecialLeaveType { get; set; }
        public bool ResetOnNewYear { get; set; }
    }
}
