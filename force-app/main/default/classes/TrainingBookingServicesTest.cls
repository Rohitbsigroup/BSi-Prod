@isTest
private class TrainingBookingServicesTest

{
    static testMethod void myUnitTest()
    {
		// Run the test
		Test.startTest();
		
		// Reference the parent class for coverage
		TrainingBookingServices parent = new TrainingBookingServices();

		// Create an instance of the SOAP service
		TrainingBookingServices.TrainingBookingServiceSoap soap = new TrainingBookingServices.TrainingBookingServiceSoap();

		// Create an authentication header
		TrainingBookingServices.AuthenticationHeader auth = new TrainingBookingServices.AuthenticationHeader();
		auth.UserName = 'tester';
		auth.Password = 'tester';
		soap.AuthenticationHeader = auth;

		// Add the order details
		TrainingBookingServices.TrainingBookingOrder testOrder = new TrainingBookingServices.TrainingBookingOrder();
		testOrder.SalesOrg = '1000';
        testOrder.Currency_x = 'GBP';
        testOrder.Language = 'EN';
        testOrder.PoNumber = '12345';
        testOrder.OrderNumber = '1234567';
        testOrder.OrderDate = DateTime.now();
        testOrder.StartDate = DateTime.now();
        testOrder.EndDate = DateTime.now();
        testOrder.CcAuthorisedType = 'VISA';
        testOrder.CcAuthorisedName = 'TEST CONTACT';
        testOrder.CcAuthorisedDate = DateTime.now();
        testOrder.CcAuthorisedAmount = 100.00;
        testOrder.CcAuthorisationNo = '1234567890';	
		TrainingBookingServices.TrainingBookingAddress testShipTo = new TrainingBookingServices.TrainingBookingAddress();
		testShipTo.Salutation = 'Mr';
        testShipTo.Contact = 'Test Contact';
        testShipTo.Email = 'test@bsigroup.com';
        testShipTo.Phone = '01234 123123';
        testShipTo.Company = 'BSI';
        testShipTo.Street = '389 Chiswick High Rd';
        testShipTo.City = 'London';
        testShipTo.Region = '';
        testShipTo.Postcode = 'W4 4AL';
        testShipTo.Country = 'GB';
        testShipTo.VatNumber = 'GB123456789';
        testShipTo.Overseas = false;		
		TrainingBookingServices.TrainingBookingAddress testSoldTo = testShipTo;
		TrainingBookingServices.TrainingBookingItem testItem = new TrainingBookingServices.TrainingBookingItem();
		testItem.Description = 'Test Course';
        testItem.Material = '30012345';
        testItem.Quantity = 1.00;
        testItem.Price = 100.00;
        testItem.Discount = 0.00;
        testItem.Currency_x = 'GBP';
        testItem.SmoNumber = '1234567';
        testItem.Delegates = 'John Smith';
		TrainingBookingServices.ArrayOfTrainingBookingItem testItems = new TrainingBookingServices.ArrayOfTrainingBookingItem();
		testItems.TrainingBookingItem = new TrainingBookingServices.TrainingBookingItem[]{ testItem };
		
		// Perform a (simulated) tax calculation
		TrainingBookingServices.CreateOrderResult resp = soap.CreateOrder('DEV', true, testOrder, testShipTo, testSoldTo, testItems);
		System.assert(resp.Success);
		
		Test.stopTest();
    }
    
