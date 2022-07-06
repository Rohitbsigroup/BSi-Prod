@isTest
private class EfQuestionnaireTest {

    static testMethod void myUnitTest() {
    	
    	// Create an Account
    	Account acc = new Account(Name = 'Test Account', BillingCountry = 'GB', Phone = '01234 123123', Type = 'Consultant');
    	insert acc;

		// Add the settings
		insert new EfSettings__c( Name = 'Master', Improvement_Slides__c = 'http://www.google.com', Motivations_Dashboard__c = 'http://www.google.com', Playbook_Link__c = 'http://www.google.com');

		// Create a questionnaire
		EfQuestionnaire__c quest = new EfQuestionnaire__c();
        
		// Start the tests
		Test.startTest();

		// Create the edit page
		PageReference editPage = Page.EfQuestionnaireEdit;
		Test.setCurrentPageReference(editPage);

		// Create an instance of the standard controller and the controller extension
		ApexPages.StandardController stdCont = new ApexPages.standardController(quest);
		EfQuestionnaireCtrl extCont = new EfQuestionnaireCtrl(stdCont);

		// Should be a new entry
		System.assertEquals(true, extCont.IsNew);
		
		// Save the new record
		PageReference pr = extCont.CustomSave();
		System.assertEquals(null, pr);
		extCont.Efq.S1_Related_Account__c = acc.Id;
		pr = extCont.CustomSave();
		quest = [SELECT Id, Name FROM EfQuestionnaire__c WHERE Id = :extCont.Efq.Id];

		// Create an instance of the standard controller and the controller extension
		stdCont = new ApexPages.standardController(quest);
		extCont = new EfQuestionnaireCtrl(stdCont);
		
		// Should be an existing entry
		System.assertEquals(false, extCont.IsNew);
		
		// Save the new record
		extCont.CustomSave();
		quest = [SELECT Id, Name FROM EfQuestionnaire__c WHERE Id = :extCont.Efq.Id];
		
		// Create the view page
		PageReference viewPage = Page.EfQuestionnaireView;
		Test.setCurrentPageReference(viewPage);

		// Create an instance of the standard controller and the controller extension
		stdCont = new ApexPages.standardController(quest);
		extCont = new EfQuestionnaireCtrl(stdCont);
		
		// Should be an existing entry
		System.assertEquals(false, extCont.IsNew);

		// Stop the tests
		Test.stopTest();
    }
}