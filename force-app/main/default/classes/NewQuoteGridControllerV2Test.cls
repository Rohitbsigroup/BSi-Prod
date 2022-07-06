/********************************************************************
 * NewQuoteGridControllerV2Test
 *
 * Test class for NewQuoteGridControllerV2
 * 
 * 
 * Author: Richard Jimenez
 * Created: 10-09-2015
 * Changes: 
 *          03-10-17 - RC - removed assert as controller is redundant.
 ********************************************************************/
@isTest
private class NewQuoteGridControllerV2Test {

    private static testMethod void testNewQuoteGridControllerV2() {
        /*
            Method to test NewQuoteGridControllerV2
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
        // Opportunity Site
        OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);

        test.startTest();                
            /*  LOAD QUOTE TEST */
            Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
			Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, siteHQ, opp, oppSite);
            quoteProduct.Registration_Path__c = 'New Registration';
            quoteProduct.Included_in_IMS__c = true;
            quoteProduct.Sampling_Available__c = true;
            quoteProduct.Sampling_Applied__c = true;
            quoteProduct.Sampling_Verified__c = true;
            update quoteProduct;

            // Setup page
            Test.setCurrentPage(Page.newQuoteGridV2);
            ApexPages.currentPage().getParameters().put('accid', acc.Id);
            ApexPages.currentPage().getParameters().put('oppid', opp.Id);
            ApexPages.currentPage().getParameters().put('quoid', quote.Id);
    
            NewQuoteGridControllerV2 controller = new NewQuoteGridControllerV2();

            system.assertEquals(false, controller.SaveError);

            controller.QuickSave();
            controller.Save();
            controller.ShowContacts();
            controller.HideContacts();
    
            system.assertNotEquals(0, controller.getPricebookItems().size());
            system.assertNotEquals(0, controller.getCurrencyCodeItems().size());
            system.assertNotEquals(0, controller.getContactItems().size());
            system.assertNotEquals(false, controller.getCheckPricebooksSet());
    
            //system.assertNotEquals(null, controller.Back());
			system.assertNotEquals(null, controller.Close());

			controller.selectedProductId = product.Id;
			controller.selectedQuoteProductId = quoteProduct.Id;

			//system.assertEquals(null, controller.ViewProductProfile());
            //system.assertEquals(null, controller.ConfigureProduct());
            //system.assertEquals(null, controller.ConfigureAll());

			//system.assertEquals(null, controller.UploadProduct());
			
        test.stopTest();
    }

}