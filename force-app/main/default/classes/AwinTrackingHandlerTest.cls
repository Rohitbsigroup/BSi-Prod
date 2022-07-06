@isTest
private class AwinTrackingHandlerTest {
    @testSetup
    static void createData(){
        Awin_Settings__c awinSettings = new Awin_Settings__c (
            Name = 'Awin_Tracking',
            Endpoint_Url__c = 'www.awin1.com/sread.php',
            Merchant_Id__c = '25134',
            Test_Mode__c = 1.0,
            Channel__c = 'aw'
        );
        insert awinSettings;

        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today(), true);

        TrainingBooking__c booking = new TrainingBooking__c (
            First_Name__c = 'Test Booking', 
            Training_Event__c = event.Id
        );
        insert booking;
    }

    @isTest 
    static void sendDataToAwin() {
        Test.setMock(HttpCalloutMock.class, new AwinTrackingMockHttpResponseGenerator());

        TrainingBooking__c booking = [SELECT Id, AWIN_Fail_Response__c FROM TrainingBooking__c][0];

        // Test data for sending to Awing
        Decimal amount = 1668.60;
        String promotionalCode = 'TESTUK10';
        String currencyIsoCode = 'GBP';
        String bookingId = booking.Id;
        String awc = '25134_1635427316_ae7f3122a40e0f3e9c9c580e143eb12f';

        Test.startTest();
            AwinTrackingHandler.sendRequest(
                amount, promotionalCode, currencyIsoCode, bookingId, awc
            );
        Test.stopTest();

        booking = [SELECT Id, AWIN_Fail_Response__c FROM TrainingBooking__c][0];

        HttpResponse res = AwinTrackingHandler.response;

        System.assert(res.getHeader('Content-Type') == 'application/json');
        System.assertEquals(res.getBody(), '');
        System.assertEquals(404, res.getStatusCode());

        String awinResponseMessage = 'Status Code: 404; Status: Not Found;';
        System.assertEquals(booking.AWIN_Fail_Response__c, awinResponseMessage);
    }
}