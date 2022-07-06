/*
* Mimeo Document Trigger Handler Test
* Created: PC K2 (June 2020)
*
* changelog 
*/

@isTest public class MimeoDocumentTriggerHandlerTest {

    @isTest static void handleMimeoDocumentsTest_noCourse(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Test.startTest();
            Mimeo_Document__c doc = new Mimeo_Document__c(Name = 'null test');
            insert doc;
        Test.stopTest();
        
        doc = [SELECT Asset_Id__c FROM Mimeo_Document__c WHERE Id = :doc.Id];
        System.assert(doc.Asset_Id__c == null);
    }

    @isTest static void handleMimeoDocumentsTest_insert(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Product2 product = new Product2(Name = 'test', I_codes_Required__c = 'Icode1,Icode2', Course_Duration_Days__c = 1, ProductArea__c = 'Training', IsActive = true, Training_Taxonomy_Code__c = 'testUK', CurrencyIsoCode = bg_Globals.CURRENCY_CODE_USD);
        insert product;

        Test.startTest();
            Mimeo_Document__c doc = new Mimeo_Document__c(Name = 'test', Course__c = product.Id);
            insert doc;
        Test.stopTest();
        
        doc = [SELECT Asset_Id__c FROM Mimeo_Document__c WHERE Id = :doc.Id];
        System.assert(doc.Asset_Id__c != null);
    }

    @isTest static void handleMimeoDocumentsTest_update(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Product2 product = new Product2(Name = 'test', I_codes_Required__c = 'Icode1,Icode2', Course_Duration_Days__c = 1, ProductArea__c = 'Training', IsActive = true, Training_Taxonomy_Code__c = 'testUK', CurrencyIsoCode = bg_Globals.CURRENCY_CODE_USD);
        insert product;

        MimeoDocumentTriggerHandler.isHandleMimeoDocumentsFirstRun = false;
        Mimeo_Document__c doc = new Mimeo_Document__c(Name = 'test', Course__c = product.Id, Active__c = false);
        insert doc;

        doc = [SELECT Asset_Id__c FROM Mimeo_Document__c WHERE Id = :doc.Id];
        System.assert(doc.Asset_Id__c == null);

        Test.startTest();
            MimeoDocumentTriggerHandler.isHandleMimeoDocumentsFirstRun = true;
            doc.Active__c = true;
            update doc;
        Test.stopTest();
        
        doc = [SELECT Asset_Id__c FROM Mimeo_Document__c WHERE Id = :doc.Id];
        System.assert(doc.Asset_Id__c != null);
    }
}