/********************************************************************
 * bg_BluePrintUtils2
 *
 * Utility methods to support Blue Print integration
 * 
 * 
 * Author: Richard Jimenez
 * Created: 27-08-2014
 * Changes: 07-02-2018 - ADS - Case 35482 - Asian Characters
 ********************************************************************/
public class bg_BluePrintUtils2 {

	// Custom Settings
	private static final SystemSetting__c SYSTEM_SETTINGS	= bg_CustomSettingsUtils.getSystemSettings();
	private static final BPSettings__c BLUE_PRINT_SETTINGS	= bg_CustomSettingsUtils.getBlueprintSettings();
	//private static final string        BLUE_PRINT_URL		= '/apex/Blueprint_Quote';
	
	// URL PARAM NAMES 
	public static final string PARAM_NAME_QUOTEID			= 'QuoteId';
	public static final string PARAM_NAME_RETURNURL			= 'returnurl';
	public static final string PARAM_NAME_PRODUCTCODE		= 'ProductCode';
    public static final string PARAM_NAME_LANGUAGE          = 'Language';
	public static final string PARAM_NAME_MODE     			= 'mode';
	public static final string PARAM_NAME_CLOSE     		= 'CloseWhenDone';
	public static final string PARAM_NAME_SESSIONID     	= 'SessionId';
	public static final string PARAM_NAME_SERVERURL     	= 'ServerURL';
	public static final string PARAM_VALUE_MODE_READONLY	= '0';
	public static final string PARAM_VALUE_CLOSE			= '1';

	// Blueprint server page names
	public static final string BLUEPRINT_LOGIN_PAGE			= 'login.aspx';
    
	public static string BuildConfigureURL(string quoteId, string productId) {
		/* Return Blueprint configure quote product URL */
		return BuildConfigureURL(true, quoteId, productId, null);
	}    

	public static string BuildConfigureURL(string quoteId, string productId, string quoteLanguage) {
		/* Return Blueprint configure quote product URL */
		return BuildConfigureURL(true, quoteId, productId, quoteLanguage);
	}

	public static string BuildConfigureURL(boolean editMode, string quoteId, string productId, string quoteLanguage) {
		/* Return Blueprint configure quote product URL */
		return BuildConfigureURL(editMode, quoteId, productId, quoteLanguage, null);
	}

	public static string BuildConfigureURL(boolean editMode, string quoteId, string productId, string quoteLanguage, string retUrl) {
		/* Return Blueprint configure quote product URL */
		return BuildConfigureURL(editMode, quoteId, productId, quoteLanguage, retUrl, false);
	}

	public static string BuildConfigureURL(boolean editMode, string quoteId, string productId, string quoteLanguage, string retUrl, boolean newConfiguration) {

		// build Blueprint endpoint URL
		String blueprintURL = buildConfiguratorURL(quoteId, newConfiguration);

		// Add mandatory URL Params
		// SessionId
		blueprintURL += bg_Constants.DELIMITER_QUESTION_MARK+PARAM_NAME_SESSIONID+bg_Constants.DELIMITER_EQUALS_SIGN+UserInfo.getSessionId();
		// ServerURL - this is the salesforce SOAP endpoint URL
		blueprintURL += bg_Constants.DELIMITER_AMPERSAND+PARAM_NAME_SERVERURL+bg_Constants.DELIMITER_EQUALS_SIGN+BLUE_PRINT_SETTINGS.SalesforceURL__c;
		// QuoteId
		blueprintURL += bg_Constants.DELIMITER_AMPERSAND + PARAM_NAME_QUOTEID + bg_Constants.DELIMITER_EQUALS_SIGN + quoteId;//.left(15);
        // QuoteLanguage
        blueprintURL += bg_Constants.DELIMITER_AMPERSAND + PARAM_NAME_LANGUAGE + bg_Constants.DELIMITER_EQUALS_SIGN + 
            (String.isBlank(quoteLanguage) ? bg_UserUtils.GetUserById(UserInfo.getUserId()).blueprint_language__c : quoteLanguage);
        
		// Add Optional URL params
		// Readonly mode
		if(!editMode)
		{
			blueprintURL += bg_Constants.DELIMITER_AMPERSAND + PARAM_NAME_MODE + bg_Constants.DELIMITER_EQUALS_SIGN + PARAM_VALUE_MODE_READONLY;
		}
		
		// Add product Id - the url param may be different for the new and legacy configurator
		if(!bg_StringUtils.IsBlank(productId))
		{
			blueprintURL += bg_Constants.DELIMITER_AMPERSAND + PARAM_NAME_PRODUCTCODE + bg_Constants.DELIMITER_EQUALS_SIGN + productId;//.left(15);
		}

		// Return Url
		if(!bg_StringUtils.IsBlank(retURL)) 
		{
			blueprintURL += bg_Constants.DELIMITER_AMPERSAND + PARAM_NAME_RETURNURL + bg_Constants.DELIMITER_EQUALS_SIGN + EncodingUtil.urlEncode(retURL, bg_Constants.CHARACTER_ENCODING_UTF_8);
		} 
		else 
		{
			blueprintURL += bg_Constants.DELIMITER_AMPERSAND + PARAM_NAME_CLOSE + bg_Constants.DELIMITER_EQUALS_SIGN + PARAM_VALUE_CLOSE;
		}
		system.debug('### blueprintURL: '+blueprintURL);
		return blueprintURL;
	}

	public static string buildConfiguratorURL(string quoteId, boolean newConfigurator)
	{
    	// configure blueprint URL
    	// Add https prefix
    	String configURL = bg_Constants.URL_HTTPS_PREFIX;
    	// Define server URL
		configURL += BLUE_PRINT_SETTINGS.BluePrint_Server_URL__c + bg_Constants.DELIMITER_FWD_SLASH;
		// Define server path - products configured prior to PS implementation will use the legacy configurator, new projects will utilise the new configurator
		configURL += (newConfigurator ? BLUE_PRINT_SETTINGS.Blueprint_Server_Path__c : BLUE_PRINT_SETTINGS.Blueprint_Server_Path_Legacy__c) + bg_Constants.DELIMITER_FWD_SLASH;
		// Define login URL
		configURL += BLUEPRINT_LOGIN_PAGE;
		return configURL;
	}
}