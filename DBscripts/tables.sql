GO
USE HRFINAL;
/*
CREATE DATABASE HRFINAL;
GO
UPDATE Employee 
SET profile_image = '1041_f8bc9bf4-3654-4a51-8f91-f049a000548a.jpg'
WHERE employee_id = 1041;
*/


-- =============================================
-- 2. TABLE CREATION
-- =============================================

CREATE TABLE Employee (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    full_name AS (first_name + ' ' + last_name),
    national_id VARCHAR(30) NOT NULL UNIQUE,
    date_of_birth DATE,
    country_of_birth VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(255) UNIQUE,
    address VARCHAR(255),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(30),
    relationship VARCHAR(50),
    biography VARCHAR(1000),
    profile_image VARCHAR(255),
    employment_progress VARCHAR(50),
    account_status VARCHAR(50),
    employment_status VARCHAR(50),
    hire_date DATE DEFAULT GETDATE(),
    is_active BIT DEFAULT 1,
    profile_completion INT DEFAULT 0 CHECK (profile_completion BETWEEN 0 AND 100),
    department_id INT NOT NULL,
    position_id INT NOT NULL,
    manager_id INT NULL, 
    contract_id INT NOT NULL,
    tax_form_id INT NOT NULL,
    salary_type_id INT NOT NULL,
    pay_grade INT
);

CREATE TABLE HRAdministrator (
    employee_id INT PRIMARY KEY,
    approval_level VARCHAR(50),   
    record_access_scope VARCHAR(100), 
    document_validation_rights VARCHAR(100)
);

CREATE TABLE SystemAdministrator (
    employee_id INT PRIMARY KEY,
    system_privilege_level VARCHAR(50),       
    configurable_fields VARCHAR(200),         
    audit_visibility_scope VARCHAR(100)       
);

CREATE TABLE PayrollSpecialist (
    employee_id INT PRIMARY KEY,
    assigned_region VARCHAR(50),                
    processing_frequency VARCHAR(50),           
    last_processed_period VARCHAR(50)           
);

CREATE TABLE LineManager (
    employee_id INT PRIMARY KEY,
    team_size INT,
    supervised_departments VARCHAR(200),         
    approval_limit VARCHAR(50)                    
);

CREATE TABLE Position (
    position_id     INT PRIMARY KEY IDENTITY(1,1),
    position_title  VARCHAR(150)  NOT NULL,
    responsibilities VARCHAR(1000),
    status          VARCHAR(50)   NOT NULL  
);

CREATE TABLE Department (
    department_id INT PRIMARY KEY IDENTITY(1,1),   
    department_name VARCHAR(50) NOT NULL,           
    purpose VARCHAR(200),                           
    department_head_id INT                          
);

CREATE TABLE Skill(
    skill_id int primary key identity(1,1),
    skill_name varchar(20),
    description varchar(20)
);

CREATE TABLE Employee_Skill(
    employee_id int,
    skill_id int,
    proficiency_level varchar(20),
    primary key(employee_id, skill_id)
);

CREATE TABLE Verification(
    verification_id int primary key identity(1,1),
    verification_type varchar(50),
    issuer varchar(50),
    issue_date date,
    expiry_period int
);

CREATE TABLE Employee_Verification(
    employee_id int,
    verification_id int,
    primary key(employee_id, verification_id)
);

CREATE TABLE [Role] (
    role_id INT PRIMARY KEY IDENTITY(1,1),
    role_name VARCHAR(50) NOT NULL,
    purpose VARCHAR(200)                          
);

CREATE TABLE Employee_Role (
    employee_id INT,                              
    role_id INT,                               
    assigned_date DATE DEFAULT GETDATE(),        
    PRIMARY KEY (employee_id, role_id)        
);

CREATE TABLE RolePermission (
    role_id INT,
    permission_name VARCHAR(100),
    allowed_action VARCHAR(50),
    PRIMARY KEY (role_id, permission_name)
);

CREATE TABLE Contract(
    contract_id int primary key identity(1,1),
    contract_type varchar(20),
    contract_start_date date,
    contract_end_date date, 
    contract_current_state varchar(20)
);

CREATE TABLE FullTimeContract(
    contract_id int primary key ,
    leave_entitlement int,
    insurance_eligibility bit,
    weekly_working_hours int
);

CREATE TABLE PartTimeContract(
    contract_id int primary key ,
    working_hours int,
    hourly_rate decimal(20,5)
);

