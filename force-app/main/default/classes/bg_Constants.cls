/****************************************************************************************************************************
 * bg_Constants.cls
 *
 * @description: Constants for the BSI PS Project
 *
 * @author BrightGen
 * @date 30-June-2017
 *
 * Changes:
 * 
 *****************************************************************************************************************************/
public with sharing class bg_Constants 
{
	// Delimiters
	public static final String DELIMITER_FWD_SLASH = '/';
    public static final String DELIMITER_SEMI_COLON = ';';
    public static final String DELIMITER_UNDERSCORE = '_';
	public static final String DELIMITER_HYPHEN = '-';
    public static final String DELIMITER_HASHTAG = '#';
    public static final String DELIMITER_QUESTION_MARK = '?';
    public static final String DELIMITER_AMPERSAND = '&';
    public static final String DELIMITER_EQUALS_SIGN = '=';

    public static final String INHOUSE_PRODUCT = 'In-House';
    public static final String PRICINGMETHOD_DAYRATE = 'Day Rate';
    public static final String PRICINGMETHOD_DELEGATERATE = 'Delegate Rate';
    
	public static final String NEW_LINE = '\n'; 
	
    // Profile Constants
	public static final String PROFILE_NAME_SYSTEM_ADMINISTRATOR = 'System Administrator';
	public static final List<String> ADMIN_PROFILES = new List<String>
    {
           PROFILE_NAME_SYSTEM_ADMINISTRATOR
    };

    // HTTP Constants
    public static final String HTTP_HEADER_KEY_CONTENT_LENGTH = 'Content-Length';
    public static final String HTTP_HEADER_KEY_CONTENT_TYPE = 'Content-Type';
	public static final String HTTP_HEADER_KEY_AUTHORIZATIOIN = 'Authorization';
	public static final Integer HTTP_STATUS_CODE_OK = 200;
	public static final String HTTP_CONTENT_TYPE_FORM = 'application/x-www-form-urlencoded';
	public static final String HTTP_CONTENT_TYPE_JSON = 'application/json;charset=UTF-8';        
    
    // Timezones - see https://help.salesforce.com/apex/HTViewHelpDoc?id=admin_supported_timezone.htm
	public static final String TIMEZONE_UK = 'GMT';
    
    // URL Parameter Constants
    public static final String URL_HTTPS_PREFIX = 'https://';
    public static final String URL_PARAMETER_ID = 'id';
    public static final String URL_PARAMETER_IDS = 'ids';

    //Encoding Constants
    public static final String CHARACTER_ENCODING_UTF_8 = 'UTF-8';
}