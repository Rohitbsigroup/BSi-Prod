@isTest(seeAllData=true) // Needed for access to custom settings
private class CiWizardControllerTest {

    static testMethod void myUnitTest() {

		// Setup test data
		CI_Account__c acc = CiTestUtility.createTestAccount('-100');
		CI_Certificate__c cert = CiTestUtility.createTestCertificate(acc, '-200');		
		CI_Site__c site1 = CiTestUtility.createTestSite(acc, '-300');
		CI_Contact__c cont1 = CiTestUtility.createTestContact(site1, '-400');
		CI_Certificate_Site__c mp1 = CiTestUtility.createTestCertificateSite(cert, site1, '-600');
		CI_Visit__c visit1 = CitestUtility.createTestVisit(mp1, '-4567890');
		CI_Site__c site2 = CiTestUtility.createTestSite(acc, '-301');
		CI_Contact__c cont2 = CiTestUtility.createTestContact(site2, '-401');
		CI_Certificate_Site__c mp2 = CiTestUtility.createTestCertificateSite(cert, site2, '-601');
		CI_Visit__c visit2 = CitestUtility.createTestVisit(mp2, '-4567891');

		// Start the processing
		Test.startTest();

		// Simulate call
		PageReference step1Page = Page.CiWizard1;
		Test.setCurrentPageReference(step1Page);

		// Create an instance of the standard controller and the controller extension
		ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
		CiWizardController extCont = new CiWizardController(stdCont);

		// Call the dummy refresh method (for coverage)
		extCont.ok();

		// Select the Create New option and move on
		extCont.targetType = 'new';
		extCont.forwardToStep2();
		PageReference step2Page = Page.CiWizard2;
		Test.setCurrentPageReference(step2Page);

		// Move back and move on again
		extCont.backToStep1();
		extCont.forwardToStep2();

		// Select all the sites and move on
		for (CiWizardController.SiteWrapper site : extCont.sourceSites) site.isPicked = true;
		extCont.forwardToStep3();
		PageReference step3Page = Page.CiWizard3;
		Test.setCurrentPageReference(step3Page);

		// Move back and move on again
		extCont.backToStep2();
		extCont.forwardToStep3();
		
		// Select all the contacts and move on
		for (CiWizardController.ContactWrapper contact : extCont.sourceContacts) contact.isPicked = true;
		extCont.doIt2();

		// Introduce a duff site and contact
		CI_Site__c site3 = CiTestUtility.createTestSite(acc, '-302');
		CI_Contact__c cont3 = CiTestUtility.createTestContact(site2, '-402');
		site3.Postcode__c = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
		update site3;
		cont3.Postcode__c = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
		update cont3;

		// Now start again because we have created one
		stdCont = new ApexPages.standardController(acc);
		extCont = new CiWizardController(stdCont);
		
		// Select the Create Old option and no account
		extCont.targetType = 'old';
		extCont.tempSite.Account__c = null;
		extCont.forwardToStep2();

		// Select the Create Old option and account
		Account newAcc = [
			SELECT	ea.Id
			FROM	Account ea
			WHERE	ea.GoldenCompanyID__c = :Integer.valueOf(acc.Account_Id__c)
			LIMIT	1
		];
		extCont.tempSite.Account__c = newAcc.Id;
		extCont.forwardToStep2();
		step2Page = Page.CiWizard2;
		Test.setCurrentPageReference(step2Page);

		// Select all the sites and move on
		for (CiWizardController.SiteWrapper site : extCont.sourceSites) site.isPicked = true;
		extCont.forwardToStep3();
		step3Page = Page.CiWizard3;
		Test.setCurrentPageReference(step3Page);
		
		// Select all the contacts and move on
		for (CiWizardController.ContactWrapper contact : extCont.sourceContacts) contact.isPicked = true;
		extCont.doIt2();		

		// Stop the processing
		Test.stopTest();
    }
}