-- =============================================
-- NOTIFICATION MODULE TEST SCRIPT
-- =============================================
-- Run this script to test all new notification functionality
-- Prerequisites: Run tables.sql and notification_procedures.sql first
-- =============================================

USE HRFINAL;
GO

-- =============================================
-- SETUP: Ensure there's a manager-employee relationship for testing
-- =============================================
PRINT '--- SETUP: Checking/Creating test team relationship ---';

DECLARE @Manager INT;
DECLARE @TeamMember INT;

-- Find an active employee to be the manager
SELECT TOP 1 @Manager = employee_id FROM Employee WHERE is_active = 1 ORDER BY employee_id;

-- Find another active employee to be a team member
SELECT TOP 1 @TeamMember = employee_id FROM Employee WHERE is_active = 1 AND employee_id <> @Manager ORDER BY employee_id DESC;

IF @Manager IS NOT NULL AND @TeamMember IS NOT NULL
BEGIN
    -- Set the manager relationship temporarily if not exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE manager_id = @Manager AND is_active = 1)
    BEGIN
        UPDATE Employee SET manager_id = @Manager WHERE employee_id = @TeamMember;
        PRINT CONCAT('SETUP: Set employee #', @TeamMember, ' as team member of manager #', @Manager);
    END
    ELSE
    BEGIN
        PRINT CONCAT('SETUP: Manager #', @Manager, ' already has team members.');
    END
END
ELSE
BEGIN
    PRINT 'WARNING: Need at least 2 active employees for team testing.';
END
GO


PRINT '=============================================';
PRINT 'NOTIFICATION MODULE TEST SCRIPT';
PRINT '=============================================';
PRINT '';

-- =============================================
-- TEST 1: Verify new columns exist
-- =============================================
PRINT '--- TEST 1: Verify new columns exist ---';

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Notification') AND name = 'sender_id')
    PRINT 'PASS: Notification.sender_id column exists';
ELSE
    PRINT 'FAIL: Notification.sender_id column NOT FOUND';

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Employee_Notification') AND name = 'read_at')
    PRINT 'PASS: Employee_Notification.read_at column exists';
ELSE
    PRINT 'FAIL: Employee_Notification.read_at column NOT FOUND';

PRINT '';

-- =============================================
-- TEST 2: Verify stored procedures exist
-- =============================================
PRINT '--- TEST 2: Verify stored procedures exist ---';

DECLARE @procedures TABLE (ProcName VARCHAR(100));
INSERT INTO @procedures VALUES 
    ('sp_GetEmployeeNotifications'),
    ('sp_GetUnreadNotificationCount'),
    ('sp_MarkNotificationAsRead'),
    ('sp_MarkAllNotificationsAsRead'),
    ('sp_CreateNotificationForEmployee'),
    ('sp_SendTeamNotification'),
    ('sp_SendBroadcastNotification'),
    ('sp_GetTeamMembers'),
    ('sp_SendNotificationToEmployees'),
    ('sp_NotifyLeaveStatusChange'),
    ('sp_NotifyContractExpiry'),
    ('sp_NotifyShiftChange'),
    ('sp_NotifyMissionUpdate');


DECLARE @procName VARCHAR(100);
DECLARE proc_cursor CURSOR FOR SELECT ProcName FROM @procedures;
OPEN proc_cursor;
FETCH NEXT FROM proc_cursor INTO @procName;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(@procName, 'P') IS NOT NULL
        PRINT 'PASS: ' + @procName + ' exists';
    ELSE
        PRINT 'FAIL: ' + @procName + ' NOT FOUND';
    FETCH NEXT FROM proc_cursor INTO @procName;
END

CLOSE proc_cursor;
DEALLOCATE proc_cursor;

PRINT '';

-- =============================================
-- TEST 3: Create test notification
-- =============================================
PRINT '--- TEST 3: Create notification for employee ---';

-- Get a test employee ID (first active employee)
DECLARE @TestEmployeeId INT;
DECLARE @TestSenderId INT;

SELECT TOP 1 @TestEmployeeId = employee_id FROM Employee WHERE is_active = 1;
SELECT TOP 1 @TestSenderId = employee_id FROM Employee WHERE is_active = 1 AND employee_id <> @TestEmployeeId;

IF @TestEmployeeId IS NULL
BEGIN
    PRINT 'WARNING: No active employees found. Skipping functional tests.';
    GOTO EndTests;
END

PRINT 'Using Test Employee ID: ' + CAST(@TestEmployeeId AS VARCHAR);
PRINT 'Using Test Sender ID: ' + CAST(ISNULL(@TestSenderId, 0) AS VARCHAR);

-- Test creating a notification
BEGIN TRY
    EXEC sp_CreateNotificationForEmployee 
        @EmployeeId = @TestEmployeeId,
        @MessageContent = 'TEST: This is a test notification created by the test script.',
        @NotificationType = 'Test',
        @Urgency = 'Normal',
        @SenderId = @TestSenderId;
    PRINT 'PASS: sp_CreateNotificationForEmployee executed successfully';
