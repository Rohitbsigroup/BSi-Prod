/********************************************************************
 * ProductInterestComponentController2Test
 *
 * Test methods for Product Interest Component Controller 2
 * 
 * 
 * Author: Richard Jimenez
 * Created: 27-01-2014
 * Changes: 31/08/2017 ADS
 *            - Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 ********************************************************************/
@isTest
private class ProductInterestComponentController2Test 
{
	private static testMethod void testLeadProductInterestComponentController2() 		
	{
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
		
		// create products
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification('UT-ProductA', 'StreamA', 'SubStreamA', 'PortfolioA','ProductAreaA');
		Product_Classification__c pcB = bg_UnitTestHelper.GetProductClassification('UT-ProductB', 'StreamB', 'SubStreamB', 'PortfolioB','ProductAreaB');
		Product_Classification__c pcC = bg_UnitTestHelper.GetProductClassification('UT-ProductC', 'StreamC', 'SubStreamC', 'PortfolioC','ProductAreaC');
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) {
		
			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			newLead.Product_Stream__c 			= pcA.Stream2__c;
			newLead.Product_SubStream__c 		= pcA.SubStream__c;
			newLead.Portfolio_Interests__c 		= pcA.Portfolio2__c;
			newLead.Product_Area_Interests__c 	= pcA.Family2__c;
			newLead.Product_Interests__c 		= pcA.Product__c;
			update newLead;

			system.debug('**** New Lead = ' + newLead);
		
			// create standardcontroller
			ApexPages.StandardController sc = new ApexPages.standardController(newLead);
		
			test.startTest();
				// create LeadProductInterestExt2
				LeadProductInterestExt ext = new LeadProductInterestExt(sc);

				system.debug('**** Lead Product Interest Ext = ' + ext);
			
				ProductInterestComponentController2 comp = new ProductInterestComponentController2();
				comp.objRecord = newLead;
				comp.Initialise();

				system.assertEquals(1, comp.selectedStreams.size());
				system.assertEquals(1, comp.selectedSubStreams.size());
				system.assertEquals(1, comp.selectedPortfolios.size());
				system.assertEquals(1, comp.selectedFamilies.size());
				system.assertEquals(1, comp.selectedProducts.size());
				
				// TEST STREAM
				comp.selectedStream = pcB.Stream2__c;
				comp.SelectStream();			
				system.assertEquals(pcB.SubStream__c, comp.selectedSubStream);
				system.assertEquals(pcB.Portfolio2__c, comp.selectedPortfolio);
				system.assertEquals(pcB.Family2__c, comp.selectedFamily);
				system.assertEquals(pcB.Product__c, comp.selectedProduct);
				system.assertEquals(2, comp.getStreamOptions().size());
				system.assertEquals(2, comp.getSubStreamOptions().size());
				system.assertEquals(2, comp.getPortfolioOptions().size());
				system.assertEquals(2, comp.getFamilyOptions().size());
				system.assertEquals(2, comp.getProductOptions().size());
				
				comp.ClearAll();

				// TEST SUBSTREAM
				comp.selectedSubStream = pcB.SubStream__c;
				comp.SelectSubStream();				
				system.assertEquals(pcB.SubStream__c, comp.selectedSubStream);
				system.assertEquals(pcB.Portfolio2__c, comp.selectedPortfolio);
				system.assertEquals(pcB.Family2__c, comp.selectedFamily);
				system.assertEquals(pcB.Product__c, comp.selectedProduct);
				system.assertEquals(2, comp.getStreamOptions().size());
				system.assertEquals(2, comp.getSubStreamOptions().size());
				system.assertEquals(2, comp.getPortfolioOptions().size());
				system.assertEquals(2, comp.getFamilyOptions().size());
				system.assertEquals(2, comp.getProductOptions().size());

				comp.ClearAll();

				// TEST PORTFOLIO
				comp.selectedPortfolio = pcB.Portfolio2__c;
				comp.SelectPortfolio();
				system.assertEquals(pcB.SubStream__c, comp.selectedSubStream);
				system.assertEquals(pcB.Portfolio2__c, comp.selectedPortfolio);
				system.assertEquals(pcB.Family2__c, comp.selectedFamily);
				system.assertEquals(pcB.Product__c, comp.selectedProduct);
				system.assertEquals(2, comp.getStreamOptions().size());
				system.assertEquals(2, comp.getSubStreamOptions().size());
				system.assertEquals(2, comp.getPortfolioOptions().size());
				system.assertEquals(2, comp.getFamilyOptions().size());
				system.assertEquals(2, comp.getProductOptions().size());

				comp.ClearAll();

				// TEST FAMILY
				comp.selectedFamily = pcB.Family2__c;
				comp.SelectFamily();
				system.assertEquals(pcB.SubStream__c, comp.selectedSubStream);
				system.assertEquals(pcB.Portfolio2__c, comp.selectedPortfolio);
				system.assertEquals(pcB.Family2__c, comp.selectedFamily);
				system.assertEquals(pcB.Product__c, comp.selectedProduct);
				system.assertEquals(2, comp.getStreamOptions().size());
				system.assertEquals(2, comp.getSubStreamOptions().size());
				system.assertEquals(2, comp.getPortfolioOptions().size());
				system.assertEquals(2, comp.getFamilyOptions().size());
				system.assertEquals(2, comp.getProductOptions().size());				

				comp.ClearAll();

				// TEST PRODUCT
				comp.selectedProduct = pcB.Product__c;
				comp.SelectProduct();
				system.assertEquals(pcB.SubStream__c, comp.selectedSubStream);
				system.assertEquals(pcB.Portfolio2__c, comp.selectedPortfolio);
				system.assertEquals(pcB.Family2__c, comp.selectedFamily);
				system.assertEquals(pcB.Product__c, comp.selectedProduct);
				system.assertEquals(2, comp.getStreamOptions().size());
				system.assertEquals(2, comp.getSubStreamOptions().size());
				system.assertEquals(2, comp.getPortfolioOptions().size());
				system.assertEquals(2, comp.getFamilyOptions().size());
				system.assertEquals(2, comp.getProductOptions().size());
				
				// Clear all selected products
				comp.RemoveAll();
				system.assertEquals(0, comp.selectedStreams.size());
				system.assertEquals(0, comp.selectedSubStreams.size());
				system.assertEquals(0, comp.selectedPortfolios.size());
				system.assertEquals(0, comp.selectedFamilies.size());
				system.assertEquals(0, comp.selectedProducts.size());

				// Add selection
				comp.AddSelection();
				system.assertEquals(1, comp.selectedStreams.size());
				system.assertEquals(1, comp.selectedSubStreams.size());
				system.assertEquals(1, comp.selectedPortfolios.size());
				system.assertEquals(1, comp.selectedFamilies.size());
				system.assertEquals(1, comp.selectedProducts.size());

				comp.RemoveAll();
				comp.selectedSubStreams.add(pcB.SubStream__c);
				comp.SelectListSubStream();
				system.assertEquals(1, comp.selectedStreams.size());
				system.assertEquals(1, comp.selectedSubStreams.size());
				system.assertEquals(0, comp.selectedPortfolios.size());
				system.assertEquals(0, comp.selectedFamilies.size());
				system.assertEquals(0, comp.selectedProducts.size());
							
				comp.RemoveAll();
				comp.selectedPortfolios.add(pcB.Portfolio2__c);
				comp.SelectListPortfolio();
				system.assertEquals(1, comp.selectedStreams.size());
				system.assertEquals(1, comp.selectedSubStreams.size());
				system.assertEquals(1, comp.selectedPortfolios.size());
				system.assertEquals(0, comp.selectedFamilies.size());
				system.assertEquals(0, comp.selectedProducts.size());
					
				comp.RemoveAll();
				comp.selectedFamilies.add(pcB.Family2__c);
				comp.SelectListFamily();
				system.assertEquals(1, comp.selectedStreams.size());
				system.assertEquals(1, comp.selectedSubStreams.size());
				system.assertEquals(1, comp.selectedPortfolios.size());
				system.assertEquals(1, comp.selectedFamilies.size());
				system.assertEquals(0, comp.selectedProducts.size());

				comp.RemoveAll();
				comp.selectedProducts.add(pcB.Product__c);
				comp.SelectListProduct();
				system.assertEquals(1, comp.selectedStreams.size());
				system.assertEquals(1, comp.selectedSubStreams.size());
				system.assertEquals(1, comp.selectedPortfolios.size());
				system.assertEquals(1, comp.selectedFamilies.size());
				system.assertEquals(1, comp.selectedProducts.size());

				comp.Cancel();
				system.assertEquals(pcA.Stream2__c, comp.selectedStreams[0]);
				system.assertEquals(pcA.SubStream__c, comp.selectedSubStreams[0]);
				system.assertEquals(pcA.Portfolio2__c, comp.selectedPortfolios[0]);
				system.assertEquals(pcA.Family2__c, comp.selectedFamilies[0]);
				system.assertEquals(pcA.Product__c, comp.selectedProducts[0]);

				comp.RemoveAll();
				comp.AddSelection();
				comp.Save();

				system.assertEquals(pcB.Stream2__c, newLead.Product_Stream__c);
				system.assertEquals(pcB.SubStream__c, newLead.Product_SubStream__c);
				system.assertEquals(pcB.Portfolio2__c, newLead.Portfolio_Interests__c);
				system.assertEquals(pcB.Family2__c, newLead.Product_Area_Interests__c);
				system.assertEquals(pcB.Product__c, newLead.Product_Interests__c);
				
				comp.ClearSelectedStreams();
				comp.ClearSelectedSubStreams();
				comp.ClearSelectedPortfolios();
				comp.ClearSelectedFamilies();
				comp.ClearSelectedProducts();
				comp.Save();

				system.assertEquals('', newLead.Product_Stream__c);
				system.assertEquals('', newLead.Product_SubStream__c);
				system.assertEquals('', newLead.Portfolio_Interests__c);
				system.assertEquals('', newLead.Product_Area_Interests__c);
				system.assertEquals('', newLead.Product_Interests__c);				
				
				comp.ShowStreams();
				comp.ShowSubStreams();
				comp.ShowPortfolios();
				comp.ShowFamilies();
				comp.ShowProducts();
				
			test.stopTest();
		}	
	}
}