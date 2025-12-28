namespace HRMANGMANGMENT.Models
{
    public class Employee
    {
        public int EmployeeId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? FullName { get; set; }
        public string NationalId { get; set; } = string.Empty;
        public DateTime? DateOfBirth { get; set; }
        public string? CountryOfBirth { get; set; }
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public string? Address { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactPhone { get; set; }
        public string? Relationship { get; set; }
        public string? Biography { get; set; }
        public string? ProfileImage { get; set; }
        public string? EmploymentProgress { get; set; }
        public string? AccountStatus { get; set; }
        public string? EmploymentStatus { get; set; }
        public DateTime? HireDate { get; set; }
        public bool IsActive { get; set; } = true;
        public int ProfileCompletion { get; set; } = 0;
        
        // Foreign Keys
        public int? DepartmentId { get; set; }
        public int? PositionId { get; set; }
        public int? ManagerId { get; set; }
        public int? ContractId { get; set; }
        public int? TaxFormId { get; set; }
        public int? SalaryTypeId { get; set; }
        public int? PayGrade { get; set; }

        // Authentication & Security
        public string? PasswordHash { get; set; }
        public string? PasswordSalt { get; set; }
        public DateTime? LastLogin { get; set; }
        public bool IsLocked { get; set; } = false;

        // Navigation Properties
        public string? DepartmentName { get; set; }
        public string? PositionTitle { get; set; }
        public string? ManagerName { get; set; }
        public string? RoleName { get; set; } // Primary role name for display
        public List<int>? RoleIds { get; set; } // List of all role IDs

        // Role-Specific Properties
        // HR Administrator
        public string? ApprovalLevel { get; set; }
        public string? RecordAccessScope { get; set; }
        public string? DocumentValidationRights { get; set; }

        // System Administrator
        public string? SystemPrivilegeLevel { get; set; }
        public string? ConfigurableFields { get; set; }
        public string? AuditVisibilityScope { get; set; }

        // Payroll Specialist
        public string? AssignedRegion { get; set; }
        public string? ProcessingFrequency { get; set; }
        public string? LastProcessedPeriod { get; set; }

        // Line Manager
        public int? TeamSize { get; set; }
        public string? SupervisedDepartments { get; set; }
        public string? ApprovalLimit { get; set; }
    }
}

