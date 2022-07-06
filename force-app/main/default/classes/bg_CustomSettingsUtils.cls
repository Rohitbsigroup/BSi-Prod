/********************************************************************
 * bg_CustomSettingsUtils
 *
 * Utility methods to custom setting functions
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 21-11-16 - 	JT 	Added GetLeadSettings and SetupLeadSettings
 ********************************************************************/
public class bg_CustomSettingsUtils {

	// Custom Setting Cache
	private static SystemSetting__c systemSettings; 				 			// System Settings
	private static SiteSetting__c siteSettings; 					 			// Site Settings
	private static QuoteSetting__c quoteSettings;					 			// Quote Settings
	private static BSIPermissions__c permissionSettings; 				 		// Permission Settings
	private static BPSettings__c blueprintSettings;
	@TestVisible private static LeadSetting__c leadSettings = null;				// Lead Settings
	private static map<string, ConversionScore__c> defaultCountrySettingMap; 	// Default Country Settings
	private static map<string, Country_Currency__c> countryCurrencySettingMap;	// Country currencies

	public class CustomSettingException extends Exception{}
	
	public static ConversionScore__c GetDefaultCountrySettings() {
		/*
			Return Default Country Settings
		*/
		ConversionScore__c cs;
		User curUser = [SELECT OperationCountry__c FROM User WHERE Id = :UserInfo.getUserId()];
		try {
			cs = GetDefaultCountrySettings(curUser.OperationCountry__c);
		} catch (Exception ex) {
			throw new CustomSettingException('Unable to find Default Country Settings - ' + curUser.OperationCountry__c);	
		} 
		return cs;		
	}

	public static ConversionScore__c GetDefaultCountrySettings(string countryCode) {
		/*
			Return Default Country Settings
		*/
		if(defaultCountrySettingMap == null) {
			defaultCountrySettingMap = new map<string, ConversionScore__c>();
		}
		if(!defaultCountrySettingMap.containsKey(countryCode)) {
			defaultCountrySettingMap.put(countryCode, ConversionScore__c.getInstance(countryCode));
		}
		return defaultCountrySettingMap.get(countryCode);
	}

	public static SiteSetting__c GetSiteSettings() {
		/*
			Return Site Settings
		*/
		if(siteSettings == null) {
    		siteSettings = SiteSetting__c.getInstance();
		}
		return siteSettings;
	}
	
	public static SystemSetting__c GetSystemSettings() {
		/*
			Return System Settings
		*/
		if(systemSettings == null) {
    		systemSettings = SystemSetting__c.getInstance();
		}
		return systemSettings;
	}
	
	public static map<string, Country_Currency__c> GetCountryCurrencySettings() {
		/*
			Return Country Currency Setting Map
		*/
		if(countryCurrencySettingMap == null) {
    		countryCurrencySettingMap = Country_Currency__c.getAll();
		}
		return countryCurrencySettingMap;
	}	
	
	public static QuoteSetting__c GetQuoteSettings() {
		/*
			Return Quote Settings
		*/
		if(quoteSettings == null) {
    		quoteSettings = QuoteSetting__c.getInstance();
		}
		return quoteSettings;
	}	

	public static BSIPermissions__c GetPermissionSettings() {
		/*
			Return Permission Settings
		*/
		if(permissionSettings == null) {
    		permissionSettings = BSIPermissions__c.getInstance();
		}
		return permissionSettings;
	}

	public static LeadSetting__c GetLeadSettings() {
		/*
			Return Lead Settings
		*/
		SetupLeadSettings();
		if(leadSettings.id == null) {
    		leadSettings = new LeadSetting__c();
    		leadSettings.DuplicateReason__c = 'Duplicate';
    		leadSettings.FiveCalls__c = '5 Call Close';
    		leadSettings.InsufficientDetailsReason__c = 'Insufficient Details Provided';
    		leadSettings.ProcessedSF__c = 'Processed in current SFDC';
    		leadSettings.StatusContacted__c = 'Open-Contacted';
    		leadSettings.StatusNotConverted__c = 'Closed-Not Converted';
		}
		return leadSettings;
	}

	public static void SetupLeadSettings()
	{
		/*Determine if we have a leadSetting cached or not */
		if(leadSettings == null)
		{
			leadSettings = LeadSetting__c.getInstance();
		}
	}

	// getter for blueprint settings
	public static BPSettings__c GetBlueprintSettings()
	{
		if(null==blueprintSettings)
		{
			blueprintSettings = BPSettings__c.getOrgDefaults();
		}
		return blueprintSettings;
	}
}