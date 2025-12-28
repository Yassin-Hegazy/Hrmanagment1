using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IAuthService
    {
        Task<Employee?> AuthenticateAsync(string email, string password);
        string HashPassword(string password);
        bool VerifyPassword(string password, string hash);
        Task<bool> IsEmailUniqueAsync(string email);
        Task UpdateLastLoginAsync(int employeeId);
        Task<bool> IsAccountLockedAsync(int employeeId);
        Task<Employee?> GetEmployeeByEmailAsync(string email);
        Task SetPasswordAsync(int employeeId, string hashedPassword);
    }
}
