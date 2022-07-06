/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         01/03/2012
* Description:  TEST CLASS: EchosignTrigger
*
* ------------------
* TRIGGER:		100%
* ------------------
*          RJ 01-06-2014 Updated to use getTestSalesUser 
*          JA 01-03-2016 Added bulkTest_signedAgreement_withTrainingBookings
*          RC 04-08-2017 Removed creating an HQ site in bulkTest_signedAgreement_withTrainingBookings as process builder does this now
           PC K2 30-10-2018 populated fields on QuotePart and Booking related to Sales Price calculation
**/
@isTest
private class EchosignTriggerTest {

    static testMethod void signedAgreement() {
    	bg_UnitTestHelper.GetGlobalPricebook();

        // Set up data
        SiteSetting__c s = TestData.getSiteSetting();
        insert s;
        ConversionScore__c c = TestData.getCountryDefault();
        insert c;
        User sales = TestData.getTestSalesUser();
        insert sales;
        Territory__c terr = TestData.getTestTerritory('GB', 'EC');
        terr.AssignedTo__c = sales.Id;
        insert terr;
        Account acc = TestData.getTestAccount();
        acc.BillingCountry = 'GB';
        acc.BillingPostalCode = 'EC';
    	insert acc;
    	Opportunity opp = TestData.getTestOpty();
    	opp.AccountId = acc.Id;
    	insert opp;
    	Contact con = TestData.getTestContact();
    	con.FirstName = 'Nathan';
    	con.LastName = 'Drake';
    	con.AccountId = acc.Id;
    	insert con;
    	Quote__c quote = TestData.getTestQuote(opp.Id, con.Id, acc.Id);
    	quote.SkipCustomer__c = true;
    	insert quote;
    	
    	// Agreement
    	echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
    	agreement.Name = '[Proposal] - Nathan Drake Test Document';
    	agreement.Quote__c = quote.Id;
    	agreement.echosign_dev1__Recipient__c = con.Id;
    	agreement.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;
    	insert agreement;
    	
    	Test.startTest();
    	
    	// Test Out for Signature features
    	agreement.echosign_dev1__Status__c = 'Out for Signature';
    	update agreement;
    	
    	// Check Expected Result
    	Opportunity opty = [SELECT QuoteSent__c, StageName FROM Opportunity WHERE Id =:opp.Id];
    	system.assertEquals(bg_OpportunityUtils.OPPORTUNITY_STAGE_NEGOTIATION, opty.StageName);
    	system.assertEquals(true, opty.QuoteSent__c);
    	
    	// Test Signed Agreement features
    	agreement.echosign_dev1__Status__c = 'Signed';
    	update agreement;

    	// Check Expected Result
    	opty = [SELECT QuoteSent__c, StageName FROM Opportunity WHERE Id =:opp.Id];
    	system.assertEquals(bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING, opty.StageName);

    	// Check Expected Result
    	QuoteSetting__c setting = QuoteSetting__c.getInstance();
    	Quote__c q = [SELECT ValidationStatus__c, ValidatedBy__c FROM Quote__c WHERE Id =:quote.Id];
    	System.assertEquals(q.ValidationStatus__c, setting.StatusApproved__c);
    	System.assertEquals(q.ValidatedBy__c, 'Nathan Drake');
    	
    	Test.stopTest();
    }

