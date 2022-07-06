/********************************************************************
 * bg_OpportunityUtilsTest
 *
 * Test class for bg_OpportunityUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 17-10-2013
 * Changes: 
 * 3/02/2015    KM  Added test methods for sync opportunity line items 
 * 20/04/2015   KM  Added BSI Permissions custom setting
 * 06/05/2015   KM  Added testSetOppsClosedProcessing + testUpdateOpportunitiesForSignature
 * 21/08/2015   CB  Commented out seealldata and replaced pricebook methods with updated pricebook method
 * 15-01-16     ASD - Fixed Unit Tests to suit VR rules and WFRs (too many SOQLS)
 * 22-07-2016   CH  Adjusted Test.Start to correct position in testSyncOpportunityLineItemsAllOperations()
 * 29-10-2018   PC K2 updated testSyncOpportunityLineItem()
 ********************************************************************/
@isTest
private class bg_OpportunityUtilsTest {

    private static Boolean testOLIEqualsQuotePartWithSOQL(Quote_Part__c quotePart, OpportunityLineItem oli) {
        
            //checks the OLI was created from the quote part
        
        quotePart = GetQuotePart(quotePart.id);
        oli = GetOli(oli.id);
        return testOLIEqualsQuotePart(quotePart, oli);
    }
    
    private static Boolean testOLIEqualsQuotePart(Quote_Part__c quotePart, OpportunityLineItem oli) {
        
            //checks the OLI was created from the quote part
        
        return oli.Quantity == quotePart.Number__c &&
            oli.ProductAttribute__c == quotePart.ProductAttribute__c &&
            oli.TotalPrice == quotePart.Total_Price_In_Currency__c && // Price in quote currency
            oli.Part_Extended_Value__c == quotePart.Part_Extended_Value__c &&
            oli.Product_Name__c == quotePart.Quote_Product__r.Product_Name__c &&
            oli.TotalGrossPrice__c == quotePart.Total_Gross_Price__c &&
            oli.Site__c == quotePart.Quote_Product__r.Site__c &&
            oli.Registration_Path__c == quotePart.Quote_Product__r.Registration_Path__c &&
            oli.LifeCycle__c == quotePart.Quote_Product__r.LifeCycle__c &&
            oli.Notes__c == quotePart.Notes__c &&
            oli.Quote_Part__c == quotePart.id;
    }
    
    private static Quote_Part__c GetQuotePart(Id quotePartId) {
        list<Quote_Part__c> quoteParts = GetQuoteParts(new set<Id>{quotePartId}); 
        Quote_Part__c returnVal;
        if(quoteParts.size() > 0) {
            returnVal = quoteParts.get(0);
        }
        return returnVal;
    }
    
    private static list<Quote_Part__c> GetQuoteParts(Set<Id> quotePartIds) {
        return new list<Quote_Part__c>([SELECT Id, Number__c, Price__c, Total_Price_In_Currency__c, Customer_Code__c, 
                                            ProductAttribute__c, Product2__c, Part_Extended_Value__c, Total_Gross_Price__c,
                                            Quote_Product__r.Product_Name__c, Quote_Ref__r.Opportunity_Name__c, Quote_Ref__r.PriceBook2Id__c, 
                                            Quote_Ref__r.Opportunity_Name__r.CurrencyIsoCode, Product2__r.ProductArea__c,Product2__r.Course_Delivery__c,
                                            Quote_Product__r.Site__c, Quote_Product__r.Registration_Path__c, RegistrationPath__c, Quote_Product__r.LifeCycle__c,
                                            Product2__r.ProductCode, InfoTxt__c, Notes__c                                               
                                        FROM Quote_Part__c 
                                        WHERE Id IN :quotePartIds]);
    }
    
    private static list<OpportunityLineItem> GetOLIs(Id oppId) {
        
        //Gets opportunity line items from an opp
        
        return new list<OpportunityLineItem>([SELECT Id, Quantity, ProductAttribute__c, TotalPrice, Part_Extended_Value__c, Product_Name__c,
                                                    TotalGrossPrice__c, Site__c, Registration_Path__c, LifeCycle__c, Notes__c, Quote_Part__c
                                            FROM OpportunityLineItem
                                            WHERE OpportunityId = :oppId]);
    }
    
    private static OpportunityLineItem GetOLI(Id oliId) {
        
            //Gets an opportunity line item by Id
        
        return [SELECT Id, Quantity, ProductAttribute__c, TotalPrice, Part_Extended_Value__c, Product_Name__c,
                         TotalGrossPrice__c, Site__c, Registration_Path__c, LifeCycle__c, Notes__c, Quote_Part__c
                FROM OpportunityLineItem
                WHERE Id = :oliId];
    }

    private static testMethod void testGetOpportunityById() {
        
            //Test GetOpportunityById method
        
        bg_UnitTestHelper.SetupCustomSettings();
        Opportunity newOpp = bg_UnitTestHelper.GetOpportunity();
        test.startTest();
            system.assertEquals(newOpp.Id, bg_OpportunityUtils.GetOpportunityById(newOpp.Id).Id);
        test.stopTest();
    }

