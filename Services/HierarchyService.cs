using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class HierarchyService : IHierarchyService
    {
        private readonly SqlHelper _sqlHelper;

        public HierarchyService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        // ====================================================================
        // ORGANIZATION CHART
        // ====================================================================

        public async Task<OrganizationChart> GetOrganizationChartAsync()
        {
            var chart = new OrganizationChart();

            // Get counts
            var countQuery = @"
                SELECT 
                    (SELECT COUNT(*) FROM Employee) AS TotalEmployees,
                    (SELECT COUNT(*) FROM Department) AS TotalDepartments,
                    (SELECT COUNT(DISTINCT manager_id) FROM Employee WHERE manager_id IS NOT NULL) AS TotalManagers";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var countCmd = new SqlCommand(countQuery, connection);

            await connection.OpenAsync();
            using var reader = await countCmd.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                chart.TotalEmployees = reader["TotalEmployees"] != DBNull.Value ? Convert.ToInt32(reader["TotalEmployees"]) : 0;
                chart.TotalDepartments = reader["TotalDepartments"] != DBNull.Value ? Convert.ToInt32(reader["TotalDepartments"]) : 0;
                chart.TotalManagers = reader["TotalManagers"] != DBNull.Value ? Convert.ToInt32(reader["TotalManagers"]) : 0;
            }

            await reader.CloseAsync();

            // Get department teams
            chart.Departments = (await GetDepartmentTeamsAsync()).ToList();

            return chart;
        }

        // ====================================================================
        // DEPARTMENT TEAMS
        // ====================================================================

        public async Task<IEnumerable<DepartmentTeam>> GetDepartmentTeamsAsync()
        {
            var query = @"
                SELECT 
                    d.department_id,
                    d.department_name,
                    d.department_head_id,
                    head.full_name AS HeadName,
                    (SELECT COUNT(*) FROM Employee e WHERE e.department_id = d.department_id) AS EmployeeCount
                FROM Department d
                LEFT JOIN Employee head ON d.department_head_id = head.employee_id
                ORDER BY d.department_name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var teams = new List<DepartmentTeam>();
            foreach (DataRow row in dataTable.Rows)
            {
                teams.Add(new DepartmentTeam
                {
                    DepartmentId = Convert.ToInt32(row["department_id"]),
                    DepartmentName = row["department_name"]?.ToString() ?? "",
                    HeadEmployeeId = row["department_head_id"] != DBNull.Value ? Convert.ToInt32(row["department_head_id"]) : null,
                    HeadName = row["HeadName"]?.ToString(),
                    EmployeeCount = row["EmployeeCount"] != DBNull.Value ? Convert.ToInt32(row["EmployeeCount"]) : 0
                });
            }

            return teams;
        }

        public async Task<DepartmentTeam?> GetDepartmentTeamAsync(int departmentId)
        {
            var teams = await GetDepartmentTeamsAsync();
            var team = teams.FirstOrDefault(t => t.DepartmentId == departmentId);
            
            if (team != null)
            {
                team.Members = (await GetEmployeesByDepartmentAsync(departmentId)).ToList();
            }

            return team;
        }

        public async Task<IEnumerable<TeamMember>> GetEmployeesByDepartmentAsync(int departmentId)
        {
            var query = @"
                SELECT 
                    e.employee_id,
                    e.full_name,
                    p.position_title,
                    e.profile_image,
                    e.manager_id,
                    m.full_name AS ManagerName,
                    e.department_id,
                    d.department_name,
                    (SELECT COUNT(*) FROM Employee sub WHERE sub.manager_id = e.employee_id) AS DirectReports
                FROM Employee e
                LEFT JOIN Position p ON e.position_id = p.position_id
                LEFT JOIN Employee m ON e.manager_id = m.employee_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                WHERE e.department_id = @DepartmentId
                ORDER BY e.full_name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@DepartmentId", departmentId);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToTeamMembers(dataTable);
        }

        // ====================================================================
        // MANAGER TEAMS
        // ====================================================================

        public async Task<ManagerTeam?> GetManagerTeamAsync(int managerId)
        {
            // Get manager info
            var managerQuery = @"
                SELECT 
                    e.employee_id,
                    e.full_name,
                    p.position_title,
                    e.profile_image,
                    e.department_id,
                    d.department_name
                FROM Employee e
                LEFT JOIN Position p ON e.position_id = p.position_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                WHERE e.employee_id = @ManagerId";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(managerQuery, connection);
            command.Parameters.AddWithValue("@ManagerId", managerId);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (!await reader.ReadAsync())
                return null;

            var team = new ManagerTeam
            {
                ManagerId = Convert.ToInt32(reader["employee_id"]),
                ManagerName = reader["full_name"]?.ToString() ?? "",
                Position = reader["position_title"]?.ToString(),
                ProfileImage = reader["profile_image"]?.ToString(),
                DepartmentId = reader["department_id"] != DBNull.Value ? Convert.ToInt32(reader["department_id"]) : null,
                DepartmentName = reader["department_name"]?.ToString()
            };

            await reader.CloseAsync();

            // Get direct reports
            team.DirectReports = (await GetDirectReportsAsync(managerId)).ToList();

            return team;
        }

        public async Task<IEnumerable<TeamMember>> GetDirectReportsAsync(int managerId)
        {
            var query = @"
                SELECT 
                    e.employee_id,
                    e.full_name,
                    p.position_title,
                    e.profile_image,
                    e.manager_id,
                    m.full_name AS ManagerName,
                    e.department_id,
                    d.department_name,
                    (SELECT COUNT(*) FROM Employee sub WHERE sub.manager_id = e.employee_id) AS DirectReports
                FROM Employee e
                LEFT JOIN Position p ON e.position_id = p.position_id
                LEFT JOIN Employee m ON e.manager_id = m.employee_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                WHERE e.manager_id = @ManagerId
                ORDER BY e.full_name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@ManagerId", managerId);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            return MapToTeamMembers(dataTable);
        }

        // ====================================================================
        // HIERARCHY TREE - Using ViewOrgHierarchy stored procedure
        // ====================================================================

        public async Task<IEnumerable<HierarchyNode>> GetHierarchyTreeAsync()
        {
            // Use the ViewOrgHierarchy stored procedure
            var parameters = new SqlParameter[] { };
            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("ViewOrgHierarchy", parameters);

            // Build a dictionary of all nodes
            var allNodes = new Dictionary<int, HierarchyNode>();
            foreach (DataRow row in dataTable.Rows)
            {
                var empId = row["employee_id"] != DBNull.Value ? Convert.ToInt32(row["employee_id"]) : 0;
                if (empId == 0) continue;

                // Get direct reports count
                int directReports = 0;
                if (dataTable.Columns.Contains("DirectReports") && row["DirectReports"] != DBNull.Value)
                    directReports = Convert.ToInt32(row["DirectReports"]);

                // Get manager_id
                int? managerId = null;
                if (dataTable.Columns.Contains("manager_id") && row["manager_id"] != DBNull.Value)
                    managerId = Convert.ToInt32(row["manager_id"]);

                // Get hierarchy level
                int level = 0;
                if (dataTable.Columns.Contains("hierarchy_level") && row["hierarchy_level"] != DBNull.Value)
                    level = Convert.ToInt32(row["hierarchy_level"]);

                // Get position/title
                string? title = null;
                if (dataTable.Columns.Contains("position_title") && row["position_title"] != DBNull.Value)
                    title = row["position_title"].ToString();
                else if (dataTable.Columns.Contains("position") && row["position"] != DBNull.Value)
                    title = row["position"].ToString();

                // Get name
                string name = "";
                if (dataTable.Columns.Contains("full_name") && row["full_name"] != DBNull.Value)
                    name = row["full_name"].ToString() ?? "";
                else if (dataTable.Columns.Contains("employee_name") && row["employee_name"] != DBNull.Value)
                    name = row["employee_name"].ToString() ?? "";

                allNodes[empId] = new HierarchyNode
                {
                    Id = empId,
                    Name = name,
                    Title = title,
                    ProfileImage = dataTable.Columns.Contains("profile_image") && row["profile_image"] != DBNull.Value 
                        ? row["profile_image"].ToString() : null,
                    Type = directReports > 0 ? "Manager" : "Employee",
                    ParentId = managerId,
                    Level = level,
                    ChildCount = directReports
                };
            }

            // Build the tree structure
            var rootNodes = new List<HierarchyNode>();
            foreach (var node in allNodes.Values)
            {
                if (node.ParentId.HasValue && allNodes.ContainsKey(node.ParentId.Value))
                {
                    allNodes[node.ParentId.Value].Children.Add(node);
                }
                else
                {
                    // No parent = root node
                    rootNodes.Add(node);
                }
            }

            return rootNodes;
        }

        // ====================================================================
        // REASSIGNMENT - Using stored procedures
        // ====================================================================

        public async Task ReassignEmployeeAsync(int employeeId, int? newDepartmentId, int? newManagerId)
        {
            if (!newDepartmentId.HasValue && !newManagerId.HasValue)
                throw new Exception("No changes specified for reassignment");

            // Use appropriate stored procedure based on what's being changed
            if (newDepartmentId.HasValue || (newDepartmentId.HasValue && newManagerId.HasValue))
            {
                // Use ReassignHierarchy for department and/or manager changes
                var parameters = new SqlParameter[]
                {
                    new SqlParameter("@EmployeeID", employeeId),
                    new SqlParameter("@NewDepartmentID", newDepartmentId ?? (object)DBNull.Value),
                    new SqlParameter("@NewManagerID", newManagerId ?? (object)DBNull.Value)
                };

                await _sqlHelper.ExecuteNonQueryAsync("ReassignHierarchy", parameters);
            }
            else if (newManagerId.HasValue)
            {
                // Use ReassignManager for manager-only changes
                var parameters = new SqlParameter[]
                {
                    new SqlParameter("@EmployeeID", employeeId),
                    new SqlParameter("@NewManagerID", newManagerId.Value)
                };

                await _sqlHelper.ExecuteNonQueryAsync("ReassignManager", parameters);
            }

            // Notify affected employees of the structure change
            await NotifyStructureChangeAsync(employeeId.ToString(), "Your organizational assignment has been updated.");
        }

        // Notify employees of structure changes
        public async Task NotifyStructureChangeAsync(string affectedEmployees, string message)
        {
            try
            {
                var parameters = new SqlParameter[]
                {
                    new SqlParameter("@AffectedEmployees", affectedEmployees),
                    new SqlParameter("@Message", message)
                };

                await _sqlHelper.ExecuteNonQueryAsync("NotifyStructureChange", parameters);
            }
            catch
            {
                // Notification failure shouldn't block reassignment
            }
        }

        public async Task<IEnumerable<TeamMember>> GetAllManagersAsync()
        {
            var query = @"
                SELECT DISTINCT
                    e.employee_id,
                    e.full_name,
                    p.position_title,
                    e.profile_image,
                    e.manager_id,
                    m.full_name AS ManagerName,
                    e.department_id,
                    d.department_name,
                    (SELECT COUNT(*) FROM Employee sub WHERE sub.manager_id = e.employee_id) AS DirectReports
                FROM Employee e
                LEFT JOIN Position p ON e.position_id = p.position_id
                LEFT JOIN Employee m ON e.manager_id = m.employee_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                WHERE e.employee_id IN (SELECT DISTINCT manager_id FROM Employee WHERE manager_id IS NOT NULL)
                   OR e.employee_id IN (SELECT department_head_id FROM Department WHERE department_head_id IS NOT NULL)
                ORDER BY e.full_name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var members = MapToTeamMembers(dataTable);
            foreach (var m in members) m.IsManager = true;
            return members;
        }

        // ====================================================================
        // HIERARCHY TABLE MANAGEMENT
        // ====================================================================

        public async Task RebuildHierarchyTableAsync()
        {
            var parameters = new SqlParameter[] { };
            // Using ExecuteStoredProcedureAsync returning DataTable, ignoring result
            await _sqlHelper.ExecuteStoredProcedureAsync("BuildEmployeeHierarchy", parameters);
        }

        public async Task<IEnumerable<HierarchyTableEntry>> GetHierarchyTableEntriesAsync()
        {
            var query = @"
                SELECT 
                    eh.employee_id, (e.first_name + ' ' + e.last_name) AS EmpName,
                    eh.manager_id, ISNULL((m.first_name + ' ' + m.last_name), 'No Manager (CEO)') AS MgrName,
                    eh.hierarchy_level
                FROM EmployeeHierarchy eh
                JOIN Employee e ON eh.employee_id = e.employee_id
                LEFT JOIN Employee m ON eh.manager_id = m.employee_id AND eh.manager_id != eh.employee_id
                ORDER BY eh.hierarchy_level, e.first_name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);

            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var entries = new List<HierarchyTableEntry>();
            foreach (DataRow row in dataTable.Rows)
            {
                entries.Add(new HierarchyTableEntry
                {
                    EmployeeId = Convert.ToInt32(row["employee_id"]),
                    EmployeeName = row["EmpName"]?.ToString() ?? "",
                    ManagerId = row["manager_id"] != DBNull.Value ? Convert.ToInt32(row["manager_id"]) : 0,
                    ManagerName = row["MgrName"]?.ToString() ?? "No Manager",
                    HierarchyLevel = Convert.ToInt32(row["hierarchy_level"])
                });
            }
            return entries;
        }

        public async Task UpdateHierarchyLevelAsync(int employeeId, int managerId, int newLevel)
        {
            var query = "UPDATE EmployeeHierarchy SET hierarchy_level = @Level WHERE employee_id = @E AND manager_id = @M";
            var parameters = new[]
            {
                new SqlParameter("@Level", newLevel),
                new SqlParameter("@E", employeeId),
                new SqlParameter("@M", managerId)
            };
            
            await _sqlHelper.ExecuteRawSqlAsync(query, parameters);
        }

        // ====================================================================
        // HELPER METHODS
        // ====================================================================

        // ====================================================================
        // CYCLE DETECTION & DATA LOADING
        // ====================================================================

        public async Task<List<int>> GetAllSubordinatesAsync(int employeeId)
        {
            // Recursive CTE to get all subordinates down the chain
            var query = @"
                WITH SubordinatesCTE AS (
                    SELECT employee_id, manager_id
                    FROM Employee
                    WHERE manager_id = @EmployeeId
                    
                    UNION ALL
                    
                    SELECT e.employee_id, e.manager_id
                    FROM Employee e
                    INNER JOIN SubordinatesCTE s ON e.manager_id = s.employee_id
                )
                SELECT employee_id FROM SubordinatesCTE";

            var parameters = new[] { new SqlParameter("@EmployeeId", employeeId) };
            var subordinates = new List<int>();

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddRange(parameters);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                subordinates.Add(reader.GetInt32(0));
            }

            return subordinates;
        }

        public async Task<bool> WouldCreateCycleAsync(int employeeId, int newManagerId)
        {
            if (employeeId == newManagerId) return true; // Cannot manage self

            // If the new manager is currently a subordinate of the employee, that creates a cycle
            var subordinates = await GetAllSubordinatesAsync(employeeId);
            return subordinates.Contains(newManagerId);
        }

        public async Task<ManageLevelsViewModel> GetManageLevelsDataAsync()
        {
            var viewModel = new ManageLevelsViewModel();

            // 1. Get all employees with hierarchy info
            // Joining Employee table to get current Departments as well
            var query = @"
                SELECT 
                    eh.employee_id, 
                    (e.first_name + ' ' + e.last_name) AS EmpName,
                    eh.manager_id, 
                    ISNULL((m.first_name + ' ' + m.last_name), 'No Manager (CEO)') AS MgrName,
                    e.department_id,
                    d.department_name,
                    eh.hierarchy_level
                FROM EmployeeHierarchy eh
                JOIN Employee e ON eh.employee_id = e.employee_id
                LEFT JOIN Employee m ON eh.manager_id = m.employee_id AND eh.manager_id != eh.employee_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                ORDER BY eh.hierarchy_level, e.first_name";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            await connection.OpenAsync();
            
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            // 2. Map to ViewModel Rows
            var rows = new List<EmployeeReassignmentRow>();
            foreach (DataRow row in dataTable.Rows)
            {
                var empId = Convert.ToInt32(row["employee_id"]);
                rows.Add(new EmployeeReassignmentRow
                {
                    EmployeeId = empId,
                    EmployeeName = row["EmpName"]?.ToString() ?? "",
                    CurrentManagerId = row["manager_id"] != DBNull.Value ? Convert.ToInt32(row["manager_id"]) : null,
                    CurrentManagerName = row["MgrName"]?.ToString() ?? "No Manager",
                    CurrentDepartmentId = row["department_id"] != DBNull.Value ? Convert.ToInt32(row["department_id"]) : null,
                    CurrentDepartmentName = row["department_name"]?.ToString() ?? "Unassigned",
                    HierarchyLevel = Convert.ToInt32(row["hierarchy_level"]),
                    // Subordinates will be loaded on demand or we accept slight overhead here?
                    // For 83 employees, we can lazy load or just checking cycle on backend is safer.
                    // Frontend will just exclude SELF.
                });
            }
            viewModel.Employees = rows;

            // 3. Get Available Managers (Anyone who is an employee can potentialy be a manager, 
            // but we usually filter to at least header level or just everyone?)
            // Requirement says "A dropdown to select a new Manager" -> usually implies any employee could be a manager.
            var allEmployeesQuery = "SELECT employee_id, (first_name + ' ' + last_name) as full_name FROM Employee ORDER BY first_name";
            using var cmd2 = new SqlCommand(allEmployeesQuery, connection); // Reuse connection
            using var reader2 = await cmd2.ExecuteReaderAsync();
            while (await reader2.ReadAsync())
            {
                viewModel.AvailableManagers.Add(new ManagerOption
                {
                    EmployeeId = reader2.GetInt32(0),
                    FullName = reader2.GetString(1)
                });
            }
            await reader2.CloseAsync();

            // 4. Get Available Departments
            var deptQuery = "SELECT department_id, department_name FROM Department ORDER BY department_name";
            using var cmd3 = new SqlCommand(deptQuery, connection);
            using var reader3 = await cmd3.ExecuteReaderAsync();
            while (await reader3.ReadAsync())
            {
                viewModel.AvailableDepartments.Add(new DepartmentOption
                {
                    DepartmentId = reader3.GetInt32(0),
                    DepartmentName = reader3.GetString(1)
                });
            }

            return viewModel;
        }

        private List<TeamMember> MapToTeamMembers(DataTable dataTable)
        {
            var members = new List<TeamMember>();
            foreach (DataRow row in dataTable.Rows)
            {
                var directReports = row["DirectReports"] != DBNull.Value ? Convert.ToInt32(row["DirectReports"]) : 0;
                members.Add(new TeamMember
                {
                    EmployeeId = Convert.ToInt32(row["employee_id"]),
                    FullName = row["full_name"]?.ToString() ?? "",
                    Position = row["position_title"]?.ToString(),
                    ProfileImage = row["profile_image"]?.ToString(),
                    ManagerId = row["manager_id"] != DBNull.Value ? Convert.ToInt32(row["manager_id"]) : null,
                    ManagerName = row["ManagerName"]?.ToString(),
                    DepartmentId = row["department_id"] != DBNull.Value ? Convert.ToInt32(row["department_id"]) : null,
                    DepartmentName = row["department_name"]?.ToString(),
                    IsManager = directReports > 0,
                    DirectReports = directReports
                });
            }
            return members;
        }
    }
}
