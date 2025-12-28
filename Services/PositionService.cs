using HRMANGMANGMENT.Data;
using HRMANGMANGMENT.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace HRMANGMANGMENT.Services
{
    public class PositionService : IPositionService
    {
        private readonly SqlHelper _sqlHelper;

        public PositionService(SqlHelper sqlHelper)
        {
            _sqlHelper = sqlHelper;
        }

        public async Task<IEnumerable<Position>> GetAllPositionsAsync()
        {
            var positions = new List<Position>();
            using (var reader = await _sqlHelper.ExecuteReaderAsync("GetAllPositions"))
            {
                while (await reader.ReadAsync())
                {
                    positions.Add(new Position
                    {
                        PositionId = reader.GetInt32(reader.GetOrdinal("position_id")),
                        PositionTitle = reader.GetString(reader.GetOrdinal("position_title")),
                        Responsibilities = reader.IsDBNull(reader.GetOrdinal("responsibilities")) ? null : reader.GetString(reader.GetOrdinal("responsibilities")),
                        Status = reader.GetString(reader.GetOrdinal("status"))
                    });
                }
            }
            return positions;
        }

        public async Task<int> AddPositionAsync(Position position)
        {
             var parameters = new[]
            {
                new SqlParameter("@PositionTitle", position.PositionTitle),
                new SqlParameter("@Responsibilities", (object?)position.Responsibilities ?? DBNull.Value),
                new SqlParameter("@Status", "Active")
            };

            var result = await _sqlHelper.ExecuteScalarAsync("AddPosition", parameters);
            return Convert.ToInt32(result);
        }
    }
}