CREATE TABLE ConsultantContract(
    contract_id int primary key ,
    project_scope varchar(20),
    fees decimal(20,2),
    payment_schedule varchar(20)
);

CREATE TABLE InternshipContract(
    contract_id int primary key ,
    mentoring varchar(20),
    evaluation varchar(20),
    stipend_related varchar(20)
);

CREATE TABLE Insurance (
    insurance_id INT PRIMARY KEY IDENTITY(1,1),
    type VARCHAR(100) NOT NULL,
    contribution_rate DECIMAL(5,2),
    coverage VARCHAR(1000)
);

CREATE TABLE Termination (
    termination_id INT PRIMARY KEY IDENTITY(1,1),
    date DATE,
    reason VARCHAR(1000),
    contract_id INT NOT NULL
);

CREATE TABLE Reimbursement (
    reimbursement_id INT PRIMARY KEY IDENTITY(1,1),
    type VARCHAR(50),
    claim_type VARCHAR(50),
    approval_date DATE default getdate(),
    current_status VARCHAR(50),
    amount decimal(10,2),
    employee_id INT NOT NULL
);

CREATE TABLE Mission (
    mission_id INT PRIMARY KEY IDENTITY(1,1),
    destination VARCHAR(100),
    start_date DATE,
    end_date DATE,
    status VARCHAR(50),
    employee_id INT NOT NULL,
    manager_id INT NULL
);

CREATE TABLE [Leave] (
    leave_id INT PRIMARY KEY IDENTITY(1,1),
    leave_type VARCHAR(50) NOT NULL,
    leave_description VARCHAR(255)
);

CREATE TABLE VacationLeave (
    leave_id INT PRIMARY KEY,
    carry_over_days INT,
    approving_manager VARCHAR(100)
);

CREATE TABLE SickLeave (
    leave_id INT PRIMARY KEY,
    medical_cert_required BIT,
    physician_id INT
);

CREATE TABLE ProbationLeave (
    leave_id INT PRIMARY KEY,
    eligibility_start_date DATE,
    probation_period INT 
);

CREATE TABLE HolidayLeave (
    leave_id INT PRIMARY KEY,
    holiday_name VARCHAR(100) NOT NULL,
    official_recognition BIT, 
    regional_scope VARCHAR(50)
);

CREATE TABLE LeavePolicy (
    policy_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    purpose VARCHAR(MAX),
    eligibility_rules VARCHAR(MAX),
    notice_period INT,
    special_leave_type VARCHAR(50),
    reset_on_new_year BIT 
);

CREATE TABLE LeaveRequest (
    request_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,            
    leave_id INT NOT NULL,
    justification VARCHAR(MAX),
    duration INT,
    approval_timing DATETIME,
    status VARCHAR(10),
    submission_date DATETIME
);

CREATE TABLE LeaveEntitlement (
    employee_id INT NOT NULL,
    leave_type_id INT NOT NULL,
    entitlement DECIMAL(5, 2) NOT NULL,
    PRIMARY KEY (employee_id, leave_type_id)
);

CREATE TABLE LeaveDocument (
    document_id INT PRIMARY KEY IDENTITY(1,1),
    leave_request_id INT NOT NULL,
    file_path VARCHAR(260) NOT NULL,
    uploaded_at DATETIME NOT NULL
);

CREATE TABLE Attendance(
    attendance_id int primary key identity(1,1),
    employee_id int,
    shift_id int,
    entry_time datetime,
    exit_time datetime,
    duration decimal(20,2),
    login_method varchar(20),
    logout_method varchar(20),
    exception_id int
);

CREATE TABLE AttendanceLog (
    attendance_log_id INT PRIMARY KEY IDENTITY(1,1),
    attendance_id INT NOT NULL,
    actor VARCHAR(100),
    timestamp DATETIME ,
    reason VARCHAR(1000)
);

CREATE TABLE AttendanceCorrectionRequest (
    request_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT,
    date DATE,
    correction_type VARCHAR(50),
    reason VARCHAR(200),
    status VARCHAR(20),
    recorded_by INT
);

CREATE TABLE ShiftSchedule(
    shift_id int primary key identity(1,1),
    name varchar(50),
    type varchar(50),
    start_time time,
    end_time time, 
    break_duration decimal(20,2),
    break_start_time time NULL, -- Added for Split Shift support
    shift_date date,
    status bit,
    cycle_id int NULL -- Added for Rotational Shift support
);

