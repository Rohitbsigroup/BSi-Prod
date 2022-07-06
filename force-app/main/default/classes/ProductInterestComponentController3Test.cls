/********************************************************************
 * ProductInterestComponentController3Test
 *
 * Test methods for Product Interest Component Controller 3
 * 
 * 
 * Author: Richard Jimenez
 * Created: 01-08-2015
 * Changes: 31/08/2017 ADS
 *            - Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 ********************************************************************/
@isTest
private class ProductInterestComponentController3Test 
{
	private static testMethod void testLeadProductInterestComponentController3() 		
	{
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

        BSIPermissions__c cs = BSIPermissions__c.getInstance(UserInfo.getUserId());
        if(cs == null) {        		
	        cs = new BSIPermissions__c();
        }
        cs.CanEditSuggestedProductsGLOBAL__c = true;
        upsert cs;
		
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
        
		// create products
		
        Product__c product = new Product__c();
        product.name = 'Test';
        product.Active__c = true;
        product.Product_Stream__c = 'stream';
        product.Product_SubStream__c = 'substream';
        product.Active_In_SF__c = true;
        product.Product_Type__c = 'main';
        product.CCode__c = 'C300';
		product.RegistrationPaths__c  = 'New Registation;ETS: New Site';
        insert product;
         
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductA', 'StreamA', 'PortfolioA','ProductAreaA', product);
		Product_Classification__c pcB = bg_UnitTestHelper.GetProductClassification2('UT-ProductB', 'StreamB', 'PortfolioB','ProductAreaB', product);
		Product_Classification__c pcC = bg_UnitTestHelper.GetProductClassification2('UT-ProductC', 'StreamC', 'PortfolioC','ProductAreaC', product);
		
        
        
		Product_Classification_Relationship__c pcr = new Product_Classification_Relationship__c();
		pcr.ProductClassification__c = pcA.Id;
		pcr.SuggestedProductClassification__c = pcC.Id;
		pcr.Region__c = 'GLOBAL';
		insert pcr;

		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) {
		
			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			newLead.Product_Stream__c 			= pcA.Stream2__c;
			newLead.Portfolio_Interests__c 		= pcA.Portfolio2__c;
			newLead.Product_Area_Interests__c 	= pcA.Family2__c;
			newLead.Product_Interests__c 		= pcA.Product__c;
			update newLead;

			system.debug('**** New Lead = ' + newLead);
		
			// create standardcontroller
			ApexPages.StandardController sc = new ApexPages.standardController(newLead);
		
			test.startTest();
				// create LeadProductInterestExt
				LeadProductInterestExt ext = new LeadProductInterestExt(sc);

				system.debug('**** Lead Product Interest Ext = ' + ext);

				ProductInterestComponentController3 comp = new ProductInterestComponentController3();
				comp.objRecord = newLead;
				comp.Initialise();

				system.assertEquals(0, comp.selectedDivisions.size());
				system.assertEquals(0, comp.selectedStreams.size());
				system.assertEquals(0, comp.selectedPortfolios.size());
				system.assertEquals(0, comp.selectedThemes.size());
				system.assertEquals(0, comp.selectedSectors.size());				
				system.assertEquals(1, comp.selectedProducts.size());
				system.assertEquals(1, comp.getSuggestedProductItems().size());

				// TEST SUGGESTED PRODUCT
				comp.selectedSuggestedProducts.add(pcC.Product__c);
				comp.SelectSuggestedProduct();
				
				system.assertEquals(2, comp.selectedProducts.size());
				system.assertEquals(0, comp.getSuggestedProductItems().size());

				// TEST SEARCH
				comp.searchText = pcA.Stream2__c;
				comp.SearchProductInterest();
				system.assertEquals(2, comp.pagedResultsWrappers.size());
				system.assertEquals(1, comp.TotalPages);

				system.assertEquals(false, comp.getHasNext());
				system.assertEquals(false, comp.getHasPrevious());
				system.assertEquals(2, comp.recordCount);

				// Select Product
				comp.selectedId = pcA.Id;
				comp.SelectSuggestedProduct();

				// Test results paging
				comp.Next();
				comp.Previous();
				comp.First();
				comp.Last();
				
				// change to view selection
				comp.viewSelection();
				system.assertEquals(2, comp.pagedResultsWrappers.size());
				system.assertEquals(false, comp.getHasNext());
				system.assertEquals(false, comp.getHasPrevious());
				system.assertEquals(2, comp.recordCount);

				// go back to view search
				comp.viewSearch();
				system.assertEquals(1, comp.pagedResultsWrappers.size());
				system.assertEquals(false, comp.getHasNext());
				system.assertEquals(false, comp.getHasPrevious());
				system.assertEquals(1, comp.recordCount);

				comp.filterStream = 'stream';
				comp.filterPortfolio = 'portfolio';
				comp.filterTheme = 'theme';
				comp.filterSector = 'sector';
				comp.SelectFilter();
				system.assertEquals(0, comp.pagedResultsWrappers.size());
				system.assertEquals(1, comp.TotalPages);

				comp.ClearAll();
				system.assertEquals('', comp.filterStream);
				system.assertEquals('', comp.filterPortfolio);
				system.assertEquals('', comp.filterTheme);
				system.assertEquals('', comp.filterSector);

				// Remove
				comp.viewSelection();
				system.assertEquals(2, comp.pagedResultsWrappers.size());
				comp.selectedId = comp.pagedResultsWrappers[0].obj.Id;
				comp.pagedResultsWrappers[0].selected = false;
				comp.SelectProduct();
				system.assertEquals(1, comp.pagedResultsWrappers.size());

				comp.Save();

				// Cancel button
				comp.Cancel();				
				system.assertEquals(true, comp.reloadNeeded);
				system.assertNotEquals('', comp.reloadPageURL);

			test.stopTest();
		}	
	}
}