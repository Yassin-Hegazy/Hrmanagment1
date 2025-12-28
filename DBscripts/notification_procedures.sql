-- =============================================
-- NOTIFICATION MODULE STORED PROCEDURES
-- =============================================
-- This file contains all notification-related stored procedures
-- Run this after tables.sql to add notification functionality
-- =============================================

USE HRFINAL;
GO

-- =============================================
-- PROCEDURE: sp_GetEmployeeNotifications
-- Purpose: Get all notifications for a specific employee
-- =============================================
IF OBJECT_ID('sp_GetEmployeeNotifications', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetEmployeeNotifications;
GO

CREATE PROCEDURE sp_GetEmployeeNotifications
    @EmployeeId INT
AS
BEGIN
    -- Validate employee exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeId)
    BEGIN
        RAISERROR('Employee with ID %d does not exist.', 16, 1, @EmployeeId);
        RETURN;
    END

    -- Get all notifications for this employee, ordered by newest first
    SELECT 
        n.notification_id,
        n.message_content,
        n.timestamp,
        n.urgency,
        CASE 
            WHEN en.read_at IS NOT NULL THEN 'Read' 
            ELSE 'Unread' 
        END AS read_status,
        n.notification_type,
        n.sender_id,
        CONCAT(sender.first_name, ' ', sender.last_name) AS sender_name,
        en.delivery_status,
        en.delivered_at,
        en.read_at
    FROM Notification n
    INNER JOIN Employee_Notification en 
        ON n.notification_id = en.notification_id
    LEFT JOIN Employee sender 
        ON n.sender_id = sender.employee_id
    WHERE en.employee_id = @EmployeeId
    ORDER BY n.timestamp DESC;

    PRINT CONCAT('Retrieved notifications for employee #', @EmployeeId);
END
GO

