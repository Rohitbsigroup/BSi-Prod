/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         13/01/2012
* Description:  TEST CLASS: AccountTriggerHandler
* Updates:		ASD @ BG 31/12/2013 (Have a happy new year!) Improved code coverage to 95% from 84%
*				ASD @ BG 12-01-2016 (Thank you past me!) Fixed API version to exclude test data and work with Validation Rules
* ------------------
* TESTING:		 95%
* ------------------
* TRIGGER:		100%
* ------------------      
**/
@isTest
private class AccountTriggerHandlerTest 
{
	
	// Test territory assignment (and HQ Site auto creation)
    static testMethod void accountTerritory() {
    	SiteSetting__c ss = bg_UnitTestHelper.GetSiteSettings();
    	
        // Set up data
        Territory__c terrC = TestData.getTestTerritory('GB','');
        terrC.Name = 'TEST UK';
        insert terrC;
        Territory__c terrP = TestData.getTestTerritory('GB','PO');
        terrP.Name = 'Patch One';
        insert terrP;
        Territory__c terrP2 = TestData.getTestTerritory('GB','ZI');
        terrP2.Name = 'Patch Two';
        insert terrP2;
       	List<Account> accs = new List<Account>();
       	for (Integer i=0;i<20;i++) 
       	{
       		Account a = TestData.getTestAccount();
       		a.BillingCountry = terrC.Country__c;
       		if (i <= 1) a.BillingPostalCode = 'PO STCODE' + i;
       		else a.BillingStreet = 'North End Road 2' + i;	
       		accs.add(a);
       	}
       	
       	Account ta = TestData.getTestAccount();
       	ta.BillingCountry = terrC.Country__c;
       	ta.BillingState = 'PO';
       	ta.BillingPostalCode = 'TS1 4BS';
       	ta.BillingStreet = 'North End Road 2B';	
       	accs.add(ta);
       	
       	Account ta2 = TestData.getTestAccount();
       	ta2.BillingCountry = terrC.Country__c;
       	ta2.BillingPostalCode = 'TS1 4BS';
       	ta2.BillingStreet = 'North End Road 2B';	
       	accs.add(ta2);
       	
       	Account ta3 = TestData.getTestAccount();
       	ta3.BillingCountry = 'RU';
       	ta3.BillingStreet = 'SomeStreet';	
       	accs.add(ta3);

       	
       	// DML Insert
       	Test.startTest();
       	insert accs;
       	
       	// Check results
       	List<Account> accsCountry = [SELECT Territory__c FROM Account WHERE Territory__c =:terrC.Id];
       	System.assertEquals(accsCountry.size(), 19);
       	List<Account> accsPostcode = [SELECT Territory__c FROM Account WHERE Territory__c =:terrP.Id];
       	System.assertEquals(accsPostcode.size(), 3);
       	
       	for (Account curr : accsPostcode) {
       		curr.BillingPostalCode = 'ZI PCODE';
       	}
       	update accsPostcode;
       	List<Account> accsZipcode = [SELECT Territory__c FROM Account WHERE Territory__c =:terrP2.Id];
       	System.assertEquals(accsZipcode.size(), 3);
       	
       	Test.stopTest();
       	
    }
}