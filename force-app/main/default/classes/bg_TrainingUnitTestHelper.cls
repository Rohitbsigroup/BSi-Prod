/********************************************************************
 * bg_TrainingUnitTestHelper
 *
 * Methods to Training support tests
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-08-2015
 * Changes: 
 *          15-01-2016 ASD  - Fixed Unit Tests to suit VR rules and WFRs (too many SOQLS) added inMemory Creators
 *          06-11-2017 ADS  - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
 *          12-02-2018 ADS  - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
 *          16-09-2019 JS   - Added venue city into create training venue
 ********************************************************************/
@isTest
public class bg_TrainingUnitTestHelper {

    /*public class trainingUnitTestSetup{
        public Account primaryAcc;
        public Contact primaryAccContact;
        public List<Site__c> primaryAccSites;
        public Quote__c primaryAccQuote;
        public List<EventWrappers> eventsWithDependancies
    }*/

    public static Training_Venue__c createTrainingVenue(String name, String currencyIsoCode)
    {
        return createTrainingVenue(null, name, currencyIsoCode);
    }
    
    public static Training_Venue__c getTrainingVenue(String name, String currencyIsoCode)
    {
        return getTrainingVenue(null, name, currencyIsoCode);
    }

    public static Account createAccount(String name, String countryIsoCode)
    {
        Account acc = new Account();
        acc.Name = name;
        acc.BillingCountry = countryIsoCode;
        //acc.BillingStreet = '123 Billing Street';
        acc.BillingCity = 'Billing City';
        insert acc;
        return acc;
    }

    public static Contact createContact(Id pAccountId, String pLastName, String pMailingCountry)
    {
        Contact con = new Contact();
        con.AccountId = pAccountId;
        con.MailingCountry = pMailingCountry;
        con.LastName = pLastName;
        insert con;
        return con;
    }

    public static Site__c createSite(Id pAccountId, Id pAccountPrimaryContactId, String pSiteType, String pPostcode, String pCountryISOCode, String pIndustry, String pTcodeDesc)
    {
        Site__c site = new Site__c();
        site.Account__c = pAccountId;
        site.Type__c = pSiteType;
        site.Postcode__c = pPostcode;
        site.Country_Code__c = pCountryISOCode;
        site.Industry__c = pIndustry;
        site.TCodeDescr__c = pTcodeDesc;
        site.PrimaryContact__c = pAccountPrimaryContactId;
        insert site;
        return site;
    }
    
    public static Product__c getConfiguratorProduct(String pProductName)
    {
        Product__c configuratorProduct = new Product__c();
        configuratorProduct.Name = pProductName;
        configuratorProduct.Product_Stream__c = 'Training';
        configuratorProduct.RegistrationPaths__c = 'Training';
        configuratorProduct.Active__c = true;
        configuratorProduct.Product_Type__c = 'Main';
        configuratorProduct.Active_In_SF__c = true;
        return configuratorProduct;
    }    

    public static Product__c createConfiguratorProduct(String pProductName)
    {
        Product__c configuratorProduct = getConfiguratorProduct(pProductName);
        insert configuratorProduct;
        return configuratorProduct;
    }

    public static Product2 createTrainingCourseProductWithOptionalDependancies(String pProductName, String pIcodes, String pTaxonomyCode, String pProductCode, Integer pDurationDays, Boolean pIsResidential, Boolean pIsBespokeEvent, Boolean pAccommodation, Boolean pExtraNight, Boolean pPremiumProduct, Boolean pCreateStandardPriceBookEntry, Integer pStandardPriceBookUnitPrice, Boolean pCreateCustomPriceBookWithEntry, Integer pCustomPriceBookUnitPrice)
    {
        Product2 courseProduct = new Product2();
        courseProduct.Name = pProductName;
        courseProduct.Training_Taxonomy_Code__c = pTaxonomyCode;
        courseproduct.ProductCode = pProductCode;
        courseProduct.Course_Duration_Days__c = pDurationDays;
        courseProduct.Training_Event_Residential__c = pIsResidential;
        courseProduct.Bespoke_Event__c = pIsBespokeEvent;
        courseProduct.I_codes_Required__c = pIcodes;
        courseProduct.Division__c = 'Training';
        courseProduct.ProductArea__c = 'Training';
        courseProduct.Course_Delivery__c = 'Public';
        courseProduct.Training_Product_Type__c = 'Accommodation';
        courseProduct.IsActive = true;
        insert courseProduct;

        PriceBook2 customPB = null;
        if(pCreateStandardPriceBookEntry)
        {
            createStandardPriceBookEntry(courseProduct.Id, pStandardPriceBookUnitPrice);
        }
        if(pCreateCustomPriceBookWithEntry)
        {
            customPB = createCustomPricebook('CUST_PB');
            createCustomPriceBookEntry(customPB.Id, courseProduct.Id, pCustomPriceBookUnitPrice);
        }
        if(pAccommodation)
        {
            courseProduct.Base_Product__c = createAccommodationProduct(pCreateStandardPriceBookEntry,null,customPB,null).Id;
        }
        if(pExtraNight)
        {
            courseProduct.Extra_Night__c = createExtraNightProduct(pCreateStandardPriceBookEntry,null,customPB,null).Id;
        }
        if(pPremiumProduct)
        {
            courseProduct.Premium_Product__c = createPremiumPriceProduct(pCreateStandardPriceBookEntry,null,customPB,null).Id;
        }
        return courseProduct;
    }

