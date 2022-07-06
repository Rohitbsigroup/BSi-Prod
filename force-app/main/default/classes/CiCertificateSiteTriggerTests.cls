@isTest
private class CiCertificateSiteTriggerTests {

    static testMethod void myUnitTest() {
    	
		// Setup test data
		CI_Account__c acc = CiTestUtility.createTestAccount('100');
		CI_Site__c site = CiTestUtility.createTestSite(acc, '300');
		
		// Start the processing
		Test.startTest();
		
		// Site and Account should be COI Risks
		CI_Certificate__c cert = CiTestUtility.createTestCertificate(acc, '200');		
		CI_Certificate_Site__c mp = CiTestUtility.createTestCertificateSite(cert, site, '600');
		site = [SELECT Id, COI_Count__c, COI_Risk__c FROM CI_Site__c WHERE Id = :site.Id];
		acc = [SELECT Id, COI_Count__c, COI_Risk__c FROM CI_Account__c WHERE Id = :acc.Id];
		System.assertEquals(true, site.COI_Risk__c);
		System.assertEquals(true, acc.COI_Risk__c);
		
		// Delete to complete coverage
		delete mp;
		delete cert;
		site = [SELECT Id, COI_Count__c, COI_Risk__c FROM CI_Site__c WHERE Id = :site.Id];
		acc = [SELECT Id, COI_Count__c, COI_Risk__c FROM CI_Account__c WHERE Id = :acc.Id];
		System.assertEquals(false, site.COI_Risk__c);
		System.assertEquals(false, acc.COI_Risk__c);
		
		// Stop the processing
		Test.stopTest();
    }
}