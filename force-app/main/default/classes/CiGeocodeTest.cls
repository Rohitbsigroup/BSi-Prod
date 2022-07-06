@isTest
private class CiGeocodeTest
{
    static testMethod void myUnitTest()
    {
		// Setup test data
		CI_Account__c acc = CiTestUtility.createTestAccount('100');
		CI_Site__c site1 = CiTestUtility.createTestSite(acc, '200');

		// Start the processing
		Test.startTest();

		// Geocode one CI Site
		CiGeocode.Geocode(site1.Id);
		site1 = [SELECT Id, Geocoding__c FROM CI_Site__c WHERE Id = :site1.Id];
		System.assert(site1.Geocoding__c == 'OK');

		// Stop the processing
		Test.stopTest();
    }
}