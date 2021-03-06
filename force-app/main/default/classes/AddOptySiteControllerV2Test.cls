/********************************************************************
 * AddOptySiteControllerV2Test 
 *
 * Test class for AddOptySiteControllerV2
 * 
 * 
 * Author: Rob Earey
 * Created: 22-10-2013
 * Changes: 
 * Changes: 24-05-2017 - RC changed assert statements to take into 
 *                       account the auto creation of a default site.
 ********************************************************************/
@isTest 
private class AddOptySiteControllerV2Test 
{
	static testMethod void addOptySiteTest() {
		
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
        // Set up test data
        Account acc = TestData.getTestAccount();
        insert acc;
        Contact con = TestData.getTestContact();
        con.AccountId = acc.Id;
        insert con;
        Opportunity opty = TestData.getTestOpty();
        opty.AccountId = acc.Id;
        insert opty;
        Contact_Opportunity__c contOpp = bg_UnitTestHelper.GetOpportunityContact(opty, con, 'Influencer');
        List<Site__c> sites = new List<Site__c>();
     	Site__c s1 = bg_UnitTestHelper.GetSite(acc, 'TestSite11', 'GB','NAMED', 'EC1 3NS');
     	Site__c s2 = bg_UnitTestHelper.GetSite(acc, 'TestSite22', 'GB', 'NAMED', 'W14 9NN');     

        OpportunitySite__c os = new OpportunitySite__c();
        os.Site__c = s1.Id;
        os.Opportunity__c = opty.Id;
        os.ProposedScope__c = 'Test';
        insert os;
        
        Test.setCurrentPage(Page.addOptySiteV2);
        ApexPages.currentPage().getParameters().put('oppid',opty.Id);
        //AddOptySiteController controller = new AddOptySiteController(new Apexpages.Standardcontroller(opty));
        AddOptySiteControllerV2 controller = new AddOptySiteControllerV2();
        
        // Adding an existing site
        //am changing this as hq site is not autogenerated anymore
        controller.deselectAll();
        controller.selectAll();
        controller.linkToOpty();
        //System.assertEquals(controller.optySitesNew.size(), 1); // HQ is auto created - not here - check
        
        // Adding a new site
        controller.newSite = TestData.getTestSite('CM8 1BB');
        controller.newSite.name = 'TestSite33';
        controller.showNewSection = true;
        controller.addNewSite();
        //system.assertEquals(false, bg_StringUtils.IsBlank(controller.errorMessage));
        //system.assertEquals(false, controller.showError);
        //System.assertEquals(2, controller.optySitesNew.size()); // HQ is auto created - not here - check
        
        // Save selection
     	//System.assertEquals(controller.saveAll().getURL(), '/' + opty.Id);
     	
     	// Remove from list
     	controller.toRemove = string.valueOf(controller.optySitesNew[0].index);
     	controller.removeLink();
     	controller.toRemove = string.valueOf(controller.optySitesNew[0].index);
     	controller.removeLink();
     	system.debug('controller.optySitesNew: ' + controller.optySitesNew);
     	//System.assertEquals(controller.optySitesNew.size(), 0); // HQ is auto created
     	
     	// Add contact Role
     	controller.getAccContacts();
     	controller.getRoles();
     	controller.addContactRole(con.Id);
     	controller.saveAndQuote();
     	
     	// Cancel
     	//System.assertEquals(controller.back().getURL(), '/' + opty.Id);
    }
    
	static testMethod void addOptySiteTest2() {
		
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
        // Set up test data
        Account acc = TestData.getTestAccount();
        insert acc;
        Contact con = TestData.getTestContact();
        con.AccountId = acc.Id;
        insert con;
        Opportunity opty = TestData.getTestOpty();
        opty.AccountId = acc.Id;
        insert opty;
        Contact_Opportunity__c contOpp = bg_UnitTestHelper.GetOpportunityContact(opty, con, 'Influencer');
        List<Site__c> sites = new List<Site__c>();
     	Site__c s1 = bg_UnitTestHelper.GetSite(acc, 'TestSite11', 'GB','NAMED', 'EC1 3NS');
     	
     	Site__c s2 = bg_UnitTestHelper.GetSite(acc, 'TestSite22', 'GB', 'NAMED', 'W14 9NN');     
        OpportunitySite__c os = new OpportunitySite__c();
        os.Site__c = s1.Id;
        os.Opportunity__c = opty.Id;
        os.ProposedScope__c = 'Test';
        insert os;
        
        Test.setCurrentPage(Page.addOptySiteV2);
        ApexPages.currentPage().getParameters().put('oppid',opty.Id);
        AddOptySiteControllerV2 controller = new AddOptySiteControllerV2();
        
        // Adding an existing site
        controller.deselectAll();
        controller.selectAll();
        controller.linkToOpty();
        System.assertEquals(controller.optySitesNew.size(), 1); // HQ is auto created - not here - check
        
        controller.siteDefault();
        controller.showNewSection = true;
        controller.addNewSite();
        System.assertEquals(controller.optySitesNew.size(), 1); // HQ is auto created - not here - check
        
        // Save selection
     	System.assertEquals(controller.saveAll().getURL(), '/' + opty.Id);
     	
     	// Remove from list
     	controller.toRemove = string.valueOf(controller.optySitesNew[0].index);
     	controller.removeLink();
     	System.assertEquals(controller.optySitesNew.size(), 0); // HQ is auto created
     	
     	// Add contact Role
     	controller.getAccContacts();
     	controller.getRoles();
     	controller.addContactRole(con.Id);
     	controller.saveAndQuote();
     	
     	controller.getAccSites();

     	// Cancel
     	System.assertEquals(controller.back().getURL(), '/' + opty.Id);
    }
}