    public static Product2 createAccommodationProduct(Boolean pCreateStandardPriceBookEntry, Integer pStandardPriceBookUnitPrice, PriceBook2 pCustomPriceBook, Integer pCustomPriceBookUnitPrice)
    {
        Product2 accommProduct = new Product2();
        accommProduct.Name = 'UNIT TEST ACCOMM PRODUCT';
        accommProduct.Training_Taxonomy_Code__c = 'GB';
        accommProduct.Division__c = 'Training';
        accommProduct.ProductArea__c = 'Training';
        accommProduct.Course_Delivery__c = 'Public';
        accommProduct.Training_Product_Type__c = 'Accommodation';
        insert accommProduct;
        if(pCreateStandardPriceBookEntry)
        {
            createStandardPriceBookEntry(accommProduct.Id, pStandardPriceBookUnitPrice);
        }
        if(null!=pCustomPriceBook)
        {
            createCustomPriceBookEntry(pCustomPriceBook.Id, accommProduct.Id, pCustomPriceBookUnitPrice);
        }
        return accommProduct;
    }

    public static Product2 createExtraNightProduct(Boolean pCreateStandardPriceBookEntry, Integer pStandardPriceBookUnitPrice, PriceBook2 pCustomPriceBook, Integer pCustomPriceBookUnitPrice)
    {
        Product2 extraNightProduct = new Product2();
        extraNightProduct.Name = 'UNIT TEST EXTRA NIGHT PRODUCT';
        extraNightProduct.Training_Taxonomy_Code__c = 'GB';
        extraNightProduct.Division__c = 'Training';
        extraNightProduct.ProductArea__c = 'Training';
        extraNightProduct.Course_Delivery__c = 'Public';
        extraNightProduct.Training_Product_Type__c = 'Accommodation';
        insert extraNightProduct;
        if(pCreateStandardPriceBookEntry)
        {
            createStandardPriceBookEntry(extraNightProduct.Id, pStandardPriceBookUnitPrice);
        }
        if(null!=pCustomPriceBook)
        {
            createCustomPriceBookEntry(pCustomPriceBook.Id, extraNightProduct.Id, pCustomPriceBookUnitPrice);
        }
        return extraNightProduct;
    }

    public static Product2 createPremiumPriceProduct(Boolean pCreateStandardPriceBookEntry, Integer pStandardPriceBookUnitPrice, PriceBook2 pCustomPriceBook, Integer pCustomPriceBookUnitPrice)
    {
        Product2 premProduct = new Product2();
        premProduct.Name = 'UNIT TEST PREMIUM PRODUCT';
        premProduct.Training_Taxonomy_Code__c = 'GB';
        premProduct.Division__c = 'Training Services';
        premProduct.ProductArea__c = 'Training';
        premProduct.Course_Delivery__c = 'Public';
        premProduct.Type__c = 'Other';
        premProduct.Training_Product_Type__c = 'Training Course';
        insert premProduct;
        if(pCreateStandardPriceBookEntry)
        {
            createStandardPriceBookEntry(premProduct.Id, pStandardPriceBookUnitPrice);
        }
        if(null!=pCustomPriceBook)
        {
            createCustomPriceBookEntry(pCustomPriceBook.Id, premProduct.Id, pCustomPriceBookUnitPrice);
        }
        return premProduct;
    }

