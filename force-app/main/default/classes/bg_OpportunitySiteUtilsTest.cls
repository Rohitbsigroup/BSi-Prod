/********************************************************************
 * bg_OpportunitySiteUtilsTest
 *
 * Methods to support UpdateQuote HQ test
 * 
 * 
 * Author:  Michael Holt
 * Created: 01-08-2014
 * Changes: 
 *	11-11-2014	KM	Added testCloneOpportunitySites
 *	CPE 04/09/2017	New testmethods for getOpportunitySite, getOpportunitySites,
 *					getOpportunitySiteMapById and getOpportunitySiteMapByOppId  
 * CPE 05/09/2017	Removal of test for UpdateQuoteHQSite method as no longer utilised
 * CPE 14/09/2017	New tests for verifyDeletionOfOpportunitySites & deleteRelatedQuoteProducts methods
 ********************************************************************/
@isTest
public with sharing class bg_OpportunitySiteUtilsTest {
	
	public static testMethod void testCloneOpportunitySites() {
		// Test method for CloneOpportunitySites
		
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
		Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
		
		OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		OpportunitySite__c opsite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
		OpportunitySite__c opsite3 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3); 	
		
		test.startTest();
			system.assertEquals(4, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity1.id).size());
			system.assertEquals(1, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id).size());
			insert bg_OpportunitySiteUtils.CloneOpportunitySites(opportunity1.id, opportunity2.id).values();
			system.assertEquals(4, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity1.id).size());
			system.assertEquals(5, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id).size());
		test.stopTest();
	}

	/*
		Test for getOpportunitySiteMapById
		Empty results
	*/
	static testMethod void testgetOpportunitySiteMapByIdNoSites()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);
		
		Map<Id, OpportunitySite__c> results;
		Set<Id> siteIds = new Set<Id>();
		results = bg_OpportunitySiteUtils.getOpportunitySiteMapById(siteIds);

		system.assertEquals(true, results != null);
		system.assertEquals(true, results.isEmpty());
	}


	/*
		Test for getOpportunitySiteMapById
		Single Site
	*/
	static testMethod void testgetOpportunitySiteMapByIdSingleSite()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);

		OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		
		Map<Id, OpportunitySite__c> results;
		Set<Id> siteIds = new Set<Id>();
		siteIds.add(opsite1.Id);

		results = bg_OpportunitySiteUtils.getOpportunitySiteMapById(siteIds);

		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(1, results.size());
		system.assertEquals(true, results.containsKey(opsite1.Id));
		system.assertEquals(opsite1.Id, results.get(opsite1.Id).Id);
		system.assertEquals(site1.Id, results.get(opsite1.Id).Site__c);
	}


	/*
		Test for getOpportunitySiteMapById
		Multiple Sites
	*/
	static testMethod void testgetOpportunitySiteMapByIdMultiSite()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);

		OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		OpportunitySite__c opsite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
		OpportunitySite__c opsite3 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3);
		
		Map<Id, OpportunitySite__c> results;
		Set<Id> siteIds = new Set<Id>();
		siteIds.add(opsite1.Id);
		siteIds.add(opsite2.Id);
		siteIds.add(opsite3.Id);

		results = bg_OpportunitySiteUtils.getOpportunitySiteMapById(siteIds);

		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(3, results.size());
		system.assertEquals(true, results.containsKey(opsite1.Id));
		system.assertEquals(opsite1.Id, results.get(opsite1.Id).Id);
		system.assertEquals(site1.Id, results.get(opsite1.Id).Site__c);
		system.assertEquals(true, results.containsKey(opsite2.Id));
		system.assertEquals(opsite2.Id, results.get(opsite2.Id).Id);
		system.assertEquals(site2.Id, results.get(opsite2.Id).Site__c);
		system.assertEquals(true, results.containsKey(opsite3.Id));
		system.assertEquals(opsite3.Id, results.get(opsite3.Id).Id);
		system.assertEquals(site3.ID, results.get(opsite3.Id).Site__c);
	}


	/*
		Test for getOpportunitySites
		Empty results
	*/
	static testMethod void testgetOpportunitySitesNoSites()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);
		
		List<OpportunitySite__c> results;
		Set<Id> siteIds = new Set<Id>();
		results = bg_OpportunitySiteUtils.getOpportunitySites(siteIds);

		system.assertEquals(true, results != null);
		system.assertEquals(true, results.isEmpty());
	}

	/*
		Test for getOpportunitySites
		Multiple Sites
	*/
	static testMethod void testgetOpportunitySitesMultiSite()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);

		OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		OpportunitySite__c opsite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
		OpportunitySite__c opsite3 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3);
		
		List<OpportunitySite__c> results;
		Set<Id> siteIds = new Set<Id>();
		siteIds.add(opsite1.Id);
		siteIds.add(opsite2.Id);
		siteIds.add(opsite3.Id);

		results = bg_OpportunitySiteUtils.getOpportunitySites(siteIds);

		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(3, results.size());
		Boolean site1Found = false;
		Boolean site2Found = false;
		Boolean site3Found = false;
		for (OpportunitySite__c oppSite : results)
		{
			if ((oppSite.Id == opsite1.id) &&
				(oppSite.Site__c == site1.Id))
			{
				site1Found = true;
			}
			if ((oppSite.Id == opsite2.id) &&
				(oppSite.Site__c == site2.Id))
			{
				site2Found = true;
			}
			if ((oppSite.Id == opsite3.id) &&
				(oppSite.Site__c == site3.Id))
			{
				site3Found = true;
			}
		}
		system.assert(site1Found);
		system.assert(site2Found);
		system.assert(site3Found);
	}



	/*
		Test for getOpportunitySite
		Empty results
	*/
	static testMethod void testgetOpportunitySiteNoSites()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);
		
		OpportunitySite__c result;
		Id siteId;
		result = bg_OpportunitySiteUtils.getOpportunitySite(siteId);

		system.assertEquals(true, result == null);
	}

	/*
		Test for getOpportunitySite
		Single Site Id - multi sites on Opp
	*/
	static testMethod void testgetOpportunitySiteSingle()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);

		OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		OpportunitySite__c opsite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
		OpportunitySite__c opsite3 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3);
		
		OpportunitySite__c result;

		result = bg_OpportunitySiteUtils.getOpportunitySite(opsite1.Id);

		system.assertEquals(true, result != null);
		system.assertEquals(opsite1.Id, result.Id);
		system.assertEquals(site1.Id, result.Site__c);
	}





	/*
		Test for getOpportunitySiteMapByOppId
		Default Sites Only
		Process Builders are inplace to automatically create a default site on Account creation and
		not link to Opportunity on Opportunity creation
		
	*/
	static testMethod void testgetOpportunitySiteMapByOppIdNoSites()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);
		
		Map<Id, List<OpportunitySite__c>> results;
		Set<Id> oppIds = new Set<Id>();
		oppIds.add(opportunity1.Id);
		oppIds.add(opportunity2.Id);

		results = bg_OpportunitySiteUtils.getOpportunitySiteMapByOppId(oppIds);

		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(2, results.size());
		system.assertEquals(true, results.containsKey(opportunity1.Id));
		system.assertEquals(false, results.get(opportunity1.Id).isEmpty());
		system.assertEquals(1, results.get(opportunity1.Id).size());
		system.assertEquals(true, results.containsKey(opportunity2.Id));
		system.assertEquals(false, results.get(opportunity2.Id).isEmpty());
		system.assertEquals(1, results.get(opportunity2.Id).size());
	}


	/*
		Test for getOpportunitySiteMapByOppId
		Multi Sites - including the defaults created by PBs
	*/
	static testMethod void testgetOpportunitySiteMapByOppIdMultiSites()
	{
		bg_UnitTestHelper.GetSiteSettings();    	
		
		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_TEST');
		Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_OPP_SITE_TEST_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');		
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
		
		Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact Opp Site', account1);

		OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		OpportunitySite__c opsite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
		OpportunitySite__c opsite3 = bg_UnitTestHelper.GetOpportunitySite(opportunity2, site3, true);
		
		Map<Id, List<OpportunitySite__c>> results;
		Set<Id> oppIds = new Set<Id>();
		oppIds.add(opportunity1.Id);
		oppIds.add(opportunity2.Id);

		results = bg_OpportunitySiteUtils.getOpportunitySiteMapByOppId(oppIds);

		system.assertEquals(true, results != null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(2, results.size());
		system.assertEquals(true, results.containsKey(opportunity1.Id));
		system.assertEquals(false, results.get(opportunity1.Id).isEmpty());
		system.assertEquals(3, results.get(opportunity1.Id).size());
		system.assertEquals(true, results.containsKey(opportunity2.Id));
		system.assertEquals(false, results.get(opportunity2.Id).isEmpty());
		system.assertEquals(2, results.get(opportunity2.Id).size());
	}

	/*
		Test for verifyDeletionOfOpportunitySites
		Null sitemap parameter
	*/
	static testMethod void testverifyDeletionOfOpportunitySitesNull()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = true;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END

		Map<Id, OpportunitySite__c> results;
		Map<Id, OpportunitySite__c> optySiteMap;
		
		results =  bg_OpportunitySiteUtils.verifyDeletionOfOpportunitySites(null);
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());
	}


	/*
		Test for verifyDeletionOfOpportunitySites
		Empty sitemap parameter
	*/
	static testMethod void testverifyDeletionOfOpportunitySitesEmpty()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = true;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END

		Map<Id, OpportunitySite__c> results;
		Map<Id, OpportunitySite__c> optySiteMap = new Map<Id, OpportunitySite__c>();
		
		results =  bg_OpportunitySiteUtils.verifyDeletionOfOpportunitySites(optySiteMap);
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());
	}

	/*
		Test for verifyDeletionOfOpportunitySites
		Single sitemap parameter for configured product
	*/
	static testMethod void testverifyDeletionOfOpportunitySitesSingleConfigured()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = true;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END

		Map<Id, OpportunitySite__c> results;
		Map<Id, OpportunitySite__c> optySiteMap = new Map<Id, OpportunitySite__c>();
		OpportunitySite__c oppSiteToTest = testOppSites[0];
		
		PageReference testPage = Page.AddSiteToQuote;
		Test.setCurrentPage(testPage);
		
		optySiteMap.put(oppSiteToTest.Id, oppSiteToTest);
		results =  bg_OpportunitySiteUtils.verifyDeletionOfOpportunitySites(optySiteMap);
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());
		system.assertEquals(true, ApexPages.hasMessages());
	}

	/*
		Test for verifyDeletionOfOpportunitySites
		Multi sitemap parameter for configured product
	*/
	static testMethod void testverifyDeletionOfOpportunitySitesMultiConfigured()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = true;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END

		Map<Id, OpportunitySite__c> results;
		Map<Id, OpportunitySite__c> optySiteMap = new Map<Id, OpportunitySite__c>();
		
		PageReference testPage = Page.AddSiteToQuote;
		Test.setCurrentPage(testPage);
		
		optySiteMap.putAll(testOppSites);
		results =  bg_OpportunitySiteUtils.verifyDeletionOfOpportunitySites(optySiteMap);
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());
		system.assertEquals(true, ApexPages.hasMessages());
	}	

	/*
		Test for verifyDeletionOfOpportunitySites
		Single sitemap parameter for non configured product
	*/
	static testMethod void testverifyDeletionOfOpportunitySitesSingleNotConfigured()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = false;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END

		Map<Id, OpportunitySite__c> results;
		Map<Id, OpportunitySite__c> optySiteMap = new Map<Id, OpportunitySite__c>();
		OpportunitySite__c oppSiteToTest = testOppSites[0];
		
		PageReference testPage = Page.AddSiteToQuote;
		Test.setCurrentPage(testPage);
		
		optySiteMap.put(oppSiteToTest.Id, oppSiteToTest);
		results =  bg_OpportunitySiteUtils.verifyDeletionOfOpportunitySites(optySiteMap);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(1, results.size());
		system.assertEquals(true, results.containsKey(oppSiteToTest.Id));
		system.assertEquals(false, ApexPages.hasMessages());
	}

	/*
		Test for verifyDeletionOfOpportunitySites
		Multi sitemap parameter for non configured product
	*/
	static testMethod void testverifyDeletionOfOpportunitySitesMultiNotConfigured()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = false;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END

		Map<Id, OpportunitySite__c> results;
		Map<Id, OpportunitySite__c> optySiteMap = new Map<Id, OpportunitySite__c>();
		
		PageReference testPage = Page.AddSiteToQuote;
		Test.setCurrentPage(testPage);
		
		optySiteMap.putAll(testOppSites);
		results =  bg_OpportunitySiteUtils.verifyDeletionOfOpportunitySites(optySiteMap);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(testOppSites.size(), results.size());
		for (OpportunitySite__c oppSite : testOppSites)
		{
			system.assertEquals(true, results.containsKey(oppSite.Id));
		}
		system.assertEquals(false, ApexPages.hasMessages());
	}	


	/*
		Test for verifyDeletionOfOpportunitySites
		Multi sitemap parameter for mixed configured product
	*/
	static testMethod void testverifyDeletionOfOpportunitySitesMultiMixedConfigured()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		Boolean configuredProduct = false;
		List<OpportunitySite__c> nonConfigured = new List<OpportunitySite__c>();
		 
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = configuredProduct;
			if (!configuredProduct)
			{
				nonConfigured.add(testOppSite);
			}
			testQuoteProducts.add(testQuoteProduct);
			configuredProduct = !configuredProduct;
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END

		Map<Id, OpportunitySite__c> results;
		Map<Id, OpportunitySite__c> optySiteMap = new Map<Id, OpportunitySite__c>();
		
		PageReference testPage = Page.AddSiteToQuote;
		Test.setCurrentPage(testPage);
		
		optySiteMap.putAll(testOppSites);
		results =  bg_OpportunitySiteUtils.verifyDeletionOfOpportunitySites(optySiteMap);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(nonConfigured.size(), results.size());
		for (OpportunitySite__c oppSite : nonConfigured)
		{
			system.assertEquals(true, results.containsKey(oppSite.Id));
		}
		system.assertEquals(true, ApexPages.hasMessages());
	}	


	/*
		public static void deleteRelatedQuoteProducts(Set<Id> deletedOptySiteIds)
	*/
	
	/*
		Test for deleteRelatedQuoteProducts
		Null parameter
	*/
	static testMethod void testdeleteRelatedQuoteProductsNull()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = false;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END		
		
		List<Quote_Product__c> results;
		Map<Id, OpportunitySite__c> oppSiteMap = new Map<Id, OpportunitySite__c>();
		oppSiteMap.putAll(testOppSites);
		
		bg_OpportunitySiteUtils.deleteRelatedQuoteProducts(null);
		 
		results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteMap.keySet());
		Map<Id, Quote_Product__c> expectedQuoteProducts = new Map<Id, Quote_Product__c>();
		expectedQuoteProducts.putAll(results);

		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		for (Quote_Product__c quoteProduct : testQuoteProducts)
		{
			system.assertEquals(true, expectedQuoteProducts.containsKey(quoteProduct.Id));
		}
	}

	/*
		Test for deleteRelatedQuoteProducts
		Empty parameter
	*/
	static testMethod void testdeleteRelatedQuoteProductsEmpty()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = false;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END		
		
		List<Quote_Product__c> results;
		Map<Id, OpportunitySite__c> oppSiteMap = new Map<Id, OpportunitySite__c>();
		oppSiteMap.putAll(testOppSites);
		Set<Id> forDelete = new Set<Id>();
		
		bg_OpportunitySiteUtils.deleteRelatedQuoteProducts(forDelete);
		 
		results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteMap.keySet());
		Map<Id, Quote_Product__c> expectedQuoteProducts = new Map<Id, Quote_Product__c>();
		expectedQuoteProducts.putAll(results);

		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(testQuoteProducts.size(), results.size());
		for (Quote_Product__c quoteProduct : testQuoteProducts)
		{
			system.assertEquals(true, expectedQuoteProducts.containsKey(quoteProduct.Id));
		}
	}
	
	/*
		Test for deleteRelatedQuoteProducts
		Single parameter
	*/
	static testMethod void testdeleteRelatedQuoteProductsSingle()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = false;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END		
		
		List<Quote_Product__c> results;
		Map<Id, OpportunitySite__c> oppSiteMap = new Map<Id, OpportunitySite__c>();
		oppSiteMap.putAll(testOppSites);
		Set<Id> forDelete = new Set<Id>();
		Id testSiteId = testOppSites[0].Id;
		forDelete.add(testSiteId);

		bg_OpportunitySiteUtils.deleteRelatedQuoteProducts(forDelete);
		 
		results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteMap.keySet());
		Map<Id, Quote_Product__c> expectedQuoteProducts = new Map<Id, Quote_Product__c>();
		expectedQuoteProducts.putAll(results);

		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(testQuoteProducts.size() -1 , results.size());
		for (Quote_Product__c quoteProduct : testQuoteProducts)
		{
			if (quoteProduct.Opportunity_Site__c == testSiteId)
			{
					system.assertEquals(false, expectedQuoteProducts.containsKey(quoteProduct.Id));
			}
			else
			{
				system.assertEquals(true, expectedQuoteProducts.containsKey(quoteProduct.Id));
			}
		}
	}
	
	/*
		Test for deleteRelatedQuoteProducts
		Multiple parameter
	*/
	static testMethod void testdeleteRelatedQuoteProductsMultiple()
	{
		// SETUP TEST DATA - START
		List<Product__c> testProducts = new List<Product__c>();
		List<Site__c> testSites = new List<Site__c>();
		Account testAccount;
		Contact testContact;
		Opportunity testOpportunity;
		List<OpportunitySite__c> testOppSites = new List<OpportunitySite__c>();
		Quote__c testQuote;
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		
		Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
		Integer recordCount = 5;
		
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
		Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-ASSURANCE-PRODUCT', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
		insert testProduct;
		
		testAccount = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_OPP_SITE_UTILS_TEST');
		
		for (Integer iterator=0; iterator<recordCount; iterator++)
		{
			
			Site__c testSite = bg_UnitTestHelper.CreateSite(testAccount, 'UT_SITE_CONFIG_QUOTE_PROD_TEST-' + iterator, 
															bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 ' + iterator + 'AB'); 
			testSites.add(testSite);
		}
		insert testSites;
		
		testOpportunity = bg_UnitTestHelper.GetOpportunity(testAccount);
		
		testContact = bg_UnitTestHelper.GetContact('Test Contact Opp Site', testAccount);

		for (Site__c testSite : testSites)
		{
			OpportunitySite__c testOppSite = bg_UnitTestHelper.CreateOpportunitySite(testOpportunity, testSite, testSite.Id == testSites[0].Id);
			testOppSites.add(testOppSite);
		}
		insert testOppSites;

		testQuote = bg_UnitTestHelper.GetQuote(testOpportunity, testContact);

 		List<Quote_Product__c> testQuoteProducts = new List<Quote_Product__c>();

		
		for (Integer iterator=0; iterator<testSites.size(); iterator++)
		{
			Site__c testSite = testSites[iterator];
			OpportunitySite__c testOppSite = testOppSites[iterator];
			Quote_Product__c testQuoteProduct = bg_UnitTestHelper.CreateQuoteProduct(testQuote, testContact, testProduct, testSite, testOpportunity, testOppSite);
			testQuoteProduct.Configuration_Complete__c = false;
			testQuoteProducts.add(testQuoteProduct);
		}
		insert testQuoteProducts;		
		// SETUP TEST DATA - END		
		
		List<Quote_Product__c> results;
		Map<Id, OpportunitySite__c> oppSiteMap = new Map<Id, OpportunitySite__c>();
		oppSiteMap.putAll(testOppSites);
		Set<Id> forDelete = new Set<Id>();
		forDelete.addAll(oppSiteMap.keySet());
		
		bg_OpportunitySiteUtils.deleteRelatedQuoteProducts(forDelete);
		 
		results = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(oppSiteMap.keySet());
		Map<Id, Quote_Product__c> expectedQuoteProducts = new Map<Id, Quote_Product__c>();
		expectedQuoteProducts.putAll(results);

		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());
	}


}