    private static testMethod void testSaveOpportunity() {
        
            //Test SaveOpportunity method
        
        bg_UnitTestHelper.SetupCustomSettings();
        Opportunity newOpp = bg_UnitTestHelper.CreateOpportunity();
        test.startTest();
            bg_OpportunityUtils.SaveOpportunity(newOpp);
            system.assertNotEquals(null, newOpp.Id);
        test.stopTest();
    }

    private static testMethod void testSaveOpportunities() {
        
            //Test SaveOpportunities method
        
        bg_UnitTestHelper.SetupCustomSettings();
        Opportunity newOpp = bg_UnitTestHelper.CreateOpportunity();
        test.startTest();
            bg_OpportunityUtils.SaveOpportunities(new list<Opportunity>{newOpp});
            system.assertNotEquals(null, newOpp.Id);
        test.stopTest();
    }

    private static testMethod void testPopulateOpportunityDefaults() {
        
            //Test PopulateOpportunityDefaults method
        
        bg_UnitTestHelper.SetupCustomSettings();
        Opportunity newOpp = bg_UnitTestHelper.CreateOpportunity();
        Contact newCon = bg_UnitTestHelper.GetContact('UT_OPP_UTIL');
        test.startTest();
            newOpp.MainQuotePDFid__c = 'MainQuotePDFId';
            boolean result = bg_OpportunityUtils.PopulateOpportunityDefaults(newOpp, true, newCon.Id);
            system.assertEquals(true, result);
            system.assertEquals(newOpp.PrimaryContact__c, newCon.Id);
            system.assertEquals(null, newOpp.MainQuotePDFid__c);
        test.stopTest();    
    }
    
    private static testMethod void testSetOpportunitySyncFlag() {
        bg_UnitTestHelper.GetDefaultCountrySetting();
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp = [select id, Sync_in_Progress__c From Opportunity WHERE Id =: opp.Id];
        system.assert(!opp.Sync_In_Progress__c);
        bg_OpportunityUtils.SetOpportunitySyncFlag(new set<Opportunity>{opp});
        opp = [select id, Sync_in_Progress__c From Opportunity WHERE Id =: opp.Id];
        system.assert(opp.Sync_In_Progress__c);
    }
    
    private static testMethod void testClearOpportunitySyncFlag() {
        bg_UnitTestHelper.GetDefaultCountrySetting();
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp.Sync_In_Progress__c = true; 
        update opp;
        opp = [select id, Sync_in_Progress__c From Opportunity WHERE Id =: opp.Id];
        system.assert(opp.Sync_In_Progress__c);
        bg_OpportunityUtils.ClearOpportunitySyncFlag(new set<Opportunity>{opp});
        opp = [select id, Sync_in_Progress__c From Opportunity WHERE Id =: opp.Id];
        system.assert(!opp.Sync_In_Progress__c);
    }
    
    private static testMethod void testGetOpportunityLineItemsList() {
        bg_UnitTestHelper.SetupCustomSettings();
        BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
        bsiPerm.Can_Add_Opp_Products__c = true;
        update bsiPerm;
        string productName = 'ISO 9001';
        Product2 prod2 = bg_UnitTestHelper.GetProductFee(productName);
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp.CurrencyIsoCode = 'USD';
        Opportunity opp2 = bg_UnitTestHelper.GetOpportunity();
        opp2.CurrencyIsoCode = 'USD';
        update new list<Opportunity> {opp, opp2};
        PricebookEntry pbe = bg_UnitTestHelper.GetPricebookEntry(test.GetStandardPricebookId(), prod2.id);
        OpportunityLineItem oli = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
        OpportunityLineItem oli2 = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
        OpportunityLineItem oli3 = bg_UnitTestHelper.GetOpportunityLineItem(opp2, pbe);
        list<OpportunityLineItem> olis = bg_OpportunityUtils.GetOpportunityLineItemsList(new set<Id> {opp.Id, opp2.Id});
        system.assertEquals(3, olis.size());
    }
    
    private static testMethod void testSyncOpportunityLineItemsTriggerUpdate() {
        
            //Tests the sync oli method from updating the quote
        
        bg_UnitTestHelper.SetupCustomSettings();
        BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
        bsiPerm.Can_Add_Opp_Products__c = true;
        update bsiPerm;
        string productName = 'ISO 9001';
        Product2 prod2 = bg_UnitTestHelper.GetProductFee(productName);
        Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp.CurrencyIsoCode = 'USD';
        update opp;
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
        quotePart.Product2__c = prod2.id;
        quotePart.Notes__c = 'test note';
        update quotePart;
        PricebookEntry pbe = bg_UnitTestHelper.GetPricebookEntry(test.GetStandardPricebookId(), prod2.id);
        OpportunityLineItem oli = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
        oli.Quantity = 99;
        oli.TotalPrice = 10000;
        update oli;
        test.startTest();
            system.assert(!testOLIEqualsQuotePartWithSOQL(quotePart, oli)); 
            quote.SyncWithOpportunity__c = true;
            quote.Main_Quote__c = true;
            update quote;
            system.assertEquals(1, GetOLIs(opp.Id).size());
            oli = GetOLIs(opp.Id).get(0);
            system.assert(testOLIEqualsQuotePartWithSOQL(quotePart, oli));
        test.stopTest();
    }
    
