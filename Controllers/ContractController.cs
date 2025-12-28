using HRMANGMANGMENT.Models;
using HRMANGMANGMENT.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HRMANGMANGMENT.Controllers
{
    [Authorize(Roles = "HRAdmin")] // Only HR Admin can manage contracts
    public class ContractController : Controller
    {
        private readonly IContractService _contractService;
        private readonly IEmployeeService _employeeService;

        public ContractController(IContractService contractService, IEmployeeService employeeService)
        {
            _contractService = contractService;
            _employeeService = employeeService;
        }

        // GET: Contract
        public async Task<IActionResult> Index()
        {
            var contracts = await _contractService.GetAllContractsAsync();
            return View(contracts);
        }

        // GET: Contract/Expiring
        public async Task<IActionResult> Expiring()
        {
            var contracts = await _contractService.GetExpiringContractsAsync(30);
            return View(contracts);
        }

        // GET: Contract/Terminated
        [Authorize(Roles = "HRAdmin")]
        public async Task<IActionResult> Terminated()
        {
            var terminations = await _contractService.GetTerminatedContractsAsync();
            return View(terminations);
        }

        // GET: Contract/Details/5
        public async Task<IActionResult> Details(int id)
        {
            var contract = await _contractService.GetContractByIdAsync(id);

            if (contract == null)
            {
                return NotFound();
            }

            return View(contract);
        }

        // GET: Contract/Create
        public async Task<IActionResult> Create(int? employeeId)
        {
            // Populate employee dropdown
            var employees = await _employeeService.GetAllEmployeesAsync();
            ViewBag.Employees = new Microsoft.AspNetCore.Mvc.Rendering.SelectList(
                employees.Select(e => new { 
                    Value = e.EmployeeId, 
                    Text = $"{e.FullName} (ID: {e.EmployeeId})" 
                }),
                "Value",
                "Text",
                employeeId // Pre-select if provided
            );
            
            var contract = new Contract
            {
                EmployeeId = employeeId ?? 0,
                StartDate = DateTime.Today,
                Status = "Active"
            };
            
            return View(contract);
        }

        // POST: Contract/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Contract contract)
        {
            try
            {
                if (ModelState.IsValid)
                {
                    var newId = await _contractService.AddContractAsync(contract);
                    
                    if (newId > 0)
                    {
                        TempData["SuccessMessage"] = "Contract created successfully!";
                        return RedirectToAction(nameof(Details), new { id = newId });
                    }
                }

                TempData["ErrorMessage"] = "Failed to create contract. Please check the form and try again.";
                return View(contract);
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                return View(contract);
            }
        }

        // GET: Contract/Edit/5
        public async Task<IActionResult> Edit(int id)
        {
            var contract = await _contractService.GetContractByIdAsync(id);

            if (contract == null)
            {
                return NotFound();
            }

            // Populate employee dropdown
            var employees = await _employeeService.GetAllEmployeesAsync();
            ViewBag.Employees = new Microsoft.AspNetCore.Mvc.Rendering.SelectList(
                employees.Select(e => new { 
                    Value = e.EmployeeId, 
                    Text = $"{e.FullName} (ID: {e.EmployeeId})" 
                }),
                "Value",
                "Text",
                contract.EmployeeId // Pre-select current employee
            );

            return View(contract);
        }

        // POST: Contract/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Contract contract)
        {
            if (id != contract.ContractId)
            {
                return BadRequest();
            }

            try
            {
                if (ModelState.IsValid)
                {
                    await _contractService.UpdateContractAsync(contract);
                    TempData["SuccessMessage"] = "Contract updated successfully!";
                    return RedirectToAction(nameof(Details), new { id });
                }

                return View(contract);
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                return View(contract);
            }
        }

        // GET: Contract/Renew/5
        public async Task<IActionResult> Renew(int id)
        {
            var contract = await _contractService.GetContractByIdAsync(id);
            if (contract == null) return NotFound();
            return View(contract);
        }

        // POST: Contract/Renew
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Renew(int contractId, DateTime newEndDate)
        {
            try
            {
                await _contractService.RenewContractAsync(contractId, newEndDate);
                TempData["SuccessMessage"] = "Contract renewed successfully!";
                return RedirectToAction(nameof(Details), new { id = contractId });
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                // Reload view with contract data if error
                var contract = await _contractService.GetContractByIdAsync(contractId);
                return View(contract);
            }
        }

        // GET: Contract/Terminate/5
        public async Task<IActionResult> Terminate(int id)
        {
            var contract = await _contractService.GetContractByIdAsync(id);
            if (contract == null) return NotFound();
            return View(contract);
        }

        // POST: Contract/Terminate
        [HttpPost, ActionName("Terminate")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> TerminateConfirmed(int contractId, string reason, DateTime? terminationDate)
        {
            try
            {
                await _contractService.TerminateContractAsync(contractId, reason, terminationDate ?? DateTime.Now);
                TempData["SuccessMessage"] = "Contract terminated successfully!";
                return RedirectToAction(nameof(Details), new { id = contractId });
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = $"Error: {ex.Message}";
                var contract = await _contractService.GetContractByIdAsync(contractId);
                return View(contract);
            }
        }
    }
}
