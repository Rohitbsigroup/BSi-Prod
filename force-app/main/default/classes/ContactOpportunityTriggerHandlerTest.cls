/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         05/01/2012
* Description:  TEST CLASS: ContactOpportunityTriggerHandler
*
* ------------------
* TESTING:		100%
* ------------------
* TRIGGER:		100%
* ------------------      
**/
@isTest
private class ContactOpportunityTriggerHandlerTest {
	
	// Testing adding-updating-deleting Contact Roles
    static testMethod void syncStandardRoles() {
    	// Set up data
    	Account acc = TestData.getTestAccount();
    	insert acc;
    	Contact con = TestData.getTestContact();
    	con.AccountId = acc.Id;
    	insert con;
    	Opportunity opty = TestData.getTestOpty();
    	opty.AccountId = acc.Id;
    	insert opty;
		Contact_Opportunity__c crole = new Contact_Opportunity__c();
		crole.Contact__c = con.Id;
		crole.Opportunity__c = opty.Id;
		crole.OppRole__c = 'Role';
		OpportunityContactRole ocr = new OpportunityContactRole();
		
		Test.startTest();
		insert crole;
		ocr = [SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId =:opty.Id];
		System.assertEquals(ocr.ContactId,con.Id);
		crole.OppRole__c = 'Edited';
		update crole;
		ocr = [SELECT Role FROM OpportunityContactRole WHERE OpportunityId =:opty.Id];
		System.assertEquals(ocr.Role,'Edited');
		delete crole;
		List<OpportunityContactRole> ocrs = [SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId =:opty.Id];
		System.assertEquals(ocrs.isEmpty(),true);
		Test.stopTest();
    	   
    }
}