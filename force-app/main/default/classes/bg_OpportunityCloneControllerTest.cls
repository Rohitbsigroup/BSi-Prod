/********************************************************************
 * bg_OpportunityCloneControllerTest
 *
 * Test methods for the opportunity clone controller
 * 
 * Author:  Kieran Maguire
 * Created: 14-11-2014
 * Changes: 
 ********************************************************************/
@isTest
public class bg_OpportunityCloneControllerTest 
{
 
    public static testMethod void testConfigureCloneAllObjects() 
    {
        /*bg_UnitTestHelper.GetDefaultCountrySetting();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');      
        
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
        opportunity2.Cloned_From_Opportunity__c = opportunity1.id;
        update opportunity2;
        
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        Contact_Opportunity__c contactOpp = bg_UnitTestHelper.GetContactOpportunity(opportunity1.id, contact1.id);
        
        OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
        OpportunitySite__c opsite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
        OpportunitySite__c opsite3 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3);
        
        Attachment doc = bg_UnitTestHelper.GetAttachment(opportunity1.id, 'Unit', 'Unit Test Body');    
        Note doc2 = bg_UnitTestHelper.GetNote(opportunity1.id);
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        Product__c mainProduct = bg_UnitTestHelper.GetProduct('product'); 
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct, site1, opportunity1, opsite1);*/


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
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(acc, productName);
        Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(acc, productName);
        opportunity2.Cloned_From_Opportunity__c = opportunity1.id;
        update opportunity2;
        // Add Site
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV2_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        // Opportunity Site
        OpportunitySite__c oppSite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, siteHQ, true);
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, siteHQ, opportunity1, oppSite2);

        test.startTest();
            /*system.assertEquals(4, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity1.id).size());
            system.assertEquals(1, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id).size());
            system.assertEquals(0, bg_AttachmentUtils.GetAttachments(opportunity2.id).size());
            system.assertEquals(1, bg_AttachmentUtils.GetAttachments(opportunity1.id).size());
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity1.id).size(), 1);
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity2.id).size(), 0);*/
                        
            ApexPages.currentPage().getParameters().put(bg_OpportunityCloneController.URL_PARAMETER_CLONED_FROM_OPP_ID, opportunity1.id);
            ApexPages.currentPage().getParameters().put(bg_OpportunityCloneController.URL_PARAMETER_OPP_ID, opportunity2.id);
            bg_OpportunityCloneController controller = new bg_OpportunityCloneController(new Apexpages.Standardcontroller(opportunity2));
            controller.ConfiguratorClone();
            
            /*system.assertEquals(1, bg_NoteUtils.GetCloneNotes(opportunity1.id).size());
            system.assertEquals(1, bg_NoteUtils.GetCloneNotes(opportunity2.id).size());
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity1.id).get(0).title, bg_NoteUtils.GetCloneNotes(opportunity2.id).get(0).title);
            system.assertEquals(false, bg_OpportunityUtils.GetOpportunityById(opportunity2.id).Clone_Available__c);
            system.assertEquals(1, [SELECT Id, BodyLength FROM Attachment WHERE ParentId = :opportunity1.id].size());
            system.assertEquals(1, [SELECT Id, BodyLength FROM Attachment WHERE ParentId = :opportunity2.id].size());
            system.assertEquals([SELECT Id, BodyLength FROM Attachment WHERE ParentId = :opportunity2.id].get(0).bodylength, [SELECT Id, BodyLength FROM Attachment WHERE ParentId = :opportunity1.Id].get(0).bodylength);            
            system.assertEquals(4, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity1.id).size());
            system.assertEquals(5, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id).size());*/
            
            List<Quote_Product__c> quoteProducts = bg_QuoteUtils.GetQuoteProducts(bg_QuoteUtils.GetMainQuoteId(opportunity2.id));
            OpportunitySite__c cloneOppSite;
            for(OpportunitySite__c oppSite : bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id))
            {
                if(oppSite.Site__c == siteHQ.id)
                {
                    cloneOppSite = oppSite;
                    break;
                }
            }

            /*system.assertEquals(cloneOppSite.id, quoteProducts.get(0).Opportunity_Site__c);
            system.assertNotEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity2.id));*/
    }
    
    public static testMethod void testConfigureCloneNoObjects() 
    {
        bg_UnitTestHelper.GetDefaultCountrySetting();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
        opportunity2.Cloned_From_Opportunity__c = opportunity1.id;
        update opportunity2;
        
        test.startTest();
            ApexPages.currentPage().getParameters().put(bg_OpportunityCloneController.URL_PARAMETER_CLONED_FROM_OPP_ID, opportunity1.id);
            ApexPages.currentPage().getParameters().put(bg_OpportunityCloneController.URL_PARAMETER_OPP_ID, opportunity2.id);
            bg_OpportunityCloneController controller = new bg_OpportunityCloneController(new Apexpages.Standardcontroller(opportunity2));
            controller.ConfiguratorClone();         
        test.stopTest();
    }
}