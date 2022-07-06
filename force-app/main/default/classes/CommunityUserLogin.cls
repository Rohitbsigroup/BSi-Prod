/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-01-29
* @group CloudShiftGroup
* @description - Class used to validate community user details
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 29/01/2021    Jadd Ennaciri      Created Class
*
*/

public with sharing class CommunityUserLogin {

    public static Boolean authenticate(String username, String password) {
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        HttpRequest request = new HttpRequest();
        Http http = new Http();
        if(runningInASandbox) {
            request.setEndpoint('https://test.salesforce.com/services/Soap/c/44.0');
        } else {
            request.setEndpoint('https://login.salesforce.com/services/Soap/c/44.0');
        }
        request.setTimeout(60000);
        request.setHeader('SOAPAction', 'login');
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setHeader('Accept','text/xml');
        request.setMethod('POST');
        request.setBody(buildRequest(username, password));
        HttpResponse response = http.send(request);
        System.debug(response);
        String sessionId = getValueFromXMLString(response.getBody(), 'sessionId');
        Boolean isAuthenticated;
        if(String.isNotBlank(sessionId)){
            isAuthenticated = true;
        }else{
            isAuthenticated = false;
        }
        return isAuthenticated;
    }

    private static String buildRequest(String username, String password) {
        String request = '<?xml version="1.0" encoding="utf-8"?>';
        request += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:enterprise.soap.sforce.com">';
        request += '<soapenv:Header>';
        request += '<urn:LoginScopeHeader>';
        request += '<urn:organizationId>'+ UserInfo.getOrganizationId() +'</urn:organizationId>';
        request += '</urn:LoginScopeHeader>';
        request += '</soapenv:Header>';
        request += '<soapenv:Body>';
        request += '<urn:login>';
        request += '<urn:username>'+ username +'</urn:username>';
        request += '<urn:password>'+ password +'</urn:password>';
        request += '</urn:login>';
        request += '</soapenv:Body>';
        request += '</soapenv:Envelope>';
        return request;
    }

    public static string getValueFromXMLString(string xmlString, string keyField){
        String xmlKeyValue = '';
        if(xmlString.contains('<' + keyField + '>')){
            try{
                xmlKeyValue = xmlString.substring(xmlString.indexOf('<' + keyField + '>')+keyField.length() + 2, xmlString.indexOf('</' + keyField + '>'));
            }catch (exception e){}
        }
        return xmlKeyValue;
    }
}