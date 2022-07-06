/********************************************************************
 * bg_QuoteProductUtilsTest
 *
 * Test methods for Quote Product Utility class
 * 
 * 
 * Author: Chris Eales
 * Created: 06-09-2017
 * Changes: 
 *		    
 *			02-10-2017 - RC - Added new unit tests to cover MatchPhaseWithProjectGroupNumber
 ********************************************************************/
@isTest
private class bg_QuoteProductUtilsTest 
{

	/*
		Test data setup method and class member variables for use in tests
	*/
	
	@testSetup
	static void setupTestData()
	{
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONFIG_QUOTE_PROD_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT-' + iterator, true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
			testProducts.add(testProduct);
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testProducts;
		insert testSites;
		
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);
		
	}
	
	/* 
		resuable method to retrieve the test sites
	*/
	private static Map<Id, Site__c> GetTestSites()
	{
		Map<Id, Site__c> results = new Map<Id, Site__c>();
		results.putAll([SELECT	Id, Name, Account__c, Type__c, Country_Code__c, TCodeDescr__c, Postcode__c, RecordTypeId
						FROM	Site__c]);
						//WHERE	CreatedDate = :Date.today()]);
	
		return results;	
	} 

	/* 
		resuable method to retrieve the test products 
	*/
	private static Map<Id, Product__c> GetTestProducts()
	{
		Map<Id, Product__c> results = new Map<Id, Product__c>();
		results.putAll([SELECT	Id, Name, Active__c, Product_Stream__c, Product_SubStream__c, Portfolio_Interest__c, Product_Area_Interest__c,
								Active_In_SF__c, Product_Type__c, CCode__c, RegistrationPaths__c, Country__c, Product_Classification__c
						FROM	Product__c]);
						//WHERE	CreatedDate = :Date.today()]);
	
		return results;	
	} 

	/* 
		resuable method to retrieve the test opp sites
	*/
	private static Map<Id, OpportunitySite__c> GetTestOpportunitySites()
	{
		Map<Id, OpportunitySite__c> results = new Map<Id, OpportunitySite__c>();
		results.putAll([SELECT	Id, Name, Opportunity__c, Site__c, HQ__c 
						FROM	OpportunitySite__c]);
						//WHERE	CreatedDate = :Date.today()]);

		return results;	
	} 
	
	/* 
		resuable method to retrieve the test Quote
	*/
	private static Quote__c GetTestQuote()
	{
		Quote__c result;
		result = [SELECT	Id, Name,  Opportunity_Name__c, CurrencyIsoCode, Contact__c, Booking__c, CreditCheck__c,
							Invoice_Contact__c, PriceBook2Id__c
				  FROM	Quote__c
				  //WHERE	CreatedDate = :Date.today()
				  LIMIT 1];

		return result;	
	} 

	/* 
		resuable method to retrieve the test Opportunity
	*/
	private static Opportunity GetTestOpportunity()
	{
		Opportunity result;
		result = [SELECT	Id, Name,  StageName, CloseDate, Product_Interests__c, AccountId
				  FROM	Opportunity
				  //WHERE	CreatedDate = :Date.today()
				  LIMIT 1];

		return result;	
	} 

	/* 
		resuable method to retrieve the test Contact
	*/
	private static Contact GetTestContact()
	{
		Contact result;
		result = [SELECT	Id, FirstName,  LastName, MailingCountry, Email, RecordTypeId, AccountId
				  FROM	Contact
				  //WHERE	CreatedDate = :Date.today()
				  LIMIT 1];

		return result;	
	} 

	/*
	* Test for checking that projects get matched up with phases by group numbers.
	*/

	static testMethod void testProjectMatchWithPhase()
	{
	
		Test.startTest();

		Map<Id, Site__c> testSites = GetTestSites();
		Map<Id, Product__c> testProducts = GetTestProducts();
		Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

		Product__c testProduct = testProducts.values()[0];
		Site__c testSite = testSites.values()[0];
		OpportunitySite__c testOppSite = testOppSites.values()[0];

		//create a project
		Account acc = [Select Id FROM Account];

		Project__c prj = bg_UnitTestHelper.CreateProject(acc.Id, 'Test project', true); 
		insert prj;

		//create a quote Product linked to a project
		Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
		testQuoteProduct.Project__c = prj.Id;
		testQuoteProduct.GroupNumber__c = 1;
		insert testQuoteProduct;

		//create another one and set it as a phase and set as different group number.
		Product__c testProduct2 = testProducts.values()[1];
		Site__c testSite2 = testSites.values()[1];
		OpportunitySite__c testOppSite2 = testOppSites.values()[1];

		Quote_Product__c testQuoteProduct2 = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct2, testSite2, testOpportunity, testOppSite2);
		insert testQuoteProduct2;

		Test.stopTest();

		//query out the 2nd quote product and call and update.
		Quote_Product__c qpQueryUpdate = [select Id, Project__c, GroupNumber__c, Is_Project_Phase__c 
		FROM Quote_Product__c WHERE Id =:testQuoteProduct2.Id];
		qpQueryUpdate.Project__c = prj.Id;
		qpQueryUpdate.Is_Project_Phase__c = true;
		qpQueryUpdate.GroupNumber__c = 2;
		update qpQueryUpdate;


		Set<Id> quoteProductsIds = new Set<Id>();
		quoteProductsIds.add(testQuoteProduct.Id);

		bg_QuoteProductUtils.MatchPhaseWithProjectGroupNumber(quoteProductsIds);

		//query out the quote phase to see that group number is now matched with the group number from testquoteProduct.
		Quote_Product__c qpQuery = [select Id, GroupNumber__c FROM Quote_Product__c WHERE Id =:testQuoteProduct2.Id];
		System.assertEquals(1, qpQuery.GroupNumber__c);

	}

    
    /*
    	Test for method getConfiguredQuoteProductsByOpportunitySiteIds
    	Empty oppSiteIds parameter
    */
    static testMethod void testgetConfiguredQuoteProductsByOpportunitySiteIdsEmpty()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
    	Map<Id, List<Quote_Product__c>> results;
    	List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
    	Integer productCount = 5;
    	
		Map<Id, Site__c> testSites = GetTestSites();
		Map<Id, Product__c> testProducts = GetTestProducts();
		Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();
    	
    	//ensure quote product data exists to confirm method is responding as expected
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProducts.add(testQuoteProduct);
			}
		}
		insert testQuoteProducts;

    	results = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(oppSiteIds);
    	
    	system.assertEquals(true, results != null);
    	system.assertEquals(true, results.isEmpty());
    }

     /*
    	Test for method getConfiguredQuoteProductsByOpportunitySiteIds
    	NULL oppSiteIds parameter
    */
    static testMethod void testgetConfiguredQuoteProductsByOpportunitySiteIdsNull()
    {
    	Set<Id> oppSiteIds = null;
    	Map<Id, List<Quote_Product__c>> results;
    	List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
    	
    	Integer productCount = 5;
    	
    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
    	Quote__c testQuote = GetTestQuote();
    	Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();
    	
    	//ensure quote product data exists to confirm method is responding as expected
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProducts.add(testQuoteProduct);
			}
		}
		insert testQuoteProducts;

    	results = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(oppSiteIds);
    	
    	system.assertEquals(true, results != null);
    	system.assertEquals(true, results.isEmpty());
    }


     /*
    	Test for method getConfiguredQuoteProductsByOpportunitySiteIds
    	Single oppSiteIds parameter - No Quote Products - ensures the OppSiteId is in the map but empty list returned
    */
    static testMethod void testgetConfiguredQuoteProductsByOpportunitySiteIdsNoProduct()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 5;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Map<Id, List<Quote_Product__c>> results;
    	Id testOppSiteId = testOppSites.values()[0].Id;
		oppSiteIds.add(testOppSiteId);
		
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			if (testOppSiteId != testOppSiteId) //Adds Quote Products to all Opp Sites except the one we are testing
			{
				for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
				{
					Product__c testProduct = testProducts.values()[prodIterator];
					Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
					testQuoteProduct.Configuration_Complete__c = true;
					testQuoteProducts.add(testQuoteProduct);
				}
			}
		}
		insert testQuoteProducts;
    	
    	results = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(1, results.size());
    	system.assertEquals(true, results.containsKey(testOppSiteId));
    	system.assertEquals(true, results.get(testOppSiteId).isEmpty());
    }

     /*
    	Test for method getConfiguredQuoteProductsByOpportunitySiteIds
    	Single oppSiteIds parameter - single Quote Product
    */
    static testMethod void testgetConfiguredQuoteProductsByOpportunitySiteIdsSingle()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 1;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Map<Id, List<Quote_Product__c>> results;
    	Id testOppSiteId = testOppSites.values()[0].Id;
		oppSiteIds.add(testOppSiteId);
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProduct.Configuration_Complete__c = true;
				testQuoteProducts.add(testQuoteProduct);
			}
		}
		insert testQuoteProducts;
		
    	
    	results = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(1, results.size());
    	system.assertEquals(true, results.containsKey(testOppSiteId));
    	system.assertEquals(productCount, results.get(testOppSiteId).size());
    }


     /*
    	Test for method getConfiguredQuoteProductsByOpportunitySiteIds
    	Single oppSiteIds parameter - multi Quote Product
    */
    static testMethod void testgetConfiguredQuoteProductsByOpportunitySiteIdsMulti()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 5;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Map<Id, List<Quote_Product__c>> results;
    	Id testOppSiteId = testOppSites.values()[0].Id;
		oppSiteIds.add(testOppSiteId);
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProduct.Configuration_Complete__c = true;
				testQuoteProducts.add(testQuoteProduct);
			}
		}
		insert testQuoteProducts;
		
    	
    	results = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(1, results.size());
    	system.assertEquals(true, results.containsKey(testOppSiteId));
    	system.assertEquals(productCount, results.get(testOppSiteId).size());
    }


     /*
    	Test for method getConfiguredQuoteProductsByOpportunitySiteIds
    	Single oppSiteIds parameter - multi Quote Product Mixed Configuration
    */
    static testMethod void testgetConfiguredQuoteProductsByOpportunitySiteIdsMixedConfiguration()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 5;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Map<Id, List<Quote_Product__c>> results;
    	Id testOppSiteId = testOppSites.values()[0].Id;
		oppSiteIds.add(testOppSiteId);
		
		Map<Id, Integer> configCount = new Map<Id, Integer>();
		Boolean configComplete = false;
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			if (!configCount.containsKey(testOppSite.Id))
			{
				configCount.put(testOppSite.Id, 0);
			}
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				if (configComplete)
				{
					configCount.put(testOppSite.Id, configCount.get(testOppSite.Id)+1);
				}
				testQuoteProduct.Configuration_Complete__c = configComplete;
				testQuoteProducts.add(testQuoteProduct);
				configComplete = !configComplete;
			}
		}
		insert testQuoteProducts;
		
    	
    	results = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(1, results.size());
    	system.assertEquals(true, results.containsKey(testOppSiteId));
    	system.assertEquals(configCount.get(testOppSiteId), results.get(testOppSiteId).size());
    }



     /*
    	Test for method getConfiguredQuoteProductsByOpportunitySiteIds
    	multiple oppSiteIds parameter - multi Quote Product Mixed Configuration
    */
    static testMethod void testgetConfiguredQuoteProductsByOpportunitySiteIdsMultiMixedConfiguration()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 5;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Map<Id, List<Quote_Product__c>> results;

		Map<Id, Integer> configCount = new Map<Id, Integer>();
		Boolean configComplete = false;
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			if (!configCount.containsKey(testOppSite.Id))
			{
				configCount.put(testOppSite.Id, 0);
			}
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				if (configComplete)
				{
					configCount.put(testOppSite.Id, configCount.get(testOppSite.Id)+1);
				}
				testQuoteProduct.Configuration_Complete__c = configComplete;
				testQuoteProducts.add(testQuoteProduct);
				configComplete = !configComplete;
			}
			oppSiteIds.add(testOppSite.Id);
			
		}
		insert testQuoteProducts;
		
    	
    	results = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(testOppSites.size(), results.size());
    	for (Id testOppSiteId : testOppSites.keySet())
    	{
	    	system.assertEquals(true, results.containsKey(testOppSiteId));
    		system.assertEquals(configCount.get(testOppSiteId), results.get(testOppSiteId).size());
    	}
    }

	/*
		public static List<Quote_Product__c> getQuoteProductsForOpportunitySiteIds(Set<Id> opportuntiySiteIds)
	*/
    /*
    	Test for method getQuoteProductsForOpportunitySiteIds
    	Empty oppSiteIds parameter
    */
    static testMethod void testgetQuoteProductsForOpportunitySiteIdsEmpty()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
    	List<Quote_Product__c> results;
    	List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
    	Integer productCount = 5;
    	
		Map<Id, Site__c> testSites = GetTestSites();
		Map<Id, Product__c> testProducts = GetTestProducts();
		Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();
    	
    	//ensure quote product data exists to confirm method is responding as expected
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProducts.add(testQuoteProduct);
			}
		}
		insert testQuoteProducts;

    	results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteIds);
    	
    	system.assertEquals(true, results != null);
    	system.assertEquals(true, results.isEmpty());
    }

     /*
    	Test for method getQuoteProductsForOpportunitySiteIds
    	NULL oppSiteIds parameter
    */
    static testMethod void testgetQuoteProductsForOpportunitySiteIdsNull()
    {
    	Set<Id> oppSiteIds = null;
    	List<Quote_Product__c> results;
    	List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
    	
    	Integer productCount = 5;
    	
    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
    	Quote__c testQuote = GetTestQuote();
    	Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();
    	
    	//ensure quote product data exists to confirm method is responding as expected
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProducts.add(testQuoteProduct);
			}
		}
		insert testQuoteProducts;

    	results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteIds);
    	
    	system.assertEquals(true, results != null);
    	system.assertEquals(true, results.isEmpty());
    }


     /*
    	Test for method getQuoteProductsForOpportunitySiteIds
    	Single oppSiteIds parameter - No Quote Products 
    */
    static testMethod void testgetQuoteProductsForOpportunitySiteIdsNoProduct()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
    	List<Quote_Product__c> results;
    	List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 5;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Id testOppSiteId = testOppSites.values()[0].Id;
		oppSiteIds.add(testOppSiteId);
		
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			if (testOppSiteId != testOppSiteId) //Adds Quote Products to all Opp Sites except the one we are testing
			{
				for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
				{
					Product__c testProduct = testProducts.values()[prodIterator];
					Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
					testQuoteProduct.Configuration_Complete__c = true;
					testQuoteProducts.add(testQuoteProduct);
				}
			}
		}
		insert testQuoteProducts;
    	
    	results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(true, results.isEmpty());
    }

     /*
    	Test for method getQuoteProductsForOpportunitySiteIds
    	Single oppSiteIds parameter - single Quote Product
    */
    static testMethod void testgetQuoteProductsForOpportunitySiteIdsSingle()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
    	List<Quote_Product__c> results;
    	List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 1;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Id testOppSiteId = testOppSites.values()[0].Id;
		oppSiteIds.add(testOppSiteId);
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProduct.Configuration_Complete__c = true;
				testQuoteProducts.add(testQuoteProduct);
			}
		}
		insert testQuoteProducts;
		
    	
    	results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(1, results.size());
    }


     /*
    	Test for method getQuoteProductsForOpportunitySiteIds
    	Single oppSiteIds parameter - multi Quote Product
    */
    static testMethod void testgetQuoteProductsForOpportunitySiteIdsMulti()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
    	List<Quote_Product__c> results;
 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 5;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Id testOppSiteId = testOppSites.values()[0].Id;
		oppSiteIds.add(testOppSiteId);
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];
			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProduct.Configuration_Complete__c = true;
				testQuoteProducts.add(testQuoteProduct);
			}
		}
		insert testQuoteProducts;
		
    	
    	results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteIds);
    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(productCount, results.size());
    	List<Quote_Product__c> expectedResults = new List<Quote_Product__c>();
    	for (Quote_Product__c quoteProduct : testQuoteProducts)
    	{
    		if (quoteProduct.Opportunity_Site__c == testOppSiteId)
    		{
    			expectedResults.add(quoteProduct);
    		}
    	}
		Map<Id, Quote_Product__c> resultsMap = new Map<Id, Quote_Product__c>();
		resultsMap.putAll(results);
    	for (Quote_Product__c quoteProduct : expectedResults)
    	{
    		system.assertEquals(true, resultsMap.containsKey(quoteProduct.Id));
    	}
    	
    }


     /*
    	Test for method getQuoteProductsForOpportunitySiteIds
    	Single oppSiteIds parameter - multi Quote Product Mixed Configuration
    */
    static testMethod void testgetQuoteProductsForOpportunitySiteIdsMixedConfiguration()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
    	List<Quote_Product__c> results;
 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 5;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

    	Id testOppSiteId = testOppSites.values()[0].Id;
		oppSiteIds.add(testOppSiteId);
		
		Boolean configComplete = false;
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];

			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
				testQuoteProduct.Configuration_Complete__c = configComplete;
				testQuoteProducts.add(testQuoteProduct);
				configComplete = !configComplete;
			}
		}
		insert testQuoteProducts;
		
    	
    	results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(productCount, results.size());
    	List<Quote_Product__c> expectedResults = new List<Quote_Product__c>();
    	for (Quote_Product__c quoteProduct : testQuoteProducts)
    	{
    		if (quoteProduct.Opportunity_Site__c == testOppSiteId)
    		{
    			expectedResults.add(quoteProduct);
    		}
    	}
		Map<Id, Quote_Product__c> resultsMap = new Map<Id, Quote_Product__c>();
		resultsMap.putAll(results);
    	for (Quote_Product__c quoteProduct : expectedResults)
    	{
    		system.assertEquals(true, resultsMap.containsKey(quoteProduct.Id));
    	}
    }



     /*
    	Test for method getQuoteProductsForOpportunitySiteIds
    	multiple oppSiteIds parameter - multi Quote Product Mixed Configuration
    */
    static testMethod void testgetQuoteProductsForOpportunitySiteIdsMultiMixedConfiguration()
    {
    	Set<Id> oppSiteIds = new Set<Id>();
    	List<Quote_Product__c> results;
 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();
 		Integer productCount = 5;

    	Map<Id, Site__c> testSites = GetTestSites();
    	Map<Id, Product__c> testProducts = GetTestProducts();
    	Map<Id, OpportunitySite__c> testOppSites = GetTestOpportunitySites();
		Quote__c testQuote = GetTestQuote();
		Opportunity testOpportunity = GetTestOpportunity();
		Contact testContact = GetTestContact();

		Boolean configComplete = false;
		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites.values()[iterator];
			OpportunitySite__c testOppSite = testOppSites.values()[iterator];

			for (Integer prodIterator = 0; prodIterator<productCount; prodIterator++)
			{
				Product__c testProduct = testProducts.values()[prodIterator];
				Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);

				testQuoteProduct.Configuration_Complete__c = configComplete;
				testQuoteProducts.add(testQuoteProduct);
				configComplete = !configComplete;
			}
			oppSiteIds.add(testOppSite.Id);
			
		}
		insert testQuoteProducts;
		
    	
    	results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteIds);

    	system.assertEquals(true, results != null);
    	system.assertEquals(false, results.isEmpty());
    	system.assertEquals(testQuoteProducts.size(), results.size());
		Map<Id, Quote_Product__c> resultsMap = new Map<Id, Quote_Product__c>();
		resultsMap.putAll(results);
    	for (Quote_Product__c quoteProduct : testQuoteProducts)
    	{
    		system.assertEquals(true, resultsMap.containsKey(quoteProduct.Id));
    	}

    }


}