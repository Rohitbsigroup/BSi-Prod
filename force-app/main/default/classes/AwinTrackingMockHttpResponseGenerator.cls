@isTest
public class AwinTrackingMockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('');
        res.setStatus('Not Found');
        res.setStatusCode(404);
        return res;
    }
}