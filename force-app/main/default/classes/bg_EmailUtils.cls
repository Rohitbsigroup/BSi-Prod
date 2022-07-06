/********************************************************************
 * bg_EmailUtils
 *
 * Utility methods to support sending emails
 * 
 * Author: Alexis Lignereux
 * Created: 05-01-2015
 * Changes: 
 * 06/01/2015 - ALexis Lignereux
 *      Implemented logic for sendOnlineBookingReceived and sendConfirmationOfPlace
 *      New method getTrainingOrgWideAddress
 *      New inner class EmailWrapper
 *      Implemented logic for sendEmail
 ********************************************************************/
public with sharing class bg_EmailUtils {

/*
    private class EmailWrapper {
        String replyToAddress {get; set;}
        Id fromAddress {get; set;}
        String toAddress {get; set;}
        String cc1Address {get; set;}
        String cc2Address {get; set;}
        String subject {get; set;}
        Id targetObjectId {get; set;}
        Id whatId {get; set;}
        Id emailTemplateId {get; set;}

        public EmailWrapper() {}
    }
*/
/*
    public static void sendOnlineBookingReceived(Map<Id, TrainingBooking__c> oldMap, Map<Id, TrainingBooking__c> newMap)
    {
        List<Id> trainingBookingIds = new List<Id>();
        for (Id bookingId : newMap.keySet())
        {
        	system.debug('$$$$$ Old Value: ' + oldMap.get(bookingId).Confirmation_Emails_Sent__c);
        	system.debug('$$$$$ New Value: ' + newMap.get(bookingId).Confirmation_Emails_Sent__c);
        	if ( newMap.get(bookingId).Confirmation_Emails_Sent__c != null && oldMap.get(bookingId).Confirmation_Emails_Sent__c == null )
            {
            	system.debug('$$$$$ training booking requires email notification');
                trainingBookingIds.add(bookingId);
            }
        }

		system.debug('$$$$$ training bookings to process: ' + trainingBookingIds.size());

        if (!trainingBookingIds.isEmpty())
        {
            List<TrainingBooking__c> bookings = [ SELECT id,
                Conversion_Contact__c,
                Training_Translations__r.Reply_to_Email_Address__c,
                Training_Translations__r.cc_1_Email_Address__c,
                Training_Translations__r.cc_2_Email_Address__c,
                Training_Translations__r.From_Email_Address__c,
                Training_Translations__r.OnlineBooking_Notfn_Subject__c,
                Email_Address__c
                from TrainingBooking__c where id in :trainingBookingIds
                and Training_Translations__r.Enable_Online_Booking_Emails__c = true
            ];

            EmailTemplate template = [SELECT id 
            						  FROM EmailTemplate 
            						  WHERE DeveloperName = 'A1_Online_Booking_Received'
            						  LIMIT 1];

			system.debug('$$$$$ Email Template: ' + template);

            if (template != null && !bookings.isEmpty())
            {

                // get all fromAddresses from all training bookings
                List<String> fromAddresses = new List<String>();
                for (TrainingBooking__c booking : bookings)
                {
                    if (!bg_StringUtils.isBlank(booking.Training_Translations__r.From_Email_Address__c))
                    {
                        fromAddresses.add(booking.Training_Translations__r.From_Email_Address__c);
                    }
                }

                Map<String,Id> orgWideEmails = getTrainingOrgWideAddress(fromAddresses);

				system.debug('$$$$$ org wide emails: ' + orgWideEmails.values().size());

                if (orgWideEmails != null)
                {
                    List<EmailWrapper> emails = new List<EmailWrapper>();
                    for (TrainingBooking__c booking : bookings)
                    {
                        EmailWrapper ew = new EmailWrapper();
                        ew.emailTemplateId = template.Id;

                        if (orgWideEmails.containsKey(booking.Training_Translations__r.From_Email_Address__c))
                        {
                            ew.fromAddress = orgWideEmails.get(booking.Training_Translations__r.From_Email_Address__c);
                        }

                        ew.cc1Address = booking.Training_Translations__r.cc_1_Email_Address__c;
                        ew.cc2Address = booking.Training_Translations__r.cc_2_Email_Address__c;
                        ew.targetObjectId = booking.Conversion_Contact__c; // Is always null at point of online booking!
                        ew.whatId = booking.id;
                        ew.toAddress = booking.Email_Address__c;
                        emails.add(ew);
                    }

					system.debug('$$$$$ Emails: ' + emails.size());

                    if (!emails.isEmpty())
                    {
                    	system.debug('$$$$$ Sending Emails');
                        sendEmail(emails);
                    }
                }
            }
        }
    }
*/

/*
    public static void sendConfirmationOfPlace(Map<Id, Enrollment__c> oldMap, Map<Id, Enrollment__c> newMap)
    {
        List<Id> enrolmentIds = new List<Id>();
        for (Id enrolmentId : newMap.keySet())
        {
            if ( newMap.get(enrolmentId).Email_Confirmation_Sent__c == true && oldMap.get(enrolmentId).Email_Confirmation_Sent__c == false )
            //if ( newMap.get(enrolmentId).Email_Confirmation_Sent__c == true)
            {
                enrolmentIds.add(enrolmentId);
            }
        }

        if (!enrolmentIds.isEmpty())
        {
            List<Enrollment__c> enrolments = [ SELECT Id,
                Delegate_name__c,
                Delegate_Email__c,
                Training_Translations__r.Reply_to_Email_Address__c,
                Training_Translations__r.cc_1_Email_Address__c,
                Training_Translations__r.cc_2_Email_Address__c,
                Training_Translations__r.From_Email_Address__c
                from Enrollment__c
                where id in :enrolmentIds
                and Training_Translations__r.Enable_Confirmation_of_Place_Emails__c  = true
            ];

            EmailTemplate template = null;
            
            template = [SELECT Id 
					    FROM EmailTemplate 
					    //WHERE DeveloperName = 'X2_Confirmation_of_Place'
					    WHERE DeveloperName = 'A2_Confirmation_of_Place'
					    LIMIT 1];

            if (!enrolments.isEmpty() && template != null)
            {

                // get all fromAddresses from all enrolments
                List<String> fromAddresses = new List<String>();
                for (Enrollment__c enrolment : enrolments)
                {
                    if (!bg_StringUtils.isBlank(enrolment.Training_Translations__r.From_Email_Address__c))
                    {
                        fromAddresses.add(enrolment.Training_Translations__r.From_Email_Address__c);
                    }
                }

                Map<String,Id> orgWideEmails = getTrainingOrgWideAddress(fromAddresses);

                if (orgWideEmails != null)
                {

                    List<EmailWrapper> emails = new List<EmailWrapper>();
                    for(Enrollment__c enrolment : enrolments)
                    {
                        EmailWrapper ew = new EmailWrapper();
                        ew.emailTemplateId = template.Id;

                        if (orgWideEmails.containsKey(enrolment.Training_Translations__r.From_Email_Address__c))
                        {
                            ew.fromAddress = orgWideEmails.get(enrolment.Training_Translations__r.From_Email_Address__c);
                        }
						ew.toAddress = enrolment.Delegate_Email__c;
                        ew.cc1Address = enrolment.Training_Translations__r.cc_1_Email_Address__c;
                        ew.cc2Address = enrolment.Training_Translations__r.cc_2_Email_Address__c;
                        ew.targetObjectId = enrolment.Delegate_name__c;
                        ew.whatId = enrolment.id;
                        emails.add(ew);
                    }

                    if (!emails.isEmpty())
                    {
                        sendEmail(emails);
                    }
                }
            }
        }
    }
*/

/*
    public static void sendEmail(List<EmailWrapper> emails)
    {
        if (!emails.isEmpty())
        {
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

            for (EmailWrapper ew : emails)
            {
                // new email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                //mail.setCharset('utf-8');

                // don't need to set the subject, replyTo and boby as this is on the VF email template

                // from address - need to have the from address on training translation as a
                // org wide email address and then overrite the it on the email
                mail.setOrgWideEmailAddressId(ew.fromAddress);

				//set recipient
				List<String> toAddressess = new List<String>();
				toAddressess.add(ew.toAddress);
				mail.setToAddresses(toAddressess);

                //set list of people who should be CC'ed
                List<String> ccTo = new List<String>();
                if (!bg_StringUtils.isBlank(ew.cc1Address))
                {
                    ccTo.add(ew.cc1Address);
                }

                if (!bg_StringUtils.isBlank(ew.cc1Address))
                {
                    ccTo.add(ew.cc2Address);
                }

                if (!ccTo.isEmpty())
                {
                    mail.setCcAddresses(ccTo);
                }

                // get email template
                mail.setTemplateId(ew.emailTemplateId);

                // set targetObjectId and whatId
                mail.setTargetObjectId(ew.targetObjectId);
                mail.setWhatId(ew.whatId);
                mail.setSaveAsActivity(false);

                mails.add(mail);
            }

            if (!mails.isEmpty() && !Test.isRunningTest())
            {
                // send emails
                Messaging.sendEmail(mails);
            }
        }
    }
*/

/*
    public static Map<String,Id> getTrainingOrgWideAddress(List<String> emails)
    {
        List<OrgWideEmailAddress> owea = [select Id, Address from OrgWideEmailAddress where Address in :emails];
        Map<String,Id> results = new Map<String,Id>();
        if (!owea.isEmpty())
        {
            for(OrgWideEmailAddress email : owea)
            {
                results.put(email.address, email.Id);
            }
        }

        if (!results.isEmpty())
        {
            return results;
        }
        else
        {
            return null;
        }
    }
*/    
}