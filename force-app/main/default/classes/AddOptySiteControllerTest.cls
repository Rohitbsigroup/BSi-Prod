/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         18/11/2011
* Description:  TEST CLASS: AddOptySiteController
*
* ------------------
* TESTING:		 92%
* ------------------
* Changes :
*   24-05-2017 - RC BG - updated asserts to take into account auto generated sites.    
*   04-08-2017 - RC BG - Remove 2nd remove link from test and link only removes particular record type.
**/
@isTest
private class AddOptySiteControllerTest {

    static testMethod void addOptySiteTest() {
        // Set up test data
        Account acc = TestData.getTestAccount();
        insert acc;
        Contact con = TestData.getTestContact();
        con.AccountId = acc.Id;
        insert con;
        Opportunity opty = TestData.getTestOpty();
        opty.AccountId = acc.Id;
        insert opty;
        List<Site__c> sites = new List<Site__c>();
        Site__c s1 = TestData.getTestSite('EC1 3NS');
        s1.Account__c = acc.Id;
        Site__c s2 = TestData.getTestSite('W14 9NN');
        s2.Account__c = acc.Id;
        sites.add(s1);
        sites.add(s2);
        insert sites;
        OpportunitySite__c os = new OpportunitySite__c();
        os.Site__c = s1.Id;
        os.Opportunity__c = opty.Id;
        os.ProposedScope__c = 'Test';
        insert os;
        
        Test.setCurrentPage(Page.addOptySite);
        ApexPages.currentPage().getParameters().put('oppid',opty.Id);
        //AddOptySiteController controller = new AddOptySiteController(new Apexpages.Standardcontroller(opty));
        AddOptySiteController controller = new AddOptySiteController();
        
        // Adding an existing site
        controller.deselectAll();
        controller.selectAll();
        controller.linkToOpty();
        System.assertEquals(1, controller.optySitesNew.size()); // HQ is auto created - not here - check
        
        // Adding a new site
        controller.newSite = TestData.getTestSite();
        controller.addNew();
        System.assertEquals(1, controller.optySitesNew.size()); // HQ is auto created - not here - check
        
        // Save selection
     	System.assertEquals(controller.saveAll().getURL(), '/' + opty.Id);
     	
     	// Remove from list
     	/*controller.toRemove = '0';
     	controller.removeLink();
     	System.assertEquals(0, controller.optySitesNew.size()); // HQ is auto created
     	*/
     	// Add contact Role
     	controller.getAccContacts();
     	controller.getRoles();
     	controller.addContactRole(con.Id);
     	controller.saveAndQuote();
     	
     	// Cancel
     	System.assertEquals(controller.back().getURL(), '/' + opty.Id);
    }
}