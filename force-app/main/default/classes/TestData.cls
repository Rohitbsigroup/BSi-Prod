/**
*
* Author:       Carmine Barbuto
* Company:      Tquila
* Date:         09/11/2011
* Description:  Utility class for Test Classes. This class contains some methods 
*               to easily retrieve test data sample with all the required field
*               already filled. 
*
*          RJ 01-06-2014 Added new method getTestSalesUser to use BSI Salesperson profile      
*          RJ 01-08-2015 Added lead fields to rating and stream to lead
*          RJ 04-08-2015 Added recordtypeId to product2 creation
*          ADS 06/11/2017 Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
*          ADS 05/12/2017 Updates for new Validation Rule "Americas Customer Type Should Be Populated" on Opportunity
**/
public class TestData {
    
    public static Account getTestAccount() {
        Account acc     = new Account();
        acc.Name        = 'Tquila Test' + DateTime.now().getTime() + Integer.valueof((Math.random() * 100));
        acc.Industry    = 'Test';
        acc.TCodeDescr__c = 'Test';
        acc.BillingCountry = 'GB';
        acc.BillingStreet  = '20 Test Street';
        acc.BillingCity = 'Test City';
        
        return acc;
    }
    
    public static Contact getTestContact() {
        Contact con     = new Contact();
        con.FirstName   = 'Tquila';
        con.LastName    = 'Test';
        con.MailingCountry = 'GB';
        con.Email       = 'test@bisimailtest.com';
        
        return con;
    }
    
    public static Lead getTestLead() {
        return getTestLead('test');
    }
    public static Lead getTestLead(String name) {
        Lead lead       = new Lead();
        lead.FirstName  = 'Tquila';
        lead.LastName   = name;
        lead.Phone      = '079499999';
        lead.Email      = name + '@tquilatest.com';
        lead.Company    = 'Tquila Test';
        lead.Industry   = 'Test';
        lead.Country    = 'GB';
        lead.Postalcode = 'EC3NDS';

        // Validation rule required fields
        lead.Delivery__c        = Date.today();
        lead.TotalEmployees__c  = 20;
        lead.SitesNumber__c     = 20;
        lead.Email              = 'email@test.com';
        lead.TCodeDescr__c      = 'Test';
        lead.PortfolioInterestArea__c = 'Test';
        lead.Portfolio_Interests__c = 'Test';
        lead.PrevCustomer__c = 'No';
        lead.Product_Area_Interests__c = 'Test';
        lead.Position__c = 'Test';
        lead.RegistrationPath__c = 'New Registration';
        lead.Product_SubStream__c = 'Test';
        lead.Conversion_Check__c = false;
        lead.Lead_Rating__c = 'Leads';
        lead.Product_Stream__c = 'Test';
        return lead;    
    }
    
    public static Opportunity getTestOpty() {
        Opportunity opty    = new Opportunity();
        opty.Name           = 'Tquila Test';
        opty.CloseDate      = Date.today() + 20;
        opty.StageName      = 'Draft';
        opty.BusinessDrivers__c = 'New Customer';
        
        return opty;
    }
    
    public static OpportunityLineItem getTestOptyLine(Id opty, Id pbe) {
        OpportunityLineItem ol  = new OpportunityLineItem();
        ol.OpportunityId        = opty;
        ol.PricebookEntryId     = pbe;
        ol.Quantity             = 2;
        ol.UnitPrice            = 2;
        
        return ol;
    }
    
    public static Task getTestTask() {
        Task task           = new Task();
        task.ActivityDate   = Date.today();
        task.Subject        = 'Test';
        task.Status         = 'Not Started';    
        
        return task;
    }
    
    public static Event getTestEvent() {
        Event event             = new Event();
        event.ActivityDateTime  = Date.today();
        event.DurationInMinutes = 200;
        event.Subject           = 'Test';
        event.MeetingStatus__c  = 'Not Started';    
        
        return event;
    }
    
    public static Site__c getTestSite(String postcode) {
        Site__c site        = new Site__c();
        site.Name           = 'Test';
        site.Street__c      = 'Test Street';
        site.Postcode__c    = postcode;
        site.Industry__c    = 'Test';
        site.TCodeDescr__c  = 'Test';
        site.Country__c     = 'GB';
        site.Type__c    = 'Test Site Type';     
        return site;
    }
    public static Site__c getTestSite() {
        return getTestSite('EC29EX');
    }
    
    public static Product2 getTestProduct() {
        Product2 prod       = new Product2();
        prod.IsActive       = true;
        prod.ProductCode    = '0200';
        prod.Name           = 'Test';
        prod.RecordTypeId   = bg_RecordTypeUtils.GetRecordTypes('Product2').get('Product_Part').Id;     
        return prod;
    }
    
    public static Territory__c getTestTerritory(String country,String postcode) {
        Territory__c terr   = new Territory__c();
        terr.Name           = 'Test';
        terr.Region__c      = 'EMEA';
        if (country != '')  terr.Country__c     = country;
        if (postcode != '')     terr.PostZipCode__c = 'TT,TS,' + postcode + ',SS';
        
        return terr;
    }
    
