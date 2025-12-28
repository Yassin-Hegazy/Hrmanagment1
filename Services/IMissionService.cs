using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IMissionService
    {
        // Employee methods
        Task<IEnumerable<Mission>> GetMyMissionsAsync(int employeeId);
        Task<Mission?> GetMissionByIdAsync(int missionId);
        
        // Manager methods
        Task<IEnumerable<Mission>> GetPendingMissionsAsync(int managerId);
        Task ApproveMissionAsync(int missionId, int approverId);
        Task RejectMissionAsync(int missionId, int approverId, string reason);
        
        // HR Admin methods
        Task AssignMissionAsync(int employeeId, int managerId, string destination, DateTime startDate, DateTime endDate);
        Task<IEnumerable<Mission>> GetAllMissionsAsync();
        Task UpdateMissionStatusAsync(int missionId, string status);
    }
}
