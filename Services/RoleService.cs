using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class RoleService : IRoleService
    {
        private readonly SqlHelper _sqlHelper;

        public RoleService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        public async Task<IEnumerable<Role>> GetAllRolesAsync()
        {
            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetAllRoles", Array.Empty<SqlParameter>());

            var roles = new List<Role>();
            foreach (DataRow row in dataTable.Rows)
            {
                roles.Add(MapToRole(row));
            }

            return roles;
        }

        public async Task<Role?> GetRoleByIdAsync(int roleId)
        {
            var parameters = new[]
            {
                new SqlParameter("@RoleID", roleId)
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetRoleById", parameters);

            if (dataTable.Rows.Count == 0)
                return null;

            return MapToRole(dataTable.Rows[0]);
        }

        public async Task<Role?> GetRoleByNameAsync(string roleName)
        {
            var parameters = new[]
            {
                new SqlParameter("@RoleName", roleName)
            };

            var dataTable = await _sqlHelper.ExecuteStoredProcedureAsync("GetRoleByName", parameters);

            if (dataTable.Rows.Count == 0)
                return null;

            return MapToRole(dataTable.Rows[0]);
        }

        private Role MapToRole(DataRow row)
        {
            return new Role
            {
                RoleId = Convert.ToInt32(row["role_id"]),
                RoleName = row["role_name"].ToString() ?? string.Empty,
                Purpose = row["purpose"].ToString()
            };
        }
    }
}
