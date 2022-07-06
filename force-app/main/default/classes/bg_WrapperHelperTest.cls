/********************************************************************
 * bg_WrapperHelperTest
 *
 * Test class for bg_WrapperHelper
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 *	CPE 11-09-2017 	New Unit test methods for new and altered methods in bg_WrapperHelper:
 *						CreateProductSiteWrapper (updated)
 *						CreateProjectWrappers (new)
 *						GetControllingLocations (new)
 *					And updates/new wrapper classes in bg_Wrappers:
 *						ProjectWrapper (new)
 *						RelatedProjectWrapper (new)
 *						ProductAreaWrapper (updated)
 *						QuoteProductWrapper (updated)
 *	RC 28-09-2017   New Unit test for getRegistrationPathItems
 *  RC 06-10-2017   changed apply sampling to change the product to be in the grid view
 *  ADS 13-11-2017  Case 33437 Only Systems Certification Products should appear in the sampling map
 *
 ********************************************************************/
@isTest 
private class bg_WrapperHelperTest {

	/*
	*	Test getRegistration path Items	Transition does exist
	*/
	private static testMethod void testRegistrationPathItemsPassInTransition()
	{
		List<SelectOption> selectOption = bg_WrapperHelper.GetRegistrationPathItems(true, 'Transition;TestPath;TestPath2;', 
		false, 'Transition', true);

		//should return 3 items 
		System.assertEquals(2, selectOption.size());
	}

	/*
	*	Test getRegistration path Items	Transition Does not Exist
	*/
	private static testMethod void testRegistrationPathItemsTransitionDoesNotExist()
	{
		List<SelectOption> selectOption = bg_WrapperHelper.GetRegistrationPathItems(true, 'TestPath;TestPath2;', 
		false, 'TestPath', true);

		//should return 1 items that is None
		System.assertEquals(3, selectOption.size());
		//System.assertEquals('--' + Label.None + '--', selectOption[0].getLabel());
	}

	private static testMethod void testCreateProductWrappers() {
		/*
			Test CreateProductWrappers Methods
		*/	
		// Create 3 products	
		list<Product__c> products = new list<Product__c>();
		products.add(bg_UnitTestHelper.GetProduct('UT-ProductA'));
		products.add(bg_UnitTestHelper.GetProduct('UT-ProductB'));
		products.add(bg_UnitTestHelper.GetProduct('UT-ProductC'));
		// Create selected products
		set<string> selectedProducts = new set<string>{'UT-ProductA','UT-ProductB'};
		test.startTest();
			// TEST: CreateProductWrappers(list<Product__c> products)
			system.assertEquals(3, bg_WrapperHelper.CreateProductWrappers(products).size());

			// TEST: CreateProductWrappers(list<Product__c> products, set<string> selectedProducts)
			list<bg_Wrappers.ProductWrapper> productWrappers = bg_WrapperHelper.CreateProductWrappers(products, selectedProducts);
			system.assertEquals(3, productWrappers.size());
			for(bg_Wrappers.ProductWrapper pw : productWrappers) {
				if(selectedProducts.contains(pw.name)) {
					system.assertEquals(true, pw.Selected);
				} else {
					system.assertEquals(false, pw.Selected);
				}
			}
		test.stopTest();
	}

	private static testMethod void testCreateProductWrapper() {
		/*
			Test CreateProductWrapper Methods
		*/
		// Create product
		Product__c product = bg_UnitTestHelper.GetProduct('UT-ProductA');
		set<string> selectedProducts = new set<string>{'UT-ProductA', 'UT-ProductB'};
		test.startTest();
			// TEST: CreateProductWrapper(Product__c product) 
			bg_Wrappers.ProductWrapper pw = bg_WrapperHelper.CreateProductWrapper(product);
			system.assertNotEquals(null, pw);
			system.assertEquals(product.Name, pw.Name);
			system.assertEquals(false, pw.Selected);
			system.assertEquals(product, pw.Product);
			// TEST: CreateProductWrapper(Product__c product, set<string> selectedProducts)
			system.assertEquals(true, bg_WrapperHelper.CreateProductWrapper(product, selectedProducts).Selected);
		test.stopTest();			
	}

	private static testMethod void testCreateProductWrappersMap() {
		/*
			Test CreateProductWrappersMap Method
		*/
		// Create products
		list<Product__c> products = new list<Product__c>();
		products.add(bg_UnitTestHelper.GetProduct('UT-ProductA'));
		test.startTest();
			map<string, bg_Wrappers.ProductWrapper> pwMap = bg_WrapperHelper.CreateProductWrappersMap(products);
			system.assertEquals(true, pwMap.containsKey(products[0].name));
			system.assertEquals(products[0].name, pwMap.get(products[0].name).Product.Name);		
		test.stopTest();	
	}

	private static testMethod void testCreateProductInterestsWrapperMap() {
		/*
			Test CreateProductInterestsWrapperMap Method
		*/
		list<Product__c> products = new list<Product__c>();
		products.add(bg_UnitTestHelper.GetProduct('UT-ProductA', true, 'PortfolioA','ProductAreaA'));
		products.add(bg_UnitTestHelper.GetProduct('UT-ProductB', true, 'PortfolioB','ProductAreaB'));
		products.add(bg_UnitTestHelper.GetProduct('UT-ProductC', true, 'PortfolioC','ProductAreaC'));
		map<string, bg_Wrappers.ProductWrapper> pwMap = bg_WrapperHelper.CreateProductWrappersMap(products);
		list<string> selectedProducts = new list<string>{'UT-ProductA', 'UT-ProductB'};
		set<string> selectedProductSet = new set<string>(selectedProducts);
		test.startTest();
			map<string, map<string, map<string, bg_Wrappers.ProductWrapper>>> pwiMap;
			// TEST: CreateProductInterestsWrapperMap(map<string, bg_Wrappers.ProductWrapper> productWrapperMap)
			pwiMap = bg_WrapperHelper.CreateProductInterestsWrapperMap(pwMap);
			// Check map
			for(bg_Wrappers.ProductWrapper pw: pwMap.values()) {
				// Check portfolios
				system.assertNotEquals(null, pwiMap.get(pw.Product.Portfolio_Interest__c));
				system.assertEquals(1, pwiMap.get(pw.Product.Portfolio_Interest__c).size());
				// Check product Area
				system.assertNotEquals(null, pwiMap.get(pw.Product.Portfolio_Interest__c).get(pw.Product.Product_Area_Interest__c));
				system.assertEquals(1, pwiMap.get(pw.Product.Portfolio_Interest__c).get(pw.Product.Product_Area_Interest__c).size());
				// check product
				system.assertNotEquals(null, pwiMap.get(pw.Product.Portfolio_Interest__c).get(pw.Product.Product_Area_Interest__c).get(pw.Name));
			}
			// TEST: CreateProductInterestsWrapperMap(map<string, bg_Wrappers.ProductWrapper> productWrapperMap, list<string> selectedProducts) {
			pwiMap = bg_WrapperHelper.CreateProductInterestsWrapperMap(pwMap, selectedProducts);
			// Check map
			for(bg_Wrappers.ProductWrapper pw: pwMap.values()) {
				// check product is selected
				system.assertEquals(selectedProductSet.contains(pw.Name), pw.Selected);
			}
		test.stopTest();		
	}
	