    @isTest
    private static void testRESTCall(){		
        SystemSetting__c  settings = new SystemSetting__c ();
        settings.JWT_Auth_Endpoint__c = 'https://login.microsoftonline.com';
        settings.JWT_Client_ID__c = 'id';
        settings.JWT_Client_Secret__c = 'secret';
        settings.JWT_Resource__c = 'resource';
        insert settings;

		// Reference the parent class for coverage
		TrainingBookingServices parent = new TrainingBookingServices();

		// Create an instance of the SOAP service
		TrainingBookingServices.TrainingBookingServiceREST call = new TrainingBookingServices.TrainingBookingServiceREST();

		// Add the order details
		TrainingBookingServices.TrainingBookingOrder testOrder = new TrainingBookingServices.TrainingBookingOrder();
		testOrder.SalesOrg = '1000';
        testOrder.Currency_x = 'GBP';
        testOrder.Language = 'EN';
        testOrder.PoNumber = '12345';
        testOrder.OrderNumber = '1234567';
        testOrder.OrderDate = DateTime.now();
        testOrder.StartDate = DateTime.now();
        testOrder.EndDate = DateTime.now();
        testOrder.CcAuthorisedType = 'VISA';
        testOrder.CcAuthorisedName = 'TEST CONTACT';
        testOrder.CcAuthorisedDate = DateTime.now();
        testOrder.CcAuthorisedAmount = 100.00;
        testOrder.CcAuthorisationNo = '1234567890';	
		TrainingBookingServices.TrainingBookingAddress testShipTo = new TrainingBookingServices.TrainingBookingAddress();
		testShipTo.Salutation = 'Mr';
        testShipTo.Contact = 'Test Contact';
        testShipTo.Email = 'test@bsigroup.com';
        testShipTo.Phone = '01234 123123';
        testShipTo.Company = 'BSI';
        testShipTo.Street = '389 Chiswick High Rd';
        testShipTo.City = 'London';
        testShipTo.Region = '';
        testShipTo.Postcode = 'W4 4AL';
        testShipTo.Country = 'GB';
        testShipTo.VatNumber = 'GB123456789';
        testShipTo.Overseas = false;		
		TrainingBookingServices.TrainingBookingAddress testSoldTo = testShipTo;
		TrainingBookingServices.TrainingBookingItem testItem = new TrainingBookingServices.TrainingBookingItem();
		testItem.Description = 'Test Course';
        testItem.Material = '30012345';
        testItem.Quantity = 1.00;
        testItem.Price = 100.00;
        testItem.Discount = 0.00;
        testItem.Currency_x = 'GBP';
        testItem.SmoNumber = '1234567';
        testItem.Delegates = 'John Smith';
		TrainingBookingServices.TrainingBookingItem[] items = new TrainingBookingServices.TrainingBookingItem[]{ testItem };
        
        Test.setMock(HttpCalloutMock.class, new MockCallouts());
        // Run the test
		Test.startTest();
		// Perform a (simulated) tax calculation
		TrainingBookingServices.CreateOrderResult resp = call.CreateOrder('DEV', true, testOrder, testShipTo, testSoldTo, items, '1');
		System.assert(resp.Success, 'Response is successful');
        System.assertEquals(resp.Tax, 35415.15, 'Correct Tax is returned');
		
		Test.stopTest();
    }
    
