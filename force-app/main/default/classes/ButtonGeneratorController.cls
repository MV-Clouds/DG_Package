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
public static List<String> getQuickActionButtonObj(List<ObjectsWrapper> allObjects){
    try {
        List<String> objects = new List<String>();
        if(allObjects.size() > 0){
            for (ObjectsWrapper ow : allObjects) {
                List<String> actionButtonsList = new List<String>();
                actionButtonsList.add(ow.value+ '.DG_Generate_Document');
                if(QuickAction.DescribeQuickActions(actionButtonsList).size() > 0) {
                    objects.add(ow.value);
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
    public static List<ObjectsWrapper> getAllObjects(){
        List<ObjectsWrapper> listOfOW = new List<ObjectsWrapper>();
        try {
            List<EntityDefinition> objects = [SELECT Label, QualifiedApiName FROM EntityDefinition WHERE IsCustomizable = true WITH SECURITY_ENFORCED];
            for (EntityDefinition obj : objects) {
                ObjectsWrapper ow = new ObjectsWrapper();
                ow.label = obj.Label;
                ow.value = obj.QualifiedApiName;
                listOfOW.add(ow);
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'getAllObjects');
            system.debug('exception in getAllObjects : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            // throw new AuraHandledException(e.getMessage());
        }
        return listOfOW;
    }

/*
*********************************************************
@description     : Method is used to create a list view button 
@param           : bdw - {ButtonDataWrapper} - button data
@return          : none
********************************************************
*/
    @AuraEnabled
    public static Boolean createListViewButtons(ButtonDataWrapper bdw){
        try {
            System.debug('BDW Wrapper :' + bdw);
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            if (!Test.isRunningTest()) {   
                service.SessionHeader = new MetadataService.SessionHeader_element();
                service.SessionHeader.sessionId = Page.UserSessionIdPage.getContent().toString();
            }
            List<MetadataService.Metadata> webLinks = new List<MetadataService.Metadata>();
            for (String obj: bdw.objects) {
                System.debug('BDW Wrapper :' + bdw);
                String buttonURL = '/lightning/cmp/MVDG__generateDocument?MVDG__objectApiName='+ obj + bdw.buttonEndURL;
                String displayType = 'massActionButton';
                if(bdw.buttonName == 'DG_Basic_Print'){
                    buttonURL = '/apex/MVDG__Dynamicpage?id={!'+ obj+'.Id}';
                    displayType = 'button';
                }
                String buttonApiName = bdw.buttonName;
                MetadataService.WebLink webLink = new MetadataService.WebLink();
                webLink.fullName = obj+'.'+buttonApiName;
                webLink.availability = 'online';
                webLink.displayType = displayType;
                webLink.linkType = 'url';
                webLink.url = buttonURL;
                webLink.encodingKey = 'UTF-8';
                webLink.masterLabel = bdw.buttonLabel;
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
                    addButtons(chunk);
                    
                    // Clear the chunk list for the next batch
                    chunk.clear();
                }
            }

            return true;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'createListViewButtons');
            system.debug('exception in createListViewButtons : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return false;
        }
    }
    
/*
*********************************************************
@description     : Method is used as a helper method for addding buttons in chunk of 10 at once
@param           : webLinks - {List<MetadataService.Metadata>}
@return          : none
********************************************************
*/
    public static void addButtons(List<MetadataService.Metadata> webLinks){
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
                throw new AuraHandledException('Error Creating Button.');
            }

        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'addButtons');
            system.debug('exception in addButtons : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
        }
    }


// -------------------------------------------------------------- Wrapper Classes ------------------------------------------------------------ //

/*
*********************************************************
@description     : wrapper containing Data for the objects list
@param           : label {String} - Label of the object
@param           : value {String} - Name of the object
********************************************************
*/
    public class ObjectsWrapper{
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
    }

/*
*********************************************************
@description     : wrapper containing Data of the Custom Button
@param           : objects {List<String>} - list of objects to create buttons on
@param           : buttonLabel {String} - Label of the button
@param           : buttonName {String} - Name of the button
@param           : buttonEndURL {String} - End URL for the button
@param           : buttonType {String} -type of the button
********************************************************
*/
    public class ButtonDataWrapper{
        @AuraEnabled public List<String> objects {get; set;}
        @AuraEnabled public String buttonLabel {get; set;}
        @AuraEnabled public String buttonName {get; set;}
        @AuraEnabled public String buttonEndURL {get; set;}
    }

/*
*********************************************************
@description     : wrapper containing data of all already create button objects
@param           : allObjects {List<ObjectsWrapper>} - list of all objects
@param           : listViewButtonObj {List<String>} - list of object that have a list view button
@param           : quickActionButtonObj {List<String>} - list of object that have a quick action button
@param           : basicPrintButtonObj {List<String>} - list of objects that have a basic print button
********************************************************
*/
    public class CombinedDataWrapper{
        @AuraEnabled public List<ObjectsWrapper> allObjects;
        @AuraEnabled public List<String> listViewButtonObj;
        @AuraEnabled public List<String> quickActionButtonObj;
        @AuraEnabled public List<String> basicPrintButtonObj;
        @AuraEnabled public Boolean isSuccess;
    }



}