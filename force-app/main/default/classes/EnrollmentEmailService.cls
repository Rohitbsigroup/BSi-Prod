/**
* Author:       Pawel Chrzanowski (K2)
* Date:         08/08/2018
* Description:  class to send emails for Enrollments asynchronously
*
* ******************* Change Log *******************
**/

public class EnrollmentEmailService implements Queueable {

    private Set<Id> enrollmentsToEmailIdSet;
    private String emailType;
    
    public EnrollmentEmailService(Set<Id> enrollmentsToEmailIdSet, String emailType){
        this.enrollmentsToEmailIdSet = enrollmentsToEmailIdSet;
        this.emailType = emailType;
    }

    public void execute(QueueableContext context){
        if(enrollmentsToEmailIdSet.isEmpty() || String.isBlank(emailType)) return;

        //Enrollments
        List<Enrollment__c> enrollmentList = [SELECT Bookers_Email__c, CreatedBy.Email, Delegate_name__c, Training_Event__r.OwnerId, Training_Translations__c FROM Enrollment__c WHERE Id IN :enrollmentsToEmailIdSet];
        if(enrollmentList.isEmpty()) return;

        Set<Id> trainingTranslationSet = new Set<Id>();
        Set<Id> ownerSet = new Set<Id>();
        for(Enrollment__c e : enrollmentList){
            trainingTranslationSet.add(e.Training_Translations__c);
            ownerSet.add(e.Training_Event__r.OwnerId);
        }

        //Users
        Map<Id, User> userMap = new Map<Id, User>([SELECT Email FROM User WHERE Id IN :ownerSet]);

        //Training Translations
        Map<Id, Training_Translations__c> trainingTranslationMap = new Map<Id, Training_Translations__c>([SELECT Additional_Emails__c, CC_Training_Event_Owner__c, CC_Enrollment_Creator__c, Booking_Confirmation_IH_additional_SR__c, From_Email_Address__c FROM Training_Translations__c WHERE Id IN :trainingTranslationSet]);

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

        //Static Resources
        Map<String, StaticResource> staticResourceNameSRMap = new Map<String, StaticResource>();
        for(StaticResource sr : [SELECT Body, Name FROM StaticResource]){
            staticResourceNameSRMap.put(sr.Name, sr);
        }

        //email
        List<Messaging.SingleEmailMessage> singleEmailList = new List<Messaging.SingleEmailMessage>();
        for(Enrollment__c e : enrollmentList){
            //CC emails
            List<String> additionalEmailList = new List<String>();
            if(!String.isBlank(trainingTranslationMap.get(e.Training_Translations__c).Additional_Emails__c)){
                additionalEmailList = trainingTranslationMap.get(e.Training_Translations__c).Additional_Emails__c.deleteWhitespace().split(',');
            }
            if(!String.isBlank(e.Bookers_Email__c)){
                additionalEmailList.add(e.Bookers_Email__c);
            }
            if(trainingTranslationMap.get(e.Training_Translations__c).CC_Training_Event_Owner__c && userMap.get(e.Training_Event__r.OwnerId) != null && !String.isBlank(userMap.get(e.Training_Event__r.OwnerId).Email)){
                additionalEmailList.add(userMap.get(e.Training_Event__r.OwnerId).Email);
            }
            if(trainingTranslationMap.get(e.Training_Translations__c).CC_Enrollment_Creator__c && !String.isBlank(e.CreatedBy.Email)){
                additionalEmailList.add(e.CreatedBy.Email);
            }

            //additional Static Resources
            List<String> staticResourceNameList = new List<String>();
            List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
            if(
                ((emailType == Label.Booking_Confirmation_In_House) || (emailType == Label.Booking_Confirmation_Bespoke_In_House)) && 
                !String.isBlank(trainingTranslationMap.get(e.Training_Translations__c).Booking_Confirmation_IH_additional_SR__c)
            ){
                staticResourceNameList = trainingTranslationMap.get(e.Training_Translations__c).Booking_Confirmation_IH_additional_SR__c.deleteWhitespace().split(',');
            }
            for(String s : staticResourceNameList){
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(s + '.pdf');
                efa.setBody(staticResourceNameSRMap.get(s).Body);
                attachmentList.add(efa);
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSaveAsActivity(false);
            email.setOrgWideEmailAddressId(oweaEmailIdMap.get(trainingTranslationMap.get(e.Training_Translations__c).From_Email_Address__c));
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

        if(!Test.isRunningTest() && !singleEmailList.isEmpty()){
            Messaging.sendEmail(singleEmailList);
        }
    }

}