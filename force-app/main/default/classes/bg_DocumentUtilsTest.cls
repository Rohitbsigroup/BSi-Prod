/**
 * bg_DocumentUtils
 *
 * Utility methods to support Conga Mail Merge and EchoSoft document integration
 * 
 * 
 * Author: Antony Daley
 * Created: 02-09-2013
 * Changes: 
 * 06-06-2015 KM BG - 	Added methods for testHandleQuotesOutForSignature and testHandleQuotesSigned
 *						modified testUpdateQuoteAgreementStatus
 * 01-08-2015 RJ BG -	Remove some lines in the getDocumentUrlTest that were no longer needed for the test and were making the quota to fail 
 * 
 * 24-05-2017 RC BG -   Add start/stop test into  getDocumentUrlTest method                      
 */
@isTest
private class bg_DocumentUtilsTest 
{

    static testMethod void getDocumentUrlTest()
    {
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetSiteSettings();        
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c siteHQ = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c siteN = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c siteT = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');      
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteHQ, true);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteN);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteT);      
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        contact1.email = 'test654@test.com';
        update contact1;
        
        Contact contact2 = bg_UnitTestHelper.GetContact('Test Contact2', account1);
        contact2.email = 'test789@test.com';
        update contact2;
        
        Contact contact3 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        contact3.email = 'test910@test.com';
        update contact3;
        
        Quote__c quote = new Quote__c();
        
        quote.Account__c = account1.Id;
        quote.Contact__c = contact1.Id;
        quote.Opportunity_Name__c = opportunity1.Id;
        insert quote;
        
        SystemSetting__c ss = new SystemSetting__c();
        ss.ServerURL__c = 'https://bsi--dev.cs8.my.salesforce.com/';
        ss.CongaUpgradeURL__c = 'someurl';
        ss.Conga_Server_URL__c = 'someurl';
        insert ss;
        
        CongaQueryIds__c cstSet = new CongaQueryIds__c();
        cstSet.Name = 'Fail';
        insert cstSet;
        
        try
        {
            string URL5 = bg_DocumentUtils.GetDocumentUrl(quote.Id, '123', bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, false, true, false); 
        }catch(Exception de)
        {
            system.assertEquals(true, de != null);
        }
        
        cstSet.Name = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
        cstSet.QueryId1__c = '123';
        cstSet.Alias1__c = 'al';
        update cstSet;
        
        Test.startTest();
        //String URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, 'EN', false);
        
        list<String>templateIds = new list<String>();
        String URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, false, true, false);
        
        system.debug(logginglevel.error, 'ASD### quote url ' + URL2);
        system.assertEquals(true,URL2.contains('someurl'));
        system.assertEquals(false,URL2.contains('null'));
        system.assertEquals(false,URL2.contains('&DS7=4'));
        system.assertEquals(false,URL2.contains('&DS7=14'));
        system.assertEquals(false,URL2.contains('&TemplateId='));
//        system.assertEquals(true,URL2.contains('&queryId=[al]123'));
        
        List<Id>recipientContactIds = new List<Id>();
        recipientContactIds.add(contact1.id);
        List<String>copyToAddresses = new List<String>();
        copyToAddresses.add(Contact1.email);
        copyToAddresses.add(Contact2.email);
        copyToAddresses.add(Contact3.email);
        
        string URL3 = bg_DocumentUtils.GetDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, recipientContactIds, false, true, false);
            
        system.assertEquals(false,URL3.contains('null'));
        system.assertEquals(false,URL3.contains('&DS7=4'));
        system.assertEquals(false,URL3.contains('&DS7=14'));
        system.assertEquals(false,URL3.contains('&TemplateId='));
