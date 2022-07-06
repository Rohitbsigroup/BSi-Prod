/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         07/12/2011
* Description:  TEST CLASS: NewQuoteController
*
* ------------------
* TESTING:		 90%
* ------------------
*       
**/
@isTest
private class NewQuoteControllerTest {
	
	// Testing creating a new quote and adding products
    static testMethod void creatingNewQuote() {
		// Set up data
		SiteSetting__c s = SiteSetting__c.getInstance();
		Account acc = TestData.getTestAccount();
		insert acc;
		Contact con = TestData.getTestContact();
		con.AccountId = acc.Id;
		insert con;
		Opportunity opty = TestData.getTestOpty();
		opty.AccountId = acc.Id;
		insert opty;
		// Add a new Site
		Site__c site = TestData.getTestSite();
		site.Type__c = 'Test Scope Site';
		site.Account__c = acc.Id;
		insert site;
		// Query for the HQ Auto created and link it to the opportunity
		Site__c hq = [SELECT Name FROM Site__c WHERE Account__c =:acc.Id AND Type__c =:s.HQLabel__c];
		OpportunitySite__c osite = new OpportunitySite__c();
		osite.HQ__c = true;
		osite.Opportunity__c = opty.Id;
		osite.Site__c = hq.Id;
		insert osite;
		// Link the other site
		OpportunitySite__c osite2 = new OpportunitySite__c();
		osite2.Opportunity__c = opty.Id;
		osite2.Site__c = site.Id;
		insert osite2;
		Product__c prod = new Product__c();
		prod.Name = '14001';
		prod.Active__c = true;
		prod.Cost_Center__c = 'Std';
		prod.Product_Family__c = 'Std';
		prod.Country__c = 'GB';
		insert prod;
		Product__c fake = new Product__c();
		fake.Name = '14001 Site';
		fake.Active__c = true;
		fake.Cost_Center__c = 'Std';
		fake.Product_Family__c = 'Std';
		insert fake;

		Test.startTest();
		
		Test.setCurrentPage(Page.newQuote);
		ApexPages.currentPage().getParameters().put('oppid', opty.Id);
		ApexPages.currentPage().getParameters().put('accid', acc.Id);
        NewQuoteController controller = new NewQuoteController();
        
        System.assertEquals(controller.back().getURL(), '/' + opty.Id);
        
        // Calling getters
        controller.getContacts();
        controller.generateQuote(); // Test Exception - no Contact
        controller.sContact = con.Id;
        controller.sInvoice	= con.Id;
        controller.newQuote.Booking__c = con.Id;
        controller.newQuote.CreditCheck__c = con.Id;
        controller.getFamilys(); 
        controller.sFamily = 'Std';
        controller.getCostCenters();
        controller.sCostCenter = 'Std';
        controller.generateQuote(); // Test Exception - no Site Type
        controller.sType = 'HQ';
        controller.getSites();
		controller.queryProducts();
		controller.searchProds();
		controller.generateQuote(); // Test Exception - no Products
		// Search and check the product inserted
		for (NewQuoteController.ProductWrapper curr: controller.PWlist) {
			if (curr.product.Id == prod.Id) controller.PWlist.get(0).checked = true;
		}
		// Required questions and detail to save
		controller.siteTypes.get(0).approved = 'Yes';
		controller.updatePath();
		controller.generateQuote();
		
		
		// Check the saved quote
		List<Quote__c> quotes = [SELECT Id FROM Quote__c WHERE Id =:controller.newQuote.Id];
		System.assertEquals(quotes.size(), 1);
		
		// Redirect to Manage Site page
		System.assertEquals(controller.manageSite().getURL(), '/apex/addOptySite?oppid=' + opty.Id);
		
		// Testing adding new products to existing quote
		Test.setCurrentPage(Page.newQuote);
		ApexPages.currentPage().getParameters().put('quoid', quotes.get(0).Id);
		ApexPages.currentPage().getParameters().put('oppid', opty.Id);
		NewQuoteController controllerEdit = new NewQuoteController();
		
		// Search and check the product inserted
		for (NewQuoteController.ProductWrapper curr: controllerEdit.PWlist) {
			if (curr.product.Id == prod.Id) controllerEdit.PWlist.get(0).checked = true;
		}
		System.assertEquals(controllerEdit.back().getURL(), '/' + quotes.get(0).Id);
		controllerEdit.generateQuote();
		Test.stopTest();
    }
  
}