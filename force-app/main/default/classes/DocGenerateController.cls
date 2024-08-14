global with sharing class DocGenerateController {

    public static String paraData {get; set;}
    public static String selectedExtension {get; set;}
    public static String selectedChannels {get; set;}
    public static String recordId {get; set;}
    public static String fileName {get; set;}
    public static String templateId {get; set;}
    public static String selectedFolder {get; set;}
    public static String useMode {get; set;}

    public static String headerHtml {get; set;}
    public static String bodyHtml {get; set;}
    public static String footerHtml {get; set;}
    public static String watermarkValue {get; set;}

    public static String pageMargins {get; set;}
    public static String pageConfigUnit {get; set;}
    public static String pageSize {get; set;}
    public static String pageOrientation {get; set;}

    public static Decimal headerMarginTop {get; set;}
    public static Decimal footerMarginBottom {get; set;}
    public static Boolean showHeader {get; set;}
    public static Boolean showFooter {get; set;}
    public static Boolean showWatermark {get; set;}

    public static Boolean isBatchRequired {get; set;}

    public static String mappingKeyVsMappingValues {get; set;}
    public static String childRecordTableKeys {get; set;}
    public static String salesforceImages {get; set;}
    public static String mergeTemplateKeys {get; set;}
    public static String signatureImageCvId {get; set;}
    public static String signatureKey {get; set;}
    public static Decimal signatureSize {get; set;}
    public static integer imageMaxSize {get; set;}

    public static String sessionId {get; set;}
    
    public static string apexError {get; set;}

    /**
     * constructor :  DocGenerateController
     * @description : run when vf page call, entry point of all the vf page methods...
     */
    public DocGenerateController() {
        sessionId = GenerateDocumentController.getSessionId();
        getTemplateDetails();
    }

    /**
     * method : getTemplateDetails
     * @description : get template detail and tempate data and template page configuration for document generation
     */
    public static void getTemplateDetails(){
        try {
                System.debug('paraData before : ' + ApexPages.currentPage().getParameters().get('paraData'));

                if(ApexPages.currentPage().getParameters().get('paraData') != null){
                    String paraData = ApexPages.currentPage().getParameters().get('paraData');
                    Map<String, Object> rawData = (Map<String, Object>)JSON.deserializeUntyped(paraData);
    
                    System.debug('paraData : ' + paraData);
        
                    selectedExtension = (String)rawData.get('selectedExtension');
                    selectedChannels = (String)rawData.get('selectedChannels');
                    fileName = (String)rawData.get('fileName');
                    selectedFolder = (String)rawData.get('selectedFolder');
                    useMode = (String)rawData.get('useMode') != null ? (String)rawData.get('useMode') : 'generate';
    
                    templateId = (String)rawData.get('templateId');
                    recordId = (String)rawData.get('recordId');
    
                    bodyHtml = '';
                    headerHtml = '';
                    footerHtml = '';
                    watermarkValue = '';
    
                    signatureKey = KeyMappingController.signatureKey;
                    imageMaxSize = KeyMappingController.maxImageSize;
    
                    List<MVDG__Template__c> temp = new List<MVDG__Template__c>();
    
                    List<String> valueTypes = new List<String>{'Body Value', 'Header Value', 'Footer Value', 'Watermark Value'};
                    Integer totalTemplateDataRecords = Database.countQuery('SELECT Count() FROM MVDG__Template_Data__c WHERE MVDG__Template__c =: templateId AND MVDG__Value_Type__c IN :valueTypes');
    
                    // If totalTemplateDataRecords > 25 ,mease there is higher changes to code exceed heap size limit...
                    // So only send 'Header Value' and 'Footer values' and send body value is batch...
                    isBatchRequired = totalTemplateDataRecords > 25;
                    List<String> getValueTypes = new List<String>{'Header Value', 'Footer Value', 'Watermark Value'};
                    
                    if(isBatchRequired == false){
                        getValueTypes.add('Body Value');
                    }
    
                    setTemplateDetails(getValueTypes, templateID, recordId);
                }
                else {
                    apexError = 'Document generation request not well in defied.';
                }

        }
        catch (Exception e){
            apexError = e.getMessage();
            system.debug('exception in getTemplateDetails : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
        }
    }

    /**
     * @method setTemplateDetails
     * @param getValueTypes, list of template types
     * @param templateID, template Id String
     * @param recordId, sorce record id
     * @description : method to collect template deatils and template data for document generation.
     */
    public static void setTemplateDetails(List<String> getValueTypes, String templateID, String recordId){
        try {

            if( Schema.sObjectType.MVDG__Template__c.fields.Id.isAccessible() &&
                Schema.sObjectType.MVDG__Template__c.fields.MVDG__Template_Name__c.isAccessible() && Schema.sObjectType.MVDG__Template__c.fields.MVDG__Signature_Size__c.isAccessible() &&
                Schema.sObjectType.MVDG__Template_Data__c.fields.Id.isAccessible() && Schema.sObjectType.MVDG__Template_Data__c.fields.MVDG__Template_Value_Simple__c.isAccessible() &&
                Schema.sObjectType.MVDG__Template_Data__c.fields.MVDG__Value_Type__c.isAccessible() && 
                Schema.sObjectType.MVDG__Template_Page__c.fields.Id.isAccessible() &&  Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Page_Margin__c.isAccessible() &&
                Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Page_Orientation__c.isAccessible() && Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Page_Size__c.isAccessible() &&
                Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Unit_of_Page_Configs__c.isAccessible() && Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Show_Header__c.isAccessible() &&
                Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Show_Footer__c.isAccessible() && Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Show_Watermark__c.isAccessible() &&
                Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Header_margin_top__c.isAccessible() && Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Footer_margin_bottom__c.isAccessible() &&
                Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Page_Number__c.isAccessible() && Schema.sObjectType.MVDG__Template_Page__c.fields.MVDG__Template__c.isAccessible())
            {
                List<MVDG__Template__c> temp = [SELECT Id, MVDG__Template_Name__c, MVDG__Signature_Size__c,
                                (SELECT Id, MVDG__Template_Value_Simple__c,MVDG__Value_Type__c FROM MVDG__Template_Data__r WHERE MVDG__Value_Type__c IN: getValueTypes ORDER BY MVDG__Order_No_Simple__c ASC),
                                (SELECT Id, MVDG__Page_Margin__c, MVDG__Page_Orientation__c, MVDG__Page_Size__c, MVDG__Unit_of_Page_Configs__c, MVDG__Show_Header__c, MVDG__Show_Footer__c,MVDG__Show_Watermark__c, MVDG__Header_margin_top__c, MVDG__Footer_margin_bottom__c FROM MVDG__Template_Pages__r ORDER BY MVDG__Page_Number__c ASC)
                                FROM MVDG__Template__c WHERE Id =: templateID WITH SECURITY_ENFORCED LIMIT 1 ];
    
                if(temp.size() > 0){
                    MVDG__Template_Page__c pageConfigs = temp[0].MVDG__Template_Pages__r[0];
                    showHeader = pageConfigs.MVDG__Show_Header__c;
                    showFooter = pageConfigs.MVDG__Show_Footer__c;
                    showWatermark = pageConfigs.MVDG__Show_Watermark__c;
                    pageMargins = pageConfigs.MVDG__Page_Margin__c;
                    pageConfigUnit = pageConfigs.MVDG__Unit_of_Page_Configs__c;
                    pageOrientation = pageConfigs.MVDG__Page_Orientation__c;
                    pageSize = pageConfigs.MVDG__Page_Size__c;
                    headerMarginTop = pageConfigs.MVDG__Header_margin_top__c;
                    footerMarginBottom = pageConfigs.MVDG__Footer_margin_bottom__c;
    
                    for(MVDG__Template_Data__c fieldData : temp[0].MVDG__Template_Data__r){
                        String value = fieldData.MVDG__Template_Value_Simple__c != null ? fieldData.MVDG__Template_Value_Simple__c : '';
                        if(fieldData.MVDG__Value_Type__c == 'Body Value'){
                            bodyHtml += value;
                        }
                        else if(fieldData.MVDG__Value_Type__c == 'Header Value' && showHeader == true){
                            headerHtml += value;
                        }
                        else if(fieldData.MVDG__Value_Type__c == 'Footer Value' && showFooter == true){
                            footerHtml += value;
                        }
                        else if(fieldData.MVDG__Value_Type__c == 'Watermark Value' && showWatermark == true){
                            system.debug(' watermarkValue : ' + watermarkValue);
                            watermarkValue += value;
                        }
                    }
    
                    signatureSize = temp[0].MVDG__Signature_Size__c != null ? temp[0].MVDG__Signature_Size__c : 50;
    
                }
    
                // ---- ----- ----- Collect all mapping key with actual value ---- ----- -----
                map<String, Map<String, String>> mappingKeys = DataMappingControllerV2.getMappingsKeyValues(new List<String>{temp[0].Id}, recordId, true);
    
                mappingKeyVsMappingValues = JSON.serialize(mappingKeys.get('objectNGeneral'));
                childRecordTableKeys = JSON.serialize(mappingKeys.get('childRecordTable'));
                salesforceImages = JSON.serialize(mappingKeys.get('salesforceImages'));
                mergeTemplateKeys = JSON.serialize(mappingKeys.get('margeTemplate'));
                signatureImageCvId = JSON.serialize(mappingKeys.get('signatureImage'));
            }
            else{
                apexError = 'User does not have premission of DocGenius Custome Object\'s Fields';
            }

        } catch (Exception e) {
            apexError = e.getMessage();
            system.debug('exception in setTemplateDatas : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
        }
    }

    /**
     * method : fetchTemplateData
     * @param offset
     * @param templateId
     * @param mappingKey
     * @return list<string>
     * @description : fetch template data in batch for large template data and merge template.
     */
    @RemoteAction
    global static list<string> fetchTemplateData(Integer offset, String templateId, String mappingKey){
        System.debug('heap size 1 : '+ Limits.getHeapSize());

        Boolean isLastBatch = false;
        List<String> bodyHtml = new List<String>();

        mappingKey = mappingKey != null ? mappingKey : '';

        List<MVDG__Template__c> temp = [SELECT Id, MVDG__Template_Type__c, MVDG__Template_Name__c, MVDG__Template_Status__c FROM MVDG__Template__c WHERE Id =: templateId  WITH SECURITY_ENFORCED LIMIT 1];

        if(temp.size() > 0 && temp[0]?.MVDG__Template_Type__c == 'Simple Template' && temp[0]?.MVDG__Template_Status__c == true ){

            Integer batchSize = 25;
            
            Integer bodyValueRecords = Database.countQuery('SELECT Count() FROM MVDG__Template_Data__c WHERE MVDG__Template__c =: templateId AND MVDG__Value_Type__c = \'Body Value\'');

            Integer endIndex = (offset + batchSize) >= bodyValueRecords ? bodyValueRecords : (offset + batchSize);
            isLastBatch = (offset + batchSize) >= bodyValueRecords ? true : false;

            for(MVDG__Template_Data__c fieldData : [SELECT Id, MVDG__Order_No_Simple__c, MVDG__Template_Value_Simple__c, MVDG__Value_Type__c
                                                FROM MVDG__Template_Data__c
                                                WHERE MVDG__Template__c = : templateId
                                                AND MVDG__Order_No_Simple__c >= :offset
                                                AND MVDG__Order_No_Simple__c <= :endIndex
                                                AND MVDG__Value_Type__c =: 'Body Value'
                                                WITH SECURITY_ENFORCED
                                                ORDER BY MVDG__Order_No_Simple__c ASC])
            {
                String data = fieldData.MVDG__Template_Value_Simple__c;
                bodyHtml.add(data);
            }

            return new list<string>{string.valueOf(isLastBatch), string.join(bodyHtml,'').unescapeHtml4()};
        }
        else if(temp.size() > 0 && temp[0]?.MVDG__Template_Type__c == 'Simple Template' && temp[0]?.MVDG__Template_Status__c == false){
            String data = '<span style="color: red;"> '+mappingKey+' --- Inactive Template --- </span>';
            bodyHtml.add(data);
            isLastBatch = true;
             return new list<string>{string.valueOf(isLastBatch), string.join(bodyHtml,'').unescapeHtml4()};
        }
        else if(temp.size() > 0 && (temp[0]?.MVDG__Template_Type__c == 'CSV Template' || temp[0]?.MVDG__Template_Type__c == 'Google Doc Template')){
            String data = '<span style="color: red;"> '+mappingKey+' --- Can Not Merge '+temp[0].MVDG__Template_Name__c+' --- span>';
            bodyHtml.add(data);
            isLastBatch = true;
            return new list<string>{string.valueOf(isLastBatch), string.join(bodyHtml,'').unescapeHtml4()};
        }
        
        // if none of the above condition matched...
        String data = '<span style="color: red;"> '+mappingKey+' --- Template Deleted or Invalid Template Merge Key ---  </span>';
        bodyHtml.add(data);
        isLastBatch = true;
        
        return new list<string>{string.valueOf(isLastBatch), string.join(bodyHtml,'').unescapeHtml4()};
    }
}