/********************************************************************
 * OpportunityProductInterestExtTest
 *
 * Test methods for Opportunity Product Interest Extension Controller
 * 
 * 
 * Author: Rob Earey
 * Created: 22-10-2013
 * Changes: 
 ********************************************************************/
@isTest
public with sharing class OpportunityProductInterestExtTest 
{

	private static testMethod void testOppProductInterestExt() {
		
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
		
		// create products
		Product__c productA = bg_UnitTestHelper.GetProduct('UT-ProductA', true, 'PortfolioA','ProductAreaA');
		Product__c productB = bg_UnitTestHelper.GetProduct('UT-ProductB', true, 'PortfolioB','ProductAreaB');
		Product__c productC = bg_UnitTestHelper.GetProduct('UT-ProductC', true, 'PortfolioC','ProductAreaC');
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{

			// create account
			Account newAcc = bg_UnitTestHelper.GetAccount('TestAcc1');
			// create opportunity
			Opportunity newOpp = bg_UnitTestHelper.GetOpportunity(newAcc);
			newOpp.Portfolio_Interests__c = 'PortfolioA';
			newOpp.Product_Area_Interests__c = 'ProductAreaA';
			update newOpp;
			
			system.debug('**** New Opportunity = ' + newOpp);

			// create standardcontroller
			ApexPages.StandardController sc = new ApexPages.standardController(newOpp);
			
			test.startTest();
				// create OpportunityProductInterestExt
				OpportunityProductInterestExt ext = new OpportunityProductInterestExt(sc);
				system.assertEquals('PortfolioA', ext.oppExt.Portfolio_Interests__c);
			test.stopTest();	

		}	
	}
}