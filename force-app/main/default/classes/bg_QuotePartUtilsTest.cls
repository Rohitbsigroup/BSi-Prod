/********************************************************************
 * bg_QuotePartUtilsTest
 *
 * Test methods for Quote Part Utility class
 * 
 * 
 * Author: Richard Jimenez
 * Created: 06-12-2013
 * Changes: 
 * KM 		29-10-2014	Added testResetDiscountsOnQuote (deleted)
 *
 * CB       20-08-2014  Removed seealldata = true from the test methods, replaced standard prciebook selection with new standard pricebook entry methods
 * IB		14-08-2017  Added @testmethod annotations, removed test for deprecated methods, fixed testPopulatePartExtendedValues added testGetConvertedPriceInQuotePartCurrency()
 * CPE		18/09/2017	New tests for UpdateQuotePartFromPricebookEntry
 * ADS      06/11/2017  Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
 * ADS 		12/02/2018  Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
 ********************************************************************/
@isTest 
private class bg_QuotePartUtilsTest {

	private static testmethod void testPopulatePartExtendedValues() {
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
		
		Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
		PricebookEntry spbeUSD = bg_UnitTestHelper.createStandardPriceBookEntry(prod.Id, 100, 'USD');		
		
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
		List<Quote_Part__c> qpList = new List<Quote_Part__c>();
		qpList.add(quotePart);
		Map<Id, Quote_Part__c> qpmap = new Map<Id, Quote_Part__c>();
		qpMap.put(quotePart.Id, quotePart);

		Pricebook2 pb = bg_PricebookUtils.GetPricebookByName('UT-Pricebook');
		
		PricebookEntry pbe  = bg_UnitTestHelper.GetPricebookEntry(pb.Id,  prod.Id, 'USD', 100.0);

		quotePart.Price_Book__c = pb.Id;
		quotePart.Product2__c = prod.Id;
		quotePart.Info__c = 'Country:US;' + bg_QuotePartUtils.INFOTEXT_USELOCALPRICES + ':True;';
		update quotePart;
				
		// Create Quote Products
		list<Quote_Part__c> quoteParts = new list<Quote_Part__c>{quotePart};

		test.startTest();
			bg_QuotePartUtils.PopulatePartExtendedValues(quoteParts);
			system.assertEquals(true, quotePart.Part_Extended_Value__c != null);
		test.stopTest();
	}

	private static testmethod void testPopulatePartExtendedValues2() {
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
		Product2 prod = bg_UnitTestHelper.GetProductFee(productName);

		Pricebook2 pb = bg_PricebookUtils.GetPricebookByName('UT-Pricebook');
		
		PricebookEntry spbe = bg_UnitTestHelper.createStandardPriceBookEntry(prod.Id, 100, 'USD');
		PricebookEntry pbe  = bg_UnitTestHelper.GetPricebookEntry(pb.Id,  prod.Id, 'USD', 100.0);
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
		List<Quote_Part__c> qpList = new List<Quote_Part__c>();
		qpList.add(quotePart);
		Map<Id, Quote_Part__c> qpmap = new Map<Id, Quote_Part__c>();
		qpMap.put(quotePart.Id, quotePart);

		quotePart.Price_Book__c = pb.Id;
		quotePart.Product2__c = prod.Id;
		quotePart.Info__c = 'Country:US;' + bg_QuotePartUtils.INFOTEXT_USELOCALPRICES + ':True;';
		update quotePart;
		
		Part_Extended_Value__c pev = new Part_Extended_Value__c();
		pev.Price_Book__c = pb.Id;
		pev.Product__c = prod.Id;
		insert pev;
				
		list<Quote_Part__c> quoteParts = new list<Quote_Part__c>{quotePart};

		test.startTest();
		bg_QuotePartUtils.PopulatePartExtendedValues(quoteParts);
		system.assertEquals(true, quotePart.Part_Extended_Value__c != null);
			
		test.stopTest();
	}

	
	private static testMethod void testUpdateExchangeRates(){
		/*
			Test UpdateExchangeRates Method
		*/

		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);

		// set quote and quote part currency codes		
		quote.CurrencyIsoCode = 'USD';
		quotePart.CurrencyIsoCode = 'USD';

		test.startTest();
		bg_QuotePartUtils.UpdateExchangeRates(quote, new list<Quote_Part__c>{quotePart}, true);
		test.stopTest();
		
