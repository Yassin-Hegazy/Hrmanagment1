using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class MissionService : IMissionService
    {
        private readonly SqlHelper _sqlHelper;
        private readonly INotificationService _notificationService;

        public MissionService(SqlHelper sqlHelper, INotificationService notificationService)
        {
            _sqlHelper = sqlHelper;
            _notificationService = notificationService;
        }

        // ====================================================================
        // EMPLOYEE METHODS
        // ====================================================================

        public async Task<IEnumerable<Mission>> GetMyMissionsAsync(int employeeId)
        {
            var query = @"
                SELECT 
                    m.mission_id,
                    m.destination,
                    m.start_date,
                    m.end_date,
                    m.status,
                    m.employee_id,
                    m.manager_id,
                    e.full_name AS employee_name,
                    mgr.full_name AS manager_name
                FROM Mission m
                INNER JOIN Employee e ON m.employee_id = e.employee_id
                LEFT JOIN Employee mgr ON m.manager_id = mgr.employee_id
                WHERE m.employee_id = @EmployeeId
                ORDER BY m.start_date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeId", employeeId);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToMissions(dataTable);
        }

        public async Task<Mission?> GetMissionByIdAsync(int missionId)
        {
            var query = @"
                SELECT 
                    m.mission_id,
                    m.destination,
                    m.start_date,
                    m.end_date,
                    m.status,
                    m.employee_id,
                    m.manager_id,
                    e.full_name AS employee_name,
                    mgr.full_name AS manager_name
                FROM Mission m
                INNER JOIN Employee e ON m.employee_id = e.employee_id
                LEFT JOIN Employee mgr ON m.manager_id = mgr.employee_id
                WHERE m.mission_id = @MissionId";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@MissionId", missionId);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToMissions(dataTable).FirstOrDefault();
        }

        // ====================================================================
        // MANAGER METHODS
        // ====================================================================

        public async Task<IEnumerable<Mission>> GetPendingMissionsAsync(int managerId)
        {
            var query = @"
                SELECT 
                    m.mission_id,
                    m.destination,
                    m.start_date,
                    m.end_date,
                    m.status,
                    m.employee_id,
                    m.manager_id,
                    e.full_name AS employee_name,
                    mgr.full_name AS manager_name
                FROM Mission m
                INNER JOIN Employee e ON m.employee_id = e.employee_id
                LEFT JOIN Employee mgr ON m.manager_id = mgr.employee_id
                WHERE m.manager_id = @ManagerId AND m.status = 'Pending'
                ORDER BY m.start_date ASC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@ManagerId", managerId);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToMissions(dataTable);
        }

        public async Task ApproveMissionAsync(int missionId, int approverId)
        {
            var parameters = new[]
            {
                new SqlParameter("@MissionID", missionId),
                new SqlParameter("@ManagerID", approverId),
                new SqlParameter("@Remarks", "Approved")
            };

            await _sqlHelper.ExecuteNonQueryAsync("ApproveMissionCompletion", parameters);
            
            // Trigger notification for mission approval
            var mission = await GetMissionByIdAsync(missionId);
            if (mission != null)
            {
                await _notificationService.CreateNotificationAsync(
                    mission.EmployeeId,
                    $"Your mission to {mission.Destination} has been approved!",
                    "Mission Update",
                    "Normal");
            }
        }

        public async Task RejectMissionAsync(int missionId, int approverId, string reason)
        {
            // Update status directly since procedure may not have rejection
            var query = @"UPDATE Mission SET status = 'Rejected' WHERE mission_id = @MissionId";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@MissionId", missionId);

            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
            
            // Trigger notification for mission rejection
            var mission = await GetMissionByIdAsync(missionId);
            if (mission != null)
            {
                await _notificationService.CreateNotificationAsync(
                    mission.EmployeeId,
                    $"Your mission to {mission.Destination} has been rejected. Reason: {reason}",
                    "Mission Update",
                    "Medium");
            }
        }

        // ====================================================================
        // HR ADMIN METHODS
        // ====================================================================

        public async Task AssignMissionAsync(int employeeId, int managerId, string destination, DateTime startDate, DateTime endDate)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@ManagerID", managerId),
                new SqlParameter("@Destination", destination),
                new SqlParameter("@StartDate", startDate),
                new SqlParameter("@EndDate", endDate)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AssignMission", parameters);
            
            // Trigger notification for the EMPLOYEE about their new mission
            await _notificationService.CreateNotificationAsync(
                employeeId,
                $"You have been assigned a new mission to {destination} from {startDate:MMM dd} to {endDate:MMM dd, yyyy}.",
                "Mission Update",
                "Normal");
            
            // Trigger notification for the MANAGER to review and approve/reject
            await _notificationService.CreateNotificationAsync(
                managerId,
                $"New mission request pending your approval: {destination} ({startDate:MMM dd} - {endDate:MMM dd}). Please review in 'Mission Approvals'.",
                "Mission Approval Needed",
                "High");
        }

        public async Task<IEnumerable<Mission>> GetAllMissionsAsync()
        {
            var query = @"
                SELECT 
                    m.mission_id,
                    m.destination,
                    m.start_date,
                    m.end_date,
                    m.status,
                    m.employee_id,
                    m.manager_id,
                    e.full_name AS employee_name,
                    mgr.full_name AS manager_name
                FROM Mission m
                INNER JOIN Employee e ON m.employee_id = e.employee_id
                LEFT JOIN Employee mgr ON m.manager_id = mgr.employee_id
                ORDER BY m.start_date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToMissions(dataTable);
        }

        public async Task UpdateMissionStatusAsync(int missionId, string status)
        {
            var query = @"UPDATE Mission SET status = @Status WHERE mission_id = @MissionId";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@MissionId", missionId);
            command.Parameters.AddWithValue("@Status", status);

            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
            
            // Trigger notification for mission status update
            var mission = await GetMissionByIdAsync(missionId);
            if (mission != null)
            {
                await _notificationService.CreateNotificationAsync(
                    mission.EmployeeId,
                    $"Your mission to {mission.Destination} status has been updated to: {status}.",
                    "Mission Update",
                    "Normal");
            }
        }

        // ====================================================================
        // HELPER METHODS
        // ====================================================================

        private IEnumerable<Mission> MapToMissions(DataTable dataTable)
        {
            var missions = new List<Mission>();
            foreach (DataRow row in dataTable.Rows)
            {
                missions.Add(new Mission
                {
                    MissionId = Convert.ToInt32(row["mission_id"]),
                    Destination = row["destination"]?.ToString() ?? "",
                    StartDate = Convert.ToDateTime(row["start_date"]),
                    EndDate = Convert.ToDateTime(row["end_date"]),
                    Status = row["status"]?.ToString() ?? "Pending",
                    EmployeeId = Convert.ToInt32(row["employee_id"]),
                    ManagerId = row["manager_id"] != DBNull.Value ? Convert.ToInt32(row["manager_id"]) : null,
                    EmployeeName = row["employee_name"]?.ToString(),
                    ManagerName = row["manager_name"]?.ToString()
                });
            }
            return missions;
        }
    }
}