    private class MockCallouts implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().startsWith('https://login.microsoftonline')) {
        		res.setBody(
                	'{' +
                        '"token_type": "Bearer",'+
                        '"expires_in": "3599",' +
                        '"ext_expires_in": "3599",' +
                        '"expires_on": "1634807791",' +
                        '"not_before": "1634803891",' +
                        '"resource": "ac6f8a64-19be-4dce-8db0-f6cc4c7febb9",' +
                        '"access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Imwzc1EtNTBjQ0g0eEJWWkxIVEd3blNSNzY4MCJ9.eyJhdWQiOiJhYzZmOGE2NC0xOWJlLTRkY2UtOGRiMC1mNmNjNGM3ZmViYjkiLCJpc3MiOiJodHRwczovL2xvZ2luLm1pY3Jvc29mdG9ubGluZS5jb20vNTQ5NDZmZmMtNjhkMy00OTU1LWFjNzAtZGNhNzI2ZDQ0NWI0L3YyLjAiLCJpYXQiOjE2MzQ4MDM4OTEsIm5iZiI6MTYzNDgwMzg5MSwiZXhwIjoxNjM0ODA3NzkxLCJhaW8iOiJFMlpnWUdndVlkOWZOa3YzcE9WNUlkdXYyNjU1QWdBPSIsImF6cCI6ImNhN2ZkOTRiLTg5MzAtNGNmNS1hNDBhLWMwNjYxY2YyY2I0ZiIsImF6cGFjciI6IjEiLCJvaWQiOiJmODdkNDgyYS04NzgxLTQ4ZWMtOGY5Ni01YjliYjNmNWViM2IiLCJyaCI6IjAuQVFrQV9HLVVWTk5vVlVtc2NOeW5KdFJGdEV2WmY4b3dpZlZNcEFyQVpoenl5MDhKQUFBLiIsInN1YiI6ImY4N2Q0ODJhLTg3ODEtNDhlYy04Zjk2LTViOWJiM2Y1ZWIzYiIsInRpZCI6IjU0OTQ2ZmZjLTY4ZDMtNDk1NS1hYzcwLWRjYTcyNmQ0NDViNCIsInV0aSI6Inl3XzhMSGdLa1VLalNSZHVFZW9IQUEiLCJ2ZXIiOiIyLjAifQ.qnC7WPdTW7oocypyjBQi-QJA9RDPxNeLhj5uN0KPodnujuwY4NydR8ynUfIY7RxneFS68aJhcEv_udRPzMF2_pAEko69ozOnhQxeY6MAMkCmbsp7TtkUaeA1qUoaNxDPtKMj6NoSHdGQWMGrR6wUZC3lKZCxyJglHVPmvnpFS9ixaTcXN5icNwpKhPFmmUVmZ1Q26L6xuPl9HTivMSFpkFvxqSovw33NSaiWKc10MHlKSw3eyfE3zLJkjuCMbX4gfLwsD9XvvV7adFy5aOx-riFf0iPvoiix5xyKKtFOrzPh0k7bg5QdBr3oxpowgQqgv6KMOoS8JrVNueDDMUnsDQ"' +
                    '}'
                );
            } else {
                            res.setBody('{' +
                    '"ZLMS_BAPI_SALESORDER_CREATE": {' +
                        '"response": {' +
                            '"return": {' +
                                '"raw": ['+
                                    '{' +
                                        '"TYPE": "S",' +
                                        '"ID": "V4",' +
                                        '"NUMBER": "233",' +
                                        '"MESSAGE": "SALES_HEADER_IN has been processed successfully",' +
                                        '"LOG_NO": null,' +
                                        '"LOG_MSG_NO": "000000",' +
                                        '"MESSAGE_V1": "VBAKKOM",' +
                                        '"MESSAGE_V2": null,' +
                                        '"MESSAGE_V3": null,' +
                                        '"MESSAGE_V4": null,' +
                                        '"PARAMETER": "SALES_HEADER_IN",' +
                                        '"ROW": "0",' +
                                        '"FIELD": null,' +
                                        '"SYSTEM": "PRDLOGIC"' +
                                    '},' +
                                    '{' +
                                        '"TYPE": "S",' +
                                        '"ID": "V4",' +
                                        '"NUMBER": "233",' +
                                        '"MESSAGE": "SALES_ITEM_IN has been processed successfully",' +
                                        '"LOG_NO": null,' +
                                        '"LOG_MSG_NO": "000000",' +
                                        '"MESSAGE_V1": "VBAPKOM",' +
                                        '"MESSAGE_V2": "000010",' +
                                        '"MESSAGE_V3": null,' +
                                        '"MESSAGE_V4": null,' +
                                        '"PARAMETER": "SALES_ITEM_IN",' +
                                        '"ROW": "1",' +
                                        '"FIELD": null,' +
                                        '"SYSTEM": "PRDLOGIC"' +
                                    '},' +
                                    '{' +
                                        '"TYPE": "S",' +
                                        '"ID": "V4",' +
                                        '"NUMBER": "233",' +
                                        '"MESSAGE": "SALES_CONDITIONS_IN has been processed successfully",' +
                                        '"LOG_NO": null,' +
                                        '"LOG_MSG_NO": "000000",' +
                                        '"MESSAGE_V1": "KONVKOM",' +
                                        '"MESSAGE_V2": null,' +
                                        '"MESSAGE_V3": null,' +
                                        '"MESSAGE_V4": null,' +
                                        '"PARAMETER": "SALES_CONDITIONS_IN",' +
                                        '"ROW": "1",' +
                                        '"FIELD": null,' +
                                        '"SYSTEM": "PRDLOGIC"' +
                                    '},' +
                                    '{' +
                                        '"TYPE": "S",' +
                                        '"ID": "V1",' +
                                        '"NUMBER": "311",' +
                                        '"MESSAGE": "LMS Order/Contract 50146974 has been saved",' +
                                        '"LOG_NO": null,' +
                                        '"LOG_MSG_NO": "000000",' +
                                        '"MESSAGE_V1": "LMS Order/Contract",' +
                                        '"MESSAGE_V2": "50146974",' +
                                        '"MESSAGE_V3": null,' +
                                        '"MESSAGE_V4": null,' +
                                        '"PARAMETER": "SALES_HEADER_IN",' +
                                        '"ROW": "0",' +
                                        '"FIELD": null,' +
                                        '"SYSTEM": "PRDLOGIC"' +
                                    '}' +
                                '],' +
                                '"messages": [' +
                                    '"SALES_HEADER_IN has been processed successfully",' +
                                    '"SALES_ITEM_IN has been processed successfully",' +
                                    '"SALES_CONDITIONS_IN has been processed successfully",' +
                                    '"LMS Order/Contract 50146974 has been saved"' +
                                ']' +
                            '},' +
                            '"output": {' +
                                '"documentNumber": "0050146974",' +
                                '"taxAmount": "35415.150000000",' +
                                '"netAmount": "505930.750000000"' +
                            '}' +
                        '}' +
                    '}' +
                '}'
            );
            }
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class RESTCalculateResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{' +
                    '"ZLMS_BAPI_SALESORDER_CREATE": {' +
                        '"response": {' +
                            '"return": {' +
                                '"raw": ['+
                                    '{' +
                                        '"TYPE": "S",' +
                                        '"ID": "V4",' +
                                        '"NUMBER": "233",' +
                                        '"MESSAGE": "SALES_HEADER_IN has been processed successfully",' +
                                        '"LOG_NO": null,' +
                                        '"LOG_MSG_NO": "000000",' +
                                        '"MESSAGE_V1": "VBAKKOM",' +
                                        '"MESSAGE_V2": null,' +
                                        '"MESSAGE_V3": null,' +
                                        '"MESSAGE_V4": null,' +
                                        '"PARAMETER": "SALES_HEADER_IN",' +
                                        '"ROW": "0",' +
                                        '"FIELD": null,' +
                                        '"SYSTEM": "PRDLOGIC"' +
                                    '},' +
                                    '{' +
                                        '"TYPE": "S",' +
                                        '"ID": "V4",' +
                                        '"NUMBER": "233",' +
                                        '"MESSAGE": "SALES_ITEM_IN has been processed successfully",' +
                                        '"LOG_NO": null,' +
                                        '"LOG_MSG_NO": "000000",' +
                                        '"MESSAGE_V1": "VBAPKOM",' +
                                        '"MESSAGE_V2": "000010",' +
                                        '"MESSAGE_V3": null,' +
                                        '"MESSAGE_V4": null,' +
                                        '"PARAMETER": "SALES_ITEM_IN",' +
                                        '"ROW": "1",' +
                                        '"FIELD": null,' +
                                        '"SYSTEM": "PRDLOGIC"' +
                                    '},' +
                                    '{' +
                                        '"TYPE": "S",' +
                                        '"ID": "V4",' +
                                        '"NUMBER": "233",' +
                                        '"MESSAGE": "SALES_CONDITIONS_IN has been processed successfully",' +
                                        '"LOG_NO": null,' +
                                        '"LOG_MSG_NO": "000000",' +
                                        '"MESSAGE_V1": "KONVKOM",' +
                                        '"MESSAGE_V2": null,' +
                                        '"MESSAGE_V3": null,' +
                                        '"MESSAGE_V4": null,' +
                                        '"PARAMETER": "SALES_CONDITIONS_IN",' +
                                        '"ROW": "1",' +
                                        '"FIELD": null,' +
                                        '"SYSTEM": "PRDLOGIC"' +
                                    '},' +
                                    '{' +
                                        '"TYPE": "S",' +
                                        '"ID": "V1",' +
                                        '"NUMBER": "311",' +
                                        '"MESSAGE": "LMS Order/Contract 50146974 has been saved",' +
                                        '"LOG_NO": null,' +
                                        '"LOG_MSG_NO": "000000",' +
                                        '"MESSAGE_V1": "LMS Order/Contract",' +
                                        '"MESSAGE_V2": "50146974",' +
                                        '"MESSAGE_V3": null,' +
                                        '"MESSAGE_V4": null,' +
                                        '"PARAMETER": "SALES_HEADER_IN",' +
                                        '"ROW": "0",' +
                                        '"FIELD": null,' +
                                        '"SYSTEM": "PRDLOGIC"' +
                                    '}' +
                                '],' +
                                '"messages": [' +
                                    '"SALES_HEADER_IN has been processed successfully",' +
                                    '"SALES_ITEM_IN has been processed successfully",' +
                                    '"SALES_CONDITIONS_IN has been processed successfully",' +
                                    '"LMS Order/Contract 50146974 has been saved"' +
                                ']' +
                            '},' +
                            '"output": {' +
                                '"documentNumber": "0050146974",' +
                                '"taxAmount": "35415.150000000",' +
                                '"netAmount": "505930.750000000"' +
                            '}' +
                        '}' +
                    '}' +
                '}'
            );
            res.setStatusCode(200);
            return res;
        }
	}
    
}