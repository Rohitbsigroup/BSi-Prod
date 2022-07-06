/**
* Author:       Pawel Chrzanowski (K2)
* Date:         02/02/2021
* Description:  class to send emails for Enrollments synchronously
*
* ******************* Change Log *******************
**/

public without sharing class EnrollmentEmailServiceSync {

    public static Boolean isSendEmailFirstRun = true;
    
    public static void sendEmail(Map<String, Set<Id>> emailTypeEnrollmentIdsMap){
        System.debug('### EnrollmentEmailServiceSync.sendEmail');
        if(emailTypeEnrollmentIdsMap == null || emailTypeEnrollmentIdsMap.isEmpty()) return;
        
        if(isSendEmailFirstRun) isSendEmailFirstRun = false;
        else return;
        
        Set<Id> enrollmentIds = new Set<Id>();
        for(String emailType : emailTypeEnrollmentIdsMap.keySet()){
            enrollmentIds.addAll(emailTypeEnrollmentIdsMap.get(emailType));
        }
        
        //Enrollments
        Map<Id, Enrollment__c> enrollmentMap = new Map<Id, Enrollment__c>([
            SELECT 
                Available_In_Portal__c,
                Bookers_Email__c,
                CreatedBy.Email,
                Delegate_name__c,
                Portal_Access__c,
                Portal_Login_Link__c,
                Portal_Set_Password_Link__c,
                User_Last_Login_Date__c,
                Training_Event__r.OwnerId,
                Training_Event__r.Owner.Email,
                Training_Translations__c,
                Training_Translations__r.Additional_Emails__c,
                Training_Translations__r.Booking_Confirmation_IH_additional_SR__c,
                Training_Translations__r.CC_Training_Event_Owner__c,
                Training_Translations__r.CC_Enrollment_Creator__c,
                Training_Translations__r.From_Email_Address__c
            FROM Enrollment__c WHERE Id IN :enrollmentIds
        ]);
        System.debug('### enrollmentMap: ' + enrollmentMap);
                
        //Static Resources
        Set<String> staticResourceNames = new Set<String>();
        for(Enrollment__c e : enrollmentMap.values()){
            if(!String.isBlank(e.Training_Translations__r.Booking_Confirmation_IH_additional_SR__c)){
                staticResourceNames.addAll(e.Training_Translations__r.Booking_Confirmation_IH_additional_SR__c.deleteWhitespace().split(','));
            }
        }
        Map<String, StaticResource> staticResourceNameSRMap = new Map<String, StaticResource>();
        for(StaticResource sr : [SELECT Body, Name FROM StaticResource WHERE Name IN :staticResourceNames]){
            staticResourceNameSRMap.put(sr.Name, sr);
        }

        //OWEA email
        Map<String, Id> oweaEmailIdMap = new Map<String, Id>();
        for(OrgWideEmailAddress owea : [SELECT Address FROM OrgWideEmailAddress]){
            oweaEmailIdMap.put(owea.Address, owea.Id);
        }
        
        //VF email template Name
        Map<String, String> emailTypeTemplateMap = new Map<String, String>();
        for(Email_Template_Settings__mdt ets : [SELECT Email_Template_Unique_Name__c, Label FROM Email_Template_Settings__mdt]){
            emailTypeTemplateMap.put(ets.Label, ets.Email_Template_Unique_Name__c);
        }

        //VF email template Id
        Map<String, Id> emailTemplateIdMap = new Map<String, Id>();
        for(EmailTemplate et : [SELECT DeveloperName FROM EmailTemplate]){
            emailTemplateIdMap.put(et.DeveloperName, et.Id);
        }

        //emails
        List<Messaging.SingleEmailMessage> singleEmailList = new List<Messaging.SingleEmailMessage>();
        for(String emailType : emailTypeEnrollmentIdsMap.keySet()){
            for(Id id : emailTypeEnrollmentIdsMap.get(emailType)){
                Enrollment__c e = enrollmentMap.get(id);
                System.debug('### enrollment: ' + e);
                
                
                for(User u : [SELECT ContactId, LastLoginDate FROM User WHERE ContactId = :e.Delegate_name__c]){
                    System.debug('### User: ' + u);
                }
                
                //CC emails
                List<String> additionalEmailList = new List<String>();
                if(!String.isBlank(e.Training_Translations__r.Additional_Emails__c)){
                    additionalEmailList = e.Training_Translations__r.Additional_Emails__c.deleteWhitespace().split(',');
                }
                if(!String.isBlank(e.Bookers_Email__c)){
                    additionalEmailList.add(e.Bookers_Email__c);
                }
                if(e.Training_Translations__r.CC_Training_Event_Owner__c && e.Training_Event__r.OwnerId != null && !String.isBlank(e.Training_Event__r.Owner.Email)){
                    additionalEmailList.add(e.Training_Event__r.Owner.Email);
                }
                if(e.Training_Translations__r.CC_Enrollment_Creator__c && !String.isBlank(e.CreatedBy.Email)){
                    additionalEmailList.add(e.CreatedBy.Email);
                }
                
                //additional Static Resources
                List<String> staticResourceNameList = new List<String>();
                List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
                if(
                    ((emailType == Label.Booking_Confirmation_In_House) || (emailType == Label.Booking_Confirmation_Bespoke_In_House)) && 
                    !String.isBlank(e.Training_Translations__r.Booking_Confirmation_IH_additional_SR__c)
                ){
                    staticResourceNameList = e.Training_Translations__r.Booking_Confirmation_IH_additional_SR__c.deleteWhitespace().split(',');
                }
                for(String s : staticResourceNameList){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(s + '.pdf');
                    efa.setBody(staticResourceNameSRMap.get(s).Body);
                    attachmentList.add(efa);
                }
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setSaveAsActivity(false);
                email.setOrgWideEmailAddressId(oweaEmailIdMap.get(e.Training_Translations__r.From_Email_Address__c));
                email.setTargetObjectId(e.Delegate_name__c);
                email.setWhatId(e.Id);
                email.setTemplateId(emailTemplateIdMap.get(emailTypeTemplateMap.get(emailType)));
                if(!additionalEmailList.isEmpty()){
                    email.setCcAddresses(additionalEmailList);    
                }
                if(!attachmentList.isEmpty()){
                    email.setFileAttachments(attachmentList);
                }
                singleEmailList.add(email);
            }
        }

        if(!Test.isRunningTest() && !singleEmailList.isEmpty()){
            System.debug('### EnrollmentEmailServiceSync email size: ' + singleEmailList.size());
            Messaging.sendEmail(singleEmailList);
        }
    }
}