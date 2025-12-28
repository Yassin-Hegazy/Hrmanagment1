using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IPositionService
    {
        Task<IEnumerable<Position>> GetAllPositionsAsync();
        Task<int> AddPositionAsync(Position position);
    }
}
