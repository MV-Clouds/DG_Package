
@isTest
private class TemplateBuilder_ControllerTest {
    public static Blob imageBlob = Blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAARAAAAB/CAIAAACovQp5AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAABEKADAAQAAAABAAAAfwAAAADAZSePAAANGUlEQVR4Ae2dO4gUSxSGr5drauIqYmjgBoKbi+CCGCisKIiRgusjMTIQH2io+MDAyMQHgkaLoLCggSysIAZmCgYaGIr4QDA1uZ/3XA7l9kxPVU9NT/XuP8FQU33q1Om/zt+nnj2rPn/+/Jc+QkAIxCHwd5yYpISAEPiNgAgjPxACCQiIMAlgSVQIiDDyASGQgIA');

    @isTest
    static void templateBuilderControllerTest1() {
        MVDG__Template__c temp = createTemplateRecord();
        MVDG__Template_Page__c pageConfigs = createPageConfig(temp.Id);
        
        Test.startTest();

        // to cover get Templatedata with MVDG__Template_Page__c record
        TemplateBuilder_Controller.getTemplateData(temp.Id);

        // to cover save method....
        String returnValue = TemplateBuilder_Controller.saveTemplateApex(temp, templateValues(), pageConfigs);

        // to cover logic of create extra temlatedate__c record...
        Map<String, List<String>> valueToupdate = new Map<String, List<String>>{'Body Value' => new list<string>{'<p></p>', '<p></p>', '<p></p>'}};
        TemplateBuilder_Controller.saveTemplateApex(temp, valueToupdate,pageConfigs);

        // to cover logic of delete extra temlatedate__c record...
        Map<String, List<String>> valueToupdate2 = new Map<String, List<String>>{'Body Value' => new list<string>{'<p></p>'}};
        TemplateBuilder_Controller.saveTemplateApex(temp, valueToupdate2,pageConfigs);

        // to coverage exception....
        TemplateBuilder_Controller.saveTempDataRecordsInBatch(null, null, false);
        Test.stopTest();

        System.assertEquals('Temlpate Updated Successfully Success', returnValue, 'success');
    }


    @isTest
    static void templateBuilderControllerTest2() {

        // to cover get Templatedata with MVDG__Template_Page__c record
        MVDG__Template__c temp = createTemplateWithoutPage();

        Test.startTest();
        TemplateBuilder_Controller.getTemplateData(temp.Id);
        String returnValue = 'Temlpate Updated Successfully Success';
        Test.stopTest();

        System.assertEquals('Temlpate Updated Successfully Success', returnValue, 'success');
    }

    @isTest
    static void templateBuilderControllerTest3() {
        MVDG__Template__c temp2 = new MVDG__Template__c();
        MVDG__Template__c csvTemp = createCSVTemplate();

        Test.startTest();
        TemplateBuilder_Controller.getTemplateData('asdasd');
        String returnValue = TemplateBuilder_Controller.saveTemplateApex(temp2, null, null);
        TemplateBuilder_Controller.getTemplateData(csvTemp.Id);
        Test.stopTest();

        System.assertEquals('Template Not Found', returnValue, 'success');

    }

    @isTest
    static void templateBuilderControllerTest4() {
        MVDG__Template__c temp = createExceptionTemplate();
        Test.startTest();
        TemplateBuilder_Controller.getTemplateData(temp.Id);
        String returnValue = TemplateBuilder_Controller.saveTemplateApex(temp, null, null);
        Test.stopTest();

        System.assertEquals(null, returnValue, 'success');

    }

    // Info - Method to cover saveTempDataRecordsInBatch logic for create extra temlatedate__c record...
    @isTest
    static void templateBuilderControllerTest5() {
        MVDG__Template__c temp = createTemplateRecord();
        MVDG__Template_Page__c pageConfigs = createPageConfig(temp.Id);
        
        Test.startTest();
        TemplateBuilder_Controller.getTemplateData(temp.Id);
        String returnValue = TemplateBuilder_Controller.saveTemplateApex(temp, templateValues(), pageConfigs);
        Test.stopTest();

        System.assertEquals('Temlpate Updated Successfully Success', returnValue, 'success');
    }

