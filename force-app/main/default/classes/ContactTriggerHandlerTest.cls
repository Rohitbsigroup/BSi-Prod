/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         28/02/2012
* Description:  TEST CLASS: ContactTriggerHandler
*
* ------------------
* TESTING:		 86%
* ------------------
* TRIGGER:		100%
* ------------------      
**/
@isTest
private class ContactTriggerHandlerTest {
	
	// Test territory assignment
    static testMethod void accountTerritory() {
        // Set up data
        Territory__c terrC = TestData.getTestTerritory('T0','');
        terrC.Name = 'TEST UK';
        insert terrC;
        Territory__c terrP = TestData.getTestTerritory('T0','PO');
        terrP.Name = 'Patch One';
        insert terrP;
        Territory__c terrP2 = TestData.getTestTerritory('T0','ZI');
        terrP2.Name = 'Patch Two';
        insert terrP2;
       	List<Contact> cons = new List<Contact>();
       	for (Integer i=0;i<20;i++) {
       		Contact c = TestData.getTestContact();
       		c.MailingCountry = terrC.Country__c;
       		if (i <= 1) c.MailingPostalCode = 'PO STCODE' + i;
       		else c.MailingStreet = 'North End Road 2' + i;	
       		cons.add(c);
       	}
       	
       	// DML Insert
       	Test.startTest();
       	insert cons;
       	
       	// Check results
       	List<Contact> consCountry = [SELECT Territory__c FROM Contact WHERE Territory__c =:terrC.Id];
       	System.assertEquals(consCountry.size(), 18);
       	List<Contact> consPostcode = [SELECT Territory__c FROM Contact WHERE Territory__c =:terrP.Id];
       	System.assertEquals(consPostcode.size(), 2);
       	
       	for (Contact curr : consPostcode) {
       		curr.MailingPostalCode = 'ZI PCODE';
       	}
       	update consPostcode;
       	List<Contact> consZipcode = [SELECT Territory__c FROM Contact WHERE Territory__c =:terrP2.Id];
       	System.assertEquals(consZipcode.size(), 2);
       	
       	Test.stopTest();
       	
    }
}