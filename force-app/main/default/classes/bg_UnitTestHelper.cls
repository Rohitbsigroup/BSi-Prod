/********************************************************************
 * bg_UnitTestHelper
 *
 * Methods to support tests
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 29-09-2014 ASD BG - Added methods for conga tempaltes, tempalte queries.
 *          20-11-2014 KM BG  - Added methods for events, notes etc.
 *          07-01-2105 AL BG  - Added methods for training bookings and enrolments. 
 *                              Improvement to existing training booking methods.
 *          03-02-2015 KM BG -  Added method for OLI 
 *          20-04-2015 KM BG - Added BSI Permissions Custom Setting
 *          05-05-2015 KM BG - Added Create methods for account and quote
 *          15-01-2016 ASD   - Fixed Unit Tests to suit VR rules and WFRs (too many SOQLS) added inMemory Creators
 *          22-02-2016 cp    - SetupTrainingBookingController() added to create a working TrainingBookingController()
 *          23-05-2016 JT BG - Added GetTemplate, GetQuery, GetQueries, GetTemplateQuery and GetTemplateQueries methods
 *          31/08/2017 ADS   - Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 *          04/09/2017 CPE   - New method GetPermissionSetAssignment for getting a new PermissionSetAssignment
 *          05/09/2017 CPE   - New methods for CreateProductClassification and CreateProduct for creating in memory records only
 *                             New methods for CreateProjects
 *          12/09/2017 RC    - New method for GetPricebook and CreatePriceBook, CreateAccountBulk
 *          06/11/2017 ADS   - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
 *          05/12/2017 ADS   - Updates for new Validation Rule "Americas Customer Type Should Be Populated" on Opportunity
 *          12/02/2018 ADS   - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
 *          02/03/2018 ADS   - Fix Unit Test for new restricted Picklist Presentation Group on Product Classification
 ********************************************************************/
@isTest
public class bg_UnitTestHelper {
    public static final string UT_TCODE_MANUFACTURING = 'MANUFACTURING';
    public static final string UT_SITE_POSTCODE = 'SW1 8UY';
    public static final string TEMPLATE_TYPE = 'Document';
    public static final string TEMPLATE_CURRENCY = 'GBP';
    public static final string COUNTRY = 'GB';
    
    //public static final string UT_ProductToPropertyGuid = '96BEEBB6-9EB7-4561-9A48-92B117829781';
    //public static final string UT_QuoteToProductGuid    = '95CEEBB6-9EB7-4561-9A48-92B117829781';

    public static Account GetAccount() {
        return GetAccount('Test Account');
    }

    public static Account GetAccount(string name) {
        /*
            Return Account
        */
        Account acc = CreateAccount(name);
        insert acc;
        return acc;
    }
    
    public static Account CreateAccount() {
        return CreateAccount('Test Account');
    }
    
    public static Account CreateAccount(String name) {
        GetSiteSettings();
        Account acc = new Account();
        acc.Name = name;
        acc.BillingCountry = bg_SiteUtils.COUNTRY_CODE_US;
        acc.BillingStreet = '123 Billing Street';
        acc.BillingCity = 'Billing City';
        return acc;
        
    }

    public static List<Account> CreateAccountBulk(Integer num)
    {
        List<Account> accList = new List<Account>();

        for(Integer i=0; i<num; i++)
        {
            Account acc = new Account();
            acc.Name = 'test ' + num;
            acc.BillingCountry = bg_SiteUtils.COUNTRY_CODE_US;
            acc.BillingStreet = '123 Billing Street';
            acc.BillingCity = 'Billing City';
            accList.add(acc);
        }
        return accList;
    }
    
    public static Note GetNote(Id parentId){
        /*
            Return Note
        */
        return GetNote(parentId, 'test body', 'test title');
    }
    
    public static Note GetNote(Id parentId, String body, String title){
        /*
            Return note
        */
        Note note = new Note();
        note.ParentId = parentId;
        note.Body = body;
        note.Title = title;
        insert note;
        return note;
    }
    
    public static Task GetTask(Id parentId){
        Task task = new Task(
            ActivityDate = Date.today().addDays(7),
            Subject='Sample Task',
            WhatId = parentId,
            Status='In Progress');
        
        insert task;
        return task;
    }
    
    public static Event GetEvent(Id parentId){
        Event e = new Event (
                DurationInMinutes = 50,
                ActivityDateTime = system.now(),
                WhatId = parentId); 
        
        insert e;
        return e;
    }
    

    public static Contact_Opportunity__c GetContactOpportunity(Id oppId, Id contactId){
        return GetContactOpportunity(oppId, contactId, 'Test');
    }

    public static Contact_Opportunity__c GetContactOpportunity(Id oppId, Id contactId, String role){
        Contact_Opportunity__c contactOpp = new Contact_Opportunity__c();
        contactOpp.Opportunity__c = oppId;
        contactOpp.Contact__c = contactId;
        contactOpp.OppRole__c = role;
        
        insert contactOpp;
        return contactOpp;
    }
    
