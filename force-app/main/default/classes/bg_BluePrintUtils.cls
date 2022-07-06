/********************************************************************
 * bg_BluePrintUtils
 *
 * Utility methods to support Blue Print integration
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 *          07-09-2015 - RJ - Added BuildBluePrintTemplateURL method 
 *          07-02-2018 - ADS - Case 35482 - Asian Characters
 ********************************************************************/
public class bg_BluePrintUtils {

    public static final string SF_SOAP_SERVICE_URL      = 'services/Soap/u/36.0/';
    private static final string URL_ENCODING_UTF8       = 'UTF-8';
    private static final string SINGLE_PAGE_MERGE       = 'singlepagemerge.aspx?';
    
    //Temporary workaround for documents merge
    private static final string DOCUMENT_MERGE_PATH     = 'BSI_Document';
    
    // URL PARAM NAMES 
    private static final string PARAM_NAME_SESSIONID        = 'SessionId';
    private static final string PARAM_NAME_SERVERURL        = 'ServerURL';
    private static final string PARAM_NAME_QUOTEID          = 'QuoteId';    
    private static final string PARAM_NAME_ACTION           = 'action';
    private static final string PARAM_NAME_CLONEQUOTEID     = 'ToQuoteId';
    private static final string PARAM_NAME_UPLOADFILE       = 'uploadfile';
    private static final string PARAM_NAME_RETURNURL        = 'ReturnUrl';
    private static final string PARAM_NAME_PRODUCTCODE      = 'ProductCode';
    private static final string PARAM_NAME_MODE             = 'mode';
    private static final string PARAM_NAME_CLOSE            = 'CloseWhenDone';
    private static final string PARAM_NAME_QUOTEPRODUCTID   = 'QuoteProduct';
    private static final string PARAM_NAME_TEMPLATE_NAME    = 'TemplateName';
    private static final string PARAM_NAME_DOC_PATH         = 'DocPath';
    private static final string PARAM_NAME_PARAMETERS       = 'Parameters';

    // URL PARAM VALUES
    private static final string PARAM_VALUE_ACTION_COPYQUOTE    = 'copyquote';
    private static final string PARAM_VALUE_ACTION_MERGE        = 'merge';
    private static final string PARAM_VALUE_UPLOADFILE          = '1';
    private static final string PARAM_VALUE_MODE_READONLY       = '0';
    private static final string PARAM_VALUE_CLOSE               = '1';
    private static final string PARAM_VALUE_DEFAULT_DOC_NAME    = 'quote';

    // TEMPLATE DOCUMENTS
    public static final string TEMPLATE_NAME_PRODUCT_PROFILE    = 'Days Profile';
    public static final string TEMPLATE_DOC_EXT_PDF             = 'pdf'; 

    public static string BuildConfigureQuoteProductURL(string quoteId) {
        /* Return Blueprint configure quote product URL */      
        return BuildConfigureQuoteProductURL(true, quoteId, null);
    }

    public static string BuildConfigureQuoteProductURL(boolean editMode, string quoteId) {
        /* Return Blueprint configure quote product URL */      
        return BuildConfigureQuoteProductURL(editMode, quoteId, null);
    }

    public static string BuildConfigureQuoteProductURL(string quoteId, string productId) {
        /* Return Blueprint configure quote product URL */  
        return BuildConfigureQuoteProductURL(true, quoteId, productId, null);
    }
    
    public static string BuildConfigureQuoteProductURL(boolean editMode, string quoteId, string productId) {
        /* Return Blueprint configure quote product URL */  
        return BuildConfigureQuoteProductURL(editMode, quoteId, productId, null);
    }

    public static string BuildConfigureQuoteProductURL(string quoteId, string productId, string cloneQuoteId) {
        /* Return Blueprint configure quote product URL */  
        return BuildConfigureQuoteProductURL(true, quoteId, productId, cloneQuoteId, null);
    }
    
    public static string BuildConfigureQuoteProductURL(boolean editMode, string quoteId, string productId, string cloneQuoteId) {
        /* Return Blueprint configure quote product URL */  
        return BuildConfigureQuoteProductURL(editMode, quoteId, productId, cloneQuoteId, null);
    }
    
    public static string BuildConfigureQuoteProductURL(string quoteId, string productId, string cloneQuoteId, string retUrl) {
        /* Return Blueprint configure quote product URL */
        return BuildConfigureQuoteProductURL(true, quoteId, productId, cloneQuoteId, retUrl);
    }

    public static string BuildConfigureQuoteProductURL(boolean editMode, string quoteId, string productId, string cloneQuoteId, string retUrl) {
        /*
            Return Blueprint configure quote product URL
        */
        
        string sUrl = BuildBaseURL(editMode, quoteId, productId, retUrl);

        // Clone Quote?
        if(!bg_StringUtils.IsBlank(cloneQuoteId)) {
            sUrl += '&' + PARAM_NAME_ACTION       + '=' + PARAM_VALUE_ACTION_COPYQUOTE + 
                    '&' + PARAM_NAME_CLONEQUOTEID + '=' + cloneQuoteId.left(15);
        }

        system.debug('sURL' + sURL);

        return sURL;
    }
    