	private static testMethod void testCreateProductSiteWrapper() {
		/*
			Test CreateProductSiteWrapper Methods
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Contact con = bg_UnitTestHelper.GetContact('UT-WH-CON', acc);
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
 		
		// Create Wrappers
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
 		map<Id, Contact> contactMap = new map<Id, Contact>();
 		contactMap.put(con.Id, con);

 		test.startTest();
 			system.assertNotEquals(null, bg_WrapperHelper.CreateProductSiteWrapper(quote, qpw, sw));
 			system.assertNotEquals(null, bg_WrapperHelper.CreateProductSiteWrapper(quote, qpw, sw, quoteProduct));
			system.assertNotEquals(null, bg_WrapperHelper.CreateProductSiteWrapper(quote, qpw, sw, quoteProduct, contactMap));
		test.stopTest();
	}



	/*
		Test CreateProductSiteWrapper Methods for PS Stream Product - no quoteProduct
	*/
	static testMethod void testCreateProductSiteWrapperPSStream() {
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'PS Project Product';
		set<string> countries = new set<string>{bg_SiteUtils.COUNTRY_CODE_US};
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Contact con = bg_UnitTestHelper.GetContact('UT-WH-CON', acc);
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);


		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2(productName, bg_ProductUtils.PRODUCT_STREAM_PS, 'PortfolioA', 'FamilyA');
		
		Product__c testProduct = bg_UnitTestHelper.CreateProduct(productName, true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		testProduct.Product_Stream__c = bg_ProductUtils.PRODUCT_STREAM_PS;
		insert testProduct;

		pcA.SF_Product__c = testProduct.Id;
		update pcA;


		Quote__c quote = bg_UnitTestHelper.GetQuote();
 		
		// Create Wrappers
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(pcA);
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
 		map<Id, Contact> contactMap = new map<Id, Contact>();
 		contactMap.put(con.Id, con);

		system.assertEquals(bg_ProductUtils.PRODUCT_STREAM_PS, qpw.Area);
		system.assertEquals(pca.Stream2__c, qpw.Area);
		
 		bg_Wrappers.ProductSiteWrapper result;
 		
 		result = bg_WrapperHelper.CreateProductSiteWrapper(quote, qpw, sw, null, contactMap, false);
 		
 		system.assertEquals(false, result == null);
 		system.assertEquals(true, result.Selected);
 		system.assertEquals(bg_QuoteUtils.DEFAULT_REGPATH_NONASSURANCE, result.RegistrationPath);
 		
	}

	
	private static testMethod void testPopulateProductSiteDefaults() {
		/*
			Test PopulateProductSiteDefaults Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Contact con = bg_UnitTestHelper.GetContact('UT-WH-CON', acc);		
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(null, con);
 		
		// Create Wrappers
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
		bg_Wrappers.ProductSiteWrapper psw = bg_WrapperHelper.CreateProductSiteWrapper(quote, qpw, sw);

		test.startTest();
			bg_WrapperHelper.PopulateProductSiteDefaults(psw, quote);
			quote.UseSiteContactDefaults__c = true;
			bg_WrapperHelper.PopulateProductSiteContactDefaults(psw, quote);
			quote.UseLocalPrices__c = true;
			bg_WrapperHelper.PopulateProductSiteCurrencyDefaults(psw, quote);
		test.stopTest();
	}
	
	private static testMethod void testCreateIMSWrapper() {
		/*
			Test CreateIMSWrapper Method
		*/
		string productName = 'ISO 9001';
		set<string> imsProducts = new set<string>();
		set<string> selectedProducts = new set<string>();
		set<string> selectedIMSProducts = new set<string>();
		set<string> allSelectedIMS = new set<string>();
		test.startTest();
			system.assertNotEquals(null, bg_WrapperHelper.CreateIMSWrapper(productName, imsProducts, selectedProducts, selectedIMSProducts, allSelectedIMS));
		test.stopTest();			
	}
	
	private static testMethod void testCreateIMSProductMap() {
		/*
			Test CreateIMSProductMap Method
		*/
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
 		
		// Create Wrappers
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		map<string, bg_Wrappers.QuoteProductWrapper> productMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.QuoteProductWrapper>{qpw});
		
		set<string> selectedProducts = new set<string>();
		set<string> selectedIMSProducts = new set<string>();
		set<string> allSelectedIMS = new set<string>();
		test.startTest();
			system.assertNotEquals(null, bg_WrapperHelper.CreateIMSProductMap(productMap, selectedProducts, selectedIMSProducts, allSelectedIMS));
		test.stopTest();	
	}

	private static testMethod void testCreateProductAreaWrapper() {
		/*
			Test CreateProductAreaWrapper Method
		*/
		string areaTitle = 'UT-AREA';	
		test.startTest();
			system.assertEquals(areaTitle, bg_WrapperHelper.CreateProductAreaWrapper(areaTitle, false).Title);	 
		test.stopTest();
	}