-- =============================================
-- PROCEDURE: sp_GetUnreadNotificationCount
-- Purpose: Get count of unread notifications for navbar badge
-- =============================================
IF OBJECT_ID('sp_GetUnreadNotificationCount', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetUnreadNotificationCount;
GO

CREATE PROCEDURE sp_GetUnreadNotificationCount
    @EmployeeId INT
AS
BEGIN
    SELECT COUNT(*) AS UnreadCount
    FROM Notification n
    INNER JOIN Employee_Notification en 
        ON n.notification_id = en.notification_id
    WHERE en.employee_id = @EmployeeId 
      AND en.read_at IS NULL;
END
GO

-- =============================================
-- PROCEDURE: sp_MarkNotificationAsRead
-- Purpose: Mark a single notification as read for an employee
-- =============================================
IF OBJECT_ID('sp_MarkNotificationAsRead', 'P') IS NOT NULL
    DROP PROCEDURE sp_MarkNotificationAsRead;
GO

CREATE PROCEDURE sp_MarkNotificationAsRead
    @NotificationId INT,
    @EmployeeId INT
AS
BEGIN
    -- Validate the notification belongs to this employee
    IF NOT EXISTS (
        SELECT 1 FROM Employee_Notification 
        WHERE notification_id = @NotificationId 
          AND employee_id = @EmployeeId
    )
    BEGIN
        RAISERROR('Notification #%d not found for employee #%d.', 16, 1, @NotificationId, @EmployeeId);
        RETURN;
    END

    -- Update read_at timestamp
    UPDATE Employee_Notification 
    SET read_at = GETDATE()
    WHERE notification_id = @NotificationId 
      AND employee_id = @EmployeeId
      AND read_at IS NULL;

    -- Update read_at timestamp
    UPDATE Employee_Notification 
    SET read_at = GETDATE()
    WHERE notification_id = @NotificationId 
      AND employee_id = @EmployeeId
      AND read_at IS NULL;

    PRINT CONCAT('Notification #', @NotificationId, ' marked as read for employee #', @EmployeeId);
END
GO

-- =============================================
-- PROCEDURE: sp_MarkAllNotificationsAsRead
-- Purpose: Mark all notifications as read for an employee
-- =============================================
IF OBJECT_ID('sp_MarkAllNotificationsAsRead', 'P') IS NOT NULL
    DROP PROCEDURE sp_MarkAllNotificationsAsRead;
GO

CREATE PROCEDURE sp_MarkAllNotificationsAsRead
    @EmployeeId INT
AS
BEGIN
    DECLARE @UpdatedCount INT;

    -- Update read_at timestamp for all that don't have one
    UPDATE Employee_Notification 
    SET read_at = GETDATE()
    WHERE employee_id = @EmployeeId
      AND read_at IS NULL;
    
    SET @UpdatedCount = @@ROWCOUNT;

    PRINT CONCAT('Marked ', @UpdatedCount, ' notifications as read for employee #', @EmployeeId);
END
GO

-- =============================================
-- PROCEDURE: sp_CreateNotificationForEmployee
-- Purpose: Create a notification and assign it to an employee
-- =============================================
IF OBJECT_ID('sp_CreateNotificationForEmployee', 'P') IS NOT NULL
    DROP PROCEDURE sp_CreateNotificationForEmployee;
GO

CREATE PROCEDURE sp_CreateNotificationForEmployee
    @EmployeeId INT,
    @MessageContent VARCHAR(1000),
    @NotificationType VARCHAR(50),
    @Urgency VARCHAR(50),
    @SenderId INT = NULL
AS
BEGIN
    DECLARE @NotificationId INT;

    -- Validate target employee exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeId)
    BEGIN
        RAISERROR('Target employee with ID %d does not exist.', 16, 1, @EmployeeId);
        RETURN;
    END

    -- Validate sender exists if provided
    IF @SenderId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @SenderId)
    BEGIN
        RAISERROR('Sender employee with ID %d does not exist.', 16, 1, @SenderId);
        RETURN;
    END

    -- Insert the notification
    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type, sender_id)
    VALUES (@MessageContent, GETDATE(), @Urgency, 'Unread', @NotificationType, @SenderId);

    SET @NotificationId = SCOPE_IDENTITY();

    -- Link notification to employee
    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    VALUES (@EmployeeId, @NotificationId, 'Delivered', GETDATE());

    -- Return the new notification ID
    SELECT @NotificationId AS NewNotificationId;

    PRINT CONCAT('Created notification #', @NotificationId, ' for employee #', @EmployeeId);
END
GO

-- =============================================
-- PROCEDURE: sp_SendTeamNotification (Updated)
-- Purpose: Send notification to all employees under a manager
-- Note: This updates the existing SendTeamNotification procedure
-- =============================================
IF OBJECT_ID('sp_SendTeamNotification', 'P') IS NOT NULL
    DROP PROCEDURE sp_SendTeamNotification;
GO

CREATE PROCEDURE sp_SendTeamNotification
    @ManagerId INT,
    @MessageContent VARCHAR(1000),
    @Urgency VARCHAR(50)
AS
BEGIN
    DECLARE @NotificationId INT;
    DECLARE @TeamCount INT;

    -- Validate manager exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @ManagerId)
    BEGIN
        RAISERROR('Manager with ID %d does not exist.', 16, 1, @ManagerId);
        RETURN;
    END

    -- Check if manager has team members
    SELECT @TeamCount = COUNT(*) 
    FROM Employee 
    WHERE manager_id = @ManagerId AND is_active = 1;

    IF @TeamCount = 0
    BEGIN
        RAISERROR('Manager #%d has no active team members.', 16, 1, @ManagerId);
        RETURN;
    END

    -- Create the notification with sender tracking
    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type, sender_id)
    VALUES (@MessageContent, GETDATE(), @Urgency, 'Unread', 'Team Message', @ManagerId);

    SET @NotificationId = SCOPE_IDENTITY();

    -- Send to all team members
    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT 
        employee_id,
        @NotificationId,
        'Delivered',
        GETDATE()
    FROM Employee
    WHERE manager_id = @ManagerId AND is_active = 1;

    PRINT CONCAT('Notification #', @NotificationId, ' sent to ', @TeamCount, ' team members of manager #', @ManagerId);
