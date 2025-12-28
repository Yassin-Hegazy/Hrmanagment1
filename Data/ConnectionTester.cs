using Microsoft.Data.SqlClient;

namespace HRMANGMANGMENT.Data
{
    /// <summary>
    /// Utility class to test database connection
    /// </summary>
    public class ConnectionTester
    {
        public static async Task<(bool Success, string Message)> TestConnectionAsync(string connectionString)
        {
            try
            {
                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();
                
                // Test a simple query
                using var command = new SqlCommand("SELECT @@VERSION", connection);
                var version = await command.ExecuteScalarAsync();
                
                return (true, $"Connection successful! SQL Server Version: {version}");
            }
            catch (SqlException ex)
            {
                return (false, $"SQL Error: {ex.Message}");
            }
            catch (Exception ex)
            {
                return (false, $"Error: {ex.Message}");
            }
        }

        public static async Task<(bool Success, string Message)> TestDatabaseExistsAsync(string connectionString, string databaseName)
        {
            try
            {
                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();
                
                var query = "SELECT COUNT(*) FROM sys.databases WHERE name = @DatabaseName";
                using var command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("@DatabaseName", databaseName);
                
                var count = (int)await command.ExecuteScalarAsync()!;
                
                if (count > 0)
                {
                    return (true, $"Database '{databaseName}' exists!");
                }
                else
                {
                    return (false, $"Database '{databaseName}' does not exist.");
                }
            }
            catch (Exception ex)
            {
                return (false, $"Error checking database: {ex.Message}");
            }
        }
    }
}