		system.assertEquals(1, quotePart.Exchange_Rate__c);
	}
	
	private static testMethod void testGetQuoteProductValues() {
		/*
			Test GetQuoteProductValues Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';

		Product__c product = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);

		string textValue = 'UT-TEXT';
		string alias = 'UT-QUESTION';
		PropertyValue__c pv = bg_UnitTestHelper.GetPropertyValue(alias, quoteProduct.Id, textValue);

		test.startTest();
		system.assertEquals(1, bg_QuotePartUtils.GetQuoteProductValues(quote.Id, productName, alias, textValue).size());
		test.stopTest();	
	}
	
	private static testMethod void testHasHalfDayPrices() {
		/*
			Test HasHalfDayPrices Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		set<string> countryCodes = new set<string>();
		test.startTest();
			system.assertEquals(false, bg_QuotePartUtils.HasHalfDayPrices(quote.Id, countryCodes));
		test.stopTest();
	}
	
	private static testMethod void testCheckQuotePartsBelowGridMax() {
		/*
			Test HasHalfDayPrices Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		test.startTest();
			system.assertEquals(true, bg_QuotePartUtils.CheckQuotePartsBelowGridMax(quote.Id, 1));
		test.stopTest();		
	}

	private static testmethod void testCreateQuotePartExtension()
	{
		Product2 prod = bg_UnitTestHelper.GetProductFee('TestProd');
		Pricebook2 pb = new Pricebook2();
		pb.Name = 'TestPriceBook';
		pb.Year__c = '2015';
		insert pb;
		
		Part_Extended_Value__c pevResult = bg_QuotePartUtils.CreateQuotePartExtension(pb.Id, prod.Id);
		system.assertEquals(true, pevResult != null);
		system.assertEquals(pb.Id, pevResult.Price_Book__c);
	}	
	
	public static testmethod void testGetConvertedPriceInQuotePartCurrency()
	{
		
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		opp.CurrencyISOCode = 'USD';
		update opp; 
		
		string productName = 'ISO 9001';
		Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
		
		System.debug(Logginglevel.ERROR, 'prod.Id' + prod.Id);
		System.debug(Logginglevel.ERROR, 'opp.CurrencyIsoCode' + opp.CurrencyIsoCode);
		PricebookEntry spbeUSD = bg_UnitTestHelper.createStandardPriceBookEntry(prod.Id, 100, opp.CurrencyIsoCode);
		PricebookEntry spbeGBP = bg_UnitTestHelper.createStandardPriceBookEntry(prod.Id, 80, 'GBP');
		
        // Create custom price books
        Pricebook2 pricebookUS = bg_UnitTestHelper.getPricebook('PB US', 'US');
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');

		PricebookEntry pbeUSD  = bg_UnitTestHelper.GetPricebookEntry(pricebookUS.Id,  prod.Id, 'USD', 100.0);
		PricebookEntry pbeGBP  = bg_UnitTestHelper.GetPricebookEntry(pricebookGB.Id,  prod.Id, 'GBP', 80.0);
		
		Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
		
		// paranInput: Price to convert, Quote Part Currency, Main Quote Currency
		Decimal priceToConvert = 100.00;
		String quotePartCurrency = 'USD';
		String mainQuoteCurrency = 'GBP';
		
		Decimal convertedPrice = bg_QuotePartUtils.getConvertedPriceInQuotePartCurrency(priceToConvert, quotePartCurrency, mainQuoteCurrency);
		System.debug('+++ convertedPrice = ' + convertedPrice);
		System.assertNotEquals(null, convertedPrice);
		System.assertNotEquals(0, convertedPrice);
		System.assertNotEquals(priceToConvert, convertedPrice);
		
		priceToConvert = 0.00;
		convertedPrice = bg_QuotePartUtils.getConvertedPriceInQuotePartCurrency(priceToConvert, quotePartCurrency, mainQuoteCurrency);
		// price to convert 0, no conversion
		System.assertEquals(convertedPrice, priceToConvert);
		
		priceToConvert = 100.00;
		mainQuoteCurrency = 'USD';
		convertedPrice = bg_QuotePartUtils.getConvertedPriceInQuotePartCurrency(priceToConvert, quotePartCurrency, mainQuoteCurrency);
		// currencies are the same, no conversion
		System.assertEquals(convertedPrice, priceToConvert);
		
		
	}
	
	
	/*
		public static void UpdateQuotePartFromPricebookEntry(Quote_Part__c quotePart, PricebookEntry priceBookEntry, String quoteCurrency)
	*/
	
	/*
		test UpdateQuotePartFromPricebookEntry
		Null values
	*/
	static testMethod void testUpdateQuotePartFromPricebookEntryNULLS()
	{
		// Setup Test Data
        Product2 ISO9001Prod = new Product2(Name = 'ISO9001-TEST-PRODUCT', Family = 'Hardware');
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
            
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');        
            
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,    
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_GB_GBP, ISO9001_GB_EUR};
        insert pricebookEntries;

		Quote_Part__c testQuotePart;
		PricebookEntry testPricebookEntry;
		String testCurrency;
		
		// TEST NULLS
		try
		{
			bg_QuotePartUtils.UpdateQuotePartFromPricebookEntry(testQuotePart, testPricebookEntry, testCurrency);
			system.assert(true);
		}
		catch (Exception ex)
		{
			system.assert(false, 'Error from UpdateQuotePartFromPricebookEntry - should not happen');
		}

		// QuotePart Populated
		testQuotePart = new Quote_Part__c(CurrencyISOCode = 'USD', List_Price__c = 0, Converted_List_Price__c = 0);
		try
		{
			bg_QuotePartUtils.UpdateQuotePartFromPricebookEntry(testQuotePart, testPricebookEntry, testCurrency);
			system.assertEquals('USD', testQuotePart.CurrencyISOCode);
			system.assertEquals(0, testQuotePart.List_Price__c);
			system.assertEquals(0, testQuotePart.Converted_List_Price__c);
		}
		catch (Exception ex)
		{
			system.assert(false, 'Error from UpdateQuotePartFromPricebookEntry - should not happen');
		}
		
		// PricebookEntry Populated
		testPricebookEntry = ISO9001_GB_GBP;
		try
		{
			bg_QuotePartUtils.UpdateQuotePartFromPricebookEntry(testQuotePart, testPricebookEntry, testCurrency);
			system.assertEquals('USD', testQuotePart.CurrencyISOCode);
			system.assertEquals(0, testQuotePart.List_Price__c);
			system.assertEquals(0, testQuotePart.Converted_List_Price__c);
		}
		catch (Exception ex)
		{
			system.assert(false, 'Error from UpdateQuotePartFromPricebookEntry - should not happen');
		}

		// Currency Populated
		testPricebookEntry = null;
		testCurrency = 'GBP';
		try
		{
			bg_QuotePartUtils.UpdateQuotePartFromPricebookEntry(testQuotePart, testPricebookEntry, testCurrency);
			system.assertEquals('USD', testQuotePart.CurrencyISOCode);
			system.assertEquals(0, testQuotePart.List_Price__c);
			system.assertEquals(0, testQuotePart.Converted_List_Price__c);
		}
		catch (Exception ex)
		{
			system.assert(false, 'Error from UpdateQuotePartFromPricebookEntry - should not happen');
		}
	}


	/*
		test UpdateQuotePartFromPricebookEntry
		Success
	*/
	static testMethod void testUpdateQuotePartFromPricebookEntrySuccess()
	{
		// Setup Test Data
        Product2 ISO9001Prod = new Product2(Name = 'ISO9001-TEST-PRODUCT', Family = 'Hardware');
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
        
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>{standardPrice, standardPrice2};
        insert standardPricebookEntries;
        
        // Create custom price books
        Pricebook2 pricebookGB = bg_UnitTestHelper.getPricebook('PB GB', 'GB');
        
        
        PricebookEntry ISO9001_GB_GBP = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,  
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 8000, IsActive = true, CurrencyIsoCode = 'GBP');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'GBP');
        
        PricebookEntry ISO9001_GB_EUR = new PricebookEntry(
        Pricebook2Id = pricebookGB.Id, Product2Id = ISO9001Prod.Id,   
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry            
            // UnitPrice = 10000, IsActive = true, CurrencyIsoCode = 'EUR');
            UnitPrice = 0.0, IsActive = true, CurrencyIsoCode = 'EUR');
                
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{ISO9001_GB_GBP, ISO9001_GB_EUR};
        insert pricebookEntries;

		Quote_Part__c testQuotePart;
		PricebookEntry testPricebookEntry;
		String testCurrency;
		
		
		testQuotePart = new Quote_Part__c(CurrencyISOCode = 'USD', List_Price__c = 0, Converted_List_Price__c = 0);
		testPricebookEntry = ISO9001_GB_GBP;
		testCurrency = 'EUR';
        // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
		// Decimal expectedConvetedPrice = bg_QuotePartUtils.getConvertedPriceInQuotePartCurrency(8000, 'GBP', 'EUR');
        Decimal expectedConvetedPrice = bg_QuotePartUtils.getConvertedPriceInQuotePartCurrency(0.0, 'GBP', 'EUR');

		try
		{
			bg_QuotePartUtils.UpdateQuotePartFromPricebookEntry(testQuotePart, testPricebookEntry, testCurrency);
			system.assertEquals('GBP', testQuotePart.CurrencyISOCode);
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
			// system.assertEquals(8000, testQuotePart.List_Price__c);
            system.assertEquals(0.0, testQuotePart.List_Price__c);
			system.assertEquals(expectedConvetedPrice, testQuotePart.Converted_List_Price__c);
		}
		catch (Exception ex)
		{
			system.assert(false, 'Error from UpdateQuotePartFromPricebookEntry - should not happen');
		}
		
	}






}