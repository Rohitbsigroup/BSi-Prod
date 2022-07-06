/********************************************************************
 * bg_QuoteBuilderControllerTest
 *
 * Test class for bg_QuoteBuilderController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 08-10-2013
 * Changes: 16-11-16 - JT Case 27420 added extra assertions
 * 			24-05-17 - RC had to change assert to not equals as checkmangedsites
 *						will return a url as default site is always created now
 *			07-08-17 - RC had to remove check for site as hq site is not correct record type.
 *          31/08/2017 - ADS Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 *			12/09/2017 - RC Added multiple tests to cover new functionality with PS project and edited testLoadbg_QuoteBuilderController 
 *			27/09/2017 - RC changed testApplyToAllSites to take into account controlling location
 *			28/09/2017 - RC added unit tests for SetControllingLocation
 *			02/10/2017 - RC removed SelectProductArea from test as its been removed from class and added test for setLayoutOrderForProductSiteWrappers
 ********************************************************************/
@isTest
private class bg_QuoteBuilderControllerTest 
{

	public static string RESET_ERROR = 'Only Main Quote Contacts can be Reset';

	/*
	*	Function to test setting the site indexs
	*/ 

	public static testMethod void TestLayoutOrderQuoteProduct()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();

		string classificationName = 'test';
		Product_Classification__c pc = bg_UnitTestHelper.GetProductClassification2(classificationName, 'Assurance', 'Risk', 'Quality');
		pc.Product_Group__c = 'ISO 9001'; //  Product Group is used for the keyword search
		update(pc);

		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Product_Classification__c = pc.Id;
		product.Product_Type__c = bg_ProductUtils.PRODUCT_TYPE_MAIN;
		update product;

		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		//create multiple sites to check the reg paths

		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c siteN = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		// Opportunity Site
		OpportunitySite__c oppSite1 = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		OpportunitySite__c oppSite2 = bg_UnitTestHelper.GetOpportunitySite(opp, siteN, true);
		OpportunitySite__c oppSite3 = bg_UnitTestHelper.GetOpportunitySite(opp, siteT, true);

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);

		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		// add a faceceted search component
		bg_FacetedSearchComponentController fsc = new bg_FacetedSearchComponentController();
		fsc.paramKey='Product_Classification__r.Stream2__c';
		fsc.objectName='Product__c';
		controller.addSearchComponent('Product__cProduct_Classification__r.Stream2__c', fsc);
		fsc.selectedItems = new List<String>{'Assurance'};

		controller.searchProductName = productName;
		controller.facetedSearchProducts();

		//add the product
		controller.ProductSearchResults[0].Selected = true;
		controller.AddSelectedProducts();

		controller.selectedControllingLocationProduct = 'ISO 9001';
		controller.ProductMap.get(productName).controllingLocationId = siteHQ.Id;
		controller.setControllingLocation();

		//loop round site map make sure the sitehq is index 1
		for(bg_Wrappers.ProductSiteWrapper psw : controller.ProductMap.get(productName).SitesMap.values())
		{			
			if(psw.Site.Id==siteHQ.Id)
			{
				System.assertEquals(1, psw.SiteIndex);
			}

		}
		//change the controlling location 
		//set the controlling location to the other site
		Site__c siteQuery = [select id, RecordType.Name from Site__c Where RecordType.Name='Default'];
		controller.ProductMap.get(productName).controllingLocationId = siteQuery.Id;
		controller.setControllingLocation();

		//loop round site map make sure the Default site is now index 1
		for(bg_Wrappers.ProductSiteWrapper psw : controller.ProductMap.get(productName).SitesMap.values())
		{
			
			if(psw.Site.Id==siteQuery.Id)
			{
				System.assertEquals(1, psw.SiteIndex);
			}

		}

	}

	/*
	*	Function to test setting the controlling location
	*/
	public static testMethod void TestControllingLocation()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();

		string classificationName = 'test';
		Product_Classification__c pc = bg_UnitTestHelper.GetProductClassification2(classificationName, 'Assurance', 'Risk', 'Quality');
		pc.Product_Group__c = 'ISO 9001'; //  Product Group is used for the keyword search
		update(pc);

		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Product_Classification__c = pc.Id;
		product.Product_Type__c = bg_ProductUtils.PRODUCT_TYPE_MAIN;
		product.GridView__C = true;
		update product;

		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		//create multiple sites to check the reg paths

		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c siteN = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		// Opportunity Site
		OpportunitySite__c oppSite1 = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		OpportunitySite__c oppSite2 = bg_UnitTestHelper.GetOpportunitySite(opp, siteN, true);
		OpportunitySite__c oppSite3 = bg_UnitTestHelper.GetOpportunitySite(opp, siteT, true);

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);

		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		// add a faceceted search component
		bg_FacetedSearchComponentController fsc = new bg_FacetedSearchComponentController();
		fsc.paramKey='Product_Classification__r.Stream2__c';
		fsc.objectName='Product__c';
		controller.addSearchComponent('Product__cProduct_Classification__r.Stream2__c', fsc);
		fsc.selectedItems = new List<String>{'Assurance'};

		controller.searchProductName = productName;
		controller.facetedSearchProducts();

		//add the product
		controller.ProductSearchResults[0].Selected = true;
		controller.AddSelectedProducts();

		controller.selectedControllingLocationProduct = 'ISO 9001';
		controller.ProductMap.get(productName).controllingLocationId = siteHQ.Id;
		controller.setControllingLocation();
		//make sure the controlling location is set for that site.
		System.debug(controller.ProductMap.get(productName).SitesMap);
		System.assertEquals(true, controller.ProductMap.get(productName).SitesMap.get(2).IsControllingLocation);

		//try calling set all locations
		controller.setControllingLocationForAllProducts();

		for(bg_Wrappers.QuoteProductWrapper qpw : controller.ProductMap.values())
		{
			System.assertEquals(siteHQ.Id,qpw.controllingLocationId);
		}

	}


	/*
	*	Function to test days profile button.
	*/
	public static testMethod void testDaysProfile()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();

		string classificationName = 'test';
		Product_Classification__c pc = bg_UnitTestHelper.GetProductClassification2(classificationName, 'Assurance', 'Risk', 'Quality');
		pc.Product_Group__c = 'ISO 9001'; //  Product Group is used for the keyword search
		update(pc);

		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Product_Classification__c = pc.Id;
		product.Product_Type__c = bg_ProductUtils.PRODUCT_TYPE_MAIN;
		update product;

		string productName2 = 'ISO 9001 Site';
		Product__c product2 = bg_UnitTestHelper.GetProduct(productName2);
		product2.Product_Type__c = bg_ProductUtils.PRODUCT_TYPE_SITE;
		update product2;

		System.debug('####RC ' + product2);

		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);

		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		// add a faceceted search component
		bg_FacetedSearchComponentController fsc = new bg_FacetedSearchComponentController();
		fsc.paramKey='Product_Classification__r.Stream2__c';
		fsc.objectName='Product__c';
		controller.addSearchComponent('Product__cProduct_Classification__r.Stream2__c', fsc);
		fsc.selectedItems = new List<String>{'Assurance'};

		controller.searchProductName = productName;
		controller.facetedSearchProducts();

		//add the product
		controller.ProductSearchResults[0].Selected = true;
		controller.AddSelectedProducts();

		controller.selectedProductName = productName;

		//select a reg path
		controller.ProductMap.get(productName).SitesMap.get(1).RegistrationPath = 'New Registration';
		controller.selectedProdRegPath = productName;

		//query the default site
		Site__C site = [Select id from Site__c];

		controller.ProductMap.get(productName).ControllingLocationId = site.id;

		controller.selectedControllingLocationId = site.id;

		PageReference pr = controller.ViewProductProfile();

		//check that a url came back with the template in
		System.assertEquals(true, pr.getUrl().contains(EncodingUtil.urlEncode(bg_BluePrintUtils.TEMPLATE_NAME_PRODUCT_PROFILE, 'UTF-8')));

	}

	/*
	*	Function to test apply to all sites button.
	*/
	public static testMethod void testApplyToAllSites()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();

		string classificationName = 'test';
		Product_Classification__c pc = bg_UnitTestHelper.GetProductClassification2(classificationName, 'Assurance', 'Risk', 'Quality');
		pc.Product_Group__c = 'ISO 9001'; //  Product Group is used for the keyword search
		update(pc);

		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Product_Classification__c = pc.Id;
		product.Product_Type__c = bg_ProductUtils.PRODUCT_TYPE_MAIN;
		product.GridView__C = true;
		update product;

		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		//create multiple sites to check the reg paths

		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c siteN = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		// Opportunity Site
		bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		bg_UnitTestHelper.GetOpportunitySite(opp, siteN, true);
		bg_UnitTestHelper.GetOpportunitySite(opp, siteT, true);

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);

		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		// add a faceceted search component
		bg_FacetedSearchComponentController fsc = new bg_FacetedSearchComponentController();
		fsc.paramKey='Product_Classification__r.Stream2__c';
		fsc.objectName='Product__c';
		controller.addSearchComponent('Product__cProduct_Classification__r.Stream2__c', fsc);
		fsc.selectedItems = new List<String>{'Assurance'};

		controller.searchProductName = productName;
		controller.facetedSearchProducts();

		//add the product
		controller.ProductSearchResults[0].Selected = true;
		controller.AddSelectedProducts();

		//check that paths are not set
		controller.ProductMap.get(productName).SitesMap.get(1).RegistrationPath = 'New Registration';
		controller.ProductMap.get(productName).SitesMap.get(1).IsControllingLocation = true;
		System.assertEquals('New Registration', controller.ProductMap.get('ISO 9001').SitesMap.get(1).RegistrationPath);
		System.assertEquals('', controller.ProductMap.get('ISO 9001').SitesMap.get(2).RegistrationPath);
		
		controller.selectedProdRegPath = productName;
		controller.SetProductRegPathToAllSites();

		//check that second one is populated after calling SetProductRegPathToAllSites
		System.assertEquals('New Registration', controller.ProductMap.get('ISO 9001').SitesMap.get(1).RegistrationPath);
		System.assertEquals('New Registration', controller.ProductMap.get('ISO 9001').SitesMap.get(2).RegistrationPath);
	}


	public static testMethod void testPerformSearchNoResults()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		// Product
		string productName = 'Project';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);

		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		// add a faceceted search component
		bg_FacetedSearchComponentController fsc = new bg_FacetedSearchComponentController();
		fsc.paramKey='Product_Classification__r.Stream2__c';
		fsc.objectName='Product__c';
		controller.addSearchComponent('Product__cProduct_Classification__r.Stream2__c', fsc);
		fsc.selectedItems = new List<String>{'Assurance'};

		controller.searchProductName = 'test product does not exist';

		controller.facetedSearchProducts();

		//check that ProductSearchResults is empty
		System.assertEquals(true, controller.ProductSearchResults.IsEmpty());
	}

	public static testMethod void testSaveWithoutProducts()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		// Product
		string productName = 'Project';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);

		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		//don't do anything and click save button
		controller.SaveQuote();

		//check for errors
		System.assertEquals(true, controller.hasMessages);

		List<Apexpages.Message> msgs = ApexPages.getMessages();
        System.assertEquals(Label.bg_No_Product_Or_Project_Error, msgs[0].getDetail());
	}


	/*
	*	Test reset contact button after loading a quote.
	*/
	private static testMethod void testResetContactButton()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		// Product
		string productName = 'Project';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		/*  LOAD QUOTE TEST */
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp, con);

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);
		ApexPages.currentPage().getParameters().put('quoid', quote.Id);

		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		//check that the quote loaded has contacts associated with it
		System.assertNotEquals(null, controller.quote.Contact__c);
		System.assertNotEquals(null, controller.quote.Invoice_Contact__c );
		System.assertNotEquals(null, controller.quote.Booking__c );
		System.assertNotEquals(null, controller.quote.CreditCheck__c );

		controller.ResetContacts();
		System.assertEquals(null, controller.quote.Contact__c);
		System.assertEquals(null, controller.quote.Invoice_Contact__c );
		System.assertEquals(null, controller.quote.Booking__c );
		System.assertEquals(null, controller.quote.CreditCheck__c );


	}

	/*
	*	Test reset contact button when not a main quote.
	*/
	private static testMethod void testResetContactButtonNotMainQuote()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		// Product
		string productName = 'Project';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		/*  LOAD QUOTE TEST */
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp, con);

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);
		ApexPages.currentPage().getParameters().put('quoid', quote.Id);

		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		//check that the quote loaded has contacts associated with it
		System.assertNotEquals(null, controller.quote.Contact__c);
		System.assertNotEquals(null, controller.quote.Invoice_Contact__c );
		System.assertNotEquals(null, controller.quote.Booking__c );
		System.assertNotEquals(null, controller.quote.CreditCheck__c );

		//make sure it is not a main quote
		controller.quote.Main_Quote__c = false;

		controller.ResetContacts();
		//check they have not been reset.
		System.assertNotEquals(null, controller.quote.Contact__c);
		System.assertNotEquals(null, controller.quote.Invoice_Contact__c );
		System.assertNotEquals(null, controller.quote.Booking__c );
		System.assertNotEquals(null, controller.quote.CreditCheck__c );

		//check the apex message 
		System.assertEquals(true, controller.hasMessages);

		List<Apexpages.Message> msgs = ApexPages.getMessages();
        System.assertEquals(RESET_ERROR, msgs[0].getDetail());


	}

	/*
	*	Function to check that the redirect to addSitetoQuote happens if an opportunity site doesn't exist.
	*/
	private static testMethod void testCheckManageSites()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		

		string classificationName = 'test';
		Product_Classification__c pc = bg_UnitTestHelper.GetProductClassification2(classificationName, 'Assurance', 'Risk', 'Quality');
		pc.Product_Group__c = 'ISO 9001'; //  Product Group is used for the keyword search
		update(pc);

		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Product_Classification__c = pc.Id;
		update product;
		// Product 2
		string productName2 = 'ISO 9001';
		Product__c product2 = bg_UnitTestHelper.GetSiteProduct(productName2);

		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		/*  TEST NO SITES */
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);		
		bg_QuoteBuilderController controllerWithSites = new bg_QuoteBuilderController();

		PageReference pr = controllerWithSites.CheckManageSites();

		//pr should equal null as there is an opportunity site and should not redirect the user to addSitetoQuote page.
		System.assertEquals(null, pr);

		//delete the opportunity site then retest
		OpportunitySite__c os = [Select id from OpportunitySite__c where Opportunity__c=:opp.Id];
		delete os;

		bg_QuoteBuilderController controllerNoSites = new bg_QuoteBuilderController();


		PageReference prNoSite = controllerNoSites.CheckManageSites();

		//check that it redirects to the AddSiteToQuote page
		System.assertEquals(true, prNoSite.getUrl().contains(bg_SiteUtils.VF_PAGENAME_ADDOPTYSITE));
	}

	
	/*
	*	Function to check adding a project to the list and pressing the configure button.
	*/
	private static testMethod void testConfigureProject()
	{
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		

		string classificationName = 'test';
		Product_Classification__c pc = bg_UnitTestHelper.GetProductClassification2(classificationName, 'Assurance', 'Risk', 'Quality');
		pc.Product_Group__c = 'ISO 9001'; //  Product Group is used for the keyword search
		update(pc);

		// Product
		string productName = 'Project Builder';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Product_Classification__c = pc.Id;
		product.Product_Type__c = bg_ProductUtils.PRODUCT_TYPE_MAIN;
		product.Product_Stream__c = bg_ProductUtils.PRODUCT_STREAM_PS;
		update product;

		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		//create some projects under the account
		Project__c project = bg_UnitTestHelper.CreateProject(acc.Id, 'test project 1', true);
		insert project;
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		Project__c projectQuery = [select id, Product__c from Project__c];

		//update the project as the product__c field will get overwritten.
		projectQuery.Product__c = product.Id;
		update projectQuery;


		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);		
		bg_QuoteBuilderController controller = new bg_QuoteBuilderController();

		//try to configure a project after it is selected 
		controller.ProjectSearchResults[0].Selected = true;

		controller.AddSelectedProjects();
		controller.selectedProjectId = project.Id;
		PageReference pr = controller.ConfigureProduct();

		//check to see that the configurator url is not null.
		System.assertNotEquals(null, pr);

	}

	private static testMethod void testQuoteBuilderController() {
		/*
			Method to test bg_QuoteBuilderController
		*/
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		

		string classificationName = 'test';
		Product_Classification__c pc = bg_UnitTestHelper.GetProductClassification2(classificationName, 'Assurance', 'Risk', 'Quality');
		pc.Product_Group__c = 'ISO 9001'; //  Product Group is used for the keyword search
		update(pc);

		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.Product_Classification__c = pc.Id;
		update product;
		// Product 2
		string productName2 = 'ISO 9001';
		Product__c product2 = bg_UnitTestHelper.GetSiteProduct(productName2);

		//insert a territory
		Territory__c terrP = TestData.getTestTerritory('GB','PO');
        terrP.Name = 'Patch One';
        insert terrP;

		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		/*  TEST NO SITES */
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);		
		bg_QuoteBuilderController controllerNoSites = new bg_QuoteBuilderController();
		//now should equal null as default site gets created when account gets created.
		system.assertEquals(null, controllerNoSites.CheckManageSites());
		
		
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c siteN = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		// Opportunity Site
		bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		bg_UnitTestHelper.GetOpportunitySite(opp, siteN, true);
		bg_UnitTestHelper.GetOpportunitySite(opp, siteT, true);
				

		/* FULL NEW QUOTE TEST */
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);

			
	        bg_QuoteBuilderController controller = new bg_QuoteBuilderController();
			controller.SkipPricebookCurrencyCheck = true;
			controller.Quote.Contact__c = con.Id;
			
			// add a faceceted search component
			bg_FacetedSearchComponentController fsc = new bg_FacetedSearchComponentController();
			fsc.paramKey='Product_Classification__r.Stream2__c';
			fsc.objectName='Product__c';
			controller.addSearchComponent('Product__cProduct_Classification__r.Stream2__c', fsc);
			fsc.selectedItems = new List<String>{'Assurance'};

			controller.getAllOptions(fsc.objectName, fsc.paramKey);
			
	        		
	        // Calling getters
			system.assertEquals(null, controller.CheckManageSites());
			//the site that gets created about will not be the one that gets assigned as the default site gets created.
			system.assertEquals(siteN.Id, controller.SiteNetwork.Site__r.Id);
			system.assertEquals(siteT.Id, controller.SiteTransient.Site__r.Id);
			system.assertEquals(true, controller.IsMultiSite);
			system.assertNotEquals(0, controller.getContactItems().size());
			system.assertEquals(1, controller.getPricebookItems().size());
			system.assertNotEquals(0, controller.getCurrencyCodeItems().size());
			system.assertNotEquals(0, controller.getProductPortfolioItems().size());
			system.assertNotEquals(0, controller.getProductAreaItems().size());
			system.assertNotEquals(0, controller.getProductCountryItems().size());
			// Case 27420
			system.assertNotEquals(null, controller.getBluePrintLanguages());
			system.assertEquals(bg_UserUtils.GetUserById(UserInfo.getUserId()).bluePrint_Language__c, controller.getSelectedQuoteLanguage());
			controller.setSelectedQuoteLanguage('en_GB');

			controller.ToggleProductSearch();
			test.startTest();
			controller.facetedSearchProducts();
			
			controller.searchProductName = productName;
			controller.facetedSearchProducts();
			
			controller.GetSuggestedProducts();		
			controller.ShowSuggestedProductsFromGrid();
			controller.ClearSuggestions();
			
			controller.ProductSearchResults[0].Selected = true;
			controller.AddSelectedProducts();
			
			controller.ToggleShowSelectedOnly();
			controller.selectedProductArea = product.Product_Area_Interest__c;
			controller.ToggleSiteSummary();
			controller.ToggleSelectionSummary();
			
			controller.AddProductInterests();
			
			controller.ClearProductSelection();

			controller.selectedProduct = productName;
			controller.SelectProduct(productName);
			system.assertEquals(true, controller.SelectProduct(productName));


			controller.ProductMap.get(productName).SitesMap.get(1).RegistrationPath = 'New Registration';
			controller.selectedProdRegPath = productName;
			controller.SetProductRegPathToAllSites();
			
			controller.ProductMap.get(productName).ControllingLocationId = siteHQ.id;
			controller.selectedControllingLocationId = siteHQ.id;
			
			controller.CheckForSamplingAvailable();
			
			controller.selectedIMSProduct = productName;
			controller.CreateIMSQuestion();
			controller.selectedSamplingProduct = productName;
			controller.CreateSamplingQuestion();
			
			controller.QuickSave();


			controller.SaveQuote(true);
			controller.CheckForIMSAvailableQuestion();
			
			controller.selectedSiteProduct = productName;
			controller.selectedSite = '1';
			controller.SelectRegistrationPath();
			
			controller.selectedProduct = productName;
			controller.UseSampling();
			controller.CheckForSamplingAvailable();
			
			controller.selectedIMSProduct = productName;
			controller.SelectIMSProduct();
			
			controller.Quote.Invoice_Contact__c = con.Id;
			controller.Quote.Booking__c = con.Id;
			controller.Quote.CreditCheck__c = con.Id;
	
			controller.SaveQuote();

			controller.ConfigureProduct();
			controller.AddSelectedProjects();

		test.stopTest();
	}
	
	private static testMethod void testLoadbg_QuoteBuilderController() {
		/*
			Method to test bg_QuoteBuilderController
		*/
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		// Product
		string productName = 'Project';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		//site and opp site
		Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteT, true);

		/*  LOAD QUOTE TEST */
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);

		//create some projects under the account
		Project__c project = bg_UnitTestHelper.CreateProject(acc.Id, 'test project 1', true);
		insert project;

		//update the project as the product__c field will get overwritten by process builder.
		project.Product__c = product.Id;
		update project;

		//quote product
		Quote_Product__c quoteP = bg_UnitTestHelper.CreateQuoteProduct(quote, con, product, siteT, opp, oppSite); 
		quoteP.Project__c = project.Id;
		insert QuoteP;

		// Setup page
		Test.setCurrentPage(Page.QuoteBuilder);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);
		ApexPages.currentPage().getParameters().put('quoid', quote.Id);

		bg_QuoteBuilderController controllerEdit = new bg_QuoteBuilderController();

		//check the product area map to make sure the project has loaded.
		System.assertEquals(project.id, controllerEdit.productMap.get('Project').project.Id);
	}
	
	
}