/********************************************************************
 * QuotePartGridControllerTest
 *
 * Test class for QuotePartGridController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 18-12-2013
 * Changes: 22-07-2016   CH commented out unused variable quotePart in testQuotePartGridController()
 *	18-09-2017 CPE	Updated tests for new individual line changes
 *  03-10-2017 RC   Added new tests for various methods.	
 *  06/11/2017 ADS  Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
 ********************************************************************/
@isTest
private class QuotePartGridControllerTest {

	private static String PRODUCT_ISO9001 = 'ISO 9001';
	private static String PRODUCT_ISO1501 = 'ISO 1501';
    
	/*
	*	Test addSearchComponent
	*/
	private static testMethod void testAddSearchComponent()
	{

		bg_FacetedSearchComponentController fsc = new bg_FacetedSearchComponentController();
		fsc.paramKey='Quote_Product__r.Site__r.Name';
		fsc.objectName='Product__c';
		fsc.selectedItems = new List<String>{'Assurance'};

		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		//bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);	
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
		quotePart.List_Price__c = 123;
		update quotePart;

		Test.setCurrentPage(Page.QuotePartGrid);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);
		ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	    QuotePartGridController controller = new QuotePartGridController();	

	    controller.addSearchComponent('Product__cQuote_Product__r.Site__r.Name', fsc);
	    bg_FacetedSearchComponent comp = controller.facetedSearchComponentMap.get('Product__cQuote_Product__r.Site__r.Name');
	    System.assertEquals('Product__c', comp.getObjectName());

	    //test getallOptions
	    List<SelectOption> so = controller.getAllOptions('Quote_Part__c', 'Quote_Product__c');

