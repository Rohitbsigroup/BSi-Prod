/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         07/12/2011
* Description:  TEST CLASS: OpportunityLineItemTriggerHandler
*
* ------------------
* TESTING:		100%
* ------------------
* TRIGGER:		100%
* ------------------      
**/
@isTest
private class OpportunityLineItemTriggerHandlerTest {

/*	RJ: CURRENTLY NOT USED
	// Testing adding-deleting opportunity line items
    static testMethod void lineFamilyOpty() {
        // Set up data
        Pricebook2 pb = TestData.getPriceBook();
        List<Product2> plist = new List<Product2>();
        Product2 iso2 =	TestData.getTestProduct();
        Product2 iso4 =	TestData.getTestProduct();
        Product2 iso8 =	TestData.getTestProduct();
        iso2.ShortName__c = 'ISO 2000';
        iso4.ShortName__c = 'ISO 14001';
        iso8.ShortName__c = 'ISO 18002';
		plist.add(iso2);
		plist.add(iso4);
		plist.add(iso8);      
		insert plist;	
		List<PricebookEntry> pbelist = new List<PricebookEntry>();
		PricebookEntry pbe2 = TestData.getTestPriceBookEntry(iso2.Id, pb.Id);
		PricebookEntry pbe4 = TestData.getTestPriceBookEntry(iso4.Id, pb.Id);
		PricebookEntry pbe8 = TestData.getTestPriceBookEntry(iso8.Id, pb.Id);
		pbelist.add(pbe2);
		pbelist.add(pbe4);
		pbelist.add(pbe8);
		insert pbelist;
		
        Account acc = TestData.getTestAccount();
        insert acc;
        Opportunity opty = TestData.getTestOpty();
        opty.AccountId = acc.Id;
        opty.Pricebook2Id = pb.Id;
        insert opty;
		Opportunity opty2 = TestData.getTestOpty();
        opty2.AccountId = acc.Id;
        opty2.Pricebook2Id = pb.Id;
        insert opty2;		
		
		List<OpportunityLineItem> ols = new List<OpportunityLineItem>();
		for (Integer i = 0; i < 20; i ++) {
			OpportunityLineItem oli = TestData.getTestOptyLine(opty.Id, pbe2.Id);
			//oli.ShortName__c = 'ISO 2000';
			ols.add(oli);
		}
		for (Integer i = 0; i < 20; i ++) {
			OpportunityLineItem oli = TestData.getTestOptyLine(opty.Id, pbe4.Id);
			//oli.ShortName__c = 'ISO 14001';
			ols.add(oli);
		}
		for (Integer i = 0; i < 20; i ++) {
			OpportunityLineItem oli = TestData.getTestOptyLine(opty2.Id, pbe4.Id);
			//oli.ShortName__c = 'ISO 14001';
			ols.add(oli);
		}
		// One single Line for delete test
		OpportunityLineItem oli = TestData.getTestOptyLine(opty.Id, pbe8.Id);
		//oli.ShortName__c = 'ISO 18002';
		ols.add(0,oli);
		
		Test.startTest();
		// INSERTING
		insert ols;
        
        // Check expected results
        Opportunity o = [SELECT Id, ProductFamily__c FROM Opportunity WHERE Id =:opty.Id];
        System.assertEquals(o.ProductFamily__c.contains('ISO 2000'),true);
        System.assertEquals(o.ProductFamily__c.contains('ISO 14001'),true);
        
        // DELETING ONE LINE
        OpportunityLineItem del = ols.get(0);
        ols.remove(0);
        delete del;
        o = [SELECT Id, ProductFamily__c FROM Opportunity WHERE Id =:opty.Id];
        System.assertEquals(o.ProductFamily__c.contains('ISO 2000'),true);
        System.assertEquals(o.ProductFamily__c.contains('ISO 14001'),true);
        System.assertEquals(o.ProductFamily__c.contains('ISO 18002'),false);
        
        // DELETING ALL
        delete ols;
        
        // Check expected results
        o = [SELECT Id, ProductFamily__c FROM Opportunity WHERE Id =:opty.Id];
        System.assertEquals(o.ProductFamily__c,null);
        
        Test.stopTest();
    }
*/    
}