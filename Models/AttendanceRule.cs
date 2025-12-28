namespace HRMANGMANGMENT.Models
{
    public class AttendanceRule
    {
        public int RuleId { get; set; }
        public string RuleType { get; set; } = string.Empty; // GracePeriod, LatenessPenalty, ShortTime
        public string RuleName { get; set; } = string.Empty;
        public int? ThresholdMinutes { get; set; }
        public decimal? PenaltyAmount { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedDate { get; set; } = DateTime.Now;
        public DateTime? LastModifiedDate { get; set; }
        
        // Computed properties
        public string RuleTypeDisplay
        {
            get
            {
                return RuleType switch
                {
                    "GracePeriod" => "⏰ Grace Period",
                    "LatenessPenalty" => "💰 Lateness Penalty",
                    "ShortTime" => "⏱️ Short Time",
                    _ => RuleType
                };
            }
        }
        
        public string RuleSummary
        {
            get
            {
                return RuleType switch
                {
                    "GracePeriod" => $"{ThresholdMinutes} minutes allowed before marking late",
                    "LatenessPenalty" => $"${PenaltyAmount} deduction per {ThresholdMinutes} minutes late",
                    "ShortTime" => $"Minimum {ThresholdMinutes} minutes required",
                    _ => Description ?? ""
                };
            }
        }
    }
}
