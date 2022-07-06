/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         19/12/2011
* Description:  TEST CLASS: ContactRoleController - NOT NEEDED ANYMORE
*
* ------------------
* TESTING:		 88%
* ------------------
*       
**/
@isTest
private class ContactRoleControllerTest {
/*
    static testMethod void addContactRoles() {
        // Set up data
        Account acc = TestData.getTestAccount();
        insert acc;
        Opportunity opty = TestData.getTestOpty();
        opty.AccountId = acc.Id;
        insert opty;
        // Contacts
        List<Contact> contacts = new List<Contact>();
        Contact c1 = TestData.getTestContact();
        c1.LastName = 'Test1';
        c1.AccountId = acc.Id;
        contacts.add(c1);
        Contact c2 = TestData.getTestContact();
        c2.LastName = 'Test';
        c2.AccountId = acc.Id;
        contacts.add(c2);
        insert contacts;
        // Sites
        List<Site__c> sites = new List<Site__c>();
        Site__c s1 = TestData.getTestSite('W2 9LP');
        s1.Account__c = acc.Id;
        sites.add(s1);
        Site__c s2 = TestData.getTestSite('EC 3NS');
        s2.Account__c = acc.Id;
        sites.add(s2);
        insert sites;
        // Opportunity Sites
        OpportunitySite__c opps1 = new OpportunitySite__c(Site__c = s1.Id,Opportunity__c = opty.Id);
        insert opps1;
        OpportunitySite__c opps2 = new OpportunitySite__c(Site__c = s2.Id,Opportunity__c = opty.Id);
        insert opps2;     
        // Contact Sites
        List<ContactSite__c> csites = new List<ContactSite__c>();
        ContactSite__c cs1 = new ContactSite__c(Contact__c = c1.Id,Site__c = s1.Id);
        csites.add(cs1);
  		ContactSite__c cs2 = new ContactSite__c(Contact__c = c2.Id,Site__c = s2.Id);
        csites.add(cs2);
        insert csites;
        // Existing Opportunity Site
        Contact_Opportunity__c oldprimary = new Contact_Opportunity__c();
        oldprimary.Contact__c = c1.Id;
        oldprimary.OppPrimary__c = true;
        oldprimary.Opportunity__c = opty.Id;
        insert oldprimary;
        
        // Controller
        Test.setCurrentPage(Page.contactRole);
        Apexpages.currentPage().getParameters().put('oppid', opty.Id);
        ContactRoleController controller = new ContactRoleController();
        
        // Select one contact role and update as primary
        controller.primaryId = controller.siteGroups.get(1).croles.get(0).contact.Contact__c; // Contact from the second site
        controller.saveAll(); // Check Exception - No role selected for primary contact
        controller.siteGroups.get(0).croles.get(0).role = 'Test';
        controller.primaryId = controller.siteGroups.get(0).croles.get(0).contact.Contact__c; // Contact same as the existing one
        controller.getRoles();
        controller.saveAll();
        
        // Checking expected results
        System.assertEquals(oldprimary.Contact__c,controller.siteGroups.get(0).croles.get(0).contact.Contact__c); // Same as oldprimary
        List<Contact_Opportunity__c> coptys = [SELECT Id FROM Contact_Opportunity__c WHERE Opportunity__c =:opty.Id];
        System.assertEquals(coptys.size(),2);
       
        System.assertEquals(controller.back().getURL(), '/' + opty.Id);
    }
    
    */
}