//        system.assertEquals(true,URL3.contains('&queryId=[al]123'));
        system.assertEquals(true,URL3.contains('&ESContactId=' + contact1.Id));
        
        //string URL4 = bg_DocumentUtils.GetDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, recipientContactIds, copyToAddresses, false, true, false);
        //string URL41 = bg_DocumentUtils.GetDocumentUrl(quote.Id, 'templateId', bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, recipientContactIds, copyToAddresses, false, true, false);
        string URL4 = bg_DocumentUtils.GetDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, recipientContactIds, copyToAddresses, false, true, false, true);
        string URL41 = bg_DocumentUtils.GetDocumentUrl(quote.Id, 'templateId', bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, recipientContactIds, copyToAddresses, false, true, false);
        //string URL3 = bg_DocumentUtils.getDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, recipientContactIds, false, true, false) ;
        String comapreString1 = '&ESContactId=' + contact1.Id;
        String comapreString2 = '&ESCopyTo=' + contact1.email;
        system.assertEquals(true,URL4.contains(comapreString1));
        system.assertEquals(true,URL4.contains(comapreString2));
        system.assertEquals(true,URL41.contains(comapreString1));
        system.assertEquals(true,URL41.contains(comapreString2));
        system.assertEquals(true,URL41.contains('&TemplateId=templateId'));
        
        recipientContactIds.add(contact2.id);
        string URL5 = bg_DocumentUtils.GetDocumentUrl(quote.Id, '123', bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, recipientContactIds, false, true, false);
        String comapreString3 = '&ESContactId1=' + contact2.Id;
        system.assertEquals(true,URL5.contains(comapreString3));    
        
        quote.Expiry_Type__c = bg_DocumentUtils.DOCUMENT_EXPIRY_TYPE_HARD;
        update quote;
        
        string URL6 = bg_DocumentUtils.GetDocumentUrl(quote.Id, '123', bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, recipientContactIds, false, true, false);
        system.assertEquals(true,URL6.contains('&ESExpireInXDays='));

        Test.stopTest();

    }
    
    static testMethod void getDocumentUrlTestV2()
    {
        CongaQueryIds__c cstSet = new CongaQueryIds__c();
        cstSet.Name = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
        insert cstSet;
        
        APXTConga4__Conga_Template__c ct = new APXTConga4__Conga_Template__c();
        ct.Type__c = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
        ct.Active__c = true;
        ct.Language__c = 'EN';
        insert ct; 
        
        APXTConga4__Conga_Template__c ct2 = new APXTConga4__Conga_Template__c();
        ct2.Type__c = bg_DocumentUtils.DOCUMENT_TYPE_SALES_BRIEF;
        ct2.Active__c = true;
        ct2.Language__c = 'EN';
        insert ct2; 
        
      
        APXT_CMQR__Conga_Merge_Query__c cq = bg_UnitTestHelper.GetCongaQuery('SNCQ,SNCQ2');
        Template_Queries__c tq = bg_UnitTestHelper.GetTemplateQuery(cq.Id, ct.Id);
        
        APXT_CMQR__Conga_Merge_Query__c cq2 = bg_UnitTestHelper.GetCongaQuery('SNCX');
        Template_Queries__c tq2 = bg_UnitTestHelper.GetTemplateQuery(cq2.Id, ct2.Id);
        
        
        String ctId = bg_DocumentUtils.getTemplateId(bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, 'EN');
        system.assertEquals(true,ctId.contains(ct.Id));
        
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetSiteSettings();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c siteHQ = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c siteN = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c siteT = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');      
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteHQ, true);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteN);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteT);      
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        
        Quote__c quote = new Quote__c();
        quote.Account__c = account1.Id;
        quote.Contact__c = contact1.Id;
        quote.Opportunity_Name__c = opportunity1.Id;
        insert quote;
        
        SystemSetting__c ss = new SystemSetting__c();
        ss.ServerURL__c = 'https://bsi--dev.cs8.my.salesforce.com/';
        ss.CongaUpgradeURL__c = 'someurl';
        ss.Conga_Server_URL__c = 'someurl';
        insert ss;
        
        list<String>templateIds = new list<String>();
        templateIds.add(ct.Id);
        String URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, false, true, true);
        
        //String URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, 'EN', false, true, false, true);
        system.debug(logginglevel.error, 'ASD### quote url ' + URL2);
        system.assertEquals(false,URL2.contains('null'));
        system.assertEquals(true,URL2.contains('someurl'));
        system.assertEquals(true,URL2.contains('&DS7=4'));
        system.assertEquals(false,URL2.contains('&DS7=14'));
        system.assertEquals(true,URL2.contains('&TemplateId='));
        
        //URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, 'EN', true, true, false, true);
        URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, true, true, false);
        system.debug(logginglevel.error, 'ASD###  true true false quote url ' + URL2);
        system.assertEquals(false,URL2.contains('null'));
        system.assertEquals(false,URL2.contains('&DS7'));
        system.assertEquals(true,URL2.contains('&TemplateId='));
        
        //URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_SALES_BRIEF, 'EN', true, true, true, true);
        templateIds.clear();
        templateIds.add(ct2.Id);
        templateIds.add(ct.Id);
        URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, true, true, true);
        system.debug(logginglevel.error, 'ASD### true true true quote url ' + URL2);
        system.assertEquals(false,URL2.contains('null'));
        system.assertEquals(false,URL2.contains('&DS7=4'));
        system.assertEquals(true,URL2.contains('&DS7=14'));
        system.assertEquals(true,URL2.contains('&TemplateId='+ ct2.Id + ',' + ct.Id));
        
        URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, true, false, true);
        system.debug(logginglevel.error, 'ASD### true false true quote url ' + URL2);
        system.assertEquals(false,URL2.contains('null'));
        system.assertEquals(false,URL2.contains('&DS7=4'));
        system.assertEquals(true,URL2.contains('&DS7=12'));
        system.assertEquals(true,URL2.contains('&TemplateId='+ ct2.Id + ',' + ct.Id));
        
        URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, false, false, true);
        system.debug(logginglevel.error, 'ASD### false false true quote url ' + URL2);
        system.assertEquals(false,URL2.contains('null'));
        system.assertEquals(false,URL2.contains('&DS7=4'));
        system.assertEquals(true,URL2.contains('&DS7=1'));
        system.assertEquals(true,URL2.contains('&TemplateId='+ ct2.Id + ',' + ct.Id));
        
        URL2 = bg_DocumentUtils.getDocumentUrl(quote.Id, ct.Id, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, false, false, true);
        system.debug(logginglevel.error, 'ASD### false false true quote url ' + URL2);
        system.assertEquals(false,URL2.contains('null'));
        system.assertEquals(false,URL2.contains('&DS7=4'));
        system.assertEquals(true,URL2.contains('&DS7=1'));
        system.assertEquals(true,URL2.contains('&TemplateId=' + ct.Id));
        
        Boolean check = bg_DocumentUtils.CheckFactsExceedsDocLimit(quote.Id);
        system.assertEquals(check, false);
        
    }
   
    static testMethod void getTempalteIdTest()
    {
        APXTConga4__Conga_Template__c ct = new APXTConga4__Conga_Template__c();
        ct.Type__c = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
        ct.Active__c = true;
        ct.Language__c = 'EN';
        insert ct; 
        
        list<String> tTypes = new list<String>();
        String ctId = bg_DocumentUtils.getTemplateId(bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION,  'EN');
        system.assertEquals(true,ctId.contains(ct.Id));
        
    }
    
    static testMethod void getLatestAgreementTest()
    {
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetSiteSettings();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c siteHQ = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c siteN = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c siteT = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');      
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteHQ, true);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteN);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteT);      
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        
        Quote__c quote = new Quote__c();
        quote.Account__c = account1.Id;
        quote.Contact__c = contact1.Id;
        quote.Opportunity_Name__c = opportunity1.Id;
        insert quote;
        
        SystemSetting__c ss = new SystemSetting__c();
        ss.ServerURL__c = 'https://bsi--dev.cs8.my.salesforce.com/';
        insert ss;
        
        
        echosign_dev1__SIGN_Agreement__c ag = bg_UnitTestHelper.GetEchoSignAgreement();
        ag.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
        ag.Quote__c = quote.Id;
        update ag;
        
        echosign_dev1__SIGN_Agreement__c ag1b = bg_DocumentUtils.GetLatestAgreement(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION);
        system.assertEquals(ag.Id,ag1b.Id);
        
        echosign_dev1__SIGN_Agreement__c ag2 = bg_UnitTestHelper.GetEchoSignAgreement();
        ag2.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;
        ag2.Quote__c = quote.Id;
        update ag2;
        
        echosign_dev1__SIGN_Agreement__c ag3 = bg_UnitTestHelper.GetEchoSignAgreement();
        ag3.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_SALES_BRIEF;
        ag3.Quote__c = quote.Id;
        update ag3;
        
        List<echosign_dev1__SIGN_Agreement__c> agList = bg_DocumentUtils.GetAgreements(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, true);
        system.assertEquals(agList.size(), 1);
        system.assertEquals(agList[0].Id, ag.Id);
    }
    
    static testMethod void testCheckDocStatus()
    {
        echosign_dev1__SIGN_Agreement__c ag = bg_UnitTestHelper.GetEchoSignAgreement();
        ag.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
        ag.echosign_dev1__Status__c = 'Signed';
        update ag;
        
        system.assertEquals(true, bg_DocumentUtils.CheckDocumentStatus(ag, 'Signed'));
    }

    static testMethod void testGetRecipientContactIds()
    {
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetSiteSettings();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c siteHQ = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c siteN = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c siteT = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');      
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteHQ, true);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteN);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteT);      
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        Contact contact2 = bg_UnitTestHelper.GetContact('Test Contact2', account1);
        
        Quote__c quote = new Quote__c();
        quote.Account__c = account1.Id;
        quote.Contact__c = contact1.Id;
        quote.Opportunity_Name__c = opportunity1.Id;
        quote.Tech_Review_Team__c = contact2.Id;
        insert quote;
        
        SystemSetting__c ss = new SystemSetting__c();
        ss.ServerURL__c = 'https://bsi--dev.cs8.my.salesforce.com/';
        insert ss;
        
        List<Id> contacts = bg_DocumentUtils.GetRecipientContactIds(bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW,quote);
        System.assertEquals(contact2.Id,contacts[0]);
        
        List<Id> contacts2 = bg_DocumentUtils.GetRecipientContactIds('NotThere',quote);
        System.assertEquals(contact1.Id,contacts2[0]);
    }
    
    private static testMethod void testHandleQuotesOutForSignature()
    {
        // Test the HandleQuotesOutForSignature method
        bg_UnitTestHelper.SetupCustomSettings();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1, contact1);
        
        //SETUP ECHOSIGN AGREEMENTS
        map<Id,echosign_dev1__SIGN_Agreement__c> sentAgreements = new map<Id,echosign_dev1__SIGN_Agreement__c>();
        
        echosign_dev1__SIGN_Agreement__c ag1 = bg_UnitTestHelper.GetEchoSignAgreement(quote.Id, contact1.Id);
        ag1.echosign_dev1__Status__c = bg_DocumentUtils.DOCUMENT_STATUS_SIGNED;
        ag1.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;     
        update ag1;
        sentAgreements.put(quote.Id, ag1);
        test.startTest();
            bg_DocumentUtils.HandleQuotesOutForSignature(sentAgreements);
        test.stopTest();
        
        opportunity1 = [SELECT Id, QuoteSent__c FROM Opportunity WHERE Id = :opportunity1.Id];
        quote = [SELECT Id, Proposal_Sent_Date__c FROM Quote__c WHERE Id = :quote.Id];
        DateTime nowDateTime = DateTime.now();
        Date nowDate = Date.newInstance(nowDateTime.year(),nowDateTime.month(),nowDateTime.day());
        Date proposalSentDate = Date.newInstance(quote.Proposal_Sent_Date__c.Year(), quote.Proposal_Sent_Date__c.Month(), quote.Proposal_Sent_Date__c.Day());
        system.assertEquals(nowDate, proposalSentDate);
        system.assertEquals(true, opportunity1.QuoteSent__c);
    }

    private static testMethod void testHandleQuotesSigned()
    {
        // Test the HandleQuotesSigned method
        bg_UnitTestHelper.SetupCustomSettings();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1, contact1);
        quote.SkipCustomer__c = true;
        update quote;
        
        //Get existing number of feeds
        Integer feedItemsSize = [Select Count() FROM FeedItem]; 
        
        //SETUP ECHOSIGN AGREEMENTS
        map<Id,echosign_dev1__SIGN_Agreement__c> sentAgreements = new map<Id,echosign_dev1__SIGN_Agreement__c>();
        
        echosign_dev1__SIGN_Agreement__c ag1 = bg_UnitTestHelper.GetEchoSignAgreement(quote.Id, contact1.Id);
        ag1.echosign_dev1__Status__c = bg_DocumentUtils.DOCUMENT_STATUS_SIGNED;
        ag1.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;     
        update ag1;
        sentAgreements.put(quote.Id, ag1);
        
        test.startTest();
            bg_DocumentUtils.HandleQuotesSigned(sentAgreements, new set<Id>{contact1.Id});
        test.stopTest();
        
        quote = [SELECT ValidationCheck__c FROM Quote__c WHERE Id =:quote.Id];
        opportunity1 = [SELECT QuoteSent__c, FirstQuotationDate__c, StageName FROM Opportunity WHERE Id =:opportunity1.Id];
        
        system.assertNotEquals(feedItemsSize, [Select Count() From FeedItem]);
        system.assertEquals(quote.ValidationCheck__c, true);
        system.assertequals(bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING, opportunity1.StageName);
    }
    
    static testMethod void testUpdateQuoteAgreementStatus()
    {
        //SET UP ACCOUNTS,SITES<OPPORTUNITY,CONTACTS QUOTES AND SYSTEM SETTING
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetSiteSettings();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c siteHQ = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c siteN = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c siteT = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');      
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteHQ, true);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteN);
        bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteT);      
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        contact1.email = 'test654@test.com';
        update contact1;
        
        Contact contact2 = bg_UnitTestHelper.GetContact('Test Contact2', account1);
        contact2.email = 'test789@test.com';
        update contact2;
        
        Quote__c quote = new Quote__c();
        quote.Account__c = account1.Id;
        quote.Contact__c = contact1.Id;
        quote.Opportunity_Name__c = opportunity1.Id;
        quote.Tech_Review_Team__c = contact2.Id;
        insert quote;
        
        SystemSetting__c ss = new SystemSetting__c();
        ss.ServerURL__c = 'https://bsi--dev.cs8.my.salesforce.com/';
        insert ss;
        
        QuoteSetting__c qs = new QuoteSetting__c();
        qs.StatusDraft__c = 'Not SUbmitted';
        qs.StatusApproved__c = 'Approved';
        qs.StatusNA__c = 'N/A';
        qs.StatusWaiting__c = 'Pending';
        qs.StatusRejected__c = 'Declined';
        insert qs;
        
        //SETUP ECHOSIGN AGREEMENTS
        list<echosign_dev1__SIGN_Agreement__c> updatedAgreements = new list<echosign_dev1__SIGN_Agreement__c>();
        map<Id,echosign_dev1__SIGN_Agreement__c> oldAgreements = new map<Id,echosign_dev1__SIGN_Agreement__c>();
        
        echosign_dev1__SIGN_Agreement__c ag1 = bg_UnitTestHelper.GetEchoSignAgreement();
        echosign_dev1__SIGN_Agreement__c ag2 = bg_UnitTestHelper.GetEchoSignAgreement();
        
        ag1.echosign_dev1__Status__c = bg_DocumentUtils.DOCUMENT_STATUS_DRAFT;
        ag1.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
        ag1.Quote__c = quote.Id;
        ag1.echosign_dev1__Recipient__c = contact1.Id;
        
        ag2.echosign_dev1__Status__c = bg_DocumentUtils.DOCUMENT_STATUS_DRAFT;
        ag2.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;
        ag2.Quote__c = quote.Id;
        ag2.echosign_dev1__Recipient__c = contact2.Id;
        
        update ag1;
        update ag2;
        
        echosign_dev1__SIGN_Agreement__c agc1 = bg_UnitTestHelper.GetEchoSignAgreement();
        echosign_dev1__SIGN_Agreement__c agc2 = bg_UnitTestHelper.GetEchoSignAgreement();
        
        agc1.echosign_dev1__Status__c = bg_DocumentUtils.DOCUMENT_STATUS_SIGNED;
        agc1.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION;
        agc1.echosign_dev1__Recipient__c = contact1.Id;
        agc1.Quote__c = quote.Id;
        
        agc2.echosign_dev1__Status__c = bg_DocumentUtils.DOCUMENT_STATUS_PENDING;
        agc2.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;
        agc2.echosign_dev1__Recipient__c = contact2.Id;
        agc2.Quote__c = quote.Id;
        update agc1;
        update agc2;
        
        test.startTest();
            updatedAgreements.add(agc1);
            updatedAgreements.add(agc2);
            oldAgreements.put(agc1.Id, ag1);
            oldAgreements.put(agc2.Id, ag2);
        
            bg_DocumentUtils.UpdateQuoteAgreementStatus(updatedAgreements, oldAgreements);
            quote = [SELECT ValidationStatus__c FROM Quote__c WHERE Id =:quote.Id];
            opportunity1 = [SELECT QuoteSent__c, FirstQuotationDate__c FROM Opportunity WHERE Id =:opportunity1.Id];
            System.assertequals('Approved', quote.ValidationStatus__c);
            System.assertequals(True, opportunity1.QuoteSent__c);
            system.assertEquals(Date.today(), opportunity1.FirstQuotationDate__c);
        test.stopTest();
    }
}