    public static Contact CreateContact(String name, Account acc)
    {
        Contact con = new Contact();
        con.FirstName = 'UT';
        con.LastName = name;
        con.MailingCountry = bg_SiteUtils.COUNTRY_CODE_US;
        con.OtherCountry = 'SG'; /* JS added for new VR on contact for other country*/ 
        con.Email = 'email@email.com';
        con.RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_CONTACT).get(bg_ContactUtils.RECORD_TYPE_NAME_CLIENTS).Id;
        if(acc != null) { con.AccountId = acc.Id; }
        return con;
    }

    public static Contact GetContact(string name) {
        /* Return Contact */
        return GetContact(name, null);
    }
    
    public static Contact GetContact(string name, Account acc) {
        /* 
            Return Contact 
        */
        Contact con = CreateContact(name, acc);
        con.OtherCountry = 'UK';
        insert con;
        return con;
    }


    public static Opportunity GetOpportunity() {
        /* Return Opportunity */        
        return GetOpportunity(null);
    }

    public static Opportunity GetOpportunity(Account acc) {
        /*
            Return Opportunity
        */
        return GetOpportunity(acc, '');
    }

    public static Opportunity GetOpportunity(Account acc, string productInterest) {
        /*
            Return Opportunity
        */
        Opportunity opp = CreateOpportunity(acc, productInterest);
        insert opp;
        return opp;
    }
    
    public static Opportunity CreateOpportunity() {
        /* Return Opportunity */        
        return CreateOpportunity(null);
    }
    
    public static Opportunity CreateOpportunity(Account acc) {
        /* Return Opportunity */
        return CreateOpportunity(acc, '');
    }
    
    public static Opportunity CreateOpportunity(Account acc, string productInterest) {
        /*
            Return New Opportunity
        */      
        Opportunity opp = new Opportunity();
        opp.Name = 'UT-OPP-TEST';
        opp.StageName = 'Sales Engaged';
        opp.CloseDate = date.today();
        opp.Product_Interests__c = productInterest;
        opp.BusinessDrivers__c = 'New Customer';
        //opp.CurrencyIsoCode = bg_Globals.CURRENCY_CODE_USD;
        if(acc != null) { opp.AccountId = acc.Id; }
        return opp;
    }
    
    public static OpportunityLineItem GetOpportunityLineItem(Opportunity opp, PricebookEntry pbe) {
        OpportunityLineItem oli = CreateOpportunityLineItem(opp, pbe);
        insert oli;
        return oli;
    }
    
    public static OpportunityLineItem CreateOpportunityLineItem(Opportunity opp, PricebookEntry pbe) {
        /*
            Return new OLI
        */
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.id;
        oli.PricebookEntryId = pbe.id;
        oli.Quantity = 50;
        oli.TotalPrice = 100;
        return oli;
    }

    public static Quote__c GetQuote() {
        /* Return Quote */
        return GetQuote(null, null);
    }
    
    public static Quote__c GetQuote(Opportunity opp) {
        /* Return Quote */
        return GetQuote(opp, null);
    }
    
    public static Quote__c GetQuote(Opportunity opp, Contact con) {
        /*
            Return Quote
        */
        Quote__c quote = CreateQuote(opp, con);        
        insert quote;
        return quote;
    }
    
    public static Quote__c CreateQuote() {
        /* Return Quote */
        return CreateQuote(null, null);
    }
    
    public static Quote__c CreateQuote(Opportunity opp) {
        /* Return Quote */
        return CreateQuote(opp, null);
    }
    
    public static Quote__c CreateQuote(Opportunity opp, Contact con) {
        /*
            Return Quote
        */
        Quote__c quote = new Quote__c();
        if(opp != null) 
        { 
            quote.Opportunity_Name__c = opp.Id; 
            if(opp.CurrencyIsoCode != null)
            {   
                quote.CurrencyIsoCode = opp.CurrencyIsoCode;
            }else { 
                opp.CurrencyIsoCode = 'GBP';
                quote.CurrencyIsoCode = 'GBP';
            }
        }
        if(con != null) { 
            quote.Contact__c = con.Id;
            quote.Booking__c = con.Id;
            quote.CreditCheck__c = con.Id;
            quote.Invoice_Contact__c = con.Id; 
        }
        quote.PriceBook2Id__c = bg_PricebookUtils.GetUserDefaultPricebook().Id;
        quote.Configuration_Completed__c = false;            
        return quote;
    }
    
    public static Quote_Product__c GetQuoteProduct(Quote__c quote, Contact primaryContact) {
        /* Return Quote Product */
        return GetQuoteProduct(quote, primaryContact, null);
    }

    public static Quote_Product__c GetQuoteProduct(Quote__c quote, Contact primaryContact, Product__c product) {
        /* Return Quote Product */
        return GetQuoteProduct(quote, primaryContact, product, null);           
    }
    
    public static Quote_Product__c GetQuoteProduct(Quote__c quote, Contact primaryContact, Product__c product, Site__c site) {
        /* Return Quote Product */
        return GetQuoteProduct(quote, primaryContact, product, site, null);  
    }

    public static Quote_Product__c GetQuoteProduct(Quote__c quote, Contact primaryContact, Product__c product, Site__c site, Opportunity opp) {
        /* Return Quote Product */
        return GetQuoteProduct(quote, primaryContact, product, site, opp, null);  
    }
    
    public static Quote_Product__c GetQuoteProduct(Quote__c quote, Contact primaryContact, Product__c product, Site__c site, Opportunity opp, OpportunitySite__c oppSite) {
        /*
            Return Quote Product
        */
        Quote_Product__c quoteProduct = CreateQuoteProduct(quote, primaryContact, product, site, opp, oppSite);
        insert quoteProduct;
        return quoteProduct;
    }

    /*
        Return Quote Product in memory
    */
    public static Quote_Product__c CreateQuoteProduct(Quote__c quote, Contact primaryContact, Product__c product, Site__c site, Opportunity opp, OpportunitySite__c oppSite) {
        Pricebook2 pb = bg_PricebookUtils.GetUserDefaultPricebook();
        
        Quote_Product__c quoteProduct = new Quote_Product__c();
        quoteProduct.Quote_Ref__c = quote.Id;
        quoteProduct.Price_Book_Name__c = pb.Name;
        quoteProduct.Price_Book__c = pb.Id;
        quoteProduct.Selected__c = true;

        if(primaryContact != null) { 
            quoteProduct.Primary_Contact__c = primaryContact.Id;
            quoteProduct.Primary_Contact__r = primaryContact;
        }
        if(product != null) {
            quoteProduct.Product_Name__c = product.Id;
            quoteProduct.Product_Name__r = product;
        }
        
        if(opp == null) {
            opp = GetOpportunity();
        }
        
        if(site == null) {
            Account acc = GetAccount('UT-TEST_ACCOUNT');
            site = GetSite(acc, 'TEST-SITE','US');
        }
        
        if(oppSite == null) {
            oppSite = GetOpportunitySite(opp, site);
        }
        
        quoteProduct.Site__c = site.Id;
        quoteProduct.Site__r = site;
        quoteProduct.Opportunity_Site__c = oppSite.Id;
        quoteProduct.Instance__c = 1;
        
        return quoteProduct;
    }
    
    public static Quote_Part__c GetQuotePart(Id quoteId, Product__c product, decimal price, boolean isQuestion) {
        return GetQuotePart(quoteId, product, price, isQuestion, null);
    }
    
    public static Quote_Part__c GetQuotePart(Id quoteId, Product__c product, decimal price, boolean isQuestion, Quote_Product__c quoteProduct) {
        /*
            Return Quote Part
        */
        Quote_Part__c quotePart = CreateQuotePart(quoteId, product, price, isQuestion, quoteProduct);

        insert quotePart;
        return quotePart;
    }

    public static Quote_Part__c CreateQuotePart(Id quoteId, Product__c product, decimal price, boolean isQuestion, Quote_Product__c quoteProduct) {
        /*
            Return Quote Part
        */
        Quote_Part__c quotePart = new Quote_Part__c();
        quotePart.Quote_Ref__c = quoteId;

        if(isQuestion) {
            string productName = product.Name;
            if(productName.endsWith(bg_ProductUtils.QUESTION_PRODUCT_POSTFIX)) { productName = productName.left(productName.length()-1); }      
            string productNameNoSpaces = bg_StringUtils.RemoveSpaces(productName);
            quotePart.Description__c = 'ANS-' + productNameNoSpaces + '-CanSample';
            quotePart.Customer_Code__c = ' - ' + productNameNoSpaces + bg_ProductUtils.QUESTION_PRODUCT_POSTFIX + ' - ';
        } else {
             quotePart.Customer_Code__c = ' - ' + product.Name + ' - ';
        }
        quotePart.Price__c = price;
        if(quoteProduct != null) {
            quotePart.Quote_Product__c = quoteProduct.Id;
            quotePart.Product2__c = quoteProduct.Product2__c;
        }
        return quotePart;
    }
    
    public static Part_Extended_Value__c GetPartExtendedValue(Id pricebookId, Id productId) {
        /*
            Return Part Extended Value
        */
        Part_Extended_Value__c pev = new Part_Extended_Value__c();
        pev.Price_Book__c = pricebookId;
        pev.Product__c = productId;
        insert pev;
        return pev;
    }
    
    public static Product2 GetProductFee(string name) {
        /*
            Return Product Fee
        */
        Product2 prod = CreateProductFee(name);
        insert prod;
        return prod;
    }
    
    public static Product2 CreateProductFee(string name) 
    {
        Product2 prod = new Product2();
        prod.Name = name;
        prod.CurrencyIsoCode = bg_Globals.CURRENCY_CODE_USD;
        //prod.
        prod.IsActive = true;
        return prod;
        
    }
    
    public static Quote_Product_Approval__c GetQuoteProductApproval(Quote_Product__c qp) {
        /*
            Return Quote Product Approval
        */
        Quote_Product_Approval__c qpa = new Quote_Product_Approval__c();
        qpa.Quote__c = qp.Quote_Ref__c;
        qpa.Product__c = qp.Product_Name__c;
        insert qpa;
        return qpa;
    }
    
    public static Lead GetLead() {
        /*
            Return Lead
        */
        return GetLead('test');
    }
    
        
    public static Site__c GetSite(Account acc, string name, string countryCode) {
        /* Return Site */       
        return GetSite(acc, name, countryCode, bg_SiteUtils.RECORD_TYPE_NAME_NAMED);
    }

    public static Site__c GetSite(Account acc, string name, string countryCode, string siteRTName) {
        /* Return Site */       
        return GetSite(acc, name, countryCode, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, UT_SITE_POSTCODE);  
    }
    

    public static Site__c GetSite(Account acc, string name, string countryCode, string siteRTName, string postCode) {
        /*
            Return Site
        */

        // Create country code lookup record for validation to work
        //CreateCountryCodeLookup(countryCode);
        GetSiteSettings();
        
        Site__c site = new Site__c();
        site.name = name;
        site.Account__c = acc.Id;
        site.Country__c = countryCode;
        site.Country_Code__c = countryCode;
        site.Type__c = UT_TCODE_MANUFACTURING;
        site.TCodeDescr__c = UT_TCODE_MANUFACTURING;
        site.Postcode__c = postCode;
        System.debug('++++ Site RT keys = ' + bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_SITE).keySet());
        System.debug('+++ siteRTName = ' + siteRTName);
        site.RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_SITE).get(siteRTName).Id;
        insert site;
        return site;
    }
    
    public static Site__c CreateSite(Account acc, string name, string countryCode, string siteRTName, string postCode) {
        /*
            Return Site
        */

        // Create country code lookup record for validation to work
        //CreateCountryCodeLookup(countryCode);
        GetSiteSettings();
        
        Site__c site = new Site__c();
        site.name = name;
        site.Account__c = acc.Id;
        site.Country__c = countryCode;
        site.Country_Code__c = countryCode;
        site.Type__c = UT_TCODE_MANUFACTURING;
        site.TCodeDescr__c = UT_TCODE_MANUFACTURING;
        site.Postcode__c = postCode;
        site.RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_SITE).get(siteRTName).Id;
        return site;
    }