END
GO

-- =============================================
-- PROCEDURE: sp_SendBroadcastNotification
-- Purpose: Send notification to ALL active employees EXCEPT sender
-- =============================================
IF OBJECT_ID('sp_SendBroadcastNotification', 'P') IS NOT NULL
    DROP PROCEDURE sp_SendBroadcastNotification;
GO

CREATE PROCEDURE sp_SendBroadcastNotification
    @SenderId INT,
    @MessageContent VARCHAR(1000),
    @Urgency VARCHAR(50),
    @NotificationType VARCHAR(50) = 'Announcement'
AS
BEGIN
    DECLARE @NotificationId INT;
    DECLARE @RecipientCount INT;

    -- Validate sender exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @SenderId)
    BEGIN
        RAISERROR('Sender with ID %d does not exist.', 16, 1, @SenderId);
        RETURN;
    END

    -- Create the notification
    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type, sender_id)
    VALUES (@MessageContent, GETDATE(), @Urgency, 'Unread', @NotificationType, @SenderId);

    SET @NotificationId = SCOPE_IDENTITY();

    -- Send to ALL active employees EXCEPT the sender
    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT 
        employee_id,
        @NotificationId,
        'Delivered',
        GETDATE()
    FROM Employee
    WHERE is_active = 1 
      AND employee_id <> @SenderId;  -- EXCLUDE the sender

    SET @RecipientCount = @@ROWCOUNT;

    -- Return result
    SELECT @NotificationId AS NotificationId, @RecipientCount AS RecipientCount;

    PRINT CONCAT('Broadcast notification #', @NotificationId, ' sent to ', @RecipientCount, ' employees (excluding sender).');
END
GO

-- =============================================
-- PROCEDURE: sp_GetTeamMembers
-- Purpose: Get team members for dropdown selection
-- Logic: If @IsAdmin=1, return ALL active employees (except self)
--        If @IsAdmin=0, return only direct reports (manager_id = @EmployeeId)
-- =============================================
IF OBJECT_ID('sp_GetTeamMembers', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetTeamMembers;
GO

CREATE PROCEDURE sp_GetTeamMembers
    @EmployeeId INT,
    @IsAdmin BIT = 0
AS
BEGIN
    IF @IsAdmin = 1
    BEGIN
        -- Admin: Return ALL active employees except self
        SELECT 
            e.employee_id,
            CONCAT(e.first_name, ' ', e.last_name) AS full_name,
            e.email,
            d.department_name,
            p.position_title
        FROM Employee e
        LEFT JOIN Department d ON e.department_id = d.department_id
        LEFT JOIN Position p ON e.position_id = p.position_id
        WHERE e.is_active = 1 
          AND e.employee_id <> @EmployeeId  -- Exclude self
        ORDER BY e.first_name, e.last_name;
    END
    ELSE
    BEGIN
        -- Manager: Return only direct reports
        SELECT 
            e.employee_id,
            CONCAT(e.first_name, ' ', e.last_name) AS full_name,
            e.email,
            d.department_name,
            p.position_title
        FROM Employee e
        LEFT JOIN Department d ON e.department_id = d.department_id
        LEFT JOIN Position p ON e.position_id = p.position_id
        WHERE e.manager_id = @EmployeeId 
          AND e.is_active = 1
        ORDER BY e.first_name, e.last_name;
    END
END
GO

-- =============================================
-- PROCEDURE: sp_SendNotificationToEmployees
-- Purpose: Send notification to specific selected employees
-- =============================================
IF OBJECT_ID('sp_SendNotificationToEmployees', 'P') IS NOT NULL
    DROP PROCEDURE sp_SendNotificationToEmployees;
GO

CREATE PROCEDURE sp_SendNotificationToEmployees
    @SenderId INT,
    @EmployeeIds VARCHAR(MAX),  -- Comma-separated list of employee IDs
    @MessageContent VARCHAR(1000),
    @Urgency VARCHAR(50),
    @NotificationType VARCHAR(50) = 'Team Message'
AS
BEGIN
    DECLARE @NotificationId INT;
    DECLARE @RecipientCount INT;

    -- Validate sender exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @SenderId)
    BEGIN
        RAISERROR('Sender with ID %d does not exist.', 16, 1, @SenderId);
        RETURN;
    END

    -- Create the notification
    INSERT INTO Notification (message_content, timestamp, urgency, read_status, notification_type, sender_id)
    VALUES (@MessageContent, GETDATE(), @Urgency, 'Unread', @NotificationType, @SenderId);

    SET @NotificationId = SCOPE_IDENTITY();

    -- Send to selected employees (parse comma-separated IDs)
    INSERT INTO Employee_Notification (employee_id, notification_id, delivery_status, delivered_at)
    SELECT 
        TRY_CAST(value AS INT),
        @NotificationId,
        'Delivered',
        GETDATE()
    FROM STRING_SPLIT(@EmployeeIds, ',')
    WHERE LTRIM(RTRIM(value)) <> ''
      AND TRY_CAST(value AS INT) IS NOT NULL
      AND EXISTS (SELECT 1 FROM Employee WHERE employee_id = TRY_CAST(value AS INT) AND is_active = 1);

    SET @RecipientCount = @@ROWCOUNT;

    IF @RecipientCount = 0
    BEGIN
        -- Rollback by deleting the orphan notification
        DELETE FROM Notification WHERE notification_id = @NotificationId;
        RAISERROR('No valid recipients selected.', 16, 1);
        RETURN;
    END

    -- Return result
    SELECT @NotificationId AS NotificationId, @RecipientCount AS RecipientCount;

    PRINT CONCAT('Notification #', @NotificationId, ' sent to ', @RecipientCount, ' selected employees.');
