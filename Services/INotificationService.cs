using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface INotificationService
    {
        // ====================================================================
        // EMPLOYEE METHODS
        // ====================================================================
        
        /// <summary>Get all notifications for an employee</summary>
        Task<IEnumerable<Notification>> GetMyNotificationsAsync(int employeeId);
        
        /// <summary>Get count of unread notifications for navbar badge</summary>
        Task<int> GetUnreadCountAsync(int employeeId);
        
        /// <summary>Mark a single notification as read</summary>
        Task MarkAsReadAsync(int notificationId, int employeeId);
        
        /// <summary>Mark all notifications as read</summary>
        Task MarkAllAsReadAsync(int employeeId);
        
        // ====================================================================
        // MANAGER METHODS
        // ====================================================================
        
        /// <summary>Send notification to all team members under a manager</summary>
        Task SendTeamNotificationAsync(int managerId, string message, string urgency);
        
        // ====================================================================
        // ADMIN METHODS (NEW)
        // ====================================================================
        
        /// <summary>Send notification to ALL active employees (broadcast)</summary>
        Task<(int notificationId, int recipientCount)> SendBroadcastNotificationAsync(
            int senderId, string message, string urgency, string notificationType = "Announcement");
        
        // ====================================================================
        // SYSTEM METHODS (for automatic notifications)
        // ====================================================================
        
        /// <summary>Create a notification for an employee</summary>
        Task CreateNotificationAsync(int employeeId, string message, string type, string urgency);
        
        /// <summary>Create a notification with sender tracking</summary>
        Task CreateNotificationWithSenderAsync(int employeeId, string message, string type, string urgency, int? senderId);
        
        /// <summary>Notify employee of leave request status change</summary>
        Task NotifyLeaveStatusChangeAsync(int employeeId, string status, int requestId);
        
        /// <summary>Notify employee of leave status change with approver tracking</summary>
        Task NotifyLeaveStatusChangeWithApproverAsync(int employeeId, string status, int requestId, int? approverId);
        
        /// <summary>Notify employee of contract expiry</summary>
        Task NotifyContractExpiryAsync(int employeeId, DateTime expiryDate);
        
        /// <summary>Notify employee of shift change</summary>
        Task NotifyShiftChangeAsync(int employeeId, string shiftDetails);
        
        /// <summary>Notify employee of shift change with changer tracking</summary>
        Task NotifyShiftChangeWithChangerAsync(int employeeId, string shiftDetails, int? changedById);
        
        /// <summary>Notify employee of mission update</summary>
        Task NotifyMissionUpdateAsync(int employeeId, string destination, string status);
        
        /// <summary>Notify employee of mission update with approver tracking</summary>
        Task NotifyMissionUpdateWithApproverAsync(int employeeId, string destination, string status, int? approverId);

        // ====================================================================
        // TEAM SELECTION METHODS (NEW)
        // ====================================================================
        
        /// <summary>Get list of team members for dropdown selection</summary>
        /// <param name="employeeId">Current user's employee ID</param>
        /// <param name="isAdmin">If true, return all employees; if false, return only direct reports</param>
        Task<IEnumerable<TeamMemberInfo>> GetTeamMembersAsync(int employeeId, bool isAdmin = false);
        
        /// <summary>Send notification to specific selected employees</summary>
        Task<(int notificationId, int recipientCount)> SendNotificationToEmployeesAsync(
            int senderId, string employeeIds, string message, string urgency, string notificationType = "Team Message");
        
        /// <summary>Get sent notification history for a user</summary>
        Task<IEnumerable<SentNotificationInfo>> GetSentHistoryAsync(int senderId);
    }
    
    /// <summary>Simple DTO for team member dropdown</summary>
    public class TeamMemberInfo
    {
        public int EmployeeId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? DepartmentName { get; set; }
        public string? PositionTitle { get; set; }
    }
    
    /// <summary>DTO for sent notification history</summary>
    public class SentNotificationInfo
    {
        public int NotificationId { get; set; }
        public string MessageContent { get; set; } = string.Empty;
        public DateTime SentAt { get; set; }
        public string Urgency { get; set; } = "Normal";
        public string NotificationType { get; set; } = "General";
        public int RecipientCount { get; set; }
        public int ReadCount { get; set; }
    }
}

