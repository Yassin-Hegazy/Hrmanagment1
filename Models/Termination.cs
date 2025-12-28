using System.ComponentModel.DataAnnotations;

namespace HRMANGMANGMENT.Models
{
    public class Termination
    {
        public int TerminationId { get; set; }

        [Required]
        [DataType(DataType.Date)]
        public DateTime Date { get; set; }

        [Required]
        [StringLength(1000, ErrorMessage = "Reason cannot exceed 1000 characters.")]
        public string Reason { get; set; } = string.Empty;

        public int ContractId { get; set; }

        // Additional properties for View display
        public string? EmployeeName { get; set; }
        public string? ProfileImage { get; set; }
        public string? DepartmentName { get; set; }
        public string? ContractType { get; set; }
    }
}
