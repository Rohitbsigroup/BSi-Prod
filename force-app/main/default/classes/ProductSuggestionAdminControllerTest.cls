/********************************************************************
 * ProductSuggestionAdminControllerTest 
 *
 * Test class for ProductSuggestionAdminController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 10-11-2013
 * Changes: 
 ********************************************************************/
@isTest 
private class ProductSuggestionAdminControllerTest 
{
	private static testMethod void productSuggestionAdminControllerTest() {

		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

		// Set custom settings
		BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=user1.Id, 
					CanEditSuggestedProductsAMERICAS__c = true,
					CanEditSuggestedProductsAPAC__c = true,
					CanEditSuggestedProductsEMEA__c = true,
					CanEditSuggestedProductsGLOBAL__c = true,
					CanEditSuggestedProductsOTHER__c = true);
        insert perms;
		
		system.runAs(user1)
		{
			// Create Product Classifications
			Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductA', 'StreamA', 'PortfolioA','ProductAreaA');
			Product_Classification__c pcB = bg_UnitTestHelper.GetProductClassification2('UT-ProductB', 'StreamB', 'PortfolioB','ProductAreaB');
			Product_Classification__c pcC = bg_UnitTestHelper.GetProductClassification2('UT-ProductC', 'StreamC', 'PortfolioC','ProductAreaC');
	
			// Create Product Classification Relationships
			Product_Classification_Relationship__c pcr1 = new Product_Classification_Relationship__c();
			pcr1.ProductClassification__c = pcA.Id;
			pcr1.SuggestedProductClassification__c = pcB.Id;
			pcr1.Region__c = 'Global';
			insert pcr1;
	
			// Instantiate controller
	        Test.setCurrentPage(Page.ProductSuggestionAdmin);
	        ProductSuggestionAdminController controller = new ProductSuggestionAdminController();
	
			// Test select lists are populates
			system.assertEquals(2, controller.selectProductItems.size());
			system.assertEquals(4, controller.productItems.size());
			
			// Test  select list option
			controller.withSuggestionsOnly = false;
			controller.PopulateProductList();
			system.assertEquals(4, controller.selectProductItems.size());
			
			// Test product with no suggestions
			controller.selectedProductId = pcB.Id;
			controller.GetSuggestedProducts();
			system.assertEquals(0, controller.suggestedProductWrappers.size());
	
			// Test product with suggestions
			controller.selectedProductId = pcA.Id;
			controller.GetSuggestedProducts();
			system.assertEquals(1, controller.suggestedProductWrappers.size());
	
			// Test product with suggestions
			controller.selectedProductId = pcA.Id;
			controller.GetSuggestedProducts();
			system.assertEquals(1, controller.suggestedProductWrappers.size());
	
			// Test add with cancel
			controller.AddSuggestedProduct();
			system.assertEquals(2, controller.suggestedProductWrappers.size());
			controller.Cancel();
			system.assertEquals(1, controller.suggestedProductWrappers.size());
	
			// Test delete
			controller.deleteSuggestedProductId = controller.suggestedProductWrappers[0].obj.Id;
			controller.DeleteSuggestedProduct();
			controller.GetSuggestedProducts();
			system.assertEquals(0, controller.suggestedProductWrappers.size());

			// Test add with Save
			controller.AddSuggestedProduct();
			system.assertEquals(1, controller.suggestedProductWrappers.size());
			controller.suggestedProductWrappers[0].obj.SuggestedProductClassification__c = pcC.Id;
			controller.suggestedProductWrappers[0].obj.Region__c = 'Global'; 
			controller.Save();
			controller.GetSuggestedProducts();
			system.assertEquals(1, controller.suggestedProductWrappers.size());		
		}
	}
}