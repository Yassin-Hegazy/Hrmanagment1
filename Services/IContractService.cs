using HRMANGMANGMENT.Models;

namespace HRMANGMANGMENT.Services
{
    public interface IContractService
    {
        Task<IEnumerable<Contract>> GetAllContractsAsync();
        Task<Contract?> GetContractByIdAsync(int contractId);
        Task<IEnumerable<Contract>> GetContractsByEmployeeIdAsync(int employeeId);
        Task<IEnumerable<Contract>> GetExpiringContractsAsync(int days = 30);
        Task<int> AddContractAsync(Contract contract);
        Task UpdateContractAsync(Contract contract);
        Task RenewContractAsync(int contractId, DateTime newEndDate);
        Task TerminateContractAsync(int contractId, string reason, DateTime terminationDate);
        Task<IEnumerable<Termination>> GetTerminatedContractsAsync();
    }
}
