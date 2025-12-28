# HR Management System

This is the HR Management System built with ASP.NET Core MVC.

## Prerequisities
- Visual Studio 2022
- SQL Server (LocalDB or Express)
- .NET 8.0 SDK

## Setup Instructions

### 1. Database Setup
The project requires a SQL Server database. The scripts are located in the `HRMANGMANGMENT/DBscripts` folder.

1. Create a new database named `HRFINAL` (or adjust the connection string to match your database name).
2. Run the scripts in the following order:
   - First: `tables.sql` (Creates tables and schemas)
   - Second: `procedures.sql` (Creates stored procedures)

### 2. Connection String
The default connection string in `appsettings.json` is configured for Visual Studio's **LocalDB**:
```json
"Server=(localdb)\\MSSQLLocalDB;Database=HRFINAL;Integrated Security=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
```

**If you are using SQL Server Express:**
1. Do not modify `appsettings.json`.
2. Create a file named `appsettings.Development.json` in the `HRMANGMANGMENT` project folder (same place as `appsettings.json`).
3. Add your connection string there:
   ```json
   {
     "ConnectionStrings": {
       "HRDatabase": "Server=YOUR_COMPUTER_NAME\\SQLEXPRESS;Database=HRFINAL;Integrated Security=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
     }
   }
   ```

## Getting Started
1. Open `HRMANGMANGMENT.sln` in Visual Studio.
2. Build the solution (Ctrl+Shift+B).
3. Run the application (F5).
