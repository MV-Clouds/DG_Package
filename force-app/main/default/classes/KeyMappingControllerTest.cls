/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class KeyMappingControllerTest {
    public static Blob imageBlob = Blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAARAAAAB/CAIAAACovQp5AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAABEKADAAQAAAABAAAAfwAAAADAZSePAAANGUlEQVR4Ae2dO4gUSxSGr5drauIqYmjgBoKbi+CCGCisKIiRgusjMTIQH2io+MDAyMQHgkaLoLCggSysIAZmCgYaGIr4QDA1uZ/3XA7l9kxPVU9NT/XuP8FQU33q1Om/zt+nnj2rPn/+/Jc+QkAIxCHwd5yYpISAEPiNgAgjPxACCQiIMAlgSVQIiDDyASGQgIA');

    @isTest
    static void keyMappingTest(){
        String sourceObjectAPI = createTemplateRecord().Object_API_Name__c;
        String imgID = createContentVersion(null).Id;
        Template__c temp = createTemplateRecord();

        Test.startTest();
        KeyMappingController.getFieldMappingKeys(sourceObjectAPI, true);
        KeyMappingController.getChildObjects(sourceObjectAPI);
        KeyMappingController.getMerginTemplateKeys(sourceObjectAPI);
        KeyMappingController.getAllContentVersionImgs();
        KeyMappingController.getGeneralFields();
        string getBlob = KeyMappingController.fetchImgBlob(imgID);
        KeyMappingController.formattingFieldKeys();
        KeyMappingController.getSignatureInfo(temp.Id);
        KeyMappingController.updateSignatureInfo(temp.Id, 59);
        Test.stopTest();

        System.assertEquals(EncodingUtil.base64Encode(imageBlob), getBlob, 'success');
    }

    @isTest
    static void keyMappingTestException(){
        Test.startTest();
        KeyMappingController.getFieldMappingKeys('sdasfd', false);
        KeyMappingController.getChildObjects('sdasfd');
        KeyMappingController.getRelatedObjects('sdasfd');
        List<Schema.DescribeFieldResult> objectField = KeyMappingController.getObjectFields('sdasd');
        KeyMappingController.createMappingFieldInstance(null, 'sadas0', 'sdasddas');
        KeyMappingController.updateSignatureInfo('qewrwqer', 10);
        Test.stopTest();

        System.assertEquals(null, objectField, 'exception success');
    }

    @isTest
    static void docGenerateTest(){
        Template__c temp = createTemplateRecord();
        Account acc = createAccountRecord();
        String imageUrl = 'sfc/servlet.shepherd/version/download' + createContentVersion(acc.Id).Id;
        String orgDomain = URL.getOrgDomainURL().toExternalForm();
        String orgHost = orgDomain.substringBefore('.');
        Test.startTest();
        String paraData = '{ "templateId" : "'+temp.Id+'", "Object_API_Name__c" : "'+temp.Object_API_Name__c+'", "recordId" : "'+acc.Id+'", "usedFrom" : "Simple Template" }';
        PageReference pageRef = new PageReference('/apex/DocGeneratePage');
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('paraData', paraData);
        DocGenerateController docGenerate = new DocGenerateController();
        DocGenerateController.paraData = '{ "templateId" : "'+temp.Id+'", "Object_API_Name__c" : "'+temp.Object_API_Name__c+'", "recordId" : "'+acc.Id+'", "usedFrom" : "Simple Template" }';
        DocGenerateController.pageMargins = '';
        DocGenerateController.pageConfigUnit = '';
        DocGenerateController.pageSize = '';
        DocGenerateController.pageOrientation = '';
        DocGenerateController.selectedExtension = '';
        DocGenerateController.selectedChannels = '';
        DocGenerateController.recordId = '';
        DocGenerateController.fileName = '';
        DocGenerateController.templateId = '';
        DocGenerateController.selectedFolder = '';
        DocGenerateController.useMode = '';
        DocGenerateController.headerHtml = '';
        DocGenerateController.bodyHtml = '';
        DocGenerateController.footerHtml = '';
        DocGenerateController.watermarkValue = '';
        DocGenerateController.headerMarginTop = 1;
        DocGenerateController.footerMarginBottom = 1;
        DocGenerateController.showHeader = true;
        DocGenerateController.showFooter = true;
        DocGenerateController.showWatermark = true;
        DocGenerateController.mappingKeyVsMappingValues = '';
        DocGenerateController.childRecordTableKeys = '';
        DocGenerateController.salesforceImageSRCs = '';
        DocGenerateController.mergeTemplateKeys = '';
        DocGenerateController.signatureKey = '';
        DocGenerateController.signatureSize = 50;
        DocGenerateController.imageMaxSize = 20*1000*1000;
        DocGenerateController.sessionId = '';
        DocGenerateController.fetchTemplateData(0, temp.Id, '{{Temp.'+temp.Id+' *Demo temp*}}');
        DocGenerateController.fetchSignatureBase64(acc.Id);
        DocGenerateController.fetchImageBase64(orgHost+imageUrl);
        Test.stopTest();
    }

    @isTest
    static void keyMappingTest2(){
        Test.startTest();
        KeyMappingController.getAllContentVersionImgs();
        String getBlob = KeyMappingController.fetchImgBlob('sdas');
        Test.stopTest();

        System.assertEquals(null, getBlob, 'success');
    }



    static Template__c createTemplateRecord(){
        Template__c template = new Template__c();
        template.Template_Name__c = 'Test Template';
        template.Template_Type__c = 'Simple Template';
        template.Object_API_Name__c = 'Account';
        template.Template_Status__c = true;
        insert template;

        Template_Page__c page = new Template_Page__c();
        page.Template__c = template.Id;
        page.Page_Number__c = 1;
        page.Page_Margin__c = '1;1;1;1';
        page.Page_Orientation__c = 'portrait';
        page.Page_Size__c = 'a4';
        page.unit_of_page_configs__c = 'inch';
        insert page;

        String templateValue = templateValue();
        
        Template_Data__c templateField = new Template_Data__c();
        templateField.Template__c = template.Id;
        templateField.Value_Type__c	= 'Body Value';
        templateField.Template_Value_Simple__c = templateValue;
        templateField.Order_No_Simple__c =1;
        insert templateField;

        Template_Data__c templateField2 = new Template_Data__c();
        templateField2.Template__c = template.Id;
        templateField2.Value_Type__c	= 'header Value';
        templateField2.Template_Value_Simple__c = templateValue;
        templateField2.Order_No_Simple__c =2;
        insert templateField2;

        Template_Data__c templateField3 = new Template_Data__c();
        templateField3.Template__c = template.Id;
        templateField3.Value_Type__c	= 'Footer Value';
        templateField3.Template_Value_Simple__c = templateValue;
        templateField3.Order_No_Simple__c =3;
        insert templateField3;

        return template;
    }

    public static Template__c createMergeTemplate(){
        Template__c template = new Template__c();
        template.Template_Name__c = 'Test Template 2';
        template.Template_Type__c = 'Simple Template';
        template.Object_API_Name__c = 'Account';
        template.Template_Status__c = true;
        insert template;

        Template_Data__c templateField = new Template_Data__c();
        templateField.Template__c = template.Id;
        templateField.Template_Value_Simple__c = 'test data 1234';
        templateField.Order_No_Simple__c =1;
        insert templateField;

        return template;
    }

    public static Template__c createMergeTemplateInActive(){
        Template__c template = new Template__c();
        template.Template_Name__c = 'Test Template 3';
        template.Template_Type__c = 'Simple Template';
        template.Object_API_Name__c = 'Account';
        template.Template_Status__c = false;
        insert template;

        return template;
    }

    public static Template__c createMergeTemplateCSV(){
        Template__c template = new Template__c();
        template.Template_Name__c = 'Test Template 4';
        template.Template_Type__c = 'CSV Template';
        template.Object_API_Name__c = 'Account';
        template.Template_Status__c = false;
        insert template;

        return template;
    }

    static Account createAccountRecord(){
        Account acc = new Account();
        acc.Name = 'test Account';
        acc.NumberOfEmployees  = 12;
        insert acc;

        List<Contact> childContacts = new List<Contact>();
        for(Integer i = 1; i < 10; i++){
            childContacts.add(createContact(i, acc.Id));
        }
        insert childContacts;

        return acc;
    }

    public static Contact createContact(Integer i, String accId){
        Contact con = new contact();
        con.lastName = 'test contact' + i;
        con.accountId = accId;
        return con;
    }

    public static ContentVersion createContentVersion(String accId){
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Signature- image';
        cv.PathOnClient = 'Signature- image.png';
        cv.VersionData = imageBlob;
        if(accId != null){
            cv.FirstPublishLocationId = accId;
        }
        insert cv;

        return cv;
    }

    public static string templateValue(){
        String mergeTempId = createMergeTemplate().Id;
        String inActiveMergeTempId = createMergeTemplateInActive().Id;
        String csvMergeTempId = createMergeTemplateCSV().Id;
        String imageUrl = 'sfc/servlet.shepherd/version/download' + createContentVersion(null).Id;
        String orgDomain = URL.getOrgDomainURL().toExternalForm();
        String orgHost = orgDomain.substringBefore('.');

        String templateValue ='<p>{{#Id}}&nbsp;{{#Name}}&nbsp;{{Doc.Date.date}}&nbsp;{{Doc.User.AboutMe}}&nbsp;{{Doc.Org.City}}&nbsp;{{#CreatedBy.Username}}</p><p>{{#Name *L:20*}}&nbsp;{{#CreatedDate *dd/MM/yyyy HH:mm:ss*}}&nbsp;{{#IsDeleted *yes/no*}}&nbsp;{{#NumberOfEmployees *F:yes,*}}</p><table data-name="childRecords"><tbody class="" lwc-1tbjdqlnk30=""><tr><td style="overflow: hidden; text-align: center;">No.</td><td style="overflow: hidden; text-align: center;">Account ID</td><td style="overflow: hidden; text-align: center;">Created Date</td><td style="overflow: hidden; text-align: center;">Last Modified Date</td></tr><tr data-name="keyRow"><td style="overflow: hidden; text-align: center;">{{No.Index}}</td><td style="overflow: hidden; text-align: center;">{{!AccountId}}</td><td style="overflow: hidden; text-align: center;">{{!CreatedDate}}</td><td style="overflow: hidden; text-align: center;">{{!LastModifiedDate}}</td></tr><tr data-name="infoRow"><td colspan="4" style="position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;">Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: IsDeleted = false  ORDER BY AccountId ASC $<br></td></tr></tbody></table>';
        templateValue += '{{Doc.Temp.'+mergeTempId+' *test merge temp*'+'}}';
        templateValue += '{{Doc.Temp.'+inActiveMergeTempId+' *test merge temp*'+'}}';
        templateValue += '{{Doc.Temp.'+csvMergeTempId+' *test merge temp*'+'}}';
        templateValue += '<img src="'+orgHost+imageUrl+'" data-origin="sf" style="width: 75%;">';
        return templateValue;
    }
}