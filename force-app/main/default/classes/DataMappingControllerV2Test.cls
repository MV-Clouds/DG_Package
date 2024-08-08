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
private class DataMappingControllerV2Test {

    public static Blob imageBlob = Blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAARAAAAB/CAIAAACovQp5AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAABEKADAAQAAAABAAAAfwAAAADAZSePAAANGUlEQVR4Ae2dO4gUSxSGr5drauIqYmjgBoKbi+CCGCisKIiRgusjMTIQH2io+MDAyMQHgkaLoLCggSysIAZmCgYaGIr4QDA1uZ/3XA7l9kxPVU9NT/XuP8FQU33q1Om/zt+nnj2rPn/+/Jc+QkAIxCHwd5yYpISAEPiNgAgjPxACCQiIMAlgSVQIiDDyASGQgIA');

    @isTest
    static void Test1() {
        List<String> tempIds = new List<String>{
            createTemplateRecord().Id
        };

        String accountId = createAccountRecord().Id;

        Test.startTest();
        DataMappingControllerV2.getMappingsKeyValues(tempIds, accountId, true);
        Test.stopTest();
    }

    @isTest 
    static void converExceptions(){

        List<String> tempIds = new List<String>{
            templateRecordException().Id
        };

        String accountId = createAccountRecord().Id;
        
        Test.startTest();
        DataMappingControllerV2.getMappingsKeyValues(tempIds, accountId, true);
        Test.stopTest();

    }
    

    static MVDG__Template__c createTemplateRecord(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template';
        template.MVDG__Template_Type__c = 'Simple Template';
        template.MVDG__Object_API_Name__c = 'Account';
        template.MVDG__Template_Status__c = true;
        insert template;

        MVDG__Template_Page__c page = new MVDG__Template_Page__c();
        page.MVDG__Template__c = template.Id;
        page.MVDG__Page_Number__c = 1;
        page.MVDG__Page_Margin__c = '1;1;1;1';
        page.MVDG__Page_Orientation__c = 'portrait';
        page.MVDG__Page_Size__c = 'a4';
        page.MVDG__Unit_of_Page_Configs__c = 'inch';
        insert page;

        String templateValue = templateValue();
        
        MVDG__Template_Data__c templateField = new MVDG__Template_Data__c();
        templateField.MVDG__Template__c = template.Id;
        templateField.MVDG__Value_Type__c	= 'Body Value';
        templateField.MVDG__Template_Value_Simple__c = templateValue;
        templateField.MVDG__Order_No_Simple__c =1;
        insert templateField;

        MVDG__Template_Data__c templateField2 = new MVDG__Template_Data__c();
        templateField2.MVDG__Template__c = template.Id;
        templateField2.MVDG__Value_Type__c	= 'Extracted Mapping Keys';
        templateField2.MVDG__Template_Value_Simple__c = extractedKey();
        templateField2.MVDG__Order_No_Simple__c =2;
        insert templateField2;

        return template;
    }

    static MVDG__Template__c templateRecordException(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template';
        template.MVDG__Template_Type__c = 'Simple Template';
        template.MVDG__Object_API_Name__c = 'Account';
        template.MVDG__Template_Status__c = true;
        insert template;

        MVDG__Template_Data__c templateField2 = new MVDG__Template_Data__c();
        templateField2.MVDG__Template__c = template.Id;
        templateField2.MVDG__Value_Type__c	= 'Extracted Mapping Keys';
        templateField2.MVDG__Template_Value_Simple__c = '[{name : sfasf}]';
        templateField2.MVDG__Order_No_Simple__c =2;
        insert templateField2;

        return template;
    }

    public static MVDG__Template__c createMergeTemplate(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template 2';
        template.MVDG__Template_Type__c = 'Simple Template';
        template.MVDG__Object_API_Name__c = 'Account';
        template.MVDG__Template_Status__c = true;
        insert template;

        MVDG__Template_Data__c templateField = new MVDG__Template_Data__c();
        templateField.MVDG__Template__c = template.Id;
        templateField.MVDG__Template_Value_Simple__c = 'test data 1234';
        templateField.MVDG__Order_No_Simple__c =1;
        insert templateField;

        return template;
    }

    public static MVDG__Template__c createMergeTemplateInActive(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template 3';
        template.MVDG__Template_Type__c = 'Simple Template';
        template.MVDG__Object_API_Name__c = 'Account';
        template.MVDG__Template_Status__c = false;
        insert template;

        return template;
    }

