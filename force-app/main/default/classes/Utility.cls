/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         14/11/2011
* Description:  Utility class.
* Changes:		ASD 19/11/2014 Ammended postcode tidy to check for empty lists (ie a postcode of -----) 
*               CB 26/06/2015 Added trigger lock for quote part   
*				IB 29/08/2017 removed setHQSite() for PS implementation UAT #PS - 001 

**/ 
public class Utility {
	
	// TRIGGERS LOCKS
	public static Boolean lockAccountTrigger 	= false;
	public static Boolean lockOptyTrigger		= false;
	public static Boolean lockQuoteTrigger		= false;
	public static Boolean lockQuotePartTrigger	= false;
	public static Boolean lockcreateHQSite 		= false;
	public static Boolean lockassignTerritory	= false;
	public static Boolean isVisualforce			= false;
	
	// CONSTANT VALUES
	public final static String RTNAME_NETWORK	= 'NETWORK';
	public final static String RTNAME_TRANSIENT	= 'TRANSIENT';
	public final static String RTNAME_NAMED		= 'NAMED';
	public final static String RTNAME_DEFAULT	= 'Default';
	
	public final static String RTNAME_CONSULTANT = 'Consultants';
	
	// RETURN A MAP FOR TERRITORY ASSIGNMENT
	public static Map<String,Id> getTerritoryMap(List<Territory__c> territories) {
		Map<String,Id> postcodeMap = new Map<String,Id>(); // <COUNTRY+POSTCODESTART,TERRITORY ID>
		
		for (Territory__c terr : territories) {
			List<String> postcodes = new List<String>();
			if (terr.PostZipCode__c != null) postcodes = terr.PostZipCode__c.split(',');
			for (String pc : postcodes) {
				postCodeMap.put(terr.Country__c+'#'+pc.trim(),terr.Id);
			}
			if (postcodes.isEmpty()) {
				postCodeMap.put(terr.Country__c,terr.Id);
			}
		}
		
		return postcodeMap;
	}
	
	/*// RETURN A MAP FOR USER OPERATION COUNTRY
	public static Map<Id,String> getUserCountryMap(Set<Id> ids) {
		Map<Id,String> countryMap = new Map<Id,String>([SELECT OperationCountry__c FROM User WHERE Id IN:ids]);
		List<User> users = [SELECT OperationCountry__c FROM User WHERE Id IN:ids];
		for (User curr : users) {
			countryMap.put(curr.Id,curr.OperationCountry__c);
		}
		
		return countryMap;
	}*/
	
	// RETURN MAP OF RECORD TYPES
	public static Map<String,Id> getRecordTypes(String objectType) {
		Map<String,Id> rtypeMap = new Map<String,Id>();
		List<RecordType> rtype = [SELECT DeveloperName FROM RecordType WHERE SObjectType =:objectType];
		for (RecordType r : rtype) {
			rtypeMap.put(r.DeveloperName,r.Id);
		}
		return rtypeMap;
	}
	
	public class SiteSettingException extends Exception {}
	
	/* IB removed for PS implementation UAT #PS - 001 
	
	// HQ SITE DEFAULT VALUE
	public static Site__c setHQSite(Account acc) {
		SiteSetting__c setting = SiteSetting__c.getInstance();

		if(setting == null) {
			throw new SiteSettingException('The Custom setting \'Site Setting\' has not been configured'); 
		}

		Site__c s 		= new Site__c();
		s.Account__c 	= acc.Id;
		String newName  = acc.Name;
		if(newName.length() > 76)
		{
			newName = bg_StringUtils.truncateString(acc.Name, 76);
		}
		//s.Name 			= acc.Name + ' HQ';
		s.Name 			= newName + ' HQ';
		s.Type__c 		= setting.HQLabel__c;
		s.Street__c 	= acc.BillingStreet;
		s.City__c		= acc.BillingCity;
		s.Postcode__c	= acc.BillingPostalCode;
		s.State__c 		= acc.BillingState;
		s.Country__c	= acc.BillingCountry;
		s.Territory__c	= acc.Territory__c;
		s.Country_Code__c = acc.BillingCountry;
		s.NumberEmployees__c = acc.NumberOfEmployees;
		
		if (acc.TCodeDescr__c != null) {
			s.TCodeDescr__c = acc.TCodeDescr__c;
		} else {
			s.Industry__c = null;// Blank this field to avoid validation rule
		}
		return s;
	}
	*/
		
	// FORMAT POSTALCODE
	public static String formatZipCode(String zip) {
		String formatted = zip;
		List<String>checkFormatted;
		if (zip != null) 
		{
			if (zip.contains(' '))
			{ 
				checkFormatted = zip.split(' ');
				if(checkFormatted != null && checkFormatted.size() != 0 )
				{
					formatted = checkFormatted.get(0);
				}
			}
			else if (zip.contains('-')) 
			{
				checkFormatted = zip.split('-');
				if(checkFormatted != null && checkFormatted.size() != 0)
				{
					formatted = checkFormatted.get(0);
				}
			}
		}
		
		return formatted;
	}
	
