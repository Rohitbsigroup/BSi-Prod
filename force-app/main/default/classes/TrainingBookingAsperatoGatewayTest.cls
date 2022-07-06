/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-01-20
* @group CloudShiftGroup
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 20/01/2021    Jadd Ennaciri      Created Class
*
*/

@IsTest
private class TrainingBookingAsperatoGatewayTest {
    
    @TestSetup
    private static void setup() {
        asp04__AsperatoOneSettings__c asperatoSettings = new asp04__AsperatoOneSettings__c(
            asp04__Customer_ID__c = '2820',
            asp04__Is_Live__c = false,
            asp04__Server_URL__c = 'test.protectedpayments.net',
            asp04__BACS_Delay__c = 4,
            asp04__CreatePaymentSchedule__c = true
        );
        insert asperatoSettings;
        //setup account
        Account acc = bg_UnitTestHelper.CreateAccount();
        insert acc;
        // Set up a venue
        Training_Venue__c ven = TrainingBookingTestData.createTestVenue();
        
        Contact con = bg_UnitTestHelper.CreateContact('Test', acc);
        con.Country_Office__c = ven.Id;
        insert con;

        // Set up product #1 (non-residential)
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        
        // Set up product #2 (residential)
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        
        // Setup an event
        Training_Event__c evt = TrainingBookingTestData.createTestEvent(prd1, ven, 10 , con.Id);
        
        // Set up price book entries
        Id std1 = Test.getStandardPricebookId();
        PricebookEntry pbe1 = TrainingBookingTestData.createTestPbe(prd1, 100, 'GBP');
        PricebookEntry pbe2 = TrainingBookingTestData.createTestPbe(prd2, 200, 'GBP');
        
        // Setup the booking for a residential event (1 delegate with accommodation, 1 without)
        TrainingBooking__c booking = TrainingBookingTestData.createTestBooking(evt, pbe1, pbe2);
        
        asp04__Payment__c payment = new asp04__Payment__c(
            asp04__Amount__c = booking.Total_Price__c,
            asp04__Company_Name__c = booking.Billing_Name__c,
            asp04__Billing_Address_City__c = booking.Billing_City__c,
            asp04__Billing_Address_Country__c = booking.Billing_Country__c,
            asp04__Billing_Address_PostalCode__c = booking.Billing_Postcode__c,
            asp04__Billing_Address_Street__c = booking.Billing_Street__c,
            asp04__First_Name__c = booking.First_Name__c,
            asp04__Last_Name__c = booking.Last_Name__c,
            asp04__Email__c = booking.Email_Address__c,
            Training_Booking__c = booking.Id
        );
        insert payment;
    }
    
    @IsTest
    private static void testSuccessfulPayment() {
        TrainingBooking__c booking = [SELECT Id FROM TrainingBooking__c LIMIT 1];
        asp04__Payment__c payment = [SELECT Id FROM asp04__Payment__c LIMIT 1];
        System.debug(payment);
        Test.startTest();
        // Set the current page to TrainingBookingAsperatoGateway
        Test.setCurrentPageReference(Page.TrainingBookingAsperatoGateway);
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        ApexPages.currentPage().getParameters().put('CT', 'HK');
        ApexPages.currentPage().getParameters().put('paymentId', payment.Id);
        TrainingBookingAsperatoGatewayController controller = new TrainingBookingAsperatoGatewayController();
        PageReference init = controller.successPage();
        Test.stopTest();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking6'));
    }
    
    @IsTest
    private static void testUnsuccessfulPayment() {
        TrainingBooking__c booking = [SELECT Id FROM TrainingBooking__c LIMIT 1];
        asp04__Payment__c payment = [SELECT Id FROM asp04__Payment__c LIMIT 1];
        System.debug(payment);
        Test.startTest();
        // Set the current page to TrainingBookingAsperatoGateway
        Test.setCurrentPageReference(Page.TrainingBookingAsperatoGateway);
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        ApexPages.currentPage().getParameters().put('CT', 'HK');
        ApexPages.currentPage().getParameters().put('paymentId', payment.Id);
        TrainingBookingAsperatoGatewayController controller = new TrainingBookingAsperatoGatewayController();
        PageReference init = controller.errorPage();
        Test.stopTest();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));
    }
    
    @IsTest
    private static void testInvoiceInstead() {
        TrainingBooking__c booking = [SELECT Id FROM TrainingBooking__c LIMIT 1];
        asp04__Payment__c payment = [SELECT Id FROM asp04__Payment__c LIMIT 1];
        System.debug(payment);
        Test.startTest();
        // Set the current page to TrainingBookingAsperatoGateway
        Test.setCurrentPageReference(Page.TrainingBookingAsperatoGateway);
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        ApexPages.currentPage().getParameters().put('CT', 'HK');
        ApexPages.currentPage().getParameters().put('paymentId', payment.Id);
        TrainingBookingAsperatoGatewayController controller = new TrainingBookingAsperatoGatewayController();
        PageReference init = controller.invoiceInstead();
        Test.stopTest();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking6'));
    }
    
    
     @IsTest //JS added 08/04/2021 to increase coverage
    private static void testPaymentCancelledPage() {
        TrainingBooking__c booking = [SELECT Id FROM TrainingBooking__c LIMIT 1];
        asp04__Payment__c payment = [SELECT Id FROM asp04__Payment__c LIMIT 1];
        System.debug(payment);
        Test.startTest();
        // Set the current page to TrainingBookingAsperatoGateway
        Test.setCurrentPageReference(Page.TrainingBookingAsperatoGateway);
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        ApexPages.currentPage().getParameters().put('CT', 'HK');
        ApexPages.currentPage().getParameters().put('paymentId', payment.Id);
        TrainingBookingAsperatoGatewayController controller = new TrainingBookingAsperatoGatewayController();
        PageReference init = controller.paymentCancelledPage();
        Test.stopTest();
        System.assert(init.getUrl().startsWith('/apex/trainingbookingpaymentcancelled'));
    }
    
}