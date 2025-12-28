using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;


namespace HRMANGMANGMENT.Services
{
    public class DepartmentService : IDepartmentService
    {
        private readonly SqlHelper _sqlHelper;

        public DepartmentService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        public async Task<IEnumerable<Department>> GetAllDepartmentsAsync()
        {
            // Direct query to get all departments
            var query = @"
                SELECT 
                    d.department_id,
                    d.department_name,
                    d.purpose,
                    d.department_head_id,
                    e.full_name as head_name,
                    COUNT(emp.employee_id) as employee_count
                FROM Department d
                LEFT JOIN Employee e ON d.department_head_id = e.employee_id
                LEFT JOIN Employee emp ON emp.department_id = d.department_id
                GROUP BY d.department_id, d.department_name, d.purpose, d.department_head_id, e.full_name
                ORDER BY d.department_name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var departments = new List<Department>();
            foreach (DataRow row in dataTable.Rows)
            {
                departments.Add(MapToDepartment(row));
            }

            return departments;
        }

        public async Task<Department?> GetDepartmentByIdAsync(int departmentId)
        {
            var query = @"
                SELECT 
                    d.department_id,
                    d.department_name,
                    d.purpose,
                    d.department_head_id,
                    e.full_name as head_name,
                    COUNT(emp.employee_id) as employee_count
                FROM Department d
                LEFT JOIN Employee e ON d.department_head_id = e.employee_id
                LEFT JOIN Employee emp ON emp.department_id = d.department_id
                WHERE d.department_id = @DepartmentID
                GROUP BY d.department_id, d.department_name, d.purpose, d.department_head_id, e.full_name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@DepartmentID", departmentId);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            if (dataTable.Rows.Count == 0)
                return null;

            return MapToDepartment(dataTable.Rows[0]);
        }

        public async Task<int> AddDepartmentAsync(Department department)
        {
            var query = @"
                INSERT INTO Department (department_name, purpose, department_head_id)
                VALUES (@DepartmentName, @Purpose, @DepartmentHeadID);
                SELECT CAST(SCOPE_IDENTITY() as int);";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            command.Parameters.AddWithValue("@DepartmentName", department.DepartmentName);
            command.Parameters.AddWithValue("@Purpose", (object?)department.Purpose ?? DBNull.Value);
            command.Parameters.AddWithValue("@DepartmentHeadID", (object?)department.DepartmentHeadId ?? DBNull.Value);
            
            await connection.OpenAsync();
            var newId = await command.ExecuteScalarAsync();
            
            return Convert.ToInt32(newId);
        }

        public async Task UpdateDepartmentAsync(Department department)
        {
            var query = @"
                UPDATE Department 
                SET department_name = @DepartmentName,
                    purpose = @Purpose,
                    department_head_id = @DepartmentHeadID
                WHERE department_id = @DepartmentID";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            command.Parameters.AddWithValue("@DepartmentID", department.DepartmentId);
            command.Parameters.AddWithValue("@DepartmentName", department.DepartmentName);
            command.Parameters.AddWithValue("@Purpose", (object?)department.Purpose ?? DBNull.Value);
            command.Parameters.AddWithValue("@DepartmentHeadID", (object?)department.DepartmentHeadId ?? DBNull.Value);
            
            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
        }

        public async Task AssignDepartmentHeadAsync(int departmentId, int employeeId)
        {
            var query = @"
                UPDATE Department 
                SET department_head_id = @NewHeadID
                WHERE department_id = @DepartmentID";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            command.Parameters.AddWithValue("@DepartmentID", departmentId);
            command.Parameters.AddWithValue("@NewHeadID", employeeId);
            
            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
        }

        public async Task<IEnumerable<Employee>> GetDepartmentEmployeesAsync(int departmentId)
        {
            var parameters = new[]
            {
                new SqlParameter("@FilterField", "department_id"),
                new SqlParameter("@FilterValue", departmentId.ToString())
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GenerateProfileReport", parameters);

            var employees = new List<Employee>();
            foreach (DataRow row in dataTable.Rows)
            {
                employees.Add(MapToEmployee(row));
            }

            return employees;
        }

        private Department MapToDepartment(DataRow row)
        {
            var table = row.Table;
            
            return new Department
            {
                DepartmentId = table.Columns.Contains("department_id") 
                    ? Convert.ToInt32(row["department_id"]) 
                    : (table.Columns.Contains("DepartmentID") ? Convert.ToInt32(row["DepartmentID"]) : 0),
                    
                DepartmentName = table.Columns.Contains("department_name") 
                    ? (row["department_name"]?.ToString() ?? string.Empty)
                    : (table.Columns.Contains("DepartmentName") ? (row["DepartmentName"]?.ToString() ?? string.Empty) : string.Empty),
                    
                Purpose = table.Columns.Contains("purpose") 
                    ? row["purpose"]?.ToString() 
                    : (table.Columns.Contains("Purpose") ? row["Purpose"]?.ToString() : null),
                    
                DepartmentHeadId = table.Columns.Contains("department_head_id") && row["department_head_id"] != DBNull.Value 
                    ? Convert.ToInt32(row["department_head_id"]) 
                    : (table.Columns.Contains("DepartmentHeadID") && row["DepartmentHeadID"] != DBNull.Value ? Convert.ToInt32(row["DepartmentHeadID"]) : null),
                    
                DepartmentHeadName = table.Columns.Contains("head_name") 
                    ? row["head_name"]?.ToString() 
                    : (table.Columns.Contains("HeadName") ? row["HeadName"]?.ToString() : null),
                    
                EmployeeCount = table.Columns.Contains("employee_count") 
                    ? Convert.ToInt32(row["employee_count"]) 
                    : (table.Columns.Contains("EmployeeCount") ? Convert.ToInt32(row["EmployeeCount"]) : 0)
            };
        }

        private Employee MapToEmployee(DataRow row)
        {
            return new Employee
            {
                EmployeeId = Convert.ToInt32(row["employee_id"]),
                FirstName = row["first_name"].ToString() ?? string.Empty,
                LastName = row["last_name"].ToString() ?? string.Empty,
                FullName = row["full_name"].ToString(),
                Email = row["email"].ToString(),
                Phone = row["phone"].ToString(),
                DepartmentName = row.Table.Columns.Contains("department_name") ? row["department_name"].ToString() : null,
                PositionTitle = row.Table.Columns.Contains("position_title") ? row["position_title"].ToString() : null,
                IsActive = row["is_active"] != DBNull.Value && Convert.ToBoolean(row["is_active"])
            };
        }
    }
}
