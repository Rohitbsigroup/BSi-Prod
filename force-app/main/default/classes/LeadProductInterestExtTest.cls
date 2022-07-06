/********************************************************************
 * LeadProductInterestExtTest
 *
 * Test methods for Lead Product Interest Extension Controller
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 ********************************************************************/
@isTest
private class LeadProductInterestExtTest {

	private static testMethod void testLeadProductInterestExt() {
		
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
		
		// create products
		Product__c productA = bg_UnitTestHelper.GetProduct('UT-ProductA', true, 'PortfolioA','ProductAreaA');
		Product__c productB = bg_UnitTestHelper.GetProduct('UT-ProductB', true, 'PortfolioB','ProductAreaB');
		Product__c productC = bg_UnitTestHelper.GetProduct('UT-ProductC', true, 'PortfolioC','ProductAreaC');
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{

			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			newLead.Portfolio_Interests__c = 'PortfolioA';
			newLead.Product_Area_Interests__c = 'ProductAreaA';
			update newLead;
			
			system.debug('**** New Lead = ' + newLead);

			// create standardcontroller
			ApexPages.StandardController sc = new ApexPages.standardController(newLead);
			
			test.startTest();
				// create LeadProductInterestExt
				LeadProductInterestExt ext = new LeadProductInterestExt(sc);
				system.assertEquals('PortfolioA', ext.leadExt.Portfolio_Interests__c);
			test.stopTest();	

		}	
	}
}