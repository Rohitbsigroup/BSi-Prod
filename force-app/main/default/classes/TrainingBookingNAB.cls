public class TrainingBookingNAB
{
    // Parameters (transient except those used by 'invoice instead' link)
    public transient Map<String, String> params { get; set; }
    public String paramLanguage { get; set; }
    public String paramCountry { get; set; }
    public String paramId { get; set; }
    
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

    // NAB values not used in page
    //static final String EPS_PASSWORD = 'sEj8yltT'; // Test
    //static final String EPS_PASSWORD = 'wVi5IAbm'; // Live
    static final SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
    static final String EPS_PASSWORD = ss.NAB_EPS_Password__c;
    
      // NAB values used in page
      public String EPS_RESULTURL { get {return URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingNAB';} }
      //public String PAYMENT_URL { get {return 'https://transact.nab.com.au/test/directpostv2/authorise';} } // Old Test URL 
      //public String PAYMENT_URL { get {return 'https://demo.transact.nab.com.au/directpostv2/authorise';} } // Updated Test URL from NAB
      //public String PAYMENT_URL { get {return 'https://transact.nab.com.au/live/directpostv2/authorise';} } // Live
      //public String EPS_MERCHANT { get {return 'B640010';} }
      public String PAYMENT_URL { get {return ss.NAB_Payment_URL__c;} }
      public String EPS_MERCHANT { get {return ss.NAB_EPS_Merchant__c;} }
      public transient String EPS_TXNTYPE { get; set; }
      public transient String THREED_XID { get; set; }
      //public String EPS_MERCHANTNUM { get {return '21761549';} }
      public String EPS_MERCHANTNUM { get {return ss.NAB_EPS_Merchant_Number__c;} }
      public transient String EPS_REFERENCEID { get; set; }
      public transient String EPS_AMOUNT { get; set; }
      public transient String EPS_CURRENCY { get; set; }
      public transient String EPS_TIMESTAMP { get; set; }
      public transient String EPS_FINGERPRINT { get; set; }
    
    // Controller constructor
    public TrainingBookingNAB()
    {
        // Set defaults
        this.pageIsValid = true;
        this.pageLanguage = 'en_US';
        this.pageStep = 5;
        this.pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingNAB';
        
        // Unbundle the page parameters
        this.params = ApexPages.currentPage().getParameters();
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
        
        // Turn off 3D secure for internal use
        this.EPS_TXNTYPE = (!String.isBlank(this.objBooking.Source_BSI_Staff__c) && this.objBooking.Source_BSI_Staff__c.startsWith('SBK ')) ? '0' : '4'; // Use 3D Secure? '0' = No, '4' = Yes
        System.debug('##this.EPS_TXNTYPE##'+this.EPS_TXNTYPE);
    }

    // Redirect to error page if initialization has failed
    public PageReference initCheck()
    {
        // Deal with errors
        if (!this.pageIsValid) return errorPage();

        // Check for fingerprint (indicates postback)
        if (String.isNotBlank(params.get('fingerprint')))
        {   
             System.debug('in finger print code');
             
        // The page is a postback from NAB
          this.EPS_REFERENCEID = this.objBooking.Name;
          this.EPS_AMOUNT = String.valueOf(this.objBooking.Total_Price__c);
          String timestamp = params.get('timestamp');
          String fingerprint = params.get('fingerprint');
            System.debug('##fingerprint##'+fingerprint);
          String summarycode = params.get('summarycode');
          String toCode = this.EPS_MERCHANT + '|' + EPS_PASSWORD + '|' + this.EPS_REFERENCEID + '|' + this.EPS_AMOUNT + '|' + timestamp + '|' + summarycode;
            System.debug('##encrypted toCode##' + EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(toCode))));
          if (fingerprint != EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(toCode)))) return errorPage();
            System.debug('in payment code');
            System.debug('##summarycode##'+summarycode);
            
            // Was the payment successful?
            
            
            // Vim code starts - 14 June 2017 Vim added code as suggested by Tom - (from NAB???) as a workaround to allow card payment when payment taken over phone by BSI Staff member. This is known issue to NAB and they are trying to fix it. 
            // This code can be removed when NAB provide the solution to card payments done without 3D secure check 
            // response code will always return as 00 or 08 for successful payments.
             
            String respcode = params.get('rescode');       // workaround code (can be kept in future)
            System.debug('###respcode###' + respcode);     // workaround code (can be kept in future)
            
            if (summarycode == '1' || (respcode == '00' || respcode == '08')) // workaround code (can be kept in future) Vim code ends here //if (summarycode == '1') - original code - this line should rreplace above when you get NAB fix  
              {
                System.debug('payment successful');
                // Yes it was
                TrainingBooking__c booking = new TrainingBooking__c(Id = this.objBooking.Id);
                booking.Payment_Card__c = '';
                booking.Payment_Name__c = '';
                booking.Payment_Status__c = 'Paid Online';
                booking.Payment_Order_No__c = this.params.get('txnid');
                booking.Convert_To_On_Hold__c = false;
                update booking;

                // Asynchronous call to SAP
                TrainingBookingUtilities.sapOrder(this.objBooking.Id);

                // Redirect to confirmation page
                return successPage();
            }
            else
            {
                // Failure (display error and stay in page)
                String rescode = params.get('rescode');
                if (rescode == '14' || rescode == '101' || rescode == '102' || rescode == '131' || rescode == '132')
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingNabErrDetails));
                }
                else if (rescode == '106')
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingNabErrType));
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingNabErrGeneral));
                }
            }
        }

        // Otherwise, generate timestamp
        this.EPS_REFERENCEID = this.objBooking.Name;
        this.EPS_AMOUNT = String.valueOf(this.objBooking.Total_Price__c);
        this.EPS_CURRENCY = String.valueOf(this.objBooking.CurrencyIsoCode);
        this.EPS_TIMESTAMP = DateTime.now().format('yyyyMMddHHmmss', 'GMT');
        String toCode = this.EPS_MERCHANT + '|' + EPS_PASSWORD + '|' + this.EPS_TXNTYPE + '|' + this.EPS_REFERENCEID + '|' + this.EPS_AMOUNT + '|' + this.EPS_TIMESTAMP;
            System.debug('##this.EPS_TXNTYPE##' + this.EPS_TXNTYPE );
        this.EPS_FINGERPRINT = EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(toCode)));
            System.debug('##this.EPS_FINGERPRINT##' + this.EPS_FINGERPRINT );
        this.THREED_XID = this.objBooking.Name.right(6) + this.EPS_TIMESTAMP;
    
        return null;
    }
    
    public String[] getMonths()
    {
        // Build list of twelve months
        return new String[] { '', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12' };
    }
    
    public String[] getYears()
    {
        //  Build list of the next ten years
        String[] result = new String[11];
        result[0] = '';
        Integer year = Date.today().year();
        for (Integer i = 0; i < 10; i++) result[i + 1] = String.valueOf(year + i);
        return result;
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