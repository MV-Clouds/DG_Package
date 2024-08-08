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
private class HomePageControllerTest {

    @isTest
    static void getTemplateListTEST() {
        Test.startTest();
        String tempId = createTemplateRecord().Id;
        HomePageController.getTemplateList();
        String returnValue = HomePageController.updateTemplate(tempId, true);
        HomePageController.deleteTemplate(tempId);
        Test.stopTest();

        System.assertEquals('updated', returnValue, 'success');

    }

    @isTest
    static void getTemplateListTEST2() {
        Test.startTest();
        HomePageController.getTemplateList();
        String returnValue = HomePageController.updateTemplate('dfgdfg', true);
        HomePageController.deleteTemplate('asdasd');
        Test.stopTest();

        System.assertEquals('no Template Found', returnValue, 'success');

    }

    @isTest
    static void getTemplateListTEST3() {
        // for exception...
        Test.startTest();
        MVDG__Template__c temp = createTemplateRecord();
        temp.MVDG__Object_API_Name__c = 'asfasf';
        update temp;
        HomePageController.getTemplateList();
        String returnValue = HomePageController.updateTemplate('dfgdfg', true);

        HomePageController.createTempFieldInstance(null);
        Log_Handler.store_Exception(null, null, null);
        Test.stopTest();

        System.assertEquals('no Template Found', returnValue, 'success');

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
        templateField.MVDG__Template_Value_Simple__c = templateValue;
        templateField.MVDG__Order_No_Simple__c =1;
        insert templateField;

        return template;
    }

    public static string templateValue(){
        String templateValue ='<p>{{#Id}}&nbsp;{{#Name}}&nbsp;{{Doc.Date.date}}&nbsp;{{Doc.User.AboutMe}}&nbsp;{{Doc.Org.City}}&nbsp;{{#CreatedBy.Username}}</p><p>{{#Name *L:20*}}&nbsp;{{#CreatedDate *dd/MM/yyyy HH:mm:ss*}}&nbsp;{{#IsDeleted *yes/no*}}&nbsp;{{#NumberOfEmployees *F:yes,*}}</p><table data-name="childRecords"><tbody class="" lwc-1tbjdqlnk30=""><tr><td style="overflow: hidden; text-align: center;">No.</td><td style="overflow: hidden; text-align: center;">Account ID</td><td style="overflow: hidden; text-align: center;">Created Date</td><td style="overflow: hidden; text-align: center;">Last Modified Date</td></tr><tr data-name="keyRow"><td style="overflow: hidden; text-align: center;">{{No.Index}}</td><td style="overflow: hidden; text-align: center;">{{!AccountId}}</td><td style="overflow: hidden; text-align: center;">{{!CreatedDate}}</td><td style="overflow: hidden; text-align: center;">{{!LastModifiedDate}}</td></tr><tr data-name="infoRow"><td colspan="4" style="position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;">Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: IsDeleted = false  ORDER BY AccountId ASC $<br></td></tr></tbody></table>';
        return templateValue;
    }
}