CREATE TABLE ShiftAssignment (
    assignment_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    shift_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20)
);

CREATE TABLE Exception (
    exception_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    date DATE default getdate(),
    status VARCHAR(50)
);

CREATE TABLE Employee_Exception (
    employee_id INT NOT NULL,
    exception_id INT NOT NULL,
    PRIMARY KEY (employee_id, exception_id)
);

CREATE TABLE Payroll (
    payroll_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    base_amount DECIMAL(18, 2),
    taxes DECIMAL(18, 2),
    adjustments DECIMAL(18, 2),
    contributions DECIMAL(18, 2),
    actual_pay DECIMAL(18, 2),
    net_salary DECIMAL(18, 2),
    payment_date DATE
);

CREATE TABLE Currency (
    CurrencyCode     VARCHAR(10) PRIMARY KEY,     
    CurrencyName     VARCHAR(100) NOT NULL,       
    ExchangeRate     DECIMAL(18,6) NOT NULL,      
    CreatedDate      DATETIME     DEFAULT GETDATE(),
    LastUpdated      DATETIME     DEFAULT GETDATE()
);

CREATE TABLE SalaryType (
    salary_type_id INT PRIMARY KEY IDENTITY(1,1),
    type VARCHAR(50), 
    payment_frequency VARCHAR(50), 
    currency VARCHAR(10) 
);

CREATE TABLE HourlySalaryType (
    salary_type_id INT PRIMARY KEY,
    hourly_rate DECIMAL(10, 2), 
    max_monthly_hours INT
);

CREATE TABLE MonthlySalaryType (
    salary_type_id INT PRIMARY KEY,
    tax_rule VARCHAR(255), 
    contribution_scheme VARCHAR(255)
);

CREATE TABLE ContractSalaryType (
    salary_type_id INT PRIMARY KEY,
    contract_value DECIMAL(10, 2), 
    installment_details VARCHAR(255)
);

