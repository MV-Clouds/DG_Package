global class PostInstallationScript implements InstallHandler, UninstallHandler{
    global void onInstall(InstallContext context) {
        List<PermissionSetAssignment> permissionSets = new List<PermissionSetAssignment>();
        try {
            List<PermissionSet> ps = new List<PermissionSet>();
            ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'DocGenius_Admin_Permissions' LIMIT 1];

            List<User> admins = new List<User>();
            admins = [SELECT Id, ProfileId FROM User WHERE Profile.Name = 'System Administrator'];

            if (admins.size() > 0 && ps.size() > 0) {
                for (User user : admins) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps[0].Id, AssigneeId = user.Id);
                    permissionSets.add(psa);
                }
                if (permissionSets.size() > 0) {
                    insert permissionSets;
                }
            }

        } catch (Exception e) {
            System.debug('Exception in onInstall==>' + e.getMessage() + e.getLineNumber());
        }
    }

    @deprecated
    global void onUninstall(UnInstallContext ctx) {
        System.debug('As Global Method can't be removed, commenting this process as no longer in use.');
        /*try {
            List<PermissionSetAssignment> psassignment = new List<PermissionSetAssignment>();
            psassignment = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name IN ('DocGenius_Standard_Permissions', 'DocGenius_Admin_Permissions', 'DocGenius_Basic_Permissions')];

            if (!psassignment.isEmpty()) {
                delete psassignment;
            }
        } catch (Exception e) {
            
        }*/
    }
}
