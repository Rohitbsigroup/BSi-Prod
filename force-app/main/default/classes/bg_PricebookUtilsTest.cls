/********************************************************************
 * bg_PricebookUtilsTest
 *
 * Test class for bg_PricebookUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 17-10-2013
 * Changes:
 * 			24-05-2017 - RC - BG created test methods for UpdateAccountLookupToMSA
 *							  and GetPricebookByDeveloperName 
 *			12-09-2017 - RC - Created test methods for GetTodaysExchangeRateMap, testGetPricebookEntryMap,
 *								testGetPriceBooksNonMSA, testBulkUpdateAccountLookupToMSA, testGetPriceBooksNonMsaNoDate,
 *								testGetPriceBooksNonMsaNoAccountId, testGetPriceBooksNonMsaNoCountryCodes
 *			15-09-2017 - CPE  New tests for FindPricebookEntryByCurrency and GetPriceBookEntriesByPricebookProduct
 *          19-01-2018 - ADS - Case 35054 - Ensure User running tests has appropriate permissions to create MSA Pricebooks
 *			12-02-2018 - ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
 ********************************************************************/
@isTest
private class bg_PricebookUtilsTest 
{
	public class PricebookTestException extends Exception{}
    
    /*
     * Ensure User running tests has appropriate permissions to create MSA Pricebooks
     */    
    private static void setUp()
    {
        
        if (!bg_CustomPermissionUtils.HasPermission(UserInfo.getUserId(), bg_CustomPermissionUtils.CAN_CREATE_MSA))
        {
            final List<CustomPermission> theCustomPermissionList = [SELECT Id,
                                                                    (SELECT ParentId 
                                                                     FROM SetupEntityAccessItems)
                                                                    FROM CustomPermission
                                                                    WHERE DeveloperName = :bg_CustomPermissionUtils.CAN_CREATE_MSA];
            
            System.assert(!theCustomPermissionList.isEmpty()); // at least one Permission Set must have the Custom Permission "Can Create MSA"                       
            
            final User theUser = [SELECT Id
                                  FROM User
                                  WHERE Id = :UserInfo.getUserId()];
            
            System.runAs(theUser)
            {
                final PermissionSetAssignment thePermissionSetAssignment = new PermissionSetAssignment();
                thePermissionSetAssignment.PermissionSetId = theCustomPermissionList[0].SetupEntityAccessItems[0].ParentId;
                thePermissionSetAssignment.AssigneeId = theUser.Id;
                insert thePermissionSetAssignment;                
            }

        }
        
    } // setUp

	/*
	*	Function to test UpdateAccountLookupToMSA see if it sets the lookup on account.
	*/
	private static testMethod void testUpdateAccountLookupToMSA()
	{
        setUp();
		Account acc = bg_UnitTestHelper.GetAccount('UT-Account');
		Pricebook2 pb = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US, 
			acc.Id, bg_PricebookUtils.GetPricebookByDeveloperName(bg_PricebookUtils.MSA_DEVELOPER_NAME).Id,
			date.today().Year());

		List<Pricebook2> pbList = new List<Pricebook2>();
		pbList.add(pb);

		bg_PricebookUtils.UpdateAccountLookupToMSA(pbList);

