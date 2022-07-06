@isTest
private class CiSearchControllerTest {

    static testMethod void myUnitTest() {

		// Setup test data
    	CI_Account__c acc = CiTestUtility.createTestAccount('-100');
    	CI_Site__c sit = CiTestUtility.createTestSite(acc, '-101');
    
    	// Start the processing
    	Test.startTest();

    	// Simulate call
    	PageReference searchPage = Page.CiSearch;
    	Test.setCurrentPageReference(searchPage);
    	ApexPages.currentPage().getParameters().put('retUrl', '');

    	// Call the constructor
    	CiSearchController ctrl = new CiSearchController();

    	// Try a successful find
    	ctrl.criteria.Name_Contains__c = 'T';
		PageReference outcome = ctrl.find();
		System.assertEquals(1, ctrl.ciAccounts.size());
		System.assertEquals(1, ctrl.ciSites.size());
    	
    	// Try a failed find with all the criteria
    	ctrl.criteria.Name_Contains__c = 'Test';
    	ctrl.criteria.Secondary_Sector__c = 'Aerospace';
    	ctrl.criteria.Sector__c = 'Aerospace';
    	ctrl.criteria.Country__c = 'United Kingdom';
    	ctrl.criteria.Size_Employees__c = 'a. 1 to 25';
    	ctrl.criteria.Spend_Band__c = 'Less than £300';
    	ctrl.criteria.Substream_Logic__c = 'All of...';
    	ctrl.criteria.Substream_s__c = 'Product Certification;System Certification';
    	ctrl.criteria.Family_Logic__c = 'All of...';
    	ctrl.criteria.Families__c = 'ISO 27000;ISO 9000';
		Integer errors = ApexPages.getMessages().size();
		outcome = ctrl.find();		
		System.assertEquals(0, ctrl.ciAccounts.size());
		System.assertEquals(0, ctrl.ciSites.size());
		System.assertEquals(errors + 1, ApexPages.getMessages().size());
		
    	// Try the remaining criteria variations
    	ctrl.criteria.Secondary_Sector__c = '';
    	ctrl.criteria.Substream_Logic__c = 'Any of...';
    	ctrl.criteria.Family_Logic__c = 'Any of...';
		outcome = ctrl.find();
		
		// Try without any criteria
		ctrl = new CiSearchController();
		errors = ApexPages.getMessages().size();
		outcome = ctrl.find();		
		System.assertEquals(errors + 1, ApexPages.getMessages().size());
		
		// Try without any show options
		ctrl.criteria.Show_Accounts__c = false;
		ctrl.criteria.Show_Sites__c = false;
		ctrl.criteria.Show_Endorsements__c = false;
		errors = ApexPages.getMessages().size();
		outcome = ctrl.find();		
		System.assertEquals(errors + 1, ApexPages.getMessages().size());

		// Just for coverage
		ctrl.firstAccount();
		ctrl.lastAccount();
		ctrl.previousAccount();
		ctrl.nextAccount();
		ctrl.firstSite();
		ctrl.lastSite();
		ctrl.previousSite();
		ctrl.nextSite();
		ctrl.firstEndorsement();
		ctrl.lastEndorsement();
		ctrl.previousEndorsement();
		ctrl.nextEndorsement();
		
    	// Stop the processing
    	Test.stopTest();        
    }
}