global with sharing class CiGeocode
{	
    WebService static void Geocode(string siteId)
    {
        // Initialize
        String clientId = 'gme-thebritishstandards';
        String privateKey = 'B8dFb-z6ZkDESIH8I6HM-VoYr9k=';
        String googleDomain = 'https://maps.googleapis.com';
        String googlePath = '/maps/api/geocode/xml';
        String googleQuery = '';
        List<CI_Site__c> siteUpdates = new List<CI_Site__c>();
        
        // Select the site details
        for (CI_Site__c site : [
            SELECT  s.Id, 
                    s.Name, 
                    s.Street__c, 
                    s.City__c, 
                    s.Region__c, 
                    s.Postcode__c, 
                    s.Country__c, 
                    s.Location__Latitude__s, 
                    s.Location__Longitude__s, 
                    s.Geocoding__c 
            FROM    CI_Site__c s 
            WHERE	s.Id = :siteId
            ])
        {
        	// Build the URL
        	String address = '';
	        if (String.isNotBlank(site.Street__c)) address += site.Street__c.replace('\n',',');
    	    if (String.isNotBlank(site.City__c)) address += ',' + site.City__c;
        	if (String.isNotBlank(site.Region__c)) address += ',' + site.Region__c;
	        if (String.isNotBlank(site.Postcode__c)) address += ',' + site.Postcode__c;
    	    if (String.isNotBlank(site.Country__c)) address += ',' + site.Country__c;
        	googleQuery = '?address=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&sensor=false&client=' + clientId;
        
	        // Build and add the signature (as per https://developers.google.com/maps/documentation/business/webservices)
    	    String useableKey = privateKey.replace('-', '+').replace('_', '/');
        	Blob hmac = Crypto.generateMac('hmacSHA1', Blob.valueOf(googlePath + googleQuery), EncodingUtil.base64Decode(useableKey));
	        String signature = EncodingUtil.base64Encode(hmac);
    	    googleQuery += '&signature=' + signature.replace('+', '-').replace('/', '_');
        
        	// Call the Google API
	        Http h = new Http();
    	    HttpRequest req = new HttpRequest();
        	req.setEndpoint(googleDomain + googlePath + googleQuery);
	        req.setMethod('GET');
	        
	        // Can only run if not testing
	        HttpResponse res = Test.isRunningTest() ? CiTestUtility.createTestResponse() : h.send(req);
        
			// Create an update record
			CI_Site__c siteUpdate = new CI_Site__c();
        	siteUpdate.Id = site.Id;

        	// Process the response
        	if (res.getStatus() == 'OK')
        	{
	            // Parse XML status
    	        Dom.Document doc = res.getBodyDocument();
        	    Dom.XMLNode root = doc.getRootElement();
            	String status = root.getChildElement('status', null).getText();
	            if (status == 'OK')
    	        {
        	        // Parse XML result
            	    Dom.XMLNode result = root.getChildElement('result', null);
                	Dom.XMLNode geometry = result.getChildElement('geometry', null);
	                Dom.XMLNode location = geometry.getChildElement('location', null);
    	            String lat = location.getChildElement('lat', null).getText();
        	        String lng = location.getChildElement('lng', null).getText();

	                if (lat != '' && lng != '')
    	            {
        	            // Update record
                    	siteUpdate.Location__Latitude__s = Decimal.valueOf(lat);
                    	siteUpdate.Location__Longitude__s = Decimal.valueOf(lng);
                    	siteUpdate.Geocoding__c = 'OK';
                	}
            	}
            	else
            	{
                	siteUpdate.Geocoding__c = status;
            	}
            
            	// Add the update to the list
            	siteUpdates.add(siteUpdate);
        	}
        	else
        	{
            	System.debug('Status returned in HTTP - ' + res.getStatus());
        	}
        }
        
        // Apply updates
        if (siteUpdates.size() > 0) update siteUpdates;
    }
}