END
GO


-- =============================================
-- PROCEDURE: sp_NotifyLeaveStatusChange
-- Purpose: Create notification for leave request status change
-- =============================================
IF OBJECT_ID('sp_NotifyLeaveStatusChange', 'P') IS NOT NULL
    DROP PROCEDURE sp_NotifyLeaveStatusChange;
GO

CREATE PROCEDURE sp_NotifyLeaveStatusChange
    @EmployeeId INT,
    @Status VARCHAR(50),
    @RequestId INT,
    @ApproverId INT = NULL
AS
BEGIN
    DECLARE @Message VARCHAR(1000);
    DECLARE @NotificationType VARCHAR(50);
    DECLARE @Urgency VARCHAR(50);

    -- Build message based on status
    SET @Message = CASE 
        WHEN @Status = 'Approved' THEN CONCAT('Your leave request #', @RequestId, ' has been approved.')
        WHEN @Status = 'Rejected' THEN CONCAT('Your leave request #', @RequestId, ' has been rejected.')
        ELSE CONCAT('Your leave request #', @RequestId, ' status changed to: ', @Status)
    END;

    SET @NotificationType = CASE 
        WHEN @Status = 'Approved' THEN 'Leave Approval'
        ELSE 'Leave Rejected'
    END;

    SET @Urgency = CASE 
        WHEN @Status = 'Approved' THEN 'Normal'
        ELSE 'Medium'
    END;

    -- Create the notification
    EXEC sp_CreateNotificationForEmployee 
        @EmployeeId = @EmployeeId,
        @MessageContent = @Message,
        @NotificationType = @NotificationType,
        @Urgency = @Urgency,
        @SenderId = @ApproverId;
END
GO

-- =============================================
-- PROCEDURE: sp_NotifyContractExpiry
-- Purpose: Create notification for contract expiry warning
-- =============================================
IF OBJECT_ID('sp_NotifyContractExpiry', 'P') IS NOT NULL
    DROP PROCEDURE sp_NotifyContractExpiry;
GO

CREATE PROCEDURE sp_NotifyContractExpiry
    @EmployeeId INT,
    @ExpiryDate DATE
