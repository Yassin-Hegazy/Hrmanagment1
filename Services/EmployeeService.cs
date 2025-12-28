using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class EmployeeService : IEmployeeService
    {
        private readonly SqlHelper _sqlHelper;

        public EmployeeService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        public async Task<Employee?> GetEmployeeByIdAsync(int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId)
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("ViewEmployeeInfo", parameters);

            if (dataTable.Rows.Count == 0)
                return null;

            var row = dataTable.Rows[0];
            return MapToEmployee(row);
        }

        public async Task<List<Employee>> GetAllEmployeesAsync()
        {
            // Using GenerateProfileReport with no filter to get all employees
            var parameters = new[]
            {
                new SqlParameter("@FilterField", "is_active"),
                new SqlParameter("@FilterValue", "1")
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GenerateProfileReport", parameters);

            var employees = new List<Employee>();
            foreach (DataRow row in dataTable.Rows)
            {
                employees.Add(MapToEmployee(row));
            }

            return employees;
        }

        public async Task<int> AddEmployeeAsync(Employee employee)
        {
            var parameters = new[]
            {
                new SqlParameter("@FullName", $"{employee.FirstName} {employee.LastName}"),
                new SqlParameter("@NationalID", employee.NationalId),
                new SqlParameter("@DateOfBirth", (object?)employee.DateOfBirth ?? DBNull.Value),
                new SqlParameter("@CountryOfBirth", (object?)employee.CountryOfBirth ?? DBNull.Value),
                new SqlParameter("@Phone", (object?)employee.Phone ?? DBNull.Value),
                new SqlParameter("@Email", (object?)employee.Email ?? DBNull.Value),
                new SqlParameter("@Address", (object?)employee.Address ?? DBNull.Value),
                new SqlParameter("@EmergencyContactName", (object?)employee.EmergencyContactName ?? DBNull.Value),
                new SqlParameter("@EmergencyContactPhone", (object?)employee.EmergencyContactPhone ?? DBNull.Value),
                new SqlParameter("@Relationship", (object?)employee.Relationship ?? DBNull.Value),
                new SqlParameter("@Biography", (object?)employee.Biography ?? DBNull.Value),
                new SqlParameter("@EmploymentProgress", (object?)employee.EmploymentProgress ?? DBNull.Value),
                new SqlParameter("@AccountStatus", (object?)employee.AccountStatus ?? DBNull.Value),
                new SqlParameter("@EmploymentStatus", (object?)employee.EmploymentStatus ?? DBNull.Value),
                new SqlParameter("@HireDate", (object?)employee.HireDate ?? DBNull.Value),
                new SqlParameter("@IsActive", employee.IsActive),
                new SqlParameter("@ProfileCompletion", employee.ProfileCompletion),
                new SqlParameter("@DepartmentID", (object?)employee.DepartmentId ?? DBNull.Value),
                new SqlParameter("@PositionID", (object?)employee.PositionId ?? DBNull.Value),
                new SqlParameter("@ManagerID", (object?)employee.ManagerId ?? DBNull.Value),
                new SqlParameter("@ContractID", (object?)employee.ContractId ?? DBNull.Value),
                new SqlParameter("@TaxFormID", (object?)employee.TaxFormId ?? DBNull.Value),
                new SqlParameter("@SalaryTypeID", (object?)employee.SalaryTypeId ?? DBNull.Value),
                new SqlParameter("@PayGrade", (object?)employee.PayGrade ?? DBNull.Value),
                new SqlParameter("@PasswordHash", (object?)employee.PasswordHash ?? DBNull.Value),
                new SqlParameter("@PasswordSalt", (object?)employee.PasswordSalt ?? DBNull.Value),
                new SqlParameter("@ProfileImage", (object?)employee.ProfileImage ?? DBNull.Value)
            };

            var result = await _sqlHelper.ExecuteStoredProcedureAsync("AddEmployee", parameters);
            
            if (result.Rows.Count > 0)
            {
                return Convert.ToInt32(result.Rows[0]["NewEmployeeID"]);
            }

            return 0;
        }

        public async Task UpdateEmployeeAsync(Employee employee)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employee.EmployeeId),
                new SqlParameter("@Email", (object?)employee.Email ?? DBNull.Value),
                new SqlParameter("@Phone", (object?)employee.Phone ?? DBNull.Value),
                new SqlParameter("@Address", (object?)employee.Address ?? DBNull.Value),
                new SqlParameter("@EmergencyContactName", (object?)employee.EmergencyContactName ?? DBNull.Value),
                new SqlParameter("@EmergencyContactPhone", (object?)employee.EmergencyContactPhone ?? DBNull.Value),
                new SqlParameter("@Relationship", (object?)employee.Relationship ?? DBNull.Value),
                new SqlParameter("@ProfileImage", (object?)employee.ProfileImage ?? DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("UpdateEmployeeInfo", parameters);
        }

        public async Task<IEnumerable<Employee>> SearchEmployeesAsync(string searchTerm)
        {
            // Search by name
            var parameters = new[]
            {
                new SqlParameter("@FilterField", "first_name"),
                new SqlParameter("@FilterValue", searchTerm)
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GenerateProfileReport", parameters);

            var employees = new List<Employee>();
            foreach (DataRow row in dataTable.Rows)
            {
                employees.Add(MapToEmployee(row));
            }

            return employees;
        }

        public async Task AssignRoleAsync(int employeeId, int roleId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@RoleID", roleId)
            };

            await _sqlHelper.ExecuteNonQueryAsync("AssignEmployeeRole", parameters);
        }

        public async Task RemoveRoleAsync(int employeeId, int roleId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@RoleID", roleId)
            };

            await _sqlHelper.ExecuteNonQueryAsync("RemoveEmployeeRole", parameters);
        }

        public async Task<IEnumerable<int>> GetEmployeeRolesAsync(int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId)
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetEmployeeRoles", parameters);
            
            var roleIds = new List<int>();
            foreach (DataRow row in dataTable.Rows)
            {
                roleIds.Add(Convert.ToInt32(row["role_id"]));
            }

            return roleIds;
        }

        public async Task ReassignManagerAsync(int employeeId, int newManagerId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@NewManagerID", newManagerId)
            };

            await _sqlHelper.ExecuteNonQueryAsync("ReassignManager", parameters);
        }

        public async Task<int> SetProfileCompletenessAsync(int employeeId, int completeness)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@CompletenessPercentage", completeness)
            };

            await _sqlHelper.ExecuteNonQueryAsync("SetProfileCompleteness", parameters);
            return completeness;
        }

        public async Task<Employee?> GetEmployeeByEmailAsync(string email)
        {
            var parameters = new[]
            {
                new SqlParameter("@Email", email)
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetEmployeeByEmail", parameters);

            if (dataTable.Rows.Count == 0)
                return null;

            return MapToEmployee(dataTable.Rows[0]);
        }

        public async Task UpdateProfilePictureAsync(int employeeId, string imagePath)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@ProfileImage", imagePath)
            };

            await _sqlHelper.ExecuteNonQueryAsync("UpdateProfilePicture", parameters);
        }



        public async Task UpdateEmployeeProfileAsync(int editorId, Employee employee)
        {
            var parameters = new[]
            {
                new SqlParameter("@EditorId", editorId),
                new SqlParameter("@EmployeeID", employee.EmployeeId),
                new SqlParameter("@FirstName", (object?)employee.FirstName ?? DBNull.Value),
                new SqlParameter("@LastName", (object?)employee.LastName ?? DBNull.Value),
                new SqlParameter("@Email", (object?)employee.Email ?? DBNull.Value),
                new SqlParameter("@Phone", (object?)employee.Phone ?? DBNull.Value),
                new SqlParameter("@NationalId", (object?)employee.NationalId ?? DBNull.Value),
                new SqlParameter("@DateOfBirth", (object?)employee.DateOfBirth ?? DBNull.Value),
                new SqlParameter("@CountryOfBirth", (object?)employee.CountryOfBirth ?? DBNull.Value),
                new SqlParameter("@Address", (object?)employee.Address ?? DBNull.Value),
                new SqlParameter("@EmergencyContactName", (object?)employee.EmergencyContactName ?? DBNull.Value),
                new SqlParameter("@EmergencyContactPhone", (object?)employee.EmergencyContactPhone ?? DBNull.Value),
                new SqlParameter("@Relationship", (object?)employee.Relationship ?? DBNull.Value),
                new SqlParameter("@Biography", (object?)employee.Biography ?? DBNull.Value),
                new SqlParameter("@ProfileImage", (object?)employee.ProfileImage ?? DBNull.Value),
                new SqlParameter("@DepartmentId", (object?)employee.DepartmentId ?? DBNull.Value),
                new SqlParameter("@PositionId", (object?)employee.PositionId ?? DBNull.Value),
                new SqlParameter("@ManagerId", (object?)employee.ManagerId ?? DBNull.Value)
            };

            await _sqlHelper.ExecuteNonQueryAsync("UpdateEmployeeDetailsFull", parameters);
        }

        public async Task UpdateProfileFieldAsync(int employeeId, string fieldName, string newValue)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId),
                new SqlParameter("@FieldName", fieldName),
                new SqlParameter("@NewValue", (object?)newValue ?? DBNull.Value)
            };

            await _sqlHelper.ExecuteStoredProcedureAsync("UpdateEmployeeProfile", parameters);
        }

        public async Task DeleteEmployeeAsync(int employeeId)
        {
            // Implementation for delete if needed
            throw new NotImplementedException();
        }

        public async Task<int> AddEmployeeWithPasswordAsync(Employee employee, string password)
        {
            // Hash password and add to employee
            employee.PasswordHash = password; // Assuming password is already hashed
            return await AddEmployeeAsync(employee);
        }

        public async Task<Employee?> GetEmployeeWithRoleDetailsAsync(int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeID", employeeId)
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetEmployeeWithRoleDetails", parameters);

            if (dataTable.Rows.Count == 0)
                return null;

            return MapToEmployeeWithRoleDetails(dataTable.Rows[0]);
        }

        public async Task<int> CreateAdminAccountAsync(Employee employee, string password, int roleId)
        {
            var parameters = new[]
            {
                new SqlParameter("@FirstName", employee.FirstName),
                new SqlParameter("@LastName", employee.LastName),
                new SqlParameter("@Email", employee.Email ?? string.Empty),
                new SqlParameter("@Password", password), // Already hashed by controller
                new SqlParameter("@RoleId", roleId),
                new SqlParameter("@Phone", (object?)employee.Phone ?? DBNull.Value),
                new SqlParameter("@NationalId", (object?)employee.NationalId ?? DBNull.Value),
                // Role-specific parameters
                new SqlParameter("@ApprovalLevel", (object?)employee.ApprovalLevel ?? DBNull.Value),
                new SqlParameter("@RecordAccessScope", (object?)employee.RecordAccessScope ?? DBNull.Value),
                new SqlParameter("@DocumentValidationRights", (object?)employee.DocumentValidationRights ?? DBNull.Value),
                new SqlParameter("@SystemPrivilegeLevel", (object?)employee.SystemPrivilegeLevel ?? DBNull.Value),
                new SqlParameter("@ConfigurableFields", (object?)employee.ConfigurableFields ?? DBNull.Value),
                new SqlParameter("@AuditVisibilityScope", (object?)employee.AuditVisibilityScope ?? DBNull.Value),
                new SqlParameter("@AssignedRegion", (object?)employee.AssignedRegion ?? DBNull.Value),
                new SqlParameter("@ProcessingFrequency", (object?)employee.ProcessingFrequency ?? DBNull.Value),
                new SqlParameter("@TeamSize", (object?)employee.TeamSize ?? DBNull.Value),
                new SqlParameter("@SupervisedDepartments", (object?)employee.SupervisedDepartments ?? DBNull.Value),
                new SqlParameter("@ApprovalLimit", (object?)employee.ApprovalLimit ?? DBNull.Value),
                new SqlParameter("@NewEmployeeID", SqlDbType.Int) { Direction = ParameterDirection.Output }
            };

            await _sqlHelper.ExecuteNonQueryAsync("CreateAdminAccount", parameters);
            
            return Convert.ToInt32(parameters[parameters.Length - 1].Value);
        }

        public async Task<int> CreateEmployeeByAdminAsync(Employee employee, string password, int roleId, int creatorId)
        {
            var parameters = new[]
            {
                new SqlParameter("@CreatorId", creatorId),
                new SqlParameter("@FirstName", employee.FirstName),
                new SqlParameter("@LastName", employee.LastName),
                new SqlParameter("@Email", employee.Email ?? string.Empty),
                new SqlParameter("@Password", password), // Already hashed by controller
                new SqlParameter("@RoleId", roleId),
                new SqlParameter("@Phone", (object?)employee.Phone ?? DBNull.Value),
                new SqlParameter("@NationalId", (object?)employee.NationalId ?? DBNull.Value),
                new SqlParameter("@DateOfBirth", (object?)employee.DateOfBirth ?? DBNull.Value),
                new SqlParameter("@CountryOfBirth", (object?)employee.CountryOfBirth ?? DBNull.Value),
                new SqlParameter("@Address", (object?)employee.Address ?? DBNull.Value),
                new SqlParameter("@DepartmentId", (object?)employee.DepartmentId ?? DBNull.Value),
                new SqlParameter("@PositionId", (object?)employee.PositionId ?? DBNull.Value),
                new SqlParameter("@ManagerId", (object?)employee.ManagerId ?? DBNull.Value),
                new SqlParameter("@NewEmployeeID", SqlDbType.Int) { Direction = ParameterDirection.Output }
            };

            await _sqlHelper.ExecuteNonQueryAsync("CreateEmployeeByAdmin", parameters);
            
            return Convert.ToInt32(parameters[parameters.Length - 1].Value);
        }

        public async Task<bool> CanEditEmployeeAsync(int editorId, int targetEmployeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EditorId", editorId),
                new SqlParameter("@TargetEmployeeId", targetEmployeeId),
                new SqlParameter("@CanEdit", SqlDbType.Bit) { Direction = ParameterDirection.Output }
            };

            await _sqlHelper.ExecuteNonQueryAsync("CheckEditPermission", parameters);
            
            return Convert.ToBoolean(parameters[2].Value);
        }

        // Called by SuperAdmin/HRAdmin to update admin-only fields
        public async Task UpdateRoleSpecificDataAsync(int editorId, Employee employee)
        {
            // First update the admin control fields (ProfileCompletion, IsActive, EmploymentStatus)
            var adminParameters = new[]
            {
                new SqlParameter("@EmployeeID", employee.EmployeeId),
                new SqlParameter("@ProfileCompletion", (object?)employee.ProfileCompletion ?? DBNull.Value),
                new SqlParameter("@IsActive", (object?)employee.IsActive ?? DBNull.Value),
                new SqlParameter("@EmploymentStatus", (object?)employee.EmploymentStatus ?? DBNull.Value)
            };
            
            await _sqlHelper.ExecuteNonQueryAsync("UpdateEmployeeAdminControls", adminParameters);

            // Then update role-specific subclass data if role is specified
            if (!string.IsNullOrEmpty(employee.RoleName))
            {
                var roleParameters = new[]
                {
                    new SqlParameter("@EditorId", editorId),
                    new SqlParameter("@EmployeeID", employee.EmployeeId),
                    new SqlParameter("@RoleName", employee.RoleName),
                    new SqlParameter("@ApprovalLevel", (object?)employee.ApprovalLevel ?? DBNull.Value),
                    new SqlParameter("@RecordAccessScope", (object?)employee.RecordAccessScope ?? DBNull.Value),
                    new SqlParameter("@DocumentValidationRights", (object?)employee.DocumentValidationRights ?? DBNull.Value),
                    new SqlParameter("@SystemPrivilegeLevel", (object?)employee.SystemPrivilegeLevel ?? DBNull.Value),
                    new SqlParameter("@ConfigurableFields", (object?)employee.ConfigurableFields ?? DBNull.Value),
                    new SqlParameter("@AuditVisibilityScope", (object?)employee.AuditVisibilityScope ?? DBNull.Value),
                    new SqlParameter("@AssignedRegion", (object?)employee.AssignedRegion ?? DBNull.Value),
                    new SqlParameter("@ProcessingFrequency", (object?)employee.ProcessingFrequency ?? DBNull.Value),
                    new SqlParameter("@TeamSize", (object?)employee.TeamSize ?? DBNull.Value),
                    new SqlParameter("@SupervisedDepartments", (object?)employee.SupervisedDepartments ?? DBNull.Value),
                    new SqlParameter("@ApprovalLimit", (object?)employee.ApprovalLimit ?? DBNull.Value)
                };

                await _sqlHelper.ExecuteNonQueryAsync("UpdateRoleSpecificData", roleParameters);
            }
        }

        public async Task InsertIntoRoleSubclassAsync(int employeeId, string roleName)
        {
            if (string.IsNullOrEmpty(roleName)) return;

            // Normalize role name for comparison
            var normalizedRoleName = roleName.ToLower().Replace(" ", "");

            if (normalizedRoleName.Contains("hr") || normalizedRoleName.Contains("hradmin"))
            {
                // Insert into HRAdministrator table
                var parameters = new[]
                {
                    new SqlParameter("@employee_id", employeeId),
                    new SqlParameter("@approval_level", DBNull.Value),
                    new SqlParameter("@record_access_scope", DBNull.Value),
                    new SqlParameter("@document_validation_rights", DBNull.Value)
                };
                await _sqlHelper.ExecuteRawSqlAsync("INSERT INTO HRAdministrator (employee_id, approval_level, record_access_scope, document_validation_rights) VALUES (@employee_id, @approval_level, @record_access_scope, @document_validation_rights)", parameters);
            }
            else if (normalizedRoleName.Contains("system") || normalizedRoleName.Contains("super") || normalizedRoleName.Contains("sysadmin"))
            {
                // Insert into SystemAdministrator table
                var parameters = new[]
                {
                    new SqlParameter("@employee_id", employeeId),
                    new SqlParameter("@system_privilege_level", DBNull.Value),
                    new SqlParameter("@configurable_fields", DBNull.Value),
                    new SqlParameter("@audit_visibility_scope", DBNull.Value)
                };
                await _sqlHelper.ExecuteRawSqlAsync("INSERT INTO SystemAdministrator (employee_id, system_privilege_level, configurable_fields, audit_visibility_scope) VALUES (@employee_id, @system_privilege_level, @configurable_fields, @audit_visibility_scope)", parameters);
            }
            else if (normalizedRoleName.Contains("line") || normalizedRoleName.Contains("manager"))
            {
                // Insert into LineManager table
                var parameters = new[]
                {
                    new SqlParameter("@employee_id", employeeId),
                    new SqlParameter("@team_size", DBNull.Value),
                    new SqlParameter("@supervised_departments", DBNull.Value),
                    new SqlParameter("@approval_limit", DBNull.Value)
                };
                await _sqlHelper.ExecuteRawSqlAsync("INSERT INTO LineManager (employee_id, team_size, supervised_departments, approval_limit) VALUES (@employee_id, @team_size, @supervised_departments, @approval_limit)", parameters);
            }
        }

        private Employee MapToEmployee(DataRow row)
        {
            return new Employee
            {
                EmployeeId = Convert.ToInt32(row["employee_id"]),
                FirstName = row["first_name"].ToString() ?? string.Empty,
                LastName = row["last_name"].ToString() ?? string.Empty,
                FullName = row["full_name"].ToString(),
                NationalId = row["national_id"].ToString() ?? string.Empty,
                DateOfBirth = row["date_of_birth"] != DBNull.Value ? Convert.ToDateTime(row["date_of_birth"]) : null,
                CountryOfBirth = row["country_of_birth"].ToString(),
                Phone = row["phone"].ToString(),
                Email = row["email"].ToString(),
                Address = row["address"].ToString(),
                EmergencyContactName = row["emergency_contact_name"].ToString(),
                EmergencyContactPhone = row["emergency_contact_phone"].ToString(),
                Relationship = row["relationship"].ToString(),
                Biography = row["biography"].ToString(),
                ProfileImage = row.Table.Columns.Contains("profile_image") ? row["profile_image"].ToString() : null,
                EmploymentProgress = row["employment_progress"].ToString(),
                AccountStatus = row["account_status"].ToString(),
                EmploymentStatus = row["employment_status"].ToString(),
                HireDate = row["hire_date"] != DBNull.Value ? Convert.ToDateTime(row["hire_date"]) : null,
                IsActive = row.Table.Columns.Contains("is_active") && row["is_active"] != DBNull.Value && Convert.ToBoolean(row["is_active"]),
                ProfileCompletion = row.Table.Columns.Contains("profile_completion") && row["profile_completion"] != DBNull.Value 
                    ? Convert.ToInt32(row["profile_completion"]) : 0,
                
                // Foreign Keys
                DepartmentId = row.Table.Columns.Contains("department_id") && row["department_id"] != DBNull.Value ? Convert.ToInt32(row["department_id"]) : null,
                PositionId = row.Table.Columns.Contains("position_id") && row["position_id"] != DBNull.Value ? Convert.ToInt32(row["position_id"]) : null,
                ManagerId = row.Table.Columns.Contains("manager_id") && row["manager_id"] != DBNull.Value ? Convert.ToInt32(row["manager_id"]) : null,
                ContractId = row.Table.Columns.Contains("contract_id") && row["contract_id"] != DBNull.Value ? Convert.ToInt32(row["contract_id"]) : null,
                TaxFormId = row.Table.Columns.Contains("tax_form_id") && row["tax_form_id"] != DBNull.Value ? Convert.ToInt32(row["tax_form_id"]) : null,
                SalaryTypeId = row.Table.Columns.Contains("salary_type_id") && row["salary_type_id"] != DBNull.Value ? Convert.ToInt32(row["salary_type_id"]) : null,
                PayGrade = row.Table.Columns.Contains("pay_grade") && row["pay_grade"] != DBNull.Value ? Convert.ToInt32(row["pay_grade"]) : null,
                
                // Authentication & Security
                PasswordHash = row.Table.Columns.Contains("password_hash") ? row["password_hash"].ToString() : null,
                PasswordSalt = row.Table.Columns.Contains("password_salt") ? row["password_salt"].ToString() : null,
                LastLogin = row.Table.Columns.Contains("last_login") && row["last_login"] != DBNull.Value ? Convert.ToDateTime(row["last_login"]) : null,
                IsLocked = row.Table.Columns.Contains("is_locked") && row["is_locked"] != DBNull.Value && Convert.ToBoolean(row["is_locked"]),
                
                // Navigation Properties
                DepartmentName = row.Table.Columns.Contains("department_name") ? row["department_name"].ToString() : null,
                PositionTitle = row.Table.Columns.Contains("position_title") ? row["position_title"].ToString() : null,
                ManagerName = row.Table.Columns.Contains("manager_name") ? row["manager_name"].ToString() : null,
                RoleName = row.Table.Columns.Contains("role_name") ? row["role_name"].ToString() : null
            };
        }

        private Employee MapToEmployeeWithRoleDetails(DataRow row)
        {
            var employee = MapToEmployee(row);
            
            // Add role-specific properties
            employee.ApprovalLevel = row.Table.Columns.Contains("approval_level") ? row["approval_level"].ToString() : null;
            employee.RecordAccessScope = row.Table.Columns.Contains("record_access_scope") ? row["record_access_scope"].ToString() : null;
            employee.DocumentValidationRights = row.Table.Columns.Contains("document_validation_rights") ? row["document_validation_rights"].ToString() : null;
            
            employee.SystemPrivilegeLevel = row.Table.Columns.Contains("system_privilege_level") ? row["system_privilege_level"].ToString() : null;
            employee.ConfigurableFields = row.Table.Columns.Contains("configurable_fields") ? row["configurable_fields"].ToString() : null;
            employee.AuditVisibilityScope = row.Table.Columns.Contains("audit_visibility_scope") ? row["audit_visibility_scope"].ToString() : null;
            
            employee.AssignedRegion = row.Table.Columns.Contains("assigned_region") ? row["assigned_region"].ToString() : null;
            employee.ProcessingFrequency = row.Table.Columns.Contains("processing_frequency") ? row["processing_frequency"].ToString() : null;
            employee.LastProcessedPeriod = row.Table.Columns.Contains("last_processed_period") ? row["last_processed_period"].ToString() : null;
            
            employee.TeamSize = row.Table.Columns.Contains("team_size") && row["team_size"] != DBNull.Value ? Convert.ToInt32(row["team_size"]) : null;
            employee.SupervisedDepartments = row.Table.Columns.Contains("supervised_departments") ? row["supervised_departments"].ToString() : null;
            employee.ApprovalLimit = row.Table.Columns.Contains("approval_limit") ? row["approval_limit"].ToString() : null;
            
            return employee;
        }

        public async Task<List<Employee>> GetEmployeesByManagerIdAsync(int managerId)
        {
            var parameters = new[]
            {
                new SqlParameter("@FilterField", "manager_id"),
                new SqlParameter("@FilterValue", managerId.ToString())
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GenerateProfileReport", parameters);

            var employees = new List<Employee>();
            foreach (DataRow row in dataTable.Rows)
            {
                employees.Add(MapToEmployee(row));
            }

            return employees;
        }

        // Get all role NAMES for an employee (supports multiple roles)
        public async Task<List<string>> GetEmployeeRoleNamesAsync(int employeeId)
        {
            var parameters = new[]
            {
                new SqlParameter("@EmployeeId", employeeId)
            };

            // This query gets all roles for an employee from the junction table
            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetEmployeeRoles", parameters);
            
            var roleNames = new List<string>();
            foreach (DataRow row in dataTable.Rows)
            {
                if (row.Table.Columns.Contains("role_name") && row["role_name"] != DBNull.Value)
                {
                    roleNames.Add(row["role_name"].ToString() ?? "Employee");
                }
            }
            
            // If no roles found, default to "Employee"
            if (roleNames.Count == 0)
            {
                roleNames.Add("Employee");
            }
            
            return roleNames;
        }
    }
}

