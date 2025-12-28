-- =============================================
-- VERIFICATION TEST SCRIPT
-- =============================================
USE HRFINAL;
GO

PRINT '--- VERIFICATION STARTING ---';

-- SETUP: Ensure we have 2 distinct active employees
DECLARE @UserA INT, @UserB INT;
SELECT TOP 1 @UserA = employee_id FROM Employee WHERE is_active = 1 ORDER BY employee_id ASC;
SELECT TOP 1 @UserB = employee_id FROM Employee WHERE is_active = 1 AND employee_id > @UserA ORDER BY employee_id ASC;

IF @UserA IS NULL OR @UserB IS NULL
BEGIN
    PRINT 'ERROR: Need at least 2 active employees for this test.';
    RETURN;
END

PRINT CONCAT('User A: ', @UserA, ', User B: ', @UserB);

-- TEST 1: Broadcast Read Status Independence
PRINT '--- TEST 1: Broadcast Read Status Independence ---';

DECLARE @NotifId INT;
DECLARE @Sender INT = @UserA; -- User A sends to everyone (including B)

-- 1. Create Broadcast
EXEC sp_SendBroadcastNotification 
    @SenderId = @Sender, 
    @MessageContent = 'VERIFY: Broadcast Read Status', 
    @Urgency = 'Normal';

-- Get the ID of the broadcast we just sent
SELECT TOP 1 @NotifId = notification_id FROM Notification WHERE message_content = 'VERIFY: Broadcast Read Status' ORDER BY notification_id DESC;
PRINT CONCAT('Broadcast Notification ID: ', @NotifId);

-- 2. Verify User B sees it as Unread
DECLARE @UnreadCountB_Before INT;
EXEC @UnreadCountB_Before = sp_GetUnreadNotificationCount @EmployeeId = @UserB;
-- Note: Procedure returns count, but we also can select it directly to be sure
SELECT @UnreadCountB_Before = COUNT(*) FROM Employee_Notification WHERE employee_id = @UserB AND notification_id = @NotifId AND read_at IS NULL;

IF @UnreadCountB_Before = 1
    PRINT 'PASS: User B sees notification as Unread initially.';
ELSE
    PRINT 'FAIL: User B should see notification as Unread.';

-- 3. User A reads the notification (if they received it - wait, sender doesn't receive broadcast usually)
-- Let's pick a User C or just assume User A *didn't* get it, but someone else did. 
-- Actually, let's manually insert a record for User A to simulate they are also a recipient for testing purposes,
-- OR just verify that if User B reads it, it stays unread for User C.
-- Let's stick to User B reads it, and we check User C (if exists) OR reset and check again.

-- Better approach:
-- Update User B to read it.
EXEC sp_MarkNotificationAsRead @NotificationId = @NotifId, @EmployeeId = @UserB;
PRINT 'User B marked as read.';

-- 4. Verify User B sees it as Read
DECLARE @IsReadB INT;
SELECT @IsReadB = COUNT(*) FROM Employee_Notification WHERE employee_id = @UserB AND notification_id = @NotifId AND read_at IS NOT NULL;
IF @IsReadB = 1
    PRINT 'PASS: User B sees notification as Read.';
ELSE
    PRINT 'FAIL: User B failed to mark as read.';

-- 5. Verify Notification table read_status is NOT 'Read' (It should be irrelevant, but let's check deep logic)
-- Actually, the key is: Does another user see it as unread?
-- Let's find another user C
DECLARE @UserC INT;
SELECT TOP 1 @UserC = employee_id FROM Employee WHERE is_active = 1 AND employee_id NOT IN (@UserA, @UserB);

IF @UserC IS NOT NULL
BEGIN
    DECLARE @UnreadCountC INT;
    SELECT @UnreadCountC = COUNT(*) FROM Employee_Notification WHERE employee_id = @UserC AND notification_id = @NotifId AND read_at IS NULL;
    
    IF @UnreadCountC = 1
        PRINT 'PASS: User C still sees notification as Unread (Shared status fixed).';
    ELSE
        PRINT 'FAIL: User C sees notification as Read! Shared status bug exists.';
END
ELSE
    PRINT 'WARNING: User C not found, skipping independence check.';


-- TEST 2: Input Validation
PRINT '--- TEST 2: Input Validation ---';

BEGIN TRY
    EXEC sp_SendNotificationToEmployees 
        @SenderId = @UserA, 
        @EmployeeIds = '99999,ABC, ,,100', -- invalid inputs
        @MessageContent = 'Bad Input Test', 
        @Urgency = 'Normal';
    
    PRINT 'PASS: sp_SendNotificationToEmployees handled invalid input without crashing.';
END TRY
BEGIN CATCH
    PRINT CONCAT('FAIL: Procedure crashed with error: ', ERROR_MESSAGE());
END CATCH

PRINT '--- VERIFICATION COMPLETE ---';
GO