    static testmethod void bulkTest_signedAgreement_withTrainingBookings()
    {
        final Integer BULK_NUM_RECORDS = 5;
        bg_UnitTestHelper.GetGlobalPricebook();

        // Set up data
        SiteSetting__c siteSetting = TestData.getSiteSetting();
        insert siteSetting; //TODO
        ConversionScore__c convScore = TestData.getCountryDefault();
        insert convScore; //TODO

        User salesUser = TestData.getTestSalesUser();
        insert salesUser;

        Territory__c terr = TestData.getTestTerritory('GB', 'EC');
        terr.AssignedTo__c = salesUser.Id;
        insert terr;

        Utility.lockCreateHqSite = true;
        Account acc = TestData.getTestAccount();
        acc.BillingCountry = 'GB';
        acc.BillingPostalCode = 'EC';
        insert acc;

        Opportunity opp = TestData.getTestOpty();
        opp.AccountId = acc.Id;
        insert opp;

        Contact con = TestData.getTestContact();
        con.FirstName = 'Nathan';
        con.LastName = 'Drake';
        con.AccountId = acc.Id;
        insert con;

        List<Site__c> siteList = new List<Site__c>();
        for(Integer i = 0; i < BULK_NUM_RECORDS; i++)
        {
            Site__c site = bg_TrainingUnitTestHelper.createSite(acc.Id, con.Id, 'Site'+i, 'P05TC0D3'+i, 'GB', 'IT & Telecoms', 'T05B Software Development');
            siteList.add(site);
        }

        Quote__c quote = TestData.getTestQuote(opp.Id, con.Id, acc.Id);
        quote.SkipCustomer__c = true;
        insert quote;

        // Insert training venue

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        //insert masterVenue;
        Training_Venue__c trainingVenue = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        //insert trainingVenue;
        Contact instructor = bg_TrainingUnitTestHelper.GetContactTraining('UNITTEST_LASTNAME', 'ICODES', masterVenue.Id);
        //insert instructor;


        List<Product__c> productList = new List<Product__c>();
        List<Product2> product2List = new List<Product2>();
        //create configurator products
        for(Integer i = 0; i < BULK_NUM_RECORDS; i++)
        {
            Product__c trainingGlobal = bg_TrainingUnitTestHelper.getConfiguratorProduct('Training Global '+i);
            productList.add(trainingGlobal);
            Product2 product = bg_TrainingUnitTestHelper.CreateProductTraining('Test Course '+i,'Icode1,Icode2');
            product2List.add(product);
        }
        
        insert productList;
        insert product2List;

        List<Training_Event__c> trainingEventList = new List<Training_Event__c>();
        // Insert training event
        for(Integer i = 0; i < BULK_NUM_RECORDS; i++)
        {
            Training_Event__c trainingEvent = bg_TrainingUnitTestHelper.getTrainingEvent(trainingVenue,'GBP', 5, product2List[i], Date.today()+5, instructor.Id);

            trainingEventList.add(trainingEvent);
        }
        insert trainingEventList;
        trainingEventList = [SELECT Name FROM Training_Event__c];


        List<Quote_Product__c> quoteProductList = new List<Quote_Product__c>();
        List<Quote_Part__c> quotePartList = new List<Quote_Part__c>();

        // Create quote products
        for(Integer i = 0; i < BULK_NUM_RECORDS; i++)
        {
            Quote_Product__c quoteProduct = bg_TrainingUnitTestHelper.getQuoteProduct('TestPBook' + i, quote.Id, siteList[i].Id, productList[i].Id);
            quoteProductList.add(quoteProduct);
        }
        insert quoteProductList;


        // Create quoteParts
        for(Integer i = 0; i < BULK_NUM_RECORDS; i++)
        {
            Quote_Part__c quotePart = bg_TrainingUnitTestHelper.getQuotePart(quoteProductList[i].Id, quote.Id);
            quotePart.ProductAttribute__c = 'TrainingCourse'+i;
            quotePart.Quote_Ref__c = quote.Id;
            quotePart.Quote_Product__c = quoteProductList[i].Id; 
            //quotePart.Info__c = 'Event Code:' + trainingEventList[i].Name + ';';
            //quotePart.Info__c = 'Event Code: test '+i+';';
            //quotePart.infoTxt__c = 'Event Code:T-00000000;Accomodation:4;Extra Nights:0;Reduction:0%;';
            quotePart.Info__c = 'Event Code:ADHOC-TRAIN;';
            quotePart.Info__c += 'Date:2014-08-12;';
            quotePart.Info__c += 'Duration:2;';
            quotePart.Info__c += 'Max Seats:2;';
            quotePart.Description__c = 'UNIT_TEST_QP'+i;
            quotePart.Discount_Percentage__c = 0;
            quotePart.Exchange_Rate__c = 1;
            quotePart.Price__c = 500;
            quotePart.Number__c = 1;
            quotePartList.add(quotePart);
        }
        insert quotePartList;

        // Update training bookings
        Training_Translations__c translation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;
        List<TrainingBooking__c> tbList = new List<TrainingBooking__c>();
        for (TrainingBooking__c tb : [SELECT Id, Training_Translations__c FROM TrainingBooking__c])
        {
            tb.Training_Translations__c = translation.Id;
            tb.Price_Per_Delegate__c = 1000;
            tb.Price_Per_Delegate_Accommodation__c = 300;
            tb.Price_Per_Delegate_Extra_Night__c = 200;
            tbList.add(tb);
        }
        update tbList;

        // Update Delegates
        List<TrainingDelegate__c> delegateList = [SELECT Id, First_Name__c, Last_Name__c, Email_Address__c FROM TrainingDelegate__c];
        for (Integer i = 0; i < delegateList.size(); i++)
        {
            delegateList[i].First_Name__c = 'fname' + i;
            delegateList[i].Last_Name__c = 'lname' + i;
            delegateList[i].Email_Address__c = 'email' + i + '@test.com';
        }
        update delegateList;

        // Insert agreement
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        agreement.Name = '[Proposal] -  Test Proposal';
        agreement.Quote__c = quote.Id;
        agreement.echosign_dev1__Recipient__c = con.Id;
        agreement.Template_Type__c = bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL;
        insert agreement;


        //Sign EchoSign Agreements
        Test.startTest();

        //Signing the echosign record should convert all of the training bookings on the opportunity
        agreement.echosign_dev1__Status__c = bg_DocumentUtils.DOCUMENT_STATUS_SIGNED;
        update agreement;

        Test.stopTest();

        // Query out Bookings
        List<TrainingBooking__c> bookingList = [SELECT Id, Status__c, Converted__c, Conversion_Error__c FROM TrainingBooking__c];
        System.assertEquals(BULK_NUM_RECORDS, bookingList.size());
        System.debug(logginglevel.error, '**Booking List** ' + bookingList);

        //Governor limits
        System.debug(logginglevel.error, 'GOV LIMIT (SOQL): ' + Limits.getQueries());
        System.debug(logginglevel.error, 'GOV LIMIT (SOQL Rows): ' + Limits.getQueryRows());
        System.debug(logginglevel.error, 'GOV LIMIT (DML): ' + Limits.getDMLStatements());
        System.debug(logginglevel.error, 'GOV LIMIT (DML Rows): ' + Limits.getDMLRows());

        // Assertions
        //System.debug(logginglevel.ERROR, 'JA** Booking = ' + bookingList);
        for(TrainingBooking__c booking : bookingList)
        {
            System.assert(booking.Converted__c);
            System.assert(!booking.Conversion_Error__c);
        }
    }
}