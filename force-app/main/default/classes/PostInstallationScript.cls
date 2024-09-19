global class PostInstallationScript implements InstallHandler{
    global void onInstall(InstallContext context) {
        try {
            
            List<String> objects = new List<String>();
            List<String> notAllowedObjects = new List<String>{'history', 'tag', 'share', 'feed', 'group', 'public', 'group','CollaborationGroup', 'LocationGroup', 'WorkType', 'WorkTypeGroup', 'WorkTypeGroupMember', 'public', ' badge', 'WorkBadge', 'WorkBadgeDefinition', 'GeolocationBasedAction', 'Idea', 'SchedulingWorkspace', 'SchedulingWorkspaceTerritory', 'Solution', 'WorkCapacityLimit', 'WorkCapacityUsage', 'WorkCapacityAvailability', 'ProductWarrantyTerm', 'ListEmail'};
            
            for ( Schema.SObjectType o : Schema.getGlobalDescribe().values() )
            {
                Schema.DescribeSObjectResult objResult = o.getDescribe();
                if(!notAllowedObjects.contains(objResult.getName()) && !objResult.isCustomSetting() && objResult.isCreateable() && objResult.getRecordTypeInfos().size() > 0 && objResult.isSearchable() && objResult.isQueryable() && objResult.isMruEnabled()){
                    objects.add(objResult.getName());
                }
            }
            Map<String,String> buttonData = new Map<String,String>();
            buttonData.put('buttonName', 'DG_Basic_Print');
            buttonData.put('buttonLabel', 'DG Basic Print');
            createListViewButtons(objects, buttonData);
        } catch (Exception e) {
            // Log_Handler.store_Exception(e, 'PostInstallationScript', 'onInstall');
            System.debug('Exception in onInstall==>' + e.getMessage());
        }
    }

    public static void createListViewButtons(List<String> objects,Map<String, String> buttonData){
        try {
            System.debug('buttonData :' + buttonData+ 'Objects ::' + objects);
            String buttonName = buttonData.get('buttonName');
            String buttonEndURL = buttonData.get('buttonEndURL');
            String buttonLabel = buttonData.get('buttonLabel');

            List<MetadataService.Metadata> webLinks = new List<MetadataService.Metadata>();
            for (String obj: objects) {
                String buttonURL = '/lightning/cmp/MVDG__generateDocument?c__objectApiName='+ obj +  buttonEndURL;
                String displayType = 'massActionButton';
                if(buttonName == 'DG_Basic_Print'){
                    buttonURL = '/apex/MVDG__Dynamicpage?id={!'+ obj+'.Id}';
                    displayType = 'button';
                }
                String buttonApiName = buttonName;
                MetadataService.WebLink webLink = new MetadataService.WebLink();
                webLink.fullName = obj+'.'+buttonApiName;
                webLink.availability = 'online';
                webLink.displayType = displayType;
                webLink.linkType = 'url';
                webLink.url = buttonURL;
                webLink.encodingKey = 'UTF-8';
                webLink.masterLabel = buttonLabel;
                webLink.openType = 'newWindow';
                webLink.position = 'none'; 
                webLink.width = 600;
                webLink.height = 600;  
                webLink.protected_x = false;
                if(displayType == 'massActionButton'){
                    webLink.RequireRowSelection = true;
                }
                webLinks.add(weblink);
            }
            Integer batchSize = 10;
            Integer totalSize = webLinks.size();
            List<MetadataService.Metadata> chunk = new List<MetadataService.Metadata>();
            
            for (Integer i = 0; i < totalSize; i++) {
                chunk.add(webLinks[i]);
                
                if (chunk.size() == batchSize || i == totalSize - 1) {
                    // Process the chunk
                    Boolean isSuccess = addButtons(chunk);
                    if(!isSuccess && !Test.isRunningTest()){
                        return;
                    }
                    // Clear the chunk list for the next batch
                    chunk.clear();
                }
            }
        } catch (Exception e) {
            // Log_Handler.store_Exception(e, 'PostInstallationScript', 'createListViewButtons');
            system.debug('exception in createListViewButtons : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
        }
    }

    public static Boolean addButtons(List<MetadataService.Metadata> webLinks){
        try {
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            if (!Test.isRunningTest()) {   
                service.SessionHeader = new MetadataService.SessionHeader_element();
                if (String.isBlank(Page.UserSessionIdPage.getContent().toString())) {
                    return false;
                }
                service.SessionHeader.sessionId = Page.UserSessionIdPage.getContent().toString();
            }
            list<MetadataService.UpsertResult> saveResultList = new list<MetadataService.UpsertResult>();
            saveResultList = service.upsertMetadata(webLinks);
            System.debug('Save Result List :::' + saveResultList);

            if(!saveResultList[0].created){
                system.debug('Error Creating Button.');
                return false;
            }
            return true;
        } catch (Exception e) {
            // Log_Handler.store_Exception(e, 'PostInstallationScript', 'addButtons');
            system.debug('exception in addButtons : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return false;
            
        }
    }
}