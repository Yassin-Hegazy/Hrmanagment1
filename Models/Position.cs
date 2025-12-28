namespace HRMANGMANGMENT.Models
{
    public class Position
    {
        public int PositionId { get; set; }
        public string PositionTitle { get; set; } = string.Empty;
        public string? Responsibilities { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
