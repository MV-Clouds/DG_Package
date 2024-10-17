/*
*********************************************************
Apex Class Name    : ButtonGeneratorController
@description       : This class is used for fetching all the objects to work on and handling various processes of button generator to create the buttons
@author            : Kevin Suvagiya
@last Modified     : Kevin Suvagiya - 17 Sep, 2024
*********************************************************
*/
public with sharing class ButtonGeneratorController {

/*
*********************************************************
@description     : Method is used to combine all the data to be intially fetched to improve performance
@param           : none
@return          : combinedData {CombinedDataWrapper} - wrapper containing all objects, all buttons and a success message
********************************************************
*/
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
                List<String> notAllowedObjects = new List<String>{'Address', 'AgentWork', 'Announcement', 'AppAnalyticsQueryRequest', 'AppointmentInvitee', 'AppointmentTopicTimeSlot', 'ApptBundleConfig', 'ApptBundlePropagatepPolicy', 'ApptbundleAggrDurDnscale', 'AssetRelationship', 'AssociatedLocation', 'AuthorizationFormConsent', 'BusinessBrand', 'BuyerGroup', 'CalendarView', 'CampaignMember', 'ChannelProgramMember', 'CollaborationGroup', 'CollaborationGroupRecord', 'CommSubscription', 'CommSubscriptionChannelType', 'CommSubscriptionConsent', 'CommSubscriptionTiming', 'ContactPointAddress', 'ContactPointConsent', 'ContactPointEmail', 'ContactPointPhone', 'ContactPointTypeConsent', 'ContentVersion', 'ContractLineOutcomeData', 'ContractLintItem', 'Customer', 'DataUseLegalBasis', 'DelegatedAccount', 'DuplicateAccount', 'DuplicateRecordItem', 'DuplicateRecordSet', 'EngagementChannelWorkType', 'Entitlement', 'Event', 'ExpenseReportEntry', 'ExpressionFilter', 'ExpressionFilterCriteria', 'FinanceTransaction', 'FlowRecordRelation', 'GeolocationBasedAction', 'Idea', 'Image', 'ListEmail', 'ListEmailIndividualRecipient', 'ListEmailRecipentSource', 'Location', 'LocationGroup', 'LocationGroupAssignment', 'Macro', 'MaintenanceAsset', 'MaintenanceWorkRule', 'NamespaceRegistry', 'OrgMetric', 'PartnerFundAllocation', 'PartnerFundClaim', 'PartnerFundRequest', 'PaymentAuthAdjustment', 'PaymentGateway', 'PaymentGroup', 'PaymentLineInvoice', 'Pricebook2', 'PrivacyRTBFRequest', 'ProblemIncident', 'ProductAttribute', 'ProductAttributeSetProduct', 'ProductConsumed', 'ProductConsumptionSchedule', 'ProductItem', 'ProductRequestLineItem', 'ProductServiceCampaignItem', 'ProductWarrantyTerm', 'ProductWarrantyterm', 'Promotion', 'PromotionMarketSegment', 'PromotionQualifier', 'PromotionSegment', 'PromotionSegmentSalesStore', 'PromotionTarget', 'PromptAction', 'PromptError', 'QuickText', 'Recommendation', 'RecordAction', 'RefundLinePayment', 'ResourceAbsence', 'ReturnOrderItemAdjustment', 'ReturnOrderItemTax', 'ReturnOrderLineItem', 'SchedulingWorkspace', 'SchedulingWorkspaceTerritory', 'ScratchOrgInfo', 'Seller', 'SerializedProduct', 'ServiceAppointment', 'ServiceTerritoryWorkType', 'ServiceTerritoryWorkType3', 'Shift', 'ShiftEngagementChannel', 'ShiftTemplate', 'ShiftWorkTopic', 'Shipment', 'ShipmentItem', 'ShippingCarrier', 'ShippingCarrierMethod', 'Solution', 'Store', 'StoreIntegratedService', 'TimeSheetEntry', 'UnitOfMeasure', 'User', 'UserEmailPreferredPerson', 'UserRole', 'WaitlistServiceResource', 'WaitlistWorkType', 'WarrantyItem', 'WebCart', 'WebCartAdjustmentBasis', 'WebStore', 'WebStoreConfig', 'WebStoreInventorySource', 'WorkBadge', 'WorkBadgeDefinition', 'WorkCapacityAvailability', 'WorkCapacityLimit', 'WorkCapacityUsage', 'WorkOrderLineItem', 'WorkPlan', 'WorkPlanTemplateEntry', 'WorkStep', 'WorkType', 'WorkTypeGroup', 'WorkTypeGroupMember', 'badge', 'feed', 'group', 'history', 'public', 'share', 'tag'};
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
            return null;
        }
    }

/*
*********************************************************
@description     : Method is used to create a list view button 
@param           : objects - {List<String>} - name of objects
@param           : buttonData - {Map<String, String>} - button data
@return          : none
********************************************************
*/
    @AuraEnabled
    public static String createListViewButtons(List<String> objects,Map<String, String> buttonData){
        try {
            String buttonName = buttonData.get('buttonName');
            String buttonEndURL = buttonData.get('buttonEndURL');
            String buttonLabel = buttonData.get('buttonLabel');
            Integer batchSize = 10;
            Integer totalSize = objects.size();

            List<MetadataService.Metadata> webLinks = new List<MetadataService.Metadata>();
            for (Integer i = 0; i < totalSize; i++) {
                String obj = objects[i];
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
                
                if (webLinks.size() == batchSize || i == totalSize - 1) {
                    // Process the 10 webLinks
                    Boolean isSuccess = addButtons(webLinks);
                    if(!isSuccess && !Test.isRunningTest()){
                        throw new AuraHandledException('Error Creating Button.');
                    }
                    // Clear the webLinks list for the next batch
                    webLinks.clear();
                }
            }
            return 'success';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'createListViewButtons');
            return e.getMessage();
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

            if(!saveResultList[0].created){
                return false;
            }
            return true;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'ButtonGeneratorController', 'addButtons');
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