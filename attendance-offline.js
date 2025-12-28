// ============================================================================
// OFFLINE ATTENDANCE HANDLER
// ============================================================================
// Handles offline clock in/out when network is unavailable
// Uses localStorage to queue attendance records for later sync
// ============================================================================

const OfflineAttendance = {
    STORAGE_KEY: 'offlineAttendanceQueue',
    SYNC_ENDPOINT: '/Attendance/SyncOffline',

    // Check if online
    isOnline: function () {
        return navigator.onLine;
    },

    // Get queued records from localStorage
    getQueue: function () {
        const data = localStorage.getItem(this.STORAGE_KEY);
        return data ? JSON.parse(data) : [];
    },

    // Save queue to localStorage
    saveQueue: function (queue) {
        localStorage.setItem(this.STORAGE_KEY, JSON.stringify(queue));
        this.updateSyncIndicator();
    },

    // Add a record to the queue
    queueRecord: function (employeeId, clockTime, type) {
        const queue = this.getQueue();
        queue.push({
            employeeId: employeeId,
            clockTime: clockTime.toISOString(),
            type: type, // 'IN' or 'OUT'
            queuedAt: new Date().toISOString()
        });
        this.saveQueue(queue);
        console.log('[OfflineAttendance] Record queued:', type, 'at', clockTime);
        return true;
    },

    // Sync all queued records
    syncQueue: async function () {
        if (!this.isOnline()) {
            console.log('[OfflineAttendance] Still offline, cannot sync');
            return { success: false, reason: 'offline' };
        }

        const queue = this.getQueue();
        if (queue.length === 0) {
            console.log('[OfflineAttendance] No records to sync');
            return { success: true, synced: 0 };
        }

        console.log('[OfflineAttendance] Syncing', queue.length, 'records...');
        this.showSyncingStatus();

        let successCount = 0;
        let failedRecords = [];

        for (const record of queue) {
            try {
                const response = await fetch(this.SYNC_ENDPOINT, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'RequestVerificationToken': this.getAntiForgeryToken()
                    },
                    body: JSON.stringify(record)
                });

                if (response.ok) {
                    successCount++;
                } else {
                    failedRecords.push(record);
                }
            } catch (error) {
                console.error('[OfflineAttendance] Sync error:', error);
                failedRecords.push(record);
            }
        }

        // Keep only failed records in queue
        this.saveQueue(failedRecords);

        console.log('[OfflineAttendance] Synced', successCount, 'of', queue.length, 'records');
        this.showSyncResult(successCount, failedRecords.length);

        return { success: true, synced: successCount, failed: failedRecords.length };
    },

    // Get anti-forgery token from page
    getAntiForgeryToken: function () {
        const token = document.querySelector('input[name="__RequestVerificationToken"]');
        return token ? token.value : '';
    },

    // Update the sync indicator in UI
    updateSyncIndicator: function () {
        const indicator = document.getElementById('offlineSyncIndicator');
        const badge = document.getElementById('offlineQueueBadge');

        if (!indicator) return;

        const queue = this.getQueue();
        const isOnline = this.isOnline();

        if (queue.length > 0) {
            indicator.classList.remove('d-none');
            indicator.classList.toggle('bg-warning', !isOnline);
            indicator.classList.toggle('bg-info', isOnline);
            badge.textContent = queue.length;
            indicator.title = isOnline
                ? `${queue.length} records pending sync - Click to sync now`
                : `${queue.length} records queued - Will sync when online`;
        } else {
            indicator.classList.add('d-none');
        }
    },

    // Show syncing status
    showSyncingStatus: function () {
        const indicator = document.getElementById('offlineSyncIndicator');
        if (indicator) {
            indicator.classList.remove('bg-warning', 'bg-info');
            indicator.classList.add('bg-secondary');
            indicator.innerHTML = '<i class="bi bi-arrow-repeat spinning"></i> Syncing...';
        }
    },

    // Show sync result
    showSyncResult: function (successCount, failedCount) {
        const msg = failedCount > 0
            ? `Synced ${successCount} records. ${failedCount} failed.`
            : `Successfully synced ${successCount} records!`;

        // Show toast notification if available
        if (typeof showToast === 'function') {
            showToast(msg, failedCount > 0 ? 'warning' : 'success');
        } else {
            alert(msg);
        }

        this.updateSyncIndicator();
    },

    // Initialize event listeners
    init: function () {
        // Listen for online/offline events
        window.addEventListener('online', () => {
            console.log('[OfflineAttendance] Back online, attempting sync...');
            this.syncQueue();
        });

        window.addEventListener('offline', () => {
            console.log('[OfflineAttendance] Gone offline, records will be queued');
            this.updateSyncIndicator();
        });

        // Initial UI update
        this.updateSyncIndicator();

        // Auto-sync if online and has queued records
        if (this.isOnline() && this.getQueue().length > 0) {
            setTimeout(() => this.syncQueue(), 2000);
        }

        console.log('[OfflineAttendance] Initialized. Online:', this.isOnline());
    }
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function () {
    OfflineAttendance.init();
});

// Add CSS for spinning animation
const style = document.createElement('style');
style.textContent = `
    .spinning {
        animation: spin 1s linear infinite;
    }
    @keyframes spin {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
    }
`;
document.head.appendChild(style);