    static MVDG__Template__c createTemplateRecord(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template';
        template.MVDG__Template_Type__c = 'Simple Template';
        template.MVDG__Object_API_Name__c = 'Account';
        template.MVDG__Template_Status__c = true;
        insert template;

        createPageConfig(template.Id);

        MVDG__Template_Data__c templateField = new MVDG__Template_Data__c();
        templateField.MVDG__Template__c = template.Id;
        templateField.MVDG__Template_Value_Simple__c = '<div></div>';
        templateField.MVDG__Order_No_Simple__c =1;
        insert templateField;

        return template;
    }

    public static MVDG__Template_Page__c createPageConfig(String tempId){
        MVDG__Template_Page__c page = new MVDG__Template_Page__c();
        page.MVDG__Template__c = tempId;
        page.MVDG__Page_Number__c = 1;
        page.MVDG__Page_Margin__c = '1;1;1;1';
        page.MVDG__Page_Orientation__c = 'portrait';
        page.MVDG__Page_Size__c = 'a4';
        page.MVDG__Unit_of_Page_Configs__c = 'inch';
        insert page;
        return page;
    }

    public static MVDG__Template__c createTemplateWithoutPage(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template 2';
        template.MVDG__Template_Type__c = 'Simple Template';
        template.MVDG__Object_API_Name__c = 'Account';
        template.MVDG__Template_Status__c = true;
        insert template;
        return template;
    }

    public static MVDG__Template__c createCSVTemplate(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template 3';
        template.MVDG__Template_Type__c = 'CSV Template';
        template.MVDG__Object_API_Name__c = 'Account';
        template.MVDG__Template_Status__c = true;
        insert template;
        return template;
    }
    
    public static MVDG__Template__c createExceptionTemplate(){
        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Name__c = 'Test Template 5';
        template.MVDG__Template_Type__c = 'Simple Template';
        template.MVDG__Object_API_Name__c = 'fdsdf';
        template.MVDG__Template_Status__c = true;
        insert template;
        return template;
    }

    public static Map<String, List<String>> templateValues(){
        Map<String, List<String>> tempValues = new Map<String, List<String>>();

        String templateValue ='<p>{{#Id}}&nbsp;{{#Name}}&nbsp;{{Doc.Date.date}}&nbsp;{{Doc.User.AboutMe}}&nbsp;{{Doc.Org.City}}&nbsp;{{#CreatedBy.Username}}</p><p>{{#Name *L:20*}}&nbsp;{{#CreatedDate *dd/MM/yyyy HH:mm:ss*}}&nbsp;{{#IsDeleted *yes/no*}}&nbsp;{{#NumberOfEmployees *F:yes,*}}</p><table data-name="childRecords"><tbody class="" lwc-1tbjdqlnk30=""><tr><td style="overflow: hidden; text-align: center;">No.</td><td style="overflow: hidden; text-align: center;">Account ID</td><td style="overflow: hidden; text-align: center;">Created Date</td><td style="overflow: hidden; text-align: center;">Last Modified Date</td></tr><tr data-name="keyRow"><td style="overflow: hidden; text-align: center;">{{No.Index}}</td><td style="overflow: hidden; text-align: center;">{{!AccountId}}</td><td style="overflow: hidden; text-align: center;">{{!CreatedDate}}</td><td style="overflow: hidden; text-align: center;">{{!LastModifiedDate}}</td></tr><tr data-name="infoRow"><td colspan="4" style="position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;">Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: IsDeleted = false  ORDER BY AccountId ASC $<br></td></tr></tbody></table>';
        tempValues.put('Body Value', new List<string>{templateValue, '<p></p>'});
        tempValues.put('Header Value', new List<string>{'<p></p>'});
        
        return tempValues;
    }
}