    public static Pricebook2 createCustomPricebook(String pPriceBookName)
    {
        Pricebook2 customPB = new Pricebook2(Name=pPriceBookName, isActive=true, Year__c='2015');
        insert customPB;
        return customPB;
    }

    public static void createCustomPriceBookEntry(Id pPricebook2Id, Id pProduct2Id, Integer pUnitPrice)
    {
        Integer unitPrice = 5000;
        if(null!=pUnitPrice)
        {
            unitPrice = pUnitPrice;
        }
        PricebookEntry customPrice = new PricebookEntry
        (
            Pricebook2Id = pPricebook2Id,
            Product2Id = pProduct2Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert customPrice;
    }

    public static PricebookEntry createStandardPriceBookEntry(Id pProduct2Id, Integer pUnitPrice)
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
            IsActive = true
        );
        insert standardPrice;
        return standardPrice;
    }

    public static Training_Venue__c createTrainingVenue(Training_Venue__c masterVenue, String name, String currencyIsoCode)
    {
        Training_Venue__c tv = new Training_Venue__c();
        tv.Name = name;
        tv.CurrencyIsoCode = currencyIsoCode;
        tv.Public_Venue__c = true;
        tv.Venue_City__c = 'city';

        if (masterVenue != null) {
            tv.Training_Office__c = masterVenue.id;
        }

        insert tv;
        return tv;
    }
    
    public static Training_Venue__c getTrainingVenue(Training_Venue__c masterVenue, String name, String currencyIsoCode)
    {
        Training_Venue__c tv = new Training_Venue__c();
        tv.Name = name;
        tv.CurrencyIsoCode = currencyIsoCode;
        tv.Public_Venue__c = true;
        

        if (masterVenue != null) {
            tv.Training_Office__c = masterVenue.id;
        }

        return tv;
    }

    public static Training_Event__c createTrainingEvent(Training_Venue__c trainingVenue, String currencyIsoCode, Integer maxSeats, Product2 product, Date startDate, Id pInstructorId)
    {
        Training_Event__c te = new Training_Event__c();
        te.Training_Venue__c = trainingVenue.id;
        te.CurrencyIsoCode = currencyIsoCode;
        te.Max_Seats__c = maxSeats;
        te.Course__c = product.id;
        te.Start_date__c = startDate;
        te.Event_status__c = 'Active';
        te.Trainer__c = pInstructorId;
        insert te;

        te = [Select id, Training_Venue__c, CurrencyIsoCode, Max_Seats__c, Course__c, Start_date__c, Event_status__c, Active_1_0__c from Training_Event__c where id =: te.id];

        return te;      
    }

    public static Training_Event__c createTrainingEvent(Training_Venue__c trainingVenue, String currencyIsoCode, Integer maxSeats, Product2 product, Date startDate)
    {
        Contact trainer = GetContactTraining('UNITTEST_LASTNAME', 'ICODES', trainingVenue.Id);
        
        Training_Event__c te = new Training_Event__c();
        te.Training_Venue__c = trainingVenue.id;
        te.CurrencyIsoCode = currencyIsoCode;
        te.Max_Seats__c = maxSeats;
        te.Course__c = product.id;
        te.Start_date__c = startDate;
        te.Event_status__c = 'Active';
        te.Trainer__c = trainer.Id;
        insert te;

        te = [Select id, Training_Venue__c, CurrencyIsoCode, Max_Seats__c, Course__c, Start_date__c, Event_status__c, Active_1_0__c from Training_Event__c where id =: te.id];

        return te;
    }

    public static Training_Event__c createTrainingEvent(Training_Venue__c trainingVenue, String currencyIsoCode, Integer maxSeats, Id productId, Date startDate, String pEventStatus, String pBespokeTaxonomy, Id pInstructorId, Id pTrainingTranslationId, String keyAccount) //JS edit 200120
    {
        Training_Event__c te = new Training_Event__c();
        te.Training_Venue__c = trainingVenue.id;
        te.CurrencyIsoCode = currencyIsoCode;
        te.Max_Seats__c = maxSeats;
        te.Course__c = productId;
        te.Start_date__c = startDate;
        te.Event_status__c = pEventStatus;
        te.Trainer__c = pInstructorId;
        te.Bespoke_Taxonomy__c = pBespokeTaxonomy;
        te.In_House_Key_Account__c = keyAccount; //JS edit 200120
        insert te;

        te = [Select id, Name, Training_Venue__c, CurrencyIsoCode, Max_Seats__c, Course__c, Start_date__c, Event_status__c, Active_1_0__c, Trainer__c from Training_Event__c where id =: te.id];

        return te;
    }

    public static Training_Event__c getTrainingEvent(Training_Venue__c trainingVenue, String currencyIsoCode, Integer maxSeats, Product2 product, Date startDate, Id pInstructorId)
    {
        Training_Event__c te = new Training_Event__c();
        te.Training_Venue__c = trainingVenue.id;
        te.CurrencyIsoCode = currencyIsoCode;
        te.Max_Seats__c = maxSeats;
        te.Course__c = product.id;
        te.Start_date__c = startDate;
        te.Event_status__c = 'Active';
        te.Trainer__c = pInstructorId;
        return te;
    }


    public static Training_Event__c createTrainingEventWithDependancies(String pCurrencyIsoCode, Id pTrainingCourseId, Integer pMaxSeats, Date pStartDate, String pEventStatus, String pBespokeTaxonomy, String keyAccount) //JS edit 200120
    {
        Training_Venue__c masterVenue = createTrainingVenue('Master Venue', pCurrencyIsoCode);
        Training_Venue__c tv = createTrainingVenue(masterVenue,'Training Venue', pCurrencyIsoCode);
        Contact instructor = GetContactTraining('UNITTEST_LASTNAME', 'ICODES', masterVenue.Id);
        Training_Translations__c translation = GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;

        Training_Event__c evt = createTrainingEvent(tv, pCurrencyIsoCode, pMaxSeats, pTrainingCourseId, pStartDate, pEventStatus, pBespokeTaxonomy, instructor.Id, translation.Id, keyAccount); //JS edit 200120
        return evt;
    }

    public static TrainingBooking__c createTrainingBooking(Training_Event__c trainingEvent, Integer numberOfDelegates)
    {
        return createTrainingBooking(trainingEvent, numberOfDelegates, null);
    }

    public static TrainingBooking__c createTrainingBooking(Training_Event__c trainingEvent, Integer numberOfDelegates, Id accountId)
    {
        TrainingBooking__c tb = new TrainingBooking__c();
        tb.Training_Event__c = trainingEvent.id;
        tb.Number_of_Delegates__c = numberOfDelegates;

        if (accountId != null) {
            tb.Conversion_Account__c = accountId;
        }
        insert tb;
        return tb;
    }

    public static TrainingDelegate__c createTrainingDelegate(TrainingBooking__c tb, String firstName, String lastName, String salutation, String jobTitle,
        String emailAddress, String socialSecurityNumber, Boolean accomodationRequired, String mobileNumber)
    {
        TrainingDelegate__c td = new TrainingDelegate__c();
        td.Training_Booking__c = tb.id;
        td.First_Name__c = firstName;
        td.Last_Name__c = lastName;
        td.Salutation__c = salutation;
        td.Job_Title__c = jobTitle;
        td.Mobile_Number__c = mobileNumber;
        td.Accommodation_Required__c = accomodationRequired;
        td.Email_Address__c = emailAddress;
        td.Social_Security_Number__c = socialSecurityNumber;
        insert td;
        return td;
    }

    public static TrainingBooking__c GetTrainingBooking(Training_Event__c event, PricebookEntry pbeExc, PricebookEntry pbeInc, Training_Translations__c trainingTranslation)
    {
        // Create object
        TrainingBooking__c testBkg = new TrainingBooking__c();
        testBkg.Booking_Country__c = 'GB';
        testBkg.Booking_Language__c = 'EN';

        // translation
        testBkg.Training_Translations__c = trainingTranslation.Id;

        // Event elements
        testBkg.Training_Event__c = event.Id;
        testBkg.Is_Residential__c = true;
        testBkg.Price_Exc_Accommodation__c = 50.00;
        testBkg.Price_Inc_Accommodation__c = 50.00;
        testBkg.Price_Per_Delegate__c = null;
        testBkg.Pricebook_Entry__c = null;
        testBkg.Pricebook_Exc_Accommodation__c = pbeExc.Id;
        testBkg.Pricebook_Inc_Accommodation__c = pbeInc.Id;

        // Contact elements
        testBkg.Salutation__c = '';
        testBkg.First_Name__c = 'Test';
        testBkg.Last_Name__c = 'Contact';
        testBkg.Email_Address__c = 'test@bsigroup.com';
        testBkg.Email_Confirmation__c = 'test@bsigroup.com';
        testBkg.Job_Title__c = 'Manager';
        testBkg.Attending_Course__c = true;

        // Company elements
        testBkg.Company_Name__c = 'Test Company';
        testBkg.Company_Street__c = '389 High Rd';
        testBkg.Company_City__c = 'London';
        testBkg.Company_Region__c = 'Buckinghamshire';
        testBkg.Company_Region_Code__c = 'BU';
        testBkg.Company_Postcode__c = 'W4 4AL';
        //testBkg.Company_Country__c = 'United Kingdom';
        testBkg.Company_Country__c = 'GB';
        testBkg.Company_Country_Code__c = 'GB';
        testBkg.Contact_Phone__c = '02089969000';
        testBkg.Contact_Mobile__c = '07123456789';
        testBkg.Contact_Fax__c = '02089969001';
        testBkg.VAT_Number__c = '';

        // Billing elements
        testBkg.Billing_Address__c = true;
        testBkg.Billing_Name__c = 'Test Company';
        testBkg.Billing_Street__c = '389 High Rd';
        testBkg.Billing_City__c = 'London';
        testBkg.Billing_Region__c = 'Buckinghamshire';
        testBkg.Billing_Region_Code__c = 'BU';
        testBkg.Billing_Postcode__c = 'W4 4AL';
        //testBkg.Billing_Country__c = 'United Kingdom';
        testBkg.Billing_Country__c = 'UK';
        testBkg.Billing_Country_Code__c = 'GB';

        // Delegate and pricing elements
        testBkg.Number_of_Delegates__c = null;
        testBkg.Delegates_Exc_Accommodation__c = 1;
        testBkg.Delegates_Inc_Accommodation__c = 1;
        testBkg.Net_Price__c = 100.00;
        testBkg.Tax__c = 20.00;
        testBkg.Discount__c = 0.00;
        testBkg.Discount_Percentage__c = 0.00;
        testBkg.Discount_Value__c = 0.00;
        testBkg.Total_Price__c = 120.00;

        // Payment elements
        testBkg.Payment_Method__c = 'Invoice';
        testBkg.Payment_Order_No__c = '';
        testBkg.PO_Number__c = '';
        testBkg.Promotional_Code__c = '';
        testBkg.SAP_Order_No__c = '';
        testBkg.Agree_Personal_Data_Statement__c = true;
        testBkg.Agree_Terms_Conditions__c = true;

        // Conversion elements
        testBkg.Conversion_Account__c = null;
        testBkg.Conversion_Contact__c = null;
        testBkg.Conversion_Opportunity__c = null;
        testBkg.Converted__c = false;

        return testBkg;
    }

    public static Training_Translations__c GetTrainingTranslation(String name, String currencyIsoCode)
    {
        Training_Translations__c translation = new Training_Translations__c();
        translation.Name = name;
        translation.CurrencyIsoCode = currencyIsoCode;

        // mandatory 
        translation.Certificate_Number__c = 'Certificate Number';
        translation.Certified_By_IRCA__c = 'Certified by IRCA';
        translation.Certified_By__c = 'For and on behalf BSI:';
        translation.Course_Number__c = 'Course Number';
        translation.IRCA_Logo__c = 'https://eu1.salesforce.com/servlet/servlet.ImageServer?id=015D0000001Fs3o&oid=00D200000000Evl';
        translation.Email_Header__c = 'https://eu1.salesforce.com/servlet/servlet.ImageServer?id=015D0000001HJot&oid=00D200000000Evl';
        translation.Dear__c = 'Dear';
        translation.OnlineBooking_Notfn_Subject__c = 'Confirmation of BSI Online Booking';
        translation.Signature__c = 'https://eu1.salesforce.com/servlet/servlet.ImageServer?id=015D0000001Fs3y&oid=00D200000000Evl';
        translation.Signature_Image__c = 'signature_UK.jpg';
        translation.Training_Manager__c = 'Test Manager, Head of Test';
        translation.Contact_Email__c = 'testmanager@company.com';
        translation.Booking_Confirmation__c = 'Booking Confirmation';
        translation.Booking_Reference__c = 'Booking Reference';
        translation.Contact_Us__c = 'Contact us';
        translation.Course_Details__c = 'Course Details';
        translation.Date__c = 'Date';
        translation.Start_date__c = 'Course Start Date';
        translation.Location__c = 'Venue';
        translation.Notfn_Subject__c = 'Important! Your BSI course joining instructions';
        translation.ExR_Text2__c = 'Please be at the venue for 9am. The exam will finish around 12pm.';
        translation.Office_Address__c = 'A member of the BSI Group of Companies.';
        translation.Exam_Resit__c = 'Exam Resit';
        translation.Outcomes__c = 'When the course is finished, you should be able to';
        translation.General_Info__c = 'General Information';
        translation.Prerequisites__c = 'Prerequisites';
        translation.Aims__c = 'Aims';
        translation.Reminder__c = 'Reminder';
        translation.Text_Box_1__c = 'This is to certify that';
        translation.Text_Box_2__c = 'has attended';
        translation.Text_Box_3__c = 'has attended and passed';
        translation.Residential_Text1__c = 'You have chosen the following option:';
        translation.Residential_Text2__c = 'BSI offer a residential option with this course which includes 4 nights accommodation and evening meals starting from';
        translation.Schedule__c = 'The course schedule';
        translation.Notfn_Subject_TA__c = 'Important! Your BSI course joining instructions';
        translation.InH_Text1__c = 'Thank you for arranging an In-company training course with BSI. Please find your course details below.';

        return translation;
    }

    public static Enrollment__c GetEnrolment(String currencyIsoCode, Contact contact, Training_Translations__c translation, Training_Event__c te, 
        String bookingStatus)
    {
        Enrollment__c enrolment = new Enrollment__c();
        enrolment.CurrencyIsoCode = currencyIsoCode;
        enrolment.Delegate_name__c = contact.Id;
        enrolment.Training_Translations__c = translation.Id;
        enrolment.Email_Confirmation_Sent__c = false;
        enrolment.Booking_status__c = bookingStatus;
        enrolment.Training_Event__c = te.Id;
        enrolment.Accomodation__c = 'Non-Residential';

        return enrolment;
    }
    
    public static Product2 CreateProductTraining(string name, String icodes) {
        /*
            Return Product Fee
        */
        Product2 prod = new Product2();
        prod.Name = name;
        prod.CurrencyIsoCode = bg_Globals.CURRENCY_CODE_USD;
        prod.I_codes_Required__c = icodes;
        prod.IsActive = true;
        prod.ProductArea__c = 'Training';
        return prod;
    }    

    public static Product2 GetProductTraining(string name, String icodes) {
        /*
            Return Product Fee
        */
        Product2 prod = CreateProductTraining(name, icodes);
        insert prod;
        return prod;
    }

    public static Contact GetContactTraining(string name, String icodes, Id masterVenueId) {
        /* 
            Return Contact 
        */
        Contact con = new Contact();
        con.FirstName = 'UT';
        con.LastName = name;
        con.MailingCountry = bg_SiteUtils.COUNTRY_CODE_US;
        con.Email = 'email@email.com';
        con.RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_CONTACT).get(bg_ContactUtils.RECORD_TYPE_NAME_CLIENTS).Id;
        con.I_Codes_text__c = icodes;
        con.Country_Office__c = masterVenueId;
        insert con;
        return con;
    }

    public static Quote_Product__c GetQuoteProduct(String pricebookName, Id quote, Id site, Id productName)
    {
        quote_Product__c quoteProduct = new Quote_Product__c();
        quoteProduct.Quote_Ref__c = quote;
        quoteProduct.Price_Book_Name__c = pricebookName;
        quoteProduct.Site__c = site;
        quoteProduct.Product_Name__c = productName;
        return quoteProduct;
    }

    public static Quote_Part__c GetQuotePart(Id quoteProduct, Id quote)
    {
        Quote_Part__c quotePart = new Quote_Part__c();
        quotePart.Quote_Product__c = quoteProduct;
        quotePart.Quote_Ref__c = quote;
        return quotePart;
    }
}