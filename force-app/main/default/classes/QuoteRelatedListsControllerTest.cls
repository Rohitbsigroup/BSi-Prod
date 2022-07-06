/********************************************************************
 * QuoteRelatedListsControllerTest 
 *
 * Test class for QuoteRelatedListsController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 22-10-2013
 * Changes: 
 ********************************************************************/
@isTest 
private class QuoteRelatedListsControllerTest {

    private static testMethod void testQuoteRelatedListsController() {
		/*
			Test QuoteRelatedListsController Class
		*/		
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		
		test.startTest();
			QuoteRelatedListsController controller = new QuoteRelatedListsController(new Apexpages.Standardcontroller(quote));
			system.assertNotEquals(null, controller.getPageURL());
	    	system.assertEquals(true, controller.quoteProducts.size()>0);
			controller.ConfigurePrices();
		test.stopTest();
    } 
}