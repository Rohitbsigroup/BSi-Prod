/**
*  Author    : Prasad JN
*  Description  : Test Class Close by Line Item
*/
@isTest(SeeAllData=true)
public with sharing class emq_CloseWinByLineItemTest {
    
    static testMethod void testCloseWinByLineItem() {
      // Set up data
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
        Product2 prod =  TestData.getTestProduct();
    insert prod;  
    
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id AND Product2Id = :prod.Id];
        
    PricebookEntry pbe = TestData.getTestPriceBookEntry(prod.Id, pb.Id);
    insert pbe;  
    
      Account acc = TestData.getTestAccount();
    insert acc;
      Opportunity opp = TestData.getTestOpty();
      opp.AccountId = acc.Id;
      insert opp;
    
      OpportunityLineItem oli = TestData.getTestOptyLine(opp.Id, pbe.Id);
    insert oli;
    
    opp.StageName = 'Closed Processing';
    update opp;
        
    Test.startTest();
      List<Fulfillment_Status__c> fsItems = [SELECT Id, Status__c, Amount__c FROM Fulfillment_Status__c WHERE Opportunity__c = :opp.Id];
      System.assertEquals(fsItems.size(), 2);
      
      Fulfillment_Status__c fs = fsItems.get(0);
      emq_CloseWinByLineItem controller = new emq_CloseWinByLineItem(new ApexPages.StandardController(fs));
      controller.item = fsItems.get(0);
      controller.item.Status__c = 'Scheduled';
      controller.save();
 
     fs = [SELECT Id, Status__c FROM Fulfillment_Status__c WHERE Id = :fs.Id];
      System.assertEquals(fs.Status__c, 'Scheduled');
      Test.stopTest();      
    }
}