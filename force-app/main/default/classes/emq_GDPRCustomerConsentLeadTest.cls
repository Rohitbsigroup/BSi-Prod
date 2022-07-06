/********************************************************************
 * emq_GDPRCustomerConsentLeadTest
 *
 * Test class for emq_GDPRCustomerConsentLead
 * 
 * Author	: Prasad J N
 * Created	: 24-04-2018
 ********************************************************************/
@isTest
private class emq_GDPRCustomerConsentLeadTest {
	
    static testMethod void testContactOnBeforeInsert() {
    	
    	Lead lead = TestData.getTestLead();
    	lead.GDPR_Type_of_instruction_received__c = 'Business Card';
    	lead.LeadSource = 'Marketing Channels';
    	
    	Test.startTest();
    	try {
	        insert lead;
    	} catch(Exception error) {
			System.assert(error.getMessage().contains('Please specify permitted contact method(s)'));
    	}
    	Test.stopTest();
    }
    
    static testMethod void testContactOnBeforeUpdate() {
    	
    	Lead lead = TestData.getTestLead();
        lead.GDPR_Type_of_instruction_received__c = 'Business Card';
        lead.GDPR_Permitted_contact_by_Direct_Mail__c = 'Yes';
    	insert lead;
    	
    	lead.GDPR_Type_of_instruction_received__c = 'Consent Revoked';
    	Test.startTest();
    	update lead;    	
    	lead=[Select GDPR_Permitted_contact_by_Direct_Mail__c,
    					GDPR_Permitted_contact_by_Email__c, 
    					GDPR_Permitted_contact_by_Phone__c,
    					GDPR_Permitted_contact_by_SMS__c FROM Lead WHERE Id = :lead.Id];
    	
		System.assertEquals('No', lead.GDPR_Permitted_contact_by_Direct_Mail__c);
		System.assertEquals('No', lead.GDPR_Permitted_contact_by_Email__c);
		System.assertEquals('No', lead.GDPR_Permitted_contact_by_Phone__c);
		System.assertEquals('No', lead.GDPR_Permitted_contact_by_SMS__c);
    	Test.stopTest();
    }
}