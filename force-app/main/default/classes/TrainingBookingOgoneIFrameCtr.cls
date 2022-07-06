/*
    Created by: Mahmood (Cognizant)
    Created date: 30-01-2020
    Description: Controller to implement flexcheckout menthod of ingenico for PCI DCC compliance
    Change log
    Changed by              Changed date        Description
*/
public without sharing class TrainingBookingOgoneIFrameCtr
{
    // Parameters (transient except those used by 'invoice instead' link)
    public transient Map<String, String> params { get; set; }
    public transient String paramMode { get; set; }
    public String paramLanguage { get; set; }
    public String paramCountry { get; set; }
    public String paramId { get; set; }
    public String awc { get; set; }
    // Ogone constants (used by page)
    public transient String PSPID { get; set; }
    public transient String flexCheckout_URL { get;set; }
    
    static String ALIASGATEWAY_SHA_IN = '';
    static String ALIASGATEWAY_SHA_OUT = '';
    
    static final String ENCODING = 'UTF-8';
    //static final String SHAEncoding = 'SHA512';
    String SHAEncoding;

    // Page settings
    public transient String pageUrl { get; set; }
    public transient Boolean pageIsValid { get; set; }
    public transient Boolean isUncertain { get; set; }
    public transient String pageLanguage { get; set; }
    public transient Integer pageStep { get; set; }
    public transient Boolean pageShowSelection { get; set; }

    // Retrieved information (transient except those used by 'invoice instead' link)
    public transient String courseName { get; set; }
    public transient Boolean courseAccommodation { get; set; }
    public transient TrainingBooking__c objBooking { get; set; }
    public TrainingBookingUtilities.Country selectedCountry { get; set; }
    public transient TrainingBookingUtilities.EventWrapper selectedEvent { get; set; }
    public Boolean isPaymentSuccessful{ get;set; }
        
    // Default constructor
    public TrainingBookingOgoneIFrameCtr(){
        // Ogone variables (not used by page)
        String USERID;
        String PSWD;
        String DIRECTLINK_SHA_IN;

        // Set defaults
        pageIsValid = true;
        pageLanguage = 'en_US';
        pageStep = 5;
        pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingOgoneIFrame';
        // deleting cookie - if it existed
        Cookie pmtStatus = new Cookie('pmtstatus', '', null, 0, true );
        ApexPages.currentPage().setCookies(new Cookie[]{pmtstatus});
        System.debug(logginglevel.ERROR, 'default - cookie::' + ApexPages.currentPage().getCookies().get('pmtstatus'));

        // Unbundle the page parameters
        params = ApexPages.currentPage().getParameters();
        paramMode = params.get('MODE');
        paramLanguage = params.get('L');
        paramCountry = params.get('CT');
        paramId = params.get('ID');
        awc = params.get('awc');

        // Get the configuration
        TrainingBookingUtilities.Configuration config = new TrainingBookingUtilities.Configuration();

        // Validate the language parameter
        if (paramLanguage == null || !config.supportedLanguages.containsKey(paramLanguage.toUpperCase()))
        {
            // Language cannot be identified - Return invalid page
            pageIsValid = false;
            return;
        }

        // Set the SFDC page language
        pageLanguage = config.supportedLanguages.get(paramLanguage.toUpperCase());

        // Validate the country parameter
        if (paramCountry == null || !config.supportedCountries.containsKey(paramCountry.toUpperCase()))
        {
            // Country cannot be identified - Return invalid page
            pageIsValid = false;
            return;
        }

        // Get the country-specific settings
        selectedCountry = new TrainingBookingUtilities.Country(config.supportedCountries.get(paramCountry.toUpperCase()), paramLanguage.toUpperCase(), '');

        // Validate the id parameter
        if (String.isBlank(paramId))
        {
            // Booking cannot be identified - Return invalid page
            pageIsValid = false;
            return;
        }
        // Populate from an existing Booking Event
        objBooking = TrainingBookingUtilities.bookingDetails(paramId);
        if(objBooking == null)            
        {
            // Booking cannot be identified - Return invalid page
            pageIsValid = false;
            return;
        }

        System.debug(logginglevel.ERROR, 'Booking name::' + objBooking.Name);
        // Re-populate the Course/Event details
        courseAccommodation = objBooking.Is_Residential__c;
        if (courseAccommodation)
        {
            selectedEvent = new TrainingBookingUtilities.EventWrapper(objBooking.Training_Event__c, objBooking.Pricebook_Inc_Accommodation__c, objBooking.Pricebook_Exc_Accommodation__c, objBooking.CurrencyIsoCode, objBooking.Price_Inc_Accommodation__c, objBooking.Price_Exc_Accommodation__c);
        }
        else
        {
            selectedEvent = new TrainingBookingUtilities.EventWrapper(objBooking.Training_Event__c, objBooking.Pricebook_Entry__c, null, objBooking.CurrencyIsoCode, objBooking.Price_Per_Delegate__c, null);
        }
        courseName = selectedEvent.event.Course__r.Product_Name_Local__c;
        System.debug(logginglevel.ERROR, 'selectedEvent::' + selectedEvent);
            
        // Re-populate the page settings
        pageShowSelection = !(selectedEvent.event.Course__r.Delivery_Method__c == 'Distance Learning' || selectedEvent.event.Course__r.Delivery_Method__c == 'eLearning');

        // Check whether already paid
        if (String.isNotBlank(objBooking.Payment_Order_No__c))
        {
            // There is already a payment ref - Return invalid page
            addErr(Label.TrainingBookingExistingOrder + objBooking.Payment_Order_No__c);
            isUncertain = true;     // hide the iframe
            return;
        }
        // Check whether already paid
        if (objBooking.Payment_Error_Message__c == 'payment uncertain' )
        {
            // payment is uncertain - can't continue - pay by invoice
            addErr(Label.TrainingBookingUncertainPayment);
            isUncertain = true;
            return;
        }
        // general 'System Setting' Custom Settings
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        flexCheckout_URL = ss.Ingenico_FlexCheckout_URL__c;
        SHAEncoding = ss.SHAEncoding__c;
        // Set the gateway parameters according to the country
        Ingenico_Ogone_Settings__c ios;
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

        flexCheckout_URL = getFlexCheckoutSHAIn(flexCheckout_URL);
        system.debug(logginglevel.ERROR, 'flexCheckout_URL::' + flexCheckout_URL);
    }
    
    // Add an error to the list
    private void addErr(String errMsg)
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
    }

    // Generate the SHA signature for Flex Checkout
    public String getFlexCheckoutSHAIn(String flexCheckoutURL)
    {
            // flex check out parameters

        String hash = '';
        hash += 'ACCOUNT.PSPID=' + PSPID + ALIASGATEWAY_SHA_IN; 
        //hash += 'ALIAS.ALIASID=' + 
        hash += 'ALIAS.ORDERID=' + objBooking.Name + ALIASGATEWAY_SHA_IN; 
        //hash += 'ALIAS.STOREPERMANENTLY=' + 
        //hash += 'CARD.BIC=' + 
        //hash += 'CARD.BIN=' + 
        //hash += 'CARD.BRAND=' + 
        hash += 'CARD.PAYMENTMETHOD=' + 'CreditCard' + ALIASGATEWAY_SHA_IN; 
        hash += 'LAYOUT.LANGUAGE=' + paramLanguage + ALIASGATEWAY_SHA_IN; 
        //hash += 'LAYOUT.TEMPLATENAME=' + 
        hash += 'PARAMETERS.ACCEPTURL=' + URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingFlexCheckoutSuccessVfp' + ALIASGATEWAY_SHA_IN; 
        hash += 'PARAMETERS.EXCEPTIONURL=' + URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingErrorVfp' + ALIASGATEWAY_SHA_IN; 
        //hash += 'PARAMETERS.EXCLUDED=' + 
        //hash += 'PAYMENTMETHODS=' + 
        
        String flexParams = hash.replace(ALIASGATEWAY_SHA_IN, '&').removeEnd( '&' );
        String paramplus = 'PARAMETERS.PARAMPLUS=CT=' + paramCountry + '_L=' + paramLanguage + '_ID=' + objBooking.Id;
        hash += paramplus + ALIASGATEWAY_SHA_IN;  
        
        system.debug(logginglevel.ERROR, 'hashString::' + hash);
        system.debug(logginglevel.ERROR, 'shaencoding::' + SHAEncoding);
        
        flexParams += '&' + paramplus;  
        flexParams += '&SHASIGNATURE.SHASIGN=' + EncodingUtil.convertToHex(Crypto.generateDigest(SHAEncoding, Blob.valueOf(hash))).toUpperCase();
        system.debug(logginglevel.ERROR, 'hashString::' + hash);
        system.debug(logginglevel.ERROR, 'flexCkParams::' + flexParams);
        //myValues += 'PARAMPLUS=CT=' + paramCountry + '&L=' + paramLanguage + '&ID=' + objBooking.Id + ALIASGATEWAY_SHA_IN;     
        system.debug(logginglevel.ERROR, 'flexcheckouturl::'+flexCheckoutURL + '?' + flexParams);
        return flexCheckoutURL + '?' + flexParams;
        
    }

    // Execute option to invoice instead
    public PageReference invoiceInstead()
    {
        system.debug(logginglevel.ERROR, 'paramId:: ' + paramId );
        TrainingBooking__c booking = TrainingBookingUtilities.bookingDetails(paramId);
        // TrainingBooking__c booking = New TrainingBooking(Id = paramId);
        // check if the payment has been made for the order
        if(String.isNotBlank(booking.Payment_Order_No__c) )
        {
            addErr(Label.TrainingBookingExistingOrder + booking.Payment_Order_No__c);
            return null;
        }
        // Modify the booking record
        booking.Payment_Method__c = 'Invoice';
        booking.Payment_Status__c = 'Invoice';
        update booking;
        // Redirect to confirmation page
        return successPageInvoiced();
    }

    // Return the confirmation page
    public PageReference successPage()
    {
        PageReference ref;
        // check cookie
        Cookie pmtStatus = ApexPages.currentPage().getCookies().get('pmtstatus');
        System.debug(logginglevel.ERROR, 'pmtstatus-cookie::' + pmtstatus);
        // check the cookie state
        isPaymentSuccessful = (pmtStatus!=null)&&(pmtstatus.getValue()=='true')? true:false;
        // check if the payment is successful
        if(isPaymentSuccessful)
        {
            // redirect
            ref = Page.TrainingBooking6;
            ref.getParameters().put('ID', paramId);
            ref.getParameters().put('CT', paramCountry);
            ref.getParameters().put('L', paramLanguage);
            ref.setRedirect(true);

            TrainingBooking__c booking = TrainingBookingUtilities.bookingDetails(paramId);

            AwinTrackingHandler.sendRequest(
                (booking.Net_Price__c - booking.Discount__c),
                booking.Promotional_Code__c,
                booking.CurrencyIsoCode,
                booking.Id,
                awc
            );
        }
        return ref;
    }
    // method to handle Invoice payment action
    public PageReference successPageInvoiced()
    {
        PageReference ref;
        // redirect
        ref = Page.TrainingBooking6;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true);
            
        return ref;
    }

    // Return the error page
    public PageReference errorPage()
    {
        PageReference ref = Page.TrainingBooking7;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        //ref.getParameters().put('returl', ApexPages.currentPage().getUrl());
        ref.setRedirect(true);
        return ref;
    }   
    public PageReference validatePage()
    {
        // this will check for page errors
        System.debug('Pageisvalid::' + pageIsValid);
        if(!pageIsValid) return errorPage();
        return null;        
    }
}