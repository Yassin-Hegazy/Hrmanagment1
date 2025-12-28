using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class LeaveService : ILeaveService
    {
        private readonly SqlHelper _sqlHelper;
        private readonly INotificationService _notificationService;

        public LeaveService(SqlHelper sqlHelper, INotificationService notificationService)
        {
            _sqlHelper = sqlHelper;
            _notificationService = notificationService;
        }

        // ====================================================================
        // EMPLOYEE METHODS
        // ====================================================================

        public async Task<int> SubmitLeaveRequestAsync(int employeeId, int leaveTypeId, DateTime startDate, DateTime endDate, string reason)
        {
            var requestIdParam = new SqlParameter("@RequestID", SqlDbType.Int) { Direction = ParameterDirection.Output };

            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@LeaveTypeID", leaveTypeId),
                new SqlParameter("@StartDate", startDate),
                new SqlParameter("@EndDate", endDate),
                new SqlParameter("@Reason", reason ?? ""),
                requestIdParam
            };

            await _sqlHelper.ExecuteNonQueryAsync("SubmitLeaveRequest", parameters);
            return (int)requestIdParam.Value;
        }

        public async Task<IEnumerable<LeaveEntitlement>> GetLeaveBalanceAsync(int employeeId)
        {
            var query = @"
                SELECT 
                    LE.employee_id,
                    LE.leave_type_id,
                    L.leave_type AS leave_type_name,
                    LE.entitlement,
                    ISNULL((SELECT SUM(LR.duration) 
                            FROM LeaveRequest LR 
                            WHERE LR.employee_id = LE.employee_id 
                              AND LR.leave_id = LE.leave_type_id 
                              AND LR.status = 'Approved'), 0) AS used
                FROM LeaveEntitlement LE
                INNER JOIN [Leave] L ON LE.leave_type_id = L.leave_id
                WHERE LE.employee_id = @EmployeeId";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeId", employeeId);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var balances = new List<LeaveEntitlement>();
            foreach (DataRow row in dataTable.Rows)
            {
                balances.Add(new LeaveEntitlement
                {
                    EmployeeId = Convert.ToInt32(row["employee_id"]),
                    LeaveTypeId = Convert.ToInt32(row["leave_type_id"]),
                    LeaveTypeName = row["leave_type_name"]?.ToString(),
                    // Reconstruct Total Entitlement (Allocation) because DB stores Remaining Balance
                    Entitlement = Convert.ToDecimal(row["entitlement"]) + Convert.ToDecimal(row["used"]),
                    Used = Convert.ToDecimal(row["used"])
                });
            }

            return balances;
        }

        public async Task<IEnumerable<LeaveRequest>> GetLeaveHistoryAsync(int employeeId)
        {
            var query = @"
                SELECT 
                    LR.request_id,
                    LR.employee_id,
                    LR.leave_id,
                    L.leave_type AS leave_type_name,
                    LR.justification,
                    LR.duration,
                    LR.start_date,
                    LR.end_date,
                    LR.status,
                    LR.submission_date,
                    LR.approval_timing
                FROM LeaveRequest LR
                INNER JOIN [Leave] L ON LR.leave_id = L.leave_id
                WHERE LR.employee_id = @EmployeeId
                ORDER BY LR.submission_date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeId", employeeId);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToLeaveRequests(dataTable);
        }

        public async Task<IEnumerable<LeaveType>> GetLeaveTypesAsync()
        {
            var query = "SELECT leave_id, leave_type, leave_description FROM [Leave] ORDER BY leave_type";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var types = new List<LeaveType>();
            foreach (DataRow row in dataTable.Rows)
            {
                types.Add(new LeaveType
                {
                    LeaveId = Convert.ToInt32(row["leave_id"]),
                    LeaveTypeName = row["leave_type"]?.ToString() ?? "",
                    Description = row["leave_description"]?.ToString()
                });
            }

            return types;
        }

        public async Task CancelLeaveRequestAsync(int requestId, int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@RequestID", requestId),
                new SqlParameter("@EmployeeID", employeeId)
            };

            await _sqlHelper.ExecuteNonQueryAsync("CancelLeaveRequest", parameters);
        }

        public async Task AttachDocumentAsync(int requestId, string filePath)
        {
            var parameters = new[]
            {
                new SqlParameter("@RequestID", requestId),
                new SqlParameter("@FilePath", filePath)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AddLeaveDocument", parameters);
        }

        // ====================================================================
        // MANAGER METHODS
        // ====================================================================

        public async Task<IEnumerable<LeaveRequest>> GetPendingRequestsAsync(int managerId)
        {
            var query = @"
                SELECT 
                    LR.request_id,
                    LR.employee_id,
                    E.full_name AS employee_name,
                    LR.leave_id,
                    L.leave_type AS leave_type_name,
                    LR.justification,
                    LR.duration,
                    LR.start_date,
                    LR.end_date,
                    LR.status,
                    LR.submission_date,
                    (SELECT TOP 1 1 FROM LeaveFlag LF WHERE LF.employee_id = LR.employee_id AND LF.is_resolved = 0) AS is_flagged,
                    (SELECT TOP 1 pattern_description FROM LeaveFlag LF WHERE LF.employee_id = LR.employee_id AND LF.is_resolved = 0 ORDER BY flag_date DESC) AS flag_reason
                FROM LeaveRequest LR
                INNER JOIN Employee E ON LR.employee_id = E.employee_id
                INNER JOIN [Leave] L ON LR.leave_id = L.leave_id
                WHERE E.manager_id = @ManagerId AND LR.status = 'Pending'
                ORDER BY LR.submission_date ASC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@ManagerId", managerId);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToLeaveRequests(dataTable);
        }

        public async Task ApproveRequestAsync(int requestId, int approverId, string? comments)
        {
            var parameters = new[]
            {
                new SqlParameter("@LeaveRequestID", requestId),
                new SqlParameter("@ApproverID", approverId),
                new SqlParameter("@Status", "Approved")
            };

            await _sqlHelper.ExecuteNonQueryAsync("ApproveLeaveRequest", parameters);
            
            
    // Trigger notification for leave approval
    var requests = await GetAllLeaveRequestsAsync();
    var request = requests.FirstOrDefault(r => r.RequestId == requestId);
    
    if (request != null)
    {
        await _notificationService.CreateNotificationAsync(
            request.EmployeeId,
            $"Your leave request #{requestId} has been approved!",
            "Leave Approval",
            "Normal");

        // Automatically sync with attendance
        await SyncWithAttendanceAsync(requestId);
    }
        }

        public async Task RejectRequestAsync(int requestId, int approverId, string reason)
        {
            var parameters = new[]
            {
                new SqlParameter("@LeaveRequestID", requestId),
                new SqlParameter("@ApproverID", approverId),
                new SqlParameter("@Status", "Rejected")
            };

            await _sqlHelper.ExecuteNonQueryAsync("ApproveLeaveRequest", parameters);
            
            
    // Trigger notification for leave rejection
    var requests = await GetAllLeaveRequestsAsync();
    var request = requests.FirstOrDefault(r => r.RequestId == requestId);

    if (request != null)
    {
        await _notificationService.CreateNotificationAsync(
            request.EmployeeId,
            $"Your leave request #{requestId} has been rejected. Reason: {reason}",
            "Leave Rejection",
            "High");
    }
        }

        public async Task FlagIrregularLeaveAsync(int employeeId, int flaggedBy, string reason)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@ManagerID", flaggedBy),
                new SqlParameter("@PatternDescription", reason)
            };

            await _sqlHelper.ExecuteNonQueryAsync("FlagIrregularLeave", parameters);
        }

        // ====================================================================
        // HR ADMIN METHODS
        // ====================================================================

        public async Task<IEnumerable<LeavePolicy>> GetAllPoliciesAsync()
        {
            var query = @"
                SELECT policy_id, name, purpose, eligibility_rules, 
                       notice_period, special_leave_type, reset_on_new_year
                FROM LeavePolicy
                ORDER BY name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var policies = new List<LeavePolicy>();
            foreach (DataRow row in dataTable.Rows)
            {
                policies.Add(new LeavePolicy
                {
                    PolicyId = Convert.ToInt32(row["policy_id"]),
                    Name = row["name"]?.ToString() ?? "",
                    Purpose = row["purpose"]?.ToString(),
                    EligibilityRules = row["eligibility_rules"]?.ToString(),
                    NoticePeriod = row["notice_period"] != DBNull.Value ? Convert.ToInt32(row["notice_period"]) : 0,
                    SpecialLeaveType = row["special_leave_type"]?.ToString(),
                    ResetOnNewYear = row["reset_on_new_year"] != DBNull.Value && Convert.ToBoolean(row["reset_on_new_year"])
                });
            }

            return policies;
        }

        public async Task UpdatePolicyAsync(int policyId, string name, string purpose, string eligibilityRules, int noticePeriod, bool resetOnNewYear)
        {
            var parameters = new[]
            {
                new SqlParameter("@PolicyID", policyId),
                new SqlParameter("@Name", name),
                new SqlParameter("@Purpose", purpose),
                new SqlParameter("@EligibilityRules", eligibilityRules),
                new SqlParameter("@NoticePeriod", noticePeriod),
                new SqlParameter("@ResetOnNewYear", resetOnNewYear)
            };

            await _sqlHelper.ExecuteNonQueryAsync("UpdateLeavePolicy", parameters);
        }

        public async Task CreatePolicyAsync(LeavePolicy policy)
        {
            var parameters = new[]
            {
                new SqlParameter("@Name", policy.Name),
                new SqlParameter("@Purpose", (object?)policy.Purpose ?? DBNull.Value),
                new SqlParameter("@EligibilityRules", (object?)policy.EligibilityRules ?? DBNull.Value),
                new SqlParameter("@NoticePeriod", policy.NoticePeriod),
                new SqlParameter("@SpecialLeaveType", (object?)policy.SpecialLeaveType ?? DBNull.Value),
                new SqlParameter("@ResetOnNewYear", policy.ResetOnNewYear)
            };
            await _sqlHelper.ExecuteNonQueryAsync("CreateLeavePolicy", parameters);
        }

        public async Task<LeavePolicy?> GetPolicyByIdAsync(int id)
        {
            var policies = await GetAllPoliciesAsync();
            return policies.FirstOrDefault(p => p.PolicyId == id);
        }

        public async Task DeletePolicyAsync(int id)
        {
            var parameters = new[] { new SqlParameter("@PolicyID", id) };
            await _sqlHelper.ExecuteNonQueryAsync("DeleteLeavePolicy", parameters);
        }

        public async Task ManageLeaveTypeAsync(string action, int? leaveId, string leaveType, string? description)
        {
            var parameters = new[]
            {
                new SqlParameter("@Action", action),
                new SqlParameter("@LeaveID", (object?)leaveId ?? DBNull.Value),
                new SqlParameter("@LeaveType", leaveType),
                new SqlParameter("@Description", (object?)description ?? DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("ManageLeaveTypes", parameters);
        }

        public async Task AssignEntitlementAsync(int employeeId, int leaveTypeId, decimal entitlement)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@LeaveTypeID", leaveTypeId),
                new SqlParameter("@Entitlement", entitlement)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AssignLeaveEntitlement", parameters);
        }

        public async Task AdjustBalanceAsync(int employeeId, int leaveTypeId, string operation, decimal amount, string reason)
        {
            decimal finalAdjustment = operation == "Deduct" ? -amount : amount;

            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@LeaveTypeID", leaveTypeId),
                new SqlParameter("@Adjustment", finalAdjustment),
                new SqlParameter("@Reason", reason)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AdjustLeaveBalance", parameters);
        }

        public async Task OverrideDecisionAsync(int requestId, int adminId, string newStatus, string reason)
        {
            var parameters = new[]
            {
                new SqlParameter("@RequestID", requestId),
                new SqlParameter("@AdminID", adminId),
                new SqlParameter("@NewStatus", newStatus),
                new SqlParameter("@Reason", reason)
            };

            await _sqlHelper.ExecuteNonQueryAsync("OverrideLeaveDecision", parameters);
        }

        public async Task ConfigureSpecialLeaveAsync(string leaveType, int maxDays, string eligibilityRules)
        {
            var parameters = new[]
            {
                new SqlParameter("@LeaveType", leaveType),
                new SqlParameter("@MaxDays", maxDays),
                new SqlParameter("@EligibilityRules", eligibilityRules)
            };

            await _sqlHelper.ExecuteNonQueryAsync("ConfigureSpecialLeave", parameters);
        }

        public async Task SyncWithAttendanceAsync(int requestId)
        {
            var parameters = new[]
            {
                new SqlParameter("@LeaveRequestID", requestId)
            };

            await _sqlHelper.ExecuteNonQueryAsync("SyncLeaveToAttendance", parameters);
        }

        public async Task<IEnumerable<LeaveRequest>> GetAllLeaveRequestsAsync()
        {
            var query = @"
                SELECT 
                    LR.request_id,
                    LR.employee_id,
                    E.full_name AS employee_name,
                    LR.leave_id,
                    L.leave_type AS leave_type_name,
                    LR.justification,
                    LR.duration,
                    LR.start_date,
                    LR.end_date,
                    LR.status,
                    LR.submission_date,
                    LR.approval_timing,
                    (SELECT TOP 1 1 FROM LeaveFlag LF WHERE LF.employee_id = LR.employee_id AND LF.is_resolved = 0) AS is_flagged,
                    (SELECT TOP 1 pattern_description FROM LeaveFlag LF WHERE LF.employee_id = LR.employee_id AND LF.is_resolved = 0 ORDER BY flag_date DESC) AS flag_reason,
                    (SELECT TOP 1 file_path FROM LeaveDocument WHERE leave_request_id = LR.request_id) AS file_path
                FROM LeaveRequest LR
                INNER JOIN Employee E ON LR.employee_id = E.employee_id
                INNER JOIN [Leave] L ON LR.leave_id = L.leave_id
                ORDER BY LR.submission_date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToLeaveRequests(dataTable);
        }

        // ====================================================================
        // HELPER METHODS
        // ====================================================================

        private IEnumerable<LeaveRequest> MapToLeaveRequests(DataTable dataTable)
        {
            var requests = new List<LeaveRequest>();
            foreach (DataRow row in dataTable.Rows)
            {
                requests.Add(new LeaveRequest
                {
                    RequestId = Convert.ToInt32(row["request_id"]),
                    EmployeeId = Convert.ToInt32(row["employee_id"]),
                    EmployeeName = row.Table.Columns.Contains("employee_name") ? row["employee_name"]?.ToString() : null,
                    LeaveId = Convert.ToInt32(row["leave_id"]),
                    LeaveTypeName = row["leave_type_name"]?.ToString(),
                    Justification = row["justification"]?.ToString(),
                    Duration = row["duration"] != DBNull.Value ? Convert.ToInt32(row["duration"]) : 0,
                    StartDate = row.Table.Columns.Contains("start_date") && row["start_date"] != DBNull.Value ? Convert.ToDateTime(row["start_date"]) : null,
                    EndDate = row.Table.Columns.Contains("end_date") && row["end_date"] != DBNull.Value ? Convert.ToDateTime(row["end_date"]) : null,
                    Status = row["status"]?.ToString() ?? "Pending",
                    SubmissionDate = row["submission_date"] != DBNull.Value ? Convert.ToDateTime(row["submission_date"]) : DateTime.Now,
                    ApprovalTiming = row.Table.Columns.Contains("approval_timing") && row["approval_timing"] != DBNull.Value 
                        ? Convert.ToDateTime(row["approval_timing"]) : null,
                    DocumentPath = row.Table.Columns.Contains("file_path") && row["file_path"] != DBNull.Value ? row["file_path"].ToString() : null,
                    IsFlagged = row.Table.Columns.Contains("is_flagged") && row["is_flagged"] != DBNull.Value && Convert.ToInt32(row["is_flagged"]) == 1,
                    FlagReason = row.Table.Columns.Contains("flag_reason") ? row["flag_reason"]?.ToString() : null
                });
            }
            return requests;
        }
    }
}
