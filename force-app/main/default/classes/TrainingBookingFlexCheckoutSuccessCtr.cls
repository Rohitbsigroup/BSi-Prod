/*
    Created by: Mahmood (Cognizant) on 28/01/2020
    Description: PCI-DSS compliance project. Changes to convert current payment system to Flexcheckout with iFrame and DirectLink.
    -----------------------------------------------------------
    Changed by          Changed date        Description
*/
public with sharing class TrainingBookingFlexCheckoutSuccessCtr {
    
    public transient Map<String, String> params { get; set; }
    public transient String paramMode { get; set; }
    public String paramCountry {get;set;}
    public String paramLanguage {get;set;}
    //public String paramId { get; set; }
    public Boolean paymentSucceeded { get;set; }
    
    // Ogone constants (used by page)
    public transient String PSPID { get; set; }
    public transient String ALIASGATEWAY_URL { get; set; }

    // Ogone constants (not used by page)
    static String USERID;
    static String PSWD;

    static String ALIASGATEWAY_SHA_IN = '';
    static String ALIASGATEWAY_SHA_OUT = '';
    
    static String DIRECTLINK_URL;

    //static final String DIRECTLINK_SHA_IN = 'BSItest@1234567890';
    static String DIRECTLINK_SHA_IN;
    static final String ENCODING = 'UTF-8';
    //static final String SHAEncoding = 'SHA512';
    String SHAEncoding;
    // Page settings
    public transient String pageUrl { get; set; }
    public transient Boolean pageIsValid { get; set; }
    public transient String pageLanguage { get; set; }
    public transient Integer pageStep { get; set; }
    //public transient Boolean pageShowSelection { get; set; }
    // Retrieved information (transient except those used by 'invoice instead' link)
    
    //public transient String courseName { get; set; }
    //public transient Boolean courseAccommodation { get; set; }
    public transient TrainingBooking__c objBooking { get; set; }
    public TrainingBookingUtilities.Country selectedCountry { get; set; }
    public transient TrainingBookingUtilities.EventWrapper selectedEvent { get; set; }
    // Ogone properties
    /*
    public transient String cn { get; set; }
    public transient String brand { get; set; }
    public transient String cardNo { get; set; }
    public transient String cvc { get; set; }
    public transient String ed { get; set; }
    */
    public transient String alias { get; set; }
    public String response { get; set; }
    
    public TrainingBookingFlexCheckoutSuccessCtr() 
    {
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        // Ingenico/Ogone settings
        Ingenico_Ogone_Settings__c ios;
        // Get the configuration
        TrainingBookingUtilities.Configuration config = new TrainingBookingUtilities.Configuration();
        String orderno;
        // Set defaults
        pageIsValid = true;
        pageLanguage = 'en_US';
        pageStep = 5;
        paymentSucceeded = false;
        // page parameters from FlexCheckout response after submitting card details
        params = ApexPages.currentPage().getParameters();
        for(String str: params.keySet() ) system.debug(logginglevel.ERROR, 'key:' + str + ' - value:' + params.get(str));

        paramMode = params.get('MODE');
        // FlexCheckout call
        if(paramMode == null) 
        {
            //  MB: 17-02-2020 - temp logic - until case with Ingenico is resolved 01146319
            if(String.isNotBlank(params.get('CT')))
            {
                String[] paramplus = params.get('CT').Split('_');
                paramCountry = paramplus[0];
                paramLanguage = paramplus[1].substring(2);
            }
            orderno = params.get('Alias.OrderId');   // non 3-D call
            system.debug(logginglevel.ERROR, 'Orderno::'+ orderno);
            // Populate from an existing Booking Event
            objBooking = TrainingBookingUtilities.bookingDetailsByName(orderno);
            if(params.get('Alias.AliasId') == null) return;
            
            pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingFlexCheckoutSuccessVfp';
            // System settings
            ALIASGATEWAY_URL = ss.Ingenico_Ogone_ALIASGATEWAY_URL__c;
            DIRECTLINK_URL = ss.Ingenico_Ogone_DIRECTLINK_URL__c;
            SHAEncoding = ss.SHAEncoding__c;
            // Get the country-specific settings
            System.debug(logginglevel.ERROR, 'paramCountry::' + paramCountry + ' -- paramLanguage::' + paramLanguage);
            selectedCountry = new TrainingBookingUtilities.Country(config.supportedCountries.get(paramCountry.toUpperCase()), paramLanguage.toUpperCase(), '');
            /*
            if(selectedCountry.gateway == 'OgoneME') ios = Ingenico_Ogone_Settings__c.getInstance('OgoneME');
            else if(selectedCountry.gateway == 'NAB') ios = Ingenico_Ogone_Settings__c.getInstance('OgoneAus');
            else ios = Ingenico_Ogone_Settings__c.getInstance('Ogone');
            */
            ios = Ingenico_Ogone_Settings__c.getInstance(selectedCountry.gateway);
            if(ios == null) {
                System.debug('No settings found with the name:' + selectedCountry.gateway);
                return;
            }
            USERID = ios.USERID__c;
            PSPID = ios.PSPID__c;
            PSWD = ios.PSWD__c;
            ALIASGATEWAY_SHA_IN = ios.ALIASGATEWAY_SHA_IN__c;
            ALIASGATEWAY_SHA_OUT = ios.ALIASGATEWAY_SHA_OUT__c;
            DIRECTLINK_SHA_IN = ios.DIRECTLINK_SHA_IN__c;
        }
    }
    // method called in the action of the vf page
    public PageReference processPayment()
    {
        // Deal with errors
        if (!pageIsValid) return errorPage();
        // if its 3D response
        if(paramMode == '3D')
        {
            update3DBooking();
            return null;
        }
        // Unbundle Alias Gateway outputs
        alias = params.get('ALIAS.ALIASID');
        String orderId = params.get('ALIAS.ORDERID');
        String status = params.get('ALIAS.STATUS');
        String ncError = params.get('ALIAS.CERROR');
        String ncErrorCn = params.get('ALIAS.NCERRORCN');
        String ncErrorCardNo = params.get('ALIAS.NCERRORCARDNO');
        String ncErrorCvc = params.get('ALIAS.NCERRORCVC');
        String ncErrorEd = params.get('ALIAS.NCERRORED');
        String shaSignFlex = params.get('SHASIGN');
        
        // Validate response using expected SHA-OUT
        if(!isSHA_Valid(shaSignFlex, ALIASGATEWAY_SHA_OUT)) return null;
        system.debug(logginglevel.ERROR, 'status::' + status);
        // Check status
        if (status == '0' || status == '2') // OK (0) or Alias updated (2)
        {
            String params = '';

            // Add page parameters
            /*
            params += 'ID=' + EncodingUtil.urlEncode(objBooking.Id, ENCODING); // Not included in SHA-IN
            params += '&CT=' + EncodingUtil.urlEncode(paramCountry, ENCODING); // Not included in SHA-IN
            params += '&L=' + EncodingUtil.urlEncode(paramLanguage, ENCODING); // Not included in SHA-IN
            */
            // Add transaction parameters
            params += 'ALIAS=' + EncodingUtil.urlEncode(alias, ENCODING);
            params += '&AMOUNT=' + EncodingUtil.urlEncode(String.valueOf(Integer.valueOf((objBooking.Total_Price__c * 100))), ENCODING); 
            params += '&CURRENCY=' + EncodingUtil.urlEncode(objBooking.CurrencyIsoCode, ENCODING);
            params += '&ECI=' + EncodingUtil.urlEncode('7', ENCODING);
            params += '&LANGUAGE=' + EncodingUtil.urlEncode(pageLanguage, ENCODING);
            params += '&OPERATION=' + EncodingUtil.urlEncode('SAL', ENCODING);
            params += '&ORDERID=' + EncodingUtil.urlEncode(orderId, ENCODING);
            params += '&PSPID=' + EncodingUtil.urlEncode(PSPID, ENCODING);
            params += '&PSWD=' + EncodingUtil.urlEncode(PSWD, ENCODING);
            params += '&USERID=' + EncodingUtil.urlEncode(USERID, ENCODING);
            
            // Add 3D Secure parameters
            
            params += '&ACCEPTURL=' + EncodingUtil.urlEncode(pageUrl + '?MODE=3D', ENCODING);
            params += '&DECLINEURL=' + EncodingUtil.urlEncode(pageUrl + '?MODE=3D', ENCODING);
            params += '&EXCEPTIONURL=' + EncodingUtil.urlEncode(pageUrl + '?MODE=3D', ENCODING);
            params += '&FLAG3D=Y';
            params += '&HTTP_ACCEPT=' + EncodingUtil.urlEncode(ApexPages.currentPage().getHeaders().get('Accept'), ENCODING);
            params += '&HTTP_USER_AGENT=' + EncodingUtil.urlEncode(ApexPages.currentPage().getHeaders().get('User-Agent'), ENCODING);
            params += '&WIN3DS=MAINW';
            
            //params += '&PARAMPLUS=' + EncodingUtil.urlEncode('CT=' + paramCountry + '&L=' + paramLanguage + '&ID=' + objBooking.Id, ENCODING);
            
            // Add SHA-IN signature
            params += '&SHASIGN=' + getDirectLinkShaIn();
            system.debug(logginglevel.ERROR, 'DirectlinkURL::' + DIRECTLINK_URL + '?' + params);
            
            // Build a DirectLink request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(DIRECTLINK_URL);
            req.setMethod('POST');
            req.setCompressed(false);
            req.setBody(params);
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            Http http = new Http();
            HttpResponse res;
            Dom.Document xmlDoc;
            if (!Test.isRunningTest())
            {
                // Live code
                system.debug(logginglevel.ERROR, 'req::' + req);
                res = http.send(req);
                xmlDoc = res.getBodyDocument();
            }
            else
            {
                // Test code (success)
                res = new HttpResponse();
                xmlDoc = new Dom.Document();
                xmlDoc.load('<?xml version="1.0"?><ncresponse NCERROR="0" PAYID="1234567890" BRAND="VISA" STATUS="9" />');
            }
            
            // Read the response
            System.debug(logginglevel.ERROR, 'xmldoc::' + xmlDoc.toXmlString());
            Dom.XmlNode xmlRoot = xmlDoc.getRootElement();
            Dom.XmlNode xml3dHtml = xmlRoot.getChildElement('HTML_ANSWER', null);
            system.debug(logginglevel.ERROR, 'xml3dHtml::' + xml3dHtml);
            String transStatus;
            
            // MB- 03-03-2020-Error checks
            if(transactionHasErrors(xmlRoot)) return null;
            
            if (xml3dHtml != null)
            {
                // 3D Secure is required
                paramMode = '3D';
                response = EncodingUtil.base64Decode(xml3dHtml.getText()).toString();
                System.debug(logginglevel.ERROR, 'before-OgoneResponse::'+response); 
                
                // enescape | (pipe) sign - it should be only replaced in the JS.
                response = response.replace('&#124;', '|');  //.replace('&#38;', '&')
                System.debug(logginglevel.ERROR, 'after-Response::'+response); 
                // check transaction status
                if(xmlRoot.getAttributeValue('STATUS', null) == '46') transStatus= 'Waiting for Identification';

            }
            else
            {
                transStatus = 'Paid Online';
            }
            // Parse the response
            String xmlNcError = xmlRoot.getAttributeValue('NCERROR', null);
            objBooking.Payment_Error_Code__c = xmlNcError; 
            System.debug(logginglevel.ERROR, 'OgoneErrorCode::'+xmlNcError);
            String xmlPayId = xmlRoot.getAttributeValue('PAYID', null);
            if (xmlNcError == '0')
            {
                // Parse the rest
                String xmlBrand = xmlRoot.getAttributeValue('BRAND', null);

                // DirectLink Success - Update the Training Booking record
                TrainingBooking__c booking = new TrainingBooking__c(Id = objBooking.Id);
                booking.Payment_Card__c = xmlBrand;
                booking.Payment_Name__c = '';
                booking.Payment_Status__c = transStatus;
                If(xml3dHtml == null) booking.Payment_Order_No__c = xmlPayId;
                booking.Convert_To_On_Hold__c = false;
                update booking;
                
                //  --- set cookie to be check in the OgoneIframe page ---
                Cookie pmtStatus = ApexPages.currentPage().getCookies().get('pmtstatus');
                // if not 3D
                if(pmtStatus == null && transStatus != 'Waiting for Identification') 
                {
                    pmtStatus = new Cookie('pmtstatus', 'true', null, -1, true, 'None' );
                    System.debug(logginglevel.ERROR, 'Cookie::' + pmtStatus);
                    ApexPages.currentPage().setCookies(new Cookie[]{pmtstatus});
                    //  --- set cookie end ---
                    // Asynchronous call to SAP
                    TrainingBookingUtilities.sapOrder(objBooking.Id);
                }    
                paymentSucceeded = true;  // xmlRoot.getAttributeValue('STATUS', null) == '46' ? false:true;
            }
            else
            {
                system.debug(logginglevel.ERROR, '## line 236');
                // DirectLink Failure - Report the problem
                paramMode = '';
                String errMsg = '';
                errMsg = (xmlPayId!='0') ? Label.TrainingBookingExistingOrder + xmlPayId : Label.TrainingBookingOgoneErrGeneral;
                addErr(errMsg);
            }
            return null;
        }
        else
        {
            paymentSucceeded = false;
            // track error Code
            if(ncError != '') objBooking.Payment_Error_Code__c = ncError;
            if(ncErrorCn != '') objBooking.Payment_Error_Code__c = 'Error in Card Holder Name' + ncErrorCn;
            if(ncErrorCardNo != '') objBooking.Payment_Error_Code__c = 'Error in Card No' + ncErrorCardNo;
            if(ncErrorCvc != '') objBooking.Payment_Error_Code__c = ' Error in CVC No ' + ncErrorCvc;
            if(ncErrorEd != '') objBooking.Payment_Error_Code__c = ' Error in Expiry date ' + ncErrorEd;
            
            /*
            if (ncError == '55555555' || ncError == '50001184' || ncError == '50001186' || ncError == '50001187' || ncError == '50001300' || ncError == '50001301') 
                addErr(Label.TrainingBookingOgoneErrGeneral);
            
            if (ncErrorCn == '60001057' || ncErrorCn == '50001174') addErr(Label.TrainingBookingOgoneErrCardholder); 

            if (ncErrorCardNo == '30141001' || ncErrorCardNo == '50001069' || ncErrorCardNo == '50001176' || ncErrorCardNo == '50001177' || ncErrorCardNo == '50001178') 
                addErr(Label.TrainingBookingOgoneErrCardNo);

            if (ncErrorCvc == '50001090' || ncErrorCvc == '50001179' || ncErrorCvc == '50001180') addErr(Label.TrainingBookingOgoneErrCvc);
            if (ncErrorEd == '50001181' || ncErrorEd == '50001182' || ncErrorEd == '50001183' || ncErrorEd == '31061001') addErr(Label.TrainingBookingOgoneErrDate);
            */
            
            paramMode = '';
            return null;
        }
    
    }

    public String getDirectLinkShaIn()
    {
        String myValues = '';
        myValues += 'ACCEPTURL=' + pageUrl + '?MODE=3D' + DIRECTLINK_SHA_IN;    // 3-D secure param       
        myValues += 'ALIAS=' + alias + DIRECTLINK_SHA_IN;
        myValues += 'AMOUNT=' + String.valueOf(Integer.valueOf((objBooking.Total_Price__c * 100))) + DIRECTLINK_SHA_IN; 
        myValues += 'CURRENCY=' + objBooking.CurrencyIsoCode + DIRECTLINK_SHA_IN;
        myValues += 'DECLINEURL=' + pageUrl + '?MODE=3D' + DIRECTLINK_SHA_IN;      // 3-D secure param       
        myValues += 'ECI=' + '7' + DIRECTLINK_SHA_IN;           // possible values: 0: swiped/1:manual keyed/2:recurring/3:installments/4:manual with card/7:ecomerce
        // 3-D secure parameters 
        //myValues += 'DECLINEURL=' + pageUrl + '?MODE=3D' + DIRECTLINK_SHA_IN;
        myValues += 'EXCEPTIONURL=' + pageUrl + '?MODE=3D' + DIRECTLINK_SHA_IN;
        myValues += 'FLAG3D=Y' + DIRECTLINK_SHA_IN;
        myValues += 'HTTP_ACCEPT=' + ApexPages.currentPage().getHeaders().get('Accept') + DIRECTLINK_SHA_IN;
        myValues += 'HTTP_USER_AGENT=' + ApexPages.currentPage().getHeaders().get('User-Agent') + DIRECTLINK_SHA_IN;
        // 3-D parameters - end
        myValues += 'LANGUAGE=' + pageLanguage + DIRECTLINK_SHA_IN;
        myValues += 'OPERATION=' + 'SAL' + DIRECTLINK_SHA_IN;
        myValues += 'ORDERID=' + objBooking.Name + DIRECTLINK_SHA_IN;
        //myValues += 'PARAMPLUS=CT=' + paramCountry + '&L=' + paramLanguage + '&ID=' + objBooking.Id + DIRECTLINK_SHA_IN;
        myValues += 'PSPID=' + PSPID + DIRECTLINK_SHA_IN;
        myValues += 'PSWD=' + PSWD + DIRECTLINK_SHA_IN;
        myValues += 'USERID=' + USERID + DIRECTLINK_SHA_IN;
        myValues += 'WIN3DS=MAINW' + DIRECTLINK_SHA_IN;     // 3-D secure param
        system.debug(logginglevel.ERROR, 'Hashstring::' + myValues);
        system.debug(logginglevel.ERROR, 'SHA Directlink::' + EncodingUtil.convertToHex(Crypto.generateDigest(SHAEncoding, Blob.valueOf(myValues))).toUpperCase() );
        return EncodingUtil.convertToHex(Crypto.generateDigest(SHAEncoding, Blob.valueOf(myValues))).toUpperCase();
    }

    // Return the confirmation page
    public PageReference successPage()
    {
        PageReference ref = Page.TrainingBooking6;
        ref.getParameters().put('ID', objBooking.Id);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true);
        return ref;
    }

    // Return the error page
    public PageReference errorPage()
    {
        //PageReference ref = Page.TrainingBooking7;
        PageReference ref = Page.TrainingbookingErrorVfp;
        ref.getParameters().put('ID', objBooking.Id);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true);
        return ref;
    }   
    // Add an error to the list
    private void addErr(String errMsg)
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
    }

    public Boolean isSHA_Valid(String SHAFromFlexCall, String ShaDirection)
    {
        // Method used to generally validate SHA (IN or OUT)
        String ncError1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERROR');
        String ncErrorCn1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERRORCN');
        String ncErrorCardNo1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERRORCARDNO');
        String ncErrorCvc1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERRORCVC');
        String ncErrorEd1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERRORED');
        String orderid1 = ApexPages.currentPage().getParameters().get('ALIAS.ORDERID');
        String status1  = ApexPages.currentPage().getParameters().get('ALIAS.STATUS');
        String cardholdername1 = ApexPages.currentPage().getParameters().get('CARD.CARDHOLDERNAME');

        String recvd = '';
        if (String.isNotBlank(alias)) recvd += 'ALIAS.ALIASID=' + alias + ShaDirection;
        if (String.isNotBlank(ncError1)) recvd += 'ALIAS.NCERROR=' + ncError1 + ShaDirection;
        if (String.isNotBlank(ncErrorCardNo1)) recvd += 'ALIAS.NCERRORCARDNO=' + ncErrorCardNo1 + ShaDirection;
        if (String.isNotBlank(ncErrorCn1)) recvd += 'ALIAS.NCERRORCN=' + ncErrorCn1 + ShaDirection;
        if (String.isNotBlank(ncErrorCvc1)) recvd += 'ALIAS.NCERRORCVC=' + ncErrorCvc1 + ShaDirection;
        if (String.isNotBlank(ncErrorEd1)) recvd += 'ALIAS.NCERRORED=' + ncErrorEd1 + ShaDirection;
        if (String.isNotBlank(orderid1)) recvd += 'ALIAS.ORDERID=' + orderid1 + ShaDirection;
        if (String.isNotBlank(status1)) recvd += 'ALIAS.STATUS=' + status1 + ShaDirection;
        if (String.isNotBlank(cardholdername1)) recvd += 'CARD.CARDHOLDERNAME=' + cardholdername1 + ShaDirection;
        System.debug(logginglevel.ERROR, 'SHAOUT-Hash string::' + recvd);
        system.debug(logginglevel.ERROR, 'shaSignRcvd::'  + SHAFromFlexCall);
        system.debug(logginglevel.ERROR, 'shaSignCalc::'  + EncodingUtil.convertToHex(Crypto.generateDigest(SHAEncoding, Blob.valueOf(recvd))).toUpperCase());

        if (SHAFromFlexCall != EncodingUtil.convertToHex(Crypto.generateDigest(SHAEncoding, Blob.valueOf(recvd))).toUpperCase())
        {
            addErr(Label.TrainingBookingOgoneErrGeneral);
            paramMode = '';
            //objBooking.Payment_Error_Message__c = 'SHA Signature mismatch'; 
            System.debug(logginglevel.ERROR, '##184## ' + SHAFromFlexCall + ' ' + EncodingUtil.convertToHex(Crypto.generateDigest(SHAEncoding, Blob.valueOf(recvd))).toUpperCase());
            return false;
        }
        else return true;
        
    }
    public Boolean getPaymentProcess()
    {
        System.debug(logginglevel.ERROR, 'response::' + response);
        System.debug(logginglevel.ERROR, 'paymentSucceeded::' + paymentSucceeded);
        return paymentSucceeded;
        //response= '<b>TEST RESPONSE</b>';
    }
    // check transaction status for errors and update Booking if there is an error.
    public Boolean transactionHasErrors(Dom.XmlNode xmlRootElem)
    {
        // check for error transaction status.
        String trstatus = xmlRootElem.getAttributeValue('STATUS', null);
        // if status has an error but errinfo is not attached, then use general error
        String errinfo = xmlRootElem.getAttributeValue('NCERRORPLUS', null)==null ? 
            Label.TrainingBookingErrorTitle : xmlRootElem.getAttributeValue('NCERRORPLUS', null);

        System.debug(logginglevel.ERROR, 'ncerrorplus::' + xmlRootElem.getAttributeValue('NCERRORPLUS', null));
        
        Boolean hasError = false;
        if(integer.valueOf(trstatus) != 9)
        {
            switch on trstatus 
            {
                when '0'{ addErr(errinfo); hasError = true; }                               // invalid or incomplete - one of payment filed missing
                when '1'{ addErr(errinfo);  hasError = true; }                              // cancelled by customer
                when '2'{ addErr(Label.TrainingBookingRefusedCard); hasError = true; }      // refused by bank
                //when '46'{ addErr(errinfo);  hasError = true; }                             // waiting authentication
                when '92'{                                                                  // payment uncertain
                    errinfo = 'payment uncertain'; 
                    addErr(Label.TrainingBookingUncertainPayment); 
                    hasError = true; 
                }                              
                when '93'{ addErr(errinfo);  hasError = true; }                             // payment refused
            }
            
            if(hasError)
            {
                objBooking.Payment_Error_Message__c = errinfo; 
                objBooking.Payment_Status__c = 'Card Error';
                update objBooking;
                paymentSucceeded = false;
            }
        }
        return hasError;
    }
    private void update3DBooking()
    {
        // unbundle 3D response parameters
        String orderno = params.get('orderID');
        String status = params.get('STATUS');
        String ncError = params.get('NCERROR');
        String payid = params.get('PAYID');
        if(ncError == '0')
        {
            // 3D successful-update booking
            objBooking = TrainingBookingUtilities.bookingDetailsByName(orderno);
            objBooking.Payment_Status__c = 'Paid Online';
            objBooking.Payment_Order_No__c = payid;
            objBooking.Convert_To_On_Hold__c = false;
            update objBooking; 

            //  --- set cookie to be check in the OgoneIframe page ---
            Cookie pmtStatus = ApexPages.currentPage().getCookies().get('pmtstatus');
            pmtStatus = new Cookie('pmtstatus', 'true', null, -1, true, 'None' );
            System.debug(logginglevel.ERROR, 'Cookie::' + pmtStatus);
            ApexPages.currentPage().setCookies(new Cookie[]{pmtstatus});
            //  --- set cookie end ---
            // Asynchronous call to SAP
            TrainingBookingUtilities.sapOrder(objBooking.Id);
            paymentSucceeded = true;
        }        

    }
}