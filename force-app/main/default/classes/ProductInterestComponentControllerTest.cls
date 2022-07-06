/********************************************************************
 * ProductInterestComponentControllerTest
 *
 * Test methods for Product Interest Component Controller
 * 
 * 
 * Author: Rob Earey
 * Created: 17-10-2013
 * Changes: 
 ********************************************************************/
@isTest
private class ProductInterestComponentControllerTest 
{
	private static testMethod void testLeadProductInterestComponentController() 		
	{
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
		
		// create products
		Product__c productA = bg_UnitTestHelper.GetProduct('UT-ProductA', true, 'PortfolioA','ProductAreaA');
		Product__c productB = bg_UnitTestHelper.GetProduct('UT-ProductB', true, 'PortfolioB','ProductAreaB');
		Product__c productC = bg_UnitTestHelper.GetProduct('UT-ProductC', true, 'PortfolioC','ProductAreaC');
		Product_Bundle__c prodbundleA = bg_UnitTestHelper.GetProductBundle('testbundleA');
		Product_Relationship__c prodRelA = bg_UnitTestHelper.GetProductBundleRelationship(prodbundleA, productA);
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{
		
			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			newLead.Portfolio_Interests__c = 'PortfolioA';
			newLead.Product_Area_Interests__c = 'ProductAreaA';
			update newLead;
			
			system.debug('**** New Lead = ' + newLead);
		
			// create standardcontroller
			ApexPages.StandardController sc = new ApexPages.standardController(newLead);
		
			test.startTest();
				// create LeadProductInterestExt
				LeadProductInterestExt ext = new LeadProductInterestExt(sc);
				
				system.debug('**** Lead Product Interest Ext = ' + ext);
			
				ProductInterestComponentController comp1 = new ProductInterestComponentController();
				comp1.objRecord = newLead;
				system.assertEquals(0, comp1.getProductAreaOptions().size());
				
				ProductInterestComponentController comp2 = new ProductInterestComponentController();
				comp2.objRecord = newLead;
				system.assertEquals(4, comp2.getProductOptions().size());
				
				ProductInterestComponentController comp3 = new ProductInterestComponentController();
				comp3.objRecord = newLead;
				system.assertEquals(2, comp3.getProductBundleOptions().size());
				
				ProductInterestComponentController comp4 = new ProductInterestComponentController();
				comp4.objRecord = newLead;
				system.assertEquals(0, comp4.getSelectedProductsList().size());				

				ProductInterestComponentController comp = new ProductInterestComponentController();
				comp.objRecord = newLead;
				// verify lists initialised
				system.assertEquals(4, comp.getPortfolioOptions().size());
				system.assertEquals(0, comp.getProductAreaOptions().size());
				comp.selectedPortfolio = 'PortfolioA';
				system.assertEquals(2, comp.getProductAreaOptions().size());
				system.assertEquals(2, comp.getProductOptions().size());			
				system.assertEquals(0, comp.getSelectedProductsList().size());
				
				system.assertEquals(0, comp.getSelectedProductsList().size());				
				
				comp.selectedPortfolio = '';
				comp.selectedProductArea = '';
				comp.selectedProduct = '';
				system.assertEquals(2, comp.getProductBundleOptions().size());
								
				comp.selectedPortfolio = 'PortfolioA';
				system.assertEquals(2, comp.getProductBundleOptions().size());
				comp.SelectPortfolio(); 
				
				comp.selectedProductArea = 'ProductAreaA';
				system.assertEquals(2, comp.getProductBundleOptions().size());
				comp.SelectProductArea();
				
				// Select Product A
				comp.selectedProduct = productA.name;
				comp.AddProduct();
				system.assertEquals(1, comp.getSelectedProductsList().size());
				system.assertEquals(2, comp.getProductBundleOptions().size());
				
				list<SelectOption> optionItemstest2 = new list<SelectOption>();
				optionItemstest2 = comp.getSelectedProductsList();
				system.assertEquals(1, optionItemstest2.size());
				
				comp.UnselectProducts.add(productA.name);
				comp.RemoveProduct();
				comp.Cancel();
				
				comp.selectedProductBundle = 'testbundleA';
				comp.SelectProductBundle();
				system.assertEquals(1, comp.bundleProducts.size());
				comp.AddBundle();
				
				comp.selectedProductBundle = '';
				comp.SelectProductBundle();
				system.assertEquals(0, comp.bundleProducts.size());
				
				comp.selectedPortfolio = 'PortfolioA';
				comp.selectedProductArea = 'ProductAreaA';
				list<SelectOption> optionItemstest = new list<SelectOption>();
				optionItemstest = comp.getProductOptions();
				system.assertEquals(2, optionItemstest.size());
				comp.selectedProduct = 'UT-ProductA';
				comp.SelectProduct();
				comp.AddProduct();
				comp.Save();
				
			test.stopTest();
		}	
	}
	/*
	select portfolio (product A)
			ext.selectedPortfolio = productA.Portfolio_Interest__c;
			ext.SelectPortfolio();
			system.assertEquals(2, ext.getProductAreaOptions().size());
			system.assertEquals(0, ext.getProductOptions().size());									

			// select product area (product A)
			ext.selectedProductArea = productA.Product_Area_Interest__c;
			ext.SelectProductArea();
			system.assertEquals(2, ext.getProductOptions().size());									

			// select product A
			ext.selectedProduct = productA.name;
			ext.AddProduct();			
			system.assertEquals(1, ext.getSelectedProductsList().size());
			
			// Save selection
			ext.Save();
			
			// select product B
			ext.selectedPortfolio = productB.Portfolio_Interest__c;
			ext.selectedProductArea = productB.Product_Area_Interest__c;
			ext.selectedProduct = productB.name;
			ext.AddProduct();
			system.assertEquals(2, ext.getSelectedProductsList().size());	
			
			// remove product B
			ext.unselectProducts.add(productB.name);
			ext.RemoveProduct();
			system.assertEquals(1, ext.getSelectedProductsList().size());
			
			// remove product A
			ext.unselectProducts.add(productA.name);
			ext.RemoveProduct();
			system.assertEquals(0, ext.getSelectedProductsList().size());
			
			// cancel change
			ext.Cancel();
			system.assertEquals(1, ext.getSelectedProductsList().size()); 
	
	*/
	
