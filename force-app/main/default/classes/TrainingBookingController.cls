/*
  19/11/2014 NF: Changed Delivery_Method__c to TrainingDeliveryMethod__c (Only in SOQL so far)
  22/02/2016 CP: forwardToStep4() changed to check there is enough accommodation on the event for the booking
                 calculatePrice() changed to use TrainingBookingUtilities.calculateBookingPrices() and
                 TrainingBookingUtilities.SapOrderSend()
  27/05/2016     JS: Added section for Italy VAT/Codice Fiscale Requirements after VIES check
  23/02/2017 VA: added code to make NIP field mandatory and allow 3 attempt to validate the VAT Number. By pass the number if not validated in 3 attepmts
  16/03/2018 JS: "Un-commented" out redirect to NAB page
  27/03/2018 MD COPIED UPDATES FROM DEV3 (28/07/2017 ADS - SoW034 - Online Exam Enhancements)
  17/05/2018 MD Modified for Project 0070 GDPR Implementation
  04/03/2019 MD Modified to parameterise number of Events and Event time period shown by default
  30/07/2020 PC K2 added support for SFDC tax calculation
  09/11/2020 JS Minor updates
  29/04/2021 EN Added check on Skip Ip check field from Training_Booking_Country_Settings__mdt
  27/07/2021 EN Set list phone country codes
  xx/11/2021 CS Added AWIN information
  21/12/2021 JS fix for South Africa to remove VAT being Required  946-952
 */

public class TrainingBookingController
{
    // GLOBAL DECLARATIONS ================================================================================================================

    // Parameters and retrieved data
    public String paramLanguage { get; set; }
    public String paramCountry { get; set; }
    public String awc { get; set; }
    public TrainingBookingUtilities.Country selectedCountry { get; set; }
    private String selectedTaxonomy { get; set; }
    private Map<Id, PriceBookEntry> prices { get; set; }
    public List<TrainingBookingUtilities.EventWrapper> events { get; set; }
    public Boolean pageAllowMore { get; set; }
    private Boolean pageAllowMoreClicked;

    public Id eventId { get; set; }

    // Retrieved information
    public String courseName { get; set; }
    public String coursePmtOpts { get; set; }
    public Boolean courseAccommodation { get; set; }
    public Boolean courseOnlineExam { get; set; }
    public List<SelectOption> phoneCountryCodeOptions { get; set; }
    public Map<String, String> phoneCountryCodeByCountrySettingsName { get; set; }
    public Map<String, String> countryCodesByCountryName { get; set; }
    public String ipCountryCode { get; set; }

    // Page settings
    private transient PageReference pageRedirect { get; set; }
    public Boolean pageIsValid { get; set; }
    public String pageLanguage { get; set; }
    public Integer pageStep { get; set; }
    public Integer pageRowLimit { get; set; }
    public Boolean pageAllowCard { get; set; }
    public Boolean pageAllowInvoice { get; set; }
    public Boolean pageShowSelection { get; set; }
    // Working objects
    public TrainingBooking__c objBooking { get; set; }
    public List<TrainingDelegate__c> objDelegates { get; set; }
    //private PricebookEntry accommPBE {get; set;}

    // User inputs
    public String selectedLocation { get; set; }
    public Id selectedEventId { get; set; }
    public TrainingBookingUtilities.EventWrapper selectedEvent { get; set; }
    public Integer selectedDelegates { get; set; }
    public Boolean promoError { get; set; }
    private Boolean promoOnline { get; set; }

   // Vim 17 Oct 2016 - Additional tracking data variables for Marketing
    public String bookingName { get; set; }
    public Decimal pricePerDelegateExtraNight { get; set; }
    public Decimal pricePerDelegateAccomodation { get; set; }
    public String extraNightProductId { get; set; }
    public String accomodationProductId { get; set; }
    // Vim code ends here

    // config flags
    public Boolean isIncludeExam { get; set; }

    // 23 Feb 2017 Vim added variable to check Poland VAT attempts.
    Public Integer polandVATAttempt = 0;
    Public Integer polandVATAttempted = 3;
    // Vim code ends here

    // JE 17/01/2021 - Asperato payment record used for APAC to generate payment gateway iframe URL
    public asp04__Payment__c asperatoPayment;

    // JE 28/01/2021 - portal user login variables
    public User portalUser { get; set; }
    public Boolean isAuthenticated { get; set; }
    public String username { get; set; }
    public transient String password { get; set; }
    public String resetPasswordURL { get; set; }

    // Controller constructor - Operates in three modes:
    // 1. Entry at Step 1 - Displays list of events
    // 2. Entry at Step 2 - Skips event selection for distance learning
    // 3. Entry after confirmation with Id set - Rebuilds session supplied from Training Booking id
    public TrainingBookingController()
    {
        // Set defaults
        this.pageIsValid = true;
        this.PageRedirect = null;
        this.pageLanguage = 'en_US';
        this.pageAllowMoreClicked = false;

        // Unbundle QueryString parameters
        this.paramLanguage = ApexPages.currentPage().getParameters().get('L');
        this.paramCountry = ApexPages.currentPage().getParameters().get('CT');
        this.awc = ApexPages.currentPage().getParameters().get('awc');
        String paramTaxonomy = ApexPages.currentPage().getParameters().get('C');
        String paramId = ApexPages.currentPage().getParameters().get('ID');
        String paramPricebook = ApexPages.currentPage().getParameters().get('PB'); // Used for testing only
        String paramCard = ApexPages.currentPage().getParameters().get('CARD'); // Used for testing only
        String isoCode = ApexPages.currentPage().getParameters().get('ISOCode'); // Used for testing only
        system.debug(logginglevel.ERROR, '### ApexPages.currentPage().getParameters() : ' +  ApexPages.currentPage().getParameters());

        // Get the configuration
        TrainingBookingUtilities.Configuration config = new TrainingBookingUtilities.Configuration();

        System.debug(logginglevel.ERROR, 'Page.TrainingBooking7 -->' +  Page.TrainingBooking7);
        // MB-04-03-2020 - check if current page is errorpage then dont show steps
        Boolean errorpage = false;
        if(!Test.isRunningTest() && ApexPages.currentPage().getUrl().contains('trainingbooking7')) errorpage = true;
        if(errorpage){
            pageShowSelection = false;
        }

        // Validate the language parameter
        if (this.paramLanguage == null || !config.supportedLanguages.containsKey(this.paramLanguage.toUpperCase()))
        {
          system.debug(logginglevel.ERROR, '$$$$$ Language cannot be identified: ' + paramLanguage);
            // Language cannot be identified - Return invalid page
            this.pageIsValid = false;
            return;
        }

        // Set the SFDC page language
        this.pageLanguage = config.supportedLanguages.get(this.paramLanguage.toUpperCase());

        // Validate the country parameter
        if (this.paramCountry == null || !config.supportedCountries.containsKey(this.paramCountry.toUpperCase()))
        {
          system.debug(logginglevel.ERROR, '$$$$$ Country cannot be identified: ' + paramCountry);
            // Country cannot be identified - Return invalid page
            this.pageIsValid = false;
            return;
        }

        // Get the country-specific settings
        this.selectedCountry = new TrainingBookingUtilities.Country(config.supportedCountries.get(this.paramCountry.toUpperCase()), this.paramLanguage.toUpperCase(), '');
        this.isIncludeExam = this.selectedCountry.Flags.contains('IncludeExam');
        system.debug(logginglevel.ERROR, '### isIncludeExam: ' + isIncludeExam);

        // JE 25/01/2021 - set map of phone country codes
        this.phoneCountryCodeByCountrySettingsName = new Map<String, String>();
        List<Training_Booking_Country_Settings__mdt> countrySettings = [SELECT Id, DeveloperName, Country_Code_Picklist__c FROM Training_Booking_Country_Settings__mdt WHERE Country_Code_Picklist__c != null];
        for(Training_Booking_Country_Settings__mdt countrySetting: countrySettings) {
            this.phoneCountryCodeByCountrySettingsName.put(countrySetting.DeveloperName, countrySetting.Country_Code_Picklist__c);
        }

        // EN 27/07/2021 - set list phone country codes
        this.phoneCountryCodeOptions = new List<SelectOption>();
        for (Schema.PicklistEntry pickListVal: Training_Booking_Country_Settings__mdt.Country_Code_Picklist__c.getDescribe().getPicklistValues()){
            this.phoneCountryCodeOptions.add(new SelectOption(pickListVal.getLabel(), pickListVal.getValue()));
        }
        this.phoneCountryCodeOptions.sort();

        this.countryCodesByCountryName = new Map<String, String>();
        List<Country_Code__mdt> countryCodes = [SELECT Id, Country_Name__c, ISO_Alpha_2_Country_Code__c FROM Country_Code__mdt WHERE Country_Name__c != null AND ISO_Alpha_2_Country_Code__c != null];
        for(Country_Code__mdt countryCode: countryCodes) {
            countryCodesByCountryName.put(countryCode.Country_Name__c, countryCode.ISO_Alpha_2_Country_Code__c);
        }

        this.resetPasswordURL = Label.TrainingBookingResetPasswordLink + '?language=' + this.pageLanguage;


        // Initialize the output objects
        this.objBooking = new TrainingBooking__c();
        this.objBooking.Booking_Route__c = 'Online';
        this.objBooking.Booking_Country__c = this.paramCountry.toUpperCase();
        this.objBooking.Booking_Language__c = this.paramLanguage.toUpperCase();
        this.objBooking.Company_Country__c = this.selectedCountry.countryOptionsDefault;
        this.objBooking.Phone_Country_Code__c = this.selectedCountry.countryCode;
        this.objBooking.Mobile_Country_Code__c = this.selectedCountry.countryCode;
        if(this.selectedCountry.countryOptionsMap.containsKey(this.selectedCountry.countryOptionsDefault))
        {
            TrainingBookingUtilities.CountryOption countryOption = this.selectedCountry.countryOptionsMap.get(this.selectedCountry.countryOptionsDefault);
            if(null!=countryOption)
            {
                this.objBooking.Country_ISO_Code__c = countryOption.sapCode;
            }
        }
        this.objBooking.Billing_Country__c = this.selectedCountry.countryOptionsDefault;
        this.objBooking.Language_For_Invoice__c = this.selectedCountry.invoiceOptionsDefault;
        this.objDelegates = new List<TrainingDelegate__c>();

        // Mode 3 (see description above)
        if (String.isNotBlank(paramId))
        {
            // Re-populate the Training Booking
            this.objBooking = TrainingBookingUtilities.bookingDetails(paramId);
            if(objBooking == null)
            {
                // Booking cannot be identified - Return invalid page
                pageIsValid = false;
                return;
            }
            else if(String.isNotBlank(objBooking.Payment_Order_No__c) && errorpage)
            {
                // Booking order already processed - Return invalid page
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingExistingOrder + objBooking.Payment_Order_No__c));
                pageIsValid = false;
                return;
            }
            // Re-populate the Training Delegates
            this.objDelegates = TrainingBookingUtilities.delegateDetails(paramId);

