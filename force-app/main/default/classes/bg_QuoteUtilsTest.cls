/********************************************************************
 * bg_QuoteUtilsTest
 *
 * Test methods for Quote Utility class
 *
 *
 * Author: Richard Jimenez
 * Created: 21-10-2013
 * Changes: 02-10-2014 KM - added testReset methods
 * 			06-05-2015 KM - Added testQuotesSigned and testValidationComplete
 * 			15-01-2016 ASD- Fixed Unit Tests to suit VR rules and WFRs (too many SOQLS)
 *          25-07-2016 JA - Added testSetOfflineSignedQuoteToMainQuote
 *          03-11-2016 ADS- SoW027
 *                        - Fixed Unit Test for new Validation Rules
 *          08-09-2017 RC - added extra unit tests for changes to bg_QuoteUtils, added URL builders methods
 *          18-09-2017 RC - added extra unit test to cover d
 ********************************************************************/
@isTest
public class bg_QuoteUtilsTest {

    private static testMethod void testGetNewQuote() {

            //Test GetNewQuote method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetSiteSettings();
        Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c siteN = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');
        Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
        bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
        bg_UnitTestHelper.GetOpportunitySite(opp, siteN);
        bg_UnitTestHelper.GetOpportunitySite(opp, siteT);
        test.startTest();
            Quote__c quote1 = bg_QuoteUtils.GetNewQuote(acc.Id, opp.Id);
            system.assertNotEquals(null, quote1);
            Quote__c quote2 = bg_QuoteUtils.GetNewQuote(acc.Id, opp);
            system.assertNotEquals(null, quote2);
        test.stopTest();
    }

    private static testMethod void testGetQuoteById() {

            //Test GetQuoteById method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        test.startTest();
            system.assertEquals(quote.Id, bg_QuoteUtils.GetQuoteById(quote.Id).Id);
            system.assertEquals(quote.Id, bg_QuoteUtils.GetQuoteById(quote.Id, true).Id);
        test.stopTest();
    }

