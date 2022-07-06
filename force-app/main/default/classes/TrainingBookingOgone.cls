public with sharing class TrainingBookingOgone
{
    // Parameters (transient except those used by 'invoice instead' link)
    public transient Map<String, String> params { get; set; }
    public transient String paramMode { get; set; }
    public String paramLanguage { get; set; }
    public String paramCountry { get; set; }
    public String paramId { get; set; }
    
    // Ogone constants (used by page)
    public transient String PSPID { get; set; }
    public transient String ALIASGATEWAY_URL { get; set; }

    // Ogone constants (not used by page)
    //static final String USERID = 'SFDCsite'; // Same for UK and UAE Test. 
    //static final String USERID = 'SFDCsiteMEA'; //Should be used for MEA PROD -
    //static final String PSWD = 'BSItest@1234';
    static String USERID;
    static String PSWD;

    // 07 Dec 2016 Vim Code updated to define  SHA signature variables  
    static String ALIASGATEWAY_SHA_IN = '';
    static String ALIASGATEWAY_SHA_OUT = '';
    // Vim code ends here 
    
    //static final String DIRECTLINK_URL = 'https://secure.ogone.com/ncol/test/orderdirect.asp';
    //static final String DIRECTLINK_URL = 'https://secure.ogone.com/ncol/prod/orderdirect.asp';
    static String DIRECTLINK_URL;

    //static final String DIRECTLINK_SHA_IN = 'BSItest@1234567890';
    static String DIRECTLINK_SHA_IN;
    static final String ENCODING = 'UTF-8';

    // Page settings
    public transient String pageUrl { get; set; }
    public transient Boolean pageIsValid { get; set; }
    public transient String pageLanguage { get; set; }
    public transient Integer pageStep { get; set; }
    public transient Boolean pageShowSelection { get; set; }

    // Retrieved information (transient except those used by 'invoice instead' link)
    public transient String courseName { get; set; }
    public transient Boolean courseAccommodation { get; set; }
    public transient TrainingBooking__c objBooking { get; set; }
    public TrainingBookingUtilities.Country selectedCountry { get; set; }
    public transient TrainingBookingUtilities.EventWrapper selectedEvent { get; set; }

    // Ogone properties
    public transient String cn { get; set; }
    public transient String brand { get; set; }
    public transient String cardNo { get; set; }
    public transient String cvc { get; set; }
    public transient String ed { get; set; }
    public transient String alias { get; set; }
    public transient String response { get; set; }
    
    //22 Nov 2016 Vim added code to declare variable for Invoicing and Delivery customer to show on Ogone Translation Page Layout
    public transient String invCustomer { get; set; }
    public transient String deliveryCustomer { get; set; }
    // Vim Code ends 
        
    // Default constructor
    public TrainingBookingOgone(){
        System.debug('### TrainingBookingOgone');

        // Set defaults
        this.pageIsValid = true;
        this.pageLanguage = 'en_US';
        this.pageStep = 5;
        this.pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingOgone';
        
        // Unbundle the page parameters
        this.params = ApexPages.currentPage().getParameters();
        this.paramMode = params.get('MODE');
        this.paramLanguage = params.get('L');
        this.paramCountry = params.get('CT');
        this.paramId = params.get('ID');

        // Get the configuration
        TrainingBookingUtilities.Configuration config = new TrainingBookingUtilities.Configuration();

        // Validate the language parameter
        if (this.paramLanguage == null || !config.supportedLanguages.containsKey(this.paramLanguage.toUpperCase()))
        {
            // Language cannot be identified - Return invalid page
            this.pageIsValid = false;
            return;
        }

        // Set the SFDC page language
        this.pageLanguage = config.supportedLanguages.get(this.paramLanguage.toUpperCase());

        // Validate the country parameter
        if (this.paramCountry == null || !config.supportedCountries.containsKey(this.paramCountry.toUpperCase()))
        {
            // Country cannot be identified - Return invalid page
            this.pageIsValid = false;
            return;
        }

        // Get the country-specific settings
        this.selectedCountry = new TrainingBookingUtilities.Country(config.supportedCountries.get(this.paramCountry.toUpperCase()), this.paramLanguage.toUpperCase(), '');

        // Validate the id parameter
        if (String.isBlank(paramId))
        {
            // Booking cannot be identified - Return invalid page
            this.pageIsValid = false;
            return;
        }

        // Populate from an existing Booking Event
        this.objBooking = TrainingBookingUtilities.bookingDetails(this.paramId);
		
        
        // Re-populate the Course/Event details
        this.courseAccommodation = this.objBooking.Is_Residential__c;
        if (this.courseAccommodation)
        {
            this.selectedEvent = new TrainingBookingUtilities.EventWrapper(this.objBooking.Training_Event__c, this.objBooking.Pricebook_Inc_Accommodation__c, this.objBooking.Pricebook_Exc_Accommodation__c, this.objBooking.CurrencyIsoCode, this.objBooking.Price_Inc_Accommodation__c, this.objBooking.Price_Exc_Accommodation__c);
        }
        else
        {
            this.selectedEvent = new TrainingBookingUtilities.EventWrapper(this.objBooking.Training_Event__c, this.objBooking.Pricebook_Entry__c, null, this.objBooking.CurrencyIsoCode, this.objBooking.Price_Per_Delegate__c, null);
        }
        this.courseName = this.selectedEvent.event.Course__r.Product_Name_Local__c;
            
        // Re-populate the page settings
        this.pageShowSelection = !(this.selectedEvent.event.Course__r.Delivery_Method__c == 'Distance Learning' || this.selectedEvent.event.Course__r.Delivery_Method__c == 'eLearning');

        // Check whether already paid
        if (String.isNotBlank(this.objBooking.Payment_Order_No__c))
        {
            // There is already a payment ref - Return invalid page
            this.pageIsValid = false;
            return;
        }
        
        // PC 13092018 general 'System Setting' Custom Settings
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        ALIASGATEWAY_URL = ss.Ingenico_Ogone_ALIASGATEWAY_URL__c;
        DIRECTLINK_URL = ss.Ingenico_Ogone_DIRECTLINK_URL__c;

        // Set the gateway parameters according to the country
        // PC 13092018 country-specific 'Ingenico (Ogone) Settings' Custom Settings
        Ingenico_Ogone_Settings__c ios;
        if(this.selectedCountry.gateway == 'OgoneME') ios = Ingenico_Ogone_Settings__c.getInstance('OgoneME');
        else ios = Ingenico_Ogone_Settings__c.getInstance('Ogone');

        USERID = ios.USERID__c;
        PSPID = ios.PSPID__c;
        PSWD = ios.PSWD__c;
        ALIASGATEWAY_SHA_IN = ios.ALIASGATEWAY_SHA_IN__c;
        ALIASGATEWAY_SHA_OUT = ios.ALIASGATEWAY_SHA_OUT__c;
        DIRECTLINK_SHA_IN = ios.DIRECTLINK_SHA_IN__c;

        /*
        {
            // Settings for the Middle East instance
            this.PSPID = 'BSIOnlineUAE';
            //this.ALIASGATEWAY_URL = 'https://secure.ogone.com/ncol/test/alias_gateway.asp';
            this.ALIASGATEWAY_URL = 'https://secure.ogone.com/ncol/prod/alias_gateway.asp';
            
            // 07 Dec 2016 vim Code updated to get correct UAE SHA signature
    		//ALIASGATEWAY_SHA_IN = 'cm}AR3e8w[cMfnPl5v!'; //UAE Test
            //ALIASGATEWAY_SHA_OUT = 'u]mKNE&VCgry9Rh9}4J';//UAE Test
            ALIASGATEWAY_SHA_IN = 'BSItest@1234567890'; // UAE Prod
            ALIASGATEWAY_SHA_OUT = 'BSItest@0987654321'; // UAE Prod
            // Vim code ends here
        }
        else
        {
            // 27 March 2017 vim updated code to add PSP ID and UK SHA signature
             // Setting for the Global Instance
            this.PSPID = 'BSIOnlineUK';
            //this.ALIASGATEWAY_URL = 'https://secure.ogone.com/ncol/test/alias_gateway.asp';
            this.ALIASGATEWAY_URL = 'https://secure.ogone.com/ncol/prod/alias_gateway.asp';
            
            //ALIASGATEWAY_SHA_IN = ',8kqTnlxYJj!}vE4G7b'; // UK Test
            //ALIASGATEWAY_SHA_OUT = 'U[}CTN8Lkn4J3%GvKyL'; // UK Test
             ALIASGATEWAY_SHA_IN = 'BSItest@1234567890';//UK Prod - For production PSPID BSOnline, the information is not available yet because the PSPID is not activate it. 
             ALIASGATEWAY_SHA_OUT = 'BSItest@0987654321';//UK Prod - For production PSPID BSOnline, the information is not available yet because the PSPID is not activate it.
        }
        */
    }
    
    // Workflow processor
    public PageReference processor()
    {
        // Deal with errors
        if (!this.pageIsValid) return errorPage();
        System.debug('pagevalid'+this.pageIsValid);
        System.debug('paramMode '+this.paramMode);
        // Handle response from Alias Gateway
        if (this.paramMode == 'ALIAS')
        {
            // Unbundle Alias Gateway outputs
            String orderId = ApexPages.currentPage().getParameters().get('ORDERID');
             
            String status = ApexPages.currentPage().getParameters().get('STATUS');
            this.alias = ApexPages.currentPage().getParameters().get('ALIAS');
            this.cn = ApexPages.currentPage().getParameters().get('CN');
            this.brand = ApexPages.currentPage().getParameters().get('BRAND');
            this.cardNo = ApexPages.currentPage().getParameters().get('CARDNO');
            this.cvc = ApexPages.currentPage().getParameters().get('CVC');
            
            //22 Nov 2016 Vim added code to get Invoicing and Delivery customer to show on Ogone Translation Page Layout
            this.invCustomer = ApexPages.currentPage().getParameters().get('ECOM_BILLTO_POSTAL_NAME_FIRST');
            this.deliveryCustomer = ApexPages.currentPage().getParameters().get('ECOM_SHIPTO_POSTAL_NAME_FIRST');
            // vim code end here 
            
            this.ed = ApexPages.currentPage().getParameters().get('ED');
            String ncError = ApexPages.currentPage().getParameters().get('NCERROR');
            String ncErrorCn = ApexPages.currentPage().getParameters().get('NCERRORCN');
            String ncErrorCardNo = ApexPages.currentPage().getParameters().get('NCERRORCARDNO');
            String ncErrorCvc = ApexPages.currentPage().getParameters().get('NCERRORCVC');
            String ncErrorEd = ApexPages.currentPage().getParameters().get('NCERRORED');
            String shaSign = ApexPages.currentPage().getParameters().get('SHASIGN');
            // Validate response using expected SHA-OUT
            String recvd = '';
            if (String.isNotBlank(this.alias)) recvd += 'ALIAS=' + this.alias + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(this.brand)) recvd += 'BRAND=' + this.brand + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(this.cardNo)) recvd += 'CARDNO=' + this.cardNo + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(this.cn)) recvd += 'CN=' + this.cn + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(this.cvc)) recvd += 'CVC=' + this.cvc + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(this.ed)) recvd += 'ED=' + this.ed + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(ncError)) recvd += 'NCERROR=' + ncError + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(ncErrorCardNo)) recvd += 'NCERRORCARDNO=' + ncErrorCardNo + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(ncErrorCn)) recvd += 'NCERRORCN=' + ncErrorCn + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(ncErrorCvc)) recvd += 'NCERRORCVC=' + ncErrorCvc + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(ncErrorEd)) recvd += 'NCERRORED=' + ncErrorEd + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(orderId)) recvd += 'ORDERID=' + orderId + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(status)) recvd += 'STATUS=' + status + ALIASGATEWAY_SHA_OUT;
            System.debug('shaSign'  + shaSign);
            System.debug('shaSign'  + EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(recvd))).toUpperCase());
            if (shaSign != EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(recvd))).toUpperCase())
            {
                addErr(Label.TrainingBookingOgoneErrGeneral);
                this.paramMode = '';
                this.objBooking.Payment_Error_Message__c = 'SHA Signature mismatch'; // 13 Jan 2017 Vim added link to track error message 
                System.debug(logginglevel.ERROR, '##184## ' + shaSign + ' ' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(recvd))).toUpperCase());
                return null;
            }
            
            // Check status
            if (status == '0' || status == '2') // OK (0) or Alias updated (2)
            {
                // Alias Gateway call has succeeded
                try
                {
                    // Build a DirectLink request
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(DIRECTLINK_URL);
                    req.setMethod('POST');
                    req.setCompressed(false);
                    String params = '';

                    // Add page parameters
                    params += 'ID=' + EncodingUtil.urlEncode(this.objBooking.Id, ENCODING); // Not included in SHA-IN
                    params += '&CT=' + EncodingUtil.urlEncode(this.paramCountry, ENCODING); // Not included in SHA-IN
                    params += '&L=' + EncodingUtil.urlEncode(this.paramLanguage, ENCODING); // Not included in SHA-IN

                    // Add transaction parameters
                    params += '&ALIAS=' + EncodingUtil.urlEncode(alias, ENCODING);
                    
                    //22 Nov 2016 Vim added code to add parameter for Invoicing and Delivery customer to Ogone
                    params += '&ECOM_BILLTO_POSTAL_NAME_FIRST=' + EncodingUtil.urlEncode(this.invCustomer, ENCODING);
                    params += '&ECOM_SHIPTO_POSTAL_NAME_FIRST=' + EncodingUtil.urlEncode(this.deliveryCustomer, ENCODING);
                    // Vim code end
                     
                    params += '&PSPID=' + EncodingUtil.urlEncode(this.PSPID, ENCODING);
                    params += '&ORDERID=' + EncodingUtil.urlEncode(this.objBooking.Name, ENCODING);
                  
                    params += '&USERID=' + EncodingUtil.urlEncode(USERID, ENCODING);
                    params += '&PSWD=' + EncodingUtil.urlEncode(PSWD, ENCODING);
                    params += '&AMOUNT=' + EncodingUtil.urlEncode(String.valueOf(Integer.valueOf((this.objBooking.Total_Price__c * 100))), ENCODING); // TODO
                    params += '&CURRENCY=' + EncodingUtil.urlEncode(this.objBooking.CurrencyIsoCode, ENCODING);
					
                    // Add 3D Secure parameters
                    params += '&FLAG3D=Y';
                    params += '&HTTP_ACCEPT=' + EncodingUtil.urlEncode(ApexPages.currentPage().getHeaders().get('Accept'), ENCODING);
                    params += '&HTTP_USER_AGENT=' + EncodingUtil.urlEncode(ApexPages.currentPage().getHeaders().get('User-Agent'), ENCODING);
                    params += '&WIN3DS=MAINW';
                    params += '&ACCEPTURL=' + EncodingUtil.urlEncode(this.pageUrl + '?MODE=3D', ENCODING);
                    params += '&DECLINEURL=' + EncodingUtil.urlEncode(this.pageUrl + '?MODE=3D', ENCODING);
                    params += '&EXCEPTIONURL=' + EncodingUtil.urlEncode(this.pageUrl + '?MODE=3D', ENCODING);
                    params += '&PARAMPLUS=' + EncodingUtil.urlEncode('CT=' + this.paramCountry + '&L=' + this.paramLanguage + '&ID=' + this.objBooking.Id, ENCODING);
                    params += '&LANGUAGE=' + EncodingUtil.urlEncode(this.pageLanguage, ENCODING);
					
                    // Add SHA-IN signature
                    params += '&SHASIGN=' + getDirectLinkShaIn();
                    // Send the request and read response (support test class)
                    req.setBody(params);
                    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                    Http http = new Http();
                    HttpResponse res;
                    Dom.Document xmlDoc;
                    if (!Test.isRunningTest())
                    {
                        // Live code
                        res = http.send(req);
                        xmlDoc = res.getBodyDocument();
                    }
                    else
                    {
                        // Test code (success)
                        res = new HttpResponse();
                        xmlDoc = new Dom.Document();
                        xmlDoc.load('<?xml version="1.0"?><ncresponse NCERROR="0" PAYID="1234567890" BRAND="VISA" />');
                    }
                    
                    // Read the response
                    Dom.XmlNode xmlRoot = xmlDoc.getRootElement();
                    Dom.XmlNode xml3dHtml = xmlRoot.getChildElement('HTML_ANSWER', null);
                    if (xml3dHtml != null)
                    {
                        // 3D Secure is required
                        this.paramMode = '3D';
                        this.response = EncodingUtil.base64Decode(xml3dHtml.getText()).toString();
                        // 22 Nov Vim added error response to debug transaction if required
                        System.debug(logginglevel.ERROR, '##257##'+'##OgoneResponse##'+this.response); 
                        
                        this.objBooking.Payment_Error_Message__c = this.response; // 13 Jan 2017 Vim added link to track error message
                         
                        return null;
                    }
                    else
                    {
                        // Parse the response
                        String xmlNcError = xmlRoot.getAttributeValue('NCERROR', null);
                        this.objBooking.Payment_Error_Code__c = xmlNcError; // 13 Jan 2017 Vim added link to track error Code
						System.debug('##OgoneErrorCode##'+xmlNcError);
                        if (xmlNcError == '0')
                        {
                            // Parse the rest
                            String xmlPayId = xmlRoot.getAttributeValue('PAYID', null);
                            String xmlBrand = xmlRoot.getAttributeValue('BRAND', null);
    
                            // DirectLink Success - Update the Training Booking record
                            TrainingBooking__c booking = new TrainingBooking__c(Id = this.paramId);
                            booking.Payment_Card__c = xmlBrand;
                            booking.Payment_Name__c = '';
                            booking.Payment_Status__c = 'Paid Online';
                            booking.Payment_Order_No__c = xmlPayId;
                            booking.Convert_To_On_Hold__c = false;
                            update booking;
                            
                            // Asynchronous call to SAP
                            System.debug('justbeforesap');
                            TrainingBookingUtilities.sapOrder(this.paramId);
                            
                            // Redirect to confirmation page
                            return successPage();
                        }
                        else
                        {
                            // DirectLink Failure - Report the problem
                            this.paramMode = '';
                            addErr(Label.TrainingBookingOgoneErrGeneral);
                            // 22 Nov Vim added error code to debug transaction if required
                            System.debug(logginglevel.ERROR, '##292##'+'##OgoneErrorCode##'+xmlNcError);
                            this.objBooking.Payment_Error_Code__c = xmlNcError; // 13 Jan 2017 Vim added link to track error Code
                            return null;                        
                        }
                    }
                }
                catch (Exception ex)
                {
                    this.paramMode = '';
                    addErr(Label.TrainingBookingOgoneErrGeneral);
                    // 22 Nov Vim added error exception to debug transaction if required
                    System.debug(logginglevel.ERROR, '##301##'+'##OgoneException##'+ex.getMessage()); 
                    this.objBooking.Payment_Error_Message__c = ex.getMessage(); // 13 Jan 2017 Vim added link to track error Message
                    return null;                        
                }
            }
            else
            {
                // 22 Nov Vim added error code to debug transaction if required
                System.debug(logginglevel.ERROR, '##OgoneErrorCode#ncError#'+ncError); 
                System.debug(logginglevel.ERROR, '##OgoneErrorCode#ncErrorCn#'+ncErrorCn); 
                System.debug(logginglevel.ERROR, '##OgoneErrorCode#ncErrorCardNo#'+ncErrorCardNo); 
                System.debug(logginglevel.ERROR, '##OgoneErrorCode#ncErrorCvc#'+ncErrorCvc); 
                System.debug(logginglevel.ERROR, '##OgoneErrorCode#ncErrorEd#'+ncErrorEd); 
                // 13 Jan 2017 Vim added link to track error Code
                if(ncError != '') this.objBooking.Payment_Error_Code__c = ncError;
                if(ncErrorCn != '') this.objBooking.Payment_Error_Code__c = 'Error in Card Holder Name' + ncErrorCn;
                if(ncErrorCardNo != '') this.objBooking.Payment_Error_Code__c = 'Error in Card No' + ncErrorCardNo;
                if(ncErrorCvc != '') this.objBooking.Payment_Error_Code__c = ' Error in CVC No ' + ncErrorCvc;
                if(ncErrorEd != '') this.objBooking.Payment_Error_Code__c = ' Error in Expiry date ' + ncErrorEd;
                // Vim code ends here
                
                // Alias Gateway call has failed

                // 55555555 General error
                // 50001184 SHA_IN mismatch
                // 50001186 Operation not allowed. ORDERID but alias already exists
                // 50001187 Operation not allowed. Alias already exists
                // 50001300 Wrong brand specified
                // 50001301 Wrong bank account format
                if (ncError == '55555555' || ncError == '50001184' || ncError == '50001186' || ncError == '50001187' || ncError == '50001300' || ncError == '50001301') addErr(Label.TrainingBookingOgoneErrGeneral);
                
                // 60001057 Name is missing
                // 50001174 Name is too long
                if (ncErrorCn == '60001057' || ncErrorCn == '50001174') addErr(Label.TrainingBookingOgoneErrCardholder); 

                // 30141001 Invalid card number
                // 50001069 Brand and card number do not match
                // 50001176 Card number is too long
                // 50001177 Card number contains non-numerics
                // 50001178 Card number too short
                if (ncErrorCardNo == '30141001' || ncErrorCardNo == '50001069' || ncErrorCardNo == '50001176' || ncErrorCardNo == '50001177' || ncErrorCardNo == '50001178') addErr(Label.TrainingBookingOgoneErrCardNo);

                // 50001090 CVC missing or too short
                // 50001179 CVC too long
                // 50001180 CVC contains non-numerics
                if (ncErrorCvc == '50001090' || ncErrorCvc == '50001179' || ncErrorCvc == '50001180') addErr(Label.TrainingBookingOgoneErrCvc);

                // 50001181 Expiry date contains non-numerics
                // 50001182 Invalid expiry month
                // 50001183 Expiry date must be in the future
                // 31061001 Expiry date empty or wrong format
                if (ncErrorEd == '50001181' || ncErrorEd == '50001182' || ncErrorEd == '50001183' || ncErrorEd == '31061001') addErr(Label.TrainingBookingOgoneErrDate);
                this.paramMode = '';
                System.debug(logginglevel.ERROR, '##339##');
                return null;
            }
        }
        
        // Handle response from 3D secure process
        if (this.paramMode == '3D')
        {
            // Unbundle Ogone parameters
            String orderId = ApexPages.currentPage().getParameters().get('ORDERID');
            String status = ApexPages.currentPage().getParameters().get('STATUS');
            String payId = ApexPages.currentPage().getParameters().get('PAYID');
            String ncError = ApexPages.currentPage().getParameters().get('NCERROR');
            String shaSign = ApexPages.currentPage().getParameters().get('SHASIGN');
            
            // Validate response using expected SHA-OUT
            String recvd = '';
            if (String.isNotBlank(ncError)) recvd += 'NCERROR=' + ncError + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(orderId)) recvd += 'ORDERID=' + orderId + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(payId)) recvd += 'PAYID=' + payId + ALIASGATEWAY_SHA_OUT;
            if (String.isNotBlank(status)) recvd += 'STATUS=' + status + ALIASGATEWAY_SHA_OUT;
            if (shaSign != EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(recvd))).toUpperCase())
            {
                this.paramMode = '';
                addErr(Label.TrainingBookingOgoneErrGeneral);
                System.debug(logginglevel.ERROR, '##364##');
                return null;
            }

            // Check for success
            if (ncError == '0')
            {
                // DirectLink Success - Update the Training Booking record
                TrainingBooking__c booking = new TrainingBooking__c(Id = this.paramId);
                booking.Payment_Card__c = '';
                booking.Payment_Name__c = '';
                booking.Payment_Status__c = 'Paid Online';
                booking.Payment_Order_No__c = payId;
                booking.Convert_To_On_Hold__c = false;
                update booking;
                            
                // Asynchronous call to SAP
                TrainingBookingUtilities.sapOrder(this.paramId);
                            
                // Redirect to confirmation page
                return successPage();
            }
            else
            {
                this.paramMode = '';            
                addErr(Label.TrainingBookingOgoneErrGeneral);
                System.debug(logginglevel.ERROR, '##390##');
                return null;
            }
        }

        // Handle initial entry
        System.debug(logginglevel.ERROR, '##396##');
        return null;
    }
    
    // Add an error to the list
    private void addErr(String errMsg)
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
    }

    // Generate the SHA signature for Alias Gateway
    public String getAliasGatewayShaIn()
    {
        String myValues = '';
        myValues += 'ACCEPTURL=' + this.pageUrl + '?MODE=ALIAS' + ALIASGATEWAY_SHA_IN;
        myValues += 'EXCEPTIONURL=' + this.pageUrl + '?MODE=ALIAS' + ALIASGATEWAY_SHA_IN;
        myValues += 'ORDERID=' + this.objBooking.Name + ALIASGATEWAY_SHA_IN;
        myValues += 'PARAMPLUS=CT=' + this.paramCountry + '&L=' + this.paramLanguage + '&ID=' + this.objBooking.Id + ALIASGATEWAY_SHA_IN;     
        myValues += 'PSPID=' + this.PSPID + ALIASGATEWAY_SHA_IN;
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(myValues))).toUpperCase();
    }

    // Generate the SHA signature for DirectLink    
    public String getDirectLinkShaIn()
    {
        String myValues = '';
        myValues += 'ACCEPTURL=' + this.pageUrl + '?MODE=3D' + DIRECTLINK_SHA_IN;        
        myValues += 'ALIAS=' + this.alias + DIRECTLINK_SHA_IN;
        myValues += 'AMOUNT=' + String.valueOf(Integer.valueOf((this.objBooking.Total_Price__c * 100))) + DIRECTLINK_SHA_IN; 
        myValues += 'CURRENCY=' + this.objBooking.CurrencyIsoCode + DIRECTLINK_SHA_IN;
        myValues += 'DECLINEURL=' + this.pageUrl + '?MODE=3D' + DIRECTLINK_SHA_IN;
        
        //22 Nov 2016 Vim added code to add parameter to SHA Signature for Invoicing and Delivery customer to Ogone
        myValues += 'ECOM_BILLTO_POSTAL_NAME_FIRST=' + this.invCustomer + DIRECTLINK_SHA_IN;
        myValues += 'ECOM_SHIPTO_POSTAL_NAME_FIRST=' + this.deliveryCustomer + DIRECTLINK_SHA_IN;
        //Vim code ends here
        
        myValues += 'EXCEPTIONURL=' + this.pageUrl + '?MODE=3D' + DIRECTLINK_SHA_IN;
        myValues += 'FLAG3D=Y' + DIRECTLINK_SHA_IN;
        myValues += 'HTTP_ACCEPT=' + ApexPages.currentPage().getHeaders().get('Accept') + DIRECTLINK_SHA_IN;
        myValues += 'HTTP_USER_AGENT=' + ApexPages.currentPage().getHeaders().get('User-Agent') + DIRECTLINK_SHA_IN;
        myValues += 'LANGUAGE=' + this.pageLanguage + DIRECTLINK_SHA_IN;
        myValues += 'ORDERID=' + this.objBooking.Name + DIRECTLINK_SHA_IN;
        myValues += 'PARAMPLUS=CT=' + this.paramCountry + '&L=' + this.paramLanguage + '&ID=' + this.objBooking.Id + DIRECTLINK_SHA_IN;
        myValues += 'PSPID=' + this.PSPID + DIRECTLINK_SHA_IN;
        myValues += 'PSWD=' + PSWD + DIRECTLINK_SHA_IN;
        myValues += 'USERID=' + USERID + DIRECTLINK_SHA_IN;
        myValues += 'WIN3DS=MAINW' + DIRECTLINK_SHA_IN;
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(myValues))).toUpperCase();
    }

    // Execute option to invoice instead
    public PageReference invoiceInstead()
    {
        // Modify the booking record
        TrainingBooking__c booking = new TrainingBooking__c(Id = this.paramId);
        booking.Payment_Method__c = 'Invoice';
        booking.Payment_Status__c = 'Invoice';
        update booking;
                
        // Redirect to confirmation page
        return successPage();
    }

    // Return the confirmation page
    public PageReference successPage()
    {
        PageReference ref = Page.TrainingBooking6;
        ref.getParameters().put('ID', this.paramId);
        ref.getParameters().put('CT', this.paramCountry);
        ref.getParameters().put('L', this.paramLanguage);
        ref.setRedirect(true);
        return ref;
    }

    // Return the error page
    public PageReference errorPage()
    {
        PageReference ref = Page.TrainingBooking7;
        ref.getParameters().put('ID', this.paramId);
        ref.getParameters().put('CT', this.paramCountry);
        ref.getParameters().put('L', this.paramLanguage);
        ref.setRedirect(true);
        return ref;
    }   
}