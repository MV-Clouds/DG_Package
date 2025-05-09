global class PostInstallationScript implements InstallHandler, UninstallHandler, Schedulable {

    global void onUninstall(UnInstallContext ctx) {
        System.debug(LoggingLevel.INTERNAL, 'As Global Method can\'t be removed, commenting this process as no longer in use.');
        /*try {
            List<PermissionSetAssignment> psassignment = new List<PermissionSetAssignment>();
            psassignment = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name IN ('DocGenius_Standard_Permissions', 'DocGenius_Admin_Permissions', 'DocGenius_Basic_Permissions')];

            if (!psassignment.isEmpty()) {
                delete psassignment;
            }
        } catch (Exception e) {
            
        }*/
    }

    global void onInstall(InstallContext context) {
        try {
            // Schedule this class to run 5 minutes from now
            String cronExp = getCronExpressionAfterMinutes(1);
            String timestamp = Datetime.now().format('yyyyMMdd_HHmmss');

            System.schedule('PostInstall_Permission_Assignment_'+timestamp, cronExp, new PostInstallationScript());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '⚠️ Scheduling failed: ' + e.getMessage());
        }
    }

    global void execute(SchedulableContext sc) {
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();

        try {
            // Get the permission set
            PermissionSet ps = [
                SELECT Id FROM PermissionSet 
                WHERE Name = 'DocGenius_Admin_Permissions' 
                LIMIT 1
            ];

            // Get all System Administrators
            List<User> admins = [
                SELECT Id FROM User 
                WHERE Profile.Name = 'System Administrator'
            ];

            // Create permission assignments only if not already assigned
            for (User admin : admins) {
                Boolean alreadyAssigned = [
                    SELECT COUNT() FROM PermissionSetAssignment 
                    WHERE AssigneeId = :admin.Id AND PermissionSetId = :ps.Id
                ] > 0;

                if (!alreadyAssigned) {
                    psaList.add(new PermissionSetAssignment(
                        AssigneeId = admin.Id,
                        PermissionSetId = ps.Id
                    ));
                }
            }

            if (!psaList.isEmpty()) {
                insert psaList;
            }

        } catch (Exception e) {
            System.debug( LoggingLevel.ERROR,'⚠️ Error in Scheduled Job: ' + e.getMessage());
        }
    }

    // Helper method to get a CRON string for N minutes from now
    private String getCronExpressionAfterMinutes(Integer minutesAhead) {
        Datetime dt = Datetime.now().addMinutes(minutesAhead);
        return String.format('0 {0} {1} {2} {3} ? {4}', new String[] {
            String.valueOf(dt.minute()),
            String.valueOf(dt.hour()),
            String.valueOf(dt.day()),
            String.valueOf(dt.month()),
            String.valueOf(dt.year())
        });
    }
}