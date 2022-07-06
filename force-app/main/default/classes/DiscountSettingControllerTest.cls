/**
*
* Author:       Radoslava Radkova
* Reviewer:		Carmine Barbuto
* Company:		Tquila
* Date:         29/11/2012
* Description:  TEST CLASS: DiscountSettingController
*
* ------------------
* TESTING:		 100%
* ------------------
*          RJ 01-06-2014 Updated to use getTestSalesUser
*        
**/
@isTest
private class DiscountSettingControllerTest {
	
	static testMethod void disocuntSettingTest() {
		
		bg_UnitTestHelper.GetGlobalPricebook();
				
		User testuser = TestData.getTestSalesUser();
		testUser.OperationCountry__c = 'GB';
    	insert testuser;
		
		ConversionScore__c score = new ConversionScore__c();
       	score.Name = testUser.OperationCountry__c;
       	score.CountrySalesAdminEmail__c = 'test@test.com';
    	score.DiscountLevel1__c = 0.2;
    	score.DiscountLevel2__c = 0.5;
    	score.DiscountLevel3__c = 0.7;
    	score.DiscountLevel4__c = 0.9;
		score.DiscountLevel1User1__c = testuser.id;
		score.DiscountLevel2User1__c = testuser.id;
		score.DiscountLevel3User1__c = testuser.id;
		score.DiscountLevel4User1__c = testuser.id;
		score.DiscountLevel4User2__c = testuser.id;
    	insert score;
		
		SiteSetting__c s = new SiteSetting__c();
		s.HQLabel__c = 'HQ';
		insert s;
		
		Account acc = TestData.getTestAccount();
        acc.BillingCountry = testUser.OperationCountry__c;
    	insert acc;
    	
    	Contact con = TestData.getTestContact();
    	con.AccountId = acc.Id;
    	insert con;
    	
    	Opportunity opp = TestData.getTestOpty();
    	opp.OwnerId = testUser.Id; 
    	opp.AccountId = acc.Id;
    	insert opp;
    	
    	// Query for the HQ Auto created and link it to the opportunity
		Site__c hq = [SELECT Name FROM Site__c WHERE Account__c =:acc.Id AND Type__c =:s.HQLabel__c];
		OpportunitySite__c osite = new OpportunitySite__c();
		osite.HQ__c = true;
		osite.Opportunity__c = opp.Id;
		osite.Site__c = hq.Id;
		insert osite;
    	
    	Quote__c quote = TestData.getTestQuote(opp.Id, con.Id, acc.Id);
       	insert quote;
    	
    	Test.setCurrentPage(Page.DiscountSetting);
    	ApexPages.currentPage().getParameters().put('country', acc.BillingCountry);
    	ApexPages.currentPage().getParameters().put('quoteId', quote.Id);
    	
    	DiscountSettingController controller = new DiscountSettingController();
    	controller.score.DiscountLevel3__c = 1;
    	controller.saveAll();
    	system.assertEquals(ConversionScore__c.getInstance(acc.BillingCountry).DiscountLevel3__c, 1);
    	system.assertEquals(controller.Cancel().getURL(), '/' + quote.Id);
    	
		
	}
}