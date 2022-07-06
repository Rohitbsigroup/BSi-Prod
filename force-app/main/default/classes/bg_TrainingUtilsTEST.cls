/********************************************************************
 * bg_TrainingUtilsTEST
 *
 * Test methods for bg_TrainingUtils
 * 
 * Author: Nick Fisher
 * Created: 30-10-2014
 * Changes: 
 *  10-12-2014 Alexis Lignereux
 *      Added all the testInstructorMessage methods
 *  12-09-2015 Richard Jimenez
 *      Added ManageTrainingSMOUpdateRecords method
 *  06-11-2017 ADS
 *      Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
 *  05/12/2017 ADS
 *      Updates for new Validation Rule "Americas Customer Type Should Be Populated" on Opportunity
 *  12/02/2018 ADS
 *      Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
 *  05/04/2018 MD
 *      Copied updates made by ADS on 28-07-2017 in DEV3 for SoW034 (Online Exam Enhancements)
 *  25/09/2018 PC - reworked methods, removed (seeAllData=true), added new tests
 *  03/12/2018 JS - updated to comment out/add in details to push changes for online exams live
 *  13/12/2018 MD - removed commenting out from 20181203 - TO BE REVIEWED WITH JULIE
 *  01/04/2019 JS - reviewed the above and adjusted commenting where appropriate
 *  10/05/2020 PC(K2) - added testManageMimeoDistributionAssignment
 ********************************************************************/
@IsTest
public class bg_TrainingUtilsTEST 
{
    static Opportunity opp;
    static Quote__c quote;
    static Quote_Product__c quoteProduct;
    static Quote_Part__c quotePart;
    static OpportunityLineItem oli;
    static Training_Event__c trainingEvent;
    static TrainingBooking__c trainingBooking;
    static Enrollment__c enrollment;

    static void setupData(){
        Product2 testProduct = new Product2();
        testproduct.Name = 'test product';
        insert testProduct;

        Pricebook2 testPriceBook2 = new Pricebook2();
        testPriceBook2.Name = 'anotherTestPricebook';
        testPriceBook2.Year__c = String.valueOf(Date.today().year());
        testPriceBook2.IsActive = true;
        insert testPriceBook2;
        
        PricebookEntry testPBE2 = new PricebookEntry();
        testPBE2.Product2Id = testProduct.Id;
        testPBE2.Pricebook2Id = testPriceBook2.Id;
        testPBE2.UnitPrice = 20.00;
        testPBE2.IsActive = true;
        insert testPBE2;

        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        testAccount.BillingCountry = 'UK';
        insert testAccount;

        opp = new Opportunity();
        opp.Name = 'testOpportunity';
        opp.StageName = 'Sales Engaged';
        opp.CloseDate = date.today();
        opp.AccountId = testAccount.Id;
        opp.Sync_in_Progress__c = true;
        // 05/12/2017 ADS - Updates for new Validation Rule "Americas Customer Type Should Be Populated" on Opportunity
        opp.BusinessDrivers__c = 'New Customer';
        insert opp;
       
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        trainingEvent = bg_TrainingUnitTestHelper.createTrainingEventWithDependancies('GBP', product.Id, 10, Date.Today()+5, 'Active', 'EMS12345ENUK', 'Yes' ); //JS edit 200120
        
        Training_Translations__c translation = TestDataUtility.insertTrainingTranslation();

        enrollment = new Enrollment__c();        
        enrollment.Booking_status__c = Label.Enrollment_Booking_Status_Booked;
        
        enrollment.Training_Event__c = trainingEvent.Id;
        enrollment.Training_Translations__c = translation.Id;
        insert enrollment;

        quote = new Quote__c();
        insert quote;

        trainingBooking = new TrainingBooking__c();
        trainingBooking.Quote__c = quote.Id;
        trainingBooking.Training_Event__c = trainingEvent.Id;
        trainingBooking.Number_of_Delegates__c = 2;
        trainingBooking.Delegates_Inc_Accommodation__c = 2;
        trainingBooking.Delegates_Inc_Extra_Night__c = 2;
        trainingBooking.Delegates_inc_exam__c = 2;
        trainingBooking.Delegates_inc_standard__c = 2;
        trainingBooking.Price_Per_Delegate__c = 1000;
        trainingBooking.Price_Per_Delegate_Accommodation__c = 100;
        trainingBooking.Price_Per_Delegate_Extra_Night__c = 100;
        trainingBooking.Price_Per_Delegate_Online_Exam__c = 100;
        trainingBooking.Price_Per_Delegate_Online_Standard__c = 100;
        trainingBooking.Discount_Value__c = 0;
        trainingBooking.Discount_Percentage__c = 0;
        trainingBooking.Convert_To_On_Hold__c = false;
        insert trainingBooking;

        quoteProduct = new Quote_Product__c();
        quoteProduct.Quote_Ref__c = quote.Id;
        quoteProduct.Price_Book__c = testPriceBook2.Id;
        quoteProduct.Price_Book_Name__c = testPriceBook2.Name;
        insert quoteProduct;

        quotePart = new Quote_Part__c();
        quotePart.Quote_Product__c = quoteProduct.Id;
        quotePart.Quote_Ref__c = quote.Id;
        quotePart.Training_Booking__c = trainingBooking.Id;
        quotePart.Discount_Percentage__c = 0;
        quotePart.Exchange_Rate__c = 1;
        quotePart.Price__c = 500;
        quotePart.Number__c = 1;
        insert quotePart;

        oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.Enrollment__c = enrollment.Id;
        oli.Training_Event__c = trainingEvent.Id;
        oli.Quantity = 1;
        oli.TotalPrice = 10.00;
        oli.PricebookEntryId = testPBE2.Id;
        oli.Quote_Part__c = quotePart.Id;
        oli.TotalPrice = 1000;
        insert oli;
    }

