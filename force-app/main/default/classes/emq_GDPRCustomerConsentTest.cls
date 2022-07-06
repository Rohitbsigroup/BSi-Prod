/********************************************************************
 * emq_GDPRCustomerConsentTest
 *
 * Test class for emq_GDPRCustomerConsent
 * 
 * Author	: Prasad J N
 * Created	: 24-04-2018
 ********************************************************************/
@isTest
private class emq_GDPRCustomerConsentTest {
	
    static testMethod void testContactOnBeforeInsert() {
    	
    	Account account = TestData.getTestAccount();
        insert account;
        
        Contact contact = TestData.getTestContact();
        contact.AccountId = account.Id;
        contact.GDPR_Type_of_instruction_received__c = 'Business Card';
    	
    	Test.startTest();
    	try {
	        insert contact;
    	} catch(Exception error) {
			System.assert(error.getMessage().contains('Please specify permitted contact method(s)'));
    	}
    	Test.stopTest();
    }
    
    static testMethod void testContactOnBeforeUpdate() {
    	
    	Account account = TestData.getTestAccount();
        insert account;
        
        Contact contact = TestData.getTestContact();
        contact.AccountId = account.Id;
        contact.GDPR_Type_of_instruction_received__c = 'Business Card';
        contact.GDPR_Permitted_contact_by_Direct_Mail__c = 'Yes';
    	insert contact;
    	
    	contact.GDPR_Type_of_instruction_received__c = 'Consent Revoked';
    	Test.startTest();
    	update contact;    	
    	contact=[Select GDPR_Permitted_contact_by_Direct_Mail__c,
    					GDPR_Permitted_contact_by_Email__c, 
    					GDPR_Permitted_contact_by_Phone__c,
    					GDPR_Permitted_contact_by_SMS__c FROM Contact WHERE Id = :contact.Id];
    	
		System.assertEquals('No', contact.GDPR_Permitted_contact_by_Direct_Mail__c);
		System.assertEquals('No', contact.GDPR_Permitted_contact_by_Email__c);
		System.assertEquals('No', contact.GDPR_Permitted_contact_by_Phone__c);
		System.assertEquals('No', contact.GDPR_Permitted_contact_by_SMS__c);
    	Test.stopTest();
    }
}