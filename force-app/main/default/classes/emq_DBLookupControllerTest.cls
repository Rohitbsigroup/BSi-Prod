/**
*	Author		: Prasad JN
*	Description	: Test Class for D&B Integration
*
* ******************* Change Log *******************
*  PC K2           19-08-18    fix failed test testUpdateAddress()
*/
@isTest
public with sharing class emq_DBLookupControllerTest {
    
    static testMethod void testLookup() {
    	Account account = getAccount();
        insert account;
        
        Test.setMock(WebServiceMock.class, new emq_DBLookupProviderMock());
    	
    	Test.startTest();
    	ApexPages.StandardController stdController = new ApexPages.standardController(account);
    	emq_DBLookupController controller = new emq_DBLookupController(stdController);
    	controller.lookUp();
    	System.assertEquals(controller.LookupResults.size(), 2);
    	Test.stopTest();
    }
    
    static testMethod void testCreateAccount() {
    	Test.setMock(WebServiceMock.class, new emq_DBLookupProviderMock());
    	
    	Test.startTest();
    	emq_DBLookupController controller = new emq_DBLookupController();
    	controller.CompanyName = 'BSI Account Test';
    	controller.CountryCode = 'GB';
    	controller.lookUp();
    	System.assertEquals(controller.LookupResults.size(), 2);
		controller.SelectedDuns = controller.LookupResults[0].DUNS_NBR;
		controller.createAccount();  	
    	Test.stopTest();
    }
    
    static testMethod void testFilter() {
    	Account account = getAccount();
        insert account;
        
        Test.setMock(WebServiceMock.class, new emq_DBLookupProviderMock());
    	
    	Test.startTest();
    	ApexPages.StandardController stdController = new ApexPages.standardController(account);
    	emq_DBLookupController controller = new emq_DBLookupController(stdController);
    	controller.Filter();
    	System.assertEquals(controller.LookupResults.size(), 2);
    	Test.stopTest();
    }
    
    static testMethod void testUpdateDuns() {
    	Account account = getAccount();
        insert account;
        
        Test.setMock(WebServiceMock.class, new emq_DBLookupProviderMock());
    	
    	Test.startTest();
    	ApexPages.StandardController stdController = new ApexPages.standardController(account);
    	emq_DBLookupController controller = new emq_DBLookupController(stdController);
		controller.SelectedDuns = controller.LookupResults[0].DUNS_NBR;
		controller.UpdateDuns();
		account = [
	            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Phone, DUNS_Number__c
	            FROM   Account
	            WHERE  Id = :account.Id
	        ]; 
    	System.assertEquals(account.DUNS_Number__c, controller.LookupResults[0].DUNS_NBR);
    	Test.stopTest();
    }
    
    static testMethod void testUpdateAddress() {
    	Account account = getAccount();
        insert account;
        
        Test.setMock(WebServiceMock.class, new emq_DBLookupProviderMock());
    	
    	Test.startTest();
    	ApexPages.StandardController stdController = new ApexPages.standardController(account);
    	emq_DBLookupController controller = new emq_DBLookupController(stdController);
		controller.SelectedDuns = controller.LookupResults[0].DUNS_NBR;
        controller.CountryCode = 'GB'; //PC 18092018 fix for failed test
		controller.UpdateAddress();
		account = [
	            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Phone, DUNS_Number__c
	            FROM   Account
	            WHERE  Id = :account.Id
	        ];
    	System.assertEquals(account.Name, controller.LookupResults[0].NME);
    	System.assertEquals(account.BillingStreet, controller.LookupResults[0].ADR_LINE);
    	System.assertEquals(account.BillingCity, controller.LookupResults[0].NON_POST_TOWN);
    	System.assertEquals(account.Phone, controller.LookupResults[0].TLCM_NBR);
    	Test.stopTest();
    }
    
    static Account getAccount(){
    	Account account = new Account();
    	account.Name = 'BSI Test Account';
    	account.BillingCity = 'LONDON';
		account.BillingCountry = 'GB';
		    	
    	return account;
    }
}