CREATE TABLE AllowanceDeduction (
    ad_id INT PRIMARY KEY IDENTITY(1,1),
    payroll_id INT NOT NULL,
    employee_id INT NOT NULL,
    type VARCHAR(50) NOT NULL, 
    amount DECIMAL(18, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL, 
    duration VARCHAR(50),
    timezone VARCHAR(50)
);

CREATE TABLE PayrollPolicy (
    policy_id INT PRIMARY KEY IDENTITY(1,1),
    effective_date DATE,  
    type VARCHAR(50),
    description VARCHAR(255) 
);

CREATE TABLE OvertimePolicy (
    policy_id INT PRIMARY KEY,
    weekday_rate_multiplier DECIMAL(3, 1),
    weekend_rate_multiplier DECIMAL(3, 1),
    max_hours_per_month INT
);

CREATE TABLE LatenessPolicy (
    policy_id INT PRIMARY KEY,
    grace_period_mins INT,  
    deduction_rate VARCHAR(50)
);

CREATE TABLE BonusPolicy (
    policy_id INT PRIMARY KEY,
    bonus_type VARCHAR(50), 
    eligibility_criteria VARCHAR(255) 
);

CREATE TABLE DeductionPolicy (
    policy_id INT PRIMARY KEY,
    deduction_reason VARCHAR(100), 
    calculation_mode VARCHAR(100)
);

CREATE TABLE PayrollPolicy_ID (
    payroll_id INT NOT NULL,
    policy_id INT NOT NULL,
    PRIMARY KEY (payroll_id, policy_id)
);

CREATE TABLE Payroll_Log (
    payroll_log_id INT PRIMARY KEY,
    payroll_id INT NOT NULL,
    actor VARCHAR(100),
    change_date DATETIME NOT NULL,
    modification_type VARCHAR(50)
);

CREATE TABLE TaxForm (
    tax_form_id INT PRIMARY KEY IDENTITY(1,1),
    jurisdiction VARCHAR(100),
    validity_period VARCHAR(100),
    form_content VARCHAR(1000)
);

CREATE TABLE PayGrade (
    pay_grade_id INT PRIMARY KEY IDENTITY(1,1),   
    grade_name VARCHAR(50) NOT NULL,               
    min_salary DECIMAL(15,2),                      
    max_salary DECIMAL(15,2)                       
);

CREATE TABLE PayrollPeriod(
    payroll_period_id int primary key identity(1,1),
    payroll_id int, 
    start_date date,
    end_date date,
    status varchar(100)
);

CREATE TABLE  Notification (
    notification_id INT PRIMARY KEY IDENTITY(1,1),
    message_content VARCHAR(1000),
    timestamp DATETIME ,
    urgency VARCHAR(50),
    read_status VARCHAR(50),
    notification_type VARCHAR(50)
);

CREATE TABLE Employee_Notification (
    employee_id INT NOT NULL,
    notification_id INT NOT NULL,
    delivery_status VARCHAR(50),
    delivered_at DATETIME,
    PRIMARY KEY (employee_id, notification_id)
);

CREATE TABLE EmployeeHierarchy (
    employee_id INT,
    manager_id INT,
    hierarchy_level INT,
    PRIMARY KEY (employee_id, manager_id)   
);

CREATE TABLE Device (
    device_id INT PRIMARY KEY,
    device_type VARCHAR(50) NOT NULL,
    terminal_id INT,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    employee_id INT
);

CREATE TABLE AttendanceSource (
    attendance_id INT,
    device_id INT,
    source_type VARCHAR(50),
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    recorded_at DATETIME,
    PRIMARY KEY (attendance_id, device_id)
);

CREATE TABLE ShiftCycle (
    cycle_id INT IDENTITY PRIMARY KEY,
    cycle_name VARCHAR(100) NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE ShiftCycleAssignment (
    cycle_id INT,
    shift_id INT,
    order_number INT NOT NULL,
    PRIMARY KEY (cycle_id, shift_id)
);

CREATE TABLE ApprovalWorkflow (
    workflow_id INT PRIMARY KEY IDENTITY(1,1),
    workflow_type VARCHAR(100),
    threshold_amount DECIMAL(18,2),
    approver_role VARCHAR(100),
    created_by INT NOT  NULL,
    status VARCHAR(50)
);

CREATE TABLE ApprovalWorkflowStep (
    workflow_id INT NOT NULL,
    step_number INT NOT NULL,
    role_id INT NOT NULL,
    action_required VARCHAR(100),
    PRIMARY KEY (workflow_id, step_number)
);

CREATE TABLE ManagerNotes(
    note_id int primary key identity(1,1), 
    employee_id int,
    manager_id int,
    note_content varchar(100),
    created_at varchar(50)
);



-- Employee Table
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_Department FOREIGN KEY (department_id) REFERENCES Department(department_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_Position FOREIGN KEY (position_id) REFERENCES Position(position_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_Manager FOREIGN KEY (manager_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_TaxForm FOREIGN KEY (tax_form_id) REFERENCES TaxForm(tax_form_id) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_SalaryType FOREIGN KEY (salary_type_id) REFERENCES SalaryType(salary_type_id) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE Employee ADD CONSTRAINT FK_Employee_PayGrade FOREIGN KEY (pay_grade) REFERENCES PayGrade(pay_grade_id) ON DELETE NO ACTION ON UPDATE CASCADE;

-- HR / System Admin / Specialist / Line Manager
ALTER TABLE HRAdministrator ADD CONSTRAINT FK_HRAdministrator_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE SystemAdministrator ADD CONSTRAINT FK_SystemAdministrator_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE PayrollSpecialist ADD CONSTRAINT FK_PayrollSpecialist_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE LineManager ADD CONSTRAINT FK_LineManager_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Department (Cycle breaker)
ALTER TABLE Department ADD CONSTRAINT FK_Department_EmployeeHead FOREIGN KEY (department_head_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT

-- Skills / Verification
ALTER TABLE Employee_Skill ADD CONSTRAINT FK_EmployeeSkill_Skill FOREIGN KEY (skill_id) REFERENCES Skill(skill_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Employee_Skill ADD CONSTRAINT FK_EmployeeSkill_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Employee_Verification ADD CONSTRAINT FK_EmployeeVerification_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Employee_Verification ADD CONSTRAINT FK_EmployeeVerification_Verification FOREIGN KEY (verification_id) REFERENCES Verification(verification_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Roles
ALTER TABLE Employee_Role ADD CONSTRAINT FK_EmployeeRole_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Employee_Role ADD CONSTRAINT FK_EmployeeRole_Role FOREIGN KEY (role_id) REFERENCES Role(role_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE RolePermission ADD CONSTRAINT FK_RolePermission_Role FOREIGN KEY (role_id) REFERENCES Role(role_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Contract Inheritance
ALTER TABLE FullTimeContract ADD CONSTRAINT FK_FullTimeContract_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE PartTimeContract ADD CONSTRAINT FK_PartTimeContract_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ConsultantContract ADD CONSTRAINT FK_ConsultantContract_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE InternshipContract ADD CONSTRAINT FK_InternshipContract_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Termination
ALTER TABLE Termination ADD CONSTRAINT FK_Termination_Contract FOREIGN KEY (contract_id) REFERENCES Contract(contract_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Reimbursement / Mission
ALTER TABLE Reimbursement ADD CONSTRAINT FK_Reimbursement_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Mission (STRICT FIX: NO ACTION ON UPDATE AND DELETE)
ALTER TABLE Mission ADD CONSTRAINT FK_Mission_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE Mission ADD CONSTRAINT FK_Mission_Manager FOREIGN KEY (manager_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Leaves
ALTER TABLE VacationLeave ADD CONSTRAINT FK_VacationLeave_Leave FOREIGN KEY (leave_id) REFERENCES [Leave](leave_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE SickLeave ADD CONSTRAINT FK_SickLeave_Leave FOREIGN KEY (leave_id) REFERENCES [Leave](leave_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ProbationLeave ADD CONSTRAINT FK_ProbationLeave_Leave FOREIGN KEY (leave_id) REFERENCES [Leave](leave_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE HolidayLeave ADD CONSTRAINT FK_HolidayLeave_Leave FOREIGN KEY (leave_id) REFERENCES [Leave](leave_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE LeaveRequest ADD CONSTRAINT FK_LeaveRequest_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE LeaveRequest ADD CONSTRAINT FK_LeaveRequest_Leave FOREIGN KEY (leave_id) REFERENCES [Leave](leave_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE LeaveEntitlement ADD CONSTRAINT FK_LeaveEntitlement_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE LeaveEntitlement ADD CONSTRAINT FK_LeaveEntitlement_Leave FOREIGN KEY (leave_type_id) REFERENCES [Leave](leave_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE LeaveDocument ADD CONSTRAINT FK_LeaveDocument_LeaveRequest FOREIGN KEY (leave_request_id) REFERENCES LeaveRequest(request_id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Attendance
ALTER TABLE Attendance ADD CONSTRAINT FK_Attendance_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT
ALTER TABLE Attendance ADD CONSTRAINT FK_Attendance_ShiftSchedule FOREIGN KEY (shift_id) REFERENCES ShiftSchedule(shift_id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE Attendance ADD CONSTRAINT FK_Attendance_Exception FOREIGN KEY (exception_id) REFERENCES Exception(exception_id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE AttendanceLog ADD CONSTRAINT FK_AttendanceLog_Attendance FOREIGN KEY (attendance_id) REFERENCES Attendance(attendance_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Attendance Correction (STRICT FIX: NO ACTION ON UPDATE AND DELETE)
ALTER TABLE AttendanceCorrectionRequest ADD CONSTRAINT FK_AttendanceCorrectionRequest_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE AttendanceCorrectionRequest ADD CONSTRAINT FK_AttendanceCorrectionRequest_RecordedBy FOREIGN KEY (recorded_by) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- Shifts / Exceptions
ALTER TABLE ShiftAssignment ADD CONSTRAINT FK_ShiftAssignment_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ShiftAssignment ADD CONSTRAINT FK_ShiftAssignment_ShiftSchedule FOREIGN KEY (shift_id) REFERENCES ShiftSchedule(shift_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Employee_Exception ADD CONSTRAINT FK_EmployeeException_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Employee_Exception ADD CONSTRAINT FK_EmployeeException_Exception FOREIGN KEY (exception_id) REFERENCES Exception(exception_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Payroll (Critical: STRICT NO ACTION)
ALTER TABLE Payroll ADD CONSTRAINT FK_Payroll_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT
ALTER TABLE SalaryType ADD CONSTRAINT FK_SalaryType_Currency FOREIGN KEY (currency) REFERENCES Currency(CurrencyCode) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE HourlySalaryType ADD CONSTRAINT FK_HourlySalaryType_SalaryType FOREIGN KEY (salary_type_id) REFERENCES SalaryType(salary_type_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE MonthlySalaryType ADD CONSTRAINT FK_MonthlySalaryType_SalaryType FOREIGN KEY (salary_type_id) REFERENCES SalaryType(salary_type_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ContractSalaryType ADD CONSTRAINT FK_ContractSalaryType_SalaryType FOREIGN KEY (salary_type_id) REFERENCES SalaryType(salary_type_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Allowance Deduction (Critical: STRICT NO ACTION)
-- This is where the error was happening. By removing ON UPDATE CASCADE, we break the path check.
ALTER TABLE AllowanceDeduction ADD CONSTRAINT FK_AllowanceDeduction_Payroll FOREIGN KEY (payroll_id) REFERENCES Payroll(payroll_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE AllowanceDeduction ADD CONSTRAINT FK_AllowanceDeduction_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE AllowanceDeduction ADD CONSTRAINT FK_AllowanceDeduction_Currency FOREIGN KEY (currency) REFERENCES Currency(CurrencyCode) ON DELETE NO ACTION ON UPDATE CASCADE;

-- Payroll Policies
ALTER TABLE OvertimePolicy ADD CONSTRAINT FK_OvertimePolicy_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE LatenessPolicy ADD CONSTRAINT FK_LatenessPolicy_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE BonusPolicy ADD CONSTRAINT FK_BonusPolicy_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE DeductionPolicy ADD CONSTRAINT FK_DeductionPolicy_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE PayrollPolicy_ID ADD CONSTRAINT FK_PayrollPolicyID_Payroll FOREIGN KEY (payroll_id) REFERENCES Payroll(payroll_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE PayrollPolicy_ID ADD CONSTRAINT FK_PayrollPolicyID_PayrollPolicy FOREIGN KEY (policy_id) REFERENCES PayrollPolicy(policy_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Payroll_Log ADD CONSTRAINT FK_PayrollLog_Payroll FOREIGN KEY (payroll_id) REFERENCES Payroll(payroll_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE PayrollPeriod ADD CONSTRAINT FK_PayrollPeriod_Payroll FOREIGN KEY (payroll_id) REFERENCES Payroll(payroll_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Notifications / Hierarchy / Devices
ALTER TABLE Employee_Notification ADD CONSTRAINT FK_EmployeeNotification_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Employee_Notification ADD CONSTRAINT FK_EmployeeNotification_Notification FOREIGN KEY (notification_id) REFERENCES Notification(notification_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE EmployeeHierarchy ADD CONSTRAINT FK_EmployeeHierarchy_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE EmployeeHierarchy ADD CONSTRAINT FK_EmployeeHierarchy_Manager FOREIGN KEY (manager_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT
ALTER TABLE Device ADD CONSTRAINT FK_Device_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE AttendanceSource ADD CONSTRAINT FK_AttendanceSource_Attendance FOREIGN KEY (attendance_id) REFERENCES Attendance(attendance_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE AttendanceSource ADD CONSTRAINT FK_AttendanceSource_Device FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ShiftCycleAssignment ADD CONSTRAINT FK_ShiftCycleAssignment_ShiftCycle FOREIGN KEY (cycle_id) REFERENCES ShiftCycle(cycle_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ShiftCycleAssignment ADD CONSTRAINT FK_ShiftCycleAssignment_ShiftSchedule FOREIGN KEY (shift_id) REFERENCES ShiftSchedule(shift_id) ON DELETE CASCADE ON UPDATE CASCADE;

-- Approval Workflows & Notes
ALTER TABLE ApprovalWorkflow ADD CONSTRAINT FK_ApprovalWorkflow_CreatedBy FOREIGN KEY (created_by) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ApprovalWorkflowStep ADD CONSTRAINT FK_ApprovalWorkflowStep_ApprovalWorkflow FOREIGN KEY (workflow_id) REFERENCES ApprovalWorkflow(workflow_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ApprovalWorkflowStep ADD CONSTRAINT FK_ApprovalWorkflowStep_Role FOREIGN KEY (role_id) REFERENCES Role(role_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ManagerNotes ADD CONSTRAINT FK_ManagerNotes_Employee FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ManagerNotes ADD CONSTRAINT FK_ManagerNotes_Manager FOREIGN KEY (manager_id) REFERENCES Employee(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION; -- STRICT
GO

ALTER TABLE Contract
ADD insurance_id INT;
GO
ALTER TABLE Contract
ADD CONSTRAINT FK_Contract_Insurance
FOREIGN KEY (insurance_id) REFERENCES Insurance(insurance_id)
ON DELETE SET NULL 
ON UPDATE CASCADE;
GO
ALTER TABLE Employee
ADD  password_hash varchar(max) ;
ALTER TABLE Employee
add  password_salt varchar(max) ;
ALTER TABLE Employee
add  last_login datetime NULL;
ALTER TABLE Employee
ADD  is_locked BIT DEFAULT 0;
select * from Employee;


PRINT 'Updating Employee table schema to allow NULL foreign keys...';
GO

-- Make department_id nullable
IF EXISTS (SELECT * FROM sys.columns 
           WHERE object_id = OBJECT_ID('Employee') 
           AND name = 'department_id' 
           AND is_nullable = 0)
BEGIN
    ALTER TABLE Employee
    ALTER COLUMN department_id INT NULL;
    PRINT 'department_id is now nullable.';
END
ELSE
BEGIN
    PRINT 'department_id is already nullable.';
END
GO

-- Make position_id nullable
IF EXISTS (SELECT * FROM sys.columns 
           WHERE object_id = OBJECT_ID('Employee') 
           AND name = 'position_id' 
           AND is_nullable = 0)
BEGIN
    ALTER TABLE Employee
    ALTER COLUMN position_id INT NULL;
    PRINT 'position_id is now nullable.';
END
ELSE
BEGIN
    PRINT 'position_id is already nullable.';
END
GO

-- Make contract_id nullable
IF EXISTS (SELECT * FROM sys.columns 
           WHERE object_id = OBJECT_ID('Employee') 
           AND name = 'contract_id' 
           AND is_nullable = 0)
BEGIN
    ALTER TABLE Employee
    ALTER COLUMN contract_id INT NULL;
    PRINT 'contract_id is now nullable.';
END
ELSE
BEGIN
    PRINT 'contract_id is already nullable.';
END
GO

-- Make tax_form_id nullable
IF EXISTS (SELECT * FROM sys.columns 
           WHERE object_id = OBJECT_ID('Employee') 
           AND name = 'tax_form_id' 
           AND is_nullable = 0)
BEGIN
    ALTER TABLE Employee
    ALTER COLUMN tax_form_id INT NULL;
    PRINT 'tax_form_id is now nullable.';
END
ELSE
BEGIN
    PRINT 'tax_form_id is already nullable.';
END
GO

-- Make salary_type_id nullable
IF EXISTS (SELECT * FROM sys.columns 
           WHERE object_id = OBJECT_ID('Employee') 
           AND name = 'salary_type_id' 
           AND is_nullable = 0)
BEGIN
    ALTER TABLE Employee
    ALTER COLUMN salary_type_id INT NULL;
    PRINT 'salary_type_id is now nullable.';
END
ELSE
BEGIN
    PRINT 'salary_type_id is already nullable.';
END

-- =============================================
-- NOTIFICATION ENHANCEMENT: Add sender_id column
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('Notification') 
               AND name = 'sender_id')
BEGIN
    ALTER TABLE Notification ADD sender_id INT NULL;
    ALTER TABLE Notification ADD CONSTRAINT FK_Notification_Sender 
        FOREIGN KEY (sender_id) REFERENCES Employee(employee_id) 
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT 'Added sender_id column to Notification table.';
END
GO

-- =============================================
-- NOTIFICATION ENHANCEMENT: Add read_at column
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('Employee_Notification') 
               AND name = 'read_at')
BEGIN
    ALTER TABLE Employee_Notification ADD read_at DATETIME NULL;
    PRINT 'Added read_at column to Employee_Notification table.';
END
GO

-- =============================================
-- ANALYTICS ENHANCEMENT: Add gender column
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.columns 
               WHERE object_id = OBJECT_ID('Employee') 
               AND name = 'gender')
BEGIN
    ALTER TABLE Employee ADD gender VARCHAR(20) NULL;
    PRINT 'Added gender column to Employee table.';
END
GO

USE HRFINAL;
CREATE TABLE AttendanceRule (
    rule_id INT PRIMARY KEY IDENTITY(1,1),
    rule_type VARCHAR(50),
    rule_name VARCHAR(100),
    threshold_minutes INT,
    penalty_amount DECIMAL(10,2),
    description VARCHAR(255),
    is_active BIT,
    created_date DATETIME
);
