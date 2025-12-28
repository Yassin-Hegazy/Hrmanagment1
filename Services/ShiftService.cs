using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class ShiftService : IShiftService
    {
        private readonly SqlHelper _sqlHelper;

        public ShiftService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        public async Task<IEnumerable<ShiftSchedule>> GetAllShiftsAsync()
        {
            var query = @"
                SELECT shift_id, name, type, start_time, end_time, 
                       break_duration, shift_date, status
                FROM ShiftSchedule
                ORDER BY name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var shifts = new List<ShiftSchedule>();
            foreach (DataRow row in dataTable.Rows)
            {
                shifts.Add(MapToShiftSchedule(row));
            }

            return shifts;
        }

        public async Task<ShiftSchedule?> GetShiftByIdAsync(int shiftId)
        {
            var query = @"
                SELECT shift_id, name, type, start_time, end_time, 
                       break_duration, shift_date, status
                FROM ShiftSchedule
                WHERE shift_id = @ShiftId";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@ShiftId", shiftId);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            if (dataTable.Rows.Count == 0)
                return null;

            return MapToShiftSchedule(dataTable.Rows[0]);
        }

        public async Task<int> CreateShiftAsync(ShiftSchedule shift)
        {
            var query = @"
                INSERT INTO ShiftSchedule (name, type, start_time, end_time, break_duration, break_start_time, shift_date, status)
                VALUES (@Name, @Type, @StartTime, @EndTime, @BreakDuration, @BreakStartTime, @ShiftDate, @Status);
                SELECT CAST(SCOPE_IDENTITY() as int);";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            command.Parameters.AddWithValue("@Name", shift.Name);
            command.Parameters.AddWithValue("@Type", shift.Type);
            command.Parameters.AddWithValue("@StartTime", shift.StartTime);
            command.Parameters.AddWithValue("@EndTime", shift.EndTime);
            command.Parameters.AddWithValue("@BreakDuration", shift.BreakDuration);
            command.Parameters.AddWithValue("@BreakStartTime", (object?)shift.BreakStartTime ?? DBNull.Value);
            command.Parameters.AddWithValue("@ShiftDate", (object?)shift.ShiftDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@Status", shift.Status);
            
            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result);
        }

        public async Task AssignShiftToDepartmentAsync(int departmentId, int shiftId, DateTime startDate, DateTime? endDate)
        {
            var parameters = new[]
            {
                new SqlParameter("@DepartmentID", departmentId),
                new SqlParameter("@ShiftID", shiftId),
                new SqlParameter("@StartDate", startDate),
                new SqlParameter("@EndDate", (object?)endDate ?? DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AssignShiftToDepartment", parameters);
        }

        public async Task AssignShiftToEmployeeAsync(int employeeId, int shiftId, DateTime startDate, DateTime? endDate)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@ShiftID", shiftId),
                new SqlParameter("@StartDate", startDate),
                new SqlParameter("@EndDate", (object?)endDate ?? DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AssignShiftToEmployee", parameters);
        }

        public async Task<IEnumerable<ShiftAssignment>> GetEmployeeShiftAssignmentsAsync(int employeeId)
        {
            var query = @"
                SELECT sa.assignment_id, sa.employee_id, sa.shift_id, 
                       sa.start_date, sa.end_date, sa.status,
                       e.full_name as employee_name, s.name as shift_name
                FROM ShiftAssignment sa
                INNER JOIN Employee e ON sa.employee_id = e.employee_id
                INNER JOIN ShiftSchedule s ON sa.shift_id = s.shift_id
                WHERE sa.employee_id = @EmployeeId
                ORDER BY sa.start_date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeId", employeeId);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var assignments = new List<ShiftAssignment>();
            foreach (DataRow row in dataTable.Rows)
            {
                assignments.Add(MapToShiftAssignment(row));
            }

            return assignments;
        }

        // ====================================================================
        // ADVANCED SHIFT FEATURES
        // ====================================================================

        public async Task ConfigureSplitShiftAsync(string shiftName, TimeSpan firstSlotStart, TimeSpan firstSlotEnd, TimeSpan secondSlotStart, TimeSpan secondSlotEnd)
        {
            var parameters = new[]
            {
                new SqlParameter("@ShiftName", shiftName),
                new SqlParameter("@FirstSlotStart", firstSlotStart),
                new SqlParameter("@FirstSlotEnd", firstSlotEnd),
                new SqlParameter("@SecondSlotStart", secondSlotStart),
                new SqlParameter("@SecondSlotEnd", secondSlotEnd)
            };

            await _sqlHelper.ExecuteNonQueryAsync("ConfigureSplitShift", parameters);
        }

        public async Task AssignRotationalShiftAsync(int employeeId, int shiftCycle, DateTime startDate, DateTime endDate, string status)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@ShiftCycle", shiftCycle),
                new SqlParameter("@StartDate", startDate),
                new SqlParameter("@EndDate", endDate),
                new SqlParameter("@Status", status)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AssignRotationalShift", parameters);
        }

        public async Task AssignCustomShiftAsync(int employeeId, string shiftName, string shiftType, TimeSpan startTime, TimeSpan endTime, DateTime startDate, DateTime endDate)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@ShiftName", shiftName),
                new SqlParameter("@ShiftType", shiftType),
                new SqlParameter("@StartTime", startTime),
                new SqlParameter("@EndTime", endTime),
                new SqlParameter("@StartDate", startDate),
                new SqlParameter("@EndDate", endDate)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AssignCustomShift", parameters);
        }

        private ShiftSchedule MapToShiftSchedule(DataRow row)
        {
            return new ShiftSchedule
            {
                ShiftId = Convert.ToInt32(row["shift_id"]),
                Name = row["name"]?.ToString() ?? string.Empty,
                Type = row["type"]?.ToString() ?? string.Empty,
                StartTime = row["start_time"] != DBNull.Value ? (TimeSpan)row["start_time"] : TimeSpan.Zero,
                EndTime = row["end_time"] != DBNull.Value ? (TimeSpan)row["end_time"] : TimeSpan.Zero,
                BreakDuration = row["break_duration"] != DBNull.Value ? Convert.ToDecimal(row["break_duration"]) : 0,
                ShiftDate = row["shift_date"] != DBNull.Value ? Convert.ToDateTime(row["shift_date"]) : null,
                Status = row["status"] != DBNull.Value && Convert.ToBoolean(row["status"])
            };
        }

        private ShiftAssignment MapToShiftAssignment(DataRow row)
        {
            return new ShiftAssignment
            {
                AssignmentId = Convert.ToInt32(row["assignment_id"]),
                EmployeeId = Convert.ToInt32(row["employee_id"]),
                ShiftId = Convert.ToInt32(row["shift_id"]),
                StartDate = Convert.ToDateTime(row["start_date"]),
                EndDate = row["end_date"] != DBNull.Value ? Convert.ToDateTime(row["end_date"]) : null,
                Status = row["status"]?.ToString() ?? "Active",
                EmployeeName = row.Table.Columns.Contains("employee_name") ? row["employee_name"]?.ToString() : null,
                ShiftName = row.Table.Columns.Contains("shift_name") ? row["shift_name"]?.ToString() : null
            };
        }
    }
}