            // Re-populate the Course/Event details
            this.courseAccommodation = this.objBooking.Is_Residential__c;
            if (this.courseAccommodation)
            {
                //this.selectedEvent = new TrainingBookingUtilities.EventWrapper(this.objBooking.Training_Event__c, this.objBooking.Pricebook_Inc_Accommodation__c, this.objBooking.Pricebook_Exc_Accommodation__c, this.objBooking.CurrencyIsoCode, this.objBooking.Price_Inc_Accommodation__c, this.objBooking.Price_Exc_Accommodation__c);
                this.selectedEvent = new TrainingBookingUtilities.EventWrapper(this.objBooking);
            }
            else
            {
                //this.selectedEvent = new TrainingBookingUtilities.EventWrapper(this.objBooking.Training_Event__c, this.objBooking.Pricebook_Entry__c, null, this.objBooking.CurrencyIsoCode, this.objBooking.Price_Per_Delegate__c, null);
                this.selectedEvent = new TrainingBookingUtilities.EventWrapper(this.objBooking);
            }
            this.courseName = this.selectedEvent.event.Course__r.Product_Name_Local__c;
            this.coursePmtOpts = this.selectedEvent.event.Course__r.Payment_Options__c;
            this.courseOnlineExam = null != this.selectedEvent.event.Course__r.Online_Exam__c;

