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
    public static String salesforceImageSRCs {get; set;}
    public static String mergeTemplateKeys {get; set;}
    public static String signatureKey {get; set;}
    public static Decimal signatureSize {get; set;}
    public static integer imageMaxSize {get; set;}

    public static String sessionId {get; set;}
    
    public static string apexError {get; set;}

    public DocGenerateController() {
        sessionId = GenerateDocumentController.getSessionId();
        getTemplateDetails();
    }

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
    
                    List<Template__c> temp = new List<Template__c>();
    
                    List<String> valueTypes = new List<String>{'Body Value', 'Header Value', 'Footer Value', 'Watermark Value'};
                    Integer totalTemplateDataRecords = Database.countQuery('SELECT Count() FROM Template_Data__c WHERE Template__c =: templateId AND Value_Type__c IN :valueTypes');
    
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

    public static void setTemplateDetails(List<String> getValueTypes, String templateID, String recordId){
        try {

            if( Schema.sObjectType.Template__c.fields.Id.isAccessible() &&
                Schema.sObjectType.Template__c.fields.Template_Name__c.isAccessible() && Schema.sObjectType.Template__c.fields.Signature_Size__c.isAccessible() &&
                Schema.sObjectType.Template_Data__c.fields.Id.isAccessible() && Schema.sObjectType.Template_Data__c.fields.Template_Value_Simple__c.isAccessible() &&
                Schema.sObjectType.Template_Data__c.fields.Value_Type__c.isAccessible() && 
                Schema.sObjectType.Template_Page__c.fields.Id.isAccessible() &&  Schema.sObjectType.Template_Page__c.fields.Page_Margin__c.isAccessible() &&
                Schema.sObjectType.Template_Page__c.fields.Page_Orientation__c.isAccessible() && Schema.sObjectType.Template_Page__c.fields.Page_Size__c.isAccessible() &&
                Schema.sObjectType.Template_Page__c.fields.Unit_of_Page_Configs__c.isAccessible() && Schema.sObjectType.Template_Page__c.fields.Show_Header__c.isAccessible() &&
                Schema.sObjectType.Template_Page__c.fields.Show_Footer__c.isAccessible() && Schema.sObjectType.Template_Page__c.fields.Show_Watermark__c.isAccessible() &&
                Schema.sObjectType.Template_Page__c.fields.Header_margin_top__c.isAccessible() && Schema.sObjectType.Template_Page__c.fields.Footer_margin_bottom__c.isAccessible() &&
                Schema.sObjectType.Template_Page__c.fields.Page_Number__c.isAccessible() && Schema.sObjectType.Template_Page__c.fields.Template__c.isAccessible())
            {
                List<Template__c> temp = [SELECT Id, Template_Name__c, Signature_Size__c,
                                (SELECT Id, Template_Value_Simple__c,Value_Type__c FROM Template_Data__r WHERE Value_Type__c IN: getValueTypes ORDER BY Order_No_Simple__c ASC),
                                (SELECT Id, Page_Margin__c, Page_Orientation__c, Page_Size__c, Unit_of_Page_Configs__c, Show_Header__c, Show_Footer__c,Show_Watermark__c, Header_margin_top__c, Footer_margin_bottom__c FROM Template_Pages__r ORDER BY Page_Number__c ASC)
                                FROM Template__c WHERE Id =: templateID WITH SECURITY_ENFORCED LIMIT 1 ];
    
                if(temp.size() > 0){
                    Template_Page__c pageConfigs = temp[0].Template_Pages__r[0];
                    showHeader = pageConfigs.Show_Header__c;
                    showFooter = pageConfigs.Show_Footer__c;
                    showWatermark = pageConfigs.Show_Watermark__c;
                    pageMargins = pageConfigs.Page_Margin__c;
                    pageConfigUnit = pageConfigs.Unit_of_Page_Configs__c;
                    pageOrientation = pageConfigs.Page_Orientation__c;
                    pageSize = pageConfigs.Page_Size__c;
                    headerMarginTop = pageConfigs.Header_margin_top__c;
                    footerMarginBottom = pageConfigs.Footer_margin_bottom__c;
    
                    for(Template_Data__c fieldData : temp[0].Template_Data__r){
                        String value = fieldData.Template_Value_Simple__c != null ? fieldData.Template_Value_Simple__c : '';
                        if(fieldData.Value_Type__c == 'Body Value'){
                            bodyHtml += value;
                        }
                        else if(fieldData.Value_Type__c == 'Header Value' && showHeader == true){
                            headerHtml += value;
                        }
                        else if(fieldData.Value_Type__c == 'Footer Value' && showFooter == true){
                            footerHtml += value;
                        }
                        else if(fieldData.Value_Type__c == 'Watermark Value' && showWatermark == true){
                            system.debug(' watermarkValue : ' + watermarkValue);
                            watermarkValue += value;
                        }
                    }
    
                    signatureSize = temp[0].Signature_Size__c != null ? temp[0].Signature_Size__c : 50;
    
                }
    
                // ---- ----- ----- Collect all mapping key with actual value ---- ----- -----
                map<String, Map<String, String>> mappingKeys = DataMappingControllerV2.getMappingsKeyValues(new List<String>{temp[0].Id}, recordId, true);
    
                mappingKeyVsMappingValues = JSON.serialize(mappingKeys.get('objectNGeneral'));
                childRecordTableKeys = JSON.serialize(mappingKeys.get('childRecordTable'));
                salesforceImageSRCs = JSON.serialize(mappingKeys.get('salesforceImages'));
                mergeTemplateKeys = JSON.serialize(mappingKeys.get('margeTemplate'));
            }
            else{
                apexError = 'User does not have premission of DocGenius Custome Object\'s Fields';
            }

        } catch (Exception e) {
            apexError = e.getMessage();
            system.debug('exception in setTemplateDatas : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
        }
    }

    @RemoteAction
    global static list<string> fetchTemplateData(Integer offset, String templateId, String mappingKey){
        System.debug('heap size 1 : '+ Limits.getHeapSize());

        Boolean isLastBatch = false;
        List<String> bodyHtml = new List<String>();

        mappingKey = mappingKey != null ? mappingKey : '';

        List<Template__c> temp = [SELECT Id, Template_Type__c, Template_Name__c, Template_Status__c FROM Template__c WHERE Id =: templateId  WITH SECURITY_ENFORCED LIMIT 1];

        if(temp.size() > 0 && temp[0]?.Template_Type__c == 'Simple Template' && temp[0]?.Template_Status__c == true ){

            Integer batchSize = 25;
            
            Integer bodyValueRecords = Database.countQuery('SELECT Count() FROM Template_Data__c WHERE Template__c =: templateId AND Value_Type__c = \'Body Value\'');

            Integer endIndex = (offset + batchSize) >= bodyValueRecords ? bodyValueRecords : (offset + batchSize);
            isLastBatch = (offset + batchSize) >= bodyValueRecords ? true : false;

            for(Template_Data__c fieldData : [SELECT Id, Order_No_Simple__c, Template_Value_Simple__c, Value_Type__c
                                                FROM Template_Data__c
                                                WHERE Template__c = : templateId
                                                AND Order_No_Simple__c >= :offset
                                                AND Order_No_Simple__c <= :endIndex
                                                AND Value_Type__c =: 'Body Value'
                                                WITH SECURITY_ENFORCED
                                                ORDER BY Order_No_Simple__c ASC])
            {
                String data = fieldData.Template_Value_Simple__c;
                bodyHtml.add(data);
            }

            return new list<string>{string.valueOf(isLastBatch), string.join(bodyHtml,'').unescapeHtml4()};
        }
        else if(temp.size() > 0 && temp[0]?.Template_Type__c == 'Simple Template' && temp[0]?.Template_Status__c == false){
            String data = '<span style="color: red;"> '+mappingKey+' --- Inactive Template --- </span>';
            bodyHtml.add(data);
            isLastBatch = true;
             return new list<string>{string.valueOf(isLastBatch), string.join(bodyHtml,'').unescapeHtml4()};
        }
        else if(temp.size() > 0 && (temp[0]?.Template_Type__c == 'CSV Template' || temp[0]?.Template_Type__c == 'Google Doc Template')){
            String data = '<span style="color: red;"> '+mappingKey+' --- Can Not Merge '+temp[0].Template_Name__c+' --- span>';
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

    @RemoteAction
    global static String fetchImageBase64(String imageSRC){
        String base64 = '';

        String imageId = imageSRC?.substringAfter('/download/');

        List<contentVersion> image = [SELECT Id, VersionData FROM ContentVersion WHERE Id =: imageId AND IsLatest = true WITH SECURITY_ENFORCED LIMIT 1];
        //  AND ContentSize < 5000000
        base64 = image.size() > 0 ? EncodingUtil.base64Encode(image[0].VersionData) : '';

        system.debug('size : ' + ((base64.length() / 4)  * 3 ) / 1000000+ ' MB');

        return base64;
    }

    @RemoteAction
    global static String fetchSignatureBase64(String recordId){

        List<ContentVersion> signatures = [SELECT Id, VersionData, ContentSize FROM ContentVersion WHERE Title Like '%Signature-%' AND FirstPublishLocationId =: recordId AND IsLatest = true WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];

        if(signatures.size() > 0){
            return signatures[0].ContentSize < 3000000  ? 'data:image/png;base64,' + EncodingUtil.base64Encode(signatures[0].VersionData) : 'largeImage';
        }
        else{
            return 'noSignature';
        }
    }

           

    public static void dummyMethod(){
        System.debug('content Type Set');
    }
}