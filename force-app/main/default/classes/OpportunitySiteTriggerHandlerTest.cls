/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         25/11/2011
* Description:  TEST CLASS: OpportunitySiteTriggerHandler
*
* ------------------
* TESTING:		 91%
* ------------------
* TRIGGER:		100%
* ------------------      
**/
@isTest
private class OpportunitySiteTriggerHandlerTest {
	
	// Testing adding and deleting site - opportunity
    static testMethod void siteOpty() {
        // Set up data
        Account acc = TestData.getTestAccount();
        insert acc;
        Opportunity opty = TestData.getTestOpty();
        opty.AccountId = acc.Id;
        insert opty;
        
        // Add a new Site
        Site__c s = TestData.getTestSite();
        s.Account__c = acc.Id;
        insert s;
        // Add the site to the opportunity
        OpportunitySite__c os = new OpportunitySite__c();
        os.Site__c = s.Id;
        os.Opportunity__c = opty.Id;
        insert os;
        
        // Check expected results
        Opportunity oadd = [SELECT Id, SiteNumber__c FROM Opportunity WHERE Id =:opty.Id];
        //System.assertEquals(oadd.SiteNumber__c,1);
        
        // Delete the site from opportinity
        delete os;
        Opportunity odel = [SELECT Id, SiteNumber__c FROM Opportunity WHERE Id =:opty.Id];
       //System.assertEquals(odel.SiteNumber__c,0);
    }
}