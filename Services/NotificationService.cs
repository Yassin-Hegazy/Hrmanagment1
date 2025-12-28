using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class NotificationService : INotificationService
    {
        private readonly SqlHelper _sqlHelper;

        public NotificationService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        // ====================================================================
        // EMPLOYEE METHODS
        // ====================================================================

        /// <summary>
        /// Get all notifications for the specified employee
        /// Uses stored procedure: sp_GetEmployeeNotifications
        /// </summary>
        public async Task<IEnumerable<Notification>> GetMyNotificationsAsync(int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetEmployeeNotifications", parameters);
            return MapToNotifications(result);
        }

        /// <summary>
        /// Get count of unread notifications for navbar badge
        /// Uses stored procedure: sp_GetUnreadNotificationCount
        /// </summary>
        public async Task<int> GetUnreadCountAsync(int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId)
            };

            var result = await _sqlHelper.ExecuteScalarAsync("sp_GetUnreadNotificationCount", parameters);
            return result != null ? Convert.ToInt32(result) : 0;
        }

        /// <summary>
        /// Mark a single notification as read
        /// Uses stored procedure: sp_MarkNotificationAsRead
        /// </summary>
        public async Task MarkAsReadAsync(int notificationId, int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@NotificationId", notificationId),
                new SqlParameter("@EmployeeId", employeeId)
            };

            await _sqlHelper.ExecuteNonQueryAsync("sp_MarkNotificationAsRead", parameters);
        }

        /// <summary>
        /// Mark all notifications as read for an employee
        /// Uses stored procedure: sp_MarkAllNotificationsAsRead
        /// </summary>
        public async Task MarkAllAsReadAsync(int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId)
            };

            await _sqlHelper.ExecuteNonQueryAsync("sp_MarkAllNotificationsAsRead", parameters);
        }

        // ====================================================================
        // MANAGER METHODS
        // ====================================================================

        /// <summary>
        /// Send notification to all team members under a manager
        /// Uses stored procedure: sp_SendTeamNotification
        /// </summary>
        public async Task SendTeamNotificationAsync(int managerId, string message, string urgency)
        {
            var parameters = new[]
            {
                new SqlParameter("@ManagerId", managerId),
                new SqlParameter("@MessageContent", message),
                new SqlParameter("@Urgency", urgency)
            };

            await _sqlHelper.ExecuteNonQueryAsync("sp_SendTeamNotification", parameters);
        }

        /// <summary>
        /// Send notification to ALL active employees (broadcast)
        /// Uses stored procedure: sp_SendBroadcastNotification
        /// </summary>
        public async Task<(int notificationId, int recipientCount)> SendBroadcastNotificationAsync(
            int senderId, string message, string urgency, string notificationType = "Announcement")
        {
            var parameters = new[]
            {
                new SqlParameter("@SenderId", senderId),
                new SqlParameter("@MessageContent", message),
                new SqlParameter("@Urgency", urgency),
                new SqlParameter("@NotificationType", notificationType)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_SendBroadcastNotification", parameters);
            
            if (result.Rows.Count > 0)
            {
                var row = result.Rows[0];
                return (
                    Convert.ToInt32(row["NotificationId"]),
                    Convert.ToInt32(row["RecipientCount"])
                );
            }
            
            return (0, 0);
        }

        // ====================================================================
        // SYSTEM NOTIFICATION METHODS
        // ====================================================================

        /// <summary>
        /// Create a notification and assign to an employee
        /// Uses stored procedure: sp_CreateNotificationForEmployee
        /// </summary>
        public async Task CreateNotificationAsync(int employeeId, string message, string type, string urgency)
        {
            await CreateNotificationWithSenderAsync(employeeId, message, type, urgency, null);
        }

        /// <summary>
        /// Create a notification with sender tracking
        /// Uses stored procedure: sp_CreateNotificationForEmployee
        /// </summary>
        public async Task CreateNotificationWithSenderAsync(int employeeId, string message, string type, string urgency, int? senderId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId),
                new SqlParameter("@MessageContent", message),
                new SqlParameter("@NotificationType", type),
                new SqlParameter("@Urgency", urgency),
                new SqlParameter("@SenderId", senderId.HasValue ? (object)senderId.Value : DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("sp_CreateNotificationForEmployee", parameters);
        }

        /// <summary>
        /// Notify employee of leave request status change
        /// Uses stored procedure: sp_NotifyLeaveStatusChange
        /// </summary>
        public async Task NotifyLeaveStatusChangeAsync(int employeeId, string status, int requestId)
        {
            await NotifyLeaveStatusChangeWithApproverAsync(employeeId, status, requestId, null);
        }

        /// <summary>
        /// Notify employee of leave request status change with approver tracking
        /// Uses stored procedure: sp_NotifyLeaveStatusChange
        /// </summary>
        public async Task NotifyLeaveStatusChangeWithApproverAsync(int employeeId, string status, int requestId, int? approverId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId),
                new SqlParameter("@Status", status),
                new SqlParameter("@RequestId", requestId),
                new SqlParameter("@ApproverId", approverId.HasValue ? (object)approverId.Value : DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("sp_NotifyLeaveStatusChange", parameters);
        }

        /// <summary>
        /// Notify employee of contract expiry
        /// Uses stored procedure: sp_NotifyContractExpiry
        /// </summary>
        public async Task NotifyContractExpiryAsync(int employeeId, DateTime expiryDate)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId),
                new SqlParameter("@ExpiryDate", expiryDate.Date)
            };

            await _sqlHelper.ExecuteNonQueryAsync("sp_NotifyContractExpiry", parameters);
        }

        /// <summary>
        /// Notify employee of shift change
        /// Uses stored procedure: sp_NotifyShiftChange
        /// </summary>
        public async Task NotifyShiftChangeAsync(int employeeId, string shiftDetails)
        {
            await NotifyShiftChangeWithChangerAsync(employeeId, shiftDetails, null);
        }

        /// <summary>
        /// Notify employee of shift change with changer tracking
        /// Uses stored procedure: sp_NotifyShiftChange
        /// </summary>
        public async Task NotifyShiftChangeWithChangerAsync(int employeeId, string shiftDetails, int? changedById)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId),
                new SqlParameter("@ShiftDetails", shiftDetails),
                new SqlParameter("@ChangedById", changedById.HasValue ? (object)changedById.Value : DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("sp_NotifyShiftChange", parameters);
        }

        /// <summary>
        /// Notify employee of mission update
        /// Uses stored procedure: sp_NotifyMissionUpdate
        /// </summary>
        public async Task NotifyMissionUpdateAsync(int employeeId, string destination, string status)
        {
            await NotifyMissionUpdateWithApproverAsync(employeeId, destination, status, null);
        }

        /// <summary>
        /// Notify employee of mission update with approver tracking
        /// Uses stored procedure: sp_NotifyMissionUpdate
        /// </summary>
        public async Task NotifyMissionUpdateWithApproverAsync(int employeeId, string destination, string status, int? approverId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId),
                new SqlParameter("@Destination", destination),
                new SqlParameter("@Status", status),
                new SqlParameter("@ApproverId", approverId.HasValue ? (object)approverId.Value : DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("sp_NotifyMissionUpdate", parameters);
        }

        // ====================================================================
        // HELPER METHODS
        // ====================================================================

        private IEnumerable<Notification> MapToNotifications(DataTable dataTable)
        {
            var notifications = new List<Notification>();
            foreach (DataRow row in dataTable.Rows)
            {
                notifications.Add(new Notification
                {
                    NotificationId = Convert.ToInt32(row["notification_id"]),
                    MessageContent = row["message_content"]?.ToString() ?? "",
                    Timestamp = row["timestamp"] != DBNull.Value ? Convert.ToDateTime(row["timestamp"]) : DateTime.Now,
                    Urgency = row["urgency"]?.ToString() ?? "Normal",
                    ReadStatus = row["read_status"]?.ToString() ?? "Unread",
                    NotificationType = row["notification_type"]?.ToString() ?? "General",
                    SenderId = row.Table.Columns.Contains("sender_id") && row["sender_id"] != DBNull.Value 
                        ? Convert.ToInt32(row["sender_id"]) : null,
                    SenderName = row.Table.Columns.Contains("sender_name") 
                        ? row["sender_name"]?.ToString() : null,
                    DeliveryStatus = row["delivery_status"]?.ToString(),
                    DeliveredAt = row["delivered_at"] != DBNull.Value ? Convert.ToDateTime(row["delivered_at"]) : null,
                    ReadAt = row.Table.Columns.Contains("read_at") && row["read_at"] != DBNull.Value 
                        ? Convert.ToDateTime(row["read_at"]) : null
                });
            }
            return notifications;
        }

        // ====================================================================
        // TEAM SELECTION METHODS
        // ====================================================================

        /// <summary>
        /// Get team members for dropdown selection
        /// Uses stored procedure: sp_GetTeamMembers
        /// </summary>
        /// <param name="employeeId">Current user's employee ID</param>
        /// <param name="isAdmin">If true, return all employees; if false, return only direct reports</param>
        public async Task<IEnumerable<TeamMemberInfo>> GetTeamMembersAsync(int employeeId, bool isAdmin = false)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId),
                new SqlParameter("@IsAdmin", isAdmin)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetTeamMembers", parameters);
            
            var teamMembers = new List<TeamMemberInfo>();
            foreach (DataRow row in result.Rows)
            {
                teamMembers.Add(new TeamMemberInfo
                {
                    EmployeeId = Convert.ToInt32(row["employee_id"]),
                    FullName = row["full_name"]?.ToString() ?? "",
                    Email = row["email"]?.ToString(),
                    DepartmentName = row["department_name"]?.ToString(),
                    PositionTitle = row["position_title"]?.ToString()
                });
            }
            return teamMembers;
        }

        /// <summary>
        /// Send notification to specific selected employees
        /// Uses stored procedure: sp_SendNotificationToEmployees
        /// </summary>
        public async Task<(int notificationId, int recipientCount)> SendNotificationToEmployeesAsync(
            int senderId, string employeeIds, string message, string urgency, string notificationType = "Team Message")
        {
            var parameters = new[]
            {
                new SqlParameter("@SenderId", senderId),
                new SqlParameter("@EmployeeIds", employeeIds),
                new SqlParameter("@MessageContent", message),
                new SqlParameter("@Urgency", urgency),
                new SqlParameter("@NotificationType", notificationType)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_SendNotificationToEmployees", parameters);
            
            if (result.Rows.Count > 0)
            {
                var row = result.Rows[0];
                return (
                    Convert.ToInt32(row["NotificationId"]),
                    Convert.ToInt32(row["RecipientCount"])
                );
            }
            
            return (0, 0);
        }

        // ====================================================================
        // HISTORY METHODS
        // ====================================================================

        /// <summary>
        /// Get sent notification history for a user
        /// Uses stored procedure: sp_GetSentNotificationHistory
        /// </summary>
        public async Task<IEnumerable<SentNotificationInfo>> GetSentHistoryAsync(int senderId)
        {
            var parameters = new[]
            {
                new SqlParameter("@SenderId", senderId)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("sp_GetSentNotificationHistory", parameters);
            
            var history = new List<SentNotificationInfo>();
            foreach (DataRow row in result.Rows)
            {
                history.Add(new SentNotificationInfo
                {
                    NotificationId = Convert.ToInt32(row["notification_id"]),
                    MessageContent = row["message_content"]?.ToString() ?? "",
                    SentAt = row["sent_at"] != DBNull.Value ? Convert.ToDateTime(row["sent_at"]) : DateTime.Now,
                    Urgency = row["urgency"]?.ToString() ?? "Normal",
                    NotificationType = row["notification_type"]?.ToString() ?? "General",
                    RecipientCount = Convert.ToInt32(row["recipient_count"]),
                    ReadCount = Convert.ToInt32(row["read_count"])
                });
            }
            return history;
        }
    }
}

