/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         15/11/2011
* Description:  TEST CLASS: AddLeadSiteController
*
* ------------------
* TESTING:		 92%
* ------------------
*       
**/
@isTest
private class AddLeadSiteControllerTest {
	
	// Testing adding and deleting Lead sites
    static testMethod void addLeadSiteTest() {
        // Set up test data
        Lead l = TestData.getTestLead();
        insert l;
        Site__c s = TestData.getTestSite();
        s.Lead__c = l.Id;
        insert s;
        
        Test.setCurrentPage(Page.addLeadSite);
        AddLeadSiteController controller = new AddLeadSiteController(new Apexpages.Standardcontroller(l));
        
        // Adding a site
        controller.site.Name = 'Test';
        //controller.addSite(); // Fail because of custom validation (Postcode or Street required)
        controller.site.Street__c = 'Test Street';
        controller.addSite();
        System.assertEquals(2, controller.newSites.size());
        controller.saveAll();
        List<Site__c> tempSites = [SELECT Id FROM Site__c WHERE Lead__c =:l.Id];
        // Check expected result
        System.assertEquals(2, tempSites.size());
        
        // Removing a site        
        controller.toRemove = '1'; // Removing the second element
        controller.removeSite();
        tempSites = [SELECT Id FROM Site__c WHERE Lead__c =:l.Id];
        // Check expected result
        System.assertEquals(1, tempSites.size());
        
        // Updating a site
        controller.toEdit = '0';
        controller.editSite();
        controller.site.Name = 'Test Changed';
        controller.editComplete();
        // Check expected result
        System.assertEquals(controller.newSites.get(0).site.Name, 'Test Changed');
        
        controller.getPageURL();
        
    }
}