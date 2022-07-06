/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         01/02/2012
* Description:  TEST CLASS: OpportunityTriggerHandler
*
* ------------------
* TESTING:		100%
* ------------------
* TRIGGER:		100%
* ------------------      
**/
@isTest
private class OpportunityTriggerHandlerTest {
    
	static testMethod void chatterMessage() {
		BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
		bsiPerm.Can_Add_Opp_Products__c = true;
		update bsiPerm;
		// Set up data
        Pricebook2 pb = TestData.getPriceBook();
        Product2 prod =	TestData.getTestProduct();
		insert prod;	
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id AND Product2Id = :prod.Id];
        
		PricebookEntry pbe = TestData.getTestPriceBookEntry(prod.Id, pb.Id);
		insert pbe;				
		Account acc = TestData.getTestAccount();
		insert acc;
		Opportunity opp = TestData.getTestOpty();
		opp.AccountId = acc.Id;
		insert opp;
		// Fake the product line
		OpportunityLineItem oli = TestData.getTestOptyLine(opp.Id, pbe.Id);
		insert oli;
		
		Test.startTest();
		opp.StageName = 'Application Received'; // Step required by validation rule
		opp.WonLostComments__c = 'Test';
		opp.CreateFollowupOpp__c = 'Yes';
		update opp;
		//opp.StageName = 'Closed Won';
		//update opp;
		
		Test.stopTest();
	}
	
	static testMethod void followUp() {
		Account acc = TestData.getTestAccount();
		insert acc;
		Opportunity opp = TestData.getTestOpty();
		opp.AccountId = acc.Id;
		insert opp;
		
		Test.startTest();
		
		opp.CreateFollowupOpp__c = 'Yes';
		update opp;
		
		Test.stopTest();
	}
	
	static testMethod void businessDriversFail() {
		Account acc = TestData.getTestAccount();
		insert acc;
		Opportunity opp = TestData.getTestOpty();
		opp.AccountId = acc.Id;
		opp.BusinessDrivers__c = 'Test;Test2;Test3';
		
		Test.startTest();
		
		try {insert opp;}
		catch (Exception ex){}

		Test.stopTest();
		
		List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id =:opp.Id];
		//System.assertEquals(opps.isEmpty(), true);
	}
	
	static testMethod void rollUpTraining() {
		/*
		TESTS THAT WHEN A TRAINING PRODUCT IS ADDED TO AN OPP THEY GET ROLLED UP
		AND THE TRAINING PRODUCTS FIELD IS POPULATED
		*/
		
		BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
		bsiPerm.Can_Add_Opp_Products__c = true;
		update bsiPerm;
		// Set up data
        Pricebook2 pb = TestData.getPriceBook();
        Product2 prod =	TestData.getTestProduct();
        prod.ProductArea__c='Training';
		insert prod;	
		PricebookEntry pbe = TestData.getTestPriceBookEntry(prod.Id, pb.Id);
		insert pbe;				
		Account acc = TestData.getTestAccount();
		insert acc;
		Opportunity opp = TestData.getTestOpty();
		opp.AccountId = acc.Id;
		insert opp;
		
		Test.startTest();
		
		// Fake the product line
		OpportunityLineItem oli = TestData.getTestOptyLine(opp.Id, pbe.Id);
		insert oli;
		
		opp = [SELECT Id, NoOfTrainingProducts__c, TrainingProducts__c 
				FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
		
		system.assertEquals(1, opp.NoOfTrainingProducts__c);
		system.assertNotEquals(null, opp.TrainingProducts__c);
		
		Test.stopTest();
	}
}