	public static String formtZipCode(String zip, String country) {
		String formatted = zip;
		if (country == 'US') { 
			// MANAGE EXCEPTION
			if (zip.length() >= 5) {
				formatted = zip.substring(0,5);
			} else {
				formatted = zip;
			}
		}
		//else if (country == 'GB') formatted = zip.substring(0,2); IF UK SPLIT ON SPACE
		
		return formatZipCode(formatted);
	}
	public static String cleanPostcode(String zip) {
		if (zip != null)
			zip = zip.toUpperCase();
		
		return zip;	
	}
	
	// CREATE CUSTOMER USER
	public static User createPortalUser(String contactId, String email, String firstName, String lastName, String company, String country) {
		// Get the Customer Portal profile
		SystemSetting__c setting = SystemSetting__c.getInstance();
		Profile profile = [SELECT Name FROM Profile WHERE Name =:setting.CustomerProfile__c];
		
		// Set up the user
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.EmailHeader.triggerUserEmail = true;
        User u = new User(alias = 'standt', email=email, firstname=firstname,
            emailencodingkey='UTF-8', lastname=lastname, languagelocalekey=localeKeys.get(country),
            localesidkey=localeKeys.get(country), profileid = profile.Id, contactId=contactId,
            timezonesidkey=timeZones.get(country), username=email+'.bsi');
        u.setOptions(dmo);
        return u;
    }
	
	// USER'S LOCALE KEY CODE COUNTRY MAPPING
	private static Map<String,String> languages = new Map<String,String>();
	static {
		languages.put('GB','English');
		languages.put('US','English');
		languages.put('IT','Italiano');
	}
	// USER'S LOCALE KEY CODE COUNTRY MAPPING
	private static Map<String,String> localeKeys = new Map<String,String>();
	static {
		localeKeys.put('GB','en_US');
		localeKeys.put('US','en_US');
		localeKeys.put('IT','it');
	}
	// USER'S TIME ZONE CODE COUNTRY MAPPING
	private static Map<String,String> timeZones = new Map<String,String>();
	static {
		timeZones.put('GB','Europe/London');
		timeZones.put('US','America/Los_Angeles');
		timeZones.put('IT','Europe/Rome');
	}
	
	// DATE FORMATTING MAPPING
	public static Map<String,String> dateFormat = new Map<String,String>();
	static {
		dateFormat.put('en_GB', 'MMM dd yyyy \'at\' HH:mm'); // dd/MM/yyyy hh:mm TT -> for AM PM
		dateFormat.put('en_US', 'MMM dd yyyy \'at\' HH:mm');
	}
	
	// -------------------------------
	
	
	
	// SOBJECT'S COLORS
	private static Map<String,String> objectColors = new Map<String,String>();
	static {
		objectColors.put('Lead','#F9EAD5');
		objectColors.put('Site','#FCD0D9');
		objectColors.put('Opportunity','#F6EDC9');
	}
	
	// RETURN A NICE FORMATTED MESSAGE
	public static String niceErrorMessage(String message, String objectName) {
		String color = objectColors.get(objectName);	 
		String niceMessage 	= '<div style="text-align:center;vertical-align:middle;background-color:' + color + '"><br/>'
							+'<center><table><tr><td><img src="/resource/1321271149000/icon_warning" width="30"/></td><td style="vertical-align:middle;">' 
							+ message 
							+ '</td></tr></table></center><br/></div>';
		return niceMessage;
	}
	
	// RETURN A NICE FORMATTED MESSAGE WITH A TIP
	public static String niceErrorMessage(String message, String objectName, String tip) {
		String color = objectColors.get(objectName);
		 
		String niceMessage 	= '<div style="text-align:center;vertical-align:middle;background-color:' + color + '"><br/>'
							+'<center><table><tr><td><img src="/resource/1321271149000/icon_warning" width="30"/></td><td style="vertical-align:middle;">' 
							+ message 
							+ '</td></tr><tr><td><img src="/resource/1321279250000/icon_info" width="30"/></td><td style="vertical-align:middle;">'
							+ tip
							+'</td></tr></table></center><br/></div>';
		return niceMessage;
	}
	
	// RETURN LINK WITH STANDARD SALESFORCE HOVER INFO
	public static String hoverHref(String recordId, String anchorText) {

		return '<a href="/' + recordId + '/e?retURL=/' + recordId + '" id="' + recordId + '" '
			+ 'onblur="LookupHoverDetail.getHover(\'' + recordId + '\').hide();" '
			+ 'onfocus="LookupHoverDetail.getHover(\'' + recordId + '\', \'/' + recordId 
			+ '/m?retURL=%2F' + recordId + '&isAjaxRequest=1\').show();" ' 
			+ 'onmouseout="LookupHoverDetail.getHover(\'' + recordId + '\').hide();" ' 
			+ 'onmouseover="LookupHoverDetail.getHover(\'' + recordId + '\', \'/' + recordId 
			+ '/m?retURL=%2F' + recordId + '&isAjaxRequest=1\').show();" style="color:red;">' + anchorText + '</a>';
  	}
	
	// RETURN USER FRIENDLY MESSAGE FOR WELL KNOWN EXCEPTION CODES
	public static String friendlyMessage(String message) {
		String friendlyMessage = message;
		
		if (message.contains('INVALID_EMAIL_ADDRESS')) {
			friendlyMessage = 'Email can not be sent. Please insert a valid email address.';
		} 
		
		return friendlyMessage;
	}
	
	public static Decimal getDecimal(Decimal value)
	{
    	if(value==null) return 0;
    	else return value;
  	}
}