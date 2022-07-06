/********************************************************************
 * bg_EmailUtils
 *
 * Test class for bg_DiscountUtils
 * 
 * Author: Alexis Lignereux
 * Created: 05-01-2015
 * Changes: 
 ********************************************************************/
@isTest
private class bg_EmailUtilsTest {

/*
    @isTest(SeeAllData=true) 
    static void testSendOnlineBookingReceived()
    {

        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_UnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_UnitTestHelper.GetContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 2, product, Date.today()+5,trainer);

        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        Product2 prd3 = TrainingBookingTestData.createTestCourse('Exam','EMS12345ENUK', null);

        // Set up price book entries
        Pricebook2 std = bg_UnitTestHelper.GetStandardPricebook();
        PriceBookEntry pbe3 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd3.id);
        PricebookEntry pbe1 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd1.id);
        PricebookEntry pbe2 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd2.id);

        // todo create a traning translation test method
        Training_Translations__c translation = bg_UnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;

        TrainingBooking__c booking = bg_UnitTestHelper.GetTrainingBooking(te, pbe1, pbe2, translation);
        booking.Pricebook_Entry__c = pbe3.Id;
        booking.Price_Per_Delegate__c = 50.00;
        booking.CurrencyIsoCode = 'USD';
        booking.Country_ISO_Code__c = 'GB';
        insert booking;

        // Setup a booker delegate
        TrainingDelegate__c delegate1 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate1', null, null, 
            'a@a.com', null, true, null);
        delegate1.Is_Booker__c = true;
        update delegate1;

        TrainingDelegate__c delegate2 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate2', null, null, 
            'a2@a.com', null, false, null);

        // Account and contacts
        Account acc = bg_UnitTestHelper.GetAccount('Test Account');
        Contact con = bg_UnitTestHelper.GetContact('Test Contact 1', acc);
        con.Email = 'bsi.sfdc@brightgen.com';
        update con;

        Test.startTest();

        TrainingBooking__c updatedBooking = [SELECT Confirmation_Emails_Sent__c from TrainingBooking__c where id = :booking.id];
        system.assertEquals(null,updatedBooking.Confirmation_Emails_Sent__c);

        translation.Enable_Online_Booking_Emails__c = true;
        translation.From_Email_Address__c = 'bsi.sfdc@brightgen.com';
        translation.cc_1_Email_Address__c = 'bsi.sfdc@brightgen.com';
        translation.cc_2_Email_Address__c = 'bsi.sfdc@brightgen.com';
        update translation;

        booking.Payment_Method__c = 'Invoice';
        booking.Number_of_Delegates__c = 2;
        booking.Confirmation_Emails_Sent__c = null;
        booking.Source_BSI_Staff__c = 'Test';
        booking.Delegates_Inc_Accommodation__c = 0;
        booking.Delegates_Exc_Accommodation__c = 0;
        booking.Conversion_Contact__c = con.id;
        update booking;

        updatedBooking = [SELECT Confirmation_Emails_Sent__c from TrainingBooking__c where id = :booking.id];
        system.assertNotEquals(null, updatedBooking.Confirmation_Emails_Sent__c);

        Test.stopTest();
    }
*/

/*
    @isTest(SeeAllData=true)
    static void testConfirmationOfPlace() {
        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_UnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_UnitTestHelper.GetContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 2, product, Date.today()+5,trainer);

        // todo create a traning translation test method
        Training_Translations__c translation = bg_UnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;

        // Account and contacts
        Account acc = bg_UnitTestHelper.GetAccount('Test Account');
        Contact con = bg_UnitTestHelper.GetContact('Test Contact 1', acc);
        con.Email = 'bsi.sfdc@brightgen.com';
        update con;

        Enrollment__c enrolment = bg_UnitTestHelper.GetEnrolment('GBP', con, translation, te, 'No Show');
        insert enrolment;

        Test.startTest();

        Enrollment__c updateEnrolment = [SELECT Email_Confirmation_Sent__c from Enrollment__c where id = :enrolment.Id];
        system.assertEquals(false, updateEnrolment.Email_Confirmation_Sent__c);

        translation.Enable_Confirmation_of_Place_Emails__c = true;
        translation.From_Email_Address__c = 'bsi.sfdc@brightgen.com';
        translation.cc_1_Email_Address__c = 'bsi.sfdc@brightgen.com';
        translation.cc_2_Email_Address__c = 'bsi.sfdc@brightgen.com';
        update translation;

        product.Enable_automated_email_confirmation__c = true;
        product.Description = 'Public';
        update product;

        enrolment.Booking_status__c = 'Booked';
        update enrolment;

        updateEnrolment = [SELECT Email_Confirmation_Sent__c from Enrollment__c where id = :enrolment.Id];
        system.assertEquals(true, updateEnrolment.Email_Confirmation_Sent__c);

        Test.stopTest();
    }
*/    
}