END TRY
BEGIN CATCH
    PRINT 'FAIL: sp_CreateNotificationForEmployee - ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- =============================================
-- TEST 4: Get employee notifications
-- =============================================
PRINT '--- TEST 4: Get employee notifications ---';

BEGIN TRY
    EXEC sp_GetEmployeeNotifications @EmployeeId = @TestEmployeeId;
    PRINT 'PASS: sp_GetEmployeeNotifications executed successfully';
END TRY
BEGIN CATCH
    PRINT 'FAIL: sp_GetEmployeeNotifications - ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- =============================================
-- TEST 5: Get unread count
-- =============================================
PRINT '--- TEST 5: Get unread notification count ---';

BEGIN TRY
    EXEC sp_GetUnreadNotificationCount @EmployeeId = @TestEmployeeId;
    PRINT 'PASS: sp_GetUnreadNotificationCount executed successfully';
END TRY
BEGIN CATCH
    PRINT 'FAIL: sp_GetUnreadNotificationCount - ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- =============================================
-- TEST 6: Mark notification as read
-- =============================================
PRINT '--- TEST 6: Mark notification as read ---';

DECLARE @TestNotificationId INT;
SELECT TOP 1 @TestNotificationId = n.notification_id 
FROM Notification n
INNER JOIN Employee_Notification en ON n.notification_id = en.notification_id
WHERE en.employee_id = @TestEmployeeId AND n.read_status = 'Unread';

IF @TestNotificationId IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC sp_MarkNotificationAsRead 
            @NotificationId = @TestNotificationId,
            @EmployeeId = @TestEmployeeId;
        PRINT 'PASS: sp_MarkNotificationAsRead executed successfully';
        
        -- Verify read_at was set
        IF EXISTS (SELECT 1 FROM Employee_Notification WHERE notification_id = @TestNotificationId AND read_at IS NOT NULL)
            PRINT 'PASS: read_at timestamp was set correctly';
        ELSE
            PRINT 'FAIL: read_at timestamp was not set';
    END TRY
    BEGIN CATCH
        PRINT 'FAIL: sp_MarkNotificationAsRead - ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT 'SKIP: No unread notifications found to test';
END

PRINT '';

-- =============================================
-- TEST 7: Mark all as read
-- =============================================
PRINT '--- TEST 7: Mark all notifications as read ---';

BEGIN TRY
    EXEC sp_MarkAllNotificationsAsRead @EmployeeId = @TestEmployeeId;
    PRINT 'PASS: sp_MarkAllNotificationsAsRead executed successfully';
END TRY
BEGIN CATCH
    PRINT 'FAIL: sp_MarkAllNotificationsAsRead - ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- =============================================
-- TEST 8: Broadcast notification
-- =============================================
PRINT '--- TEST 8: Broadcast notification to all employees ---';

IF @TestSenderId IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC sp_SendBroadcastNotification 
            @SenderId = @TestSenderId,
            @MessageContent = 'TEST: Broadcast test notification',
            @Urgency = 'Low',
            @NotificationType = 'Test Broadcast';
        PRINT 'PASS: sp_SendBroadcastNotification executed successfully';
    END TRY
    BEGIN CATCH
        PRINT 'FAIL: sp_SendBroadcastNotification - ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT 'SKIP: No sender available for broadcast test';
END

PRINT '';

-- =============================================
-- TEST 9: Leave status notification
-- =============================================
PRINT '--- TEST 9: Leave status change notification ---';

BEGIN TRY
    EXEC sp_NotifyLeaveStatusChange 
        @EmployeeId = @TestEmployeeId,
        @Status = 'Approved',
        @RequestId = 999,
        @ApproverId = @TestSenderId;
    PRINT 'PASS: sp_NotifyLeaveStatusChange executed successfully';
END TRY
BEGIN CATCH
    PRINT 'FAIL: sp_NotifyLeaveStatusChange - ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- =============================================
-- TEST 10: Contract expiry notification
-- =============================================
PRINT '--- TEST 10: Contract expiry notification ---';

BEGIN TRY
    EXEC sp_NotifyContractExpiry 
        @EmployeeId = @TestEmployeeId,
        @ExpiryDate = '2025-12-31';
    PRINT 'PASS: sp_NotifyContractExpiry executed successfully';
END TRY
BEGIN CATCH
    PRINT 'FAIL: sp_NotifyContractExpiry - ' + ERROR_MESSAGE();
END CATCH

EndTests:
PRINT '';
PRINT '=============================================';
PRINT 'TEST SCRIPT COMPLETED';
PRINT '=============================================';
PRINT '';
PRINT 'To clean up test notifications, run:';
PRINT 'DELETE FROM Notification WHERE notification_type IN (''Test'', ''Test Broadcast'');';
GO