    private static testMethod void testGetQuoteQuestionPart() {

            //Test GetQuoteQuestionPart method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);

        Product__c questionProduct = bg_UnitTestHelper.GetQuestionProduct(productName);
        Quote_Product__c questionQuoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, questionProduct);
        Quote_Part__c questionQuotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, questionProduct, 0, true, questionQuoteProduct);

        test.startTest();
            system.assertEquals(questionQuotePart.Id, bg_QuoteUtils.GetQuoteQuestionPart(quote.Id, productName, integer.valueOf(questionQuoteProduct.instance__c)).Id);
        test.stopTest();
    }

    private static testMethod void testGetQuoteProducts() {

            //Test GetQuoteProducts method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        Product__c product = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, null, opp, null);

        test.startTest();
            system.assertEquals(1, bg_QuoteUtils.GetQuoteProducts(quote.Id).size());
            system.assertEquals(1, bg_QuoteUtils.GetQuoteProducts(quote.Id, true).size());
            system.assertEquals(1, bg_QuoteUtils.GetQuoteProducts(quote.Id, true, bg_ProductUtils.PRODUCT_TYPE_MAIN).size());
        test.stopTest();
    }

    private static testMethod void testGetQuoteParts() {

            //Test GetQuoteProducts method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c product = bg_UnitTestHelper.GetProduct(productName);
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
        test.startTest();
            system.assertEquals(1, bg_QuoteUtils.GetQuoteParts(quote.Id).size());
            system.assertEquals(0, bg_QuoteUtils.GetQuoteParts(quote.Id, true).size());
            system.assertEquals(1, bg_QuoteUtils.GetQuoteParts(quote.Id, false, new set<string>{productName}).size());
        test.stopTest();
    }

    private static testMethod void testMissingControllingLocation()
    {
        bg_UnitTestHelper.GetSiteSettings();
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.SetupCountryCurrencySettings();
        string productName = 'ISO 9001';
        Account acc = bg_UnitTestHelper.GetAccount('UT-QUOTEUTILS-ACC');
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 7TY');
        Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-SITE', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 8TY');
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Product__c siteProduct = bg_UnitTestHelper.GetSiteProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();

        // Create Wrappers for Save
        map<string, bg_Wrappers.QuoteProductWrapper> selectedProductsMap = bg_UnitTestHelper.GetQuoteProductWrapperMap(quote, new list<Product__c>{mainProduct}, new list<Site__c>{siteHQ, site});
        bg_Wrappers.QuoteProductWrapper qpw = selectedProductsMap.get(productName);

        test.startTest();
        // Save Quote Products, should get an exception
        try
        {
            bg_QuoteUtils.SaveQuoteProducts(quote, selectedProductsMap);
        }
        catch (Exception ex)
        {
            System.assertEquals(ex.getMessage(), 'A controlling location must be set for each selected product');
        }

        test.stopTest();
    }

    private static testMethod void testSaveQuote() {

            //Test SaveQuote and SaveQuoteProducts method

        bg_UnitTestHelper.GetSiteSettings();
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.SetupCountryCurrencySettings();
        string productName = 'ISO 9001';
        Account acc = bg_UnitTestHelper.GetAccount('UT-QUOTEUTILS-ACC');
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT-HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 7TY');
        Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-SITE', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 8TY');
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Product__c siteProduct = bg_UnitTestHelper.GetSiteProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();

        // Create Wrappers for Save
        map<string, bg_Wrappers.QuoteProductWrapper> selectedProductsMap = bg_UnitTestHelper.GetQuoteProductWrapperMap(quote, new list<Product__c>{mainProduct}, new list<Site__c>{siteHQ, site});
		bg_Wrappers.QuoteProductWrapper qpw = selectedProductsMap.get(productName);
		qpw.controllingLocationId = siteHQ.id;
		System.debug('+++ selectedProductsMap = ' + selectedProductsMap);

        test.startTest();
            // Save Quote
            bg_QuoteUtils.SaveQuote(quote);
            system.assertNotEquals(null, quote.Id);
            // Save Quote with Products
            bg_QuoteUtils.SaveQuote(quote, selectedProductsMap);
            system.assertNotEquals(null, selectedProductsMap.values()[0].SitesMap.values()[0].qpId);
            // Save Quote with Defaults
            bg_QuoteUtils.SaveQuote(quote, true);
            // Save Quote and Products with defaults
            quote.UseLocalPrices__c = true;
            selectedProductsMap.values()[0].SitesMap.values()[0].CurrencyCode = bg_Globals.CURRENCY_CODE_USD;
            bg_QuoteUtils.SaveQuote(quote, selectedProductsMap, true);
            system.assertEquals(bg_Globals.CURRENCY_CODE_USD, selectedProductsMap.values()[0].SitesMap.values()[0].CurrencyCode);
            // Save Quote Products
            bg_QuoteUtils.SaveQuoteProducts(quote, selectedProductsMap);
            bg_QuoteUtils.SaveQuoteProducts(quote, selectedProductsMap, true);
            // Clear registration path
            selectedProductsMap.values()[0].sitesMap.values()[0].RegistrationPath = '';
            bg_QuoteUtils.SaveQuote(quote, selectedProductsMap);
        test.stopTest();
    }

    private static testMethod void testGetSampleQuestionProduct() {

            //Test GetSampleQuestionProduct method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Product__c questionProd = bg_UnitTestHelper.GetQuestionProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        test.startTest();
            system.assertNotEquals(null, bg_QuoteUtils.GetSampleQuestionProduct(productName, quote.Id, true));
            system.assertEquals(null, bg_QuoteUtils.GetSampleQuestionProduct('UT', quote.Id, true));
        test.stopTest();
    }

    private static testMethod void testGetIMSQuestionProduct() {

            //Test GetIMSQuestionProduct method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Product__c imsProd = bg_UnitTestHelper.GetQuestionProduct(bg_ProductUtils.QUESTION_PRODUCT_IMS);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        test.startTest();
            system.assertNotEquals(null, bg_QuoteUtils.GetIMSQuestionProduct(productName, quote.Id, true));
        test.stopTest();
    }

    private static testMethod void testRemoveSamplingQuestionProduct() {

            //Test RemoveSamplingQuestionProduct method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);

        Product__c questionProduct = bg_UnitTestHelper.GetQuestionProduct(productName);
        Product__c product = bg_UnitTestHelper.GetProduct(productName);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, questionProduct, null, opp);
        Quote_Part__c questionQuotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, questionProduct, 0, true, quoteProduct);

        test.startTest();

            quoteProduct = [SELECT Id, Quote_Ref__c, Product_Name__c, Instance__c FROM Quote_Product__c WHERE Id = :quoteProduct.Id];
            system.assertEquals(quote.Id, quoteProduct.Quote_Ref__c);
            system.assertEquals(questionProduct.Id, quoteProduct.Product_Name__c);

            questionQuotePart = [SELECT Id, Quote_Ref__c, Product_Name__c, IsQuestion__c, Quote_Product__c FROM Quote_Part__c WHERE Id = :questionQuotePart.Id];
            system.assertEquals(quote.Id, questionQuotePart.Quote_Ref__c);
            system.assertEquals(productName+bg_ProductUtils.QUESTION_PRODUCT_POSTFIX, questionQuotePart.Product_Name__c);
            system.assertEquals(true, questionQuotePart.IsQuestion__c);
            system.assertEquals(quoteProduct.Id, questionQuotePart.Quote_Product__c);

            bg_QuoteUtils.RemoveSamplingQuestionProduct(productName, quote.Id, integer.valueOf(quoteProduct.instance__c));
        test.stopTest();

        system.debug('RemoveSamplingQuestionProduct: ' + [SELECT Id, Product_Name__c, IsQuestion__c
                        FROM Quote_Part__c
                        WHERE Quote_Ref__c = :quote.Id]);

        // Check Quote product & part are deleted
        system.assertEquals(0, [SELECT Id FROM Quote_Product__c WHERE Id = :quoteProduct.Id].size());
        system.assertEquals(0, [SELECT Id FROM Quote_Part__c WHERE Id = :questionQuotePart.Id].size());
    }

    private static testMethod void testBuildNewQuoteURL() {

        //Test BuildNewQuoteURL method

        string url1 = bg_QuoteUtils.BuildNewQuoteURL('UT_ACCOUNT_ID', 'UT_OPPORTUNITY_ID');
        system.assertEquals(true, url1.contains(bg_QuoteUtils.VF_PAGENAME_NEWQUOTE));
        system.assertEquals(true, url1.contains('UT_ACCOUNT_ID'));
        system.assertEquals(true, url1.contains('UT_OPPORTUNITY_ID'));
        string url2 = bg_QuoteUtils.BuildNewQuoteURL('UT_ACCOUNT_ID', 'UT_OPPORTUNITY_ID','UT_QUOTE_ID');
        system.assertEquals(true, url2.contains(bg_QuoteUtils.VF_PAGENAME_NEWQUOTE));
        system.assertEquals(true, url2.contains('UT_ACCOUNT_ID'));
        system.assertEquals(true, url2.contains('UT_OPPORTUNITY_ID'));
        system.assertEquals(true, url2.contains('UT_QUOTE_ID'));


    }

    private static testMethod void testBuildNewQuoteGridURL() {

            //Test BuildNewQuoteGridURL method

        string url1 = bg_QuoteUtils.BuildNewQuoteGridURL('UT_ACCOUNT_ID', 'UT_OPPORTUNITY_ID', 'UT_QUOTE_ID');
        system.assertEquals(true, url1.contains(bg_QuoteUtils.VF_PAGENAME_NEWQUOTEGRID));
        system.assertEquals(true, url1.contains('UT_ACCOUNT_ID'));
        system.assertEquals(true, url1.contains('UT_OPPORTUNITY_ID'));
        system.assertEquals(true, url1.contains('UT_QUOTE_ID'));

        string url2 = bg_QuoteUtils.BuildNewQuoteGridURL('UT_ACCOUNT_ID', 'UT_OPPORTUNITY_ID', 'UT_QUOTE_ID', false);
        system.assertEquals(true, url2.contains(bg_QuoteUtils.VF_PAGENAME_NEWQUOTEGRID));
        system.assertEquals(true, url2.contains('UT_ACCOUNT_ID'));
        system.assertEquals(true, url2.contains('UT_OPPORTUNITY_ID'));
        system.assertEquals(true, url2.contains('UT_QUOTE_ID'));
        system.assertEquals(true, url2.contains(bg_QuoteUtils.URL_PARAM_MODE));
    }

    /*
    *   Function to test building a url for quoteBuilder vf page
    */
    private static testMethod void testBuildQuoteBuilderURL() 
    {
        string url1 = bg_QuoteUtils.BuildQuoteBuilderURL('UT_ACCOUNT_ID', 'UT_OPPORTUNITY_ID', 'UT_QUOTE_ID');
        system.assertEquals(true, url1.contains(bg_QuoteUtils.VF_PAGENAME_NEWQUOTEGRID));
        system.assertEquals(true, url1.contains('UT_ACCOUNT_ID'));
        system.assertEquals(true, url1.contains('UT_OPPORTUNITY_ID'));
        system.assertEquals(true, url1.contains('UT_QUOTE_ID'));

    }

    private static testMethod void testBuildQuotePartGridURL() 
    {
        string url1 = bg_QuoteUtils.BuildQuotePartGridURL( 'UT_QUOTE_ID');
        system.assertEquals(true, url1.contains(bg_QuoteUtils.VF_PAGENAME_QUOTEPARTGRID));
        system.assertEquals(true, url1.contains('UT_QUOTE_ID'));

        string url2 = bg_QuoteUtils.BuildQuotePartGridURL( 'UT_QUOTE_ID', false);
        system.assertEquals(true, url2.contains(bg_QuoteUtils.VF_PAGENAME_QUOTEPARTGRID));
        system.assertEquals(true, url2.contains('UT_QUOTE_ID'));
        system.assertEquals(true, url2.contains(bg_QuoteUtils.URL_PARAM_MODE));
    }


    private static testMethod void testGetProducts() {

            //Test GetProducts method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c product = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        test.startTest();
            system.assertEquals(product.Id, bg_QuoteUtils.GetProducts(new list<Quote_Product__c>{quoteProduct})[0].Id);
        test.stopTest();
    }

    private static testMethod void testGetMainProducts() {

            //Test GetMainProducts method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Product__c siteProduct = bg_UnitTestHelper.GetSiteProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, siteProduct);
        test.startTest();
            system.assertEquals(mainProduct.Id, bg_QuoteUtils.GetMainProducts(new list<Quote_Product__c>{quoteProduct})[0].Id);
        test.stopTest();
    }

    private static testMethod void testPopulateIMSFields() {

            //Test PopulateIMSFields method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        quote.IMS_Complete__c = true;
        update quote;
        quote.IMS_Complete__c = false;
        test.startTest();
            bg_QuoteUtils.PopulateIMSFields(quote);
            system.assertEquals(true, quote.IMS_Complete__c);
        test.stopTest();
    }

    private static testMethod void testGetMainQuoteId() {
        bg_UnitTestHelper.GetDefaultCountrySetting();

    	Account account1 = bg_UnitTestHelper.GetAccount('Account 1');
    	Opportunity opportunity1 = bg_UnitTestHelper.CreateOpportunity(account1);
    	Opportunity opportunity2 = bg_UnitTestHelper.CreateOpportunity(account1);
    	List<Opportunity> oppsToInsert = new List<Opportunity>();
    	oppsToInsert.add(opportunity1);
    	oppsToInsert.add(opportunity2);
    	insert oppsToInsert;
		Site__c site1 = bg_UnitTestHelper.CreateSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c site2 = bg_UnitTestHelper.CreateSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c site3 = bg_UnitTestHelper.CreateSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');
		List<Site__c> sitesToInsert = new List<Site__c>();
    	sitesToInsert.add(site1);
    	sitesToInsert.add(site2);
    	sitesToInsert.add(site3);
    	insert sitesToInsert;
		OpportunitySite__c opsite1 = bg_UnitTestHelper.CreateOpportunitySite(opportunity1, site1, true);
        OpportunitySite__c opsite2 = bg_UnitTestHelper.CreateOpportunitySite(opportunity1, site2);
		OpportunitySite__c opsite3 = bg_UnitTestHelper.CreateOpportunitySite(opportunity1, site3);
		List<OpportunitySite__c> opSitesToInsert = new List<OpportunitySite__c>();
    	opSitesToInsert.add(opsite1);
    	opSitesToInsert.add(opsite2);
    	opSitesToInsert.add(opsite3);
    	insert opSitesToInsert;
		Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        Product__c mainProduct = bg_UnitTestHelper.GetProduct('ISO 9001');
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct);

        test.startTest();
         	system.assertEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity2.id));
        	system.assertEquals(quote.id, bg_QuoteUtils.GetMainQuoteId(opportunity1.id));
        	quote.Main_Quote__c = false;
        	update quote;
        	system.assertEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity1.id));
        test.stopTest();
    }

	private static testMethod void testCloneQuoteWithSites() {

            //Test CloneQuote method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Account account1 = bg_UnitTestHelper.GetAccount('Test');
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);

        Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
		Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');
        OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		OpportunitySite__c opsite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
		OpportunitySite__c opsite3 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3);

        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct, site1, opportunity1, opsite1);

        test.startTest();
            Quote__c cloneQuote;
    		Map<Id, OpportunitySite__c> oldToNewSites = bg_OpportunitySiteUtils.CloneOpportunitySites(opportunity1.id, opportunity2.id);
			insert oldToNewSites.values();
    		cloneQuote = bg_QuoteUtils.CloneQuote(quote.Id, true, false, opportunity2.Id, oldToNewSites);
    		List<Quote_Product__c> quoteProducts = bg_QuoteUtils.GetQuoteProducts(cloneQuote.id);
    		system.assertEquals(oldToNewSites.get(quoteProduct.Opportunity_Site__c).id, quoteProducts.get(0).Opportunity_Site__c);
    	test.stopTest();
    }

    private static testMethod void testCloneQuote() {

            //Test CloneQuote method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity();
        Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity();
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct);
        test.startTest();
            Quote__c cloneQuote;

            // Clone Quote
            cloneQuote = bg_QuoteUtils.CloneQuote(quote.Id);
            system.assertEquals(cloneQuote.Name, quote.Name);

            // Clone Quote & Quote Product
            cloneQuote = bg_QuoteUtils.CloneQuote(quote.Id, true);
            system.assertEquals(cloneQuote.Name, quote.Name);

            // Clone Quote, Quote Product, Quote Product Approvals
            cloneQuote = bg_QuoteUtils.CloneQuote(quote.Id, true, true);
            system.assertEquals(cloneQuote.Name, quote.Name);

            cloneQuote = bg_QuoteUtils.CloneQuote(quote.Id, true, false, opportunity2.Id);
            system.assertEquals(cloneQuote.Name, quote.Name);
			system.assertEquals(cloneQuote.id, bg_QuoteUtils.GetMainQuoteId(opportunity2.id));
        test.stopTest();
    }

    private static testMethod void testOverrideQuoteStatus() {

            //Test OverrideQuoteStatus method

        QuoteSetting__c cs = bg_CustomSettingsUtils.GetQuoteSettings();
        test.startTest();
            system.assertEquals(true, bg_QuoteUtils.OverrideQuoteStatus(''));
            system.assertEquals(true, bg_QuoteUtils.OverrideQuoteStatus(cs.StatusNA__c));
            system.assertEquals(true, bg_QuoteUtils.OverrideQuoteStatus(cs.StatusDraft__c));
            system.assertEquals(false, bg_QuoteUtils.OverrideQuoteStatus('AnythingElse'));
        test.stopTest();
    }

    private static testMethod void testResetPsProposalFields()
    {
        //Reset the fields related to PsProposal

        bg_UnitTestHelper.GetDefaultCountrySetting();
        Quote__c quote = bg_UnitTestHelper.GetQuote();

        quote.PsProposalDateTimeApproved__c = System.Today();
        quote.PsProposalDateTimeDeclined__c = System.Today();
        quote.PsProposalDateTimeSubmitted__c = System.Today();
        quote.PS_Proposal_Approval_Status__c = bg_CustomSettingsUtils.GetQuoteSettings().StatusDraft__c;  
        test.startTest();
            bg_QuoteUtils.ResetPsProposalApprovalFields(quote);
            System.assertEquals(true, checkResetPsProposalFields(quote));
        test.stopTest();
    }

    public static Boolean checkResetPsProposalFields(Quote__c quote) {

        //Returns true if the PsProposal fields reset correctly

        return  (null == quote.PsProposalDateTimeApproved__c) &&
                (null == quote.PsProposalDateTimeDeclined__c) &&
                (null == quote.PsProposalDateTimeSubmitted__c) &&
                (null == quote.DiscountDateTimeSubmitted__c) &&
                (null == quote.PS_Proposal_Approver__c) &&
                (null == quote.PS_Proposal_Approval_Status__c);
    }



    private static testMethod void testResetValidationFields()
    {
	    	//Reset the fields related to validation

        bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		quote.SkipCustomer__c = true;

		quote.SkippedDate__c = System.Today();
		quote.ValidationStatus__c = bg_CustomSettingsUtils.GetQuoteSettings().StatusWaiting__c;
		test.startTest();
			bg_QuoteUtils.ResetValidationFields(quote);
			System.assertEquals(true, checkResetValidationFields(quote));
		test.stopTest();
    }

    public static Boolean checkResetValidationFields(Quote__c quote){

    		//Returns true if the validation fields reset correctly
    	System.debug((false == quote.ValidationCheck__c));
    	System.debug(null == quote.ValidationDate__c);
    	System.debug(null == quote.ValidatedBy__c);

		return	(bg_CustomSettingsUtils.GetQuoteSettings().StatusDraft__c == quote.ValidationStatus__c) &&
				(false == quote.ValidationCheck__c) &&
				(null == quote.ValidationDate__c) &&
				(null == quote.ValidatedBy__c);
    }


    private static testMethod void testResetSkipCustomerFields() {

    		//Test method for ResetSkipCustomerFields

        bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		quote.SkipCustomer__c = true;
		quote.SkippedDate__c = System.Today();
		quote.ValidationStatus__c = bg_CustomSettingsUtils.GetQuoteSettings().StatusDraft__c;
		test.startTest();
			bg_QuoteUtils.ResetSkipCustomerFields(quote);
            system.assertEquals(true, checkResetSkipCustomerFields(quote));
        test.stopTest();

    }

    public static Boolean checkResetSkipCustomerFields(Quote__c quote){

    		//Returns true if the customer skip fields reset correctly

		return	(false == quote.SkipCustomer__c) &&
				(null == quote.SkippedBy__c) &&
				(null == quote.SkippedDate__c);
    }

    public static testMethod void testResetFinanceFields() {

    		//Test method for ResetFinanceFields

        bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		quote.FinanceStatus__c = 'Declined';
		test.startTest();
            bg_QuoteUtils.ResetQuoteStages(quote);
			system.assertEquals(true, checkResetFinanceFields(quote));
        test.stopTest();
    }

	public static Boolean checkResetFinanceFields(Quote__c quote)
	{
    		//Returns true if finance fields have reset correctly

		return (quote.FinanceStatus__c == null);
	}

    private static testMethod void testResetDiscountFields() {

       		//Test method for Reset Discount fields

        bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		quote.DiscountDateTimeSubmitted__c = System.Today();
		quote.DiscountDateTimeDeclined__c = System.Today();
		test.startTest();
            bg_QuoteUtils.ResetQuoteStages(quote);
			System.assertEquals(true, checkResetDiscountFields(quote));
		test.stopTest();
    }

    public static Boolean checkResetDiscountFields(Quote__c quote) {

    		//Returns true if the discount fields reset correctly

    	return 	(null == quote.ManagerDiscount__c) &&
    			(null == quote.DiscountStatus__c) &&
        		(null == quote.DirectorDiscount__c) &&
	        	(null == quote.DiscountDateTimeSubmitted__c) &&
	        	(null == quote.DiscountDateTimeDeclined__c) &&
	        	(null == quote.DiscountDateTimeApproved__c);
    }

    private static testMethod void testResetTechReviewFields() {

       		//Test method for Reset tech review fields

        bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		quote.SkipTechReview__c = true;
		quote.SkippedTechReviewDate__c = System.Today();
		test.startTest();
            bg_QuoteUtils.ResetQuoteStages(quote);
        	system.assertEquals(false, quote.SkipTechReview__c);
            system.assertEquals(null, quote.SkippedTechReviewBy__c);
            system.assertEquals(null, quote.SkippedTechReviewDate__c);
        test.stopTest();
    }

	public static Boolean checkResetTechReviewFields(Quote__c quote) {

    		//Returns true if the discount fields reset correctly

    	return	(false == quote.SkipTechReview__c) &&
            	(null == quote.SkippedTechReviewBy__c) &&
            	(null == quote.SkippedTechReviewDate__c);
    }

    private static testMethod void testResetProposalSentFields() {

       		//Test method for Reset proposal sent fields

        bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		quote.Proposal_Sent_Date__c = System.Today();
		test.startTest();
            bg_QuoteUtils.ResetQuoteStages(quote);
        	system.assertEquals(null, quote.Proposal_Sent_Date__c);
        test.stopTest();
    }

    public static Boolean checkResetProposalSentFields(Quote__c quote) {

    		//Returns true if the proposal fields reset correctly

    	return	(null == quote.Proposal_Sent_Date__c);
    }

    private static testMethod void testResetQuoteStages() {

       		//Test method for Reset Quote Stages

        bg_UnitTestHelper.GetDefaultCountrySetting();
		Quote__c quote = bg_UnitTestHelper.GetQuote();
		quote.SkipCustomer__c = true;
		quote.DiscountStatus__c = bg_CustomSettingsUtils.GetQuoteSettings().StatusWaiting__c;
		quote.Proposal_Sent_Date__c = System.Today();
		quote.SkippedTechReviewDate__c = System.Today();
		test.startTest();
            bg_QuoteUtils.ResetQuoteStages(quote);
			system.assertEquals(true, checkResetQuoteFields(quote));
        test.stopTest();
    }

    public static Boolean checkResetQuoteFields(Quote__c quote) {

    		//Returns true if the quote reset correctly

    	return	(true == checkResetValidationFields(quote)) &&
    			(true == checkResetSkipCustomerFields(quote)) &&
    			(true == checkResetFinanceFields(quote)) &&
    			(true == checkResetDiscountFields(quote)) &&
    			(true == checkResetTechReviewFields(quote)) &&
    			(true == checkResetProposalSentFields(quote)) &&
    			(true == bg_QuoteApprovalUtilsTest.checkQuoteApprovalFieldsReset(quote));
    }

    private static testMethod void testSkipFactsValidationByCustomer() {

            //Test SkipFactsValidationByCustomer method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        test.startTest();
            bg_QuoteUtils.SkipFactsValidationByCustomer(quote);
            system.assertEquals(true, quote.SkipCustomer__c);
            system.assertNotEquals(null, quote.SkippedDate__c);
            system.assertNotEquals(null, quote.SkippedBy__c);
        test.stopTest();
    }

    private static testMethod void testSkipTechReview() {

            //Test SkipTechReview method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        test.startTest();
            bg_QuoteUtils.SkipTechReview(quote);
            system.assertEquals(true, quote.SkipTechReview__c);
            system.assertNotEquals(null, quote.SkippedTechReviewDate__c);
            system.assertNotEquals(null, quote.SkippedTechReviewBy__c);
        test.stopTest();
    }

    private static testMethod void testQuoteContainsProducts() {

            //Test QuoteContainsProducts method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct);
        test.startTest();
            system.assertEquals(true, bg_QuoteUtils.QuoteContainsProducts(quote.Id, new set<string>{productName}));
        test.stopTest();
    }

    private static testMethod void testIsQuoteMultiCurrency() {

            //Test IsQuoteMultiCurrency method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct);
        test.startTest();
            system.assertEquals(false, bg_QuoteUtils.IsQuoteMultiCurrency(quote.Id));
        test.stopTest();
    }

    private static testMethod void testSetFinanceDirector() {

            //Test SetFinanceDirector method

    }

    private static testMethod void testUpdateQuoteRegPathFlags() {

            //Test UpdateQuoteRegPathFlags method

        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct);
        quoteProduct.Registration_Path__c = 'New Registration';
        update quoteProduct;
        test.startTest();

            quote = [SELECT Id,ProductRegPaths__c,HasNewRegPath__c,HasTransferRegPath__c,HasOtherRegPath__c
                     FROM Quote__c
                     WHERE Id = :quote.Id];
            system.assertEquals('New Registration', quote.ProductRegPaths__c);
            system.assertEquals(True, quote.HasNewRegPath__c);
            system.assertEquals(False, quote.HasTransferRegPath__c);
            system.assertEquals(False, quote.HasOtherRegPath__c);

            Quote_Product__c quoteProduct2 = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct);
            quoteProduct2.Registration_Path__c = 'Other';
            update quoteProduct2;

            quote = [SELECT Id,ProductRegPaths__c,HasNewRegPath__c,HasTransferRegPath__c,HasOtherRegPath__c
                     FROM Quote__c
                     WHERE Id = :quote.Id];
            system.assertEquals('New Registration;Other', quote.ProductRegPaths__c);
            system.assertEquals(True, quote.HasNewRegPath__c);
            system.assertEquals(False, quote.HasTransferRegPath__c);
            system.assertEquals(True, quote.HasOtherRegPath__c);

        test.stopTest();
    }

    private static testMethod void testGetMainQuoteProductNameMap() {

            //Test GetMainQuoteProductNameMap method


        bg_UnitTestHelper.GetDefaultCountrySetting();
        string productName = 'ISO 9001';
        Product__c mainProduct = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct);

        set<Id> quoteIds = new set<Id>{quote.Id};
        test.startTest();
            map<Id, set<string>> mqpnMap = bg_QuoteUtils.GetMainQuoteProductNameMap(quoteIds, true, null);
            system.assertEquals(1, mqpnMap.size());
            system.assertEquals(1, mqpnMap.get(quote.Id).size());
        test.stopTest();
    }

    private static testMethod void testGetBSIMembershipWarning() {

    		// Test GetBSIMembershipWarning

		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_QUOTEUTILS');
		acc.BSIMembershipNo__c = 'ABCDEF123';
		acc.BSIMembershipExpiryDate__c = date.today();
		update acc;

		Site__c site1 = bg_UnitTestHelper.CreateSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
		Site__c site2 = bg_UnitTestHelper.CreateSite(acc, 'UT_SITE_PRICEBOOKUTILS_SITE1', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM3 9AB');
		List<Site__c> sitesToInsert = new List<Site__c>();
		sitesToInsert.add(site1);
		sitesToInsert.add(site2);
		insert sitesToInsert;

		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		OpportunitySite__c opsite1 = bg_UnitTestHelper.CreateOpportunitySite(opp, site1, true);
		OpportunitySite__c opsite2 = bg_UnitTestHelper.CreateOpportunitySite(opp, site2);
		List<OpportunitySite__c> opSitesToInsert = new List<OpportunitySite__c>();
		opSitesToInsert.add(opsite1);
		opSitesToInsert.add(opsite2);
		insert opSitesToInsert;

		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		product.CountriesRequiringBSIMembership__c = bg_SiteUtils.COUNTRY_CODE_US;
		update product;

		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);

		list<Quote_Product__c> quoteProducts = bg_QuoteUtils.GetQuoteProducts(quote.Id, true);
		//list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, bg_SiteUtils.RECORD_TYPE_NAME_NAMED);
		list<Product__c> productList = bg_QuoteUtils.GetMainProducts(quoteProducts);

		//sites = bg_WrapperHelper.CreateSiteWrappers(siteList);
		list<bg_Wrappers.QuoteProductWrapper> products = bg_WrapperHelper.CreateQuoteProductWrappers(productList);
		map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(products);

    	test.startTest();
			system.assertNotEquals(null, bg_QuoteUtils.GetBSIMembershipWarning(opp.Id, acc.Id, quoteProductMap.values()));
		test.stopTest();
    }

	private static testMethod void testQuotesSigned() {
    	// Test QuotesSigned method Without inserts
    	bg_UnitTestHelper.SetupCustomSettings();

		Quote__c quote = bg_UnitTestHelper.GetQuote();
		Quote__c quote2 = bg_UnitTestHelper.GetQuote();
		Quote__c quote3 = bg_UnitTestHelper.GetQuote();
		quote.SkipCustomer__c = true;
        quote2.SkipCustomer__c = true;
        quote2.ValidationCheck__c = false;
        quote3.SkipCustomer__c = true;
        Contact contact = bg_UnitTestHelper.GetContact('Test Contact');

        //SETUP ECHOSIGN AGREEMENTS
		map<Id,echosign_dev1__SIGN_Agreement__c> agreementMap = new map<Id,echosign_dev1__SIGN_Agreement__c>();
		echosign_dev1__SIGN_Agreement__c ag1 = bg_UnitTestHelper.GetEchoSignAgreement(quote.Id);
		echosign_dev1__SIGN_Agreement__c ag2 = bg_UnitTestHelper.GetEchoSignAgreement(quote2.Id);
		echosign_dev1__SIGN_Agreement__c ag3 = bg_UnitTestHelper.GetEchoSignAgreement(quote3.Id);
    	ag1.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
    	ag2.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;
    	ag3.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW;

 		agreementMap.put(quote.Id, ag1);
 		agreementMap.put(quote2.Id, ag2);
 		agreementMap.put(quote3.Id, ag3);

 		map<Id, String> contactNameMap = new map<Id, String>{contact.Id => contact.Name};
 		list<Quote__c> quotes = new list<Quote__c> { quote, quote2 };
 		test.startTest();
 			set<Id> oppIds = bg_QuoteUtils.QuotesSigned(agreementMap, contactNameMap, quotes);
 		test.stopTest();

 		system.assertEquals(1, oppIds.size());
 		system.assertEquals(false, quote3.ValidationCheck__c);
 		system.assertEquals(true, quote.ValidationCheck__c);
 		system.assertEquals(true, quote2.ValidationCheck__c);
    }


    private static testMethod void testQuotesSigned2() {
    	// Test QuoteSigned method with insert
    	bg_UnitTestHelper.SetupCustomSettings();

    	list<Quote__c> quoteList = new list<Quote__c>();
		Quote__c quote1 = bg_UnitTestHelper.GetQuote();
		Quote__c quote2 = bg_UnitTestHelper.GetQuote();
		Quote__c quote3 = bg_UnitTestHelper.GetQuote();
		quote1.SkipCustomer__c = true;
		quote2.SkipCustomer__c = true;
        quote2.ValidationCheck__c = false;
        quote3.SkipCustomer__c = true;
        quoteList.add(quote1);
        quoteList.add(quote2);
        quoteList.add(quote3);
        update quoteList;

        Contact contact = bg_UnitTestHelper.GetContact('Test Contact');

        //SETUP ECHOSIGN AGREEMENTS
		map<Id,echosign_dev1__SIGN_Agreement__c> agreementMap = new map<Id,echosign_dev1__SIGN_Agreement__c>();
		echosign_dev1__SIGN_Agreement__c ag1 = bg_UnitTestHelper.GetEchoSignAgreement(quote1.Id);
		echosign_dev1__SIGN_Agreement__c ag2 = bg_UnitTestHelper.GetEchoSignAgreement(quote2.Id);
		echosign_dev1__SIGN_Agreement__c ag3 = bg_UnitTestHelper.GetEchoSignAgreement(quote3.Id);
    	ag1.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
    	ag2.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;
    	ag3.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW;

 		agreementMap.put(quote1.Id, ag1);
 		agreementMap.put(quote2.Id, ag2);
 		agreementMap.put(quote3.Id, ag3);

 		map<Id, String> contactNameMap = new map<Id, String>{contact.Id => contact.Name};
 		test.startTest();
 			set<Id> oppIds = bg_QuoteUtils.QuotesSigned(agreementMap, contactNameMap);
 		test.stopTest();

 		system.assertEquals(1, oppIds.size());

 		quoteList = [Select Id, ValidationCheck__c FROM Quote__c WHERE Id = : new set<Id> {quote1.Id, quote2.Id, quote3.Id}];
 		for(Quote__c quote : quoteList) {
 			if(quote.Id == quote1.Id) {
 				system.assertEquals(true, quote.ValidationCheck__c);
 			}else if(quote.Id == quote2.Id) {
 				system.assertEquals(true, quote.ValidationCheck__c);
 			}else if(quote.Id == quote3.Id) {
 				system.assertEquals(false, quote.ValidationCheck__c);
 			}
 		}
    }

    private static testMethod void ValidationComplete() {
    	// Test ValidationComplete method
    	final String VALIDATED_BY_STRING = 'Test Contact Name';
    	final String APPROVED_STRING = 'Test Approved';

    	bg_UnitTestHelper.SetupCustomSettings();
    	QuoteSetting__c setting = bg_UnitTestHelper.GetQuoteSettings();
    	setting.StatusApproved__c = APPROVED_STRING;
    	Quote__c quote = bg_UnitTestHelper.CreateQuote();
    	test.startTest();
    		bg_QuoteUtils.ValidationComplete(quote, VALIDATED_BY_STRING, setting);
    	test.stopTest();
    	system.assertEquals(quote.ValidationStatus__c, APPROVED_STRING);
    	system.assertEquals(quote.ValidationCheck__c, true);
    	system.assertEquals(quote.ValidatedBy__c, VALIDATED_BY_STRING);
    }

    private static testMethod void testSetOfflineSignedQuoteToMainQuote()
    {
        bg_UnitTestHelper.SetupCustomSettings();
        List<Quote__c> quotes = new List<Quote__c>();
        Quote__c q1 = bg_UnitTestHelper.CreateQuote();
        quotes.add(q1);
        Quote__c q2 = bg_UnitTestHelper.CreateQuote();
        quotes.add(q2);
        Opportunity opp = bg_UnitTestHelper.CreateOpportunity();
        insert opp;
        quotes.get(0).Opportunity_Name__c = opp.id;
        quotes.get(1).Opportunity_Name__c = opp.id;
        Test.startTest();
        insert quotes;
        System.debug('JA** A : ' + [SELECT Id, Opportunity_Name__c, ProposalSignedOffline__c, Main_Quote__c FROM Quote__c]);
        Quote__c quoteresult = [SELECT Id, Main_Quote__c FROM Quote__c WHERE Main_Quote__c = false LIMIT 1];
        system.assertEquals(false, quoteresult.main_quote__c);
        quoteresult.OperationsReviewStatus__c = bg_QuoteApprovalUtils.APPROVAL_STATUS_APPROVED;
        quoteresult.CongaOfflineDoc__c = true;
        quoteresult.ProposalSignedOffline__c = true;
        update quoteresult;
        List<Quote__c> quoteResultList = new List<Quote__c>();
        quoteResultList.add(quoteResult);
        bg_QuoteUtils.SetOfflineSignedQuoteToMainQuote(quoteResultList,false);
        //System.debug('JA** B : ' + [SELECT Id, Opportunity_Name__c, ProposalSignedOffline__c, Main_Quote__c FROM Quote__c]);
        quoteresult = [SELECT Id, Main_Quote__c FROM Quote__c WHERE Id = :quoteresult.Id];
        system.assertEquals(true, quoteresult.main_quote__c);
        Quote__c otherQuote = [SELECT Id, Main_Quote__c FROM Quote__c WHERE Id != :quoteresult.Id LIMIT 1];
        System.assertEquals(false,otherQuote.main_quote__c);
        Test.stopTest();
    }
    
    private static testMethod void testGetDefaultControllingLocation()
    {
    	bg_UnitTestHelper.SetupCustomSettings();
    	
    	Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
    	
        List<Quote__c> quotes = new List<Quote__c>();
        Quote__c q1 = bg_UnitTestHelper.CreateQuote();
        quotes.add(q1);
        Opportunity opp = bg_UnitTestHelper.CreateOpportunity();
        insert opp;
    	
		ID defaultID = bg_QuoteUtils.GetDefaultControllingLocation(opp);
		System.assertEquals(null, defaultID);
				
		Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);

		// Now have one none default site		
		defaultID = bg_QuoteUtils.GetDefaultControllingLocation(opp);
		System.assertEquals(siteHQ.id, defaultID);
		
		Site__c siteHQ2 = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ2', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AC');
        bg_UnitTestHelper.GetOpportunitySite(opp,siteHQ2, true); 
        
        // Now we have two non default sites so back to null
        defaultID = bg_QuoteUtils.GetDefaultControllingLocation(opp);
        System.assertEquals(null, defaultID);
        
		// add one default site
		//Site__c siteDEF1 = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_DEF1', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_DEFAULT, 'CM2 9AD');
		Site__c siteDEF1 = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_DEF1', bg_SiteUtils.COUNTRY_CODE_US, 'Default', 'CM2 9AD');
        bg_UnitTestHelper.GetOpportunitySite(opp, siteDEF1, true);
		
    	defaultID = bg_QuoteUtils.GetDefaultControllingLocation(opp);
		System.assertEquals(siteDEF1.id, defaultID);
		
		// add a second default site, should go back to null
		//Site__c siteDEF2 = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_DEF1', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_DEFAULT, 'CM2 9AE');
		Site__c siteDEF2 = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_DEF1', bg_SiteUtils.COUNTRY_CODE_US, 'Default', 'CM2 9AE');		
        bg_UnitTestHelper.GetOpportunitySite(opp, siteDEF2, true);
        defaultID = bg_QuoteUtils.GetDefaultControllingLocation(opp); 
		System.assertEquals(null, defaultID);
		
    }
}