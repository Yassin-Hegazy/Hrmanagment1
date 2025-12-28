using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface ILeaveService
    {
        // ========== EMPLOYEE METHODS ==========
        Task<int> SubmitLeaveRequestAsync(int employeeId, int leaveTypeId, DateTime startDate, DateTime endDate, string reason);
        Task<IEnumerable<LeaveEntitlement>> GetLeaveBalanceAsync(int employeeId);
        Task<IEnumerable<LeaveRequest>> GetLeaveHistoryAsync(int employeeId);
        Task<IEnumerable<LeaveType>> GetLeaveTypesAsync();
        Task CancelLeaveRequestAsync(int requestId, int employeeId);
        Task AttachDocumentAsync(int requestId, string filePath);
        
        // ========== MANAGER METHODS ==========
        Task<IEnumerable<LeaveRequest>> GetPendingRequestsAsync(int managerId);
        Task ApproveRequestAsync(int requestId, int approverId, string? comments);
        Task RejectRequestAsync(int requestId, int approverId, string reason);
        Task FlagIrregularLeaveAsync(int employeeId, int flaggedBy, string reason);
        
        // ========== HR ADMIN METHODS ==========
        Task<IEnumerable<LeavePolicy>> GetAllPoliciesAsync();
        Task CreatePolicyAsync(LeavePolicy policy);
        Task<LeavePolicy?> GetPolicyByIdAsync(int id);
        Task DeletePolicyAsync(int id);
        Task UpdatePolicyAsync(int policyId, string name, string purpose, string eligibilityRules, int noticePeriod, bool resetOnNewYear);
        Task ManageLeaveTypeAsync(string action, int? leaveId, string leaveType, string? description);
        Task AssignEntitlementAsync(int employeeId, int leaveTypeId, decimal entitlement);
        Task AdjustBalanceAsync(int employeeId, int leaveTypeId, string operation, decimal amount, string reason);
        Task OverrideDecisionAsync(int requestId, int adminId, string newStatus, string reason);
        Task ConfigureSpecialLeaveAsync(string leaveType, int maxDays, string eligibilityRules);
        Task SyncWithAttendanceAsync(int requestId);
        Task<IEnumerable<LeaveRequest>> GetAllLeaveRequestsAsync();
    }
}