    public static MVDG__Template__c createMergeTemplateCSV(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template 4';
        template.MVDG__Template_Type__c = 'CSV Template';
        template.MVDG__Object_API_Name__c = 'Account';
        template.MVDG__Template_Status__c = false;
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

    public static ContentVersion createContentVersion(){
        ContentVersion cv = new ContentVersion();
        cv.Title = 'test image';
        cv.PathOnClient = 'test image.png';
        cv.VersionData = imageBlob;
        insert cv;

        return cv;
    }

    public static String createContentDistributuion(){

        ContentDistribution cd = new ContentDistribution(
            ContentVersionId = createContentVersion().Id,
            Name =  createContentVersion().Title
        );

        insert cd;

        return cd.ContentDownloadUrl;
    }

    public static string templateValue(){
        String mergeTempId = createMergeTemplate().Id;
        String inActiveMergeTempId = createMergeTemplateInActive().Id;
        String csvMergeTempId = createMergeTemplateCSV().Id;
        String contentDownloadUrl = createContentDistributuion();
        String orgDomain = URL.getOrgDomainURL().toExternalForm();
        String orgHost = orgDomain.substringBefore('.');

        String templateValue ='<p>{{#Id}}&nbsp;{{#Name}}&nbsp;{{Doc.Date.date}}&nbsp;{{Doc.User.AboutMe}}&nbsp;{{Doc.Org.City}}&nbsp;{{#CreatedBy.Username}}</p><p>{{#Name *L:20*}}&nbsp;{{#CreatedDate *dd/MM/yyyy HH:mm:ss*}}&nbsp;{{#IsDeleted *yes/no*}}&nbsp;{{#NumberOfEmployees *F:yes,*}}</p><table data-name="childRecords"><tbody class="" lwc-1tbjdqlnk30=""><tr><td style="overflow: hidden; text-align: center;">No.</td><td style="overflow: hidden; text-align: center;">Account ID</td><td style="overflow: hidden; text-align: center;">Created Date</td><td style="overflow: hidden; text-align: center;">Last Modified Date</td></tr><tr data-name="keyRow"><td style="overflow: hidden; text-align: center;">{{No.Index}}</td><td style="overflow: hidden; text-align: center;">{{!AccountId}}</td><td style="overflow: hidden; text-align: center;">{{!CreatedDate}}</td><td style="overflow: hidden; text-align: center;">{{!LastModifiedDate}}</td></tr><tr data-name="infoRow"><td colspan="4" style="position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;">Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: IsDeleted = false  ORDER BY AccountId ASC $<br></td></tr></tbody></table>';
        templateValue += '{{Doc.Temp.'+mergeTempId+' *test merge temp*'+'}}';
        templateValue += '{{Doc.Temp.'+inActiveMergeTempId+' *test merge temp*'+'}}';
        templateValue += '{{Doc.Temp.'+csvMergeTempId+' *test merge temp*'+'}}';
        templateValue += '<img src="'+orgHost+contentDownloadUrl+'" data-origin="sf" style="width: 75%;">';
        return templateValue;
    }

    public static string extractedKey(){
        String key = '{\"objectFields\":[\"{{#Id}}\",\"{{#Name}}\",\"{{#CreatedBy.Username}}\",\"{{#Name *L:20*}}\",\"{{#CreatedDate *dd/MM/yyyy HH:mm:ss*}}\",\"{{#IsDeleted *yes/no*}}\",\"{{#NumberOfEmployees *F:yes,*}}\"],\"generalFields\":[\"{{Doc.Date.date}}\",\"{{Doc.User.AboutMe}}\",\"{{Doc.Org.City}}\"],\"mergeTempKeys\":[\"{{Temp.a09H3000000O5RbIAK *Demo temp*}}\"],\"childRecordTables\":[{\"tableHTML\":\"<table data-name=\\\"childRecords\\\"><tbody class=\\\"\\\"><tr><td style=\\\"overflow: hidden; text-align: center;\\\">No.</td><td style=\\\"overflow: hidden; text-align: center;\\\">Account ID</td><td style=\\\"overflow: hidden; text-align: center;\\\">Created Date</td><td style=\\\"overflow: hidden; text-align: center;\\\">Last Modified Date</td></tr><tr data-name=\\\"keyRow\\\"><td style=\\\"overflow: hidden; text-align: center;\\\">{{No.Index}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!AccountId}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!CreatedDate}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!LastModifiedDate}}</td></tr><tr data-name=\\\"infoRow\\\"><td colspan=\\\"4\\\" style=\\\"position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;\\\">Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: IsDeleted = false  ORDER BY AccountId ASC $<br></td></tr></tbody></table>\",\"keyRow\":\"<tr data-name=\\\"keyRow\\\"><td style=\\\"overflow: hidden; text-align: center;\\\">{{No.Index}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!AccountId}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!CreatedDate}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!LastModifiedDate}}</td></tr>\",\"infoRow\":\"<tr data-name=\\\"infoRow\\\"><td colspan=\\\"4\\\" style=\\\"position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;\\\">Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: IsDeleted = false  ORDER BY AccountId ASC $<br></td></tr>\",\"mappingFields\":[\"{{!AccountId}}\",\"{{!CreatedDate}}\",\"{{!LastModifiedDate}}\"]}],\"signatureKeys\":[\"{{Sign.DocGenius *Signature Key*}}\"],\"salesforceImages\":[\"https://sanrafael-module-4006-dev-ed.scratch.file.force.com/sfc/dist/version/download/?oid=00DH300000017YT&ids=068H30000005jnn&d=%2Fa%2FH3000000L2eg%2FjTUXdIXBeYL1pXuV21e5ks7HNe9148cT5ERU4e1yahw&asPdf=false\"]}';
        return key;
    }
}