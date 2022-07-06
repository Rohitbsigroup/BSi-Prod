/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-02-03
* @group CloudShiftGroup
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 03/02/2021    Jadd Ennaciri      Created Class
*
*/

@IsTest
private with sharing class CommunityUserLoginTest {

    public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            res.setBody('<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:enterprise.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><loginResponse><result><metadataServerUrl>https://bsi--dev2020.my.salesforce.com/services/Soap/m/44.0/00D3L0000008af7</metadataServerUrl><passwordExpired>false</passwordExpired><sandbox>true</sandbox><serverUrl>https://bsi--dev2020.my.salesforce.com/services/Soap/c/44.0/00D3L0000008af7</serverUrl><sessionId>SESSION_ID_REMOVED</sessionId><userId>0053L000000vf8JQAQ</userId></result></loginResponse></soapenv:Body></soapenv:Envelope>');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    private static void testAuthenticate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Test.startTest();
        Boolean isAuthenticated = CommunityUserLogin.authenticate('test', 'test');
        Test.stopTest();
        System.assertEquals(true, isAuthenticated, 'Failed to authenticate');
    }
}