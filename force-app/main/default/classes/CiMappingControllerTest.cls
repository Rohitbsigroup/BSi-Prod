@isTest
private class CiMappingControllerTest
{
    static testMethod void myUnitTest()
    {
		// Setup test data
		CI_Account__c acc = CiTestUtility.createTestAccount('100');
		CI_Certificate__c cert = CiTestUtility.createTestCertificate(acc, '200');		
		CI_Site__c site1 = CiTestUtility.createTestSite(acc, '300');
		CI_Contact__c cont1 = CiTestUtility.createTestContact(site1, '400');
		CI_Certificate_Site__c mp1 = CiTestUtility.createTestCertificateSite(cert, site1, '600');
		CI_Visit__c visit1 = CitestUtility.createTestVisit(mp1, '4567890');
		CI_Site__c site2 = CiTestUtility.createTestSite(acc, '301');
		CI_Contact__c cont2 = CiTestUtility.createTestContact(site2, '401');
		CI_Certificate_Site__c mp2 = CiTestUtility.createTestCertificateSite(cert, site2, '601');
		CI_Visit__c visit2 = CitestUtility.createTestVisit(mp2, '4567891');
		CI_Assessor__c ass = CiTestUtility.createTestAssessor('100');
		Training_Venue__c ven = CiTestUtility.createTestTrainingVenue();
		Training_Event__c evt = CiTestUtility.createTestTrainingEvent(ven);
		
		// Start the processing
		Test.startTest();


		// Simulate call from Sites tab
		PageReference sitesPage = Page.CI_Map_Sites;
		Test.setCurrentPageReference(sitesPage);
     	ApexPages.currentPage().getParameters().put('retUrl', '');

		// Try with no sites selected
		List<CI_Site__c> sites = new List<CI_Site__c>();
		ApexPages.StandardSetController stdCont1 = new ApexPages.standardSetController(sites);
		CiMappingController extCont1 = new CiMappingController(stdCont1);
		System.assert(extCont1.isValid == false);
				
		// Now add some sites
		sites.add(site1);
		sites.add(site2);
		stdCont1 = new ApexPages.standardSetController(sites);
		extCont1 = new CiMappingController(stdCont1);
		System.assert(extCont1.isValid == true);
		extCont1.showSites = true;
		extCont1.showAssessors = true;
		extCont1.showVisits = true;
		extCont1.showEvents = true;
		PageReference result1 = extCont1.SiteBased();
		
		// Try bad date parameters
		extCont1.dateStore.Start_Date__c = null;
		result1 = extCont1.SiteBased();


		// Simulate call from Contacts tab
		PageReference contsPage = Page.CI_Map_Contacts;
		Test.setCurrentPageReference(contsPage);
     	ApexPages.currentPage().getParameters().put('retUrl', '');
		
		// Try with no contacts selected
		List<CI_Contact__c> conts = new List<CI_Contact__c>();
		ApexPages.StandardSetController stdCont2 = new ApexPages.standardSetController(conts);
		CiMappingController extCont2 = new CiMappingController(stdCont2);
		System.assert(extCont2.isValid == false);

		// Try with contacts selected
		conts.add(cont1);
		conts.add(cont2);
		stdCont2 = new ApexPages.standardSetController(conts);
		extCont2 = new CiMappingController(stdCont2);
		System.assert(extCont2.isValid == true);
		extCont2.showSites = true;
		extCont2.showAssessors = true;
		extCont2.showVisits = true;
		extCont2.showEvents = true;
		PageReference result2 = extCont2.SiteBased();


		// Simulate call for Nearby
		PageReference nearbyPage = Page.CI_Map_Nearby;
		Test.setCurrentPageReference(nearbyPage);
     	ApexPages.currentPage().getParameters().put('retUrl', '');
		
		// Try with no id selected
		CiMappingController extCont3 = new CiMappingController();
		System.assert(extCont3.isValid == false);

		// Try with a contact
     	ApexPages.currentPage().getParameters().put('id', cont1.Id);
		extCont3 = new CiMappingController();
		System.assert(extCont3.isValid == true);
		extCont3.showSites = true;
		extCont3.showAssessors = true;
		extCont3.showVisits = true;
		extCont3.showEvents = true;
		PageReference result3 = extCont3.NearbyBased();

		// Try with a site
     	ApexPages.currentPage().getParameters().put('id', site1.Id);
		extCont3 = new CiMappingController();
		System.assert(extCont3.isValid == true);
		extCont3.showSites = true;
		extCont3.showAssessors = true;
		extCont3.showVisits = true;
		extCont3.showEvents = true;
		result3 = extCont3.NearbyBased();
		
		// Try bad date parameters
		extCont3.dateStore.Start_Date__c = null;
		result3 = extCont3.NearbyBased();

		// Simulate call for Account
		PageReference accountPage = Page.CI_Map_Account;
		Test.setCurrentPageReference(accountPage);
     	ApexPages.currentPage().getParameters().put('id', acc.Id);
     	ApexPages.currentPage().getParameters().put('retUrl', '');
		
		// Try with good data
		CiMappingController extCont5 = new CiMappingController();
		System.assert(extCont5.isValid == true);
		extCont5.showSites = true;
		extCont5.showVisits = true;
		PageReference result5 = extCont5.AccountBased();

		// Stop the processing
		Test.stopTest();
    }
}