	private static testMethod void testOppProductInterestComponentController() 		
	{
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
		
		// create products
		Product__c productA = bg_UnitTestHelper.GetProduct('UT-ProductA', true, 'PortfolioA','ProductAreaA');
		Product__c productB = bg_UnitTestHelper.GetProduct('UT-ProductB', true, 'PortfolioB','ProductAreaB');
		Product__c productC = bg_UnitTestHelper.GetProduct('UT-ProductC', true, 'PortfolioC','ProductAreaC');
		Product_Bundle__c prodbundleA = bg_UnitTestHelper.GetProductBundle('testbundleA');
		Product_Relationship__c prodRelA = bg_UnitTestHelper.GetProductBundleRelationship(prodbundleA, productA);
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{
		
			// create account
			Account newAcc = bg_UnitTestHelper.GetAccount('TestAcc1');
			// create opportunity
			Opportunity newOpp = bg_UnitTestHelper.GetOpportunity(newAcc);
			newOpp.Portfolio_Interests__c = 'PortfolioA';
			newOpp.Product_Area_Interests__c = 'ProductAreaA';
			update newOpp;
			
			system.debug('**** New Opportunity = ' + newOpp);
		
			// create standardcontroller
			ApexPages.StandardController sc = new ApexPages.standardController(newOpp);
		
			test.startTest();
				// create LeadProductInterestExt
				OpportunityProductInterestExt ext = new OpportunityProductInterestExt(sc);
				
				system.debug('**** Opportunity Product Interest Ext = ' + ext);
			
				ProductInterestComponentController comp = new ProductInterestComponentController();
				comp.objRecord = newOpp;

				// verify lists initialised
				system.assertEquals(4, comp.getPortfolioOptions().size());
				system.assertEquals(0, comp.getProductAreaOptions().size());
				comp.selectedPortfolio = 'PortfolioA';
				system.assertEquals(2, comp.getProductAreaOptions().size());
				system.assertEquals(2, comp.getProductOptions().size());			
				system.assertEquals(0, comp.getSelectedProductsList().size());
				
				system.assertEquals(0, comp.getSelectedProductsList().size());				
				
				comp.selectedPortfolio = '';
				comp.selectedProductArea = '';
				comp.selectedProduct = '';
				system.assertEquals(2, comp.getProductBundleOptions().size());
								
				comp.selectedPortfolio = 'PortfolioA';
				system.assertEquals(2, comp.getProductBundleOptions().size());
				comp.SelectPortfolio(); 
				
				comp.selectedProductArea = 'ProductAreaA';
				system.assertEquals(2, comp.getProductBundleOptions().size());
				comp.SelectProductArea();
				
				comp.selectedProduct = 'UT-ProductA';
				system.assertEquals(2, comp.getProductBundleOptions().size());
				comp.SelectProduct();
				comp.AddProduct();
				
				list<SelectOption> optionItemstest2 = new list<SelectOption>();
				optionItemstest2 = comp.getSelectedProductsList();
				system.assertEquals(1, optionItemstest2.size());
				
				comp.UnselectProducts.add('UT-ProductA');
				comp.RemoveProduct();
				comp.Cancel();
				
				comp.selectedProductBundle = 'testbundleA';
				comp.SelectProductBundle();
				system.assertEquals(1, comp.bundleProducts.size());
				comp.AddBundle();
				
				comp.selectedProductBundle = '';
				comp.SelectProductBundle();
				system.assertEquals(0, comp.bundleProducts.size());
				
				comp.selectedPortfolio = 'PortfolioA';
				comp.selectedProductArea = 'ProductAreaA';
				list<SelectOption> optionItemstest = new list<SelectOption>();
				optionItemstest = comp.getProductOptions();
				system.assertEquals(2, optionItemstest.size());
				comp.selectedProduct = 'UT-ProductA';
				comp.SelectProduct();
				comp.AddProduct();
				comp.Save();
				
			test.stopTest();
		}	
	}			
}