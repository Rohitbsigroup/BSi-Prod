/********************************************************************
 * bg_SiteUtilsTest
 *
 * Test methods for Site Utility class
 * 
 * 
 * Author: Richard Jimenez
 * Created: 17-10-2013
 * Changes: 
 *			04-08-2017 - RC - changed the opportunity site hq check as process builder creates the opportunity site now
 *			08-09-2017 - RC - added extra assert to cover new GetOpportunitySite overload
 ********************************************************************/
@isTest
private class bg_SiteUtilsTest {

	private static testMethod void testBuildManageOpportunitySitesURL() {
		/*
			Test BuildManageOpportunitySitesURL Method
		*/
		string oppId = 'UT-OPPID';
		string retUrl = 'UT-RETURL';
		test.startTest();
			string url = bg_SiteUtils.BuildManageOpportunitySitesURL(oppId, retUrl);
		test.stopTest();
		system.assertEquals(true, url.contains(oppId));
		system.assertEquals(true, url.contains(retUrl));
	}
	
	private static testMethod void testGetAccountSites() {
		/*
			Test GetAccountSites and GetAccountSitesMap Method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_SITEUTILS');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_SITEUTILS', bg_SiteUtils.COUNTRY_CODE_US);		
		test.startTest();
			system.assertEquals(2, bg_SiteUtils.GetAccountSites(acc.Id).size());
			system.assertEquals(2, bg_SiteUtils.GetAccountSitesMap(acc.Id).size());			
		test.stopTest();
	}


	

	private static testMethod void testGetOpportunitySites() {
		/*
			Test GetOpportunitySites Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_SITEUTILS');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_SITEUTILS', bg_SiteUtils.COUNTRY_CODE_US);		
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, site, true); 

		test.startTest();
			system.assertEquals(2, bg_SiteUtils.GetOpportunitySites(opp.Id).size());
			system.assertEquals(1, bg_SiteUtils.GetOpportunitySites(opp.Id, bg_SiteUtils.RECORD_TYPE_NAME_NAMED).size());
			system.assertEquals(1, bg_SiteUtils.GetOpportunitySites(opp.Id, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, true).size());	
			system.assertEquals(2, bg_SiteUtils.GetOpportunitySites(opp.Id, bg_SiteUtils.RECORD_TYPE_NAME_NAMED,  bg_SiteUtils.RECORD_TYPE_NAME_DEFAULT).size());	
		test.stopTest();
	}

	private static testMethod void testGetOpportunitySiteCountries() {
		/*
			Test GetOpportunitySiteCountries Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_SITEUTILS');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_SITEUTILS', bg_SiteUtils.COUNTRY_CODE_US);		
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, site, true); 
		
		test.startTest();
			system.assertEquals(true, bg_SiteUtils.GetOpportunitySiteCountries(new list<OpportunitySite__c>{oppSite}).contains(bg_SiteUtils.COUNTRY_CODE_US));
		test.stopTest();
	}
	
	private static testMethod void testGetOpportunityHQSite() {
		/*
			Test GetOpportunityHQSite Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_SITEUTILS');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_SITEUTILS', bg_SiteUtils.COUNTRY_CODE_US);		
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		
		test.startTest();
			//query the opp site that has been created by process builder
			OpportunitySite__c oppSite = [Select id from OpportunitySite__c];		
			system.assertEquals(oppSite.Id, bg_SiteUtils.GetOpportunityHQSite(opp.Id).Id);
		test.stopTest();
	}
}