/********************************************************************
 * QuoteProductTriggerHandlerTest
 *
 * Test class for QuoteProductTriggerHandler
 *
 *
 * Author : ADS
 * Created: 03-10-2017
 * Changes:
 ********************************************************************/
@isTest
private class QuoteProductTriggerHandlerTest 
{
    
    // methods

    @testSetup
    private static void setUp()
    {
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();        
        final Set<String> countries = new Set<String> { 'GB', 'US', 'ES' };        
        
        final List<Product__c> testProducts = new List<Product__c>();        
        final List<Site__c> testSites = new List<Site__c>();
        
        final Account testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONFIG_QUOTE_PROD_TEST');
		final Product_Classification__c testProductClassification = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 
                                                                                                                'StreamA', 
                                                                                                                'PortfolioA', 
                                                                                                                'FamilyA');        
        final Integer recordCount = 5;
        
		for (Integer i = 0; i < recordCount; i++)
		{
			testProducts.add(bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT-' + i, 
                                                             true, 
                                                             testProductClassification.Portfolio2__c, 
                                                             testProductClassification.Family2__c, 
                                                             bg_ProductUtils.PRODUCT_TYPE_MAIN, 
                                                             countries, 
                                                             testProductClassification.Id));
			
			testSites.add(bg_UnitTestHelper.CreateSite(testAccount, 
                                                       'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + i, 															
                                                       bg_SiteUtils.COUNTRY_CODE_US, 
                                                       bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 
                                                       'CM2 ' + i + 'AB')); 
		}
        
		insert testProducts;
		insert testSites;
				
		final Opportunity testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		final Contact testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);
        
        final List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();

		for (Site__c testSite : testSites)
		{
			testOppSites.add(bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id));
		}
        
		insert testOppSites;

		final Quote__c testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);
    } // setUp
    
    @isTest
    private static void testOnAfterDelete()
    {        
        final Map<Id, Quote_Product__c> quoteProductMap = getTestQuoteProducts();
        
        Test.startTest();
        final QuoteProductTriggerHandler handler = new QuoteProductTriggerHandler(null, null);
        handler.OnAfterDelete(quoteProductMap.values(), quoteProductMap);
        Test.stopTest();
        
        //@todo: assertions

    } // testOnAfterDelete
    
    @isTest
    private static void testOnAfterUndelete()
    {
        final Map<Id, Quote_Product__c> quoteProductMap = getTestQuoteProducts();
        
        Test.startTest();
        final QuoteProductTriggerHandler handler = new QuoteProductTriggerHandler(null, null);
        handler.OnAfterUndelete(quoteProductMap.values());
        Test.stopTest();        
        
        //@todo: assertions

    } // testOnAfterUndelete
    
    @isTest
    private static void testOnAfterUpdate()
    {
        final Integer recordCount = 5;
        
		final Map<Id, Site__c> testSites = getTestSites();
		final Map<Id, Product__c> testProducts = getTestProducts();
		final Map<Id, OpportunitySite__c> testOppSites = getTestOpportunitySites();
		final Quote__c testQuote = getTestQuote();
		final Opportunity testOpportunity = getTestOpportunity();
		final Contact testContact = getTestContact();
        
        final List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();        
    	
		for (Integer i = 0; i < testSites.size(); i++)
		{
			final Site__c testSite = testSites.values()[i];
			final OpportunitySite__c testOppSite = testOppSites.values()[i];
            
			for (Integer j = 0; j < recordCount; j++)
			{
				Product__c testProduct = testProducts.values()[j];
                final Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
                testQuoteProduct.Configuration_Complete__c = true;
				testQuoteProducts.add(testQuoteProduct);
			}
            
		}
        
        insert testQuoteProducts;
        
        final List<Quote_Product__c> updateQuoteProducts = getTestQuoteProducts().values();
        
        // force a post configuration change by simulating a change in registration path
        
        if (!updateQuoteProducts.isEmpty())
        {
            updateQuoteProducts[0].Registration_Path__c = updateQuoteProducts[0].Registration_Path__c + ' changed';
        }
        
        final Map<Id, Quote_Product__c> oldQuoteProductMap = getTestQuoteProducts();

        Test.startTest();
        final QuoteProductTriggerHandler handler = new QuoteProductTriggerHandler(null, null);
        handler.OnAfterUpdate(updateQuoteProducts, oldQuoteProductMap);
        Test.stopTest();        
        
        // no quote products will be configuration complete
        
        for (Quote_Product__c quoteProduct : getTestQuoteProducts().values())
        {
            System.assert(!quoteProduct.Configuration_Complete__c);            
        }
        
    } // testOnAfterUpdate
    
	private static Map<Id, Site__c> getTestSites()
	{
        return new Map<Id, Site__c>([SELECT Id
                                    FROM Site__c]);
	} // getTestSites
    
    private static Map<Id, Product__c> getTestProducts()
    {
        return new Map<Id, Product__c>([SELECT Id
                                        FROM Product__c]);
    } // getTestProducts
    
    private static Map<Id, OpportunitySite__c> getTestOpportunitySites()
    {
        return new Map<Id, OpportunitySite__c>([SELECT Id
                                               FROM OpportunitySite__c]);        
    } // getTestOpportunitySites
    
    private static Quote__c getTestQuote()
    {
        return [SELECT Id
               FROM Quote__c
               LIMIT 1];
    } // getTestQuote
    
    private static Opportunity getTestOpportunity()
    {
        return [SELECT Id
               FROM Opportunity
               LIMIT 1];
    } // getTestOpportunity
    
    private static Contact getTestContact()
    {
        return [SELECT Id
               FROM Contact
               LIMIT 1];
    } // getTestContact
    
    private static Map<Id, Quote_Product__c> getTestQuoteProducts()
    {
        return new Map<Id, Quote_Product__c>([SELECT Id, Quote_Ref__c, Registration_Path__c, Risk_Level__c, Sampling_Applied__c, GroupNumber__c, Product_Name__c, Configuration_Complete__c
                                             FROM Quote_Product__c]);
    } // getQuoteProducts
    
} // QuoteProductTriggerHandlerTest

// file