AS
BEGIN
    DECLARE @Message VARCHAR(1000);
    DECLARE @Urgency VARCHAR(50);
    DECLARE @DaysUntil INT;

    SET @DaysUntil = DATEDIFF(DAY, GETDATE(), @ExpiryDate);

    SET @Message = CASE 
        WHEN @DaysUntil <= 0 THEN 'Your contract has expired. Please contact HR.'
        ELSE CONCAT('Your contract expires in ', @DaysUntil, ' days on ', FORMAT(@ExpiryDate, 'MMMM dd, yyyy'), '.')
    END;

    SET @Urgency = CASE 
        WHEN @DaysUntil <= 7 THEN 'High'
        WHEN @DaysUntil <= 30 THEN 'Medium'
        ELSE 'Low'
    END;

    EXEC sp_CreateNotificationForEmployee 
        @EmployeeId = @EmployeeId,
        @MessageContent = @Message,
        @NotificationType = 'Contract Expiry',
        @Urgency = @Urgency,
        @SenderId = NULL;
END
GO

-- =============================================
-- PROCEDURE: sp_NotifyShiftChange
-- Purpose: Create notification for shift schedule change
-- =============================================
IF OBJECT_ID('sp_NotifyShiftChange', 'P') IS NOT NULL
    DROP PROCEDURE sp_NotifyShiftChange;
GO

CREATE PROCEDURE sp_NotifyShiftChange
    @EmployeeId INT,
    @ShiftDetails VARCHAR(500),
    @ChangedById INT = NULL
AS
BEGIN
    DECLARE @Message VARCHAR(1000);

    SET @Message = CONCAT('Your shift has been updated: ', @ShiftDetails);

    EXEC sp_CreateNotificationForEmployee 
        @EmployeeId = @EmployeeId,
        @MessageContent = @Message,
        @NotificationType = 'Shift Change',
        @Urgency = 'Medium',
        @SenderId = @ChangedById;
END
GO

-- =============================================
-- PROCEDURE: sp_NotifyMissionUpdate
-- Purpose: Create notification for mission status update
-- =============================================
IF OBJECT_ID('sp_NotifyMissionUpdate', 'P') IS NOT NULL
    DROP PROCEDURE sp_NotifyMissionUpdate;
GO

CREATE PROCEDURE sp_NotifyMissionUpdate
    @EmployeeId INT,
    @Destination VARCHAR(100),
    @Status VARCHAR(50),
    @ApproverId INT = NULL
AS
BEGIN
    DECLARE @Message VARCHAR(1000);

    SET @Message = CONCAT('Your mission to ', @Destination, ' has been ', LOWER(@Status), '.');

    EXEC sp_CreateNotificationForEmployee 
        @EmployeeId = @EmployeeId,
        @MessageContent = @Message,
        @NotificationType = 'Mission Update',
        @Urgency = 'Normal',
        @SenderId = @ApproverId;
END
GO

-- =============================================
-- PROCEDURE: sp_GetSentNotificationHistory
-- Purpose: Get all notifications sent by a user (for History view)
-- =============================================
IF OBJECT_ID('sp_GetSentNotificationHistory', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetSentNotificationHistory;
GO

CREATE PROCEDURE sp_GetSentNotificationHistory
    @SenderId INT
AS
BEGIN
    -- Validate sender exists
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @SenderId)
    BEGIN
        RAISERROR('Employee with ID %d does not exist.', 16, 1, @SenderId);
        RETURN;
    END

    -- Get all notifications sent by this user with recipient count
    SELECT 
        n.notification_id,
        n.message_content,
        n.timestamp AS sent_at,
        n.urgency,
        n.notification_type,
        (SELECT COUNT(*) FROM Employee_Notification en WHERE en.notification_id = n.notification_id) AS recipient_count,
        (SELECT COUNT(*) FROM Employee_Notification en WHERE en.notification_id = n.notification_id AND en.read_at IS NOT NULL) AS read_count
    FROM Notification n
    WHERE n.sender_id = @SenderId
    ORDER BY n.timestamp DESC;

    PRINT CONCAT('Retrieved sent notification history for employee #', @SenderId);
END
GO

PRINT '=============================================';
PRINT 'All Notification Stored Procedures Created!';
PRINT '=============================================';
GO
