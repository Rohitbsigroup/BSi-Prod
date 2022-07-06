/********************************************************************
 * 
 * Trigger to check GDPR Customer Consent is provided and 
 * 
 * Author   : Prasad J N
 * Created  : 24-04-2018
 ********************************************************************/
trigger emq_GDPRCustomerConsent on Contact (before insert, before update) {
    if(Trigger.isBefore)
    {
        List<Contact> contList = new List<Contact>();
        
        if(Trigger.IsInsert)
        {
            Contact contact = Trigger.New[0];
            
            if(contact.GDPR_Type_of_instruction_received__c != null)
                contact.GDPR_Date_instruction_received__c = Datetime.now();
        }
        else if(Trigger.IsUpdate)
        {
            Contact contact = Trigger.New[0];
            Contact oldContact = Trigger.Old[0];
            
            //Check if Type of instruction received is changed and update the 
            // date of instruction received timestamp
            if(oldContact.GDPR_Type_of_instruction_received__c == null
                && contact.GDPR_Type_of_instruction_received__c != null){
                contact.GDPR_Date_instruction_received__c = Datetime.now();
            }
            else if(contact.GDPR_Type_of_instruction_received__c != null &&
                !contact.GDPR_Type_of_instruction_received__c.equals(oldContact.GDPR_Type_of_instruction_received__c)){
                contact.GDPR_Date_instruction_received__c = Datetime.now();
            }
            
            // Check if consent is revoked and set all fields to NO
            if(contact.GDPR_Type_of_instruction_received__c != null && 
                contact.GDPR_Type_of_instruction_received__c == 'Consent Revoked'){
                contact.GDPR_Permitted_contact_by_Direct_Mail__c = 'No';
                contact.GDPR_Permitted_contact_by_Email__c = 'No';
                contact.GDPR_Permitted_contact_by_Phone__c = 'No';
                contact.GDPR_Permitted_contact_by_SMS__c = 'No';
            }
            else if(contact.GDPR_Type_of_instruction_received__c != null &&
            		contact.GDPR_Type_of_instruction_received__c != 'Electronic Form'){
                // Check if type is instruction received is other than Consent Revoked & Electronic Form then any one type
                // of communication should be allowed
                if((contact.GDPR_Permitted_contact_by_Direct_Mail__c == null || contact.GDPR_Permitted_contact_by_Direct_Mail__c == 'No') &&
                    (contact.GDPR_Permitted_contact_by_Email__c ==  null || contact.GDPR_Permitted_contact_by_Email__c == 'No') && 
                    (contact.GDPR_Permitted_contact_by_Phone__c == null || contact.GDPR_Permitted_contact_by_Phone__c == 'No') &&
                    (contact.GDPR_Permitted_contact_by_SMS__c ==  null || contact.GDPR_Permitted_contact_by_SMS__c == 'No')){
                        contact.addError('Please specify permitted contact method(s)');
                    }
            }
            else if(contact.GDPR_Type_of_instruction_received__c == null){
                contact.GDPR_Permitted_contact_by_Direct_Mail__c = '';
                contact.GDPR_Permitted_contact_by_Email__c = '';
                contact.GDPR_Permitted_contact_by_Phone__c = '';
                contact.GDPR_Permitted_contact_by_SMS__c = '';
                contact.GDPR_Date_instruction_received__c = null;
            }
        }
    }
}