		//should have updated the lookup on the account.
		Account accQuery = [Select id, MSA_Pricebook__c FROM Account WHERE Id=:acc.Id];
		System.assertEquals(accQuery.MSA_Pricebook__c, pb.Id);
	}

	/*
	*	Function to test Bulk update of MSA lookup
	*/
	private static testMethod void testBulkUpdateAccountLookupToMSA()
	{
        setUp();
		//create multiple account and link them to msa pricesbooks
		List<Account> accList = new List<Account>();
		List<Pricebook2> pricebookList = new List<Pricebook2>();
		Map<Id, Pricebook2> pricebookMap = new Map<Id, Pricebook2>();
		accList= bg_UnitTestHelper.CreateAccountBulk(200);
		

		if(!accList.isEmpty())
		{
			insert accList;
		}

		//create multiple pricebooks and link them to the accounts
		for(Integer i=0; i<200; i++)
		{
			Pricebook2 pb = bg_UnitTestHelper.CreatePriceBook('UT_PRICEBOOKUTILS' + i, bg_SiteUtils.COUNTRY_CODE_US, 
			accList[i].Id, bg_PricebookUtils.GetPricebookByDeveloperName(bg_PricebookUtils.MSA_DEVELOPER_NAME).Id,
			date.today().Year());

			pricebookList.add(pb);

			//to keep track of which pricebook is under which account 
			pricebookMap.put(accList[i].Id, pb);
		}
		if(!pricebookList.isEmpty())
		{
			insert pricebookList;
		}

		bg_PricebookUtils.UpdateAccountLookupToMSA(pricebookList);

		//query all the accounts to see if they are linked to the correct pricebook.
		List<Account> accQueryList = [Select id, MSA_Pricebook__c FROM Account WHERE Id IN :accList]; 

		for(Account acc : accQueryList)
		{
			System.assertEquals(acc.MSA_Pricebook__c, pricebookMap.get(acc.Id).Id);
		}
	}

	/*
	*	Function to test getting a non msa pricebook
	*/
	private static testMethod void testGetPriceBooksNonMSA()
	{
        setUp();
		//create a msa pricebook and a non msa pricebook under same account
		Account acc = bg_UnitTestHelper.GetAccount('UT-Account');

		Pricebook2 pbMsa = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US,
			acc.Id, bg_PricebookUtils.GetPricebookByDeveloperName(bg_PricebookUtils.MSA_DEVELOPER_NAME).Id, 
			date.today().Year());

		Pricebook2 pb = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US,
			acc.Id, null, date.today().Year());

		set<String> countryCodes = new set<String>();
		countryCodes.add(bg_SiteUtils.COUNTRY_CODE_US);

		//test to see if pricebook query works with non msa
		List<Pricebook2> pricebookpb = bg_PricebookUtils.GetPriceBooksNonMSA(date.today().Year(), acc.Id, countryCodes, true);
		System.assertEquals(1, pricebookpb.size());
		System.assertEquals(pb.Id, pricebookpb[0].Id);
		
	}

	/*
	*	Function to test getting a non msa pricebook without date should still come back with results as query
	*	excludes the date.
	*/
	private static testMethod void testGetPriceBooksNonMsaNoDate()
	{
        setUp();
		//create a msa pricebook and a non msa pricebook under same account
		Account acc = bg_UnitTestHelper.GetAccount('UT-Account');

		Pricebook2 pbMsa = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US,
			acc.Id, bg_PricebookUtils.GetPricebookByDeveloperName(bg_PricebookUtils.MSA_DEVELOPER_NAME).Id, 
			date.today().Year());

		Pricebook2 pb = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US,
			acc.Id, null, date.today().Year());

		set<String> countryCodes = new set<String>();
		countryCodes.add(bg_SiteUtils.COUNTRY_CODE_US);

		//test to see if pricebook query works with non msa
		List<Pricebook2> pricebookpb = bg_PricebookUtils.GetPriceBooksNonMSA(null, acc.Id, countryCodes, true);
		System.assertEquals(1, pricebookpb.size());
		System.assertEquals(pb.Id, pricebookpb[0].Id);
	}

	/*
	*	Function to test getting a non msa pricebook without an account
	*/
	private static testMethod void testGetPriceBooksNonMsaNoAccountId()
	{
        setUp();
		//create a msa pricebook and a non msa pricebook under same account
		Account acc = bg_UnitTestHelper.GetAccount('UT-Account');

		Pricebook2 pbMsa = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US,
			acc.Id, bg_PricebookUtils.GetPricebookByDeveloperName(bg_PricebookUtils.MSA_DEVELOPER_NAME).Id, 
			date.today().Year());

		Pricebook2 pb = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US,
			acc.Id, null, date.today().Year());

		set<String> countryCodes = new set<String>();
		countryCodes.add(bg_SiteUtils.COUNTRY_CODE_US);

		//test to see if pricebook query works with non msa
		List<Pricebook2> pricebookpb = bg_PricebookUtils.GetPriceBooksNonMSA(date.today().Year(), null, countryCodes, true);
		system.assertEquals(false, pricebookpb == null);
		system.assertEquals(true, pricebookpb.isEmpty());
	}

	/*
	*	Function to test getting a non msa pricebook without any Country Codes, should still come back as query ignores them
	*/
	private static testMethod void testGetPriceBooksNonMsaNoCountryCodes()
	{
        setUp();
		//create a msa pricebook and a non msa pricebook under same account
		Account acc = bg_UnitTestHelper.GetAccount('UT-Account');

		Pricebook2 pbMsa = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US,
			acc.Id, bg_PricebookUtils.GetPricebookByDeveloperName(bg_PricebookUtils.MSA_DEVELOPER_NAME).Id, 
			date.today().Year());

		Pricebook2 pb = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US,
			acc.Id, null, date.today().Year());

		set<String> countryCodes = new set<String>();
		countryCodes.add(bg_SiteUtils.COUNTRY_CODE_US);

		//test to see if pricebook query works with non msa
		List<Pricebook2> pricebookpb = bg_PricebookUtils.GetPriceBooksNonMSA(date.today().Year(), acc.Id, countryCodes, true);
		System.assertEquals(1, pricebookpb.size());
		System.assertEquals(pb.Id, pricebookpb[0].Id);
	}

	/*
	*	Function to test returning the pricebook entry based on pricebooks, products and Iso Codes
	*/
	private static testMethod void testGetPricebookEntryMap()
	{
		//create a product
		Product2 prod = new Product2(Name = 'test prod', Family = 'test family');
        insert prod;
		
		//create a pricebook
		Pricebook2 pb = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US);

		//create a standard pricebook
		bg_UnitTestHelper.createStandardPriceBookEntry(prod.Id, 100, 'USD');

		//create a pricebook entry
		PricebookEntry pe = bg_UnitTestHelper.GetPricebookEntry(pb.id, prod.id);

		Set<Id> pricebookIds = new Set<Id>();
		pricebookIds.add(pb.Id);
		Set<Id> productIds = new Set<Id>();
		productIds.add(prod.Id);

		map<string, PricebookEntry> pbEntryMap =  bg_PricebookUtils.GetPricebookEntryMap(pricebookIds, productIds);

		//should only be 1 entry
		System.assertEquals(1, pbEntryMap.size());

		//check that the pricebook entry is the one above the key is in this format pricebookId + '_' + productId
		PricebookEntry peValidate = pbEntryMap.get(pb.Id + '_'+ prod.Id);
		System.assertEquals(pe.Id, peValidate.Id);

		//call GetPricebookEntryMap passing in iso codes
		set<String> inptISOCodes = new set<String>();
		inptISOCodes.add('USD');
		map<string, PricebookEntry> pbEntryMapIsoCodes =  bg_PricebookUtils.GetPricebookEntryMap(productIds, inptISOCodes);
		
		//should only be 2 entries as it will return standard pricebook as well
		System.assertEquals(2, pbEntryMapIsoCodes.size());
		//check that the pricebook entry is the one above the key is in this format pricebookId + '_' + productId
		PricebookEntry peValidateIsoCodes = pbEntryMapIsoCodes.get(pb.Id + '_'+ prod.Id);
		System.assertEquals(pe.Id, peValidateIsoCodes.Id);
	}

	/*
	*	Function to test getting todays exchange rate.
	*/
	private static testMethod void testGetTodaysExchangeRateMap()
	{
		map<string, decimal> exchangeRateMap = bg_PricebookUtils.GetTodaysExchangeRateMap();

		//check to see if there anything there
		System.assertNotEquals(null, exchangeRateMap);
	}

	/*
	*	Function to see if pricebooks function throws exception when called with incorrect record type
	*/
	private static testMethod void testGetPricebookByDeveloperName()
	{
		try
		{
			RecordType rt = bg_PricebookUtils.GetPricebookByDeveloperName('test pricebook record type');
			throw new PricebookTestException('An exception should have been thrown testGetPricebookByDeveloperName.'); 
		}
		catch(Exception e)
		{

			Boolean expectedExceptionThrown =  e.getMessage().contains(label.BG_MSA_DEVELOPERNAME_ERROR + ' test pricebook record type') ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
		} 
	}

	private static testMethod void testGetPricebookByName() {
		/*
			Test GetPricebookByName method
		*/
		string pricebookName = 'UT_PRICEBOOKUTILS';
		Pricebook2 pb = bg_UnitTestHelper.GetPricebook(pricebookName, bg_SiteUtils.COUNTRY_CODE_US);
		test.startTest();
			system.assertEquals(pb.Id, bg_PricebookUtils.GetPricebookByName(pricebookName).Id);
			system.assertEquals(null, bg_PricebookUtils.GetPricebookByName('PB_DOES_NOT_EXIST'));
		test.stopTest();
	}

	private static testMethod void testGetPricebooks() {
		/*
			Test GetPricebooks method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		string pricebookName = 'UT_PRICEBOOKUTILS';
		Pricebook2 pb = bg_UnitTestHelper.GetPricebook(pricebookName, bg_SiteUtils.COUNTRY_CODE_US);
		Account acc = bg_UnitTestHelper.GetAccount('UT-Account');
		test.startTest();
			system.assertEquals(1, bg_PricebookUtils.GetPricebooks().size());
			system.assertEquals(1, bg_PricebookUtils.GetPricebooks(integer.valueOf(pb.Year__c)).size());
			system.assertEquals(1, bg_PricebookUtils.GetPricebooks(integer.valueOf(pb.Year__c), acc.Id).size());
		test.stopTest();
	}

	private static testMethod void testGetUserDefaultPricebook() {
		/*
			Test GetUserDefaultPricebook method
		*/	
		ConversionScore__c cs = bg_UnitTestHelper.GetDefaultCountrySetting();
		test.startTest();
			system.assertEquals(cs.DefaultPriceBookName__c, bg_PricebookUtils.GetUserDefaultPricebook().Name);
		test.stopTest();
	}

	private static testMethod void testGetPricebookById() {
		/*
			Test GetPricebookById method
		*/
		string pricebookName = 'UT_PRICEBOOKUTILS';
		Pricebook2 pb = bg_UnitTestHelper.GetPricebook(pricebookName, bg_SiteUtils.COUNTRY_CODE_US);
		test.startTest();
			system.assertEquals(pb.Name, bg_PricebookUtils.GetPricebookById(pb.Id).Name);
			// Get cached version
			system.assertEquals(pb.Name, bg_PricebookUtils.GetPricebookById(pb.Id).Name);
		test.stopTest();		
	}

	private static testMethod void testGetPricebookByOpportunitySites() {
		/*
			Test GetPricebookByOpportunitySites method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US);		
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, site); 
		Pricebook2 pb = bg_UnitTestHelper.GetPricebook(bg_SiteUtils.COUNTRY_CODE_US);

		test.startTest();
			system.assertEquals(true, bg_PricebookUtils.GetPricebookByOpportunitySites(opp.Id).containsKey(bg_SiteUtils.COUNTRY_CODE_US));
			// Get cached version
			system.assertEquals(true, bg_PricebookUtils.GetPricebookByOpportunitySites(opp.Id).containsKey(bg_SiteUtils.COUNTRY_CODE_US));			
		test.stopTest();			
	}
	
	private static testMethod void testGetCurrencyCodeByCountry() {
		/*
			Test GetCurrencyCodeByCountry method
		*/
		bg_UnitTestHelper.SetupCountryCurrencySettings();
		test.startTest();
			system.assertEquals(bg_Globals.CURRENCY_CODE_USD, bg_PricebookUtils.GetCurrencyCodeByCountry(bg_SiteUtils.COUNTRY_CODE_US, bg_Globals.CURRENCY_CODE_EUR));
			system.assertEquals(bg_Globals.CURRENCY_CODE_GBP, bg_PricebookUtils.GetCurrencyCodeByCountry(bg_SiteUtils.COUNTRY_CODE_UK, bg_Globals.CURRENCY_CODE_EUR));
			system.assertEquals('UT', bg_PricebookUtils.GetCurrencyCodeByCountry('XX', 'UT'));			
		test.stopTest();			
	}
	
	private static testMethod void testCheckPricebookSupportsCurrency() {
		/*
			Test CheckPricebookSupportsCurrency method
		*/
		test.startTest();
			system.assertEquals(false, bg_PricebookUtils.CheckPricebookSupportsCurrency(null, bg_Globals.CURRENCY_CODE_GBP));
		test.stopTest();
	}
	
	@isTest(SeeAllData=true)
	private static void testGetGlobalPricebook() {
		/*
			Test testGetGlobalPricebook method
		*/		
		test.startTest();
			system.assertNotEquals(null, bg_PricebookUtils.GetGlobalPricebook());
		test.stopTest();
	}
	
	private static testMethod void testGetPricebookIdByCountry() {
		/*
			Test GetPricebookIdByCountry method
		*/
		set<string> countryCodes = new set<string>{'US'};
		map<string, Pricebook2> pricebookCountryMap = bg_PricebookUtils.GetPricebookCountryMap(date.today().year(), countryCodes);
		Pricebook2 primaryPricebook = bg_UnitTestHelper.GetPricebook(bg_SiteUtils.COUNTRY_CODE_US); 
		
		test.startTest();
			system.assertNotEquals(null, bg_PricebookUtils.GetPricebookIdByCountry(pricebookCountryMap, 'US', primaryPricebook.Id));
		test.stopTest();		
	}
	
	private static testMethod void testGetConvertedValue() {
		/*
			Test GetPricebookIdByCountry method
		*/
		date pDate = date.today();
		
		// USD exchange rate
		DatedConversionRate dcrUSD = [SELECT ConversionRate
										FROM DatedConversionRate
										WHERE StartDate <= :pDate AND NextStartDate >= :pDate
											AND IsoCode = 'USD'];

		// EUR Exchange rate
		DatedConversionRate dcrEUR = [SELECT ConversionRate
										FROM DatedConversionRate
										WHERE StartDate <= :pDate AND NextStartDate >= :pDate
											AND IsoCode = 'EUR'];

		test.startTest();
			system.assertEquals(1, bg_PricebookUtils.GetConvertedValue('GBP', 'GBP', 1.0));
			system.assertEquals(1, bg_PricebookUtils.GetConvertedValue('USD', 'USD', 1.0));
			system.assertEquals(1, bg_PricebookUtils.GetConvertedValue('EUR', 'EUR', 1.0));

			system.assertEquals(dcrUSD.ConversionRate, bg_PricebookUtils.GetConvertedValue('GBP', 'USD', 1.0));
			system.assertEquals(dcrEUR.ConversionRate, bg_PricebookUtils.GetConvertedValue('GBP', 'EUR', 1.0));
		test.stopTest();
	}
	

	/*
		test for FindPricebookEntryByCurrency
		null values
	*/
	static testMethod void testFindPricebookEntryByCurrencyNulls()
	{
		PricebookEntry result;
		List<PricebookEntry> entries;
		String currencyCode;
		
		result = bg_PriceBookUtils.FindPricebookEntryByCurrency(null, null);
		system.assertEquals(true, result == null);
	}

	/*
		test for FindPricebookEntryByCurrency
		empty list = null currency
	*/
	static testMethod void testFindPricebookEntryByCurrencyEmptyListNullCurrency()
	{
		PricebookEntry result;
		List<PricebookEntry> entries = new List<PricebookEntry>();
		String currencyCode;
		
		result = bg_PriceBookUtils.FindPricebookEntryByCurrency(entries, null);
		system.assertEquals(true, result == null);
	}
	
	/*
		test for FindPricebookEntryByCurrency
		empty list = empty string
	*/
	static testMethod void testFindPricebookEntryByCurrencyEmptyListEmptyCurrency()
	{
		PricebookEntry result;
		List<PricebookEntry> entries = new List<PricebookEntry>();
		String currencyCode = '';
		
		result = bg_PriceBookUtils.FindPricebookEntryByCurrency(entries, currencyCode);
		system.assertEquals(true, result == null);
	}

	/*
		test for FindPricebookEntryByCurrency
		Invalid Currency
	*/
	static testMethod void testFindPricebookEntryByCurrencyInvalidCurrency()
	{
		PricebookEntry result;
		List<PricebookEntry> entries = new List<PricebookEntry>();
		String currencyCode = '';

		//create a product
		Product2 prod = new Product2(Name = 'test prod', Family = 'test family');
        insert prod;
		
		//create a pricebook
		Pricebook2 pb = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US);
		
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create  pricebook entries
		List<PricebookEntry> newPBEntries = new List<PriceBookEntry>();
		for (String thisCode : currencyCodes)
		{
			PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
			entries.add(newEntry);
		}

		currencyCode = 'CAD';
		system.assertEquals(false, currencyCodes.contains(currencyCode));
		result = bg_PriceBookUtils.FindPricebookEntryByCurrency(entries, currencyCode);
		system.assertEquals(true, result == null);
	}

	/*
		test for FindPricebookEntryByCurrency
		Valid Currency
	*/
	static testMethod void testFindPricebookEntryByCurrencyValidCurrency()
	{
		PricebookEntry result;
		List<PricebookEntry> entries = new List<PricebookEntry>();
		String currencyCode = '';

		//create a product
		Product2 prod = new Product2(Name = 'test prod', Family = 'test family');
        insert prod;
		
		//create a pricebook
		Pricebook2 pb = bg_UnitTestHelper.GetPricebook('UT_PRICEBOOKUTILS', bg_SiteUtils.COUNTRY_CODE_US);
		
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create  pricebook entries
		for (String thisCode : currencyCodes)
		{
			PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
			entries.add(newEntry);
		}

		currencyCode = 'USD';
		system.assertEquals(true, currencyCodes.contains(currencyCode));
		result = bg_PriceBookUtils.FindPricebookEntryByCurrency(entries, currencyCode);
		system.assertEquals(false, result == null);
		system.assertEquals(currencyCode, result.CurrencyISOCode);
	}


	/*
		public static Map<Id, List<PricebookEntry>> GetPriceBookEntriesByPricebookProduct(Set<Id> pricebookIds, Set<Id> productIds)
	*/ 

	/*
		test GetPriceBookEntriesByPricebookProduct
		for Null parameters
	*/
	testMethod static void testGetPriceBookEntriesByPricebookProductNullValues()
	{
		//Set up test data
		List<PricebookEntry> entries = new List<PricebookEntry>();
		List<PricebookEntry> standardEntries = new List<PricebookEntry>();
		List<Product2> testProducts = new List<Product2>();
		List<Pricebook2> testPriceBooks = new List<Pricebook2>();
		Integer productCount = 3;
		Integer priceBookCount = 3;
		
		//create a product
		for (Integer iterator=0; iterator<productCount; iterator ++)
		{
			Product2 testProduct = bg_UnitTestHelper.CreateProductFee('UT_PB_UTILS_' + iterator);
			testProducts.add(testProduct);
		}
        insert testProducts;

		
		//create pricebooks
		for (Integer iterator=0; iterator<priceBookCount; iterator ++)
		{
			Pricebook2 pb = bg_UnitTestHelper.CreatePriceBook('UT_PRICEBOOKUTILS-' + iterator, null, null, null, system.today().year());
			testPriceBooks.add(pb);
		}
		insert testPriceBooks;
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry];                 
		
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create standard pricebook entries
		List<PricebookEntry> newPBEntries = new List<PriceBookEntry>();
		for (Product2 prod : testProducts)
		{
			for (String thisCode : currencyCodes)
			{
				PricebookEntry newStandardEntry = bg_UnitTestHelper.getStandardPriceBookEntry(prod.Id, 750, thisCode);
				standardEntries.add(newStandardEntry);
				for (Pricebook2 pb : testPriceBooks)
				{
					PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
					entries.add(newEntry);
				}
			}
		}
		insert standardEntries;
		insert entries;
		
		Set<Id> pricebookIds;
		Set<Id> productIds;
		Map<Id, List<PricebookEntry>> results;
		results = bg_PricebookUtils.GetPriceBookEntriesByPricebookProduct(null, null);
		system.assertEquals(false, results==null);
		system.assertEquals(true, results.isEmpty());
	}


	/*
		test GetPriceBookEntriesByPricebookProduct
		for Empty parameters
	*/
	testMethod static void testGetPriceBookEntriesByPricebookProductEmptyValues()
	{
		//Set up test data
		List<PricebookEntry> entries = new List<PricebookEntry>();
		List<PricebookEntry> standardEntries = new List<PricebookEntry>();
		List<Product2> testProducts = new List<Product2>();
		List<Pricebook2> testPriceBooks = new List<Pricebook2>();
		Integer productCount = 3;
		Integer priceBookCount = 3;
		
		//create a product
		for (Integer iterator=0; iterator<productCount; iterator ++)
		{
			Product2 testProduct = bg_UnitTestHelper.CreateProductFee('UT_PB_UTILS_' + iterator);
			testProducts.add(testProduct);
		}
        insert testProducts;
		
		//create pricebooks
		for (Integer iterator=0; iterator<priceBookCount; iterator ++)
		{
			Pricebook2 pb = bg_UnitTestHelper.CreatePriceBook('UT_PRICEBOOKUTILS-' + iterator, null, null, null, system.today().year());
			testPriceBooks.add(pb);
		}
		insert testPriceBooks;
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry];         
		
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create standard pricebook entries
		List<PricebookEntry> newPBEntries = new List<PriceBookEntry>();
		for (Product2 prod : testProducts)
		{
			for (String thisCode : currencyCodes)
			{
				PricebookEntry newStandardEntry = bg_UnitTestHelper.getStandardPriceBookEntry(prod.Id, 750, thisCode);
				standardEntries.add(newStandardEntry);
				for (Pricebook2 pb : testPriceBooks)
				{
					PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
					entries.add(newEntry);
				}
			}
		}
		insert standardEntries;
		insert entries;
		
		Set<Id> pricebookIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		Map<Id, List<PricebookEntry>> results;
		results = bg_PricebookUtils.GetPriceBookEntriesByPricebookProduct(pricebookIds, productIds);
		system.assertEquals(false, results==null);
		system.assertEquals(true, results.isEmpty());
	}

	/*
		test GetPriceBookEntriesByPricebookProduct
		for PriceBookIds and null products
	*/
	testMethod static void testGetPriceBookEntriesByPricebookProductPricebooksNullProducts()
	{
		//Set up test data
		List<PricebookEntry> entries = new List<PricebookEntry>();
		List<PricebookEntry> standardEntries = new List<PricebookEntry>();
		List<Product2> testProducts = new List<Product2>();
		List<Pricebook2> testPriceBooks = new List<Pricebook2>();
		Integer productCount = 3;
		Integer priceBookCount = 3;
		
		//create a product
		for (Integer iterator=0; iterator<productCount; iterator ++)
		{
			Product2 testProduct = bg_UnitTestHelper.CreateProductFee('UT_PB_UTILS_' + iterator);
			testProducts.add(testProduct);
		}
        insert testProducts;

		
		//create pricebooks
		for (Integer iterator=0; iterator<priceBookCount; iterator ++)
		{
			Pricebook2 pb = bg_UnitTestHelper.CreatePriceBook('UT_PRICEBOOKUTILS-' + iterator, null, null, null, system.today().year());
			testPriceBooks.add(pb);
		}
		insert testPriceBooks;
		
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry];         
        
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create standard pricebook entries
		List<PricebookEntry> newPBEntries = new List<PriceBookEntry>();
		for (Product2 prod : testProducts)
		{
			for (String thisCode : currencyCodes)
			{
				PricebookEntry newStandardEntry = bg_UnitTestHelper.getStandardPriceBookEntry(prod.Id, 750, thisCode);
				standardEntries.add(newStandardEntry);
				for (Pricebook2 pb : testPriceBooks)
				{
					PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
					entries.add(newEntry);
				}
			}
		}
		insert standardEntries;
		insert entries;
		
		Map<Id, PriceBook2> pricebooks = new Map<Id, PriceBook2>();
		Map<Id, Product2> products = new Map<Id, Product2>();
		Map<Id, List<PricebookEntry>> results;
		pricebooks.putAll(testPriceBooks);
		
		results = bg_PricebookUtils.GetPriceBookEntriesByPricebookProduct(pricebooks.keySet(), null);
		system.assertEquals(false, results==null);
		system.assertEquals(true, results.isEmpty());
	}


	/*
		test GetPriceBookEntriesByPricebookProduct
		for PriceBookIds and empty products
	*/
	testMethod static void testGetPriceBookEntriesByPricebookProductPricebooksEmptyProducts()
	{
		//Set up test data
		List<PricebookEntry> entries = new List<PricebookEntry>();
		List<PricebookEntry> standardEntries = new List<PricebookEntry>();
		List<Product2> testProducts = new List<Product2>();
		List<Pricebook2> testPriceBooks = new List<Pricebook2>();
		Integer productCount = 3;
		Integer priceBookCount = 3;
		
		//create a product
		for (Integer iterator=0; iterator<productCount; iterator ++)
		{
			Product2 testProduct = bg_UnitTestHelper.CreateProductFee('UT_PB_UTILS_' + iterator);
			testProducts.add(testProduct);
		}
        insert testProducts;

		
		//create pricebooks
		for (Integer iterator=0; iterator<priceBookCount; iterator ++)
		{
			Pricebook2 pb = bg_UnitTestHelper.CreatePriceBook('UT_PRICEBOOKUTILS-' + iterator, null, null, null, system.today().year());
			testPriceBooks.add(pb);
		}
		insert testPriceBooks;
		
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry];         
        
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create standard pricebook entries
		List<PricebookEntry> newPBEntries = new List<PriceBookEntry>();
		for (Product2 prod : testProducts)
		{
			for (String thisCode : currencyCodes)
			{
				PricebookEntry newStandardEntry = bg_UnitTestHelper.getStandardPriceBookEntry(prod.Id, 750, thisCode);
				standardEntries.add(newStandardEntry);
				for (Pricebook2 pb : testPriceBooks)
				{
					PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
					entries.add(newEntry);
				}
			}
		}
		insert standardEntries;
		insert entries;
		
		Map<Id, PriceBook2> pricebooks = new Map<Id, PriceBook2>();
		Map<Id, Product2> products = new Map<Id, Product2>();
		Map<Id, List<PricebookEntry>> results;
		pricebooks.putAll(testPriceBooks);
		
		results = bg_PricebookUtils.GetPriceBookEntriesByPricebookProduct(pricebooks.keySet(), products.keySet());
		system.assertEquals(false, results==null);
		system.assertEquals(true, results.isEmpty());
	}


	/*
		test GetPriceBookEntriesByPricebookProduct
		for multi PriceBookIds and single product
	*/
	testMethod static void testGetPriceBookEntriesByPricebookProductPricebooksSingleProduct()
	{
		//Set up test data
		List<PricebookEntry> entries = new List<PricebookEntry>();
		List<PricebookEntry> standardEntries = new List<PricebookEntry>();
		List<Product2> testProducts = new List<Product2>();
		List<Pricebook2> testPriceBooks = new List<Pricebook2>();
		Integer productCount = 3;
		Integer priceBookCount = 3;
		
		//create a product
		for (Integer iterator=0; iterator<productCount; iterator ++)
		{
			Product2 testProduct = bg_UnitTestHelper.CreateProductFee('UT_PB_UTILS_' + iterator);
			testProducts.add(testProduct);
		}
        insert testProducts;

		
		//create pricebooks
		for (Integer iterator=0; iterator<priceBookCount; iterator ++)
		{
			Pricebook2 pb = bg_UnitTestHelper.CreatePriceBook('UT_PRICEBOOKUTILS-' + iterator, null, null, null, system.today().year());
			testPriceBooks.add(pb);
		}
		insert testPriceBooks;
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry];                 
		
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create standard pricebook entries
		List<PricebookEntry> newPBEntries = new List<PriceBookEntry>();
		for (Product2 prod : testProducts)
		{
			for (String thisCode : currencyCodes)
			{
				PricebookEntry newStandardEntry = bg_UnitTestHelper.getStandardPriceBookEntry(prod.Id, 750, thisCode);
				standardEntries.add(newStandardEntry);
				for (Pricebook2 pb : testPriceBooks)
				{
					PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
					entries.add(newEntry);
				}
			}
		}
		insert standardEntries;
		insert entries;
		
		Map<Id, PriceBook2> pricebooks = new Map<Id, PriceBook2>();
		Map<Id, Product2> products = new Map<Id, Product2>();
		Map<Id, List<PricebookEntry>> results;
		pricebooks.putAll(testPriceBooks);
		Product2 testProduct = testProducts[0];
		products.put(testProduct.Id, testProduct);
		
		results = bg_PricebookUtils.GetPriceBookEntriesByPricebookProduct(pricebooks.keySet(), products.keySet());
		system.assertEquals(false, results==null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(priceBookCount, results.size());
		for (Pricebook2 priceBook : testPriceBooks)
		{
			system.assertEquals(true, results.containsKey(priceBook.Id));
			system.assertEquals(3, results.get(priceBook.Id).size());
			for (PricebookEntry pbe : results.get(priceBook.Id))
			{
				system.assertEquals(testProduct.Id, pbe.Product2Id);
			}
		}
	}


	/*
		test GetPriceBookEntriesByPricebookProduct
		for Single PriceBookIds and single product
	*/
	testMethod static void testGetPriceBookEntriesByPricebookProductSinglePricebooksSingleProduct()
	{
		//Set up test data
		List<PricebookEntry> entries = new List<PricebookEntry>();
		List<PricebookEntry> standardEntries = new List<PricebookEntry>();
		List<Product2> testProducts = new List<Product2>();
		List<Pricebook2> testPriceBooks = new List<Pricebook2>();
		Integer productCount = 3;
		Integer priceBookCount = 3;
		
		//create a product
		for (Integer iterator=0; iterator<productCount; iterator ++)
		{
			Product2 testProduct = bg_UnitTestHelper.CreateProductFee('UT_PB_UTILS_' + iterator);
			testProducts.add(testProduct);
		}
        insert testProducts;

		
		//create pricebooks
		for (Integer iterator=0; iterator<priceBookCount; iterator ++)
		{
			Pricebook2 pb = bg_UnitTestHelper.CreatePriceBook('UT_PRICEBOOKUTILS-' + iterator, null, null, null, system.today().year());
			testPriceBooks.add(pb);
		}
		insert testPriceBooks;
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry];                 
		
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create standard pricebook entries
		List<PricebookEntry> newPBEntries = new List<PriceBookEntry>();
		for (Product2 prod : testProducts)
		{
			for (String thisCode : currencyCodes)
			{
				PricebookEntry newStandardEntry = bg_UnitTestHelper.getStandardPriceBookEntry(prod.Id, 750, thisCode);
				standardEntries.add(newStandardEntry);
				for (Pricebook2 pb : testPriceBooks)
				{
					PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
					entries.add(newEntry);
				}
			}
		}
		insert standardEntries;
		insert entries;
		
		Map<Id, PriceBook2> pricebooks = new Map<Id, PriceBook2>();
		Map<Id, Product2> products = new Map<Id, Product2>();
		Map<Id, List<PricebookEntry>> results;
		Pricebook2 testPriceBook = testPriceBooks[0];
		pricebooks.put(testPriceBook.Id, testPriceBook);
		Product2 testProduct = testProducts[0];
		products.put(testProduct.Id, testProduct);
		
		results = bg_PricebookUtils.GetPriceBookEntriesByPricebookProduct(pricebooks.keySet(), products.keySet());
		system.assertEquals(false, results==null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(1, results.size());
		system.assertEquals(true, results.containsKey(testPriceBook.Id));
		system.assertEquals(3, results.get(testPriceBook.Id).size());
		for (PricebookEntry pbe : results.get(testPriceBook.Id))
		{
			system.assertEquals(testProduct.Id, pbe.Product2Id);
		}
	}
	
	/*
		test GetPriceBookEntriesByPricebookProduct
		for Multi PriceBookIds and Mulit product
	*/
	testMethod static void testGetPriceBookEntriesByPricebookProductMulti()
	{
		//Set up test data
		List<PricebookEntry> entries = new List<PricebookEntry>();
		List<PricebookEntry> standardEntries = new List<PricebookEntry>();
		List<Product2> testProducts = new List<Product2>();
		List<Pricebook2> testPriceBooks = new List<Pricebook2>();
		Integer productCount = 3;
		Integer priceBookCount = 3;
		
		//create a product
		for (Integer iterator=0; iterator<productCount; iterator ++)
		{
			Product2 testProduct = bg_UnitTestHelper.CreateProductFee('UT_PB_UTILS_' + iterator);
			testProducts.add(testProduct);
		}
        insert testProducts;

		
		//create pricebooks
		for (Integer iterator=0; iterator<priceBookCount; iterator ++)
		{
			Pricebook2 pb = bg_UnitTestHelper.CreatePriceBook('UT_PRICEBOOKUTILS-' + iterator, null, null, null, system.today().year());
			testPriceBooks.add(pb);
		}
		insert testPriceBooks;
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry];                 
		
		Set<String> currencyCodes = new Set<String>{ 'GBP', 'USD', 'EUR' };

		//create standard pricebook entries
		List<PricebookEntry> newPBEntries = new List<PriceBookEntry>();
		for (Product2 prod : testProducts)
		{
			for (String thisCode : currencyCodes)
			{
				PricebookEntry newStandardEntry = bg_UnitTestHelper.getStandardPriceBookEntry(prod.Id, 750, thisCode);
				standardEntries.add(newStandardEntry);
				for (Pricebook2 pb : testPriceBooks)
				{
					PricebookEntry newEntry = bg_UnitTestHelper.CreatePricebookEntry(pb.Id, prod.Id, thisCode, 500.00);
					entries.add(newEntry);
				}
			}
		}
		insert standardEntries;
		insert entries;
		
		Map<Id, PriceBook2> pricebooks = new Map<Id, PriceBook2>();
		Map<Id, Product2> products = new Map<Id, Product2>();
		Map<Id, List<PricebookEntry>> results;
		Integer testPBCount = priceBookCount - 1;
		Integer testProductCount = productCount - 1;

		for (Integer iterator=0; iterator<testPBCount; iterator++)
		{
			Pricebook2 testPriceBook = testPriceBooks[iterator];
			pricebooks.put(testPriceBook.Id, testPriceBook);			
		}
		for (Integer iterator=0; iterator<testProductCount; iterator++)
		{
			Product2 testProduct = testProducts[testProductCount];
			products.put(testProduct.Id, testProduct);
		}
		
		results = bg_PricebookUtils.GetPriceBookEntriesByPricebookProduct(pricebooks.keySet(), products.keySet());

		system.assertEquals(false, results==null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(testProductCount, results.size());
		for (Pricebook2 priceBook : pricebooks.values())
		{
			system.assertEquals(true, results.containsKey(priceBook.Id));
			system.assertEquals(3, results.get(priceBook.Id).size());
			for (PricebookEntry pbe : results.get(priceBook.Id))
			{
				system.assertEquals(true, products.containsKey(pbe.Product2Id));
			}
		}
	}	

}