    public static PricebookEntry getTestPriceBookEntry(Id prodID, Id pricebookID) {
        PricebookEntry pbe  = new PricebookEntry();
        pbe.Product2Id      = prodID;
        pbe.Pricebook2Id    = pricebookID;
        pbe.IsActive        = true;
        // 06/11/2017 ADS   - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
        // pbe.UnitPrice        = 2;
        pbe.UnitPrice = 0.0;
        
        return pbe;
    }
    
    public static Pricebook2 getPriceBook() {
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
        
        return pb;
    }
    
    public static Quote__c getTestQuote(String optyId, String contactId, String accountId) {
        Quote__c quote = new Quote__c();
        quote.Opportunity_Name__c = optyId;
        quote.Contact__c = contactId;
        quote.Account__c = accountId;
        
        return quote;
    }
    
    public static User getTestStandardUser(String profileName) {
        return getTestStandardUser('standarduser', profileName);
    }

    public static User getTestSalesUser() {
        return getTestStandardUser('standarduser', bg_UserUtils.PROFILE_NAME_BSI_SALESPERSON);
    }

    public static User getTestStandardUser(String name, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName]; 
        User user = new User(Alias = name.substring(0,3), 
        Email=name+string.valueOf(system.currentTimeMillis())+'@bsissos.testuser.com', 
        EmailEncodingKey='UTF-8', 
        LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', 
        ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', 
        UserName=name+string.valueOf(system.currentTimeMillis())+'@bsissos.testuser.com');
        user.BusinessHours__c = 'London';
        user.OperationCountry__c = 'GB';
        
        return user;    
    }
    
    // CUSTOM SETTINGS FOR CLASSES WITH API 24 --> ALL TEST CLASSES SHOULD BE API 24 AT SOME POINT
    public static SiteSetting__c getSiteSetting() {
        SiteSetting__c s = new SiteSetting__c();
        s.HQLabel__c = 'HQ';
        
        return s;   
    }
    
    public static ConversionScore__c getCountryDefault() {
        ConversionScore__c s = new ConversionScore__c();
        s.CountrySalesAdminEmail__c = 'test@test.test';
        s.SLAHours__c = 12;
        s.SLAHoursWarning__c = 9;
        s.Name = 'GB';
        
        return s;   
    }

    /**
     * To construct a number of User records
     *
     * @param contact related Contact record (Community Contact)
     *
     * @param isInsert true to insert records, else false
     *
     * @return list of User records
     */
    public static List<User> createPortalUsers(List<Contact> contacts, Boolean isInsert) {

        Id profileId = [SELECT Id FROM Profile WHERE Name = :Label.BSIUserSettings_ProfileNameDelegate LIMIT 1].Id;

        List<User> users = new List<User>();

        for(Contact contact : contacts) {
            users.add(
                    new User(
                            ProfileId = profileId,
                            LastName = contact.LastName,
                            FirstName = contact.FirstName,
                            Email = contact.Email.toLowerCase(),
                            ContactId = contact.Id,
                            EmailEncodingKey=Label.BSIUserSettings_EmailEncodingKey,
                            Alias = String.valueOf(contact.FirstName.substring(0,1) + contact.LastName.substring(0,1)),
                            Username = contact.Email + '.username',
                            TimeZoneSidKey='GMT',
                            LocaleSidKey='en_GB',
                            Phone = contact.Phone,
                            LanguageLocaleKey='en_US', 
                            Portal_User_Country__c = 'UK'
                    )
            );
        } 
        if (isInsert) {
            insert users;
        }
        return users;
    }
    
    /**
     * To construct a number of User records
     *
     * @param contact related Contact record (Community Contact)
     *
     * @param isInsert true to insert records, else false
     *
     * @return list of User records
     */
    public static List<User> createPortalUsersTutors(List<Contact> contacts, Boolean isInsert) {

        Id profileId = [SELECT Id FROM Profile WHERE Name = :Label.BSIUserSettings_ProfileNameTutor LIMIT 1].Id;

        List<User> users = new List<User>();

        for(Contact contact : contacts) {
            users.add(
                    new User(
                            ProfileId = profileId,
                            LastName = contact.LastName,
                            FirstName = contact.FirstName,
                            Email = contact.Email.toLowerCase(),
                            ContactId = contact.Id,
                            EmailEncodingKey=Label.BSIUserSettings_EmailEncodingKey,
                            Alias = String.valueOf(contact.FirstName.substring(0,1) + contact.LastName.substring(0,1)),
                            Username = contact.Email + '.username',
                            TimeZoneSidKey='GMT',
                            LocaleSidKey='en_GB',
                            Phone = contact.Phone,
                            LanguageLocaleKey='en_GB',
                            Portal_User_Country__c = 'UK'
                    )
            );
        }
        if (isInsert) {
            insert users;
        }
        return users;
    }
}