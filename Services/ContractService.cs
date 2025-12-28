using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class ContractService : IContractService
    {
        private readonly SqlHelper _sqlHelper;
        private readonly INotificationService _notificationService;

        public ContractService(SqlHelper sqlHelper, INotificationService notificationService)
        {
            _sqlHelper = sqlHelper;
            _notificationService = notificationService;
        }

        public async Task<IEnumerable<Contract>> GetAllContractsAsync()
        {
            // Direct query since GetActiveContracts doesn't return all needed fields
            var query = @"
                SELECT 
                    c.contract_id,
                    e.employee_id,
                    e.full_name AS employee_name,
                    c.contract_type,
                    c.contract_start_date,
                    c.contract_end_date,
                    c.contract_current_state,
                    d.department_name,
                    p.position_title,
                    e.profile_image,
                    DATEDIFF(DAY, GETDATE(), c.contract_end_date) AS days_remaining
                FROM Contract c
                INNER JOIN Employee e ON c.contract_id = e.contract_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                LEFT JOIN Position p ON e.position_id = p.position_id
                WHERE c.contract_current_state = 'Active' 
                   OR c.contract_end_date >= GETDATE()
                ORDER BY c.contract_end_date ASC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var contracts = new List<Contract>();
            foreach (DataRow row in dataTable.Rows)
            {
                contracts.Add(MapToContractDirect(row));
            }

            return contracts;
        }

        public async Task<Contract?> GetContractByIdAsync(int contractId)
        {
            // Direct query since there's no specific stored procedure for single contract
            var query = @"
                SELECT 
                    c.contract_id,
                    e.employee_id,
                    e.full_name AS employee_name,
                    c.contract_type,
                    c.contract_start_date,
                    c.contract_end_date,
                    c.contract_current_state,
                    d.department_name,
                    p.position_title,
                    e.profile_image,
                    DATEDIFF(DAY, GETDATE(), c.contract_end_date) AS days_remaining
                FROM Contract c
                INNER JOIN Employee e ON c.contract_id = e.contract_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                LEFT JOIN Position p ON e.position_id = p.position_id
                WHERE c.contract_id = @ContractID";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@ContractID", contractId);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            if (dataTable.Rows.Count == 0)
                return null;

            return MapToContractDirect(dataTable.Rows[0]);
        }

        public async Task<IEnumerable<Contract>> GetContractsByEmployeeIdAsync(int employeeId)
        {
            var query = @"
                SELECT 
                    c.contract_id,
                    e.employee_id,
                    e.full_name AS employee_name,
                    c.contract_type,
                    c.contract_start_date,
                    c.contract_end_date,
                    c.contract_current_state,
                    d.department_name,
                    p.position_title,
                    e.profile_image,
                    DATEDIFF(DAY, GETDATE(), c.contract_end_date) AS days_remaining
                FROM Contract c
                INNER JOIN Employee e ON c.contract_id = e.contract_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                LEFT JOIN Position p ON e.position_id = p.position_id
                WHERE e.employee_id = @EmployeeID
                ORDER BY c.contract_start_date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@EmployeeID", employeeId);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var contracts = new List<Contract>();
            foreach (DataRow row in dataTable.Rows)
            {
                contracts.Add(MapToContractDirect(row));
            }

            return contracts;
        }

        public async Task<IEnumerable<Contract>> GetExpiringContractsAsync(int days = 30)
        {
            // Use GetExpiringContracts stored procedure
            var parameters = new SqlParameter[]
            {
                new SqlParameter("@DaysBefore", days)
            };
            
            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetExpiringContracts", parameters);

            var contracts = new List<Contract>();
            foreach (DataRow row in dataTable.Rows)
            {
                contracts.Add(MapToContractFromExpiring(row));
            }

            return contracts;
        }

        public async Task<int> AddContractAsync(Contract contract)
        {
            // Use CreateContract stored procedure
            var parameters = new SqlParameter[]
            {
                new SqlParameter("@EmployeeID", contract.EmployeeId),
                new SqlParameter("@Type", contract.ContractType),
                new SqlParameter("@StartDate", contract.StartDate),
                new SqlParameter("@EndDate", contract.EndDate ?? (object)DateTime.Now.AddYears(1))
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("CreateContract", parameters);
            
            if (dataTable.Rows.Count > 0 && dataTable.Columns.Contains("NewContractID"))
            {
                return Convert.ToInt32(dataTable.Rows[0]["NewContractID"]);
            }
            
            return 0;
        }

        public async Task UpdateContractAsync(Contract contract)
        {
            // Direct update since there's no specific stored procedure
            var query = @"
                UPDATE Contract 
                SET contract_type = @ContractType,
                    contract_start_date = @StartDate,
                    contract_end_date = @EndDate,
                    contract_current_state = @Status
                WHERE contract_id = @ContractID";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            command.Parameters.AddWithValue("@ContractID", contract.ContractId);
            command.Parameters.AddWithValue("@ContractType", contract.ContractType);
            command.Parameters.AddWithValue("@StartDate", contract.StartDate);
            command.Parameters.AddWithValue("@EndDate", (object?)contract.EndDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@Status", contract.Status);
            
            await connection.OpenAsync();
            await command.ExecuteNonQueryAsync();
            
            // Trigger notification for contract update
            if (contract.EmployeeId > 0)
            {
                var message = $"Your contract has been updated. New end date: {contract.EndDate?.ToString("MMMM dd, yyyy") ?? "Not specified"}.";
                await _notificationService.CreateNotificationAsync(
                    contract.EmployeeId, 
                    message, 
                    "Contract Update", 
                    "Medium");
            }
        }

        public async Task RenewContractAsync(int contractId, DateTime newEndDate)
        {
            // Use RenewContract stored procedure
            var parameters = new SqlParameter[]
            {
                new SqlParameter("@ContractID", contractId),
                new SqlParameter("@NewEndDate", newEndDate)
            };

            await _sqlHelper.ExecuteStoredProcedureAsync("RenewContract", parameters);
            
            // Get employee for notification
            var contract = await GetContractByIdAsync(contractId);
            if (contract != null && contract.EmployeeId > 0)
            {
                var message = $"Great news! Your contract has been renewed until {newEndDate:MMMM dd, yyyy}.";
                await _notificationService.CreateNotificationAsync(
                    contract.EmployeeId, 
                    message, 
                    "Contract Renewal", 
                    "Normal");
            }
        }

        public async Task TerminateContractAsync(int contractId, string reason, DateTime terminationDate)
        {
            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            await connection.OpenAsync();
            using var transaction = connection.BeginTransaction();

            try
            {
                // 1. Update Contract
                var updateQuery = @"
                    UPDATE Contract 
                    SET contract_current_state = 'Terminated',
                        contract_end_date = @TerminationDate
                    WHERE contract_id = @ContractID";

                using (var updateCmd = new SqlCommand(updateQuery, connection, transaction))
                {
                    updateCmd.Parameters.AddWithValue("@ContractID", contractId);
                    updateCmd.Parameters.AddWithValue("@TerminationDate", terminationDate);
                    await updateCmd.ExecuteNonQueryAsync();
                }

                // 2. Insert Termination
                var insertQuery = @"
                    INSERT INTO Termination (date, reason, contract_id)
                    VALUES (@Date, @Reason, @ContractID)";

                using (var insertCmd = new SqlCommand(insertQuery, connection, transaction))
                {
                    insertCmd.Parameters.AddWithValue("@Date", terminationDate);
                    insertCmd.Parameters.AddWithValue("@Reason", reason);
                    insertCmd.Parameters.AddWithValue("@ContractID", contractId);
                    await insertCmd.ExecuteNonQueryAsync();
                }

                transaction.Commit();
            }
            catch
            {
                transaction.Rollback();
                throw;
            }

            // Trigger notification for contract termination
            // Run in separate connection scope
            var contract = await GetContractByIdAsync(contractId);
            if (contract != null && contract.EmployeeId > 0)
            {
                var message = "Your contract has been terminated. Please contact HR for more information.";
                await _notificationService.CreateNotificationAsync(
                    contract.EmployeeId, 
                    message, 
                    "Contract Termination", 
                    "High");
            }
        }

        public async Task<IEnumerable<Termination>> GetTerminatedContractsAsync()
        {
            var query = @"
                SELECT 
                    t.termination_id, 
                    t.date, 
                    t.reason, 
                    t.contract_id,
                    e.full_name AS EmployeeName, 
                    e.profile_image, 
                    d.department_name, 
                    c.contract_type
                FROM Termination t
                INNER JOIN Contract c ON t.contract_id = c.contract_id
                LEFT JOIN Employee e ON c.contract_id = e.contract_id
                LEFT JOIN Department d ON e.department_id = d.department_id
                ORDER BY t.date DESC";

            using var connection = new SqlConnection(_sqlHelper.GetConnectionString());
            using var command = new SqlCommand(query, connection);
            
            await connection.OpenAsync();
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            adapter.Fill(dataTable);

            var terminations = new List<Termination>();
            foreach (DataRow row in dataTable.Rows)
            {
                terminations.Add(new Termination
                {
                    TerminationId = Convert.ToInt32(row["termination_id"]),
                    Date = Convert.ToDateTime(row["date"]),
                    Reason = row["reason"]?.ToString() ?? string.Empty,
                    ContractId = Convert.ToInt32(row["contract_id"]),
                    EmployeeName = row["EmployeeName"]?.ToString() ?? "Unknown",
                    ProfileImage = row.Table.Columns.Contains("profile_image") ? row["profile_image"]?.ToString() : null,
                    DepartmentName = row["department_name"]?.ToString(),
                    ContractType = row["contract_type"]?.ToString()
                });
            }

            return terminations;
        }

        private Contract MapToContract(DataRow row)
        {
            var table = row.Table;
            
            return new Contract
            {
                ContractId = table.Columns.Contains("contract_id") ? Convert.ToInt32(row["contract_id"]) : 0,
                EmployeeId = 0, // Not in GetActiveContracts result
                ContractType = row["contract_type"]?.ToString() ?? string.Empty,
                StartDate = Convert.ToDateTime(row["contract_start_date"]),
                EndDate = row["contract_end_date"] != DBNull.Value ? Convert.ToDateTime(row["contract_end_date"]) : null,
                Salary = 0, // Not in stored procedure result - set default
                Terms = null,
                Status = row["contract_current_state"]?.ToString() ?? "Active",
                RenewalDate = null,
                EmployeeName = table.Columns.Contains("EmployeeName") ? row["EmployeeName"]?.ToString() : null,
                DepartmentName = null,
                PositionTitle = null
            };
        }

        private Contract MapToContractDirect(DataRow row)
        {
            return new Contract
            {
                ContractId = Convert.ToInt32(row["contract_id"]),
                EmployeeId = Convert.ToInt32(row["employee_id"]),
                ContractType = row["contract_type"]?.ToString() ?? "Full-time",
                StartDate = Convert.ToDateTime(row["contract_start_date"]),
                EndDate = row["contract_end_date"] != DBNull.Value ? Convert.ToDateTime(row["contract_end_date"]) : null,
                Salary = 0,
                Terms = null,
                Status = row["contract_current_state"]?.ToString() ?? "Active",
                RenewalDate = null,
                EmployeeName = row["employee_name"]?.ToString(),
                DepartmentName = row["department_name"]?.ToString(),
                PositionTitle = row["position_title"]?.ToString(),
                ProfileImage = row.Table.Columns.Contains("profile_image") ? row["profile_image"]?.ToString() : null
            };
        }

        private Contract MapToContractFromExpiring(DataRow row)
        {
            return new Contract
            {
                ContractId = Convert.ToInt32(row["Contract ID"]),
                EmployeeId = Convert.ToInt32(row["Employee ID"]),
                ContractType = row["Type"]?.ToString() ?? string.Empty,
                StartDate = DateTime.Now, // Not in result
                EndDate = Convert.ToDateTime(row["Expiration Date"]),
                Salary = 0,
                Terms = null,
                Status = "Active",
                RenewalDate = null,
                EmployeeName = row["Employee Name"]?.ToString(),
                DepartmentName = null,
                PositionTitle = null
            };
        }
    }
}