            // Re-populate the page settings
            this.pageStep = 6;
            if(!errorpage) this.pageShowSelection = !(this.selectedEvent.event.Course__r.Course_Format__c == 'Distance Learning' || this.selectedEvent.event.Course__r.Course_Format__c == 'E-Learning');
            return;
        }

        // Validate the taxonomy code
        if (paramTaxonomy == null)
        {
          system.debug(logginglevel.ERROR, '$$$$$ Taxonomy is null');
            // Taxonomy cannot be identified - Return invalid page
            this.pageIsValid = false;
            return;
        }

        // If a pricebook was specified, use it (used by test class)
        if (String.isNotBlank(paramPricebook)) this.selectedCountry.pricebookId = paramPricebook;

        // If card payments were specified, allow them (used by test class)
        if (String.isNotBlank(paramCard)) this.objBooking.Payment_Method__c = 'Card';

        // (used by test class)
        if (String.isNotBlank(isoCode)) this.selectedCountry.currencyIsoCode = isoCode;

        // Get the course details
        this.selectedTaxonomy = paramTaxonomy.toUpperCase();
        system.debug(logginglevel.ERROR, '$$$$$ Getting courses (PBEs)');
        retrieveCourse();
        system.debug(logginglevel.ERROR, '$$$$$ Got courses (PBEs)');
        system.debug(logginglevel.ERROR, '$$$$$ this.prices : '+this.prices);
        if (this.prices.isEmpty())
        {
          system.debug(logginglevel.ERROR, '$$$$$ Prices is empty');
            // Course not found - Redirect to enquiry page
            this.pageRedirect = new PageReference(this.selectedCountry.enquiryUrl);
            return;
        }

        // Retrieve events
        this.pageRowLimit = this.selectedCountry.showEventRows;
        this.courseName = this.prices.values()[0].Product2.Product_Name_Local__c;
        this.coursePmtOpts = this.prices.values()[0].Product2.Payment_Options__c;
        this.courseAccommodation = false;
        this.courseOnlineExam = null != this.prices.values()[0].Product2.Online_Exam__c;
        system.debug(logginglevel.ERROR, '$$$$$ Getting Events');
        retrieveEvents();
        system.debug(logginglevel.ERROR, '$$$$$ is Events list empty::' + this.events.isEmpty());
        if (this.events.isEmpty())
        {
          system.debug(logginglevel.ERROR, '$$$$$ No events');
            // No events found - Redirect to enquiry page
            this.pageRedirect = new PageReference(this.selectedCountry.enquiryUrl);
            return;
        }

        // Mode 2 (see description above)
        if (this.events[0].event.Course__r.Course_Format__c == 'Distance Learning' || this.events[0].event.Course__r.Course_Format__c == 'E-Learning')
        {
            this.resetPasswordURL = Label.TrainingBookingResetPasswordLink + '?language=' + this.pageLanguage;
            this.selectedEventId = this.events[0].event.Id;
            this.pageShowSelection = false;
            ForwardToStep2();
            if(!this.selectedCountry.isCheckIpSkipped && checkIP() == false) {
                // Return ip error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_IP));
            }
            return;
        }

        // Mode 1 (see description above)
        this.pageShowSelection = true;
        this.pageStep = 1;
    }

    // Redirect to error page if initialization has failed
    public PageReference initCheck()
    {
        system.debug('pageStep:: ' + pageStep);
        system.debug(logginglevel.ERROR, '### initCheck pageIsValid: ' + this.pageIsValid + ' -- Page redirect::' + pageRedirect);

        if (this.pageRedirect != null) return this.pageRedirect;
        //if (!this.pageIsValid) return Page.TrainingBooking7;
        return null;
    }


    // STEP 1 =============================================================================================================================

    // Retrieve products and pricebook entries for the supplied taxonomy code
    private void retrieveCourse()
    {
        // Create an empty Map
        this.prices = new Map<Id, PriceBookEntry>();

    set<Id> relatedProductIds = new set<Id>();

        // Step through query
        for (PricebookEntry entry : [
            SELECT  pbe.Id,
                    pbe.UnitPrice,
                    pbe.Product2Id,
                    pbe.Product2.Product_Name_Local__c,
                    pbe.Product2.Short_Name_For_Training_SMO__c,
                    pbe.Product2.Training_Event_Residential__c,
                    pbe.Product2.Payment_Options__c,
                    pbe.Product2.Base_Product__c,
                    pbe.Product2.Extra_Night__c,
                    pbe.Product2.Premium_Product__c,
                    pbe.Product2.Assembly_Material__c,
                    pbe.Product2.Online_Exam__c,
                    pbe.Product2.Online_Exam__r.Short_Name_For_Training_SMO__c,
                    pbe.Product2.Online_Exam__r.Assembly_Material__c,
                    pbe.Product2.Online_Standard__c,
                    pbe.Product2.Online_Standard__r.Short_Name_For_Training_SMO__c,
                    pbe.Product2.Online_Standard__r.Assembly_Material__c,
                    pbe.Product2.Revenue_Assignment__c
            FROM    PricebookEntry pbe
            WHERE   pbe.PriceBook2Id = :this.selectedCountry.PriceBookId
                    AND pbe.CurrencyIsoCode = :this.selectedCountry.CurrencyIsoCode
                    AND pbe.IsActive = true
                    AND pbe.Product2.Training_Taxonomy_Code__c = :this.selectedTaxonomy
                    AND pbe.Product2.IsActive = true
                    AND pbe.Product2.Enable_Online_Booking__c = true
                    AND pbe.Product2.Course_Delivery__c != 'In-House' // 16 May Vim added condition to exclude in-House events from booking form
            ])
        {
            // Add a record to the Map
            this.prices.put(entry.Product2Id, entry);

            if(entry.Product2.Base_Product__c != null)
            {
              relatedProductIds.add(entry.Product2.Base_Product__c);
            }
            if(entry.Product2.Extra_Night__c != null)
            {
                relatedProductIds.add(entry.Product2.Extra_Night__c);
            }
            if(entry.Product2.Premium_Product__c != null)
            {
                relatedProductIds.add(entry.Product2.Premium_Product__c);
            }
            if(entry.Product2.Online_Exam__c != null)
            {
                relatedProductIds.add(entry.Product2.Online_Exam__c);
            }
            if(entry.Product2.Online_Standard__c != null)
            {
                relatedProductIds.add(entry.Product2.Online_Standard__c);
            }
        }

        for (PricebookEntry pbe : [
            SELECT  pbe.Id,
                    pbe.UnitPrice,
                    pbe.Product2Id,
                    pbe.Pricebook2Id,
                    pbe.Product2.Training_Event_Residential__c,
                    pbe.Product2.Product_Name_Local__c,
                    pbe.Product2.Short_Name_For_Training_SMO__c,
                    pbe.Product2.Payment_Options__c,
                    pbe.Product2.Base_Product__c,
                    pbe.Product2.Extra_Night__c,
                    pbe.Product2.Premium_Product__c,
                    pbe.Product2.Assembly_Material__c,
                    pbe.Product2.Online_Exam__c,
                    pbe.Product2.Online_Exam__r.Short_Name_For_Training_SMO__c,
                    pbe.Product2.Online_Exam__r.Assembly_Material__c,
                    pbe.Product2.Online_Standard__c,
                    pbe.Product2.Online_Standard__r.Short_Name_For_Training_SMO__c,
                    pbe.Product2.Online_Standard__r.Assembly_Material__c,
                    pbe.Product2.Online_Standard__r.Revenue_Assignment__c
            FROM    PricebookEntry pbe
      WHERE pbe.PriceBook2Id = :this.selectedCountry.PriceBookId
              AND pbe.Product2Id IN :relatedProductIds
                    AND pbe.CurrencyIsoCode = :this.selectedCountry.CurrencyIsoCode
                    AND pbe.IsActive = true
                    AND pbe.Product2.IsActive = true
            ])
        {
            // Add a record to the Map
            this.prices.put(pbe.Product2Id, pbe);
        }
    }

    // Get a list of (abridged) events for the supplied course
    private void retrieveEvents()
    {
        // Create an empty List and reset Show More flag
        this.events = new List<TrainingBookingUtilities.EventWrapper>();
        this.pageAllowMore = false;

        /* 20/11/2014 NF: Get standard Accommodation PBE for this pricebook */
/*
      try
      {
      accommPBE = [SELECT Id, Pricebook2Id, UnitPrice, Product2Id, Product2.Training_Event_Residential__c
          FROM PricebookEntry
          WHERE Pricebook2Id = :this.selectedCountry.PriceBookId
          AND Product2.ProductCode = 'AccomDuring'//'NicksAccommodationProduct'
          LIMIT 1];

      }
      catch(Exception e)
      {
        // Forward to error page?
      }
*/
      /* END */

        // Step through query
        // 13 March 2017 Vim: Query below is updated to include Virtual Learning Course
        for (Training_Event__c event : [
            SELECT  evt.Id,
                    evt.Course__c,
                    evt.Course__r.Base_Product__c,
                    evt.Course__r.Course_Format__c,
                    evt.Course__r.Premium_Product__c,
                    evt.Course__r.Extra_Night__c,
                    evt.Course__r.Enable_Online_Booking__c,
                    evt.Course__r.Training_Event_Residential__c,
                    evt.Course__r.Online_Exam__c,
                    evt.Course__r.Online_Standard__c,
                    evt.Split_Date_Event__c,
                    evt.Start_Date__c,
                    evt.End_Date_of_Section_1__c,
                    evt.Start_Date_of_Section_2__c,
                    evt.End_Date3__c,
                    evt.Training_Venue__c,
                    evt.Training_Venue__r.Name,
                    evt.Training_Venue__r.Venue_Website__c,
                    evt.Delivery_Language__c,
                    evt.Residential__c,
                    evt.Max_Seats__c,
                    evt.Enrollment_Count__c,
                    evt.On_Hold_for_Payment__c,
                    evt.Enrollment_Pending__c,
                    evt.Course_Duration_Days__c,
                    evt.Accommodation_available_for_this_event__c,
                    evt.Exclude_from_online_booking__c,
                    evt.Event_status__c,
                    evt.Premium_Priced_Event__c,
                    evt.Remaining_Accommodation__c,
                    evt.Trainer__c,
                    evt.Trainer__r.Name,
                    (
                    SELECT  m1.Id,
                            m1.Split_Date_Event__c,
                            m1.Start_Date__c,
                            m1.End_Date_of_Section_1__c,
                            m1.Start_Date_of_Section_2__c,
                            m1.End_Date3__c
                    FROM    evt.Training_Events__r m1
                    ORDER   BY m1.Start_Date__c
                    ),
                    (
                    SELECT  m2.Id,
                            m2.Split_Date_Event__c,
                            m2.Start_Date__c,
                            m2.End_Date_of_Section_1__c,
                            m2.Start_Date_of_Section_2__c,
                            m2.End_Date3__c
                    FROM    evt.Modules2__r m2
                    ORDER   BY m2.Start_Date__c
                    )
            FROM    Training_Event__c evt
            WHERE   evt.Course__c IN :this.prices.keySet()
                    AND evt.Exclude_From_Online_Booking__c = false
                    AND evt.Active_1_0__c = 1
                    AND ((evt.Course__r.Course_Format__c IN ('ILT','Webinar','Virtual Learning') AND
                        evt.Start_Date__c > :Date.today()) OR
                        (evt.Course__r.Course_Format__c IN ('Distance Learning','E-Learning') AND
                        evt.Start_Date__c <= :Date.today() AND evt.End_Date3__c >= :Date.today()))
            ORDER   BY evt.Start_Date__c
            ])
        {
            // Check to see if event matches record filter
            if (this.selectedLocation == null || this.selectedLocation == '' || this.selectedLocation == event.Training_Venue__c)
            {
                // Check to see whether there are more records
                if (this.events.size() == this.pageRowLimit)
                {
                    // More records to show
                    this.pageAllowMore = true;
                    break;
                }
                else
                {
                    //if 'show more' was not clicked - skip courses more than 180days in future (JS 20181211 unless events only in future)
                    if(!pageAllowMoreClicked && this.events.size() >= 1  && ((event.Start_Date__c - this.selectedCountry.futureEventDays) > Date.today())){
                        //more records to show
                        this.pageAllowMore = true;
                        continue;
                    }

                    // TODO: new constructor pass in event and this.prices
                    // Add a record to the List and the Map
                    //TrainingBookingUtilities.EventWrapper newEvent = new TrainingBookingUtilities.EventWrapper(event, this.Prices.get(event.Course__c), this.Prices.get(event.Course__r.Base_Product__c));

                    // 01/07/2015 CB Rework of eventWrapper
                    // 07/05/2019 PC use updated EventWrapper constructor to support config flags
                    //TrainingBookingUtilities.EventWrapper newEvent = new TrainingBookingUtilities.EventWrapper(event, this.Prices);
                    TrainingBookingUtilities.EventWrapper newEvent = new TrainingBookingUtilities.EventWrapper(event, this.Prices, this.selectedCountry.Flags);

                    if (this.selectedCountry != null && this.selectedCountry.advanceBookingDays != null)
                    {
                        newEvent.setShortNotice(this.selectedCountry.advanceBookingDays);
                    }
                    /* 21/11/2014 NF */
                    //TrainingBookingUtilities.EventWrapper newEvent = new TrainingBookingUtilities.EventWrapper(event, this.Prices.get(event.Course__c), accommPBE);
                    /* END */
                    this.Events.add(newEvent);
                    eventId = event.Id;
                }
            }
        }
    }

    // Get a list of event locations for the supplied course
    public List<SelectOption> getLocationOptions()
    {
        // Create empty List of options and Set that will be used for deduping
        List<SelectOption> result = new List<SelectOption>();
        result.add(new SelectOption('', Label.TrainingBookingLocationHeader));
        Set<Id> uniqueLocations = new Set<Id>();

        // Query future events
        // 13 March 2017 Vim: Query below is updated to include Virtual Learning Course
        for (Training_Event__c event : [
            SELECT  evt.Training_Venue__c,
                    evt.Training_Venue__r.Name
            FROM    Training_Event__c evt
            WHERE   evt.Course__c IN :this.prices.keySet()
                    AND evt.Exclude_From_Online_Booking__c = false
                    AND evt.Active_1_0__c = 1
                    AND ((evt.Course__r.Course_Format__c IN ('ILT','Webinar','Virtual Learning') AND evt.Start_Date__c > :Date.today()) OR (evt.Course__r.Course_Format__c IN ('Distance Learning','E-Learning') AND evt.Start_Date__c <= :Date.today() AND evt.End_Date3__c >= :Date.today()))
            ORDER   BY evt.Training_Venue__r.Name
            ])
        {
            if (!uniqueLocations.contains(event.Training_Venue__c))
            {
                // Add entry if it doesn't already exist
                result.add(new SelectOption(String.valueOf(event.Training_Venue__c), event.Training_Venue__r.Name));
                uniqueLocations.add(event.Training_Venue__c);
            }
        }

        return result;
    }

    // Change the location filter
    public void changeFilter()
    {
        // Refresh the list of events
        retrieveEvents();
    }

    // Change the row limit on events
    public void moreEvents()
    {
        this.pageAllowMoreClicked = true;
        // Double the maximum number of rows and refresh the list of events
        this.pageRowLimit = 2 * this.pageRowLimit;
        retrieveEvents();
    }

    // Move forward to Step 2
    public PageReference forwardToStep2()
    {

        system.debug(logginglevel.ERROR, '### this is Step2');
        // Identify the selected event and build complete EventWrapper
        Training_Event__c event = TrainingBookingUtilities.eventDetails(this.selectedEventId);

        // CB 02/07/2015
        this.selectedEvent = new TrainingBookingUtilities.EventWrapper(event, this.Prices);
        system.debug(logginglevel.ERROR, '##$$ selectedEvent: '+this.selectedEvent);

        /* 25/11/2014 NF */
        //this.selectedEvent = new TrainingBookingUtilities.EventWrapper(event, this.Prices.get(event.Course__c), this.Prices.get(event.Course__r.Base_Product__c));
//    this.selectedEvent = new TrainingBookingUtilities.EventWrapper(event, this.Prices.get(event.Course__c), accommPBE);
    /* END */

        system.debug(logginglevel.ERROR, '$$$$$ Selected Event: ' + selectedEvent);

        // Start to build the training booking object
        this.objBooking.Training_Event__c = this.selectedEventId;
        this.objBooking.CurrencyIsoCode = this.selectedCountry.CurrencyIsoCode;
        if (String.isNotBlank(this.selectedCountry.Campaign)) this.objBooking.Conversion_Campaign__c = this.selectedCountry.Campaign;
        if (String.isNotBlank(this.selectedCountry.Translations)) this.objBooking.Training_Translations__c = this.selectedCountry.Translations;
        this.objBooking.Attending_Course__c = true;

        // Save a timestamp to prevent duplicated entries
        this.objBooking.Transaction_Id__c = ApexPages.CurrentPage().getHeaders().get('x-Salesforce-SIP') + Datetime.now().getTime();

        // Is there an accommodation option or not?
        if (this.selectedEvent.event.course__r.Training_Event_Residential__c)
        {
          system.debug(logginglevel.ERROR, '$$$$$ Booking is Residential');
            // Accommodation option
            this.objBooking.Is_Residential__c = true;

            // CB 02/07/2015
            // price and pbeId fields
            this.objBooking.Price_Per_Delegate_Accommodation__c = this.selectedEvent.accommodationCost;
            //this.objBooking.Price_Inc_Accommodation__c = this.selectedEvent.totalPriceWithAccomAndExtraNight;
            this.objBooking.Pricebook_Inc_Accommodation__c = this.selectedEvent.base.Id;
            //this.objBooking.Pricebook_Exc_Accommodation__c = this.selectedEvent.price.Id;
            //this.objBooking.Price_Exc_Accommodation__c = this.selectedEvent.price.UnitPrice;

            /* 25/11/2014 NF
            this.objBooking.Price_Inc_Accommodation__c = this.selectedEvent.price.UnitPrice;
            //this.objBooking.Pricebook_Inc_Accommodation__c = this.selectedEvent.price.Id;
            this.objBooking.Pricebook_Inc_Accommodation__c = this.selectedEvent.base.Id;
            this.objBooking.Price_Exc_Accommodation__c = this.selectedEvent.base.UnitPrice;
            //this.objBooking.Pricebook_Exc_Accommodation__c = this.selectedEvent.base.Id;
            this.objBooking.Pricebook_Exc_Accommodation__c = this.selectedEvent.price.Id;
            /* END */
        }
        else
        {
          system.debug(logginglevel.ERROR, '$$$$$ Booking is not Residential');
            // No accommodation option
            this.objBooking.Price_Per_Delegate_Accommodation__c = 0;
            this.objBooking.Is_Residential__c = false;
        }
        this.objBooking.Price_Inc_Accommodation__c = this.selectedEvent.totalPriceWithAccomAndExtraNight;
        this.objBooking.Price_Exc_Accommodation__c = this.selectedEvent.price.UnitPrice;
        this.objBooking.Pricebook_Entry__c = this.selectedEvent.price.Id;
        this.objBooking.Price_Per_Delegate__c = this.selectedEvent.totalPriceCourse;

        if(null != this.selectedEvent.extraNightPrice)
        {
            this.objBooking.Price_Per_Delegate_Extra_Night__c = this.selectedEvent.extraNightCost;
            this.objBooking.Pricebook_Entry_Extra_Night__c = this.selectedEvent.extraNightPrice.Id;
        }
        else{
            this.objBooking.Price_Per_Delegate_Extra_Night__c = 0;
        }
        if(null != this.selectedEvent.premiumPrice)
        {
            this.objBooking.Pricebook_Entry_Premium_Product__c = this.selectedEvent.premiumPrice.Id;
        }
        if(null != this.selectedEvent.onlineExamPrice)
        {
            this.objBooking.Price_Per_Delegate_Online_Exam__c = this.selectedEvent.onlineExamCost;
            this.objBooking.Pricebook_Entry_Online_Exam__c = this.selectedEvent.onlineExamPrice.Id;
        }
        if(null != this.selectedEvent.onlineStandardPrice)
        {
            this.objBooking.Price_Per_Delegate_Online_Standard__c = this.selectedEvent.onlineStandardCost;
            this.objBooking.Pricebook_Entry_Online_Standard__c = this.selectedEvent.onlineStandardPrice.Id;
        }

        if(this.isAuthenticated == null) {
            this.isAuthenticated = false;
        }
        if(this.isAuthenticated && this.portalUser != null && this.portalUser.ContactId != null) {
            setExistingContactDetails(this.portalUser.ContactId);
        }

        if(!this.selectedCountry.isCheckIpSkipped && checkIP() == false) {
            // Return ip error
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_IP));
            return null;
        }

        // Set the new page
        this.pageStep = 2;
        return Page.TrainingBooking2;
    }



    // STEP 2 =============================================================================================================================

    // Populate the drop-down options for number of delegates
    public List<SelectOption> getDelegateOptions()
    {
        // Provide dropdown upto number of available places
        List<SelectOption> result = new List<SelectOption>();
        for (Integer i = 1; i <= this.selectedEvent.freeSeats && i <= selectedCountry.maxNumberOfDelegates; i++)
        {
            result.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
        }

        return result;
    }

    // Move back to Step 1
    public PageReference backToStep1()
    {
        // Set the new page to Step 1
        this.pageStep = 1;
        return Page.TrainingBooking1;
    }

    // Move forward to step 3
    public PageReference forwardToStep3()
    {
        system.debug(logginglevel.ERROR, '### this is Step3');
        // Validate inputs
        Integer errors = 0;

        // Validate the company street
        String[] lines = this.objBooking.Company_Street__c.split('\n');
        Integer longest = 0;
        for (Integer i = 0; i < lines.size(); i++) if (lines[i].length() > longest) longest = lines[i].length();
        if (lines.size() > 3 || longest > 35)
        {
            // Return error
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingStreetFormat));
            errors++;
        }

        // Make sure company data is usable in SAP
        this.objBooking.Company_Region_Code__c = '';
        this.objBooking.Company_Country_Code__c = '';
        if (this.selectedCountry.countryOptionsMap.containsKey(this.objBooking.Company_Country__c))
        {
            // Apply the codes
            TrainingBookingUtilities.CountryOption selectedOption = this.selectedCountry.countryOptionsMap.get(this.objBooking.Company_Country__c);
            this.objBooking.Company_Country_Code__c = selectedOption.sapCode;
            if (selectedOption.regionOptionsMap.containsKey(this.objBooking.Company_Region__c))
            {
                this.objBooking.Company_Region_Code__c = selectedOption.regionOptionsMap.get(this.objBooking.Company_Region__c);
            }

            // Validate the company postcode (if required)
            if (String.isNotBlank(selectedOption.pcRegex) && String.isNotBlank(this.objBooking.Company_Postcode__c) && !Pattern.matches(selectedOption.pcRegex, this.objBooking.Company_Postcode__c))
            {
                // Return error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingPostcodeErr1));
                errors++;
            }
        }
        this.objBooking.Company_Is_Overseas__c = this.objBooking.Company_Country_Code__c != this.selectedCountry.Id ? true : false;
        if (!this.objBooking.Billing_Address__c)
        {
            // Copy the company details to the billing address
            this.objBooking.Billing_Name__c = this.objBooking.Company_Name__c;
            this.objBooking.Billing_Street__c = this.objBooking.Company_Street__c;
            this.objBooking.Billing_City__c = this.objBooking.Company_City__c;
            this.objBooking.Billing_Region__c = this.objBooking.Company_Region__c;
            this.objBooking.Billing_Region_Code__c = this.objBooking.Company_Region_Code__c;
            this.objBooking.Billing_Postcode__c = this.objBooking.Company_Postcode__c;
            this.objBooking.Billing_Country__c = this.objBooking.Company_Country__c;
            this.objBooking.Billing_Country_Code__c = this.objBooking.Company_Country_Code__c;
            this.objBooking.Billing_Is_Overseas__c = this.objBooking.Company_Is_Overseas__c;
        }
        else
        {
            // Validate the billing street
            lines = this.objBooking.Billing_Street__c.split('\n');
            longest = 0;
            for (Integer i = 0; i < lines.size(); i++) if (lines[i].length() > longest) longest = lines[i].length();
            if (lines.size() > 3 || longest > 35)
            {
                // Return error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingStreetFormat));
                errors++;
            }

            // Make sure billing data is usable in SAP
            this.objBooking.Billing_Region_Code__c = '';
            this.objBooking.Billing_Country_Code__c = '';
            if (this.selectedCountry.countryOptionsMap.containsKey(this.objBooking.Billing_Country__c))
            {
                // Apply the codes
                TrainingBookingUtilities.CountryOption selectedOption = this.selectedCountry.countryOptionsMap.get(this.objBooking.Billing_Country__c);
                this.objBooking.Billing_Country_Code__c = selectedOption.sapCode;
                if (selectedOption.regionOptionsMap.containsKey(this.objBooking.Billing_Region__c))
                {
                    this.objBooking.Billing_Region_Code__c = selectedOption.regionOptionsMap.get(this.objBooking.Billing_Region__c);
                }

                // Validate the billing postcode (if required)
                if (String.isNotBlank(selectedOption.pcRegex) && String.isNotBlank(this.objBooking.Billing_Postcode__c) && !Pattern.matches(selectedOption.pcRegex, this.objBooking.Billing_Postcode__c))
                {
                    // Return error
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingPostcodeErr2));
                    errors++;
                }
            }
            this.objBooking.Billing_Is_Overseas__c = this.objBooking.Billing_Country_Code__c != this.selectedCountry.Id ? true : false;
        }

        // Validate email addresses
        if (this.objBooking.Email_Address__c != this.objBooking.Email_Confirmation__c)
        {
            // Return error
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingEmailMismatch));
            errors++;
        }

        // Validate VAT number for non-Italy
        // JE 18/03/21 - check to prevent ViesValidation from running on specified countries
        Set<String> deactivatedVATChecks = new Set<String>{'Poland', 'United Kingdom'};
        if (this.objBooking.Company_Country__c != 'Italy' && !deactivatedVATChecks.contains(this.objBooking.Company_Country__c) && String.isNotBlank(this.objBooking.VAT_Number__c))
        {
            if (!this.objBooking.VAT_Number__c.startsWith(this.objBooking.Billing_Country_Code__c))
            {
                // Return error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingVatCountryMismatch));
                errors++;
            }
            else
            {
                // 23 Feb Vim code to reset VAT variables (Change required for Poland NIP Field)
                polandVATAttempt++;
                this.objBooking.VAT_Error_Message__c  = null;
                // Vim code ends here
                // Call the VIES validation service
                ViesValidation.ViesValidationResponse vies = ViesValidation.validate(this.objBooking.VAT_Number__c);
                if (!vies.isChecked)
                {
                    // Return error
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingVatNotChecked));
                    errors++;
                }
                else if (!vies.isValid)
                {
                    // 23 Feb 2017 Vim updated to try 3 attemps when Poland Vat Number is failed and then bypass VIES validation after 3 attempts
                    if (this.selectedCountry.Flags.contains('VATRequired') && this.objBooking.Company_Country__c == 'Poland')
                    {
                        if(polandVATAttempt < 3 )
                        {
                            polandVATAttempted--;
                            // Return error
                            string errMsg = Label.TrainingBookingVatNotValid;
                            errMsg = errMsg.replace('{0}',string.valueOf(polandVATAttempted));
                            system.debug(logginglevel.ERROR, 'errMsg ' + errMsg);
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg ));
                            errors++;
                        }
                        else
                        {
                            this.objBooking.VAT_Error_Message__c = Label.TrainingBookingVATError;
                            vies.isValid = true;
                        }
                    }
                    else
                    {
                        // Return error
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingVatNotValid));
                        errors++;
                    }
                    // Vim code ends here.
                }
            }
        }

        // Validate VAT number for Italy
        // required for Company: VAT number and Invoice Recipient Code or Registered Email for Invoice
        // required for Professional: Codice Fiscale
        // 27/05/2019 PC added support for IT VAT
        if (this.objBooking.Company_Country__c == 'Italy' && this.selectedCountry.Flags.contains('italyFormat'))
        {
            if (this.objBooking.Company_Professional__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingItalyCompanyProfessional));
                errors++;
                return null;
            }

            if (this.objBooking.Company_Professional__c == 'Company')
            {
                if (String.isBlank(this.objBooking.VAT_Number__c))
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingItalyVat));
                    errors++;
                }
                else
                {
                    if (!this.objBooking.VAT_Number__c.startsWith(this.objBooking.Billing_Country_Code__c))
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingVatCountryMismatch));
                        errors++;
                    }
                    else
                    {
                        this.objBooking.VAT_Error_Message__c  = null;
                        ViesValidation.ViesValidationResponse vies = ViesValidation.validate(this.objBooking.VAT_Number__c);
                        if (!vies.isChecked)
                        {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingVatNotChecked));
                            errors++;
                        }
                        else
                        {
                            if(String.isBlank(this.objBooking.Invoice_Recipient_Code__c) && String.isBlank(this.objBooking.Registered_Email_for_Invoice__c))
                            {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingItalyInvoiceRecipientCodeRegisteredEmailInvoice));
                                errors++;
                            }
                        }
                    }
                }

            }

            if (this.objBooking.Company_Professional__c == 'Professional')
            {
                if (String.isBlank(this.objBooking.Codice_Fiscale__c))
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingItalyCodice));
                    errors++;
                }
            }

        }

        // 07 Nov 2016 Vim added code to make VAT Number mandatory for South Africa 
        //if (this.selectedCountry.Flags.contains('Vat2Display') && this.objBooking.Company_Country__c == 'South Africa' && String.isBlank(this.objBooking.VAT_Number2__C))
       // {
            // Return error
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingSouthAfricaVat));
            //errors++;
       // }
        // Vim Code ends here
        // 23 Feb 2017 Vim added code to make NIP Field Number mandatory for Poland
        if (this.selectedCountry.Flags.contains('VATRequired') && this.objBooking.Company_Country__c == 'Poland' && String.isBlank(this.objBooking.VAT_Number__C))
        {
             //Return error
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingVatTooltip));
            errors++;
        }
        // im Code ends here

        // JE 21/01/2021 - Implementation of regional restrictions/cross border booking functionality
        if(this.events[0].event.Course__r.Course_Format__c == 'Distance Learning' || this.events[0].event.Course__r.Course_Format__c == 'E-Learning') {
            if(!this.selectedCountry.isCheckIpSkipped && checkIP() == false) {
                // Return ip error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_IP));
                errors++;
            }
        }

        if(this.selectedCountry.blockCrossBorderBookings) {
            List<String> countryCodes = String.isNotBlank(this.selectedCountry.allowedCrossBorderCountries) ? this.selectedCountry.allowedCrossBorderCountries.split(',') : new List<String>();
            Boolean countryAllowed = false;
            if(!countryCodes.isEmpty()) {
                for(String countryCode: countryCodes) {
                    if(this.phoneCountryCodeByCountrySettingsName.get(countryCode) == this.objBooking.Phone_Country_Code__c) {
                        countryAllowed = true;
                    }
                }
            }
            if(this.selectedCountry.countryCode == this.objBooking.Phone_Country_Code__c) {
                countryAllowed = true;
            }
            if(!countryAllowed) {
                // Return phone error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_Phone));
                errors++;
            }
            if(!(String.isNotBlank(this.selectedCountry.allowedCrossBorderCountries) && this.selectedCountry.allowedCrossBorderCountries.contains(this.selectedCountry.countryOptionsMap.get(this.objBooking.Billing_Country__c).sapCode)) && this.paramCountry != this.selectedCountry.countryOptionsMap.get(this.objBooking.Billing_Country__c).sapCode) {
                // Return country error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_Country));
                errors++;
            }
        } else if(this.selectedEvent.event.Course__r.Block_Cross_Border_Bookings__c) {
            List<String> countryCodes = String.isNotBlank(this.selectedEvent.event.Course__r.Allowed_cross_border_Countries__c) ? this.selectedEvent.event.Course__r.Allowed_cross_border_Countries__c.split(',') : new List<String>();
            Boolean countryAllowed = false;
            if(!countryCodes.isEmpty()) {
                for(String countryCode: countryCodes) {
                    if(this.phoneCountryCodeByCountrySettingsName.get(countryCode) == this.objBooking.Phone_Country_Code__c) {
                        countryAllowed = true;
                    }
                }
            }
            if(this.selectedCountry.countryCode == this.objBooking.Phone_Country_Code__c) {
                countryAllowed = true;
            }
            if(!countryAllowed) {
                // Return phone error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_Phone));
                errors++;
            }
            if(!(String.isNotBlank(this.selectedEvent.event.Course__r.Allowed_cross_border_Countries__c) && this.selectedEvent.event.Course__r.Allowed_cross_border_Countries__c.contains(this.selectedCountry.countryOptionsMap.get(this.objBooking.Billing_Country__c).sapCode)) && this.paramCountry != this.selectedCountry.countryOptionsMap.get(this.objBooking.Billing_Country__c).sapCode) {
                // Return country error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_Country));
                errors++;
            }
        }

        // Return errors if found
        if (errors > 0) return null;

        // Set On Hold for UK Overseas, Distance or eLearning
        this.objBooking.Convert_To_On_Hold__c = false;
        if (this.paramCountry.toUpperCase() == 'GB' && this.objBooking.Company_Country__c != 'United Kingdom') this.objBooking.Convert_To_On_Hold__c = true;
        if (!this.pageShowSelection) this.objBooking.Convert_To_On_Hold__c = true;

        // Remove any existing delegates
        this.objDelegates = new List<TrainingDelegate__c>();

        // Create new delegates
        for (integer i = 0; i < this.selectedDelegates; i++)
        {
            // Create a new delegate
            TrainingDelegate__c delegate = new TrainingDelegate__c();
            //JE 22/01/2021
            delegate.Mobile_Country_Code__c = this.objBooking.Mobile_Country_Code__c;

            // First delegate may be the booker
            if (i == 0 && this.objBooking.Attending_Course__c)
            {
                // Copy contact details to delegate
                delegate.Salutation__c = this.objBooking.Salutation__c;
                delegate.First_Name__c = this.objBooking.First_Name__c;
                delegate.Last_Name__c = this.objBooking.Last_Name__c;
                delegate.Email_Address__c = this.objBooking.Email_Address__c;
                delegate.Email_Confirmation__c = this.objBooking.Email_Confirmation__c;
                delegate.Job_Title__c = this.objBooking.Job_Title__c;
                delegate.Mobile_Number__c = this.objBooking.Contact_Mobile__c;
                delegate.Is_Booker__c = true;
                delegate.Conversion_Contact__c = this.isAuthenticated && String.isNotBlank(this.portalUser.ContactId) ? this.portalUser.ContactId : null;
            }
            else
            {
                // Delegate isn't the booker
                delegate.Is_Booker__c = false;
            }

            // 07/05/2019 PC auto-check Delegate Online Exam for 'IncludeExam' config flag JS 31/07/2019 added in it also needs to have an online exam linked to the product
            if(this.isIncludeExam && null != this.selectedEvent.event.Course__r.Online_Exam__c) delegate.Online_Exam__c = true;
            system.debug(logginglevel.ERROR, '### delegate: ' + delegate);
            this.objDelegates.add(delegate);
        }

        // Set the new page to Step 3
        this.pageStep = 3;
        return Page.TrainingBooking3;
    }


    // STEP 3 =============================================================================================================================
    // Move back to Step 2
    public PageReference backToStep2()
    {
        // Set the new page
        this.pageStep = 2;
        return Page.TrainingBooking2;
    }

    // Move forward to Step 4
    public PageReference forwardToStep4()
    {
        System.debug('### this is Step4');

        // Validate inputs
        Integer errors = 0;
        Integer accomm = 0;
        Integer extraNight = 0;
        Integer onlineExam = 0;
        Integer onlineStandard = 0;
        for (TrainingDelegate__c delegate : this.objDelegates)
        {
            // Check email addresses match
            if (delegate.Email_Address__c != delegate.Email_Confirmation__c)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingEmailMismatch));
                errors++;
            }
            // Check Korean personal data agreed
          if (this.selectedCountry.Flags.contains('koreaFormat') && (!delegate.Agree_Personal_Data_Statement__c || !delegate.Sharing_Of_Personal_Data__c || !delegate.Use_Of_Personal_ID__c))
          {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingMustAgreeData));
              errors++;
          }
            // check delegate accommodation
            if (delegate.Accommodation_Required__c)
            {
                accomm++;
            }
            if (delegate.Accommodation_night_before__c)
            {
                extraNight++;
            }
            if (delegate.Online_Exam__c)
            {
                onlineExam++;
            }
            if (delegate.Standard__c)
            {
                onlineStandard++;
            }
        }

        if (accomm > this.selectedEvent.event.Remaining_Accommodation__c || extraNight > this.selectedEvent.event.Remaining_Accommodation__c)
        {
            String errorMessage = String.format(Label.TrainingEventAccommInsufficient, new string[]
                { String.valueOf(this.selectedEvent.event.Remaining_Accommodation__c) });
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            errors++;
        }

        // Return errors if found
        if (errors > 0) return null;

        // Update the training booking
        this.objBooking.Promotional_Code__c = '';
        this.promoOnline = false;
        this.objBooking.Discount_Value__c = 0;
        this.objBooking.Discount_Percentage__c = 0;

        //cp refactored for one loop
        this.objBooking.Number_of_Delegates__c = this.selectedDelegates;
        this.objBooking.Delegates_Inc_Accommodation__c = accomm;
        this.objBooking.Delegates_Exc_Accommodation__c = this.selectedDelegates - accomm;
        this.objBooking.Delegates_inc_extra_night__c  = extraNight;
        this.objBooking.Delegates_Inc_Exam__c = onlineExam;
        this.objBooking.Delegates_Inc_Standard__c = onlineStandard;

        // Perform a tax lookup (if required)
        calculatePrice();

        // Set the new page
        this.pageStep = 4;
        return Page.TrainingBooking4;
    }

    private void calculatePrice()
    {
        // Process the card/invoice options and set default value
        String courseOptions = this.selectedEvent.event.Course__r.Payment_Options__c;
        this.pageAllowCard = (this.selectedCountry.IsCardAllowed && courseOptions != 'Invoice');
        this.pageAllowInvoice = (this.selectedCountry.IsInvoiceAllowed && courseOptions != 'Card');
        this.objBooking.Payment_Method__c = this.pageAllowCard ? 'Card' : 'Invoice';
        if(this.objBooking.Payment_Method__c == 'Invoice' && this.selectedCountry.Flags.contains('bankTransfer')) {
            this.objBooking.Payment_Method__c = 'Bank Transfer';
        }
        // Reset calculations
        this.objBooking.Net_Price__c = 0;
        this.objBooking.Discount__c = 0;
        this.objBooking.Tax__c = 0;
        this.objBooking.Total_Price__c = 0;

        String delegateNames = '';
        for (TrainingDelegate__c delegate : this.objDelegates)
        {
            delegateNames += delegate.First_Name__c + ' ' + delegate.Last_Name__c + '; ';
        }
        this.objBooking = TrainingBookingUtilities.calculateBookingPrices(this.objBooking, this.selectedEvent);
        // See whether we need to do a tax lookup
        // calculate tax - SAP
        if (this.selectedCountry.calculateTax && this.selectedCountry.calculateTaxMethod != null && this.selectedCountry.calculateTaxMethod.containsIgnoreCase('SAP'))
        {
            System.debug('### calculate tax - SAP');
            try
            {
                // MD REPLACED THIS LINE FOR SoW034
                // TrainingBookingServices.CreateOrderResult result = TrainingBookingUtilities.SapOrderSend(this.objBooking, this.selectedEvent, delegateNames, this.selectedCountry, true);
                TrainingBookingServices.CreateOrderResult result = TrainingBookingUtilities.SapOrderSend(this.objBooking, this.selectedEvent, this.objDelegates, this.selectedCountry, true);

                system.debug(logginglevel.ERROR, 'Result Net: '+ result.Net + ' obj Net Price: ' + this.objBooking.Net_Price__c + 'Obj Discount: ' + this.objBooking.Discount__c);
                // Response is valid if no errors and net price is still correct
                System.debug('result');
                System.debug(result);
                System.debug(result.Success);
                System.debug(result.Net);
                System.debug(this.objBooking.Net_Price__c);
                System.debug(this.objBooking.Discount__c);
                if (result.Success && result.Net == this.objBooking.Net_Price__c - this.objBooking.Discount__c)
                {
                    // Set the fields
                    this.objBooking.Tax__c = result.Tax;
                    this.objBooking.Total_Price__c = this.objBooking.Net_Price__c - this.objBooking.Discount__c + this.objBooking.Tax__c;
                }
                else
                {
                    // Prevent card use
                    this.pageAllowCard = false;
                    this.pageAllowInvoice = true;
                    this.objBooking.Payment_Method__c = 'Invoice';
                }

                // Log the outcome
                this.objBooking.SAP_Messages__c = (String.isBlank(this.objBooking.SAP_Messages__c) ? 'TAX CALL\n' : this.objBooking.SAP_Messages__c + '\nTAX CALL\n') + result.Messages;
                system.debug(logginglevel.ERROR, 'was ok' + this.objBooking.SAP_Messages__c);
                system.debug(result);
                system.debug(this.objBooking);
            }
            catch(Exception e)
            {
                // Log the failure
                this.pageAllowCard = false;
                this.pageAllowInvoice = true;
                this.objBooking.Payment_Method__c = 'Invoice';
                this.objBooking.SAP_Messages__c = (String.isBlank(this.objBooking.SAP_Messages__c) ? 'TAX CALL\n' : this.objBooking.SAP_Messages__c + '\nTAX CALL\n') + e.getMessage();
                system.debug(logginglevel.ERROR, 'error caught' + this.objBooking.SAP_Messages__c);
            }
        }

        // calculate tax - SFDC
        if(this.selectedCountry.calculateTax && this.selectedCountry.calculateTaxMethod != null && this.selectedCountry.calculateTaxMethod.containsIgnoreCase('SFDC')){
            System.debug('### calculate tax - SFDC');
            // JE 17/01/2021 - preventing bank transfer from defaulting on countries using the Asperato payment gateway
            if(this.selectedCountry.gateway != 'Asperato') {
                this.objBooking.Payment_Method__c = 'Bank Transfer';
            }
            //Vietnam tax exempt
            if(paramCountry == 'VN' && this.selectedEvent.event.Course__r.Revenue_Assignment__c != null && (this.selectedEvent.event.Course__r.Revenue_Assignment__c == 'Public (Tax exempt)' || this.selectedEvent.event.Course__r.Revenue_Assignment__c == 'In-House (Tax Exempt)' || this.selectedEvent.event.Course__r.Revenue_Assignment__c == 'Distance Learning (Tax Free)')){
                this.selectedCountry.taxRate = 0;
            }

            this.objBooking.Tax__c = (this.objBooking.Net_Price__c - this.objBooking.Discount__c) * this.selectedCountry.taxRate / 100;
            this.objBooking.Total_Price__c = this.objBooking.Net_Price__c - this.objBooking.Discount__c + this.objBooking.Tax__c;
        }
    }

    // STEP 4 =============================================================================================================================
    // Apply promo code
    public void applyPromo()
    {
        // Select the details for the specified promo code
        List<Training_Promo_Code__c> promos = [
            SELECT  p.Id,
                    p.Name,
                    p.Description__c,
                    p.Status__c,
                    p.Start_Date__c,
                    p.End_Date__c,
                    p.Apply_To_All_Courses__c,
                    p.Country__c,
                    p.Online_Payments_Only__c,
                    p.Early_Booking_Discount__c,
                    p.Min_No_Of_Days_For_Early_Booking__c,
                    p.Volume_Discount__c,
                    p.No_Of_Delegates_Req_For_Discount__c,
                    p.Discount_Percentage__c,
                    p.Discount_Value__c,
                    (
                    SELECT  c.Id,
                            c.Product__c
                    FROM    Training_Promo_Code_Courses__r c
                    WHERE   c.Product__c = :this.selectedEvent.event.Course__c
                    ),
                    (
                    SELECT  e.Id,
                            e.Training_Event__c
                    FROM    Training_Promo_Code_Events__r e
                    WHERE   e.Training_Event__c = :this.selectedEvent.event.Id
                    )
            FROM    Training_Promo_Code__c p
            WHERE       p.Name = :this.objBooking.Promotional_Code__c
                    AND p.Status__c = 'Active'
                    AND p.Start_Date__c <= :Date.today()
                    AND p.End_Date__c >= :Date.today()
                    AND p.Country__c = :this.selectedEvent.event.Event_Country__c
            LIMIT   1
            ];

        // Set defaults for failure mode
        String tempPromo = this.objBooking.Promotional_Code__c;
        this.objBooking.Promotional_Code__c = '';
        this.promoError = true;
        this.promoOnline = false;

        // Check for validity
        if (promos.isEmpty()) return;
        if (promos[0].Training_Promo_Code_Courses__r.isEmpty() && promos[0].Training_Promo_Code_Events__r.isEmpty() && !promos[0].Apply_to_all_Courses__c) return;
        if (promos[0].Volume_Discount__c && !this.selectedEvent.event.Course__r.Training_Event_Residential__c && (this.objBooking.Number_of_Delegates__c < promos[0].No_Of_Delegates_Req_For_Discount__c)) return;
        if (promos[0].Volume_Discount__c && this.selectedEvent.event.Course__r.Training_Event_Residential__c && ((this.objBooking.Delegates_Inc_Accommodation__c + this.objBooking.Delegates_Exc_Accommodation__c) < promos[0].No_Of_Delegates_Req_For_Discount__c)) return;
        if (promos[0].Early_Booking_Discount__c && (Date.today().daysBetween(this.selectedEvent.event.Start_Date__c) < promos[0].Min_No_Of_Days_For_Early_Booking__c)) return;
        if (promos[0].Online_Payments_Only__c && !this.pageAllowCard) return;
        if (promos[0].Online_Payments_Only__c && this.objBooking.Payment_Method__c != 'Card') return;

        // Apply promotional code
        this.objBooking.Promotional_Code__c = tempPromo;
        this.promoError = false;
        this.promoOnline = promos[0].Online_Payments_Only__c;
        this.objBooking.Discount_Value__c = promos[0].Discount_Value__c;
        this.objBooking.Discount_Percentage__c = promos[0].Discount_Percentage__c / 100;
        calculatePrice();
    }

    // Remove promo code
    public void removePromo()
    {
        // Remove all promotional codes
        this.objBooking.Promotional_Code__c = '';
        this.promoOnline = false;
        this.objBooking.Discount_Value__c = 0;
        this.objBooking.Discount_Percentage__c = 0;
        calculatePrice();
    }

    // Reset promo code error
    public void resetPromo()
    {
        // Remove all promotional codes
        this.promoError = false;
    }

    // Move back to Step 3
    public PageReference backToStep3()
    {
        // Set the new page
        this.promoError = false;
        this.pageStep = 3;
        return Page.TrainingBooking3;
    }

    // Move forward to Step 5 or 6
    public PageReference forwardToStep5Or6()
    {
        // Validate inputs
        this.promoError = false;
        Integer errors = 0;

        // Check for duplicate posting
        if ([
            SELECT  bkg.Id
            FROM    TrainingBooking__c bkg
            WHERE   bkg.Transaction_Id__c = :this.objBooking.Transaction_Id__c
            ].size() > 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingDuplicatePosting));
            return null;
        }

        System.debug(this.selectedCountry);
        System.debug(this.objBooking);
        // Check Ts & Cs agreed
        if(!this.objBooking.Agree_Terms_Conditions__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingMustAgreeTerms));
            errors++;
        }
        // Check personal data agreed - MD Modified 17/05/2018 for GDPR: Now relevant to all Countries. Previously only Japan.
        // if (this.selectedCountry.Flags.contains('japanFormat') && !this.objBooking.Agree_Personal_Data_Statement__c)
        if(!this.objBooking.Agree_Personal_Data_Statement__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingMustAgreeData));
            errors++;
        }
        // Check immediate payment
        if(this.selectedCountry.calculateTaxMethod != null && this.selectedCountry.calculateTaxMethod.containsIgnoreCase('SFDC') && this.selectedCountry.Flags.contains('bankTransfer') && !this.objBooking.Agree_Immediate_Payment__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingMustAgreePayment )); //JS added custom label
            errors++;
        }
        // Check no un-applied promo code
        if(this.objBooking.Promotional_Code__c != null && this.objBooking.Promotional_Code__c != '' && this.objBooking.Discount__c == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingApplyPromotionalCode));
            errors++;
        }
        // Check for online payment discount and invoice
        if(this.promoOnline && this.objBooking.Payment_Method__c != 'Card'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingOnlinePromo));
            errors++;
        }

        // Return errors if found
        if(errors > 0) return null;

        // Save the details
        this.objBooking.Payment_Status__c = this.objBooking.Payment_Method__c == 'Card' ? 'In Progress' : 'Invoice';

        if(this.selectedCountry.countryOptionsMap.containsKey(objBooking.Company_Country__c)){
            TrainingBookingUtilities.CountryOption countryOption = this.selectedCountry.countryOptionsMap.get(objBooking.Company_Country__c);
            if(null != countryOption) this.objBooking.Country_ISO_Code__c = countryOption.sapCode;
        }

        /* 25/11/2014 NF */
        /* Country_Currency__c country = [SELECT Name, Country_Name__c
                         FROM Country_Currency__c
                         WHERE Country_Name__c = :objBooking.Company_Country__c
                         LIMIT 1];

        if(country != null)
        {
            this.objBooking.Country_ISO_Code__c = country.Name;
        }*/
        /* END */

        /* JS 20201118removed section as not working as expected - descoping until later if still required
        // add country phone code
        if(this.objBooking.Contact_Phone__c != null && this.selectedCountry.countryCodePhonePrefix != null){
            this.objBooking.Contact_Phone__c = this.selectedCountry.countryCodePhonePrefix + this.objBooking.Contact_Phone__c;
        }
        if(this.objBooking.Contact_Mobile__c != null && this.selectedCountry.countryCodeMobilePrefix != null){
            this.objBooking.Contact_Mobile__c = this.selectedCountry.countryCodeMobilePrefix + this.objBooking.Contact_Mobile__c;
        }
        if(this.objBooking.Contact_Fax__c != null && this.selectedCountry.countryCodeFaxPrefix != null){
            this.objBooking.Contact_Fax__c = this.selectedCountry.countryCodeFaxPrefix + this.objBooking.Contact_Fax__c;
        }
        */

        System.debug(logginglevel.ERROR, 'objBooking::' + objBooking);
        insert this.objBooking;
        for (TrainingDelegate__c delegate : this.objDelegates){
            delegate.Training_Booking__c = this.objBooking.Id;
        }
        insert this.objDelegates;

        // refetch record to get booking Name
        if(this.bookingName == null){
            this.bookingName = [SELECT Name FROM TrainingBooking__c WHERE Id = :this.objBooking.Id].Name;
        }
        // Set the new page according to payment type
        if (this.objBooking.Payment_Method__c == 'Card')
        {
            system.debug('gateway444 ' + this.selectedCountry.gateway);
            // commented by: Mahmood (Cognizant) on 26-03-2020 for AU implementation
            if (this.selectedCountry.gateway == 'NAB')
            {
                // Redirect to NAB payment page
                PageReference ref = Page.TrainingBookingNAB;
                ref.getParameters().put('ID', this.objBooking.Id);
                ref.getParameters().put('CT', this.paramCountry);
                ref.getParameters().put('L', this.paramLanguage);
                ref.setRedirect(true);
                return ref;
            // JE 17/01/2021 - functionality to create Asperato asp04__Payment__c record and redirect to Asperato payment gateway
            } else if(this.selectedCountry.gateway == 'Asperato') {
                this.createAsperatoPayment();
                PageReference ref = Page.TrainingBookingAsperatoGateway;
                ref.getParameters().put('ID', this.objBooking.Id);
                ref.getParameters().put('CT', this.paramCountry);
                ref.getParameters().put('L', this.paramLanguage);
                ref.getParameters().put('paymentId', this.asperatoPayment.Id);
                ref.setRedirect(true);
                return ref;
            // EN 19/05/2021 - functionality to redirect to Adyen payment gateway
            } else if(this.selectedCountry.gateway == 'Adyen') {
                PageReference ref = Page.TrainingBookingAdyen;
                ref.getParameters().put('ID', this.objBooking.Id);
                ref.getParameters().put('CT', this.paramCountry);
                ref.getParameters().put('L', this.paramLanguage);
                ref.setRedirect(true);
                return ref;
            } else {
                // Redirect to Ogone payment page (default)
                // commented by: Mahmood (Cognizant) on 30-01-2020
                //PageReference ref = Page.TrainingBookingOgone;
                PageReference ref = Page.TrainingBookingOgoneIFrame;
                ref.getParameters().put('ID', this.objBooking.Id);
                ref.getParameters().put('CT', this.paramCountry);
                ref.getParameters().put('L', this.paramLanguage);
                ref.getParameters().put('awc', this.awc);
                ref.setRedirect(true);

                return ref;
            }
        }
        // VA 17 Oct 2016 - Additional tracking data variables for Marketing
        extraNightProductId = this.selectedEvent.event.Course__r.Extra_Night__c;
        accomodationProductId = this.selectedEvent.event.Course__r.Base_Product__c;
        pricePerDelegateAccomodation = objBooking.Price_Per_Delegate_Accommodation__c;
        pricePerDelegateExtraNight = objBooking.Price_Per_Delegate_Extra_Night__c;

        // VA code ends here
        if(String.isBlank(this.objBooking.Name)) {
            this.objBooking = TrainingBookingUtilities.bookingDetails(this.objBooking.Id);
        }

        // Send conversion data to Awin
        if (this.paramCountry == 'gb') {
            AwinTrackingHandler.sendRequest(
                (this.objBooking.Net_Price__c - this.objBooking.Discount__c),
                this.objBooking.Promotional_Code__c,
                this.objBooking.CurrencyIsoCode,
                this.objBooking.Id,
                this.awc
            );
        }

        // Redirect to thank you page
        this.pageStep = 6;
        return Page.TrainingBooking6;
    }

    // JE 17/01/2021 - method to create Asperato payment record using TrainingBooking__c fields
    public void createAsperatoPayment() {
        this.asperatoPayment = new asp04__Payment__c(
            asp04__Amount__c = this.objBooking.Total_Price__c,
            asp04__Company_Name__c = this.objBooking.Billing_Name__c,
            asp04__Billing_Address_City__c = this.objBooking.Billing_City__c,
            asp04__Billing_Address_Country__c = this.objBooking.Billing_Country__c,
            asp04__Billing_Address_PostalCode__c = String.isBlank(this.objBooking.Billing_Postcode__c) && this.selectedCountry.Flags.contains('noPostcode') ? 'N/A' : this.objBooking.Billing_Postcode__c,
            asp04__Billing_Address_Street__c = this.objBooking.Billing_Street__c,
            asp04__First_Name__c = this.objBooking.First_Name__c,
            asp04__Last_Name__c = this.objBooking.Last_Name__c,
            asp04__Email__c = this.objBooking.Email_Address__c,
            Training_Booking__c = this.objBooking.Id,
            //asp04__Merchant_Group__c = ,
            CurrencyIsoCode = this.objBooking.CurrencyIsoCode
        );
        insert this.asperatoPayment;
    }

    // JE 01/02/21  - redirect to community user login screen
    public PageReference forwardToLogin() {
        if(!(this.events[0].event.Course__r.Course_Format__c == 'Distance Learning' || this.events[0].event.Course__r.Course_Format__c == 'E-Learning')) {
            if(!this.selectedCountry.isCheckIpSkipped && checkIP() == false) {
                // Return ip error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_IP));
                return null;
            }
        }

        this.pageStep = 2;
        this.isAuthenticated = false;
        this.resetPasswordURL = Label.TrainingBookingResetPasswordLink + '?language=' + this.pageLanguage;
        return Page.TrainingBookingCommunityUserLogin;
    }

    // JE 28/01/21 - method to allow existing portal user to authenticate and prepopulate fields
    public PageReference portalUserLogin() {
        if(this.events[0].event.Course__r.Course_Format__c == 'Distance Learning' || this.events[0].event.Course__r.Course_Format__c == 'E-Learning') {
            if(!this.selectedCountry.isCheckIpSkipped && checkIP() == false) {
                // Return ip error
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingCountryValidation_IP));
                return null;
            }
        }
        if(String.isNotBlank(this.username) && String.isNotBlank(this.password)) {
            this.isAuthenticated = CommunityUserLogin.authenticate(this.username, this.password);
            if(this.isAuthenticated) {
                this.portalUser = [SELECT Id, Username, FirstName, LastName, ContactId FROM User WHERE Username = :this.username];
                return forwardToStep2();
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingPortalAuthError));
                return null;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TrainingBookingPopulateLoginError));
            return null;
        }
    }

    // JE 28/01/21 - method to set existing contact details on the training booking record
    public void setExistingContactDetails(Id contactId) {
        Contact contact = [
            SELECT Id, Salutation, FirstName, LastName, Email, MailingStreet, MailingCity,
                   MailingPostalCode, MailingCountry, MailingState, Account.Name, Phone, MobilePhone, Fax, Title,
                   AccountId, OtherStreet, OtherCity, OtherPostalCode, OtherCountry, OtherState, Account.VAT_Number_NonEU__c,
                   Account.VAT_Number__c
            FROM Contact
            WHERE Id = :contactId
        ];
        System.debug(contact);

        // Get the configuration
        TrainingBookingUtilities.Configuration config = new TrainingBookingUtilities.Configuration();

        //EN 06/16/2021 - Populate Company country with Mailing Coountry and Billing Country with Other Country
        // Get the country-specific settings for Company country
        if (contact.MailingCountry.touppercase() == 'UK') {
            contact.MailingCountry = 'GB';
        }
        if (contact.OtherCountry.touppercase() == 'UK') {
            contact.OtherCountry = 'GB';
        }

        String mailingCountry = new TrainingBookingUtilities.Country(
            config.supportedCountries.get(this.paramCountry.toUpperCase()),
            this.paramLanguage.toUpperCase(),
            contact.MailingCountry.toUpperCase()
        ).countryOptionsDefault;

        // Get the country-specific settings for Billing country
        String billingCountry = '';
        if (contact.OtherCountry != null && contact.OtherCountry.length() == 2) {
            billingCountry = new TrainingBookingUtilities.Country(
                config.supportedCountries.get(this.paramCountry.toUpperCase()),
                this.paramLanguage.toUpperCase(),
                contact.OtherCountry.toUpperCase()
            ).countryOptionsDefault;
        } else {
            billingCountry = mailingCountry;
        }

        this.objBooking.Company_Name__c = contact.Account.Name;
        this.objBooking.Salutation__c = contact.Salutation;
        this.objBooking.First_Name__c = contact.FirstName;
        this.objBooking.Last_Name__c = contact.LastName;
        this.objBooking.Email_Address__c = contact.Email;
        this.objBooking.Email_Confirmation__c = contact.Email;
        this.objBooking.Company_Street__c = contact.MailingStreet;
        this.objBooking.Company_Postcode__c = contact.MailingPostalCode;
        this.objBooking.Company_Region__c = contact.MailingState;
        this.objBooking.Company_City__c = contact.MailingCity;
        this.objBooking.Company_Country__c = mailingCountry;
        this.objBooking.Job_Title__c = contact.Title;
        this.objBooking.Contact_Phone__c = contact.Phone;
        //this.objBooking.Phone_Country_Code__c  = contact.Phone_Country_Code__c;
        this.objBooking.Contact_Mobile__c = contact.MobilePhone;
        //this.objBooking.Mobile_Country_Code__c = contact.Mobile_Country_Code__c;
        this.objBooking.Contact_Fax__c = contact.Fax;
        this.objBooking.Portal_Customer__c = true;
        this.objBooking.Conversion_Account__c = contact.AccountId;
        this.objBooking.Conversion_Contact__c = contact.Id;
        this.objBooking.VAT_Number__c = contact.Account.VAT_Number__c;
        this.objBooking.VAT_Number2__c = contact.Account.VAT_Number_NonEU__c;
        if(contact.MailingStreet != contact.OtherStreet) {
            this.objBooking.Billing_Name__c = contact.Account.Name;
            this.objBooking.Billing_Address__c = true;
            this.objBooking.Billing_Street__c = contact.OtherStreet;
            this.objBooking.Billing_Postcode__c = contact.OtherPostalCode;
            this.objBooking.Billing_Region__c = contact.OtherState;
            this.objBooking.Billing_City__c = contact.OtherCity;
            this.objBooking.Billing_Country__c = billingCountry;
        }
    }

    // JE 04/02/2021 - method to validate country code returned by GeoIP integration if block cross border booking is enabled
    //                 returns null if no check is made or the check fails
    //                 returns true if check is successful and country is allowed
    //                 returns false if check is successful and country is blocked
    public Boolean checkIP() {
        if(!Test.isRunningTest()) {
            Training_Event__c event = TrainingBookingUtilities.eventDetails(this.selectedEventId);
            this.selectedEvent = new TrainingBookingUtilities.EventWrapper(event, this.Prices);
        }
        if(this.selectedCountry.blockCrossBorderBookings) {
            if(this.ipCountryCode == null) {
                this.ipCountryCode = ValidateUserIP.execute(getIPAddress());
            }
            if(this.ipCountryCode == null) {
                return null;
            } else if(!(String.isNotBlank(this.selectedCountry.allowedCrossBorderCountries) && this.selectedCountry.allowedCrossBorderCountries.contains(this.ipCountryCode)) && this.paramCountry != this.ipCountryCode) {
                return false;
            } else {
                return true;
            }
        } else if(this.selectedEvent != null && this.selectedEvent.event.Course__r.Block_Cross_Border_Bookings__c) {
            if(this.ipCountryCode == null) {
                this.ipCountryCode = ValidateUserIP.execute(getIPAddress());
            }
            if(this.ipCountryCode == null) {
                return null;
            } else if(!(String.isNotBlank(this.selectedEvent.event.Course__r.Allowed_cross_border_Countries__c) && this.selectedEvent.event.Course__r.Allowed_cross_border_Countries__c.contains(this.ipCountryCode)) && this.paramCountry != this.ipCountryCode) {
                return false;
            } else {
                return true;
            }
        } else {
            return null;
        }
    }

    // JE 04/02/2021 - returns the IP address of the current guest user
    public String getIPAddress() {
        // True-Client-IP has the value when the request is coming via the caching integration.
        String ipAddress = ApexPages.currentPage().getHeaders().get('True-Client-IP');

        // X-Salesforce-SIP has the value when no caching integration or via secure URL.
        if (String.isBlank(ipAddress)) {
            ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        }

        // get IP address when no caching (sandbox, dev, secure urls)
        if (String.isBlank(ipAddress)) {
            ipAddress = ApexPages.currentPage().getHeaders().get('X-Forwarded-For');
        }
        return ipAddress;
    }

    // STEP 6 =============================================================================================================================
    // Print confirmation page
    public PageReference printConfirmation()
    {
        PageReference ref = Page.TrainingBooking8;
        ref.getParameters().put('ID', this.objBooking.Id);
        ref.getParameters().put('CT', this.paramCountry);
        ref.getParameters().put('L', this.paramLanguage);
        ref.setRedirect(true);
        return ref;
    }

    // STEP 7 =============================================================================================================================
    // Error clean up
    public PageReference catchError()
    {
        String aliasstatus = ApexPages.currentPage().getParameters().get('ALIAS.STATUS');
        if(aliasstatus == '3') ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'canceled by user!'));
        // Set incomplete card transactions to errored (if applicable)
        if (this.objBooking != null && this.objBooking.Payment_Status__c == 'In Progress')
        {
                TrainingBooking__c booking = new TrainingBooking__c(Id = this.objBooking.Id);
                booking.Payment_Status__c = 'Card Error';
                update booking;
        }

        return null;
    }
    // 14 Nov 2016 Vim added code to retain value of Number of delegates Selected on Online booking form
    public void checkValue()
    {
        system.debug(logginglevel.ERROR, '----------------'+this.selectedDelegates);
    }
    // Vim code ends here
}