    private static testMethod void testSyncOpportunityLineItemsInsert() {
        
            //Test SyncOpportunityLineItems method with OLIs to be inserted
        
        bg_UnitTestHelper.SetupCustomSettings();
        BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
        bsiPerm.Can_Add_Opp_Products__c = true;
        update bsiPerm;
        string productName = 'ISO 9001';
        Product2 prod2 = bg_UnitTestHelper.GetProductFee(productName);
        Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp.CurrencyIsoCode = 'USD';
        update opp;
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
        quotePart.Product2__c = prod2.id;
        quotePart.Notes__c = 'test note';
        update quotePart;
        quote.SyncWithOpportunity__c = true;
        quote.Main_Quote__c = true;
        PricebookEntry pbe = bg_UnitTestHelper.GetPricebookEntry(test.GetStandardPricebookId(), prod2.id);
        OpportunityLineItem oli = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
        
        test.startTest();
            system.assert(!testOLIEqualsQuotePartWithSOQL(quotePart, oli));
            bg_OpportunityUtils.SyncOpportunityLineItems(new list<Quote__c> {quote});
            system.assertEquals(1, GetOLIs(opp.id).size());
            oli = GetOLIs(opp.id).get(0);
            system.assert(testOLIEqualsQuotePartWithSOQL(quotePart, oli));
        test.stopTest();
    }
    
    private static testMethod void testSyncOpportunityLineItemsUpdate() {
        
            //Test SyncOpportunityLineItems method with OLIs to be updated
        
        bg_UnitTestHelper.SetupCustomSettings();
        BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
        bsiPerm.Can_Add_Opp_Products__c = true;
        update bsiPerm;
        string productName = 'ISO 9001';
        Product2 prod2 = bg_UnitTestHelper.GetProductFee(productName);
        Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp.CurrencyIsoCode = 'USD';
        update opp;
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, true, quoteProduct);
        quotePart.Product2__c = prod2.id;
        quotePart.Notes__c = 'test note';
        update quotePart;
        PricebookEntry pbe = bg_UnitTestHelper.GetPricebookEntry(test.GetStandardPricebookId(), prod2.id);
        quote.SyncWithOpportunity__c = true;
        quote.Main_Quote__c = true;
        OpportunityLineItem oli = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
        oli.Quote_Part__c = quotePart.Id;
        update oli;
        quote.SyncWithOpportunity__c = true;
        quote.Main_Quote__c = true;
        
