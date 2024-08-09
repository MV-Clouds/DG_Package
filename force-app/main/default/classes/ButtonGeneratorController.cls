public with sharing class ButtonGeneratorController {

    @AuraEnabled
    public static CombinedDataWrapper getCombinedData(){
        CombinedDataWrapper combinedData = new CombinedDataWrapper();
        try {
            combinedData.allObjects = getAllObjects();
            combinedData.listViewButtonObj = getListViewButtonObj();
            combinedData.quickActionButtonObj = getQuickActionButtonObj(combinedData.allObjects);
            combinedData.basicPrintButtonObj = getBasicPrintButtonObj();
            combinedData.isSuccess = combinedData.listViewButtonObj != null && combinedData.quickActionButtonObj != null && combinedData.basicPrintButtonObj != null ? true : false;
        } catch (Exception e) {
            combinedData.isSuccess = false;
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'getCombinedData');
            system.debug('exception in getCombinedData : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
        }
        return combinedData;
    }
/*
*********************************************************
@description     : Method is used to fetch all the objects that already have the List View button
@param           : none
@return          : {List<String>} - list of object labels
********************************************************
*/
    @AuraEnabled
    public static List<String> getListViewButtonObj(){
        try {
            List<String> objects = new List<String>();
            List<WebLink> webLinks = [SELECT PageOrSobjectType FROM WebLink WHERE Name='DG_Generate_CSV' WITH SECURITY_ENFORCED];
            for (WebLink wl : webLinks) {
                objects.add(wl.PageOrSobjectType);
            }
            return objects;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'getListViewButtonObj');
            system.debug('exception in getListViewButtonObj : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

/*
*********************************************************
@description     : Method is used to fetch all the objects that already have the Basic Print Button
@param           : none
@return          : {List<String>} - list of object labels
********************************************************
*/
    @AuraEnabled
    public static List<String> getBasicPrintButtonObj(){
        try {
            List<String> objects = new List<String>();
            List<WebLink> webLinks = [SELECT PageOrSobjectType FROM WebLink WHERE Name='DG_Basic_Print' WITH SECURITY_ENFORCED];
            for (WebLink wl : webLinks) {
                objects.add(wl.PageOrSobjectType);
            }
            return objects;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'getBasicPrintButtonObj');
            system.debug('exception in getBasicPrintButtonObj : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

/*
*********************************************************
@description     : Method is used to fetch all the objects that already have the Quick Action button
@param           : none
@return          : {List<String>} - list of object labels
********************************************************
*/
@AuraEnabled
public static List<String> getQuickActionButtonObj(List<Map<String,String>> allObjects){
    try {
        List<String> objects = new List<String>();
        if(allObjects.size() > 0){
            for (Map<String,String> ow : allObjects) {
                // List<String> actionButtonsList = new List<String>();
                // actionButtonsList.add(ow.get('value')+ '.DG_Generate_Document');
                // if(QuickAction.DescribeQuickActions(actionButtonsList).size() > 0) {
                //     objects.add(ow.get('value'));
                // }
                List<QuickAction.DescribeAvailableQuickActionResult> result1 = QuickAction.DescribeAvailableQuickActions(ow.get('value'));  
                for(QuickAction.DescribeAvailableQuickActionResult action : result1){
                    if(action.getType() == 'LightningWebComponent' && action.getName().contains('.DG_Generate_Document')){
                        objects.add(ow.get('value'));
                    }
                }
            }
        }
        return objects;
    } catch (Exception e) {
        Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'getQuickActionButtonObj');
        system.debug('exception in getQuickActionButtonObj : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
        return null;
    }
}

/*
*********************************************************
@description     : Method is used to fetch all the objects from the org
@param           : none
@return          : {List<ObjectsWrapper>} - list of all the objects
********************************************************
*/
    @AuraEnabled
    public static List<Map<String, String>> getAllObjects(){
        try {
            List<Map<String, String>> listOfObjects = new List<Map<String, String>>();
            for ( Schema.SObjectType o : Schema.getGlobalDescribe().values() )
            {
                List<String> notAllowedObjects = new List<String>{'history', 'tag', 'share', 'feed', 'group', 'public', 'group','CollaborationGroup', 'LocationGroup', 'WorkType', 'WorkTypeGroup', 'WorkTypeGroupMember', 'public', ' badge', 'WorkBadge', 'WorkBadgeDefinition', 'GeolocationBasedAction', 'Idea', 'SchedulingWorkspace', 'SchedulingWorkspaceTerritory', 'Solution', 'WorkCapacityLimit', 'WorkCapacityUsage', 'WorkCapacityAvailability', 'ProductWarrantyTerm', 'ListEmail'};
                Schema.DescribeSObjectResult objResult = o.getDescribe();
                if(!notAllowedObjects.contains(objResult.getName()) &&
                !objResult.isCustomSetting() && objResult.isCreateable() &&
                objResult.getRecordTypeInfos().size() > 0 && objResult.isSearchable() && 
                objResult.isQueryable() && objResult.isMruEnabled()
                ){
                    Map<String, String> ow = new Map<String, String>();
                    ow.put('label', objResult.getLabel());
                    ow.put('value', objResult.getName());
                    listOfObjects.add(ow);
                }
            }
            return listOfObjects;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'getAllObjects');
            system.debug('exception in getAllObjects : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            // throw new AuraHandledException(e.getMessage());
            return null;
        }
    }

/*
*********************************************************
@description     : Method is used to create a list view button 
@param           : buttonData - {Map<String, Object>} - button data
@return          : none
********************************************************
*/
    @AuraEnabled
    public static void createListViewButtons(List<String> objects,Map<String, String> buttonData){
        try {
            System.debug('buttonData :' + buttonData+ 'Objects ::' + objects);
            String buttonName = buttonData.get('buttonName');
            String buttonEndURL = buttonData.get('buttonEndURL');
            String buttonLabel = buttonData.get('buttonLabel');

            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            if (!Test.isRunningTest()) {   
                service.SessionHeader = new MetadataService.SessionHeader_element();
                service.SessionHeader.sessionId = Page.UserSessionIdPage.getContent().toString();
            }
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
                        throw new AuraHandledException('Error Creating Button.');
                    }
                    // Clear the chunk list for the next batch
                    chunk.clear();
                }
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'createListViewButtons');
            system.debug('exception in createListViewButtons : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            throw new AuraHandledException('Error Creating Button.');
        }
    }
    
/*
*********************************************************
@description     : Method is used as a helper method for addding buttons in chunk of 10 at once
@param           : webLinks - {List<MetadataService.Metadata>}
@return          : none
********************************************************
*/
    public static Boolean addButtons(List<MetadataService.Metadata> webLinks){
        try {
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            if (!Test.isRunningTest()) {   
                service.SessionHeader = new MetadataService.SessionHeader_element();
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
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'addButtons');
            system.debug('exception in addButtons : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return false;
        }
    }


// -------------------------------------------------------------- Wrapper Classes ------------------------------------------------------------ //

/*
*********************************************************
@description     : wrapper containing data of all already create button objects
@param           : allObjects {List<Map<String, String>>} - list of map of label and value of the objects
@param           : listViewButtonObj {List<String>} - list of object that have a list view button
@param           : quickActionButtonObj {List<String>} - list of object that have a quick action button
@param           : basicPrintButtonObj {List<String>} - list of objects that have a basic print button
********************************************************
*/
    public class CombinedDataWrapper{
        @AuraEnabled public List<Map<String, String>> allObjects;
        @AuraEnabled public List<String> listViewButtonObj;
        @AuraEnabled public List<String> quickActionButtonObj;
        @AuraEnabled public List<String> basicPrintButtonObj;
        @AuraEnabled public Boolean isSuccess;
    }
}