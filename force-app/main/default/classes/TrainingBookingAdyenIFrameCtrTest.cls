/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-06-18
* @group CloudShiftGroup
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 18/06/2021    Jadd Ennaciri      Created Class
*
*/

@IsTest
private class TrainingBookingAdyenIFrameCtrTest {

    public class MockResponsePaymentMethods implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"paymentMethods":[{"name":"카드결제","type":"kcp_creditcard"},{"name":"실시간 계좌이체","type":"kcp_banktransfer"},{"brands":["mc","visa","amex","korean_local_card"],"details":[{"key":"encryptedCardNumber","type":"cardToken"},{"key":"encryptedSecurityCode","type":"cardToken"},{"key":"encryptedExpiryMonth","type":"cardToken"},{"key":"encryptedExpiryYear","type":"cardToken"},{"key":"holderName","optional":true,"type":"text"}],"name":"신용카드","type":"scheme"}]}');
            response.setStatusCode(200);
            return response;
        }
    }

    public class MockResponsePaymentDetails implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"pspReference":"852623971867537H","resultCode":"Authorised","merchantReference":"a2F3L00000093S0UAI"}');
            response.setStatusCode(200);
            return response;
        }
    }

    public class MockResponseMakePayment implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"pspReference":"852623971867537H","resultCode":"Authorised","merchantReference":"a2F3L00000093S0UAI"}');
            response.setStatusCode(200);
            return response;
        }
    }

    @TestSetup
    private static void setup() {
        Adyen_Settings__c adyenSettings = new Adyen_Settings__c(
            Name = 'Korea',
            API_KEY__c = 'test',
            MERCHANT_ACCOUNT__c = 'test',
            CLIENT_KEY__c = 'test.protectedpayments.net',
            ENVIRONMENT__c = 'test',
            LOCALE__c = 'ko-KR',
            ENDPOINT__c = 'https://checkout-test.adyen.com'
        );
        insert adyenSettings;

        Account acc = bg_UnitTestHelper.CreateAccount();
        insert acc;
        // Set up a venue
        Training_Venue__c ven = TrainingBookingTestData.createTestVenue();

        Contact con = bg_UnitTestHelper.CreateContact('Test', acc);
        con.Country_Office__c = ven.Id;
        con.OtherCountry = 'KR';
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
    }

    @IsTest
    private static void testSuccessfulPayment() {
        TrainingBooking__c booking = [SELECT Id FROM TrainingBooking__c LIMIT 1];
        Test.startTest();
        // Set the current page to TrainingBookingAdyen
        Test.setCurrentPageReference(Page.TrainingBookingAdyen);
        ApexPages.currentPage().getParameters().put('L', 'KO');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        ApexPages.currentPage().getParameters().put('CT', 'KR');
        Test.setMock(HttpCalloutMock.class, new MockResponsePaymentMethods());
        TrainingBookingAdyenIFrameCtr controller = new TrainingBookingAdyenIFrameCtr();
        Test.setMock(HttpCalloutMock.class, new MockResponsePaymentDetails());
        controller.getPaymentDetails('test');
        PageReference init = controller.successPage();
        Test.stopTest();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking6'));
    }

    @IsTest
    private static void testInvoiceInstead() {
        TrainingBooking__c booking = [SELECT Id FROM TrainingBooking__c LIMIT 1];
        Test.startTest();
        // Set the current page to TrainingBookingAdyen
        Test.setCurrentPageReference(Page.TrainingBookingAdyen);
        ApexPages.currentPage().getParameters().put('L', 'KO');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        ApexPages.currentPage().getParameters().put('CT', 'KR');
        Test.setMock(HttpCalloutMock.class, new MockResponsePaymentMethods());
        TrainingBookingAdyenIFrameCtr controller = new TrainingBookingAdyenIFrameCtr();
        PageReference init = controller.invoiceInstead();
        Test.stopTest();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking6'));
    }

    @IsTest
    private static void testGetPaymentDetails() {
        TrainingBooking__c booking = [SELECT Id FROM TrainingBooking__c LIMIT 1];
        Test.startTest();
        // Set the current page to TrainingBookingAdyen
        Test.setCurrentPageReference(Page.TrainingBookingAdyen);
        ApexPages.currentPage().getParameters().put('L', 'KO');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        ApexPages.currentPage().getParameters().put('CT', 'KR');
        Test.setMock(HttpCalloutMock.class, new MockResponsePaymentMethods());
        TrainingBookingAdyenIFrameCtr controller = new TrainingBookingAdyenIFrameCtr();
        Test.setMock(HttpCalloutMock.class, new MockResponsePaymentDetails());
        String response = controller.getPaymentDetails('test');
        Test.stopTest();
        System.assertNotEquals(null, response, 'failed to retrieve response');
    }

    @IsTest
    private static void testMakePayment() {
        TrainingBooking__c booking = [SELECT Id FROM TrainingBooking__c LIMIT 1];
        Test.startTest();
        // Set the current page to TrainingBookingAdyen
        Test.setCurrentPageReference(Page.TrainingBookingAdyen);
        ApexPages.currentPage().getParameters().put('L', 'KO');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        ApexPages.currentPage().getParameters().put('CT', 'KR');
        Test.setMock(HttpCalloutMock.class, new MockResponsePaymentMethods());
        TrainingBookingAdyenIFrameCtr controller = new TrainingBookingAdyenIFrameCtr();
        Test.setMock(HttpCalloutMock.class, new MockResponseMakePayment());
        TrainingBookingAdyenIFrameCtr.PaymentResponse response = TrainingBookingAdyenIFrameCtr.makePayment('{"type":"kcp_creditcard"}', controller.objBooking.currencyIsoCode, controller.objBooking.Total_Price__c, controller.objBooking.Id, 'test', controller.selectedCountry.description);
        Test.stopTest();
        System.assertNotEquals(null, response, 'failed to retrieve response');
    }
}