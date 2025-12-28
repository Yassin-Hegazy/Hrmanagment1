using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class AttendanceService : IAttendanceService
    {
        private readonly SqlHelper _sqlHelper;

        public AttendanceService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        public async Task RecordAttendanceAsync(int employeeId, DateTime timestamp, string method)
        {
            // Check if employee already has an attendance record for today
            var currentAttendance = await GetCurrentAttendanceAsync(employeeId);
            
            if (currentAttendance == null || currentAttendance.ExitTime.HasValue)
            {
                // Clock In - Create new attendance record
                // Check for grace period and lateness
                var isLate = await CheckLatenessAsync(employeeId, timestamp);
                
                var query = @"
                    INSERT INTO Attendance (employee_id, entry_time, login_method, shift_id)
                    VALUES (@EmployeeId, @EntryTime, @Method, 
                           (SELECT TOP 1 shift_id FROM ShiftAssignment 
                            WHERE employee_id = @EmployeeId 
                              AND status = 'Active' 
                              AND @EntryTime BETWEEN start_date AND ISNULL(end_date, '2099-12-31')))";

                using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
                using var command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("@EmployeeId", employeeId);
                command.Parameters.AddWithValue("@EntryTime", timestamp);
                command.Parameters.AddWithValue("@Method", method);
                
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();
                
                // Log lateness if applicable
                if (isLate)
                {
                    await LogLatenessAsync(employeeId, timestamp);
                }
            }
            else
            {
                // Clock Out - Update existing attendance record
                var duration = (timestamp - currentAttendance.EntryTime!.Value).TotalHours;
                
                var query = @"
                    UPDATE Attendance 
                    SET exit_time = @ExitTime, 
                        logout_method = @Method,
                        duration = @Duration
                    WHERE attendance_id = @AttendanceId";

                using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
                using var command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("@AttendanceId", currentAttendance.AttendanceId);
                command.Parameters.AddWithValue("@ExitTime", timestamp);
                command.Parameters.AddWithValue("@Method", method);
                command.Parameters.AddWithValue("@Duration", duration);
                
                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task<bool> CheckLatenessAsync(int employeeId, DateTime clockInTime)
        {
            // Get employee's shift details including Split and Rotational info
            var query = @"
                SELECT ss.start_time, ss.type, ss.break_start_time, ss.break_duration, ss.cycle_id, sa.start_date
                FROM ShiftAssignment sa
                INNER JOIN ShiftSchedule ss ON sa.shift_id = ss.shift_id
                WHERE sa.employee_id = @EmployeeId
                  AND sa.status = 'Active'
                  AND @ClockInTime BETWEEN sa.start_date AND ISNULL(sa.end_date, '2099-12-31')
                ORDER BY sa.start_date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeId", employeeId);
            command.Parameters.AddWithValue("@ClockInTime", clockInTime);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
                return false; // No shift assigned

            var shiftStartTime = reader.GetTimeSpan(0); // start_time
            var shiftType = reader.IsDBNull(1) ? "Normal" : reader.GetString(1);
            var breakStartTime = reader.IsDBNull(2) ? (TimeSpan?)null : reader.GetTimeSpan(2);
            var breakDuration = reader.IsDBNull(3) ? 0m : reader.GetDecimal(3);
            var cycleId = reader.IsDBNull(4) ? (int?)null : reader.GetInt32(4);
            var assignmentStartDate = reader.GetDateTime(5);

            TimeSpan targetStartTime = shiftStartTime;

            // Handle Rotational Shift Logic
            if (shiftType.Equals("Rotational", StringComparison.OrdinalIgnoreCase) && cycleId.HasValue)
            {
                reader.Close(); // Close previous reader to execute new query

                var cycleQuery = @"
                    SELECT sca.order_number, ss.start_time
                    FROM ShiftCycleAssignment sca
                    INNER JOIN ShiftSchedule ss ON sca.shift_id = ss.shift_id
                    WHERE sca.cycle_id = @CycleId
                    ORDER BY sca.order_number";

                using var cycleCommand = new SqlCommand(cycleQuery, connection);
                cycleCommand.Parameters.AddWithValue("@CycleId", cycleId.Value);
                
                using var cycleReader = await cycleCommand.ExecuteReaderAsync();
                var cycleSteps = new List<(int Order, TimeSpan Start)>();
                while (await cycleReader.ReadAsync())
                {
                    cycleSteps.Add((cycleReader.GetInt32(0), cycleReader.GetTimeSpan(1)));
                }

                if (cycleSteps.Count > 0)
                {
                    int daysElapsed = (clockInTime.Date - assignmentStartDate.Date).Days;
                    if (daysElapsed >= 0)
                    {
                        int cycleIndex = daysElapsed % cycleSteps.Count;
                        // Assuming order_number is 1-based or 0-based sequential
                        // We'll just take the element at index
                        if (cycleIndex < cycleSteps.Count)
                        {
                            targetStartTime = cycleSteps[cycleIndex].Start;
                            shiftStartTime = targetStartTime; // Update base for split check if needed
                        }
                    }
                }
            }

            // Handle Split Shift Logic
            if (shiftType.Equals("Split", StringComparison.OrdinalIgnoreCase) && breakStartTime.HasValue)
            {
                // Calculate Slot 2 Start Time
                // breakDuration is decimal hours
                var slot2StartTime = breakStartTime.Value.Add(TimeSpan.FromMinutes((double)(breakDuration * 60)));
                
                // Determine which slot we are clocking in for
                var timeOfDay = clockInTime.TimeOfDay;
                
                // Simple heuristic: If after break start, assume slot 2
                // Or if closer to slot 2 than slot 1
                var diff1 = Math.Abs((timeOfDay - shiftStartTime).TotalMinutes);
                var diff2 = Math.Abs((timeOfDay - slot2StartTime).TotalMinutes);

                if (diff2 < diff1 && timeOfDay > shiftStartTime)
                {
                    targetStartTime = slot2StartTime;
                }
            }

            // Get grace period (default 15 minutes if not set)
            var gracePeriodMinutes = await GetGracePeriodAsync();
            
            var shiftStartDateTime = clockInTime.Date.Add(targetStartTime);
            var graceEndTime = shiftStartDateTime.AddMinutes(gracePeriodMinutes);

            return clockInTime > graceEndTime;
        }

        private async Task<int> GetGracePeriodAsync()
        {
            try
            {
                var query = "SELECT TOP 1 threshold_minutes FROM AttendanceRule WHERE rule_type = 'GracePeriod' AND is_active = 1";
                
                using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
                using var command = new SqlCommand(query, connection);
                
                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                
                return result != null ? Convert.ToInt32(result) : 15; // Default 15 minutes
            }
            catch (SqlException)
            {
                // AttendanceRule table doesn't exist or query failed
                // Return default grace period
                return 15; // Default 15 minutes
            }
        }

        private async Task LogLatenessAsync(int employeeId, DateTime clockInTime)
        {
            var query = @"
                INSERT INTO AttendanceLog (attendance_id, actor, timestamp, reason)
                SELECT TOP 1 attendance_id, 'System', GETDATE(), 'Late arrival detected'
                FROM Attendance
                WHERE employee_id = @EmployeeId
                  AND CAST(entry_time AS DATE) = CAST(@ClockInTime AS DATE)
                ORDER BY entry_time DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeId", employeeId);
            command.Parameters.AddWithValue("@ClockInTime", clockInTime);

            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
        }

        public async Task<Attendance?> GetCurrentAttendanceAsync(int employeeId)
        {
            var query = @"
                SELECT TOP 1 a.attendance_id, a.employee_id, a.shift_id, 
                       a.entry_time, a.exit_time, a.duration, 
                       a.login_method, a.logout_method, a.exception_id
                FROM Attendance a
                WHERE a.employee_id = @EmployeeId
                ORDER BY a.entry_time DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeId", employeeId);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            if (dataTable.Rows.Count == 0)
                return null;

            return MapToAttendance(dataTable.Rows[0]);
        }

        public async Task<IEnumerable<Attendance>> GetEmployeeAttendanceAsync(int employeeId, int days = 30)
        {
            var query = @"
                SELECT a.attendance_id, a.employee_id, a.shift_id, 
                       a.entry_time, a.exit_time, a.duration, 
                       a.login_method, a.logout_method, a.exception_id,
                       e.full_name as employee_name,
                       s.name as shift_name,
                       CASE WHEN EXISTS (SELECT 1 FROM AttendanceLog al WHERE al.attendance_id = a.attendance_id AND al.reason LIKE '%Late%') THEN 1 ELSE 0 END as is_late
                FROM Attendance a
                INNER JOIN Employee e ON a.employee_id = e.employee_id
                LEFT JOIN ShiftSchedule s ON a.shift_id = s.shift_id
                WHERE a.employee_id = @EmployeeId 
                  AND a.entry_time >= DATEADD(day, -@Days, GETDATE())
                ORDER BY a.entry_time DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeId", employeeId);
            command.Parameters.AddWithValue("@Days", days);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var attendances = new List<Attendance>();
            foreach (DataRow row in dataTable.Rows)
            {
                attendances.Add(MapToAttendance(row));
            }

            return attendances;
        }

        public async Task<IEnumerable<Attendance>> GetTeamAttendanceAsync(int managerId, DateTime? startDate = null, DateTime? endDate = null)
        {
            var start = startDate ?? DateTime.Today.AddDays(-7);
            var end = endDate ?? DateTime.Today;

            var query = @"
                SELECT a.attendance_id, a.employee_id, a.shift_id, 
                       a.entry_time, a.exit_time, a.duration, 
                       a.login_method, a.logout_method, a.exception_id,
                       e.full_name as employee_name,
                       s.name as shift_name,
                       CASE WHEN EXISTS (SELECT 1 FROM AttendanceLog al WHERE al.attendance_id = a.attendance_id AND al.reason LIKE '%Late%') THEN 1 ELSE 0 END as is_late
                FROM Attendance a
                INNER JOIN Employee e ON a.employee_id = e.employee_id
                LEFT JOIN ShiftSchedule s ON a.shift_id = s.shift_id
                WHERE e.manager_id = @ManagerId
                  AND CAST(a.entry_time AS DATE) BETWEEN @StartDate AND @EndDate
                ORDER BY e.full_name, a.entry_time DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@ManagerId", managerId);
            command.Parameters.AddWithValue("@StartDate", start);
            command.Parameters.AddWithValue("@EndDate", end);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var attendances = new List<Attendance>();
            foreach (DataRow row in dataTable.Rows)
            {
                attendances.Add(MapToAttendance(row));
            }

            return attendances;
        }

        public async Task SubmitCorrectionRequestAsync(AttendanceCorrectionRequest request)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", request.EmployeeId),
                new SqlParameter("@Date", request.Date),
                new SqlParameter("@CorrectionType", request.CorrectionType),
                new SqlParameter("@Reason", request.Reason)
            };

            await _sqlHelper.ExecuteNonQueryAsync("SubmitCorrectionRequest", parameters);
        }

        public async Task<IEnumerable<AttendanceCorrectionRequest>> GetPendingCorrectionsAsync(int? managerId = null)
        {
            var query = @"
                SELECT acr.request_id, acr.employee_id, acr.date, 
                       acr.correction_type, acr.reason, acr.status, acr.recorded_by,
                       e.full_name as employee_name
                FROM AttendanceCorrectionRequest acr
                INNER JOIN Employee e ON acr.employee_id = e.employee_id
                WHERE acr.status = 'Pending'";

            if (managerId.HasValue)
            {
                query += " AND e.manager_id = @ManagerId";
            }

            query += " ORDER BY acr.date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            if (managerId.HasValue)
            {
                command.Parameters.AddWithValue("@ManagerId", managerId.Value);
            }
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var requests = new List<AttendanceCorrectionRequest>();
            foreach (DataRow row in dataTable.Rows)
            {
                requests.Add(MapToCorrectionRequest(row));
            }

            return requests;
        }

        // ====================================================================
        // ATTENDANCE TIME RULES
        // ====================================================================

        public async Task SetGracePeriodAsync(int gracePeriodMinutes)
        {
            var parameters = new[]
            {
                new SqlParameter("@Minutes", gracePeriodMinutes)
            };

            await _sqlHelper.ExecuteNonQueryAsync("SetGracePeriod", parameters);
        }

        public async Task DefinePenaltyThresholdAsync(int lateThresholdMinutes, decimal penaltyAmount)
        {
            var parameters = new[]
            {
                new SqlParameter("@LateMinutes", lateThresholdMinutes),
                new SqlParameter("@DeductionType", penaltyAmount.ToString())
            };

            await _sqlHelper.ExecuteNonQueryAsync("DefinePenaltyThreshold", parameters);
        }

        public async Task DefineShortTimeRulesAsync(int shortTimeThresholdMinutes)
        {
            var parameters = new[]
            {
                new SqlParameter("@RuleName", "Short Time Rule"),
                new SqlParameter("@LateMinutes", shortTimeThresholdMinutes),
                new SqlParameter("@EarlyLeaveMinutes", shortTimeThresholdMinutes),
                new SqlParameter("@PenaltyType", "Warning")
            };

            await _sqlHelper.ExecuteNonQueryAsync("DefineShortTimeRules", parameters);
        }

        public async Task SyncOfflineAttendanceAsync(int employeeId, DateTime clockTime, string type)
        {
            var parameters = new[]
            {
                new SqlParameter("@DeviceID", 1), // Default device
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@ClockTime", clockTime),
                new SqlParameter("@Type", type.ToUpper()) // IN or OUT
            };

            await _sqlHelper.ExecuteNonQueryAsync("SyncOfflineAttendance", parameters);
        }

        public async Task SyncLeaveWithAttendanceAsync(int vacationPackageId, int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@VacationPackageID", vacationPackageId),
                new SqlParameter("@EmployeeID", employeeId)
            };

            await _sqlHelper.ExecuteNonQueryAsync("LinkVacationToShift", parameters);
        }

        // ====================================================================
        // CORRECTION APPROVAL WORKFLOW
        // ====================================================================

        public async Task<IEnumerable<AttendanceCorrectionRequest>> GetPendingCorrectionsForManagerAsync(int managerId)
        {
            return await GetPendingCorrectionsAsync(managerId);
        }

        public async Task ApproveCorrectionRequestAsync(int requestId, int approverId, DateTime? correctTime = null)
        {
            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            await connection.OpenAsync();
            using var transaction = connection.BeginTransaction();

            try
            {
                // Get the correction request details
                var getRequestQuery = @"
                    SELECT employee_id, date, correction_type 
                    FROM AttendanceCorrectionRequest 
                    WHERE request_id = @RequestId";

                using var getCommand = new SqlCommand(getRequestQuery, connection, transaction);
                getCommand.Parameters.AddWithValue("@RequestId", requestId);

                int employeeId = 0;
                DateTime date = DateTime.MinValue;
                string correctionType = "";

                using (var reader = await getCommand.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        employeeId = reader.GetInt32(0);
                        date = reader.GetDateTime(1);
                        correctionType = reader.GetString(2);
                    }
                }

                if (employeeId == 0)
                {
                    throw new Exception("Correction request not found");
                }

                // Update the correction request status
                var updateRequestQuery = @"
                    UPDATE AttendanceCorrectionRequest 
                    SET status = 'Approved' 
                    WHERE request_id = @RequestId";

                using var updateCommand = new SqlCommand(updateRequestQuery, connection, transaction);
                updateCommand.Parameters.AddWithValue("@RequestId", requestId);
                await updateCommand.ExecuteNonQueryAsync();

                // Apply the correction to attendance
                if (correctTime.HasValue)
                {
                    var updateAttendanceQuery = correctionType.ToLower() switch
                    {
                        "checkin" => @"
                            UPDATE Attendance 
                            SET entry_time = @CorrectTime 
                            WHERE employee_id = @EmployeeId 
                              AND CAST(entry_time AS DATE) = @Date",
                        "checkout" => @"
                            UPDATE Attendance 
                            SET exit_time = @CorrectTime,
                                duration = DATEDIFF(HOUR, entry_time, @CorrectTime)
                            WHERE employee_id = @EmployeeId 
                              AND CAST(entry_time AS DATE) = @Date",
                        _ => @"
                            UPDATE Attendance 
                            SET entry_time = @CorrectTime 
                            WHERE employee_id = @EmployeeId 
                              AND CAST(entry_time AS DATE) = @Date"
                    };

                    using var attendanceCommand = new SqlCommand(updateAttendanceQuery, connection, transaction);
                    attendanceCommand.Parameters.AddWithValue("@EmployeeId", employeeId);
                    attendanceCommand.Parameters.AddWithValue("@Date", date.Date);
                    attendanceCommand.Parameters.AddWithValue("@CorrectTime", correctTime.Value);
                    await attendanceCommand.ExecuteNonQueryAsync();
                }

                // Log the approval
                var logQuery = @"
                    INSERT INTO AttendanceLog (attendance_id, actor, timestamp, reason)
                    SELECT TOP 1 attendance_id, @Actor, GETDATE(), 'Correction approved'
                    FROM Attendance 
                    WHERE employee_id = @EmployeeId 
                      AND CAST(entry_time AS DATE) = @Date";

                using var logCommand = new SqlCommand(logQuery, connection, transaction);
                logCommand.Parameters.AddWithValue("@Actor", $"Manager {approverId}");
                logCommand.Parameters.AddWithValue("@EmployeeId", employeeId);
                logCommand.Parameters.AddWithValue("@Date", date.Date);
                await logCommand.ExecuteNonQueryAsync();

                transaction.Commit();
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }

        public async Task RejectCorrectionRequestAsync(int requestId, int approverId, string reason)
        {
            var query = @"
                UPDATE AttendanceCorrectionRequest 
                SET status = 'Rejected', reason = @Reason 
                WHERE request_id = @RequestId";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@RequestId", requestId);
            command.Parameters.AddWithValue("@Reason", reason);

            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
        }

        // ====================================================================
        // EXCEPTION HANDLING
        // ====================================================================

        public async Task ApplyExceptionToAttendanceAsync(int exceptionId, DateTime date)
        {
            var query = @"
                UPDATE Attendance 
                SET exception_id = @ExceptionId
                WHERE CAST(entry_time AS DATE) = @Date OR CAST(exit_time AS DATE) = @Date";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@ExceptionId", exceptionId);
            command.Parameters.AddWithValue("@Date", date.Date);

            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
        }

        private Attendance MapToAttendance(DataRow row)
        {
            return new Attendance
            {
                AttendanceId = Convert.ToInt32(row["attendance_id"]),
                EmployeeId = Convert.ToInt32(row["employee_id"]),
                ShiftId = row["shift_id"] != DBNull.Value ? Convert.ToInt32(row["shift_id"]) : null,
                EntryTime = row["entry_time"] != DBNull.Value ? Convert.ToDateTime(row["entry_time"]) : null,
                ExitTime = row["exit_time"] != DBNull.Value ? Convert.ToDateTime(row["exit_time"]) : null,
                Duration = row["duration"] != DBNull.Value ? Convert.ToDecimal(row["duration"]) : null,
                LoginMethod = row["login_method"]?.ToString(),
                LogoutMethod = row["logout_method"]?.ToString(),
                ExceptionId = row["exception_id"] != DBNull.Value ? Convert.ToInt32(row["exception_id"]) : null,
                EmployeeName = row.Table.Columns.Contains("employee_name") ? row["employee_name"]?.ToString() : null,
                ShiftName = row.Table.Columns.Contains("shift_name") ? row["shift_name"]?.ToString() : null,
                IsLate = row.Table.Columns.Contains("is_late") && row["is_late"] != DBNull.Value && Convert.ToInt32(row["is_late"]) == 1
            };
        }

        private AttendanceCorrectionRequest MapToCorrectionRequest(DataRow row)
        {
            return new AttendanceCorrectionRequest
            {
                RequestId = Convert.ToInt32(row["request_id"]),
                EmployeeId = Convert.ToInt32(row["employee_id"]),
                Date = Convert.ToDateTime(row["date"]),
                CorrectionType = row["correction_type"]?.ToString() ?? string.Empty,
                Reason = row["reason"]?.ToString() ?? string.Empty,
                Status = row["status"]?.ToString() ?? "Pending",
                RecordedBy = row["recorded_by"] != DBNull.Value ? Convert.ToInt32(row["recorded_by"]) : null,
                EmployeeName = row.Table.Columns.Contains("employee_name") ? row["employee_name"]?.ToString() : null
            };
        }
    }
}