/*
    private static set<string> countryCodes;
    private static void CreateCountryCodeLookup(string countryCode) {
        / *
            Create Country Code Lookup
        * /
        if(countryCodes == null) { countryCodes = new set<string>(); }
        if(!countryCodes.contains(countryCode)) {
            // Insert Country Code
            CountryCodeLookup__c ccl = new CountryCodeLookup__c();
            ccl.Name = countryCode;
            insert ccl;
            countryCodes.add(countryCode);
        }   
    }
*/  
    public static OpportunitySite__c GetOpportunitySite(Opportunity opp, Site__c site) {
        /* Return Opportunity Site */
        return GetOpportunitySite(opp, site, false);
    }
        
    public static OpportunitySite__c GetOpportunitySite(Opportunity opp, Site__c site, boolean isHQ) {
        /*
            Return Opportunity Site
        */
        OpportunitySite__c oppSite = new OpportunitySite__c();
        oppSite.Opportunity__c = opp.Id;
        oppSite.Site__c = site.Id;
        oppSite.Site__r = site;
        oppSite.HQ__c = isHQ;
        insert oppSite;
        return oppSite;
    }
    
    public static OpportunitySite__c CreateOpportunitySite(Opportunity opp, Site__c site) {
        /* Return Opportunity Site */
        return CreateOpportunitySite(opp, site, false);
    }
        
    public static OpportunitySite__c CreateOpportunitySite(Opportunity opp, Site__c site, boolean isHQ) {
        /*
            Return Opportunity Site
        */
        OpportunitySite__c oppSite = new OpportunitySite__c();
        oppSite.Opportunity__c = opp.Id;
        oppSite.Site__c = site.Id;
        oppSite.Site__r = site;
        oppSite.HQ__c = isHQ;
        return oppSite;
    }

    public static ContactSite__c GetSiteContact(Site__c site, Contact con, string role) {
        /*
            Return Site Contact
        */
        ContactSite__c conSite = new ContactSite__c();
        conSite.Site__c = site.Id;
        conSite.Site__r = site;
        conSite.Contact__r = con;
        conSite.Contact__c = con.Id;
        conSite.Contact_Role__c = role;
        insert conSite;
        return conSite;
    }

    public static Contact_Opportunity__c GetOpportunityContact(Opportunity opp, Contact con, string role) {
        /*
            Return Opportunity Contact
        */
        Contact_Opportunity__c oppCon = bg_ContactUtils.GetOpportunityContact(opp.Id, con.Id, role);
        insert oppCon;
        return oppCon;
    }

    public static Lead GetLead(string name) {
        /*
            Return Lead
        */      
        Lead lead = CreateLead(name);
        insert lead;
        return lead;    
    }
    
    public static Lead CreateLead(string name) {
        /*
            Return Lead
        */
        Lead lead = new Lead();
        lead.FirstName = 'UT';
        lead.LastName = name;
        lead.Phone = '079499999';
        lead.Email = name + '@ut-test.com';
        lead.Company = 'UT Test Ltd';
        lead.Industry = 'Test';
        lead.Country = bg_SiteUtils.COUNTRY_CODE_UK;
        lead.Postalcode = 'TE1 4ST';
        // Validation rule required fields
        lead.Delivery__c = Date.today();
        lead.TotalEmployees__c = 20;
        lead.SitesNumber__c = 20;
        lead.Email = 'email@test.com';
        lead.TCodeDescr__c = 'Test';
        lead.LeadSource = 'Marketing Channels';
        lead.PortfolioInterestArea__c = 'Test';
        lead.Conversion_Check__c = false;
        lead.Lead_Rating__c = 'Leads';
        lead.Product_Stream__c = 'Test';
        return lead;
    }
    
    public static Product__c GetProduct(string name) {
        /* Return active product */
        return GetProduct(name, true);
    }
    
    public static Product__c GetProduct(string name, boolean active) {
        /* Return active product */
        return GetProduct(name, active, 'UT_PRODUCT_PORTFOLIO', 'UT_PRODUCT_AREA');
    }
    
    public static Product__c GetProduct(string name, boolean active, string portfolio, string productArea) {
        /* Return active product */
        return GetProduct(name, active, portfolio, productArea, bg_ProductUtils.PRODUCT_TYPE_MAIN); 
    }

    public static Product__c GetProduct(string name, boolean active, string portfolio, string productArea, set<string> countries) {
        /* Return active product */
        return GetProduct(name, active, portfolio, productArea, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries);
    }

    public static Product__c GetQuestionProduct(string name) {
        /* Return active product */
        return GetProduct(name + bg_ProductUtils.QUESTION_PRODUCT_POSTFIX, true, null, null, bg_ProductUtils.PRODUCT_TYPE_QUESTION, null);
    }
        
    public static Product__c GetProduct(string name, boolean active, string portfolio, string productArea, string productType) {
        /* Return active product */
        return GetProduct(name, active, portfolio, productArea, productType, null);
    }

    public static Product_Classification__c GetProductClassification2(string name, string stream, string portfolio, string productArea) { 
        /* Return Product Classification */
        return GetProductClassification(name, stream, null, portfolio, productArea, null);
    }
        
    public static Product_Classification__c GetProductClassification2(string name, string stream, string portfolio, string productArea, Product__c product) { 
        /* Return Product Classification */
        return GetProductClassification(name, stream, null, portfolio, productArea, product);    
    }

    public static Product_Classification__c GetProductClassification(string name, string stream, string substream, string portfolio, string productArea) { 
        /* Return Product Classification */
        return GetProductClassification(name, stream, substream, portfolio, productArea, null);
    }
    
    public static Product_Classification__c GetProductClassification(string name, string stream, string substream, string portfolio, string productArea, Product__c product) { 
        /* 
            Return Product Classification 
        */
        Product_Classification__c pc = CreateProductClassification(name, stream, substream, portfolio, productArea, product);
        insert pc;
        return pc;
    }

    public static Product_Classification__c CreateProductClassification(string name, string stream, string substream, string portfolio, string productArea, Product__c product) { 

        Product_Classification__c pc = new Product_Classification__c();
        pc.Product__c = name;
        pc.Stream2__c = stream;
        if(substream != null) { pc.SubStream__c = substream; }
        pc.Portfolio2__c = portfolio;
        pc.Family2__c = productArea;
        if(product != null) { pc.SF_Product__c = product.Id; }
        pc.PresentationGroup__c = 'Publications'; // 02/03/2018 - ADS - New restricted Picklist            
        return pc;
    }

    public static Product__c GetSiteProduct(string name) {
        /* Return Site Product */       
        return GetProduct(bg_ProductUtils.GetSiteProductName(name), true, null, null, bg_ProductUtils.PRODUCT_TYPE_SITE, null);
    }
            
    public static Product__c GetProduct(string name, boolean active, string portfolio, string productArea, string productType, set<string> countries) {
        /*
            Return product
        */      
        Product__c product = CreateProduct(name, active, portfolio, productArea, productType, countries, null);
        insert product;
        return product;
    }

    public static Product__c CreateProduct(string name, boolean active, string portfolio, string productArea, string productType, set<string> countries, Id classificationId)
    {
        Product__c product = new Product__c();
        product.name = name;
        product.Active__c = active;
        product.Product_Stream__c = 'stream';
        product.Product_SubStream__c = 'substream';
        product.Portfolio_Interest__c = portfolio;
        product.Product_Area_Interest__c = productArea;
        product.Active_In_SF__c = active;
        product.Product_Type__c = productType;
        product.CCode__c = 'C300';
        product.RegistrationPaths__c  = 'New Registation;ETS: New Site';
        if(countries != null) { product.Country__c = bg_StringUtils.ConvertToPicklistValue(countries); }
        product.Product_Classification__c = classificationId;
        return product;
    }

    public static Pricebook2 GetPricebook(string countryCode) {
        /*
            Return pricebook
        */
        return GetPricebook('UT-Pricebook', countryCode);
    }

    private static Pricebook2 globalPB;
     
    public static Pricebook2 GetGlobalPricebook() {
        /*
            Return global pricebook
        */
        if(globalPB == null) { 
            Pricebook2 pb = new Pricebook2();
            pb.Name = 'Global Price book';
            pb.IsGlobal__c = true;
            pb.AvailableForUse__c = false;
            pb.Products__c = 'ALL';
            pb.IsActive = true;
            insert pb;
            globalPB = pb;
        }
        return globalPB; 
   }
       
    public static Pricebook2 GetPricebook(string name, string countryCode) {
        /*
            Return pricebook
        */
        Pricebook2 pb = new Pricebook2();
        pb.Name = name;
        pb.Country_Code__c = countryCode;
        pb.Products__c = 'ALL';
        pb.IsActive = true;
        pb.AvailableForUse__c = true;
        pb.Year__c = string.valueOf(date.today().Year());
        insert pb;
        return pb;
    }

    public static Pricebook2 GetPricebook(string name, string countryCode, Id accountId, Id recordTypeId, Integer year) {
        /*
            Return pricebook
        */
        Pricebook2 pb = CreatePriceBook(name, countryCode, accountId, recordTypeId, year);
        insert pb;
        return pb;
    }

    public static Pricebook2 CreatePriceBook(string name, string countryCode, Id accountId, Id recordTypeId, Integer year)
    {
        /*
            Return pricebook
        */
        Pricebook2 pb = new Pricebook2();
        pb.Name = name;
        pb.Country_Code__c = countryCode;
        pb.Products__c = 'ALL';
        pb.IsActive = true;
        pb.AvailableForUse__c = true;
        pb.Year__c = string.valueOf(year);
        pb.Account__c = accountId;
        if(recordTypeId!=null)
        {
            pb.RecordTypeId = recordTypeId;
        }
        return pb;
    }
    
    public static PricebookEntry GetPricebookEntry(Id pricebookId, Id productId) {
        /* Get PricebookEntry */
        return GetPricebookEntry(pricebookId, productId, 'USD', 50.0);
    }

    public static PricebookEntry GetPricebookEntry(Id pricebookId, Id productId, string currencyCode, decimal unitPrice) {
        /*
            Get PricebookEntry
        */
        PricebookEntry pbe = CreatePricebookEntry(pricebookId, productId, currencyCode, unitPrice);
        insert pbe;                 
        return pbe;
    }

    public static PricebookEntry CreatePricebookEntry(Id pricebookId, Id productId, string currencyCode, decimal unitPrice) 
    {
        /*
            Get PricebookEntry
        */
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id = :productId AND CurrencyIsoCode = :currencyCode]; 
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pricebookId;
        pbe.Product2Id = productId;
        pbe.IsActive = true;
        pbe.CurrencyIsoCode = currencyCode;
        // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
        // pbe.UnitPrice = unitPrice;
        pbe.UnitPrice = 0.0;                    
        return pbe;
    }
    
    public static Pricebook2 GetStandardPricebook() {
        /*
            Get PricebookEntry
        */
        return [SELECT Id FROM Pricebook2 WHERE IsStandard = true];
    }
        
    public static Product_Bundle__c GetProductBundle(string name) 
    {
        /*
            Return active product bundle
        */
        Product_Bundle__c productbundle = new Product_Bundle__c();
        productbundle.name = name;
        productbundle.Active__c = true;
        insert productbundle;
        return productbundle;
    }
    
    public static Product_Relationship__c GetProductBundleRelationship(Product_Bundle__c bundle, Product__c prod1) {
        return GetProductRelationship(null, prod1, bg_ProductUtils.PRODUCT_RELATIONSHIP_TYPE_BUNDLE, bundle);
    }

    public static Product_Relationship__c GetProductRelationship(Product__c prod1, Product__c prod2, string relationshipType) {
        return GetProductRelationship(prod1, prod2, relationshipType, null);
    }
            
    public static Product_Relationship__c GetProductRelationship(Product__c prod1, Product__c prod2, string relationshipType, Product_Bundle__c bundle) {
        /*
            Return active product bundle
        */
        Product_Relationship__c productrelation = new Product_Relationship__c();
        productrelation.Active__c = true;
        if(prod1 != null) { productrelation.Product__c = prod1.Id; }
        productrelation.Related_Product__c = prod2.Id;
        productrelation.Type__c = relationshipType;
        if(bundle != null) { productrelation.Product_Bundle__c = bundle.Id; }
        insert productrelation;
        return productrelation;
    }
    
    public static void SetupCustomSettings() {
        /*
            Setup all custom settings       
        */
        GetLeadSetting();               // Setup Lead Setting
        GetActivitySetting();           // Setup Activity Setting
        GetDefaultCountrySetting();     // Setup Default Country Setting (US)
        GetQueueBusinessHours();        // Setup Queue Business Hours
        GetTerritory();                 // Setup Territory
        GetSiteSettings();              // Setup Site Settings
        GetBSIPermissionsSetting();     // Setup BSI Permissions Setting (with full permissions)
    }

    public static LeadSetting__c GetLeadSetting() {
        /*
            Setup lead settings     
        */
        LeadSetting__c cs = new LeadSetting__c();
        cs.FiveCalls__c = '5 Call Close';
        cs.StatusContacted__c = 'Open-Contacted';
        cs.StatusNotConverted__c = 'Closed-Not Converted';
        cs.ProcessedSF__c = 'Processed in current SFDC';
        cs.InsufficientDetailsReason__c = 'Insufficient Details Provided';
        cs.DuplicateReason__c = 'Duplicate';
        insert cs;
        return cs;
    }

    public static SystemSetting__c GetSystemSettings() {
        /*
            Setup System Settings     
        */
        SystemSetting__c cs = SystemSetting__c.getInstance(UserInfo.getUserId());                        
        if(cs == null) {                
            cs = new SystemSetting__c();
            cs.SkipValidationRule__c = true;
            cs.SkipSiteDupeCheck__c = true;
            cs.Conga_Server_URL__c = 'https://beta-www.appextremes.com/apps/Conga/PointMerge.aspx';
        }
        upsert cs;
        return cs;
    }
    
    public static BSIPermissions__c GetBSIPermissionsSetting() {
        /* Setup BSI Permissions */
        return GetBSIPermissionsSetting(true, true, true, true, true, true, true);
    }
    
    public static BSIPermissions__c GetBSIPermissionsSetting(Boolean canChangeLeadSources, Boolean canChangeOwnerForClosedOpps, Boolean canCloneClosedQuotes,
                                                            Boolean canEditPrices, Boolean canModifyOppProducts, Boolean closeWinOpps, Boolean recalcLeadSLATrigger) {
        /* Setup BSI Permissions */
        BSIPermissions__c permissions =  CreateBSIPermissionsSetting(canChangeLeadSources, canChangeOwnerForClosedOpps, canCloneClosedQuotes, 
                                                                    canEditPrices, canModifyOppProducts, closeWinOpps, recalcLeadSLATrigger);
        upsert permissions;
        return permissions;
    }
    
    public static BSIPermissions__c CreateBSIPermissionsSetting(Boolean canChangeLeadSources, Boolean canChangeOwnerForClosedOpps, Boolean canCloneClosedQuotes,
                                                            Boolean canEditPrices, Boolean canModifyOppProducts, Boolean closeWinOpps, Boolean recalcLeadSLATrigger) {
        /* Setup BSI Permissions */
        BSIPermissions__c permissions = BSIPermissions__c.getInstance();
        permissions.Can_Clone_Closed_Quotes__c = canCloneClosedQuotes;
        permissions.Can_Modify_Opp_Products__c = canModifyOppProducts;
        permissions.CanChangeLeadSources__c = canChangeLeadSources;
        permissions.CanEditPrices__c = canEditPrices;
        permissions.CloseWinOpportunities__c = closeWinOpps;
        permissions.RecalcLeadSLATrigger__c = recalcLeadSLATrigger;
        return permissions;
    }
    
    public static ConversionScore__c GetDefaultCountrySetting() {
        /* Setup default country settings - default to US*/
        return GetDefaultCountrySetting(bg_SiteUtils.COUNTRY_CODE_US);
    }

    public static ConversionScore__c GetDefaultCountrySetting(string countryCode) {
        /*
            Setup default country settings      
        */
        ConversionScore__c cs  = ConversionScore__c.getInstance(countryCode);                        
        if(cs == null) {
            cs = new ConversionScore__c();
            cs.name = countryCode;
        }

        cs.DefaultPriceBookName__c = GetPricebook(countryCode).Name;

        // Add discount levels
        cs.DiscountLevel1__c = 2.6;
        cs.DiscountLevel1User1__c = UserInfo.getUserId();
        cs.DiscountLevel2__c = 5.1;
        cs.DiscountLevel2User1__c = bg_QuoteApprovalUtils.DISCOUNT_LINE_MANAGER;
        cs.DiscountLevel3__c = 7.1;
        cs.DiscountLevel3User1__c = UserInfo.getUserId();
        cs.DiscountBandManager__c = 3.0;
        cs.DiscountBandDirector__c = 5.0;
        cs.Director__c = UserInfo.getUserId().left(15);
        cs.UseDiscountLevelApprovers__c = true;
        cs.Technical_Review_Region__c = bg_Globals.REGION_US;
        cs.Finance_Approval_Amount__c = 10;                
        upsert cs;

        // update current user country
        User currUser = new User(Id = UserInfo.getUserId(), 
                                OperationCountry__c = countryCode);
        update currUser;
        
        
        // GetGlobalPricebook
        GetGlobalPricebook();
        
        return cs;
    }

    public static CCode_Profile__c CreateCCodeProfile(Id userId, map<string, string> ccodeMap) {
        /*
            Create C-Code Profile record
        */
        CCode_Profile__c newCCodeProfile = new CCode_Profile__c();
        newCCodeProfile.User__c = userId;
        for(string ccode : ccodeMap.keySet()) {
            newCCodeProfile.put(ccode + '__c', ccodeMap.get(ccode));
        }
        insert newCCodeProfile;
        return newCCodeProfile;
    }

    public static ActivitySetting__c GetActivitySetting() {
        /*
            Setup activity settings     
        */      
        ActivitySetting__c cs = new ActivitySetting__c();
        cs.StatusAttempted__c = 'Attempted';
        cs.StatusComplete__c = 'Completed';
        cs.TypeCall__c = 'Call';
        insert cs;
        return cs;
    }
    
    public static QueueBusinessHours__c GetQueueBusinessHours() {
        /*
            Setup queue business hours settings     
        */      
        QueueBusinessHours__c cs = new QueueBusinessHours__c();
        cs.Name = 'Patch7';
        cs.BusinessHours__c = 'London';
        cs.Country__c = bg_SiteUtils.COUNTRY_CODE_UK;
        insert cs;
        return cs;
    }
    
    public static Territory__c GetTerritory() {
        /*
            Setup Territory     
        */      
        Territory__c ter = new Territory__c();
        ter.Name = 'Patch7';
        ter.Region__c = 'EMEA';
        ter.Country__c = bg_SiteUtils.COUNTRY_CODE_UK;
        ter.PostZipCode__c = 'TE1';
        insert ter;
        return ter;
    }

    public static void SetupCountryCurrencySettings() {
        /*
            Setup Country Currency Settings
        */
        GetCountryCurrencySetting(bg_SiteUtils.COUNTRY_CODE_US, bg_Globals.CURRENCY_CODE_USD);
        GetCountryCurrencySetting(bg_SiteUtils.COUNTRY_CODE_UK, bg_Globals.CURRENCY_CODE_GBP);
    }
    
    public static Country_Currency__c GetCountryCurrencySetting(string countryName, string currencyCode) {
        /*
            Setup default country settings      
        */
        Country_Currency__c cs = new Country_Currency__c();
        cs.name = countryName;
        cs.Currency_Code__c = currencyCode;
        insert cs;
        return cs;
    }

    public static SiteSetting__c GetSiteSettings() {
        /*
            Setup site settings     
        */
        SiteSetting__c cs = SiteSetting__c.getInstance();                        
        if(cs == null) {
            cs = new SiteSetting__c();
        }
        cs.HQLabel__c = 'HQ';
        cs.SamplingThreshold__c = 4;
        upsert cs;   
        return cs;
    }

    public static QuoteSetting__c GetQuoteSettings() {
        /*
            Setup quote settings        
        */
        QuoteSetting__c cs = new QuoteSetting__c();
        cs.StatusApproved__c = 'Approved';
        cs.StatusDraft__c = 'Not Submitted';
        cs.StatusNA__c = 'N/A';
        cs.StatusRejected__c = 'Declined';
        cs.StatusWaiting__c = 'Pending';
        insert cs;
        return cs;
    }
    
    public static Campaign GetCampaign() {
        /*
            Return Campaign
        */
        return GetCampaign('Test01');
    }
    
    public static Campaign GetCampaign(string name) {
        /*
            Return Campaign
        */
        return GetCampaign('Test01', null); 
    } 
    
    public static Campaign GetCampaign(string name, id parentId) {
        /*
            Return Campaign
        */      
        Campaign campaign = new Campaign();
        campaign.Name = name;
        campaign.ParentId = parentId;
        campaign.CurrencyIsoCode = bg_Globals.CURRENCY_CODE_GBP;

        insert campaign;
        return campaign;    
    }
    
    public static User GetUser(string theEmail, string userName, string alias) {
        /*
            Return User
        */          
        Profile p = [select id from profile WHERE name='Standard User' limit 1];
        User u = new User(alias = alias.length() > 8 ? alias.substring(0,8) : alias, 
                      email=theEmail, emailencodingkey='UTF-8', lastname='Last Name', 
                      languagelocalekey='en_US', localesidkey='en_GB', profileid = p.Id,
                      timezonesidkey='Europe/London', username=username,
                      firstname=username);
        u.OperationCountry__c = 'US';
        insert u;
        return u;
    }

    public static map<string, bg_Wrappers.QuoteProductWrapper> GetQuoteProductWrapperMap(Quote__c quote, list<Product__c> products, list<Site__c> sites) {
        /*
            Return populated QuoteProductWrapperMap 
        */
        list<bg_Wrappers.SiteWrapper> sws = GetSiteWrappers(sites);

        list<bg_Wrappers.QuoteProductWrapper> qpws = new list<bg_Wrappers.QuoteProductWrapper>();
        for(Product__c  product : products) {
            bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product);          
            bg_WrapperHelper.CreateProductSiteWrappers(quote, qpw, sws);
            for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) {
                psw.RegistrationPath = 'REG_PATH';
            }
            qpws.add(qpw);
        }
        return bg_WrapperHelper.CreateQuoteProductWrappersMap(qpws);
    }
    
    public static list<bg_Wrappers.SiteWrapper> GetSiteWrappers(list<Site__c> sites) {
        /*
            Return populated GetSiteWrappers 
        */      
        list<bg_Wrappers.SiteWrapper> sws = new list<bg_Wrappers.SiteWrapper>();
        for(Site__c site : sites) {
            sws.add(bg_WrapperHelper.CreateSiteWrapper(sws.size(), site, (sws.size()==0)));
        }
        return sws;
    }
    
    public static Attachment GetAttachment(Id parentId, string name, string bodyText) {
        /*
            Return populated Attachment 
        */
        Attachment doc = new Attachment();
        doc.Name = name;
        doc.Body = Blob.valueOf(bodyText);
        doc.ParentId = parentId;
        insert doc;
        return doc;
    }
   
    public static PropertyValue__c GetPropertyValue(string productToPropertyAlias, Id quoteProductId, string textValue) {
        return GetPropertyValue(productToPropertyAlias, quoteProductId, textValue, '', '');
    }
    
    public static PropertyValue__c GetPropertyValue(string productToPropertyAlias, Id quoteProductId, string textValue, string overridePrompt, string templateType) {
        /*
            Return Property Value
        */
        string productToPropertyGuid = '96BEEBB6-9EB7-4561-9A48-92B117829781';
        string quoteToProductGuid = '95CEEBB6-9EB7-4561-9A48-92B117829781';

        ProductToProperty__c p2p1 = new ProductToProperty__c();
        p2p1.Guid__c = quoteToProductGuid;
        p2p1.Alias__c = productToPropertyAlias;
        p2p1.OverridePrompt__c = overridePrompt;
        p2p1.Template_Type__c = templateType;
        insert p2p1;

        PropertyValue__c pv1 = new PropertyValue__c();
        pv1.ProductToPropertyGuid__c = productToPropertyGuid;
        pv1.ProductToProperty__c = p2p1.Id;
        pv1.QuoteToProductGuid__c = quoteToProductGuid;    
        pv1.QuoteToProduct__c = quoteProductId;
        pv1.TextValue__c = textValue;
        pv1.IsVisible__c = true;
        insert pv1;
        
        return pv1;       
    }
    
    public static echosign_dev1__SIGN_Agreement__c GetEchoSignAgreement()
    {
        echosign_dev1__SIGN_Agreement__c ESA = GetEchoSignAgreement(null);
        return ESA;
    }
    
    public static echosign_dev1__SIGN_Agreement__c GetEchoSignAgreement(Id quoteId)
    {
        echosign_dev1__SIGN_Agreement__c ESA = GetEchoSignAgreement(quoteId, null);
        return ESA;
    }
    
    public static echosign_dev1__SIGN_Agreement__c GetEchoSignAgreement(Id quoteId, Id contactId)
    {
        echosign_dev1__SIGN_Agreement__c ESA = CreateEchoSignAgreement(quoteId, contactId);
        insert ESA;
        return ESA;
    }

    public static echosign_dev1__SIGN_Agreement__c CreateEchoSignAgreement()
    {
        echosign_dev1__SIGN_Agreement__c ESA = CreateEchoSignAgreement(null);
        return ESA;
    }
 
    public static echosign_dev1__SIGN_Agreement__c CreateEchoSignAgreement(Id quoteId)
    {
        echosign_dev1__SIGN_Agreement__c ESA = CreateEchoSignAgreement(quoteId, null);
        return ESA;
    }
 
    public static echosign_dev1__SIGN_Agreement__c CreateEchoSignAgreement(Id quoteId, Id contactId)
    {
        echosign_dev1__SIGN_Agreement__c ESA = new echosign_dev1__SIGN_Agreement__c(Quote__c = quoteId, echosign_dev1__Recipient__c = contactId);
        return ESA;
    }
 
    
    public static APXTConga4__Conga_Template__c CreateCongaTemplate(String templateName, String templateGroup, Boolean activeSetting)
    {
        APXTConga4__Conga_Template__c ct = new APXTConga4__Conga_Template__c();
        ct.APXTConga4__Name__c = templateName;
        ct.APXTConga4__Template_Group__c = templateGroup;
        ct.Active__c = activeSetting;
        ct.Language__c = 'EN';
        ct.Country__c = 'GB';
        ct.Product_Type__c = 'Assessment';
        
        return ct;
    }
    
    public static APXTConga4__Conga_Template__c GetCongaTemplate(String templateName, String templateGroup, Boolean activeSetting)
    {
        APXTConga4__Conga_Template__c ct = CreateCongaTemplate(templateName, templateGroup, activeSetting);
        
        insert ct;
        return ct;
    }
    
    public static APXT_CMQR__Conga_Merge_Query__c CreateCongaQuery(String shortName)
    {
        APXT_CMQR__Conga_Merge_Query__c cq = new APXT_CMQR__Conga_Merge_Query__c();
        cq.ShortName__c = shortName;
        
        return cq;
    }
    
    public static APXT_CMQR__Conga_Merge_Query__c GetCongaQuery(String shortName)
    {
        APXT_CMQR__Conga_Merge_Query__c cq = CreateCongaQuery(shortName);
        
        insert cq;
        return cq;
    }

    public static Template_Queries__c CreateTemplateQuery(Id QueryId, Id TemplateId)
    {
        Template_Queries__c tq = new Template_Queries__c();
        tq.Conga_Query__c = QueryId;
        tq.Conga_Template__c = TemplateId;
        
        return tq;
    }

    public static Template_Queries__c GetTemplateQuery(Id QueryId, Id TemplateId)
    {
        Template_Queries__c tq = CreateTemplateQuery(QueryId, TemplateId);
        
        insert tq;
        return tq;
    }

    public static PricebookEntry createStandardPriceBookEntry(Id pProduct2Id, Integer pUnitPrice, String pCurrencyISOCode)
    {
        Integer unitPrice = 10000;
        if(null!=pUnitPrice)
        {
            unitPrice = pUnitPrice;
        }
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = null;
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        List<PricebookEntry> pbeList = [SELECT Id,
                                        Pricebook2Id,
                                        Product2Id,
                                        IsActive,
                                        CurrencyIsoCode,
                                        UnitPrice
                                        FROM PricebookEntry
                                        WHERE Pricebook2Id = :pricebookId
                                        AND Product2Id = :pProduct2Id
                                        AND CurrencyIsoCode = :pCurrencyISOCode
                                        LIMIT 1];
        
        // the Process Builder creating Pricebook Entry records may not be active
        if (pbeList.isEmpty())
        {
            standardPrice = new PricebookEntry
                (
                    Pricebook2Id = pricebookId,
                    Product2Id = pProduct2Id,
                    // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
                    // UnitPrice = unitPrice,            
                    UnitPrice = 0.0,
                    IsActive = true,
                    CurrencyIsoCode = pCurrencyISOCode
                );
            insert standardPrice;            
        }
        else 
        {
            standardPrice = pbeList[0];
            
            // the Process Builder creates inactive entry records
            if (!standardPrice.IsActive)
            {
                standardPrice.IsActive = true;
                update standardPrice;
            }
        }        
        
        return standardPrice;
    }
    
    public static PricebookEntry getStandardPriceBookEntry(Id pProduct2Id, Integer pUnitPrice, String pCurrencyISOCode)
    {
        Integer unitPrice = 10000;
        if(null!=pUnitPrice)
        {
            unitPrice = pUnitPrice;
        }
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry
        (
            Pricebook2Id = pricebookId,
            Product2Id = pProduct2Id,
            // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
            // UnitPrice = unitPrice,
            UnitPrice = 0.0,
            IsActive = true,
            CurrencyIsoCode = pCurrencyISOCode
        );
        return standardPrice;
    }

    public static Boolean CheckErrorIsInListOfErrors(List<ApexPages.Message> errors, String errorMessage)
    {
        Boolean errorInList = false;
        for (ApexPages.Message error : errors)
        {
            if (error.getSummary().contains(errorMessage))
            {
                errorInList = true;
            }
        }
        return errorInList;
    }

    /*
     * Set up all objects needed for a working TrainingBookingController for an event with accommodation
     */
    public static TrainingBookingController SetupTrainingBookingController(Integer maxAccommodation)
    {
        //setup account
        Account acc = bg_UnitTestHelper.CreateAccount();
        insert acc;

        // Set up a venue
        Training_Venue__c ven = TrainingBookingTestData.createTestVenue();

        Contact con = bg_UnitTestHelper.CreateContact('UnitTestContact', acc);
        con.Country_Office__c = ven.Id;
        con.OtherCountry = 'UK';
        insert con;

        // Set up promotional code
        Training_Promo_Code__c prm1 = TrainingBookingTestData.createTestPromo('Percent',0,50);
        Training_Promo_Code__c prm2 = TrainingBookingTestData.createTestPromo('Value',50,0);

        String taxonomyCode = 'EMS12345ENUK';
        String isoCode = 'GBP';
        Integer accommodationPrice = 50;

        Product2 accommodationProduct = TrainingBookingTestData.createTestCourse('Normal', 2, 'AccommodationProduct', isoCode, 'Public', taxonomyCode, null, null, null);
        PricebookEntry accommodationPBE = bg_UnitTestHelper.getStandardPriceBookEntry(accommodationProduct.Id, accommodationPrice, isoCode);

        Product2 course = TrainingBookingTestData.createTestCourse('Residential', 2, 'UnitTestCourse', isoCode, 'Public', taxonomyCode, accommodationProduct, null, null);

        // Setup an event
        Training_Event__c evt = TrainingBookingTestData.createTestEvent(course, ven, 10 , con.Id);
        evt.Max_Accommodation__c = maxAccommodation;
        update evt;
        
        // Set up price book entries
        PricebookEntry coursePBE = bg_UnitTestHelper.getStandardPriceBookEntry(course.Id, 200, 'GBP');
        // Setup the booking for a residential event (1 delegate with accommodation, 1 without)
        TrainingBooking__c booking = TrainingBookingTestData.createTestBooking(evt, coursePBE, accommodationPBE);
        booking.Pricebook_Entry_Extra_Night__c = null;
        booking.Discount_Value__c = 0;
        booking.Price_Per_Delegate__c = 200;
        booking.Discount_Percentage__c = 0;
        booking.Price_Per_Delegate_Accommodation__c = 50; 
        booking.Delegates_Inc_Accommodation__c = 1;
        booking.Delegates_Exc_Accommodation__c = 0;
        booking.Price_Per_Delegate_Extra_Night__c = 0; 
        booking.Delegates_inc_extra_night__c = 0;
        booking.Number_of_Delegates__c = 1;


        TrainingBookingUtilities.EventWrapper selectedEvent = new TrainingBookingUtilities.EventWrapper(booking);
        // Setup a booker delegate
        TrainingDelegate__c delegate = TrainingBookingTestData.createTestDelegate(booking, true, true);
        delegate.Accommodation_night_before__c = false;
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('C', 'EMS12345ENUK');
        ApexPages.currentPage().getParameters().put('PB', coursePBE.Pricebook2Id);
        ApexPages.currentPage().getParameters().put('ISOCode', 'GBP');
        TrainingBookingController cont = new TrainingBookingController();
        cont.selectedEvent = selectedEvent;
        cont.objDelegates = new List<TrainingDelegate__c>{delegate};
        cont.selectedDelegates = 1;
        cont.objBooking = booking;
        return cont;
    }

    public static APXTConga4__Conga_Template__c GetTemplate(String templateName)
    {
        APXTConga4__Conga_Template__c template = new APXTConga4__Conga_Template__c();
        template.APXTConga4__Name__c = templateName;
        template.APXTConga4__Template_Type__c = TEMPLATE_TYPE;
        template.CurrencyIsoCode = TEMPLATE_CURRENCY;
        template.Country__c = COUNTRY;
        return template;
    }

    public static APXT_CMQR__Conga_Merge_Query__c GetQuery(String queryName)
    {
        APXT_CMQR__Conga_Merge_Query__c congaQuery = new APXT_CMQR__Conga_Merge_Query__c();
        congaQuery.APXT_CMQR__Name__c = queryName;
        return congaQuery;
    }

    public static List<APXT_CMQR__Conga_Merge_Query__c> GetQueries(String queryName, Integer numberOfQueries)
    {
        List<APXT_CMQR__Conga_Merge_Query__c> congaQueryList= new List<APXT_CMQR__Conga_Merge_Query__c>();
        for (Integer i = 0; i < numberOfQueries; i++)
        {
            APXT_CMQR__Conga_Merge_Query__c congaQuery = GetQuery(queryName);
            congaQuery.APXT_CMQR__Name__c = congaQuery.name + ' ' + i + 1;
            congaQueryList.add(congaQuery);
        }
        return congaQueryList;
    }
    public static Template_Queries__c GetTemplateQuery(String templateQueryName, Id templateId, Id queryId)
    {
        Template_Queries__c templateQuery = new Template_Queries__c();
        templateQuery.Conga_Template__c = templateId;
        templateQuery.Conga_Query__c = queryId;
        templateQuery.name = templateQueryName;
        return templateQuery;
    }
    
    public static List<Template_Queries__c> GetTemplateQueries(String templateQueryName, Id templateId, Id queryId, Integer numberOfTemplateQueries)
    {
        List<Template_Queries__c> templateQueryList = new List<Template_Queries__c>();
        for (Integer i = 0; i < numberOfTemplateQueries; i++)
        {
            Template_Queries__c templateQuery = GetTemplateQuery(templateId, queryId);
            templateQuery.name = templateQueryName + ' ' + i + 1;
            templateQueryList.add(templateQuery);
        }
        return templateQueryList;
    }
    
    public static PermissionSetAssignment GetPermissionSetAssignment(Id permissionSetId, Id userId)
    {
        PermissionSetAssignment result = new PermissionSetAssignment();
        result.PermissionSetId = permissionSetId;
        result.AssigneeId = userId;
        return result;
    }
    
    public static Project__c CreateProject(Id accountId, String projectName, Boolean active)
    {
        Project__c result = new Project__c();
        
        result.Account__c = accountId;
        result.Active__c = active;
        result.Project_Name__c = projectName;
        result.Project_Family__c = 'Professional Services';
        result.Area_of_Practice__c = 'EHS';
        result.Project_Template__c = 'Generic';
        
        return result;
    }
}