namespace HRMANGMANGMENT.Models
{
    public class Notification
    {
        public int NotificationId { get; set; }
        public string MessageContent { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.Now;
        public string Urgency { get; set; } = "Normal";
        public string ReadStatus { get; set; } = "Unread";
        public string NotificationType { get; set; } = "General";
        
        // For employee-specific notifications
        public int? EmployeeId { get; set; }
        public string? DeliveryStatus { get; set; }
        public DateTime? DeliveredAt { get; set; }
        
        // NEW: Sender tracking
        public int? SenderId { get; set; }
        public string? SenderName { get; set; }
        
        // NEW: Read timestamp tracking
        public DateTime? ReadAt { get; set; }
        
        // Computed properties
        public bool IsRead => ReadStatus == "Read";
        
        public string UrgencyBadgeClass => Urgency switch
        {
            "High" => "bg-danger",
            "Medium" => "bg-warning",
            "Low" => "bg-info",
            _ => "bg-secondary"
        };
        
        public string TypeIcon => NotificationType switch
        {
            "Leave Approval" => "bi-calendar-check",
            "Leave Rejected" => "bi-calendar-x",
            "Contract Expiry" => "bi-file-earmark-x",
            "Shift Change" => "bi-clock",
            "Mission Update" => "bi-geo-alt",
            "Team Message" => "bi-chat-dots",
            "Announcement" => "bi-megaphone",
            _ => "bi-bell"
        };
        
        public string TimeAgo
        {
            get
            {
                var span = DateTime.Now - Timestamp;
                if (span.TotalMinutes < 1) return "Just now";
                if (span.TotalMinutes < 60) return $"{(int)span.TotalMinutes}m ago";
                if (span.TotalHours < 24) return $"{(int)span.TotalHours}h ago";
                if (span.TotalDays < 7) return $"{(int)span.TotalDays}d ago";
                return Timestamp.ToString("MMM dd");
            }
        }
    }
}