	private static testMethod void testCreateProductAreaWrappers() {
		/*
			Test CreateProductAreaWrappers and CreateProductAreaWrappersMap Method
		*/
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);			 
		test.startTest();
			list<bg_Wrappers.ProductAreaWrapper> paws = bg_WrapperHelper.CreateProductAreaWrappers(new list<Product__c>{product});
			system.assertEquals(product.Product_Stream__c, paws[0].Title);
			system.assertEquals(true, bg_WrapperHelper.CreateProductAreaWrappersMap(paws).containsKey(product.Product_Stream__c));			
		test.stopTest();
	}
	
	private static testMethod void testCreateSiteWrapper() {
		/*
			Test CreateSiteWrapper Method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		test.startTest();	 
			system.assertNotEquals(null, bg_WrapperHelper.CreateSiteWrapper(0, site, true));
		test.stopTest();
	}
	
	private static testMethod void testCreateSiteWrappers() {
		/*
			Test CreateSiteWrappers Method
		*/
 		bg_UnitTestHelper.GetDefaultCountrySetting();
 		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US);		
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		list<OpportunitySite__c> oppSites = new list<OpportunitySite__c>{bg_UnitTestHelper.GetOpportunitySite(opp, site, true)};
		test.startTest();	 
			system.assertEquals(1, bg_WrapperHelper.CreateSiteWrappers(oppSites).size());
		test.stopTest();
	}

	private static testMethod void testCreateQuoteProductWrapper() {
		/*
			Test CreateQuoteProductWrapper and CreateQuoteProductWrappers Method
		*/
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		list<bg_Wrappers.ProductAreaWrapper> paws = bg_WrapperHelper.CreateProductAreaWrappers(new list<Product__c>{product});				 		
		test.startTest();
			bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
			system.assertEquals(3, qpw.RegistrationPathItems.size());	
			
 			system.assertEquals(product.Name, bg_WrapperHelper.CreateQuoteProductWrapper(product).Name);
 			system.assertEquals(product.Name, bg_WrapperHelper.CreateQuoteProductWrapper(product, paws[0]).Name);
 			system.assertEquals(product.Name, bg_WrapperHelper.CreateQuoteProductWrappers(new list<Product__c>{product})[0].Name);
 			system.assertEquals(product.Name, bg_WrapperHelper.CreateQuoteProductWrappers(new list<Product__c>{product}, paws[0])[0].Name); 						
			system.assertEquals(true, bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.ProductAreaWrapper>{paws[0]}).containsKey(product.Name)); 
			system.assertEquals(true, bg_WrapperHelper.CreateQuoteProductWrappersMap(bg_WrapperHelper.CreateQuoteProductWrappers(new list<Product__c>{product}, paws[0])).containsKey(product.Name)); 
 		test.stopTest();
	}

	private static testMethod void testGetHQSite() {
		/*
			Test GetHQSite Method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US); 		
		// Create Wrappers
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
		test.startTest();		 
			system.assertEquals(sw, bg_WrapperHelper.GetHQSite(new list<bg_Wrappers.SiteWrapper>{sw}));
 		test.stopTest();		
	}

	
	private static testMethod void testGetSiteMap() {
		/*
			Test GetSiteMap Method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');	
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		// Create Wrappers
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
 		test.startTest();				 
			system.assertEquals(true, bg_WrapperHelper.GetSiteMap(new list<bg_Wrappers.SiteWrapper>{sw}).containsKey(sw.Id));
		test.stopTest();
	}
	
	private static testMethod void testPopulateSamplingFields() {
		/*
			Test PopulateSamplingFields Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Product__c questionProduct = bg_UnitTestHelper.GetQuestionProduct(productName);
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc); 
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c questionQuoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, questionProduct);
		Quote_Part__c questionQuotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 1, true, questionQuoteProduct);

		// Create Wrappers
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
 		qpw.SamplingAvailable = true;
 		test.startTest();		 
			bg_WrapperHelper.PopulateSamplingFields(qpw, quote.Id);
		test.stopTest();
		system.assertNotEquals(null, qpw.SampleQuestionURL);
		system.assertEquals(true, qpw.VerifiedForSampling);
	}

	private static testMethod void testPopulateIMSFields() {
		/*
			Test PopulateIMSFields Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Product__c imsProduct = bg_UnitTestHelper.GetQuestionProduct(bg_ProductUtils.QUESTION_PRODUCT_IMS);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		// Create Wrappers
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
 		qpw.SamplingAvailable = true;
 		test.startTest();		 
			bg_WrapperHelper.PopulateIMSFields(qpw, quote.Id);
		test.stopTest();
		system.assertNotEquals(null, qpw.IMSQuestionURL);				 
	}
	
	private static testMethod void testPopulateQuoteProductWrappers() {
		/*
			Test PopulateQuoteProductWrappers Method
		*/
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Contact con = bg_UnitTestHelper.GetContact('UT-WH-CON', acc);		
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, site);
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.QuoteProductWrapper>{qpw});
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
		list<bg_Wrappers.SiteWrapper> sites = new list<bg_Wrappers.SiteWrapper>{sw};
 		map<Id, Contact> contactMap = new map<Id, Contact>();
 		contactMap.put(con.Id, con);
		list<Quote_Product__c> quoteProducts = new list<Quote_Product__c>{quoteProduct};
		bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites);

		test.startTest();
			// TEST: PopulateQuoteProductWrappers(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap, list<bg_Wrappers.SiteWrapper> sites, list<Quote_Product__c> quoteProducts)
			system.assertEquals(false, qpw.Selected);
			bg_WrapperHelper.PopulateQuoteProductWrappers(quote, quoteProductMap, sites, quoteProducts);
			system.assertEquals(true, qpw.Selected);
			
			// TEST: PopulateQuoteProductWrappers(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap, list<bg_Wrappers.SiteWrapper> sites, list<Quote_Product__c> quoteProducts, boolean configureUrl)
			qpw.Selected = false;
			bg_WrapperHelper.PopulateQuoteProductWrappers(quote, quoteProductMap, sites, quoteProducts, true);
			system.assertEquals(true, qpw.Selected);
			
			// TEST: PopulateQuoteProductWrappers(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap, list<bg_Wrappers.SiteWrapper> sites, list<Quote_Product__c> quoteProducts, boolean configureUrl, map<Id, Contact> contactMap)
			qpw.Selected = false;
			bg_WrapperHelper.PopulateQuoteProductWrappers(quote, quoteProductMap, sites, quoteProducts, true, contactMap);
			system.assertEquals(true, qpw.Selected);
		test.stopTest();
	}
	
	private static testMethod void testCreateSamplingMap() {
		/*
			Test CreateSamplingMap, AddProductSiteToSamplingMap and RemoveProductSiteFromSamplingMap Method
		*/
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.QuoteProductWrapper>{qpw});
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
		list<bg_Wrappers.SiteWrapper> sites = new list<bg_Wrappers.SiteWrapper>{sw};
		bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites);
		
		map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap = new map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>>();
		test.startTest();
			samplingMap = bg_WrapperHelper.CreateSamplingMap(sites, quoteProductMap);
			qpw.SitesMap.values()[0].RegistrationPath = 'New Registration';
			bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, qpw, sw, qpw.SitesMap.values()[0]);
			bg_WrapperHelper.RemoveProductSiteFromSamplingMap(samplingMap, qpw, sw, qpw.SitesMap.values()[0]);
		test.stopTest();
	}

	private static testMethod void testCreateRelatedProductWrapper() {
		/*
			Test CreateRelatedProductWrapper and CreateRelatedProductWrappers Method
		*/
		Product__c prod1 = bg_UnitTestHelper.GetProduct('UT-PROD1');
		Product__c prod2 = bg_UnitTestHelper.GetProduct('UT-PROD2');
		bg_UnitTestHelper.GetProductRelationship(prod1, prod2, bg_ProductUtils.PRODUCT_RELATIONSHIP_TYPE_SUGGESTED);
		list<Product_Relationship__c> relatedProducts = bg_ProductUtils.GetSuggestedProducts(new set<Id>{prod1.Id});
		test.startTest();
			system.assertNotEquals(null, bg_WrapperHelper.CreateRelatedProductWrapper(relatedProducts[0]));
			system.assertEquals(1, bg_WrapperHelper.CreateRelatedProductWrappers(relatedProducts).size());		
		test.stopTest();
	}

	private static testMethod void testIsSelectedIMSProducts() {
		/*
			Test IsSelectedIMSProducts Method
		*/
		string productName = 'ISO 9001';
		set<string> selectedProducts = new set<string>();
		set<string> selectedIMSProducts = new set<string>();
		set<string> imsProducts = new set<string>();
		
		test.startTest();				
			system.assertEquals(false, bg_WrapperHelper.IsSelectedIMSProducts(productName, selectedProducts, selectedIMSProducts, imsProducts));
			selectedProducts.add(productName);
			imsProducts.add(productName);
			system.assertEquals(true, bg_WrapperHelper.IsSelectedIMSProducts(productName, selectedProducts, selectedIMSProducts, imsProducts));
			selectedIMSProducts.add(productName);
			system.assertEquals(true, bg_WrapperHelper.IsSelectedIMSProducts(productName, selectedProducts, selectedIMSProducts, imsProducts));
			productName = 'ISO 14001';
			system.assertEquals(true, bg_WrapperHelper.IsSelectedIMSProducts(productName, selectedProducts, selectedIMSProducts, imsProducts));
		test.stopTest();
	}
	
	private static testMethod void testGetSelectedProductWrappersMap() {
		/*
			Test  Method
		*/
		Product__c product = bg_UnitTestHelper.GetProduct('UT-PRODUCT');
		list<bg_Wrappers.ProductWrapper> productWrappers = bg_WrapperHelper.CreateProductWrappers(new list<Product__c>{product});
		productWrappers[0].Selected = true;
		test.startTest();
			system.assertEquals(true, bg_WrapperHelper.GetSelectedProductWrappersMap(productWrappers).containsKey(product.Id));
		test.stopTest();
	}

	private static testMethod void testCreateProductSiteWrappers() {
		/*
			Test CreateProductSiteWrappers Methods
		*/
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, site);
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.QuoteProductWrapper>{qpw});
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
		list<bg_Wrappers.SiteWrapper> sites = new list<bg_Wrappers.SiteWrapper>{sw};
		list<Quote_Product__c> quoteProducts = new list<Quote_Product__c>{quoteProduct};

		test.startTest();				 
			//TEST: CreateProductSiteWrappers(Quote__c quote, bg_Wrappers.QuoteProductWrapper quoteProduct, list<bg_Wrappers.SiteWrapper> sites)
			bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values()[0], sites);
			system.assertEquals(1, quoteProductMap.values()[0].SitesMap.size());
						
			//TEST: CreateProductSiteWrappers(Quote__c quote, list<bg_Wrappers.QuoteProductWrapper> quoteProducts, list<bg_Wrappers.SiteWrapper> sites)
			quoteProductMap.values()[0].SitesMap.Clear();
			bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites);
			system.assertEquals(1, quoteProductMap.values()[0].SitesMap.size());
			
			//TEST: CreateProductSiteWrappers(Quote__c quote, list<bg_Wrappers.QuoteProductWrapper> quoteProducts, list<bg_Wrappers.SiteWrapper> sites, boolean createMissingProductSites)
			quoteProductMap.values()[0].SitesMap.Clear();
			bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites, true);
			system.assertEquals(1, quoteProductMap.values()[0].SitesMap.size());
			
			//TEST: CreateProductSiteWrappers(Quote__c quote, bg_Wrappers.QuoteProductWrapper quoteProduct, list<bg_Wrappers.SiteWrapper> sites, boolean createMissingProductSites) {
			quoteProductMap.values()[0].SitesMap.Clear();
			bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values()[0], sites, true);
			system.assertEquals(1, quoteProductMap.values()[0].SitesMap.size());
		test.stopTest();
	}
	
	private static testMethod void testPopulateProductSiteWrappers() {
		/*
			Test PopulateProductSiteWrappers Method
		*/		 
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		//Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, site);
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		//map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.QuoteProductWrapper>{qpw});
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
		list<bg_Wrappers.SiteWrapper> sites = new list<bg_Wrappers.SiteWrapper>{sw};
		//list<Quote_Product__c> quoteProducts = new list<Quote_Product__c>{quoteProduct};

		test.startTest();
			bg_WrapperHelper.PopulateProductSiteWrappers(quote, sites, qpw);
			system.assertEquals(1, qpw.SitesMap.size());
		test.stopTest();			
	}
	
	private static testMethod void testUpdateIMSProductMap() {
		/*
			Test UpdateIMSProductMap Method
		*/		 
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.QuoteProductWrapper>{qpw});
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
		list<bg_Wrappers.SiteWrapper> sites = new list<bg_Wrappers.SiteWrapper>{sw};

		set<string> selectedProducts = new set<string>();
		set<string> selectedIMSProducts = new set<string>();
		set<string> allSelectedIMS = new set<string>();
		map<string, bg_Wrappers.IMSWrapper> imsProductMap = bg_WrapperHelper.CreateIMSProductMap(quoteProductMap, selectedProducts, selectedIMSProducts, allSelectedIMS);

		test.startTest();
			//TEST: UpdateIMSProductMap(Id quoteId, map<string, bg_Wrappers.IMSWrapper> IMSProductMap, bg_Wrappers.QuoteProductWrapper product, set<string> selectedProducts, set<string> selectedIMSProducts)
			qpw.Selected = true;
			bg_WrapperHelper.UpdateIMSProductMap(quote.Id, imsProductMap, qpw, selectedProducts, selectedIMSProducts, allSelectedIMS);

			//TEST: UpdateIMSProductMap(Id quoteId, map<string, bg_Wrappers.IMSWrapper> IMSProductMap, map<string, bg_Wrappers.QuoteProductWrapper> productMap, set<string> selectedProducts, set<string> selectedIMSProducts)
			qpw.Selected = false;
			bg_WrapperHelper.UpdateIMSProductMap(quote.Id, imsProductMap, quoteProductMap, selectedProducts, selectedIMSProducts, allSelectedIMS);	
		test.stopTest();
	}

	private static testMethod void testCreateQuoteProductWrapper2() {
		/*
			Test CreateQuoteProductWrapper and CreateQuoteProductWrappers Method
		*/
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Product_Classification__c pc = bg_UnitTestHelper.GetProductClassification2(product.Name, 'StreamA', product.Portfolio_Interest__c, product.Product_Area_Interest__c, product);
		
		test.startTest();

			list<Product_Classification__c> pcList = new list<Product_Classification__c>{pc};
			list<bg_Wrappers.ProductWrapper> pwList = bg_WrapperHelper.CreateProductWrappers(pcList);
			system.assertEquals(1, pwList.size());
			
			bg_Wrappers.ProductWrapper pw =  bg_WrapperHelper.CreateProductWrapper(pc);
			system.assertNotEquals(null, pw);

			bg_Wrappers.ProductWrapper qpw1 = bg_WrapperHelper.CreateQuoteProductWrapper(pc);
			system.assertNotEquals(null, qpw1);
			
			bg_Wrappers.ProductWrapper qpw2 = bg_WrapperHelper.CreateQuoteProductWrapper(product, pc);
			system.assertNotEquals(null, qpw2);
 		test.stopTest();
	}

	private static testMethod void testCheckForSamplingAvailable() {
		/*
			Test CheckForSamplingAvailable Method
		*/
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Product__c questionProduct = bg_UnitTestHelper.GetQuestionProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.QuoteProductWrapper>{qpw});
 		bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(0, site, true);
		list<bg_Wrappers.SiteWrapper> sites = new list<bg_Wrappers.SiteWrapper>{sw};
		bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites);

		map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap = new map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>>();
		samplingMap = bg_WrapperHelper.CreateSamplingMap(sites, quoteProductMap);
		qpw.SitesMap.values()[0].RegistrationPath = 'New Registration';
        qpw.GridView = true;
		bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, qpw, sw, qpw.SitesMap.values()[0]);
		
		boolean sampleWarnings = false;

		test.startTest();
			sampleWarnings = bg_WrapperHelper.CheckForSamplingAvailable(quote.Id, 1, samplingMap, qpw, false);
			system.assertEquals(false, sampleWarnings);
			system.assertEquals(false, qpw.SamplingAvailable);

			sampleWarnings = bg_WrapperHelper.CheckForSamplingAvailable(quote.Id, 0, samplingMap, qpw, false);
			system.assertEquals(false, sampleWarnings);
			system.assertEquals(true, qpw.SamplingAvailable);
 		test.stopTest();
	}

	private static testMethod void testGetSiteKeys() {
		/*
			Test GetSiteKeys
		*/

		list<integer> results;
		set<integer> siteIndexes = new set<integer>();
		integer values = 20;
		for(integer i=1; i<=values; i++) {
			siteIndexes.add(i);
		}
			
		test.startTest();
			results = bg_WrapperHelper.GetSiteKeys(siteIndexes, true);
			system.assertEquals(siteIndexes.size(), results.size());
			
			for(integer i=1; i<=values; i++) {
				system.assertEquals(i, results[i-1]);
			}

			results = bg_WrapperHelper.GetSiteKeys(siteIndexes, false);
			system.assertEquals(siteIndexes.size(), results.size());

			boolean diff = false;
			for(integer i=1; i<=values; i++) {
				if(results[i-1] != i) { diff = true; }
			}

			system.assertEquals(true, diff);

			// Check for dupes
			set<integer> resultsSet = new set<integer>(results);
			system.assertEquals(siteIndexes.size(),resultsSet.size());
		test.stopTest();
	}

	private static testMethod void testApplySampling() {
		/*
			Test ApplySampling
		*/
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT-WH-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Gridview__C = true;
		update product;
		Product__c questionProduct = bg_UnitTestHelper.GetQuestionProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new list<bg_Wrappers.QuoteProductWrapper>{qpw});

		qpw.SamplingThreshold = 2;
		
		list<bg_Wrappers.SiteWrapper> sites = new list<bg_Wrappers.SiteWrapper>();
		for(integer i=0 ; i<=99; i++) {
			bg_Wrappers.SiteWrapper sw = bg_WrapperHelper.CreateSiteWrapper(i, site, true);
			sites.add(sw);
		}		
		bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites);

		map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap;
		samplingMap = bg_WrapperHelper.CreateSamplingMap(sites, quoteProductMap);

		for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) {
			psw.RegistrationPath = 'New Registration';
			bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, qpw, psw.site, psw);
		}
		
		bg_WrapperHelper.CheckForSamplingAvailable(quote.Id, qpw.SamplingThreshold, samplingMap, qpw, false);
		
		qpw.UseSampling = true;
		qpw.VerifiedForSampling = true;
		qpw.SamplingAvailable = true;

		test.startTest();
			bg_WrapperHelper.ApplySampling(qpw.SamplingThreshold, samplingMap, qpw);	
		test.stopTest();
		
		integer selectedCount = 0;
		for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) {
			if(psw.Selected) { selectedCount++; }
		}
	
		system.assertEquals(10, selectedCount);		
	}

	private static testMethod void testCalculateMinSampleSize_1inN() {
		/*
			Test CalculateMinSampleSize_1inN 
		*/
		system.assertEquals(20, bg_WrapperHelper.CalculateMinSampleSize_1inN(20, 20, 5));
		system.assertEquals(21, bg_WrapperHelper.CalculateMinSampleSize_1inN(21, 20, 5));
		system.assertEquals(21, bg_WrapperHelper.CalculateMinSampleSize_1inN(22, 20, 5));	
		system.assertEquals(21, bg_WrapperHelper.CalculateMinSampleSize_1inN(23, 20, 5));	
		system.assertEquals(21, bg_WrapperHelper.CalculateMinSampleSize_1inN(24, 20, 5));
		system.assertEquals(21, bg_WrapperHelper.CalculateMinSampleSize_1inN(25, 20, 5));
		system.assertEquals(22, bg_WrapperHelper.CalculateMinSampleSize_1inN(26, 20, 5));	
		system.assertEquals(22, bg_WrapperHelper.CalculateMinSampleSize_1inN(27, 20, 5));
		system.assertEquals(22, bg_WrapperHelper.CalculateMinSampleSize_1inN(28, 20, 5));
	}

	private static testMethod void testCalculateMinSampleSize_Sqrt() {
		/*
			Test CalculateMinSampleSize_Sqrt 
		*/
		system.assertEquals(2, bg_WrapperHelper.CalculateMinSampleSize_Sqrt(4));
		system.assertEquals(3, bg_WrapperHelper.CalculateMinSampleSize_Sqrt(5));
		system.assertEquals(3, bg_WrapperHelper.CalculateMinSampleSize_Sqrt(6));
		system.assertEquals(3, bg_WrapperHelper.CalculateMinSampleSize_Sqrt(7));
		system.assertEquals(3, bg_WrapperHelper.CalculateMinSampleSize_Sqrt(8));										
		system.assertEquals(3, bg_WrapperHelper.CalculateMinSampleSize_Sqrt(9));
		system.assertEquals(4, bg_WrapperHelper.CalculateMinSampleSize_Sqrt(16));
		system.assertEquals(5, bg_WrapperHelper.CalculateMinSampleSize_Sqrt(25));
	}		

	
	/*
		Test for CreateProjectWrappers
		Null value for projects parameter
	*/
	static testMethod void testCreateProjectWrappersNullParameter()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		

		List<Project__c> projects;
		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(null);
		
		system.assertEquals(true, results != null);
		system.assertEquals(true, results.isEmpty());
	}

	/*
		Test for CreateProjectWrappers
		Empty List for projects parameter
	*/
	static testMethod void testCreateProjectWrappersEmptyParameter()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		

		List<Project__c> projects = new List<Project__c>();
		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(projects);
		
		system.assertEquals(true, results != null);
		system.assertEquals(true, results.isEmpty());
	}

	/*
		Test for CreateProjectWrappers
		Single Project
	*/
	static testMethod void testCreateProjectWrappersSingleProject()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		
		Project__c projectToTest = testProjectsActive[0];
	
		List<Project__c> projects = new List<Project__c>();
		projects.add(projectToTest);
		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(projects);
		
		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(1, results.size());
		system.assertEquals(projectToTest.Id, results[0].Id);
		system.assertEquals(projectToTest.Active__c, results[0].Active);
	}
	
	/*
		Test for CreateProjectWrappers
		Multiple Projects
	*/
	static testMethod void testCreateProjectWrappersMultipleProjects()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		
		Map<Id, Project__c> projectsToTest = new Map<Id, Project__c>();
		projectsToTest.putAll(testProjectsActive);
	
		List<Project__c> projects = new List<Project__c>();
		projects.addAll(testProjectsActive);
		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(projects);
		
		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(projectCount, results.size());
		for (bg_Wrappers.ProjectWrapper result : results)
		{
			system.assertEquals(true, projectsToTest.containsKey(result.Id));
			system.assertEquals(projectsToTest.get(result.Id).Active__c, result.Active);
		}
	}
	

	/*
		Test for CreateProjectWrappers
		Null values for parameter
	*/
	static testMethod void testCreateProjectWrappersNullParameters()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		

		List<Project__c> projects;
		Set<String> selectedProjects;
		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(null, null);
		
		system.assertEquals(true, results != null);
		system.assertEquals(true, results.isEmpty());
	}

	/*
		Test for CreateProjectWrappers
		Empty Lists for  parameters
	*/
	static testMethod void testCreateProjectWrappersEmptyParameters()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		

		List<Project__c> projects = new List<Project__c>();
		Set<String> selectedProjects = new Set<String>();
		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(projects, selectedProjects);
		
		system.assertEquals(true, results != null);
		system.assertEquals(true, results.isEmpty());
	}

	/*
		Test for CreateProjectWrappers
		Single Project - not selected
	*/
	static testMethod void testCreateProjectWrappersSingleProjectNotSelected()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		
		Project__c projectToTest = testProjectsActive[0];
	
		List<Project__c> projects = new List<Project__c>();
		Set<String> selectedProjects = new Set<String>();
		projects.add(projectToTest);
		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(projects, selectedProjects);
		
		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(1, results.size());
		system.assertEquals(projectToTest.Id, results[0].Id);
		system.assertEquals(false, results[0].Selected);
	}


	/*
		Test for CreateProjectWrappers
		Single Project -  selected
	*/
	static testMethod void testCreateProjectWrappersSingleProjectSelected()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		
		Project__c projectToTest = testProjectsActive[0];
	
		List<Project__c> projects = new List<Project__c>();
		Set<String> selectedProjects = new Set<String>();
		projects.add(projectToTest);
		selectedProjects.add(projectToTest.Name);
		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(projects, selectedProjects);
		
		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(1, results.size());
		system.assertEquals(projectToTest.Id, results[0].Id);
		system.assertEquals(true, results[0].Selected);
	}
	
	/*
		Test for CreateProjectWrappers
		Multiple Projects - mixed selection
	*/
	static testMethod void testCreateProjectWrappersMultipleProjectsMixedSelection()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}

		insert testProjectsActive;

		Map<Id, Project__c> projectsToTest = new Map<Id, Project__c>();
		projectsToTest.putAll(testProjectsActive);
	
		List<Project__c> projects = new List<Project__c>();
		projects.addAll(testProjectsActive);
		Set<String> selectedProjects = new Set<String>();
		
		Boolean selected = true;
		for (Project__c testProject : testProjectsActive)
		{
			if (selected)
			{
				selectedProjects.add(testProject.Name);
			}
			selected = !selected;
		}

		List<bg_Wrappers.ProjectWrapper> results;
		
		results = bg_WrapperHelper.CreateProjectWrappers(projects, selectedProjects);
		
		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(projectCount, results.size());
		for (bg_Wrappers.ProjectWrapper result : results)
		{
			system.assertEquals(true, projectsToTest.containsKey(result.Id));
			system.assertEquals(projectsToTest.get(result.Id).Active__c, result.Active);
			if (selectedProjects.contains(result.Name))
			{
				system.assert(result.Selected);
			}
		}
	}



	/*
		Test for CreateProjectWrapper
		Null values for parameter
	*/
	static testMethod void testCreateProjectWrapperNullParameters()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		

		Project__c testProject;
		Set<String> selectedProjects;
		bg_Wrappers.ProjectWrapper result;
		
		result = bg_WrapperHelper.CreateProjectWrapper(null, null);
		
		system.assertEquals(true, result != null);
		system.assertEquals(true, result.Project == null);
		
	}

	/*
		Test for CreateProjectWrapper
		Single Project Null List for selections
	*/
	static testMethod void testCreateProjectWrapperSingleProjectNullSelections()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;

		//  Refresh inserted projects list in order to obtain Project Name
		Map<Id, Project__c> newProjects = new Map<Id, Project__c>();
		newProjects.putAll(testProjectsActive);
		
		testProjectsActive.clear();
		testProjectsActive.addAll([SELECT	Id, Name, Active__c, Project_Status__c, Area_of_Practice__c, Project_Family__c,
											Account__c, Project_Template__c
								   FROM		Project__c
								   WHERE	Id IN :newProjects.keySet()]);
		

		Project__c testProject = testProjectsActive[0];
		Set<String> selectedProjects;
		bg_Wrappers.ProjectWrapper result;
		
		result = bg_WrapperHelper.CreateProjectWrapper(testProject, null);
		
		system.assertEquals(true, result != null);
		system.assertEquals(testProject.Id, result.Id);
		system.assertEquals(false, result.Selected);
	}

	/*
		Test for CreateProjectWrapper
		Single Project Empty List for selections
	*/
	static testMethod void testCreateProjectWrapperSingleProjectEmptySelections()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		
		//  Refresh inserted projects list in order to obtain Project Name
		Map<Id, Project__c> newProjects = new Map<Id, Project__c>();
		newProjects.putAll(testProjectsActive);
		
		testProjectsActive.clear();
		testProjectsActive.addAll([SELECT	Id, Name, Active__c, Project_Status__c, Area_of_Practice__c, Project_Family__c,
											Account__c, Project_Template__c
								   FROM		Project__c
								   WHERE	Id IN :newProjects.keySet()]);

		Project__c testProject = testProjectsActive[0];
		Set<String> selectedProjects = new Set<String>();
		bg_Wrappers.ProjectWrapper result;
		
		result = bg_WrapperHelper.CreateProjectWrapper(testProject, selectedProjects);
		
		system.assertEquals(true, result != null);
		system.assertEquals(testProject.Id, result.Id);
		system.assertEquals(false, result.Selected);
	}


	/*
		Test for CreateProjectWrapper
		Single Project - not selected but selected list supplied
	*/
	static testMethod void testCreateProjectWrapperSingleProjectNotSelected()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;

		//  Refresh inserted projects list in order to obtain Project Name
		Map<Id, Project__c> newProjects = new Map<Id, Project__c>();
		newProjects.putAll(testProjectsActive);
		
		testProjectsActive.clear();
		testProjectsActive.addAll([SELECT	Id, Name, Active__c, Project_Status__c, Area_of_Practice__c, Project_Family__c,
											Account__c, Project_Template__c
								   FROM		Project__c
								   WHERE	Id IN :newProjects.keySet()]);
		
		Project__c testProject = testProjectsActive[0];
		Set<String> selectedProjects = new Set<String>();
		for (Project__c newProject : testProjectsActive)
		{
			if (newProject.Id != testProject.Id)
			{
				selectedProjects.add(newProject.Name);
			}
		}
		
		system.assertEquals(projectCount - 1, selectedProjects.size());
		system.assertEquals(false, selectedProjects.contains(testProject.Name));

		bg_Wrappers.ProjectWrapper result;
		
		result = bg_WrapperHelper.CreateProjectWrapper(testProject, selectedProjects);
		
		system.assertEquals(true, result != null);
		system.assertEquals(testProject.Id, result.Id);
		system.assertEquals(false, result.Selected);
	}


	/*
		Test for CreateProjectWrapper
		Single Project - Only Selected
	*/
	static testMethod void testCreateProjectWrapperSingleProjectOnlySelected()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;
		
		//  Refresh inserted projects list in order to obtain Project Name
		Map<Id, Project__c> newProjects = new Map<Id, Project__c>();
		newProjects.putAll(testProjectsActive);
		
		testProjectsActive.clear();
		testProjectsActive.addAll([SELECT	Id, Name, Active__c, Project_Status__c, Area_of_Practice__c, Project_Family__c,
											Account__c, Project_Template__c
								   FROM		Project__c
								   WHERE	Id IN :newProjects.keySet()]);

		Project__c testProject = testProjectsActive[0];
		Set<String> selectedProjects = new Set<String>();
		selectedProjects.add(testProject.Name);
		bg_Wrappers.ProjectWrapper result;
		
		result = bg_WrapperHelper.CreateProjectWrapper(testProject, selectedProjects);
		
		system.assertEquals(true, result != null);
		system.assertEquals(testProject.Id, result.Id);
		system.assertEquals(true, result.Selected);
	}

	/*
		Test for CreateProjectWrapper
		Single Project - Included in Selected List
	*/
	static testMethod void testCreateProjectWrapperSingleProjectIncludedInSelected()
	{
		Account testAccount = bg_UnitTestHelper.GetAccount('Project Wrapper Tests Account');
		Integer projectCount = 5;
		List<Project__c> testProjectsActive = new List<Project__c>();
		for (Integer iterator=0; iterator<projectCount; iterator++)
		{
			Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Wrapper Project Name - ' + iterator, true);
			testProjectsActive.add(testProject);
		}
		insert testProjectsActive;

		//  Refresh inserted projects list in order to obtain Project Name
		Map<Id, Project__c> newProjects = new Map<Id, Project__c>();
		newProjects.putAll(testProjectsActive);
		
		testProjectsActive.clear();
		testProjectsActive.addAll([SELECT	Id, Name, Active__c, Project_Status__c, Area_of_Practice__c, Project_Family__c,
											Account__c, Project_Template__c
								   FROM		Project__c
								   WHERE	Id IN :newProjects.keySet()]);
		
		Project__c testProject = testProjectsActive[0];
		Set<String> selectedProjects = new Set<String>();

		for (Project__c newProject : testProjectsActive)
		{
			selectedProjects.add(newProject.Name);
		}
		
		system.assertEquals(projectCount, selectedProjects.size());
		system.assertEquals(true, selectedProjects.contains(testProject.Name));

		bg_Wrappers.ProjectWrapper result;
		
		result = bg_WrapperHelper.CreateProjectWrapper(testProject, selectedProjects);
		
		system.assertEquals(true, result != null);
		system.assertEquals(testProject.Id, result.Id);
		system.assertEquals(true, result.Selected);
	}

	/*
		public static list<SelectOption> GetControllingLocations(List<bg_Wrappers.ProductSiteWrapper> productSiteWrappers) {
	*/

	/*
		Test for GetControllingLocations
		Null productSiteWrappers
	*/
	static testMethod void testGetControllingLocationsNull()
	{
		List<bg_Wrappers.ProductSiteWrapper> productSiteWrappers;
		List<SelectOption> results;
		String firstOption = '--' + Label.None + '--';
		
		results =  bg_WrapperHelper.GetControllingLocations(null);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty()); // Expected return is a single value derived from the custom label - none.
		system.assertEquals(1, results.size());
		system.assertEquals(firstOption, results[0].getLabel());
	}
	
	/*
		Test for GetControllingLocations
		Empty productSiteWrappers
	*/
	static testMethod void testGetControllingLocationsEmpty()
	{
		List<bg_Wrappers.ProductSiteWrapper> productSiteWrappers = new List<bg_Wrappers.ProductSiteWrapper>();
		List<SelectOption> results;
		String firstOption = '--' + Label.None + '--';
		
		results =  bg_WrapperHelper.GetControllingLocations(productSiteWrappers);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty()); // Expected return is a single value derived from the custom label - none.
		system.assertEquals(1, results.size());
		system.assertEquals(firstOption, results[0].getLabel());
	}	

	/*
		Test for GetControllingLocations
		Single productSiteWrappers
	*/
	static testMethod void testGetControllingLocationsSingle()
	{
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();



		List<bg_Wrappers.ProductSiteWrapper> productSiteWrappers = new List<bg_Wrappers.ProductSiteWrapper>();
		List<SelectOption> results;
		String firstOption = '--' + Label.None + '--';
		String productName = 'Test Wrapper Product';

		Integer siteCount = 5;
		Account testAccount = bg_UnitTestHelper.GetAccount('Site Wrapper Tests Account');
		Contact testContact = bg_UnitTestHelper.GetContact('UT-WRAPPER-CON', testAccount);		
		
		List<Site__c> testSites = new List<Site__c>();
		for (Integer iterator=0; iterator<siteCount; iterator++)
		{
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_WRAPPER_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB');
			testSites.add(testSite);
		}
		
		insert testSites;

		Site__c siteToTest = testSites[0];

		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, siteToTest);
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		Map<String, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new List<bg_Wrappers.QuoteProductWrapper>{qpw});
		bg_Wrappers.SiteWrapper testSiteWrapper = bg_WrapperHelper.CreateSiteWrapper(0, siteToTest, false);
		List<bg_Wrappers.SiteWrapper> sites = new List<bg_Wrappers.SiteWrapper>{testSiteWrapper};
 		Map<Id, Contact> contactMap = new Map<Id, Contact>();
 		contactMap.put(testContact.Id, testContact);
		List<Quote_Product__c> quoteProducts = new List<Quote_Product__c>{quoteProduct};

		
		bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites);
		system.assertEquals(false, qpw.SitesMap.isEmpty());
		
		
		bg_Wrappers.ProductSiteWrapper testProductSiteWrapper = qpw.SitesMap.values()[0];  
		system.assertEquals(siteToTest.Id, testProductSiteWrapper.Site.Id);
		
		productSiteWrappers.add(testProductSiteWrapper);
		
		results =  bg_WrapperHelper.GetControllingLocations(productSiteWrappers);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty()); // Expected return is a single value derived from the custom label - none.
		system.assertEquals(2, results.size());
		system.assertEquals(firstOption, results[0].getLabel());
		system.assertEquals(siteToTest.Id, results[1].getValue());
		system.assertEquals(siteToTest.Name, results[1].getLabel());
	}	


	/*
		Test for GetControllingLocations
		Multiple productSiteWrappers Non PS Product
	*/
	static testMethod void testGetControllingLocationsMultipleNoPS()
	{
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();



		List<bg_Wrappers.ProductSiteWrapper> productSiteWrappers = new List<bg_Wrappers.ProductSiteWrapper>();
		List<SelectOption> results;
		String firstOption = '--' + Label.None + '--';
		String productName = 'Test Wrapper Product';

		Integer siteCount = 5;
		Account testAccount = bg_UnitTestHelper.GetAccount('Site Wrapper Tests Account');
		Contact testContact = bg_UnitTestHelper.GetContact('UT-WRAPPER-CON', testAccount);	
		Opportunity testOpp = bg_UnitTestHelper.GetOpportunity(testAccount);
			
		
		List<Site__c> testSites = new List<Site__c>();
		for (Integer iterator=0; iterator<siteCount; iterator++)
		{
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_WRAPPER_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB');
			testSites.add(testSite);
		}
		
		insert testSites;

		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Gridview__C = true;
		update product;
		Quote__c quote = bg_UnitTestHelper.GetQuote(testOpp);
		List<Quote_Product__c> quoteProducts = new List<Quote_Product__c>();
		List<bg_Wrappers.SiteWrapper> sites = new List<bg_Wrappers.SiteWrapper>();
		List<OpportunitySite__c> oppSites = new List<OpportunitySite__c>();

		for (Site__c siteToTest : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpp, siteToTest, false);
			oppSites.add(testOppSite);
		}
		insert oppSites;
		
 		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c siteToTest = testSites[iterator];
			OpportunitySite__c testOppSite = oppSites[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, testContact, product, siteToTest, testOpp, testOppSite);
			quoteProducts.add(quoteProduct);
			bg_Wrappers.SiteWrapper testSiteWrapper = bg_WrapperHelper.CreateSiteWrapper(iterator, siteToTest, false);
			sites.add(testSiteWrapper);
		}
		insert quoteProducts;
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		Map<String, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new List<bg_Wrappers.QuoteProductWrapper>{qpw});
		
		
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
 		contactMap.put(testContact.Id, testContact);
		
		
		bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites);

		
		system.assertEquals(false, qpw.SitesMap.isEmpty());
				
		productSiteWrappers.addAll(qpw.SitesMap.values());
		Map<Id, Site__c> siteMap = new Map<Id, Site__c>();
		siteMap.putAll(testSites);
		results =  bg_WrapperHelper.GetControllingLocations(productSiteWrappers);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty()); 
		system.assertEquals(siteCount + 1, results.size());
		system.assertEquals(firstOption, results[0].getLabel());

		for (Integer iterator=1; iterator<siteCount; iterator++)
		{
			system.assertEquals(true, siteMap.containsKey(results[iterator].getValue()));
			system.assertEquals(true, siteMap.get(results[iterator].getValue()).Name == results[iterator].getLabel());
		}
	}	

	/*
		Test for GetControllingLocations
		Multiple productSiteWrappers  PS Product
	*/
	static testMethod void testGetControllingLocationsMultiplePSProduct()
	{
 		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		bg_UnitTestHelper.GetSiteSettings();



		List<bg_Wrappers.ProductSiteWrapper> productSiteWrappers = new List<bg_Wrappers.ProductSiteWrapper>();
		List<SelectOption> results;
		String firstOption = '--' + Label.None + '--';
		String productName = 'Test Wrapper Product';

		Integer siteCount = 5;
		Account testAccount = bg_UnitTestHelper.GetAccount('Site Wrapper Tests Account');
		Contact testContact = bg_UnitTestHelper.GetContact('UT-WRAPPER-CON', testAccount);	
		Opportunity testOpp = bg_UnitTestHelper.GetOpportunity(testAccount);
			
		
		List<Site__c> testSites = new List<Site__c>();
		for (Integer iterator=0; iterator<siteCount; iterator++)
		{
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_WRAPPER_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB');
			testSites.add(testSite);
		}
		
		insert testSites;

		Product__c product = bg_UnitTestHelper.CreateProduct(productName, true, 'PS_UT_WRAPPER_PORTFOLIO', 'PS_UT_WRAPPER_AREA', null, null, null);
		product.Product_Stream__c = bg_ProductUtils.PRODUCT_STREAM_PS;
		insert product;
		
		Quote__c quote = bg_UnitTestHelper.GetQuote(testOpp);
		List<Quote_Product__c> quoteProducts = new List<Quote_Product__c>();
		List<bg_Wrappers.SiteWrapper> sites = new List<bg_Wrappers.SiteWrapper>();
		List<OpportunitySite__c> oppSites = new List<OpportunitySite__c>();

		for (Site__c siteToTest : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpp, siteToTest, false);
			oppSites.add(testOppSite);
		}
		insert oppSites;
		
 		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c siteToTest = testSites[iterator];
			OpportunitySite__c testOppSite = oppSites[iterator];
			Quote_Product__c quoteProduct = bg_UnitTestHelper.CreateQuoteProduct(quote, testContact, product, siteToTest, testOpp, testOppSite);
			quoteProducts.add(quoteProduct);
			bg_Wrappers.SiteWrapper testSiteWrapper = bg_WrapperHelper.CreateSiteWrapper(iterator, siteToTest, false);
			sites.add(testSiteWrapper);
		}
		insert quoteProducts;
 				
		// Initialise method parameters
 		bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);
		Map<String, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(new List<bg_Wrappers.QuoteProductWrapper>{qpw});
		
		
		Map<Id, Contact> contactMap = new Map<Id, Contact>();
 		contactMap.put(testContact.Id, testContact);
		
		
		bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites);

		
		system.assertEquals(false, qpw.SitesMap.isEmpty());
				
		productSiteWrappers.addAll(qpw.SitesMap.values());
		Map<Id, Site__c> siteMap = new Map<Id, Site__c>();
		siteMap.putAll(testSites);
		Site__c siteToTest = testSites[0];
		results =  bg_WrapperHelper.GetControllingLocations(productSiteWrappers);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty()); 
		system.assertEquals(2, results.size());
		system.assertEquals(firstOption, results[0].getLabel());
		system.assertEquals(siteToTest.Id, results[1].getValue());
		system.assertEquals(siteToTest.Name, results[1].getLabel());
	}	
}