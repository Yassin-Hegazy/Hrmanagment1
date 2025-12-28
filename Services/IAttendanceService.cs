using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IAttendanceService
    {
        Task RecordAttendanceAsync(int employeeId, DateTime timestamp, string method);
        Task<Attendance?> GetCurrentAttendanceAsync(int employeeId);
        Task<IEnumerable<Attendance>> GetEmployeeAttendanceAsync(int employeeId, int days = 30);
        Task<IEnumerable<Attendance>> GetTeamAttendanceAsync(int managerId, DateTime? startDate = null, DateTime? endDate = null);
        Task SubmitCorrectionRequestAsync(AttendanceCorrectionRequest request);
        Task<IEnumerable<AttendanceCorrectionRequest>> GetPendingCorrectionsAsync(int? managerId = null);
        
        // Correction approval workflow
        Task<IEnumerable<AttendanceCorrectionRequest>> GetPendingCorrectionsForManagerAsync(int managerId);
        Task ApproveCorrectionRequestAsync(int requestId, int approverId, DateTime? correctTime = null);
        Task RejectCorrectionRequestAsync(int requestId, int approverId, string reason);
        
        // Attendance time rules
        Task SetGracePeriodAsync(int gracePeriodMinutes);
        Task DefinePenaltyThresholdAsync(int lateThresholdMinutes, decimal penaltyAmount);
        Task DefineShortTimeRulesAsync(int shortTimeThresholdMinutes);
        
        // Offline sync
        Task SyncOfflineAttendanceAsync(int employeeId, DateTime clockTime, string type);
        
        // Leave integration
        Task SyncLeaveWithAttendanceAsync(int vacationPackageId, int employeeId);
        
        // Exception handling
        Task ApplyExceptionToAttendanceAsync(int exceptionId, DateTime date);
    }
}
