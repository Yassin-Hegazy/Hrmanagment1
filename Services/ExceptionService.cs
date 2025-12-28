using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class ExceptionService : IExceptionService
    {
        private readonly string _connectionString;

        public ExceptionService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new InvalidOperationException("Connection string not found");
        }

        public async Task<IEnumerable<ExceptionDay>> GetAllExceptionsAsync()
        {
            var exceptions = new List<ExceptionDay>();

            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand("SELECT * FROM Exception ORDER BY date DESC", connection);

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        exceptions.Add(MapException(reader));
                    }
                }
            }

            return exceptions;
        }

        public async Task<ExceptionDay?> GetExceptionByIdAsync(int exceptionId)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand("SELECT * FROM Exception WHERE exception_id = @ExceptionId", connection);
                command.Parameters.AddWithValue("@ExceptionId", exceptionId);

                using (var reader = await command.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return MapException(reader);
                    }
                }
            }

            return null;
        }

        public async Task<IEnumerable<ExceptionDay>> GetExceptionsByDateRangeAsync(DateTime startDate, DateTime endDate)
        {
            var exceptions = new List<ExceptionDay>();

            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand(
                    "SELECT * FROM Exception WHERE date BETWEEN @StartDate AND @EndDate ORDER BY date", 
                    connection);
                command.Parameters.AddWithValue("@StartDate", startDate.Date);
                command.Parameters.AddWithValue("@EndDate", endDate.Date);

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        exceptions.Add(MapException(reader));
                    }
                }
            }

            return exceptions;
        }

        public async Task<IEnumerable<ExceptionDay>> GetExceptionsByCategoryAsync(string category)
        {
            var exceptions = new List<ExceptionDay>();

            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand(
                    "SELECT * FROM Exception WHERE category = @Category ORDER BY date DESC", 
                    connection);
                command.Parameters.AddWithValue("@Category", category);

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        exceptions.Add(MapException(reader));
                    }
                }
            }

            return exceptions;
        }

        public async Task<int> CreateExceptionAsync(ExceptionDay exception)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand(
                    @"INSERT INTO Exception (name, category, date, status) 
                      VALUES (@Name, @Category, @Date, @Status);
                      SELECT CAST(SCOPE_IDENTITY() as int);", 
                    connection);

                command.Parameters.AddWithValue("@Name", exception.Name);
                command.Parameters.AddWithValue("@Category", exception.Category);
                command.Parameters.AddWithValue("@Date", exception.Date.Date);
                command.Parameters.AddWithValue("@Status", exception.Status);

                var exceptionId = (int)await command.ExecuteScalarAsync();

                // Auto-apply exception to attendance records for that date
                await ApplyExceptionToAttendanceAsync(exceptionId, exception.Date);

                return exceptionId;
            }
        }

        public async Task UpdateExceptionAsync(ExceptionDay exception)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand(
                    @"UPDATE Exception 
                      SET name = @Name, category = @Category, date = @Date, status = @Status
                      WHERE exception_id = @ExceptionId", 
                    connection);

                command.Parameters.AddWithValue("@ExceptionId", exception.ExceptionId);
                command.Parameters.AddWithValue("@Name", exception.Name);
                command.Parameters.AddWithValue("@Category", exception.Category);
                command.Parameters.AddWithValue("@Date", exception.Date.Date);
                command.Parameters.AddWithValue("@Status", exception.Status);

                await command.ExecuteNonQueryAsync();
            }
        }

        public async Task DeleteExceptionAsync(int exceptionId)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand("DELETE FROM Exception WHERE exception_id = @ExceptionId", connection);
                command.Parameters.AddWithValue("@ExceptionId", exceptionId);

                await command.ExecuteNonQueryAsync();
            }
        }

        public async Task ApplyExceptionToAttendanceAsync(int exceptionId, DateTime date)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand(
                    @"UPDATE Attendance 
                      SET exception_id = @ExceptionId
                      WHERE CAST(entry_time AS DATE) = @Date OR CAST(exit_time AS DATE) = @Date", 
                    connection);

                command.Parameters.AddWithValue("@ExceptionId", exceptionId);
                command.Parameters.AddWithValue("@Date", date.Date);

                await command.ExecuteNonQueryAsync();
            }
        }

        public async Task<bool> IsExceptionDateAsync(DateTime date)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                var command = new SqlCommand(
                    "SELECT COUNT(*) FROM Exception WHERE date = @Date AND status = 'Active'", 
                    connection);
                command.Parameters.AddWithValue("@Date", date.Date);

                var count = (int)await command.ExecuteScalarAsync();
                return count > 0;
            }
        }

        private ExceptionDay MapException(SqlDataReader reader)
        {
            return new ExceptionDay
            {
                ExceptionId = reader.GetInt32(reader.GetOrdinal("exception_id")),
                Name = reader.GetString(reader.GetOrdinal("name")),
                Category = reader.IsDBNull(reader.GetOrdinal("category")) ? "" : reader.GetString(reader.GetOrdinal("category")),
                Date = reader.GetDateTime(reader.GetOrdinal("date")),
                Status = reader.IsDBNull(reader.GetOrdinal("status")) ? "Active" : reader.GetString(reader.GetOrdinal("status"))
            };
        }
    }
}
