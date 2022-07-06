/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         22/06/2012
* Description:  TEST CLASS: TerritoryRefreshController
*
* ------------------
* TESTING:		 96%
* BATCH:		100%
* ------------------
*       
**/
@isTest
private class TerritoryRefreshControllerTest {

    static testMethod void refreshTerritory() {
        // Set up data
        Utility.lockcreateHQSite = true;
        Account a = TestData.getTestAccount();
       	a.BillingCountry = 'GB';
       	a.BillingPostalCode = 'EC2 9EX';
       	insert a;
       	System.assertEquals(a.Territory__c,null);
        Territory__c terr = TestData.getTestTerritory('GB','EC2');
        terr.Name = 'Territory';
        insert terr;
        
        // Testing the controller
        TerritoryRefreshController controller = new TerritoryRefreshController(new Apexpages.Standardcontroller(terr));
        Test.startTest();
        controller.refreshAccount();
      	controller.refreshContact();
        controller.refreshLead();
        controller.refreshOpportunity();
        controller.refreshSite();
        controller.getJob();
        
        // Call the Batch process
        TerritoryRefreshBatch refresh = new TerritoryRefreshBatch();
		refresh.query = 'SELECT Id FROM Account WHERE BillingCountry = \'' + terr.Country__c + '\'';
		refresh.objectType = 'Account';
		refresh.territoryName = terr.Name;
		refresh.lastmodified = Date.today() + 2;
		ID batchprocessid = Database.executeBatch(refresh,1);
        Test.stopTest();
        
        // Check that the territory has been updated
        Account acc = [SELECT Territory__c FROM Account WHERE Id =: a.Id];
        System.assertEquals(terr.Id,acc.Territory__c);
    }
}