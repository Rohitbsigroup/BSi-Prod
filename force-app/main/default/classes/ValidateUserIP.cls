/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-02-03
* @group CloudShiftGroup
* @description - Class used to validate IP address through GeoIP2 Precision Web Services
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 03/02/2021    Jadd Ennaciri      Created Class
*
*/

public with sharing class ValidateUserIP {

    public static String execute(String ipAddress) {
        HttpRequest request = new HttpRequest();
        Http http = new Http();
        request.setEndpoint('callout:GeoIP/geoip/v2.1/country/' + ipAddress);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept','application/json');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        System.debug(response);
        System.debug(response.getBody());
        GeoIPResponse wrappedResponse = (GeoIPResponse) JSON.deserialize(response.getBody(), GeoIPResponse.class);
        if(wrappedResponse != null && wrappedResponse.country != null && String.isNotBlank(wrappedResponse.country.iso_code)) {
            return wrappedResponse.country.iso_code;
        } else {
            return null;
        }
    }

    public class GeoIPResponse {
        public Country country;
    }

    public class Country {
        public Integer confidence;
        public Integer geoname_id;
        public String iso_code;
    }
}