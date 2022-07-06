public with sharing class AwinTrackingHandler {
    @TestVisible private static HttpResponse response;

    @future(callout=true)
    public static void sendRequest(Decimal amount, String promotionalCode, String currencyIsoCode, String bookingId, String awc) {
        Awin_Settings__c awinSettings = Awin_Settings__c.getInstance('Awin_Tracking');

        String endpoint = awinSettings.Endpoint_Url__c;
        String merchantId = awinSettings.Merchant_Id__c;
        Decimal testMode = awinSettings.Test_Mode__c;
        String channel = awinSettings.Channel__c;
        // String awc = '25134_1635427316_ae7f3122a40e0f3e9c9c580e143eb12f';

        if (promotionalCode == null) promotionalCode = '';
        if (awc == null) awc = '';

        String endpointUrl = 'https://' + endpoint + '?tt=ss&tv=2&merchant=' + merchantId +
            '&amount=' + amount + '&ch=' + channel + '&parts=DEFAULT:' + amount + '&vc=' + promotionalCode +
            '&cr=' + currencyIsoCode + '&ref=' + bookingId + '&testmode=' + Integer.valueOf(testMode) +
            '&cks=' + awc;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');

        response = http.send(request);

        if (response.getStatusCode() != 200 && response.getStatusCode() != 204) {
            system.debug('response1 ' + response);

            TrainingBooking__c booking = [SELECT AWIN_Fail_Response__c FROM TrainingBooking__c WHERE Id = :bookingId];
            booking.AWIN_Fail_Response__c = 'Status Code: ' + response.getStatusCode() + 
                '; Status: ' + response.getStatus() + '; ' + response.getBody();

            update booking;
        }
    }
}