    public static Training_Event__c createTrainingEvent(){
        Training_Event__c testTrainingEvent = new Training_Event__c();
        //testTrainingEvent.Name = 'Nicks Test TrainingEvent';
        testTrainingEvent.Max_seats__c = 50;
        return testTrainingEvent;
    }
    
    @isTest static void testFetchOLI(){
        setupData();

        bg_TrainingUtils.getEnrollmentOLI(enrollment.Id);
        bg_TrainingUtils.fetchRelatedOppLineItemMap(new Set<Id>{quotePart.Id});
    }
        
    @isTest static void testCreateDelegate(){
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        /*Training_Event__c testTrainingEvent = bg_TrainingUnitTestHelper.createTrainingEventWithDependancies('GBP', product.Id, 10, Date.Today()+5, 'Active', 'EMS12345ENUK');
        TrainingBooking__c testTrainingBooking = new TrainingBooking__c();
        testTrainingBooking.Training_Event__c = testTrainingEvent.Id;
        insert testTrainingBooking;*/
        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 2, product, Date.today()+5);
        TrainingBooking__c tb = bg_TrainingUnitTestHelper.createTrainingBooking(te, 2);
        Map<Id, TrainingBooking__c> trainingMap = new Map<Id, TrainingBooking__c>();
        trainingMap.put(tb.Id, tb);

        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetSiteSettings();        
        // Product
        string productName = 'ISO 9001';
        Product__c product2 = bg_UnitTestHelper.GetProduct(productName);
        // Account
        Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_NQCV2');
        // Contact
        Contact con = bg_UnitTestHelper.GetContact('UT-NQCV2-CON', acc);
        // Opportunity
        Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc, productName);
        // Add Site
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_QPG_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        // Opportunity Site
        //bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);
        /*  LOAD QUOTE TEST */

        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);   
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product2);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product2, 0, false, quoteProduct);
        quotePart.Training_Booking__c = tb.Id;
        update quotePart;

        Map<Id, Quote_Part__c> quoteMap = new Map<Id, Quote_Part__c>();
        quoteMap.put(quotePart.Id, quotePart);

        Test.startTest();
        TrainingDelegate__c result = bg_TrainingUtils.createDelegate(tb);
        bg_TrainingUtils.createDelegatesForTrainingBooking(trainingMap);
        bg_TrainingUtils.syncDelegatesWithTrainingBooking(trainingMap);
        bg_TrainingUtils.createDelegate(tb);
        bg_TrainingUtils.syncTrainingBookingsv2(quoteMap);
        bg_TrainingUtils.TrainingBookingConversionWrapper testWrapper = new bg_TrainingUtils.TrainingBookingConversionWrapper(tb, new List<OpportunityLineItem>(), false);
        bg_TrainingUtils.createConversionAccount(testWrapper);
        bg_TrainingUtils.updateConversionAccount(testWrapper, acc, true);
        bg_TrainingUtils.createConversionContact(testWrapper);
        bg_TrainingUtils.createConversionOpportunity(testWrapper, true);
        bg_TrainingUtils.createConversionOppContactRole(testWrapper);
        bg_TrainingUtils.createDelegateContacts(testWrapper);
        bg_TrainingUtils.createOppLineItems(testWrapper);
        bg_TrainingUtils.fetchRelatedOppLineItemMap(quoteMap.keySet());
        //system.assertEquals(testTrainingBooking.Id, result.Training_Booking__c);

        bg_TrainingUtils.SetOpportunitySyncFlag(new Set<Opportunity>{opp});
        bg_TrainingUtils.ClearOpportunitySyncFlag(new Set<Opportunity>{opp});
        Test.stopTest();
    }

    @isTest static void testCreateDelegates(){
        Pricebook2 testPB = new Pricebook2();
        testPB.Name = 'Nicks Test PB';
        testPB.Year__c = '2016';
        insert testPB;
        Quote__c testQuote = new Quote__c();
        insert testQuote;
        Quote_Product__c testQuoteProduct = new Quote_Product__c();
        testQuoteProduct.Quote_Ref__c = testQuote.Id;
        testQuoteProduct.Price_Book__c = testPB.Id;
        testQuoteProduct.Price_Book_Name__c = testPB.Name;
        insert testQuoteProduct;
        Quote_Part__c testQuotePart = new Quote_Part__c();
        testQuotePart.Quote_Product__c = testQuoteProduct.Id;
        testQuotePart.Quote_Ref__c = testQuote.Id;
        insert testQuotePart;

        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Training_Event__c testTrainingEvent = bg_TrainingUnitTestHelper.createTrainingEventWithDependancies('GBP', product.Id, 10, Date.Today()+5, 'Active', 'EMS12345ENUK', 'Yes'); //JS edit 200120

        TrainingBooking__c testTrainingBooking = new TrainingBooking__c();
        testTrainingBooking.Quote__c = testQuote.Id;
        testTrainingBooking.Training_Event__c = testTrainingEvent.Id;
        testTrainingBooking.Number_of_Delegates__c = 2;
        testTrainingBooking.Delegates_inc_exam__c = 2;
        testTrainingBooking.Delegates_inc_standard__c = 1;
        insert testTrainingBooking;
        
        Map<ID, TrainingBooking__c> theMap = new Map<ID, TrainingBooking__c>();
        theMap.put(testTrainingBooking.Id, testTrainingBooking);

        Test.startTest();
        bg_TrainingUtils.createDelegatesForTrainingBooking(theMap);
        Test.stopTest();
    }

    @isTest static void testCreateDelegateContacts(){
        setupData();

        Map<Id, TrainingBooking__c> theMap = new Map<Id, TrainingBooking__c>();
        theMap.put(trainingBooking.Id, trainingBooking);
        bg_TrainingUtils.createDelegatesForTrainingBooking(theMap);

        //refetch to update Delegate relationship
        trainingBooking = bg_TrainingUtils.fetchBookingsWithDelegatesAndQuotePartsForConversion(new Set<Id>{trainingBooking.Id})[0];

        bg_TrainingUtils.TrainingBookingConversionWrapper wrapper = new bg_TrainingUtils.TrainingBookingConversionWrapper(trainingBooking, new List<OpportunityLineItem>{oli}, true);
        wrapper.onlineExamTrainingEvent = trainingEvent;

        trainingBooking.Contact_Mobile__c = '123456789';
        trainingBooking.Training_Delegates__r[0].First_Name_English__c = 'test name';
        bg_TrainingUtils.createDelegateContacts(wrapper);
    }

    @isTest static void testCreateEnrollmentsForDelegates(){
        setupData();

        Map<Id, TrainingBooking__c> theMap = new Map<Id, TrainingBooking__c>();
        theMap.put(trainingBooking.Id, trainingBooking);
        bg_TrainingUtils.createDelegatesForTrainingBooking(theMap);

        //refetch to update Delegate relationship
        trainingBooking = bg_TrainingUtils.fetchBookingsWithDelegatesAndQuotePartsForConversion(new Set<Id>{trainingBooking.Id})[0];

        bg_TrainingUtils.TrainingBookingConversionWrapper wrapper = new bg_TrainingUtils.TrainingBookingConversionWrapper(trainingBooking, new List<OpportunityLineItem>{oli}, true);
        wrapper.onlineExamTrainingEvent = trainingEvent;
        bg_TrainingUtils.createOppLineItems(wrapper);

        //internal
        trainingBooking.Training_Event__r.Course__r.Delivery_Method__c = bg_TrainingUtils.COURSE_FORMAT_DISTANCE_LEARNING;
        trainingBooking.Booking_Route__c = bg_TrainingUtils.INTERNAL_BOOKING_ROUTE;
        trainingBooking.Delay_Invoice__c = true;
        bg_TrainingUtils.createEnrollmentsForDelegates(wrapper);

        //online
        trainingBooking.Payment_Status__c = bg_TrainingUtils.BOOKING_PAYMENT_ONLINE;
        trainingBooking.Booking_Route__c = bg_TrainingUtils.ONLINE_BOOKING_ROUTE;
        bg_TrainingUtils.createEnrollmentsForDelegates(wrapper);
    }

    @isTest static void testDeleteOrphanedTrainingBookings(){
        Pricebook2 testPB = new Pricebook2();
        testPB.Name = 'Nicks Test PB';
        testPB.Year__c = '2016';
        insert testPB;
        Quote__c testQuote = new Quote__c();
        insert testQuote;
        Quote_Product__c testQuoteProduct = new Quote_Product__c();
        testQuoteProduct.Quote_Ref__c = testQuote.Id;
        testQuoteProduct.Price_Book__c = testPB.Id;
        testQuoteProduct.Price_Book_Name__c = testPB.Name;
        insert testQuoteProduct;
        Quote_Part__c testQuotePart = new Quote_Part__c();
        testQuotePart.Quote_Product__c = testQuoteProduct.Id;
        testQuotePart.Quote_Ref__c = testQuote.Id;
        insert testQuotePart;

        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Training_Event__c testTrainingEvent = bg_TrainingUnitTestHelper.createTrainingEventWithDependancies('GBP', product.Id, 10, Date.Today()+5, 'Active', 'EMS12345ENUK','Yes'); //JS Edit 200120

        TrainingBooking__c testTrainingBooking = new TrainingBooking__c();
        testTrainingBooking.Quote_Part__c = testQuotePart.Id;
        testTrainingBooking.Training_Event__c = testTrainingEvent.Id;
        testTrainingBooking.Number_of_Delegates__c = 2;
        insert testTrainingBooking;

        List<TrainingBooking__c> results = [SELECT Id FROM TrainingBooking__c WHERE Quote_Part__c = :testQuotePart.Id];
        System.assertEquals(1, results.size());     
        
        delete testQuotePart;
        
        results = [SELECT Id FROM TrainingBooking__c WHERE Quote_Part__c = :testQuotePart.Id];
        System.assertEquals(0, results.size());
    }

    @isTest static void testDeriveEnrollmentAccomodationFromDelegate(){
        Training_Event__c te = TestDataUtility.insertTrainingEvent(Date.today() + 5, true);

        TrainingBooking__c tb = new TrainingBooking__c(Training_Event__c = te.Id);
        insert tb;

        TrainingDelegate__c tg1 = new TrainingDelegate__c(Training_Booking__c = tb.Id);
        insert tg1;
        bg_TrainingUtils.deriveEnrollmentAccomodationFromDelegate(tg1);

        TrainingDelegate__c tg2 = new TrainingDelegate__c(Training_Booking__c = tb.Id, Accommodation_night_before__c = true);
        insert tg2;
        bg_TrainingUtils.deriveEnrollmentAccomodationFromDelegate(tg2);
    }

    // MD SoW034 ADDITIONS
    @isTest static void testGetEventsForCourse(){
        System.assert(bg_TrainingUtils.getEventsForCourse(null).isEmpty());
    }

    @isTest static void testGetEventsForOnlineExam(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, Label.Enrollment_Booking_Status_Booked);
        Product2 course = [SELECT Id FROM Product2];
        bg_TrainingUtils.getEventsForCourse(course.Id);
        bg_TrainingUtils.getEventsForOnlineExam(course.Id,Date.today() + 5);
    }

    @isTest static void testGetRecordTypeId(){
        string rtContactDeveloperName = bg_ContactUtils.RECORD_TYPE_NAME_CLIENTS;
        RecordType rt = [select id,Name from RecordType where SobjectType = 'Contact' and developerName = :rtContactDeveloperName Limit 1];
        Id recordTypeId2 = bg_TrainingUtils.getRecordTypeId(Contact.SobjectType, 'Account Contacts');

        system.assertEquals(rt.Id, recordTypeId2);
    }

    @isTest static void testInstructorMessagenoIcodes(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_TrainingUnitTestHelper.createTrainingCourseProductWithOptionalDependancies('TestCourse', '', 'QMS01001XXXX', 'UTPRODCODE', 5, false, false, false, false, false, true, 500, true, 700);
            Contact instructor = bg_TrainingUnitTestHelper.GetContactTraining('UNITTEST_LASTNAME', 'ICODES', masterVenue.Id);
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5, instructor.Id);

            Test.startTest();
            Training_Event__c updatedEvent = [SELECT Trainer__c, Instructor_Message__c from Training_Event__c where id = :te.id];
            system.assertEquals(instructor.id, updatedEvent.Trainer__c);
            system.assertEquals(Label.Training_Event_Instructor_Message_Course_No_ICodes, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageBespokeCourse(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_TrainingUnitTestHelper.createTrainingCourseProductWithOptionalDependancies('TestCourse', 'ICODES', 'QMS01001XXXX', 'UTPRODCODE', 5, false, true, false, false, false, true, 500, true, 700);
            Contact instructor = bg_TrainingUnitTestHelper.GetContactTraining('UNITTEST_LASTNAME', 'ICODES', masterVenue.Id);
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5, instructor.Id);

            Test.startTest();
            Training_Event__c updatedEvent = [SELECT Instructor_Message__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_Bespoke_Course, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessgageNoInstructorAssigned(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            SystemSetting__c cs = bg_UnitTestHelper.GetSystemSettings();
            cs.SkipValidationRule__c = true;
            update cs;
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_TrainingUnitTestHelper.createTrainingCourseProductWithOptionalDependancies('TestCourse', 'ICODES', 'QMS01001XXXX', 'UTPRODCODE', 5, false, false, false, false, false, true, 500, true, 700);
            //Contact instructor = bg_TrainingUnitTestHelper.GetContactTraining('UNITTEST_LASTNAME', 'ICODES', masterVenue.Id);
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5, null);

            Test.startTest();
            Training_Event__c updatedEvent = [SELECT Instructor_Message__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_None, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageOneDoesNotMatchSkills(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_TrainingUnitTestHelper.createTrainingCourseProductWithOptionalDependancies('TestCourse', 'ICODE1,ICODE2', 'QMS01001XXXX', 'UTPRODCODE', 5, false, false, false, false, false, true, 500, true, 700);
            Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode3,Icode4', masterVenue.id);
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

            Test.startTest();
            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            String error = string.format(Label.Training_Event_Instructor_Message_Errors, new list<string>{trainer.FirstName + ' ' + trainer.LastName});
            system.assertEquals(error, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageOneDoesMatchSkills(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_TrainingUnitTestHelper.createTrainingCourseProductWithOptionalDependancies('TestCourse', 'ICODE1,ICODE2', 'QMS01001XXXX', 'UTPRODCODE', 5, false, false, false, false, false, true, 500, true, 700);
            Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','ICODE1,ICODE2', masterVenue.id);
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

            Test.startTest();
            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_All_Good, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageObserver(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_TrainingUnitTestHelper.getProductTraining('Test Course','Icode1,Icode2');
            Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
            Contact trainer2 = bg_TrainingUnitTestHelper.getContactTraining('Trainer2','Icode3,Icode4', masterVenue.id);
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

            Test.startTest();
            te.Observer_Tutor__c = 'true';
            te.Trainer_2nd__c = trainer2.id;
            update te;

            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_All_Good, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageTrainer2NotObserverError(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.getProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        System.runAs(user1)
        {
            Test.startTest();

            bg_TrainingUtils.firstRun = true;
            Contact trainer2 = bg_TrainingUnitTestHelper.getContactTraining('Trainer2','Icode3,Icode4', masterVenue.id);
            te.Trainer_2nd__c = trainer2.id;
            update te;

            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            String error = string.format(Label.Training_Event_Instructor_Message_Errors, new list<string>{trainer2.FirstName + ' ' + trainer2.LastName});
            system.assertEquals(error, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageTrainer2NotObserverSuccess(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.getProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        System.runAs(user1)
        {
            Test.startTest();

            bg_TrainingUtils.firstRun = true;
            Contact trainer2 = bg_TrainingUnitTestHelper.getContactTraining('Trainer2','Icode2,Icode1', masterVenue.id);
            te.Trainer_2nd__c = trainer2.id;
            update te;

            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_All_Good, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageAllTrainersSuccess(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.getProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        System.runAs(user1)
        {
            Test.startTest();

            bg_TrainingUtils.firstRun = true;
            Contact trainer2 = bg_TrainingUnitTestHelper.getContactTraining('Trainer2','Icode2,Icode1', masterVenue.id);
            Contact trainer3 = bg_TrainingUnitTestHelper.getContactTraining('Trainer3','Icode2,Icode1', masterVenue.id);
            Contact trainer4 = bg_TrainingUnitTestHelper.getContactTraining('Trainer4','Icode2,Icode1', masterVenue.id);
            Contact trainer5 = bg_TrainingUnitTestHelper.getContactTraining('Trainer5','Icode2,Icode1', masterVenue.id);
            te.Trainer_2nd__c = trainer2.id;
            te.Instructor_3rd__c = trainer3.id;
            te.Instructor_4th__c = trainer4.id;
            te.Instructor_5th__c = trainer5.id;
            update te;

            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_All_Good, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageTrainers3And4And5Error(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.getProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        System.runAs(user1)
        {
            Test.startTest();

            bg_TrainingUtils.firstRun = true;
            Contact trainer2 = bg_TrainingUnitTestHelper.getContactTraining('Trainer2','Icode2,Icode1', masterVenue.id);
            Contact trainer3 = bg_TrainingUnitTestHelper.getContactTraining('Trainer3','Icode3,Icode4', masterVenue.id);
            Contact trainer4 = bg_TrainingUnitTestHelper.getContactTraining('Trainer4','Icode5,Icode6', masterVenue.id);
            Contact trainer5 = bg_TrainingUnitTestHelper.getContactTraining('Trainer5','Icode7,Icode8', masterVenue.id);
            te.Trainer_2nd__c = trainer2.id;
            te.Instructor_3rd__c = trainer3.id;
            te.Instructor_4th__c = trainer4.id;
            te.Instructor_5th__c = trainer5.id;
            update te;

            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            String error = string.format(Label.Training_Event_Instructor_Message_Errors, 
                new list<string>{trainer3.FirstName + ' ' + trainer3.LastName + ', ' + trainer4.FirstName + ' ' + trainer4.LastName + ', ' + trainer5.FirstName + ' ' + trainer5.LastName});
            system.assertEquals(error, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageProductUpdateICode(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.getProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        System.runAs(user1)
        {
            Test.startTest();

            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_All_Good, updatedEvent.Instructor_Message__c);

            bg_TrainingUtils.firstRun = true;
            // update product course icodes
            product.I_codes_Required__c = 'Icode3,Icode4';
            update product;

            updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            String error = string.format(Label.Training_Event_Instructor_Message_Errors, 
                new list<string>{trainer.FirstName + ' ' + trainer.LastName});
            system.assertEquals(error, updatedEvent.Instructor_Message__c);

            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageProductUpdateBespokeEvent(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.getProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        System.runAs(user1)
        {
            Test.startTest();

            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_All_Good, updatedEvent.Instructor_Message__c);

            bg_TrainingUtils.firstRun = true;
            // update product course icodes
            product.Bespoke_Event__c = true;
            update product;

            updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_Bespoke_Course, updatedEvent.Instructor_Message__c);

            Test.stopTest();
        }
    }

    public static testmethod void testInstructorMessageContactUpdateTrainerICode(){
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.getProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.getContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        System.runAs(user1)
        {
            Test.startTest();

            // trainer has correct qualification
            Training_Event__c updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            system.assertEquals(Label.Training_Event_Instructor_Message_All_Good, updatedEvent.Instructor_Message__c);

            bg_TrainingUtils.firstRun = true;

            // update trainer to no have correct qualifications
            // should fire off AU trigger on contact to update training event
            trainer.I_Codes_text__c = 'Icode3,Icode4';
            update trainer;

            updatedEvent = [SELECT Instructor_Message__c, Trainer__c from Training_Event__c where id = :te.id];
            String error = string.format(Label.Training_Event_Instructor_Message_Errors, 
                new list<string>{trainer.FirstName + ' ' + trainer.LastName});
            system.assertEquals(error, updatedEvent.Instructor_Message__c);
            Test.stopTest();
        }
    }

    public static testMethod void testManageTrainingSMOUpdateRecords()
    {
        // insert training event
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Training_Event__c testTrainingEvent = bg_TrainingUnitTestHelper.createTrainingEventWithDependancies('GBP', product.Id, 10, Date.Today()+5, 'Active', 'EMS12345ENUK', 'Yes'); //JS edit 200120
        
        // update training event SMO
        testTrainingEvent.SAP_SMO_number__c = 'UTSMO12';
        update testTrainingEvent;

        test.startTest();
            bg_TrainingUtils.runningTrainingCreateSMOUpdates = true;
            // update training event SMO and start date
            testTrainingEvent.Start_Date__c = testTrainingEvent.Start_Date__c.addDays(5);
            //testTrainingEvent.Event_status__c = 'Cancelled';

            // update training event
            update testTrainingEvent;
            
            bg_TrainingUtils.runningTrainingCreateSMOUpdates = true;
            // update training event SMO and start date
            //testTrainingEvent.Start_Date__c = testTrainingEvent.Start_Date__c.addDays(5);
            testTrainingEvent.Event_status__c = 'Cancelled';

            // update training event
            update testTrainingEvent;           
        test.stopTest();
    }

    @isTest static void testManageEventConfirmation(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);

        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        Training_Event__c te = [SELECT Id FROM Training_Event__c];
        te.Event_Confirmed__c = true;
        update te;

        Enrollment__c e = [SELECT Email_Changes__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assert(e.Email_Changes__c);
        /*System.assert(e.Course_Confirmed_Email_Sent__c != null);   JS commenting out temporarily 29042021*/ 
    }

    @isTest static void testProcessOnHold(){
        Product2 testProduct = new Product2();
        testproduct.Name = 'test product';
        insert testProduct;

        Pricebook2 testPriceBook2 = new Pricebook2();
        testPriceBook2.Name = 'anotherTestPricebook';
        testPriceBook2.Year__c = String.valueOf(Date.today().year());
        testPriceBook2.IsActive = true;
        insert testPriceBook2;

        PricebookEntry testPBE2 = new PricebookEntry();
        testPBE2.Product2Id = testProduct.Id;
        testPBE2.Pricebook2Id = testPriceBook2.Id;
        testPBE2.UnitPrice = 20.00;
        testPBE2.IsActive = true;
        insert testPBE2;

        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        testAccount.BillingCountry = 'UK';
        insert testAccount;

        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'testOpportunity';
        testOpp.StageName = 'Sales Engaged';
        testOpp.CloseDate = date.today();
        testOpp.AccountId = testAccount.Id;
        testOpp.Sync_in_Progress__c = true;
        // 05/12/2017 ADS - Updates for new Validation Rule "Americas Customer Type Should Be Populated" on Opportunity
        testOpp.BusinessDrivers__c = 'New Customer';
        insert testOpp;

        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Training_Event__c testTrainingEvent = bg_TrainingUnitTestHelper.createTrainingEventWithDependancies('GBP', product.Id, 10, Date.Today()+5, 'Active', 'EMS12345ENUK', 'Yes');//JS edit 200120

        Training_Translations__c translation = TestDataUtility.insertTrainingTranslation();

        Enrollment__c testEnrolment = new Enrollment__c();
        testEnrolment.Training_Event__c = testTrainingEvent.Id;
        testEnrolment.Training_Translations__c = translation.Id;
        testEnrolment.Booking_Status__c = 'Booked';
        insert testEnrolment;

        OpportunityLineItem testOLI = new OpportunityLineItem();
        testOLI.OpportunityId = testOpp.Id;
        testOLI.Enrollment__c = testEnrolment.Id;
        testOLI.Quantity = 1;
        testOLI.TotalPrice = 10.00;
        testOLI.PricebookEntryId = testPBE2.Id;
        insert testOLI;

        testEnrolment.Booking_Status__c = 'On Hold - Payment (Resit)';
        update testEnrolment;

        oli = [SELECT Enrollment__c, Training_Event__c, SMOScheduledDate__c FROM OpportunityLineItem WHERE Id = :testOLI.Id];
        System.assertEquals(null, oli.Training_Event__c);
    }

    @isTest static void testSyncTrainingBookings(){
        Account acc = bg_TrainingUnitTestHelper.createAccount('UNITTEST', 'GB');
        Contact accPrimaryContact = bg_TrainingUnitTestHelper.createContact(acc.Id, 'CON1', 'GB');
        Site__c HQ_Site = bg_TrainingUnitTestHelper.createSite(acc.Id, accPrimaryContact.Id, 'HQ', 'P05TC0D3', 'GB', 'IT & Telecoms', 'T05B Software Development');
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');

        // Create quote
        Quote__c testQuote = new Quote__c();
        testQuote.Contact__c = accPrimaryContact.Id;
        testQuote.Account__c = acc.Id;
        insert testQuote;

        // Create training event
        Training_Event__c testTrainingEvent = bg_TrainingUnitTestHelper.createTrainingEventWithDependancies('GBP', product.Id, 10, Date.Today()+5, 'Active', 'EMS12345ENUK', 'Yes'); //JS edit 200120
        
        //create configurator product
        Product__c trainingGlobal = bg_TrainingUnitTestHelper.createConfiguratorProduct('Training Global');

        // create quote product
        Quote_Product__c testQuoteProduct = new Quote_Product__c();
        testQuoteProduct.Quote_Ref__c = testQuote.Id;
        testQuoteProduct.Price_Book_Name__c = 'NicksTestPriceBook';
        testQuoteProduct.Site__c = HQ_Site.Id;
        testQuoteProduct.Product_Name__c = trainingGlobal.Id;
        insert testQuoteProduct;

        list<Quote_Part__c> testQuoteParts = new list<Quote_Part__c>();
        
        // create quote part - global training
        Quote_Part__c testQuotePart1 = new Quote_Part__c();
        testQuotePart1.ProductAttribute__c = 'TrainingCourse1';
        testQuotePart1.Quote_Ref__c = testQuote.Id;
        testQuotePart1.Quote_Product__c = testQuoteProduct.Id; 
        testQuotePart1.Info__c = 'Event Code:' + testTrainingEvent.Name + ';';
        testQuotePart1.Description__c = 'UNIT_TEST_QP1';

        testQuoteParts.add(testQuotePart1);

        // create quote part - global training
        Quote_Part__c testQuotePart2 = new Quote_Part__c();
        testQuotePart2.ProductAttribute__c = 'TrainingCourse2';
        testQuotePart2.Quote_Ref__c = testQuote.Id;
        testQuotePart2.Quote_Product__c = testQuoteProduct.Id; 
        testQuotePart2.Info__c = 'Event Code:ADHOC-TRAIN;';
        testQuotePart2.Info__c += 'Date:2014-08-12;';
        testQuotePart2.Info__c += 'Duration:2;';
        testQuotePart2.Info__c += 'Max Seats:2;';
        testQuotePart2.Description__c = 'UNIT_TEST_QP2';
        testQuoteParts.add(testQuotePart2);

        // insert quote parts
        insert(testQuoteParts);
        
        map<Id, Quote_Part__c> quotePartMap = new map<Id, Quote_Part__c>(testQuoteParts);
        
        quotePartMap.putAll([SELECT Id, Name, IsTraining__c
                            FROM Quote_Part__c
                            WHERE Id IN :quotePartMap.keySet()]);

        system.assertEquals(true, quotePartMap.values()[0].IsTraining__c);
        system.assertEquals(true, quotePartMap.values()[1].IsTraining__c);
        
        List<TrainingBooking__c> resultList = [SELECT Id, Name, Quote_Part__c
                                               FROM TrainingBooking__c
                                               WHERE Quote_Part__c IN :quotePartMap.keySet()];


        system.assertEquals(2, resultList.size());
        system.assertEquals(true, quotePartMap.containsKey(resultList[0].Quote_Part__c));
        system.assertEquals(true, quotePartMap.containsKey(resultList[1].Quote_Part__c));

        // check adhoc event
        Training_Event__c adhocTrainingEvent = [SELECT Id, Duration_days__c, Max_seats__c, Start_Date__c, Quote__c
                                                FROM Training_Event__c
                                                WHERE Quote_Part__c = :testQuotePart2.Id
                                                LIMIT 1];

        system.assertNotEquals(null, adhocTrainingEvent);
        system.assertEquals(date.valueOf('2014-08-12'), adhocTrainingEvent.Start_Date__c);
        system.assertEquals(2, adhocTrainingEvent.Duration_days__c);
        system.assertEquals(2, adhocTrainingEvent.Max_seats__c);
        system.assertEquals(testQuote.id, adhocTrainingEvent.Quote__c);
    }

    @isTest static void testTrainingBookingConversionWrapper(){
        setupData();

        //refetch to update Delegate relationship
        trainingBooking = bg_TrainingUtils.fetchBookingsWithDelegatesAndQuotePartsForConversion(new Set<Id>{trainingBooking.Id})[0];

        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        bg_TrainingUtils.TrainingBookingConversionWrapper wrapper = new bg_TrainingUtils.TrainingBookingConversionWrapper(trainingBooking, new List<OpportunityLineItem>(), true);
        wrapper.coursePriceBook = pbe;
        wrapper.includingAccommodationPriceBook = pbe;
        wrapper.excludingAccomodationPriceBook = pbe;
        wrapper.setSuccessMessage('message');
        wrapper.resetBooking();
        wrapper.isReadytoConvert();

        trainingBooking.Converted__c = true;
        wrapper.isReadytoConvert();
    }
    
    @isTest static void testManageEventRevenue(){
        setupData();

        enrollment.Inhouse_Booking_Contact__c = true;
        update enrollment;

        trainingEvent = [SELECT Event_Revenue__c, Course__c FROM Training_Event__c WHERE Id = :trainingEvent.Id];

        Product2 product = [SELECT Id FROM Product2 WHERE Id = :trainingEvent.Course__c];
        product.Course_Delivery__c = Label.In_House;
        update product;

        trainingEvent.Event_Revenue__c = 1000;
        update trainingEvent;

        enrollment = [SELECT Sales_Price__c FROM Enrollment__c WHERE Id = :enrollment.Id];
        System.assertEquals(trainingEvent.Event_Revenue__c, enrollment.Sales_Price__c);
    }
    
    @isTest static void testManageMimeoDistributionAssignment(){
        insert new Mimeo_Settings__c(API__c = 'test');
        
        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today() + 5, true);
        
        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'test1', Active__c = true);

        Test.startTest();
            bg_TrainingUtils.isMimeoDistributionAssignmentFirstRun = true;
            event.Mimeo_Distribution_Assignment__c = true;
            update event;
        Test.stopTest();
        
        event = [SELECT Mimeo_Distribution_Assignment__c, Mimeo_Distribution_Created_Date__c, Mimeo_Distribution_Id__c, Mimeo_Distribution_Link__c FROM Training_Event__c WHERE Id = :event.Id];
        System.assert(event.Mimeo_Distribution_Created_Date__c != null);
        System.debug(event);
    }
}