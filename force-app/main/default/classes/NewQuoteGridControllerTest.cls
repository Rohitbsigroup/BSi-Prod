/********************************************************************
 * NewQuoteGridControllerTest
 *
 * Test class for NewQuoteGridController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 18-12-2013
 * Changes: 
 *        01-08-2015 RJ Added start/stop test
 ********************************************************************/
@isTest
private class NewQuoteGridControllerTest {

    private static testMethod void testNewQuoteGridController() {
        /*
            Method to test NewQuoteGridController
        */      
        // Set up data
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetSiteSettings();                
        // Product
        string productName = 'ISO 9001';
        Product__c product = bg_UnitTestHelper.GetProduct(productName);
        // Account
        Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
        // Contact
        Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
        // Opportunity
        Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);
        // Add Site
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV2_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c siteN = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV2_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c siteT = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV2_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');        
        // Opportunity Site
        bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
        bg_UnitTestHelper.GetOpportunitySite(opp, siteN, true);
        bg_UnitTestHelper.GetOpportunitySite(opp, siteT, true);
               
        test.startTest();                
            /*  LOAD QUOTE TEST */
            Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
            // Setup page
            Test.setCurrentPage(Page.newQuoteGrid);
            ApexPages.currentPage().getParameters().put('accid', acc.Id);
            ApexPages.currentPage().getParameters().put('oppid', opp.Id);
            ApexPages.currentPage().getParameters().put('quoid', quote.Id);
    
            NewQuoteGridController controller = new NewQuoteGridController();
            controller.QuickSave();
            controller.Save();
            controller.ShowContacts();
            controller.HideContacts();
    
            system.assertNotEquals(0, controller.getPricebookItems().size());
            system.assertNotEquals(0, controller.getCurrencyCodeItems().size());
            system.assertNotEquals(0, controller.getContactItems().size());
            system.assertNotEquals(false, controller.getCheckPricebooksSet());
    
            system.assertNotEquals(null, controller.Back());
            system.assertNotEquals(null, controller.ConfigureProduct());
            system.assertNotEquals(null, controller.ConfigureAll());
        test.stopTest();
    }

}