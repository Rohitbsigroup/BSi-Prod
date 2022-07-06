/*****************************************************************************************************************************************************
Class Name: emq_CIFRequestControllerTest
Description: TestClass for emq_CIFRequestController
Created Date: 22/09/2021
******************************************************************************************************************************************************/

@isTest
public with sharing class emq_CIFRequestControllerTest {
    
    public static testmethod void testPostCallout() {
        
        Account acc = TestData.getTestAccount();  
        acc.BillingCountry = 'GA';
        insert acc;
        
        Account acc1 = new Account();
        acc1.BillingCity = 'Test city';
        acc1.BillingCountry = 'CN';
        acc1.Name = 'Test Acc';
        acc1.BillingState = 'Test State';
        acc1.BillingPostalCode ='60091';
        acc1.BillingStreet = 'Street';
        insert acc1;
        
        Contact con     = new Contact();
        con.FirstName   = 'Contact';
        con.LastName    = 'Test';
        con.MailingCountry = 'IN';
        con.Email       = 'test@bisimailtest.com';
        insert con;
        
        Contact priCon     = new Contact();
        priCon.FirstName   = 'Contact';
        priCon.LastName    = 'Test';
        priCon.MailingCountry = 'IN';
        priCon.Email       = 'test@bisimailtest.com';
        insert priCon;
        
        Opportunity opty    = new Opportunity();
        opty.Name           = 'Test Opp';
        opty.CloseDate      = Date.today() + 20;
        opty.BusinessDrivers__c = 'New Customer';
        opty.ContactId = con.Id;
        opty.AccountId = acc.Id;
        opty.StageName = 'Sales Engaged';
        opty.PrimaryContact__c = priCon.id;
        insert opty;
        
        Opportunity opty1    = new Opportunity();
        opty1.Name           = 'Test Opp';
        opty1.CloseDate      = Date.today() + 20;
        opty1.BusinessDrivers__c = 'New Customer';
        opty1.ContactId = con.Id;
        opty1.AccountId = acc1.Id;
        opty1.StageName = 'Sales Engaged';
        opty1.PrimaryContact__c = priCon.id;
        insert opty1;
        
        
        
        ApexPages.StandardController sc = new  ApexPages.StandardController(opty);  
        emq_CIFRequestController ext = new emq_CIFRequestController(sc);  
        
        ApexPages.StandardController sc1 = new  ApexPages.StandardController(opty1);  
        emq_CIFRequestController ext1 = new emq_CIFRequestController(sc1); 
        
        PageReference pageRef = Page.cifRequestPage;
        pageRef.getParameters().put('id', String.valueOf(opty.Id));
        Test.setMock(HttpCalloutMock.class, new CIFRequestMock());
        Test.setCurrentPage(pageRef);  
        
        SystemSetting__c ss = new SystemSetting__c();      
        ss.Appian_APIKey__c = 'XXSSSSS';
        ss.Appian_URL__c = 'https://test.appian-test.com';
        ss.Appian_Contact_URL__c = 'https://test.appian-test.com';
        ss.Appian_Account_URL__c = 'https://test.appian-test.com';
        insert ss;
        
        integer countBefore = [SELECT COUNT() FROM CIFHistory__c WHERE Opportunity__c = :opty.Id];
        system.debug('countBefore-- '+countBefore);
        Test.startTest();
        ext1.Send();
        ext1.updateConButton();
        ext1.updateAccButton();
        ext.Cancel();
        ext.Send();
        
        
      

        Test.stopTest();        
        
        integer countAfter = [SELECT COUNT() FROM CIFHistory__c WHERE Opportunity__c = :opty.Id];   
        system.debug('countAfter-- '+countAfter);
        System.assertEquals(countBefore+1, countAfter);
    }
    
    public class CIFRequestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"stage":"Sales Engaged","opportunityOwnerUpn":null,"opportunityNumber":"BSI 0000847496","opportunityName":"Test Opp","opportunityId":"+opty.Id+","needByDate":"2021-10-4","contacts":[{"phone":null,"mobilePhone":null,"lastName":null,"firstName":null,"email":null,"contactType":null,"contactId":null}],"account":{"website":null,"postalCode":null,"billingState":null,"billingCountryCode":"NL","billingCountry":"Netherlands (the)","billingCity":null,"addressLine1":null,"accountName":"NEW ACCT NOV EIGT","accountId":"+acc.Id+"}}');
            response.setStatusCode(200);
            if(response.getStatusCode() == 200){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm, 'Please contact your administrator.'));
            }
            return response; 
        }
    }   
    }