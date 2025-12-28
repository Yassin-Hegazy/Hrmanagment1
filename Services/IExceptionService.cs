using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IExceptionService
    {
        Task<IEnumerable<ExceptionDay>> GetAllExceptionsAsync();
        Task<ExceptionDay?> GetExceptionByIdAsync(int exceptionId);
        Task<IEnumerable<ExceptionDay>> GetExceptionsByDateRangeAsync(DateTime startDate, DateTime endDate);
        Task<IEnumerable<ExceptionDay>> GetExceptionsByCategoryAsync(string category);
        Task<int> CreateExceptionAsync(ExceptionDay exception);
        Task UpdateExceptionAsync(ExceptionDay exception);
        Task DeleteExceptionAsync(int exceptionId);
        Task ApplyExceptionToAttendanceAsync(int exceptionId, DateTime date);
        Task<bool> IsExceptionDateAsync(DateTime date);
    }
}
