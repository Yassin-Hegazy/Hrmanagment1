using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IShiftService
    {
        Task<IEnumerable<ShiftSchedule>> GetAllShiftsAsync();
        Task<ShiftSchedule?> GetShiftByIdAsync(int shiftId);
        Task<int> CreateShiftAsync(ShiftSchedule shift);
        Task AssignShiftToDepartmentAsync(int departmentId, int shiftId, DateTime startDate, DateTime? endDate);
        Task AssignShiftToEmployeeAsync(int employeeId, int shiftId, DateTime startDate, DateTime? endDate);
        Task<IEnumerable<ShiftAssignment>> GetEmployeeShiftAssignmentsAsync(int employeeId);
        
        // Advanced shift features
        Task ConfigureSplitShiftAsync(string shiftName, TimeSpan firstSlotStart, TimeSpan firstSlotEnd, TimeSpan secondSlotStart, TimeSpan secondSlotEnd);
        Task AssignRotationalShiftAsync(int employeeId, int shiftCycle, DateTime startDate, DateTime endDate, string status);
        Task AssignCustomShiftAsync(int employeeId, string shiftName, string shiftType, TimeSpan startTime, TimeSpan endTime, DateTime startDate, DateTime endDate);
    }
}
