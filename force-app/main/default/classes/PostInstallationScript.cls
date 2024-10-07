global class PostInstallationScript implements InstallHandler{
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
            // Log_Handler.store_Exception(e, 'PostInstallationScript', 'onInstall');
            System.debug('Exception in onInstall==>' + e.getMessage() + e.getLineNumber());
        }
    }
}