/********************************************************************
 * 
 * Trigger to check GDPR Customer Consent is provided and 
 * 
 * Author   : Prasad J N
 * Created  : 24-04-2018
 ********************************************************************/
trigger emq_GDPRCustomerConsentLead on Lead (before insert, before update) {
    if(Trigger.isBefore)
    {
        List<Lead> contList = new List<Lead>();
        
        if(Trigger.IsInsert)
        {
            Lead lead = Trigger.New[0];
            
            if(lead.GDPR_Type_of_instruction_received__c != null)
                lead.GDPR_Date_instruction_received__c = Datetime.now();
        }
        else if(Trigger.IsUpdate)
        {
            Lead lead = Trigger.New[0];
            Lead oldLead = Trigger.Old[0];
            
            //Check if Type of instruction received is changed and update the 
            // date of instruction received timestamp
            if(oldLead.GDPR_Type_of_instruction_received__c == null
                && lead.GDPR_Type_of_instruction_received__c != null){
                lead.GDPR_Date_instruction_received__c = Datetime.now();
            }
            else if(lead.GDPR_Type_of_instruction_received__c != null &&
                !lead.GDPR_Type_of_instruction_received__c.equals(oldLead.GDPR_Type_of_instruction_received__c)){
                lead.GDPR_Date_instruction_received__c = Datetime.now();
            }
            
            // Check if consent is revoked and set all fields to NO
            if(lead.GDPR_Type_of_instruction_received__c != null && 
                lead.GDPR_Type_of_instruction_received__c == 'Consent Revoked'){
                lead.GDPR_Permitted_contact_by_Direct_Mail__c = 'No';
                lead.GDPR_Permitted_contact_by_Email__c = 'No';
                lead.GDPR_Permitted_contact_by_Phone__c = 'No';
                lead.GDPR_Permitted_contact_by_SMS__c = 'No';
            }
            else if(lead.GDPR_Type_of_instruction_received__c != null
            		&& lead.GDPR_Type_of_instruction_received__c != 'Electronic Form'){
                // Check if type is instruction received is other than Consent Revoked then any one type
                // of communication should be allowed
                if((lead.GDPR_Permitted_contact_by_Direct_Mail__c == null || lead.GDPR_Permitted_contact_by_Direct_Mail__c == 'No') &&
                    (lead.GDPR_Permitted_contact_by_Email__c ==  null || lead.GDPR_Permitted_contact_by_Email__c == 'No') && 
                    (lead.GDPR_Permitted_contact_by_Phone__c == null || lead.GDPR_Permitted_contact_by_Phone__c == 'No') &&
                    (lead.GDPR_Permitted_contact_by_SMS__c ==  null || lead.GDPR_Permitted_contact_by_SMS__c == 'No')){
                        lead.addError('Please specify permitted contact method(s)');
                    }
            }
            else if(lead.GDPR_Type_of_instruction_received__c == null){
                lead.GDPR_Permitted_contact_by_Direct_Mail__c = '';
                lead.GDPR_Permitted_contact_by_Email__c = '';
                lead.GDPR_Permitted_contact_by_Phone__c = '';
                lead.GDPR_Permitted_contact_by_SMS__c = '';
                lead.GDPR_Date_instruction_received__c = null;
            }
        }
    }
}