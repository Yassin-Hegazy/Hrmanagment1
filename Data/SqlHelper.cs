using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Data
{
    public class SqlHelper
    {
        private readonly string _connectionString;

        public SqlHelper(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("HRDatabase")
                ?? throw new InvalidOperationException("Connection string 'HRDatabase' not found.");
        }

        public string GetConnectionString() => _connectionString;


        /// <summary>
        /// Executes a stored procedure and returns a DataTable with results
        /// </summary>
        public async Task<DataTable> ExecuteStoredProcedureAsync(string procedureName, params SqlParameter[] parameters)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(procedureName, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            if (parameters != null && parameters.Length > 0)
            {
                command.Parameters.AddRange(parameters);
            }

            var dataTable = new DataTable();
            await connection.OpenAsync();

            using var adapter = new SqlDataAdapter(command);
            adapter.Fill(dataTable);

            return dataTable;
        }

        /// <summary>
        /// Executes a stored procedure that doesn't return results (INSERT, UPDATE, DELETE)
        /// </summary>
        public async Task<int> ExecuteNonQueryAsync(string procedureName, params SqlParameter[] parameters)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(procedureName, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            if (parameters != null && parameters.Length > 0)
            {
                command.Parameters.AddRange(parameters);
            }

            await connection.OpenAsync();
            return await command.ExecuteNonQueryAsync();
        }

        /// <summary>
        /// Executes a raw SQL query (not a stored procedure)
        /// </summary>
        public async Task<int> ExecuteRawSqlAsync(string sqlQuery, params SqlParameter[] parameters)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sqlQuery, connection)
            {
                CommandType = CommandType.Text
            };

            if (parameters != null && parameters.Length > 0)
            {
                command.Parameters.AddRange(parameters);
            }

            await connection.OpenAsync();
            return await command.ExecuteNonQueryAsync();
        }

        /// <summary>
        /// Executes a stored procedure and returns a single scalar value
        /// </summary>
        public async Task<object?> ExecuteScalarAsync(string procedureName, params SqlParameter[] parameters)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(procedureName, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            if (parameters != null && parameters.Length > 0)
            {
                command.Parameters.AddRange(parameters);
            }

            await connection.OpenAsync();
            return await command.ExecuteScalarAsync();
        }

        /// <summary>
        /// Executes a stored procedure and returns a SqlDataReader for efficient reading
        /// </summary>
        public async Task<SqlDataReader> ExecuteReaderAsync(string procedureName, params SqlParameter[] parameters)
        {
            var connection = new SqlConnection(_connectionString);
            var command = new SqlCommand(procedureName, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            if (parameters != null && parameters.Length > 0)
            {
                command.Parameters.AddRange(parameters);
            }

            await connection.OpenAsync();
            return await command.ExecuteReaderAsync(CommandBehavior.CloseConnection);
        }
    }
}
