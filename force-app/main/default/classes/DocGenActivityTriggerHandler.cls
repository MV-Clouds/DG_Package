/*
*********************************************************
Apex Class Name    : DocGenActivityTriggerHandler
@description       : This class is used to send email after all the generation process completes 
@author            : Kevin Suvagiya
@last Modified     : Kevin Suvagiya - 18 Oct, 2024
*********************************************************
*/
public with sharing class DocGenActivityTriggerHandler {
/*
*********************************************************
@description     : Method is used to identify the generation process is complete and send the results to the user
@param           : updatedActivities {List<MVDG__Generate_Document_Activity__c>} - List of activities that were updated
@return          : none
********************************************************
*/
    public void onAfterUpdate( List<MVDG__Generate_Document_Activity__c> updatedActivities){
        try{
            for (MVDG__Generate_Document_Activity__c act : updatedActivities) {
                List<String> succeeded = new List<String>();
                Map<String, String> failed = new Map<String, String>();
                Integer noOfSelectedChannels = act.MVDG__Selected_Channels__c.split(',').size();
                Integer noOfCompletedhnnels = 0;
                for (String channel : act.MVDG__Selected_Channels__c.split(',')) {
                    String fieldName = 'MVDG__' + channel.replaceAll(' & ', '_').replaceAll(' ', '_') + '__c';
                    if (act.get(fieldName) == null || String.valueOf(act.get(fieldName)).trim() == ''){
                        break;
                    }else if(act.get(fieldName) == 'Success'){
                        succeeded.add(channel);
                        noOfCompletedhnnels++;
                    }else{
                        failed.put(channel, String.valueOf(act.get(fieldName)));
                        noOfCompletedhnnels++;
                    }
                }
                if(noOfCompletedhnnels == noOfSelectedChannels){
                    sendResultsEmail(succeeded, failed, new Map<String,String>{'templateId' => act.MVDG__DocGenius_Template__c , 'fileName'=> act.MVDG__File_Name__c, 'recordId' => act.MVDG__Related_Record_Id__c});
                }
            }
        }catch (Exception e){
            Log_Handler.store_Exception(e, 'DocGenActivityTriggerHandler', 'onAfterUpdate');
        }
    }

/*
*********************************************************
@description     : Method is used to send the email after the generation is complete
@param           : succeeded List<String> - List containing succeeded chanels
@param           : failed Map<String,String> - Map of failed channels with the errors
@param           : infoData Map<String, String> - Map of the templateId and the fileName to be used in the email
@return          : none
********************************************************
*/
    public static void sendResultsEmail(List<String> succeeded, Map<String,String> failed, Map<String, String> infoData){
        try {
            String templateId = infoData.get('templateId');
            String fileName = infoData.get('fileName');
            String recordId = infoData.get('recordId');
            String resultStatus = failed.size() > 0 ? 'Failed' : 'Success';
            String domainURL = URL.getOrgDomainUrl().toExternalForm().replace('my.salesforce.com', 'lightning.force.com');
            String logoUrl = 'https://mvclouds.com/assets/img/doc-genius.png';

            List<MVDG__Template__c> templates= new List<MVDG__Template__c>();
            templates = [SELECT MVDG__Template_Name__c, MVDG__Description__c, MVDG__Object_API_Name__c, MVDG__Template_Type__c FROM MVDG__Template__c WHERE Id =:templateId WITH USER_MODE LIMIT 1];

            if(templates.size() < 1){
                throw new AuraHandledException('No Template Linked With Document Generation Activity...');
            }

            templates[0].MVDG__Description__c = (templates[0].MVDG__Description__c != null ?(templates[0].MVDG__Description__c.length() > 40 ? templates[0].MVDG__Description__c.subString(0,40) + '...' : templates[0].MVDG__Description__c) : '-');
            // Template information section
            String emailBody = '<body style="font-family:Verdana, sans-serif; background-color: #00aeff10; padding:0.5rem 1rem;border-radius: 0.5rem;border: 1px solid #00aeff20;">';
            emailBody += '<p>Dear ' + UserInfo.getName() + ',</p>';
            emailBody += '<p>Greetings!</p>';    
            emailBody += '<p>The document generation process for the <b>"' +templates[0].MVDG__Template_Name__c +'"</b> has been completed. Below is a summary of the key details:</p>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">';
            emailBody += '<tr>';
            emailBody += '<th style="background-color:#00aeffaa" colspan="2"><strong>Template Details</strong></th>';
            emailBody += '</tr>';
            emailBody += '<tr>';
            emailBody += '<th bgcolor="#d5ebff"><strong>Template Name:</strong></th>';
            emailBody += '<td>' + templates[0].MVDG__Template_Name__c + '</td>';
            emailBody += '</tr>';

            emailBody += '<tr>';
            emailBody += '<th bgcolor="#d5ebff"><strong>Template Source Object:</strong></th>';
            emailBody += '<td>' + templates[0].MVDG__Object_API_Name__c + '</td>';
            emailBody += '</tr>';

            if(templates[0].MVDG__Template_Type__c != 'CSV Template' && recordId != null){
                emailBody += '<tr>';
                emailBody += '<th bgcolor="#d5ebff"><strong>Related Record Id:</strong></th>';
                emailBody += '<td><a href="' +domainURL+'/'+recordId+ '">' + recordId + '</a></td>';
                emailBody += '</tr>';
            }

            emailBody += '<tr>';
            emailBody += '<th bgcolor="#d5ebff"><strong>File Name:</strong></th>';
            emailBody += '<td>' + fileName + '</td>';
            emailBody += '</tr>';
            emailBody += '</table> <br></br>';
            // Success section
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">';
            emailBody += '<tr>';
            emailBody += '<th style="background-color:#00aeffaa" colspan="3"><strong>Document Status</strong></th>';
            emailBody += '</tr>';
            emailBody += '<tr>';
            emailBody += '<th bgcolor="#d5ebff"><strong>Option</strong></th>';
            emailBody += '<th bgcolor="#d5ebff"><strong>Status</strong></th>';
            emailBody += resultStatus=='Failed' ? '<th bgcolor="#d5ebff"><strong>Failure Message</strong></th>' : '';
            emailBody += '</tr>';
            if(succeeded.size() > 0){
                for (String item : succeeded) {
                    emailBody += '<tr>';
                    emailBody += '<td>'+ item +'</td>';
                    emailBody += '<td> Succeeded </td>';
                    emailBody += resultStatus=='Failed' ? '<td> - </td>' : '';
                    emailBody += '</tr>';
                }
            }
        
            if(failed.keySet().size() > 0){
                for (String item : failed.keySet()) {
                    emailBody += '<tr>';
                    emailBody += '<td>'+ item +'</td>';
                    emailBody += '<td> Failed </td>';
                    emailBody += '<td>' + failed.get(item) + '</td>';
                    emailBody += '</tr>';
                }
            }
            emailBody += '</table>';
            emailBody += '<p>If you have any questions or need further assistance, please feel free to visit <a href="https://mvclouds.com/docgenius/faqs/">our FAQs page</a> for quick support.</p>';
            emailBody += '<p>Regards,</p>';
            emailBody += '<p style="line-height: 0;">Team DocGenius</p>';
            emailBody += '<img width="150" alt="DocGenius-Logo" src="'+ logoUrl +'" >';
            emailBody += '</body>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] {UserInfo.getUserEmail()});
            mail.setSubject(resultStatus +' - DocGenius Generation Status');
            mail.setHtmlBody(emailBody);

            Messaging.SendEmailResult[] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            if(!result[0].isSuccess()) {
                if(Test.isRunningTest() == false){
                    throw new AuraHandledException('Email send was unsuccessfull');     
                }
            }
        }catch (Exception e){
            Log_Handler.store_Exception(e, 'DocGenActivityTriggerHandler', 'sendResultsEmail');
        }
    }
}