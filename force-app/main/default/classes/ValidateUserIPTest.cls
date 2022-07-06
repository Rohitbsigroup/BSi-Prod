/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-02-04
* @group CloudShiftGroup
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 04/02/2021    Jadd Ennaciri      Created Class
*
*/

@IsTest
private with sharing class ValidateUserIPTest {

    public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/json');
            res.setBody('{"country":{"iso_code":"GB","geoname_id":2635167,"names":{"es":"Reino Unido","fr":"Royaume-Uni","ja":"イギリス","pt-BR":"Reino Unido","ru":"Великобритания","zh-CN":"英国","de":"Vereinigtes Königreich","en":"United Kingdom"}}}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    private static void testExecute() {
        String ipAddress = 'test';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Test.startTest();
        String ipCountryCode = ValidateUserIP.execute('test');
        Test.stopTest();
        System.assertEquals('GB', ipCountryCode, 'Failed to retrieve ip country code');
    }
}