	    System.assertEquals(1, so.size());

	}

	/*
	*	Test MSA Pricebooks
	*/
	private static testMethod void testMSAPriceBooks()
	{

		//setup an account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');

		// First, set up test price book entries.
        // Insert a test product.
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        insert ISO9001Prod;
                
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id = :ISO9001Prod.Id];                
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        pricebookGB.Account__c = acc.Id;
        update pricebookGB;
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		//bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		quote.Account__c = acc.id;
		update quote;	
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
		quotePart.Product2__c = ISO9001Prod.id;
		update quotePart;
				
		test.startTest();
		Test.setCurrentPage(Page.QuotePartGrid);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);
		ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	    QuotePartGridController controller = new QuotePartGridController();	

	    QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
	    productWrapper = controller.ProductWrappers[0];

	    //check that it has picked up the default pricebook as it has an msa
	    System.assertEquals('GBP',productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyIsoCode);
	}


	/*
	*	Test bundle selection options
	*/

	private static testMethod void testBundleActionOptions()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		//bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);	
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
		quotePart.List_Price__c = 123;
		update quotePart;

		Test.setCurrentPage(Page.QuotePartGrid);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);
		ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	    QuotePartGridController controller = new QuotePartGridController();	 
	    controller.selectedReferenceSetting = Label.bg_Bundle_Action_Discount;
	    List<SelectOption> so = controller.getBundleActionOptions();

	    //should be two options
	    System.assertEquals(2, so.size());


	}
	

	private static testMethod void testQuotePartGridController() {
		/*
			Method to test QuotePartGridController
		*/		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		//bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);	
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
		quotePart.List_Price__c = 123;
		update quotePart;
		
		test.startTest();
			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	 
	        controller.Save();
	        controller.QuickSave();
	        controller.Cancel();
	        controller.getPricebookItems();
	        controller.getSiteItems();
	        controller.selectedQuotePartId = quotePart.Id;
	        controller.getDiscountDisplayOptions();
	        controller.applyBundleAction();
	        controller.getReferenceSettings();
	        controller.getBundleActionOptions();
	        //
	        controller.toggleShowDiscountAmount();
	        controller.facetedSearchComponentMap = new Map <String, bg_FacetedSearchComponent>();
	        //controller.applyFilters();
	        //controller.removeFilters();

	        system.assertNotEquals(null, controller.getDiscountStatusNA());
	        system.assertNotEquals(null, controller.getDiscountStatusApproved());
	        system.assertNotEquals(null, controller.getDiscountStatusPending());
	        system.assertNotEquals(null, controller.getDiscountStatusRejected());
	        system.assertNotEquals(null, controller.getDiscountStatusDraft());
	        system.assertNotEquals(null, controller.getNoDiscountableParts());
	        controller.selectedDiscountProduct = productName;
	        /* IB removed for PS delete after testing */
		test.stopTest();
	}

	/*
		Check that if the user changes the pricebook for a product then the list of available currrencies
		and the prices are updated
	*/
	private static testMethod void testChangePriceBookAndCurrency() {
		
		// First, set up test price book entries.
        // Insert a test product.
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        insert ISO9001Prod;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id = :ISO9001Prod.Id];                        
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry                        
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		//bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);	
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
		quotePart.Product2__c = ISO9001Prod.id;
		update quotePart;
				
		test.startTest();
			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
	       	productWrapper = controller.ProductWrappers[0];
	        System.debug('+++ AvailablePricebooks = ' + productWrapper.SiteWrappers[0].QuotePartWrappers[0].AvailablePricebooks);
	        System.debug('+++ AvailableCurrencies = ' + productWrapper.SiteWrappers[0].QuotePartWrappers[0].AvailableCurrencies);
	        System.assertEquals(2, productWrapper.SiteWrappers[0].QuotePartWrappers[0].AvailablePricebooks.size() );
	        System.assertEquals(1, productWrapper.SiteWrappers[0].QuotePartWrappers[0].AvailableCurrencies.size());
	        System.assertEquals('USD', productWrapper.SiteWrappers[0].QuotePartWrappers[0].AvailableCurrencies[0].getLabel());
	        System.assertEquals('USD', productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyIsoCode);	        
	        System.assertEquals(12000.00, productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.List_Price__c );
	        
	        // Change to the GB Pricebook
	        controller.selectedQuotePartId = productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Id; //quotePart.Id;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Price_Book__c = pricebookGB.id;
	        controller.changeSinglePriceBook();
	        // EUR and GBP should be available now
	        system.assertEquals(false, ApexPages.hasMessages());
	        System.assertEquals(8000.00, productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.List_Price__c );
	        System.assertEquals(2, productWrapper.SiteWrappers[0].QuotePartWrappers[0].AvailableCurrencies.size());
	        System.assertEquals('GBP', productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyIsoCode);
	        
	        // change the currency to EUR
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyIsoCode = 'EUR';
	        controller.changeSingleCurrency();
	        System.assertEquals(10000.00, productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.List_Price__c );
	        System.assertEquals(2, productWrapper.SiteWrappers[0].QuotePartWrappers[0].AvailableCurrencies.size());
	        
	        
		test.stopTest();
	}



	/*
		test changeSinglePriceBook
		QuotePart Id not set - error should be returned to UI
	*/
	private static testMethod void testchangeSinglePriceBookIdNotSet() 
	{
		// Test data Setup
		List<Product2> testProducts = new List<Product2>();
		
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        Product2 ISO1501Prod = new Product2(Name = PRODUCT_ISO1501, Family = 'Hardware');
        testProducts.add(ISO9001Prod);
        testProducts.add(ISO1501Prod);
        insert testProducts;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id IN (:ISO9001Prod.Id, :ISO1501Prod.Id)];                        
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');        
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');        
        
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry standardPrice4 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice5 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice6 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            //UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');

        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3, standardPrice4, standardPrice5, standardPrice6};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');

        PricebookEntry ISO1501_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO1501_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO1501_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR, ISO1501_US_USD, ISO1501_GB_GBP, ISO1501_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		List<Product__c> testConfigProducts = new List<Product__c>();
		for (Product2 product : testProducts)
		{
			Product__c testConfigProduct = bg_UnitTestHelper.CreateProduct(product.Name + '-' + bg_productUtils.PRODUCT_TYPE_SITE, true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null, null);
			testConfigProducts.add(testConfigProduct);
		}
		insert testConfigProducts;
		
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		OpportunitySite__c testOppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ); 
		

		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		
		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();	
		for (Integer iterator=0; iterator<testConfigProducts.size(); iterator++)
		{
			Product__c testConfigProduct = testConfigProducts[iterator];
			Product2 testProduct = testProducts[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, null, testConfigProduct, siteHQ, opp, testOppSite);
			quoteProduct.Product2__c = testProduct.Id;
			testQuoteProducts.add(quoteProduct);
		}
		insert testQuoteProducts;
		List<Quote_Part__c> testQuoteParts = new List<Quote_Part__c>();
		for (Integer iterator=0; iterator<testQuoteProducts.size(); iterator++)
		{
			Quote_Product__c quoteProduct = testQuoteProducts[iterator];
			Product__c product = testConfigProducts[iterator];
			Quote_Part__c quotePart = bg_UnitTestHelper.CreateQuotePart(quote.Id, product, 0, false, quoteProduct);
			testQuoteParts.add(quotePart);
		}
		insert testQuoteParts;
				
		test.startTest();
			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
			system.assertEquals(2, controller.ProductWrappers.size());
	        
	        // Change to the GB Pricebook
	       	productWrapper = controller.ProductWrappers[0];
	        String selectedPartId;
	        controller.selectedQuotePartId = selectedPartId;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Price_Book__c = pricebookGB.id;
	        controller.changeSinglePriceBook();

	        system.assertEquals(true, ApexPages.hasMessages());
	        for (QuotePartGridController.ProductWrapper pw : controller.ProductWrappers)
	        {
	        	QuotePartGridController.QuotePartWrapper qpw = pw.SiteWrappers[0].QuotePartWrappers[0];
		        System.assertEquals(12000, qpw.QuotePart.List_Price__c );
		        System.assertEquals(1, qpw.AvailableCurrencies.size());
		        System.assertEquals('USD', qpw.QuotePart.CurrencyIsoCode);
	        }
	        
		test.stopTest();
	}


	/*
		test changeSinglePriceBook
		QuotePart Id is invalid - error should be returned to UI
	*/
	private static testMethod void testchangeSinglePriceBookIdInvalid() 
	{
		// Test data Setup
		List<Product2> testProducts = new List<Product2>();
		
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        Product2 ISO1501Prod = new Product2(Name = PRODUCT_ISO1501, Family = 'Hardware');
        testProducts.add(ISO9001Prod);
        testProducts.add(ISO1501Prod);
        insert testProducts;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id IN (:ISO9001Prod.Id, :ISO1501Prod.Id)];         
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry standardPrice4 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice5 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice6 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');

        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3, standardPrice4, standardPrice5, standardPrice6};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');

        PricebookEntry ISO1501_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO1501_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO1501_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR, ISO1501_US_USD, ISO1501_GB_GBP, ISO1501_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		List<Product__c> testConfigProducts = new List<Product__c>();
		for (Product2 product : testProducts)
		{
			Product__c testConfigProduct = bg_UnitTestHelper.CreateProduct(product.Name + '-' + bg_productUtils.PRODUCT_TYPE_SITE, true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null, null);
			testConfigProducts.add(testConfigProduct);
		}
		insert testConfigProducts;
		
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		OpportunitySite__c testOppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ); 
		

		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		
		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();	
		for (Integer iterator=0; iterator<testConfigProducts.size(); iterator++)
		{
			Product__c testConfigProduct = testConfigProducts[iterator];
			Product2 testProduct = testProducts[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, null, testConfigProduct, siteHQ, opp, testOppSite);
			quoteProduct.Product2__c = testProduct.Id;
			testQuoteProducts.add(quoteProduct);
		}
		insert testQuoteProducts;
		List<Quote_Part__c> testQuoteParts = new List<Quote_Part__c>();
		for (Integer iterator=0; iterator<testQuoteProducts.size(); iterator++)
		{
			Quote_Product__c quoteProduct = testQuoteProducts[iterator];
			Product__c product = testConfigProducts[iterator];
			Quote_Part__c quotePart = bg_UnitTestHelper.CreateQuotePart(quote.Id, product, 0, false, quoteProduct);
			testQuoteParts.add(quotePart);
		}
		insert testQuoteParts;
				
		test.startTest();
			// Setup second Quote so that an "valid" invalid quote part id can be used in test
			Quote__c quote2 = bg_UnitTestHelper.GetQuote(opp);	
			Quote_Product__c quoteProduct2 = bg_UnitTestHelper.GetQuoteProduct(quote2, null, testConfigProducts[0]);
			Quote_Part__c quotePart2 = bg_UnitTestHelper.GetQuotePart(quote2.Id, testConfigProducts[0], 0, false, quoteProduct2);
			quotePart2.Product2__c = ISO9001Prod.id;
			update quotePart2;

			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
			system.assertEquals(2, controller.ProductWrappers.size());
	        
	        // Change to the GB Pricebook
	       	productWrapper = controller.ProductWrappers[0];
	        String selectedPartId = quotePart2.Id;
	        controller.selectedQuotePartId = selectedPartId;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Price_Book__c = pricebookGB.id;
	        controller.changeSinglePriceBook();

	        system.assertEquals(true, ApexPages.hasMessages());
	        for (QuotePartGridController.ProductWrapper pw : controller.ProductWrappers)
	        {
	        	QuotePartGridController.QuotePartWrapper qpw = pw.SiteWrappers[0].QuotePartWrappers[0];
		        System.assertEquals(12000, qpw.QuotePart.List_Price__c );
		        System.assertEquals(1, qpw.AvailableCurrencies.size());
		        System.assertEquals('USD', qpw.QuotePart.CurrencyIsoCode);
	        }

		test.stopTest();
	}



	/*
		test changeSinglePriceBook
		Invalid PriceBook selected - error should be returned to UI
	*/
	private static testMethod void testchangeSinglePriceBookInvalidPricebook() 
	{
		// Test data Setup
		List<Product2> testProducts = new List<Product2>();
		
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        Product2 ISO1501Prod = new Product2(Name = PRODUCT_ISO1501, Family = 'Hardware');
        testProducts.add(ISO9001Prod);
        testProducts.add(ISO1501Prod);
        insert testProducts;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id IN(:ISO9001Prod.Id, :ISO1501Prod.Id)];        
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');        
            
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry standardPrice4 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice5 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice6 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');

        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3, standardPrice4, standardPrice5, standardPrice6};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        Pricebook2 invalidPricebook = bg_UnitTestHelper.getPricebook('PB CAD', 'CAD');
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');

        PricebookEntry ISO1501_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO1501_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO1501_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR, ISO1501_US_USD, ISO1501_GB_GBP, ISO1501_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		List<Product__c> testConfigProducts = new List<Product__c>();
		for (Product2 product : testProducts)
		{
			Product__c testConfigProduct = bg_UnitTestHelper.CreateProduct(product.Name + '-' + bg_productUtils.PRODUCT_TYPE_SITE, true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null, null);
			testConfigProducts.add(testConfigProduct);
		}
		insert testConfigProducts;
		
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		OpportunitySite__c testOppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ); 
		

		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		
		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();	
		for (Integer iterator=0; iterator<testConfigProducts.size(); iterator++)
		{
			Product__c testConfigProduct = testConfigProducts[iterator];
			Product2 testProduct = testProducts[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, null, testConfigProduct, siteHQ, opp, testOppSite);
			quoteProduct.Product2__c = testProduct.Id;
			testQuoteProducts.add(quoteProduct);
		}
		insert testQuoteProducts;
		List<Quote_Part__c> testQuoteParts = new List<Quote_Part__c>();
		for (Integer iterator=0; iterator<testQuoteProducts.size(); iterator++)
		{
			Quote_Product__c quoteProduct = testQuoteProducts[iterator];
			Product__c product = testConfigProducts[iterator];
			Quote_Part__c quotePart = bg_UnitTestHelper.CreateQuotePart(quote.Id, product, 0, false, quoteProduct);
			testQuoteParts.add(quotePart);
		}
		insert testQuoteParts;
		
				
		test.startTest();

			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
			system.assertEquals(2, controller.ProductWrappers.size());
	        
	        // Change to the Invalid Pricebook
	       	productWrapper = controller.ProductWrappers[0];
	        String selectedPartId = productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Id;
	        controller.selectedQuotePartId = selectedPartId;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Price_Book__c = invalidPricebook.id;
	        controller.changeSinglePriceBook();

	        system.assertEquals(true, ApexPages.hasMessages());
	        for (QuotePartGridController.ProductWrapper pw : controller.ProductWrappers)
	        {
	        	QuotePartGridController.QuotePartWrapper qpw = pw.SiteWrappers[0].QuotePartWrappers[0];
		        System.assertEquals(12000, qpw.QuotePart.List_Price__c );
		        System.assertEquals(1, qpw.AvailableCurrencies.size());
		        System.assertEquals('USD', qpw.QuotePart.CurrencyIsoCode);
	        }

		test.stopTest();
	}

	/*
		test changeSinglePriceBook
		Valid PriceBook change
	*/
	private static testMethod void testchangeSinglePriceBookValidPricebook()
	{
		// Test data Setup
		List<Product2> testProducts = new List<Product2>();
		
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        Product2 ISO1501Prod = new Product2(Name = PRODUCT_ISO1501, Family = 'Hardware');
        testProducts.add(ISO9001Prod);
        testProducts.add(ISO1501Prod);
        insert testProducts;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id IN(:ISO9001Prod.Id, :ISO1501Prod.Id)];        
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry standardPrice4 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice5 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice6 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');

        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3, standardPrice4, standardPrice5, standardPrice6};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        Pricebook2 invalidPricebook = bg_UnitTestHelper.getPricebook('PB CAD', 'CAD');
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');

        PricebookEntry ISO1501_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO1501_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO1501_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR, ISO1501_US_USD, ISO1501_GB_GBP, ISO1501_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		List<Product__c> testConfigProducts = new List<Product__c>();
		for (Product2 product : testProducts)
		{
			Product__c testConfigProduct = bg_UnitTestHelper.CreateProduct(product.Name + '-' + bg_productUtils.PRODUCT_TYPE_SITE, true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null, null);
			testConfigProducts.add(testConfigProduct);
		}
		insert testConfigProducts;
		
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		OpportunitySite__c testOppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ); 
		

		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		
		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();	
		for (Integer iterator=0; iterator<testConfigProducts.size(); iterator++)
		{
			Product__c testConfigProduct = testConfigProducts[iterator];
			Product2 testProduct = testProducts[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, null, testConfigProduct, siteHQ, opp, testOppSite);
			quoteProduct.Product2__c = testProduct.Id;
			testQuoteProducts.add(quoteProduct);
		}
		insert testQuoteProducts;
		List<Quote_Part__c> testQuoteParts = new List<Quote_Part__c>();
		for (Integer iterator=0; iterator<testQuoteProducts.size(); iterator++)
		{
			Quote_Product__c quoteProduct = testQuoteProducts[iterator];
			Product__c product = testConfigProducts[iterator];
			Quote_Part__c quotePart = bg_UnitTestHelper.CreateQuotePart(quote.Id, product, 0, false, quoteProduct);
			testQuoteParts.add(quotePart);
		}
		insert testQuoteParts;
		
				
		test.startTest();

			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
			system.assertEquals(2, controller.ProductWrappers.size());
	        
	        // Change to the GB Pricebook
	       	productWrapper = controller.ProductWrappers[0];
	        String selectedPartId = productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Id;
	        controller.selectedQuotePartId = selectedPartId;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Price_Book__c = pricebookGB.id;
	        controller.changeSinglePriceBook();

	        system.assertEquals(false, ApexPages.hasMessages());
	        for (QuotePartGridController.ProductWrapper pw : controller.ProductWrappers)
	        {
	        	QuotePartGridController.QuotePartWrapper qpw = pw.SiteWrappers[0].QuotePartWrappers[0];
	        	if (qpw.QuotePart.Id == selectedPartId)
	        	{
			        System.assertEquals(8000, qpw.QuotePart.List_Price__c );
			        System.assertEquals(2, qpw.AvailableCurrencies.size());
			        System.assertEquals('GBP', qpw.QuotePart.CurrencyIsoCode);
	        	}
	        	else
	        	{
			        System.assertEquals(12000, qpw.QuotePart.List_Price__c );
			        System.assertEquals(1, qpw.AvailableCurrencies.size());
			        System.assertEquals('USD', qpw.QuotePart.CurrencyIsoCode);
	        	}
	        }

		test.stopTest();
	}



	/*
		test changeSingleCurrency
		QuotePart Id not set - error should be returned to UI
	*/
	private static testMethod void testchangeSingleCurrencyIdNotSet() 
	{
		// Test data Setup
		List<Product2> testProducts = new List<Product2>();
		
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        Product2 ISO1501Prod = new Product2(Name = PRODUCT_ISO1501, Family = 'Hardware');
        testProducts.add(ISO9001Prod);
        testProducts.add(ISO1501Prod);
        insert testProducts;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id IN(:ISO9001Prod.Id, :ISO1501Prod.Id)];        
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry standardPrice4 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice5 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');        
        
        PricebookEntry standardPrice6 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');

        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3, standardPrice4, standardPrice5, standardPrice6};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');

        PricebookEntry ISO1501_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO1501_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO1501_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR, ISO1501_US_USD, ISO1501_GB_GBP, ISO1501_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		List<Product__c> testConfigProducts = new List<Product__c>();
		for (Product2 product : testProducts)
		{
			Product__c testConfigProduct = bg_UnitTestHelper.CreateProduct(product.Name + '-' + bg_productUtils.PRODUCT_TYPE_SITE, true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null, null);
			testConfigProducts.add(testConfigProduct);
		}
		insert testConfigProducts;
		
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		OpportunitySite__c testOppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ); 
		

		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		
		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();	
		for (Integer iterator=0; iterator<testConfigProducts.size(); iterator++)
		{
			Product__c testConfigProduct = testConfigProducts[iterator];
			Product2 testProduct = testProducts[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, null, testConfigProduct, siteHQ, opp, testOppSite);
			quoteProduct.Product2__c = testProduct.Id;
			testQuoteProducts.add(quoteProduct);
		}
		insert testQuoteProducts;
		List<Quote_Part__c> testQuoteParts = new List<Quote_Part__c>();
		for (Integer iterator=0; iterator<testQuoteProducts.size(); iterator++)
		{
			Quote_Product__c quoteProduct = testQuoteProducts[iterator];
			Product__c product = testConfigProducts[iterator];
			Quote_Part__c quotePart = bg_UnitTestHelper.CreateQuotePart(quote.Id, product, 0, false, quoteProduct);
			testQuoteParts.add(quotePart);
		}
		insert testQuoteParts;
				
		test.startTest();
			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
			system.assertEquals(2, controller.ProductWrappers.size());
	        
	        // Change to USD no quote part id passed
	       	productWrapper = controller.ProductWrappers[0];
	        String selectedPartId; 
	        controller.selectedQuotePartId = selectedPartId;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyISOCode = 'USD';
	        controller.changeSingleCurrency();


	        system.assertEquals(true, ApexPages.hasMessages());
	        for (QuotePartGridController.ProductWrapper pw : controller.ProductWrappers)
	        {
	        	QuotePartGridController.QuotePartWrapper qpw = pw.SiteWrappers[0].QuotePartWrappers[0];
		        System.assertEquals(12000, qpw.QuotePart.List_Price__c );
		        System.assertEquals(1, qpw.AvailableCurrencies.size());
		        System.assertEquals('USD', qpw.QuotePart.CurrencyIsoCode);
	        }

		test.stopTest();
	}


	/*
		test changeSingleCurrency
		QuotePart Id is invalid - error should be returned to UI
	*/
	private static testMethod void testchangeSingleCurrencyIdInvalid() 
	{
		// Test data Setup
		List<Product2> testProducts = new List<Product2>();
		
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        Product2 ISO1501Prod = new Product2(Name = PRODUCT_ISO1501, Family = 'Hardware');
        testProducts.add(ISO9001Prod);
        testProducts.add(ISO1501Prod);
        insert testProducts;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id IN(:ISO9001Prod.Id, :ISO1501Prod.Id)];        
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry standardPrice4 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice5 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice6 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');

        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3, standardPrice4, standardPrice5, standardPrice6};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');

        PricebookEntry ISO1501_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO1501_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO1501_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR, ISO1501_US_USD, ISO1501_GB_GBP, ISO1501_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		List<Product__c> testConfigProducts = new List<Product__c>();
		for (Product2 product : testProducts)
		{
			Product__c testConfigProduct = bg_UnitTestHelper.CreateProduct(product.Name + '-' + bg_productUtils.PRODUCT_TYPE_SITE, true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null, null);
			testConfigProducts.add(testConfigProduct);
		}
		insert testConfigProducts;
		
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		OpportunitySite__c testOppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ); 
		

		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		
		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();	
		for (Integer iterator=0; iterator<testConfigProducts.size(); iterator++)
		{
			Product__c testConfigProduct = testConfigProducts[iterator];
			Product2 testProduct = testProducts[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, null, testConfigProduct, siteHQ, opp, testOppSite);
			quoteProduct.Product2__c = testProduct.Id;
			testQuoteProducts.add(quoteProduct);
		}
		insert testQuoteProducts;
		List<Quote_Part__c> testQuoteParts = new List<Quote_Part__c>();
		for (Integer iterator=0; iterator<testQuoteProducts.size(); iterator++)
		{
			Quote_Product__c quoteProduct = testQuoteProducts[iterator];
			Product__c product = testConfigProducts[iterator];
			Quote_Part__c quotePart = bg_UnitTestHelper.CreateQuotePart(quote.Id, product, 0, false, quoteProduct);
			testQuoteParts.add(quotePart);
		}
		insert testQuoteParts;
				
		test.startTest();
			// Setup second Quote so that an "valid" invalid quote part id can be used in test
			Quote__c quote2 = bg_UnitTestHelper.GetQuote(opp);	
			Quote_Product__c quoteProduct2 = bg_UnitTestHelper.GetQuoteProduct(quote2, null, testConfigProducts[0]);
			Quote_Part__c quotePart2 = bg_UnitTestHelper.GetQuotePart(quote2.Id, testConfigProducts[0], 0, false, quoteProduct2);
			quotePart2.Product2__c = ISO9001Prod.id;
			update quotePart2;

			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
			system.assertEquals(2, controller.ProductWrappers.size());
	        
	        // Change to the USD - invalid quote part id
	       	productWrapper = controller.ProductWrappers[0];
	        String selectedPartId = quotePart2.Id;
	        controller.selectedQuotePartId = selectedPartId;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyISOCode = 'USD';
	        controller.changeSingleCurrency();

	        system.assertEquals(true, ApexPages.hasMessages());
	        for (QuotePartGridController.ProductWrapper pw : controller.ProductWrappers)
	        {
	        	QuotePartGridController.QuotePartWrapper qpw = pw.SiteWrappers[0].QuotePartWrappers[0];
		        System.assertEquals(12000, qpw.QuotePart.List_Price__c );
		        System.assertEquals(1, qpw.AvailableCurrencies.size());
		        System.assertEquals('USD', qpw.QuotePart.CurrencyIsoCode);
	        }
	        
		test.stopTest();
	}



	/*
		test changeSingleCurrency
		Invalid Currency selected - no error should be returned to UI and default currency set
	*/
	private static testMethod void testchangeSingleCurrencyInvalidCurrency() 
	{
		// Test data Setup
		List<Product2> testProducts = new List<Product2>();
		
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        Product2 ISO1501Prod = new Product2(Name = PRODUCT_ISO1501, Family = 'Hardware');
        testProducts.add(ISO9001Prod);
        testProducts.add(ISO1501Prod);
        insert testProducts;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id IN(:ISO9001Prod.Id, :ISO1501Prod.Id)];        
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');            
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry                        
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');        
            
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry                        
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry standardPrice4 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry                        
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice5 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry                        
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice6 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry                        
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');

        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3, standardPrice4, standardPrice5, standardPrice6};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');

        PricebookEntry ISO1501_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO1501_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO1501_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR, ISO1501_US_USD, ISO1501_GB_GBP, ISO1501_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		List<Product__c> testConfigProducts = new List<Product__c>();
		for (Product2 product : testProducts)
		{
			Product__c testConfigProduct = bg_UnitTestHelper.CreateProduct(product.Name + '-' + bg_productUtils.PRODUCT_TYPE_SITE, true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null, null);
			testConfigProducts.add(testConfigProduct);
		}
		insert testConfigProducts;
		
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		OpportunitySite__c testOppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ); 
		

		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		
		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();	
		for (Integer iterator=0; iterator<testConfigProducts.size(); iterator++)
		{
			Product__c testConfigProduct = testConfigProducts[iterator];
			Product2 testProduct = testProducts[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, null, testConfigProduct, siteHQ, opp, testOppSite);
			quoteProduct.Product2__c = testProduct.Id;
			testQuoteProducts.add(quoteProduct);
		}
		insert testQuoteProducts;
		List<Quote_Part__c> testQuoteParts = new List<Quote_Part__c>();
		for (Integer iterator=0; iterator<testQuoteProducts.size(); iterator++)
		{
			Quote_Product__c quoteProduct = testQuoteProducts[iterator];
			Product__c product = testConfigProducts[iterator];
			Quote_Part__c quotePart = bg_UnitTestHelper.CreateQuotePart(quote.Id, product, 0, false, quoteProduct);
			testQuoteParts.add(quotePart);
		}
		insert testQuoteParts;
				
		test.startTest();

			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
			system.assertEquals(2, controller.ProductWrappers.size());
	        
	        // Change to the GB Pricebook and EUR Currency
	       	productWrapper = controller.ProductWrappers[0];
	        String selectedPartId = productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Id;
	        controller.selectedQuotePartId = selectedPartId;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Price_Book__c = pricebookGB.Id;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyISOCode = 'EUR';
	        controller.changeSinglePriceBook();
	        system.assertEquals(false, ApexPages.hasMessages());
	        System.assertEquals(10000, productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.List_Price__c );
	        System.assertEquals(2, productWrapper.SiteWrappers[0].QuotePartWrappers[0].AvailableCurrencies.size());
	        System.assertEquals('EUR', productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyIsoCode);


	        // change to invalid currency - should reset to PB default of GBP
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyISOCode = 'CAD';
	        controller.changeSingleCurrency();

	        system.assertEquals(false, ApexPages.hasMessages());
	        for (QuotePartGridController.ProductWrapper pw : controller.ProductWrappers)
	        {
	        	QuotePartGridController.QuotePartWrapper qpw = pw.SiteWrappers[0].QuotePartWrappers[0];
	        	if (qpw.QuotePart.Id == selectedPartId)
	        	{
			        System.assertEquals(8000, qpw.QuotePart.List_Price__c );
			        System.assertEquals(2, qpw.AvailableCurrencies.size());
			        System.assertEquals('GBP', qpw.QuotePart.CurrencyIsoCode);
	        	}
	        	else
	        	{
			        System.assertEquals(12000, qpw.QuotePart.List_Price__c );
			        System.assertEquals(1, qpw.AvailableCurrencies.size());
			        System.assertEquals('USD', qpw.QuotePart.CurrencyIsoCode);
	        	}
	        }
		test.stopTest();
	}

	/*
		test changeSingleCurrency
		Invalid PriceBook selected - error should be returned to UI
	*/
	private static testMethod void testchangeSingleCurrencyInvalidPricebook() 
	{
		// Test data Setup
		List<Product2> testProducts = new List<Product2>();
		
        Product2 ISO9001Prod = new Product2(Name = PRODUCT_ISO9001, Family = 'Hardware');
        Product2 ISO1501Prod = new Product2(Name = PRODUCT_ISO1501, Family = 'Hardware');
        testProducts.add(ISO9001Prod);
        testProducts.add(ISO1501Prod);
        insert testProducts;
        
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id IN(:ISO9001Prod.Id, :ISO1501Prod.Id)];        
        
        // Insert a price book entries for the standard price book.
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice2 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
        
        PricebookEntry standardPrice3 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO9001Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry standardPrice4 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry standardPrice5 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
            
        PricebookEntry standardPrice6 = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = ISO1501Prod.Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'USD');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'USD');

        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2, standardPrice3, standardPrice4, standardPrice5, standardPrice6};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        pricebookGB.Default_Pricebook_Currency__c = 'GBP'; // ensure default currency set on pricebook, otherwise change in PB not guarenteed to provide expected results
        update pricebookGB;
        Pricebook2 invalidPricebook = bg_UnitTestHelper.getPricebook('PB CAD', 'CAD');
        
        
        PricebookEntry ISO9001_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');

        PricebookEntry ISO1501_US_USD = new PricebookEntry(
        Pricebook2Id = pricebookUS.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 12000, IsActive = true, CurrencyIsoCode = 'USD');
        
        PricebookEntry ISO1501_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO1501_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO1501Prod.Id,    
        UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_US_USD, ISO9001_GB_GBP, ISO9001_GB_EUR, ISO1501_US_USD, ISO1501_GB_GBP, ISO1501_GB_EUR};
        insert pricebookEntries;
		
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = PRODUCT_ISO9001;
		
		List<Product__c> testConfigProducts = new List<Product__c>();
		for (Product2 product : testProducts)
		{
			Product__c testConfigProduct = bg_UnitTestHelper.CreateProduct(product.Name + '-' + bg_productUtils.PRODUCT_TYPE_SITE, true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null, null);
			testConfigProducts.add(testConfigProduct);
		}
		insert testConfigProducts;
		
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.CreateOpportunity(acc, productName);
		opp.CurrencyISOCode = 'USD';
		insert opp;
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		// Opportunity Site
		OpportunitySite__c testOppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ); 
		

		/*  LOAD QUOTE TEST */

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		
		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();	
		for (Integer iterator=0; iterator<testConfigProducts.size(); iterator++)
		{
			Product__c testConfigProduct = testConfigProducts[iterator];
			Product2 testProduct = testProducts[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, null, testConfigProduct, siteHQ, opp, testOppSite);
			quoteProduct.Product2__c = testProduct.Id;
			testQuoteProducts.add(quoteProduct);
		}
		insert testQuoteProducts;
		List<Quote_Part__c> testQuoteParts = new List<Quote_Part__c>();
		for (Integer iterator=0; iterator<testQuoteProducts.size(); iterator++)
		{
			Quote_Product__c quoteProduct = testQuoteProducts[iterator];
			Product__c product = testConfigProducts[iterator];
			Quote_Part__c quotePart = bg_UnitTestHelper.CreateQuotePart(quote.Id, product, 0, false, quoteProduct);
			testQuoteParts.add(quotePart);
		}
		insert testQuoteParts;
		
				
		test.startTest();

			Test.setCurrentPage(Page.QuotePartGrid);
			ApexPages.currentPage().getParameters().put('accid', acc.Id);
			ApexPages.currentPage().getParameters().put('oppid', opp.Id);
			ApexPages.currentPage().getParameters().put('quoid', quote.Id);

	        QuotePartGridController controller = new QuotePartGridController();	
	        
	       	QuotePartGridController.ProductWrapper productWrapper = new QuotePartGridController.ProductWrapper('one');
			system.assertEquals(2, controller.ProductWrappers.size());
	        
	        // Change to the Invalid Pricebook with valid currency
	       	productWrapper = controller.ProductWrappers[0];
	        String selectedPartId = productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Id;
	        controller.selectedQuotePartId = selectedPartId;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.Price_Book__c = invalidPricebook.id;
	        productWrapper.SiteWrappers[0].QuotePartWrappers[0].QuotePart.CurrencyISOCode = 'USD';
	        controller.changeSingleCurrency();

	        system.assertEquals(true, ApexPages.hasMessages());
	        for (QuotePartGridController.ProductWrapper pw : controller.ProductWrappers)
	        {
	        	QuotePartGridController.QuotePartWrapper qpw = pw.SiteWrappers[0].QuotePartWrappers[0];
		        System.assertEquals(12000, qpw.QuotePart.List_Price__c );
		        System.assertEquals(1, qpw.AvailableCurrencies.size());
		        System.assertEquals('USD', qpw.QuotePart.CurrencyIsoCode);
	        }

		test.stopTest();
	}

}