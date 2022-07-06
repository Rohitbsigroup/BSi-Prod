/**
*
* Author:       Carmine Barbuto
* Company:      Tquila
* Date:         31/01/2012
* Description:  TEST CLASS: QuoteTriggerHandler
*
* ------------------
* TESTING:       88%
* ------------------
* TRIGGER:      100%
* ------------------      
**/
@isTest
private class QuoteTriggerHandlerTest {

    static testMethod void createOptyProds() {
        // STANDARD PRODUCT OBJECTS
        List<Product2> prods = new List<Product2>();
        List<PricebookEntry> pbes = new List<PricebookEntry>(); 
        Pricebook2 pb = TestData.getPriceBook();
        for (Integer i = 0; i < 20; i ++) {
            Product2 prod = TestData.getTestProduct();
            prod.Product_Code_Unique__c = i+'code';
            prod.ProductCode = i+'';
            prods.add(prod);
            System.debug('***SM*** prod.Product_Code_Unique__c '+prod.Product_Code_Unique__c);
            System.debug('***SM*** prod.Id ' +prod.Id);
        }
        System.debug('***SM*** What prods contains ' +prods);
        insert prods;
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id AND Product2Id IN :new Map<Id, Product2>(prods).keySet()];                         

        //Pricebook2 globalPB = bg_UnitTestHelper.GetGlobalPricebook(); 

        for (Product2 curr : prods) {   
            PricebookEntry pbe1 = TestData.getTestPriceBookEntry(curr.Id, pb.Id);
            //PricebookEntry pbe2 = TestData.getTestPriceBookEntry(curr.Id, globalPB.Id);
            pbes.add(pbe1);
            //pbes.add(pbe2);
        }
        insert pbes;
        
        // DATA
        Account acc = TestData.getTestAccount();
        insert acc;
        Opportunity opp = TestData.getTestOpty();
        opp.AccountId = acc.Id;
        opp.Pricebook2Id = pb.Id;
        insert opp;
        Contact con = TestData.getTestContact();
        con.AccountId = acc.Id;
        insert con;
        Quote__c quote = TestData.getTestQuote(opp.Id, con.Id, acc.Id);
        quote.PriceBook2Id__c = pb.Id;
        insert quote;

    string productName = 'ISO 9001';
    Product__c product = bg_UnitTestHelper.GetProduct(productName);
    Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product, null, opp, null);

        List<Quote_Part__c> qparts = new List<Quote_Part__c>();
        for (Product2 curr : prods) {
            Quote_Part__c qpart = new Quote_Part__c();
            qpart.Quote_Ref__c = quote.Id;
            qpart.Product2__c = curr.Id;
            qpart.Number__c = 1;
            qpart.Price__c = 1;
            qpart.Quote_Product__c = quoteProduct.Id;
            qparts.add(qpart);
        }
        Test.startTest();
        insert qparts;
        quote.SyncWithOpportunity__c = true;
        update quote;
        Test.stopTest();
        // Check expected results
        List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =:opp.Id];
        System.assertEquals(20, items.size());
    }
}