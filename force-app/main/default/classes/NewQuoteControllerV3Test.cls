/********************************************************************
 * NewQuoteControllerV3
 *
 * Test class for NewQuoteControllerV3
 * 
 * 
 * Author: Richard Jimenez
 * Created: 08-10-2013
 * Changes: 16-11-16 - JT Case 27420 added extra assertions
 *			04-08-17 - RC Removed Assert as no longer required.
 ********************************************************************/
@isTest
private class NewQuoteControllerV3Test {

	private static testMethod void testNewQuoteControllerV3() {
		/*
			Method to test NewQuoteControllerV3
		*/
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();		
		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);

		/*  TEST NO SITES */
		Test.setCurrentPage(Page.newQuoteV3);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);		
		NewQuoteControllerV3 controllerNoSites = new NewQuoteControllerV3();
		//system.assertNotEquals(null, controllerNoSites.CheckManageSites());
		
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c siteN = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		// Opportunity Site
		bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		bg_UnitTestHelper.GetOpportunitySite(opp, siteN, true);
		bg_UnitTestHelper.GetOpportunitySite(opp, siteT, true);

		/* FULL NEW QUOTE TEST */
		Test.setCurrentPage(Page.newQuoteV3);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);

		test.startTest();
	        NewQuoteControllerV3 controller = new NewQuoteControllerV3();
			controller.SkipPricebookCurrencyCheck = true;
			controller.Quote.Contact__c = con.Id;
	        		
	        // Calling getters
			system.assertEquals(null, controller.CheckManageSites());
			//removed as process builder creates the site and opportunity site
			//system.assertEquals(siteHQ.Id, controller.SiteHQ.Site__r.Id);
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
			controller.SearchProducts();
			controller.searchProductName = productName;
			controller.SearchProducts();
			controller.GetSuggestedProducts();		
			controller.ShowSuggestedProductsFromGrid();
			controller.ClearSuggestions();
			
			controller.ProductSearchResults[0].Selected = true;
			controller.AddSelectedProducts();
		
			controller.ToggleShowSelectedOnly();
			controller.selectedProductArea = product.Product_Area_Interest__c;
			controller.SelectProductArea();
			controller.ToggleSiteSummary();
			controller.ToggleSelectionSummary();
			
			controller.AddProductInterests();
			
			controller.ClearProductSelection();

			controller.selectedProduct = productName;
			controller.SelectProduct(productName);
			system.assertEquals(true, controller.SelectProduct(productName));

			system.debug('controller.ProductMap: ' + controller.ProductMap);

			controller.ProductMap.get(productName).SitesMap.get(1).RegistrationPath = 'New Registration';
			
			controller.selectedProdRegPath = productName;
			controller.SetProductRegPathToAllSites();
			
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

			//system.assertNotEquals(null, controller.Next());
			//system.assertNotEquals(null, controller.Cancel());
			//system.assertNotEquals(null, controller.ManageSites());
		test.stopTest();
	}
	
	private static testMethod void testLoadNewQuoteControllerV3() {
		/*
			Method to test NewQuoteControllerV3
		*/
		// Set up data
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		// Product
		string productName = 'ISO 9001';
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		// Account
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV3');
		// Contact
		Contact con = bg_UnitTestHelper.GetContact('UT-NQCV3-CON', acc);
		// Opportunity
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);
		// Add Site
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c siteN = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV3_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		// Opportunity Site
		bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
		bg_UnitTestHelper.GetOpportunitySite(opp, siteN, true);
		bg_UnitTestHelper.GetOpportunitySite(opp, siteT, true);
				
		/*  LOAD QUOTE TEST */
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		// Setup page
		Test.setCurrentPage(Page.newQuoteV3);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
		ApexPages.currentPage().getParameters().put('oppid', opp.Id);
		ApexPages.currentPage().getParameters().put('quoid', quote.Id);

		NewQuoteControllerV3 controllerEdit = new NewQuoteControllerV3();
		controllerEdit.SkipPricebookCurrencyCheck = true;
	}
}