        test.startTest();
            system.assert(!testOLIEqualsQuotePartWithSOQL(quotePart, oli));
            Id oldOLIId = oli.Id;
            bg_OpportunityUtils.SyncOpportunityLineItems(new list<Quote__c>{quote});
            oli = GetOLIs(opp.id).get(0);       
            system.assert(!testOLIEqualsQuotePartWithSOQL(quotePart, oli));
            system.assertEquals(oli.Id, oldOLIId);
        test.stopTest();
    }
    
    private static testMethod void testSyncOpportunityLineItemsDelete() {
        
            //Test SyncOpportunityLineItems method with OLIs to be deleted
        
        bg_UnitTestHelper.SetupCustomSettings();
        BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
        bsiPerm.Can_Add_Opp_Products__c = true;
        update bsiPerm;
        string productName = 'ISO 9001';
        Product2 prod2 = bg_UnitTestHelper.GetProductFee(productName);
        Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp.CurrencyIsoCode = 'USD';
        update opp;
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        PricebookEntry pbe = bg_UnitTestHelper.GetPricebookEntry(test.GetStandardPricebookId(), prod2.id);
        OpportunityLineItem oli = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
        OpportunityLineItem oli2 = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
        test.startTest();
            quote.SyncWithOpportunity__c = true;
            quote.Main_Quote__c = true;
            system.assertEquals(2, GetOLIs(opp.id).size());
            bg_OpportunityUtils.SyncOpportunityLineItems(new list<Quote__c>{quote});
            system.assertEquals(0, GetOLIs(opp.id).size());
        test.stopTest();
    }
    
    private static testMethod void testSyncOpportunityLineItemsAllOperations() {
        
            //Test SyncOpportunityLineItems method with OLIs to be inserted, updated and deleted
        
        bg_UnitTestHelper.SetupCustomSettings();
        BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
        bsiPerm.Can_Add_Opp_Products__c = true;
        update bsiPerm;
        string productName = 'ISO 9001';
        Product2 prod2 = bg_UnitTestHelper.GetProductFee(productName);
        Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp.CurrencyIsoCode = 'USD';
        update opp;
        
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        test.startTest();
            Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
            quotePart.Product2__c = prod2.id;
            Quote_Part__c quotePart2 = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
            quotePart2.Product2__c = prod2.id;
            Quote_Part__c quotePart3 = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, false, quoteProduct);
            quotePart3.Product2__c = prod2.id;
            map<Id, Quote_Part__c> quoteParts = new map<Id, Quote_Part__c>();
            quoteParts.put(quotePart.Id, quotePart);
            quoteParts.put(quotePart2.Id, quotePart2);
            quoteParts.put(quotePart3.Id, quotePart3);
            
            quotePart.Product2__c = prod2.id;
            quotePart.Notes__c = 'test note';
            update quoteParts.values();
            PricebookEntry pbe = bg_UnitTestHelper.GetPricebookEntry(test.GetStandardPricebookId(), prod2.id);
            OpportunityLineItem oli = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
    
            oli.Quote_Part__c = quotePart.id;
            oli.SMONumber__c = '0000000';
            oli.Quantity = 99;
            update oli;
            OpportunityLineItem oli2 = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
            
            
            //Check there are 2 OLIs before
            system.assertEquals(2, GetOLIs(opp.Id).size());
            quote.SyncWithOpportunity__c = true;
            quote.Main_Quote__c = true;
            bg_OpportunityUtils.SyncOpportunityLineItems(new list<Quote__c>{quote});
            //Check there are 3 OLIs after sync
            list<OpportunityLineItem> newOLIs = GetOLIs(opp.Id);
            system.assertEquals(3, newOLIs.size());
            testOLIEqualsQuotePart(quotePart, oli);
            map<Id, OpportunityLineItem> olisById = new map<Id, OpportunityLineItem>();
            olisById.putAll(newOLIs);
            //Check that OLI2 has been deleted and OLI1 is stil there
            system.assert(!olisById.containsKey(oli2.Id));
            system.assert(olisById.containsKey(oli.Id));
            
            //Check the 3 OLIs equal the quote parts
            quoteParts.putAll(GetQuoteParts(quoteParts.keySet()));
            for(OpportunityLineItem oliIterator : olisById.values()) {
                system.assert(testOLIEqualsQuotePart(quoteParts.get(oliIterator.Quote_Part__c), oliIterator));
            }
            oli = [Select Id, SMONumber__c, Quantity FROM OpportunityLineItem WHERE Id =: oli.Id];
            //Check the number hasn't been overwritten
            system.assertEquals('0000000', oli.SMONumber__c);
            system.assertNotEquals(99, oli.Quantity);
        test.stopTest();        
    }
    
    private static testMethod void testSyncOpportunityLineItem() {
        bg_UnitTestHelper.SetupCustomSettings();
        BSIPermissions__c bsiPerm  = bg_UnitTestHelper.GetBSIPermissionsSetting();
        bsiPerm.Can_Add_Opp_Products__c = true;
        update bsiPerm;
        string productName = 'ISO 9001';
        Product2 prod2 = bg_UnitTestHelper.GetProductFee(productName);
        Product__c product = bg_UnitTestHelper.GetQuestionProduct(productName);
        Opportunity opp = bg_UnitTestHelper.GetOpportunity();
        opp.CurrencyIsoCode = 'USD';
        update opp;
        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, true, quoteProduct);
        quotePart.Product2__c = prod2.id;
        quotePart.Notes__c = 'test note';
        quotePart.Discount_Percentage__c = 0;
        quotePart.Exchange_Rate__c = 1;
        quotePart.Price__c = 500;
        quotePart.Number__c = 1;
        update quotePart;

        quotePart = [SELECT ProductAttribute__c, Total_Price_In_Currency__c, Number__c, Customer_Code__c, Part_Extended_Value__c, Total_Gross_Price__c, 
            Notes__c, Info__c, InfoTxt__c, Revision__c, Location__c, Phase__c, FeeType__c, Project__c, Phase_Name__c, Phase_Start_Date__c, Phase_End_Date__c, 
            Phase_Description__c, Billing_Category__c, Price__c, Task_Detail__c, Task_Start_Date__c, Task_End_Date__c, Task_Assignment__c, 
            Product2__c, Product2__r.ProductArea__c, Product2__r.ProductCode, Product2__r.Course_Delivery__c,
            Quote_Product__r.Product_Name__c, Quote_Product__r.Site__c, Quote_Product__r.Registration_Path__c,RegistrationPath__c, Quote_Product__r.LifeCycle__c, 
            Quote_Ref__r.Opportunity_Name__c, Quote_Ref__r.PriceBook2Id__c, Quote_Ref__r.Opportunity_Name__r.CurrencyIsoCode, EHSTheme__c, EHSSpecialization__c, DeliveryLocation__c, Accreditation__c, Designation__c, NotifiedBody__c 
            FROM Quote_Part__c WHERE Id = :quotePart.Id];

        PricebookEntry pbe = bg_UnitTestHelper.GetPricebookEntry(test.GetStandardPricebookId(), prod2.id);
        OpportunityLineItem oli = bg_UnitTestHelper.GetOpportunityLineItem(opp, pbe);
        oli.Quote_Part__c = quotePart.Id;
        oli.SMONumber__c = '0000000';
        oli.Quantity = 5;
        test.startTest();
            system.assertEquals('0000000', oli.SMONumber__c);
            bg_OpportunityUtils.SyncOpportunityLineItem(pbe.Id, productName, quotePart, new List<OpportunityLineItem>{oli});
            system.assert(testOLIEqualsQuotePart(quotePart, oli));
            system.assertEquals('0000000', oli.SMONumber__c);
        test.stopTest();
    }
    
    /*private static testMethod void testCloneRelatedObjectsAll() {
        
            //Test CloneRelatedObjects method
            
        bg_UnitTestHelper.SetupCustomSettings();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');      
        
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
        opportunity2.Cloned_From_Opportunity__c = opportunity1.id;
        update opportunity2;
        
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        
        OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
        OpportunitySite__c opsite2 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
        OpportunitySite__c opsite3 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3);
        
        Attachment doc = bg_UnitTestHelper.GetAttachment(opportunity1.id, 'Unit', 'Unit Test Body');    
        Note doc2 = bg_UnitTestHelper.GetNote(opportunity1.id);
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        Product__c mainProduct = bg_UnitTestHelper.GetProduct('product'); 
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct, site1, opportunity1, opsite1);

        
            system.assertEquals(4, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity1.id).size());
            system.assertEquals(1, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id).size());
            system.assertEquals(0, bg_AttachmentUtils.GetAttachments(opportunity2.id).size());
        test.startTest();   
            system.assertEquals(1, bg_AttachmentUtils.GetAttachments(opportunity1.id).size());
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity1.id).size(), 1);
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity2.id).size(), 0);
            system.assertNotEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity1.id));
            system.assertEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity2.id));
        
            bg_OpportunityUtils.CloneRelatedObjects(opportunity1.id, opportunity2.id, true, true, true, true);
            
            system.assertEquals(1, bg_NoteUtils.GetCloneNotes(opportunity1.id).size());
            system.assertEquals(1, bg_NoteUtils.GetCloneNotes(opportunity2.id).size());
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity1.id).get(0).title, bg_NoteUtils.GetCloneNotes(opportunity2.id).get(0).title);
            system.assertEquals(false, bg_OpportunityUtils.GetOpportunityById(opportunity2.id).Clone_Available__c);
            system.assertEquals(1, [SELECT Id, BodyLength FROM Attachment WHERE ParentId = :opportunity1.id].size());
            system.assertEquals(1, [SELECT Id, BodyLength FROM Attachment WHERE ParentId = :opportunity2.id].size());
            system.assertEquals([SELECT Id, BodyLength FROM Attachment WHERE ParentId = :opportunity2.id].get(0).bodylength, [SELECT Id, BodyLength FROM Attachment WHERE ParentId = :opportunity1.id].get(0).bodylength);          
            system.assertEquals(4, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity1.id).size());
            system.assertEquals(5, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id).size());
            system.assertNotEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity1.id));
            system.assertNotEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity2.id));
            system.assertNotEquals(bg_QuoteUtils.GetMainQuoteId(opportunity1.id), bg_QuoteUtils.GetMainQuoteId(opportunity2.id));
                    
        test.stopTest();
    }*/
    
    private static testMethod void testCloneRelatedObjectsNone() {
        
            //Test CloneRelatedObjects method
        
        /*bg_UnitTestHelper.SetupCustomSettings();
        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Site__c site1 = bg_UnitTestHelper.CreateSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        //Site__c site2 = bg_UnitTestHelper.CreateSite(account1, 'UT_SITE_PRICEBOOKUTILS_NETWORK', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK, 'CM3 9AB');
        //Site__c site3 = bg_UnitTestHelper.CreateSite(account1, 'UT_SITE_PRICEBOOKUTILS_TRANSIENT', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT, 'CM4 9AB');     
        List<Site__c> sitesToInsert = new List<Site__c>();
        sitesToInsert.add(site1);
        //sitesToInsert.add(site2);
        //sitesToInsert.add(site3);
        insert sitesToInsert;
        
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
        opportunity2.Cloned_From_Opportunity__c = opportunity1.id;
        update opportunity2;
        
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        
        OpportunitySite__c opsite1 = bg_UnitTestHelper.CreateOpportunitySite(opportunity1, site1, true);
        //OpportunitySite__c opsite2 = bg_UnitTestHelper.CreateOpportunitySite(opportunity1, site2);
        //OpportunitySite__c opsite3 = bg_UnitTestHelper.CreateOpportunitySite(opportunity1, site3);
        List<OpportunitySite__c> opSitesToInsert = new List<OpportunitySite__c>();
        opSitesToInsert.add(opsite1);
        //opSitesToInsert.add(opsite2);
        //opSitesToInsert.add(opsite3);
        insert opSitesToInsert;
        Site__c siteHQ = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_NQCV2_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        
        Attachment doc = bg_UnitTestHelper.GetAttachment(opportunity1.id, 'Unit', 'Unit Test Body');    
        Note doc2 = bg_UnitTestHelper.GetNote(opportunity1.id);
        //Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        Product__c mainProduct = bg_UnitTestHelper.GetProduct('product'); 
        //Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct, null, null, opsite1);
            Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity2);
            Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, mainProduct, siteHQ, opportunity2, opsite1);*/

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
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(acc, productName);
        Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(acc, productName);
        opportunity2.Cloned_From_Opportunity__c = opportunity1.id;
        update opportunity2;
        // Add Site
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_NQCV2_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        // Opportunity Site
        OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opportunity2, siteHQ, true);
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity2);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, siteHQ, opportunity2, oppSite);
        
        test.startTest();
            /*system.assertEquals(4, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity1.id).size());
            system.assertEquals(1, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id).size());
            system.assertEquals(0, [SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opportunity2.id].size());
            system.assertEquals(1, [SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opportunity1.id].size());
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity1.id).size(), 1);
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity2.id).size(), 0);
            system.assertNotEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity1.id));
            system.assertEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity2.id));*/
            
            bg_OpportunityUtils.CloneRelatedObjects(opportunity1.id, opportunity2.id, false, false, false, false);
            bg_OpportunityUtils.CloneRelatedObjects(opportunity1.id, opportunity2.id, true, true, true, true);
            
            /*system.assertEquals(4, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity1.id).size());
            system.assertEquals(5, bg_OpportunitySiteUtils.GetCloneOpportunitySites(opportunity2.id).size());
            system.assertEquals(0, [SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opportunity2.id].size());
            system.assertEquals(1, [SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opportunity1.id].size());
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity1.id).size(), 1);
            system.assertEquals(bg_NoteUtils.GetCloneNotes(opportunity2.id).size(), 0);
            system.assertNotEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity1.id));
            system.assertEquals(null, bg_QuoteUtils.GetMainQuoteId(opportunity2.id));*/
            
        test.stopTest();
    }   
    
    private static testmethod void testSetOppsClosedProcessing()
    {
        // Tests the SetOppsClosedProcessing method without an inserts
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity();
        opportunity1.StageName = bg_OpportunityUtils.OPPORTUNITY_STAGE_NEGOTIATION;
        system.assertNotEquals(bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING, opportunity1.StageName);

        test.startTest();
            bg_OpportunityUtils.SetOppsClosedProcessing(new list<Opportunity>{opportunity1});
        test.stopTest();

        system.assertEquals(bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING, opportunity1.StageName);
    } 
    
    private static testmethod void testSetOppsClosedProcessing2()
    {
        // Tests the SetOppsClosedProcessing method with inserts
        Account account1 = bg_UnitTestHelper.GetAccount();
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
        opportunity1.StageName = bg_OpportunityUtils.OPPORTUNITY_STAGE_NEGOTIATION;
        update opportunity1;
        
        system.assertNotEquals(bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING, opportunity1.StageName);
        
        test.startTest();
            bg_OpportunityUtils.SetOppsClosedProcessing(new set<Id>{opportunity1.Id});
        test.stopTest();
        
        opportunity1 = [Select Id, StageName FROM Opportunity WHERE Id = :opportunity1.Id];
        system.assertEquals(bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING, opportunity1.StageName);
    } 

    private static testMethod void testUpdateOpportunitiesOutForSignature()
    {
        //Test the UpdateOpportunitiesOutForSignature method without inserting
        bg_UnitTestHelper.SetupCustomSettings();
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity();
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        quote.Expiry_Days__c = 60;
        map<Id, Quote__c> oppToQuote = new map<Id, Quote__c>{ opportunity1.Id => quote };
        test.startTest();
            bg_OpportunityUtils.UpdateOpportunitiesOutForSignature(oppToQuote, new list<Opportunity> {opportunity1});
            system.debug('Test 5');
        test.stopTest();
        system.assertEquals(opportunity1.QuoteSent__c, true);
        system.assertEquals(opportunity1.StageName, bg_OpportunityUtils.OPPORTUNITY_STAGE_NEGOTIATION);
        system.assertEquals(opportunity1.FirstQuotationDate__c, Date.today());
        system.assertEquals(opportunity1.QuoteExpirationDate__c, Date.today().addDays(quote.Expiry_Days__c.intValue()));
    }

    private static testMethod void testUpdateOpportunitiesOutForSignature2()
    {
        //Test the UpdateOpportunitiesOutForSignature with inserts
        bg_UnitTestHelper.SetupCustomSettings();
        Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity();
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        quote.Expiry_Days__c = 60;
        map<Id, Quote__c> oppToQuote = new map<Id, Quote__c>{ opportunity1.Id => quote };
        test.startTest();
            bg_OpportunityUtils.UpdateOpportunitiesOutForSignature(oppToQuote);
        test.stopTest();
        opportunity1 = [Select QuoteSent__c, StageName, FirstQuotationDate__c, QuoteExpirationDate__c, Id FROM Opportunity WHERE Id = :opportunity1.Id];
        system.assertEquals(opportunity1.QuoteSent__c, true);
        system.assertEquals(opportunity1.StageName, bg_OpportunityUtils.OPPORTUNITY_STAGE_NEGOTIATION);
        system.assertEquals(opportunity1.FirstQuotationDate__c, Date.today());
        system.assertEquals(opportunity1.QuoteExpirationDate__c, Date.today().addDays(quote.Expiry_Days__c.intValue()));
    }
    
    @isTest //(SeeAllData=true) // standard pricebook
    private static void testCreateEnrollementOpportunityStageCloseProcessing()
    {
        bg_UnitTestHelper.GetDefaultCountrySetting();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=user1.Id, CanChangeLeadSources__c=true, CloseWinOpportunities__c=true);
        insert perms;

        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        Opportunity opportunity1 = bg_UnitTestHelper.CreateOpportunity(account1);
        opportunity1.CurrencyIsoCode = 'GBP';
        insert opportunity1;
        OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);

        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');

        Contact instructor = bg_TrainingUnitTestHelper.GetContactTraining('UNITTEST_LASTNAME', 'ICODES', masterVenue.Id);

        // Set up product #1 (non-residential)
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        // Set up product #2 (residential)
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        Product2 prd3 = TrainingBookingTestData.createTestCourse('Exam','EMS12345ENUK', null);

        // Set up price book entries
        //Pricebook2 std = bg_UnitTestHelper.GetStandardPricebook();
        PricebookEntry pbe1 = bg_UnitTestHelper.createStandardPriceBookEntry(prd1.id, 50, opportunity1.CurrencyIsoCode);
        PricebookEntry pbe2 = bg_UnitTestHelper.createStandardPriceBookEntry(prd2.id, 50, opportunity1.CurrencyIsoCode);
        PriceBookEntry pbe3 = bg_UnitTestHelper.createStandardPriceBookEntry(prd3.id, 50, opportunity1.CurrencyIsoCode);

        Training_Translations__c trainingTranslation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert trainingTranslation;

        // Setup an event
        Training_Event__c evt = bg_TrainingUnitTestHelper.createTrainingEvent(tv, 'USD', 5, prd1, Date.today()+10, instructor.Id);

        // Setup the booking for a residential event
        TrainingBooking__c booking = TrainingBookingTestData.createTestBooking(evt, pbe1, pbe2);
        TrainingDelegate__c delegate1 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate1', 'A', null, 'a@a.com', null, true, null);
        TrainingDelegate__c delegate2 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate2', 'A', null, 'a2@a.com', null, false, null);

        booking.Pricebook_Entry__c = pbe3.Id;
        booking.Price_Per_Delegate__c = 50.00;
        booking.CurrencyIsoCode = 'USD';
        booking.Country_ISO_Code__c = 'GB';
        booking.Conversion_Account__c = account1.Id;
        booking.Conversion_Opportunity__c = opportunity1.Id;
        booking.Conversion_Contact__c = contact1.Id;
        booking.Company_Country__c = 'United Kingdom';
        booking.Converted__c = false;
        booking.Quote__c = quote.Id;
        //set conversion pre req fields
        booking.Training_Translations__c = trainingTranslation.Id;
        booking.Booking_Route__c = 'Internal Sales';
        booking.Number_of_Delegates__c = 2;
        booking.Delegates_inc_extra_night__c = 0;
        booking.Delegates_inc_exam__c = 0;
        booking.Delegates_Inc_Accommodation__c = 1;
        booking.Price_Per_Delegate_Accommodation__c = 300;
        update booking;

        Test.startTest();

        opportunity1.StageName = bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING;
        update opportunity1;



        List<TrainingBooking__c> bookings = [SELECT Id, Training_Event__c, Converted__c, Conversion_Error__c, (SELECT  Id, Conversion_Contact__c from Training_Delegates__r) from TrainingBooking__c
            where Conversion_Opportunity__c = :opportunity1.Id];

        List<Id> trainingEventIds = new List<Id>();
        for (TrainingBooking__c trainingBooking : bookings)
        {
            system.assertEquals(true, trainingBooking.Converted__c);
            system.assertEquals(2,trainingBooking.Training_Delegates__r.size());
            for (TrainingDelegate__c delegate : trainingBooking.Training_Delegates__r)
            {
                system.assertNotEquals(null, delegate.Conversion_Contact__c);
            }
            trainingEventIds.add(trainingBooking.Training_Event__c);
        }

        List<Enrollment__c> enrs = [SELECT Id, Training_Event__c, Booking_Status__c, Delegate_Name__c from Enrollment__c where Training_Event__c = :trainingEventIds];

        system.assertEquals(2, enrs.size());

        for (Enrollment__c enrolment : enrs)
        {
            system.assertNotEquals(null, enrolment.Training_Event__c);
            system.assertNotEquals(null,enrolment.Delegate_name__c);
            system.assertEquals('Booked', enrolment.Booking_Status__c);
        }

        Test.stopTest();
    }

    //@isTest //(SeeAllData=true) // standard pricebook
    private static void testCreateEnrollementOpportunityStageCloseProcessingBookingConvertToOnHold()
    {
        bg_UnitTestHelper.GetDefaultCountrySetting();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=user1.Id, CanChangeLeadSources__c=true, CloseWinOpportunities__c=true);
        insert perms;

        Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Contact contact1 = bg_UnitTestHelper.GetContact('Test Contact', account1);
        Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        
        Opportunity opportunity1 = bg_UnitTestHelper.CreateOpportunity(account1);
        opportunity1.CurrencyIsoCode = 'GBP';
        opportunity1.Sync_in_Progress__c = true;
        insert opportunity1;
        OpportunitySite__c opsite1 = bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');

        Contact instructor = bg_TrainingUnitTestHelper.GetContactTraining('UNITTEST_LASTNAME', 'ICODES', masterVenue.Id);
        
        
        // Set up product #1 (non-residential)
        Product2 prd1 = TrainingBookingTestData.getTestCourse('Normal', 'EMS12345ENUK', null);
        // Set up product #2 (residential)
        Product2 prd2 = TrainingBookingTestData.getTestCourse('Residential', 'EMS12345ENUK', prd1);
        Product2 prd3 = TrainingBookingTestData.getTestCourse('Exam','EMS12345ENUK', null);
        List<Product2> prdToInsert = new List<Product2>();
        prdToInsert.add(prd1);
        prdToInsert.add(prd2);
        prdToInsert.add(prd3);
        insert prdToInsert;
        
        // Set up price book entries
        //Pricebook2 std = bg_UnitTestHelper.GetStandardPricebook();
        PricebookEntry pbe1 = bg_UnitTestHelper.getStandardPriceBookEntry(prd1.id, 50, opportunity1.CurrencyIsoCode);
        PricebookEntry pbe2 = bg_UnitTestHelper.getStandardPriceBookEntry(prd2.id, 50, opportunity1.CurrencyIsoCode);
        PriceBookEntry pbe3 = bg_UnitTestHelper.getStandardPriceBookEntry(prd3.id, 50, opportunity1.CurrencyIsoCode);
        List<PricebookEntry> pbeToInsert = new List<PricebookEntry>();
        pbeToInsert.add(pbe1);
        pbeToInsert.add(pbe2);
        pbeToInsert.add(pbe3);
        insert pbeToInsert;
        
        Quote__c quote = bg_UnitTestHelper.GetQuote(opportunity1);
        Product__c configuratorProd = bg_TrainingUnitTestHelper.createConfiguratorProduct('Training Global');
        Quote_Product__c quoteProd = bg_UnitTestHelper.GetQuoteProduct(quote, contact1);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, configuratorProd, 0, false, quoteProd);

        
        // setup Opportunity line item
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.PricebookEntryId = pbe1.Id;
        oli.OpportunityId = opportunity1.Id;
        oli.Quantity = 1;
        oli.TotalPrice = 100;
        oli.Quote_Part__c = quotePart.Id;
        insert oli;
        
        
        // Setup an event
        Training_Event__c evt = bg_TrainingUnitTestHelper.createTrainingEvent(tv, 'USD', 5, prd1, Date.today()+10, instructor.Id);

        Training_Translations__c trainingTranslation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert trainingTranslation;

        
        Test.startTest();

        // Setup the booking for a residential event
        TrainingBooking__c booking = TrainingBookingTestData.createTestBooking(evt, pbe1, pbe2);
        TrainingDelegate__c delegate1 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate1', null, null, 'a@a.com', null, true, null);
        TrainingDelegate__c delegate2 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate2', null, null, 'a2@a.com', null, false, null);

        booking.Pricebook_Entry__c = pbe3.Id;
        booking.Price_Per_Delegate__c = 50.00;
        booking.CurrencyIsoCode = 'USD';
        booking.Country_ISO_Code__c = 'GB';
        booking.Conversion_Account__c = account1.Id;
        booking.Conversion_Opportunity__c = opportunity1.Id;
        booking.Conversion_Contact__c = contact1.Id;
        booking.Convert_To_On_Hold__c = true;
        booking.Company_Country__c = 'United Kingdom';
        booking.Quote__c = quote.Id;
        booking.Convert_To_On_Hold__c = true;
        // set pre req conversion fields
        booking.Training_Translations__c = trainingTranslation.Id;
        booking.Booking_Route__c = 'Internal Sales';
        // setting the below will force delegate creation
        booking.Number_of_Delegates__c = 2;
        booking.Delegates_inc_extra_night__c = 0;
        booking.Delegates_Inc_Accommodation__c = 1;
        update booking;

        quotePart.Training_Booking__c = booking.Id;
        update quotePart;


        opportunity1.StageName = bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING;
        update opportunity1;

        List<TrainingBooking__c> bookings = [SELECT Id, Training_Event__c, Conversion_Error__c, Converted__c, (SELECT  Id from Training_Delegates__r) from TrainingBooking__c
            where Conversion_Opportunity__c = :opportunity1.Id];

        List<Id> trainingEventIds = new List<Id>();
        for (TrainingBooking__c trainingBooking : bookings)
        {
            system.assertEquals(true, trainingBooking.Converted__c);
            system.assertEquals(2,trainingBooking.Training_Delegates__r.size());
            trainingEventIds.add(trainingBooking.Training_Event__c);
        }

        List<Enrollment__c> enrs = [SELECT Id, Training_Event__c, Booking_Status__c from Enrollment__c where Training_Event__c = :trainingEventIds];

        system.assertEquals(2, enrs.size());

        for (Enrollment__c enrolment : enrs)
        {
            system.assertEquals(evt.Id, enrolment.Training_Event__c);
            system.assertEquals(bg_TrainingUtils.ENROLMENT_BOOKING_STATUS_ONHOLD_PAYMENT.toLowerCase(), enrolment.Booking_Status__c.toLowerCase());
        }

        List<OpportunityLineItem> oppItems = [SELECT Id, Description, Training_Event__c from OpportunityLineItem where OpportunityId = :opportunity1.id];

        system.assertEquals(1,oppItems.size());
        for (OpportunityLineItem item : oppItems)
        {
            system.assertEquals(bg_TrainingUtils.ONHOLD_DESCRIPTION, item.Description);
            system.assertEquals(null, item.Training_Event__c);
        }

        Test.stopTest();
    }

    @isTest static void testDeleteOpportunityLineItems(){
        Account a = new Account(Name = 'test', BillingCountry = 'UK');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;

        Opportunity opp = new Opportunity(Name = 'test Opp', StageName = 'Sales Engaged', CloseDate = Date.today(), AccountId = a.Id, Sync_in_Progress__c = true, BusinessDrivers__c = 'New Customer');
        insert opp;

        Product2 product = TestDataUtility.insertCourse();

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 0.0, IsActive = true);
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.PricebookEntryId = pbe.Id;
        oli.OpportunityId = opp.Id;
        oli.Quantity = 1;
        oli.TotalPrice = 1000;
        insert oli;

        bg_OpportunityUtils.DeleteOpportunityLineItems(new Set<Id>{opp.Id});
    }
}