    public static string BuildUploadFileQuoteProductURL(string quoteId, string productId, string quoteProductId, string retUrl) {
        /*
            Return Blueprint upload file quote product URL
        */

        string sUrl = BuildBaseURL(false, quoteId, productId, retUrl);
        
        sUrl += '&' + PARAM_NAME_UPLOADFILE     + '=' + PARAM_VALUE_UPLOADFILE;
        sUrl += '&' + PARAM_NAME_QUOTEPRODUCTID + '=' + quoteProductId.left(15);

        system.debug('sURL' + sURL);

        return sURL;
    }
    
    private static string BuildBaseURL(boolean editMode, string quoteId, string productId, string retUrl) {
        /*
            Return Blueprint configure quote product URL
        */
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        BPSettings__c bp = bg_CustomSettingsUtils.GetBlueprintSettings();
        string serverURL = bp.SalesforceURL__c + UserInfo.getOrganizationId();
        /*string serverURL = ss.ServerURL__c + SF_SOAP_SERVICE_URL + UserInfo.getOrganizationId();*/
        string sUrl = ss.BlueprintURL__c + 
                            PARAM_NAME_SESSIONID       + '=' + UserInfo.getSessionId() + 
                            '&' + PARAM_NAME_SERVERURL + '=' + serverURL + 
                            '&' + PARAM_NAME_QUOTEID   + '=' + quoteId.left(15);

        // Readonly mode
        if(!editMode) { sUrl += '&' + PARAM_NAME_MODE + '=' + PARAM_VALUE_MODE_READONLY; }
        
        // Add product Id
        if(!bg_StringUtils.IsBlank(productId)) {                            
            sUrl += '&' + PARAM_NAME_PRODUCTCODE + '=' + productId.left(15);
        }

        // Return Url
        if(!bg_StringUtils.IsBlank(retURL)) {
            sUrl += '&' + PARAM_NAME_RETURNURL + '=' + EncodingUtil.urlEncode(ss.ServerURL__c + retURL, URL_ENCODING_UTF8);
        } else {
            sUrl += '&' + PARAM_NAME_CLOSE     + '=' + PARAM_VALUE_CLOSE;
        }

        system.debug('sURL' + sURL);

        return sURL;
    }
    
    /*
        Method to return Blue Print URL
        
        https://{!$Setup.BPSettings__c.BluePrint_Server_URL__c}/BSIDEVTest/singlepagemerge.aspx?
            SessionId={!API.Session_ID}
            &ServerURL={!API.Partner_Server_URL_160}
            &QuoteId=a0sc0000001feMAAAY
            &TemplateName=Product+Profile
            &DocPath=quote.pdf
            &Action=Merge
            &Parameters=a0rc0000003EDAuAAO,a0rc0000003EDAUAA4,a0rc0000003EDAjAAO
    */
    public static string BuildTemplateURL(string templateName, string docPath, string quoteId, string hqQuoteProductId, string imsQuoteProductId, string samplingQuoteProductId, string quoteLanguage, string retUrl)
    {
        BPSettings__c bp = BPSettings__c.getInstance();
        string server = bp.BluePrint_Server_URL__c;
        string serverPath = bp.Blueprint_Server_Path__c;
        
        //BZ Temporary change for document merge. Only apply where it's available. 
        if (serverpath == 'BSI_Focused')
        {
            serverpath = DOCUMENT_MERGE_PATH;
        }
        
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        string serverURL = bp.SalesforceURL__c + UserInfo.getOrganizationId();
        /*string serverURL = ss.ServerURL__c + SF_SOAP_SERVICE_URL + UserInfo.getOrganizationId();*/

        // set ids to blank if they are null
        list<string> paramList = new list<string>();
        if(!string.isBlank(hqQuoteProductId))       { paramList.add(hqQuoteProductId); }
        if(!string.isBlank(imsQuoteProductId))      { paramList.add(imsQuoteProductId); }
        if(!string.isBlank(samplingQuoteProductId)) { paramList.add(samplingQuoteProductId); }
        // Ids are pass through as a comma separated string
        string idParams = bg_StringUtils.ConvertToPicklistValue(paramList, ',');
        
        if(string.isBlank(docPath))
        {
            docPath = GetDocumentName(templateName, PARAM_VALUE_DEFAULT_DOC_NAME, TEMPLATE_DOC_EXT_PDF);
        }

        string sUrl = 'https://' + server + '/' + serverPath + '/' + SINGLE_PAGE_MERGE +
                            PARAM_NAME_SESSIONID            + '=' + UserInfo.getSessionId() + 
                            '&' + PARAM_NAME_SERVERURL      + '=' + serverURL + 
                            '&' + PARAM_NAME_QUOTEID        + '=' + quoteId.left(15) +
                            // 07-02-2018 - ADS - Case 35482 - Asian Characters
                            // '&' + PARAM_NAME_TEMPLATE_NAME   + '=' + templateName +
                            '&' + PARAM_NAME_TEMPLATE_NAME  + '=' + templateName + '~' + quoteLanguage +
                            '&' + PARAM_NAME_DOC_PATH       + '=' + docPath +
                            '&' + PARAM_NAME_ACTION         + '=' + PARAM_VALUE_ACTION_MERGE +
                            '&' + PARAM_NAME_PARAMETERS     + '=' + idParams;

        return sURL;
    }
    
    /*
        Return document name
    */
    public static string GetDocumentName(string templateName, string name, string extension)
    {
        return templateName + ' - ' + name + '.' + extension;
    }
}