/*
*   30/06/2015  CB  Added Accommodation_night_before__c to delegate SOQL
*                   Added Course__r.Premium_Product__c
                          Course__r.Extra_Night__c  to event SOQL
    22/02/2016  CP  AccommodationAvail and extraNightAvailable on EventWrapper to check
                    Remaining_Accommodation__c >= 1, setShortNotice() added, getIntegerValue() added,
                    calculateBookingPrices() added, SapOrderSend() added to generalise sapOrder for both dummy
                    calls and Order Calls, getUnitDiscount() added, sapOrder() changed to call SapOrderSend()
                    Country() constructor edited to get bookingDays and maxDelegates, EventWrapper Constructors
                    changed to use setShortNotice()

*   11/10/2016  VA  Updated Online Payment EU VAT (shipTo and soldTo code fix)
*   11/01/2018  JS  Added in VAT Number 2 to allow for vat calculations using this number for outside of EU
*   27/03/2018  MD  COPIED UPDATES FROM DEV3 (28/07/2017  ADS - SoW034 - Online Exam Enhancements)
*   04/03/2019  MD  Retrieve additional parameters from config file
*   15/03/2019  MD  Altered the way line items are sent to SAP to allow for exam "bundle"
*   11/12/2010  JS  Added 2 new fields to query to pull into pdf
*   02/02/2020  MB  Added new function bookingDetailsByName which accepts Booking name as parameter.
*   29/04/2021  EN  Added new Skip_IP_check__c field to Training_Booking_Country_Settings__mdt and isCheckIpSkipped property to Country class.
*   28/06/2021  JS  Adjusted mapping to SAP BAPI to send Vat_Number2__c for PH to send TIN to SAP
*   21/10/2021  Buddy Winter <Cloudshift> Modified SapOrderSend to allow to switch between SOAP and REST calls to SAP for tax calculation and orders.
*   19/05/2022  JS  With help from CS adding in a field from the event to disable autobilling if required  initially for use with SG and MY e-learning events might need to switch to "without" sharing class
*   01/06/2022  JS  Changed from with sharing to switch to "without" sharing class to fix accomm not showing
*/
public without sharing class TrainingBookingUtilities
{
    public static final String EVENT_STATUS_PLANNING = 'Planning';
    public static final String EVENT_STATUS_CANCELLED = 'Cancelled';
    public static final Integer EVENT_DEFAULT_ADVANCE_BOOKING_DAYS = 6;
    public static final Integer EVENT_MAX_DELEGATES = 4;
    public static final Integer EVENT_MAX_ROWS_DEFAULT = 15;
    public static final Integer EVENT_DEFAULT_FUTURE_EVENT_DAYS = 180;

    // Vimlesh 11 Oct 2016 variable added to get EU countries list from xml file located at static resource.
    public static Map<String, DOM.Xmlnode> supportedEUCountries { get; set; }

    // Retrieve existing Training Booking
    public static TrainingBooking__c bookingDetails(String id)
    {
        TrainingBooking__c[] tb = [
            SELECT  b.Id,
                    b.Name,
                    b.Bank_Account__c,
                    b.Bank_Name__c,
                    b.Booking_Country__c,
                    b.Booking_Language__c,
                    b.CurrencyIsoCode,
                    b.Pricebook_Entry__c,
                    b.Pricebook_Exc_Accommodation__c,
                    b.Pricebook_Inc_Accommodation__c,
                    b.Pricebook_Entry_Extra_Night__c,
                    b.Pricebook_Entry_Premium_Product__c,
                    b.Pricebook_Entry_Online_Exam__c,
                    b.Pricebook_Entry_Online_Standard__c,
                    b.Training_Event__c,
                    b.Conversion_Campaign__c,
                    b.Training_Translations__c,
                    b.Is_Residential__c,
                    b.Invoice_Category__c,
                    b.Invoice_Recipient__c,
                    b.Invoice_Notes__c,
                    b.Invoice_Phone__c,
                    b.Number_of_Delegates__c,
                    b.Delegates_Exc_Accommodation__c,
                    b.Delegates_Inc_Accommodation__c,
                    b.Delegates_inc_extra_night__c,
                    b.Delegates_Inc_Exam__c,
                    b.Delegates_Inc_Standard__c,
                    b.Salutation__c,
                    b.First_Name__c,
                    b.Last_Name__c,
                    b.Email_Address__c,
                    b.Email_Confirmation__c,
                    b.Job_Title__c,
                    b.Attending_Course__c,
                    b.Company_Name__c,
                    b.Company_Name_English__c,
                    b.Company_Street__c,
                    b.Company_City__c,
                    b.Company_Region__c,
                    b.Company_Region_Code__c,
                    b.Company_Postcode__c,
                    b.Company_Country__c,
                    b.Company_Country_Code__c,
                    b.Company_Is_Overseas__c,
                    b.Contact_Phone__c,
                    b.Contact_Mobile__c,
                    b.Contact_Fax__c,
                    b.CreatedDate,
                    b.VAT_Number__c,
                    b.VAT_Number2__c, //JS added 11/01/2018
                    b.Codice_Fiscale__c,
                    b.Billing_Address__c,
                    b.Billing_Email_Address__c,
                    b.Business_Style__c,
                    b.Billing_Name__c,
                    b.Billing_Name_English__c,
                    b.Billing_Street__c,
                    b.Billing_City__c,
                    b.Billing_Region__c,
                    b.Billing_Region_Code__c,
                    b.Billing_Postcode__c,
                    b.Billing_Country__c,
                    b.Billing_Country_Code__c,
                    b.Billing_Is_Overseas__c,
                    b.Price_Per_Delegate__c,
                    b.Price_Exc_Accommodation__c,
                    b.Price_Inc_Accommodation__c,
                    b.Discount_Value__c,
                    b.Discount_Percentage__c,
                    b.Net_Price__c,
                    b.Discount__c,
                    b.Tax__c,
                    b.Total_Price__c,
                    b.PO_Number__c,
                    b.Promotional_Code__c,
                    b.Language_For_Invoice__c,
                    b.Payment_Error_Message__c,
                    b.Payment_Method__c,
                    b.Payment_Status__c,
                    b.Payment_Order_No__c,
                    b.Payment_Card__c,
                    b.Payment_Name__c,
                    b.SAP_Order_No__c,
                    b.SAP_Messages__c,
                    b.Total_Delegates__c,
                    b.Transaction_Id__c,
                    b.How_Did_You_hear_About_Us__c,
                    b.Source_BSI_Staff__c,
                    b.Source_Other__c,
                    b.Agree_Personal_Data_Statement__c,
                    b.Agree_Terms_Conditions__c,
                    b.Price_Per_Delegate_Accommodation__c,
                    b.Price_Per_Delegate_Extra_Night__c,
                    b.Registered_Email_for_Invoice__c,
                    b.Training_Translations__r.Include_Exam_with_Course__c,
                    b.Branch_Number__c, // JS added 12/08/2020
                    b.Venue_City__c,
                b.Phone_Country_Code__c, // JE 21/01/2021
                b.Mobile_Country_Code__c,
                b.Portal_Customer__c // JE 02/02/2021
            FROM    TrainingBooking__c b
            WHERE   b.Id = :id ];
        if(tb.size()>0) return tb[0];
        else return null;
    }

    // Retrieve existing Training Booking
    public static TrainingBooking__c bookingDetailsByName(String orderName)
    {
        return [
            SELECT  b.Id, b.Name, b.Bank_Account__c, b.Bank_Name__c, b.Booking_Country__c, b.Booking_Language__c, b.CurrencyIsoCode, b.Pricebook_Entry__c,
                    b.Training_Event__c, b.Conversion_Campaign__c, b.Training_Translations__c, b.Is_Residential__c,
                    b.Invoice_Category__c, b.Invoice_Recipient__c, b.Invoice_Notes__c, b.Invoice_Phone__c, b.Number_of_Delegates__c,
                    b.Delegates_Inc_Exam__c, b.Delegates_Inc_Standard__c, b.Salutation__c, b.First_Name__c, b.Last_Name__c,
                    b.Email_Address__c, b.Email_Confirmation__c, b.Job_Title__c, b.Attending_Course__c, b.Company_Name__c,
                    b.Company_Name_English__c, b.Company_Country_Code__c, b.Contact_Phone__c, b.Contact_Mobile__c, b.Contact_Fax__c, b.CreatedDate,
                    b.Price_Per_Delegate__c, b.Price_Exc_Accommodation__c, b.Price_Inc_Accommodation__c,
                    b.Discount__c, b.Discount_Value__c, b.Discount_Percentage__c, b.Net_Price__c,
                    b.Tax__c, b.Total_Price__c, b.PO_Number__c, b.Promotional_Code__c, b.Language_For_Invoice__c,
                    b.Payment_Method__c, b.Payment_Status__c, b.Payment_Order_No__c, b.Payment_Card__c, b.Payment_Name__c,
                    b.Registered_Email_for_Invoice__c,
                    b.SAP_Order_No__c, b.SAP_Messages__c, b.Total_Delegates__c, b.Transaction_Id__c, b.How_Did_You_hear_About_Us__c,
                    b.Source_BSI_Staff__c, b.Agree_Terms_Conditions__c, b.Training_Translations__r.Include_Exam_with_Course__c,
                    b.VAT_Number__c, b.VAT_Number2__c, b.Codice_Fiscale__c, b.Venue_City__c, b.Phone_Country_Code__c, // JE 21/01/2021
                b.Mobile_Country_Code__c
            FROM    TrainingBooking__c b
            WHERE   b.Name = :orderName LIMIT 1];
    }
    // Retrieve existing Training Delegates
    public static List<TrainingDelegate__c> delegateDetails(String id)
    {
        return [
          SELECT  d.Id,
                    d.Name,
                    d.Salutation__c,
                    d.First_Name__c,
                    d.First_Name_English__c,
                    d.Last_Name__c,
                    d.Last_Name_English__c,
                    d.Email_Address__c,
                    d.Email_Confirmation__c,
                    d.Job_Title__c,
                    d.Accommodation_Required__c,
                    d.Accommodation_night_before__c,
                    d.Agree_Personal_Data_Statement__c,
                    d.Sharing_Of_Personal_Data__c,
                    d.Use_Of_Personal_ID__c,
                    d.Is_Booker__c,
                    d.Training_Booking__c,
                    d.Online_Exam__c,
                    d.Standard__c,
                d.Mobile_Country_Code__c
            FROM    TrainingDelegate__c d
            WHERE   d.Training_Booking__c = :id];
    }

    // Retrieve existing Training Event
    public static Training_Event__c eventDetails(String id)
    {
        return [
            SELECT  evt.Id,
                evt.Name,
                    evt.Course__c,
                    //evt.Course__r.Auto_invoice_when_paid_online__c, JS added 20220512 then replaced with field on event
                    evt.Course__r.Base_Product__c,
                    evt.Course__r.Product_Name_Local__c,
                    evt.Course__r.Delivery_Method__c,                    
                    evt.Course__r.Course_Format__c,
                    evt.Course__r.Short_Name_For_Training_SMO__c,
                    evt.Course__r.Short_Name_For_Training_SMO_With_Exam__c,
                    evt.Course__r.Base_Product__r.Short_Name_For_Training_SMO__c,
                    evt.Course__r.Payment_Options__c,
                    evt.Course__r.Premium_Product__c,
                    evt.Course__r.Extra_Night__c,
                    evt.Course__r.Training_Event_Residential__c,
                    evt.Course__r.Enable_Online_Booking__c,
                    evt.Course__r.Online_Exam__c,
                    evt.Course__r.Online_Standard__c,
                    evt.Course__r.Online_Exam__r.Short_Name_For_Training_SMO__c,
                    evt.Course__r.Online_Exam__r.Assembly_Material__c,
                    evt.Course__r.Online_Standard__r.Short_Name_For_Training_SMO__c,
                    evt.Course__r.Online_Standard__r.Assembly_Material__c,
                    evt.Course__r.Revenue_Assignment__c,
                    evt.Course__r.Allowed_cross_border_Countries__c, // JE 22/01/2021
                    evt.Course__r.Block_Cross_Border_Bookings__c,
                    evt.Disable_auto_invoice__c, //JS added 220519
                    evt.India_GST__c,
                    evt.Course_Duration_Days__c,
                    evt.Split_Date_Event__c,
                    evt.Start_Date__c,
                    evt.End_Date_of_Section_1__c,
                    evt.Start_Date_of_Section_2__c,
                    evt.End_Date3__c,
                    evt.Event_Country__c,
                    evt.Training_Venue__c,
                    evt.Training_Venue__r.Name,
                    evt.Training_Venue__r.Venue_Website__c,
                    evt.Delivery_Language__c,
                    evt.Residential__c,
                    evt.Max_Seats__c,
                    evt.Enrollment_Count__c,
                    evt.On_Hold_for_Payment__c,
                    evt.Enrollment_Pending__c,
                    evt.SMO_Service_Material__c,
                    evt.SAP_Company_Code__c,
                    evt.SAP_SMO_Number__c,
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
                    ORDER  BY m1.Start_Date__c
                    ),
                    (
                    SELECT  m2.Id,
                        m2.Split_Date_Event__c,
                        m2.Start_Date__c,
                        m2.End_Date_of_Section_1__c,
                        m2.Start_Date_of_Section_2__c,
                        m2.End_Date3__c
                    FROM    evt.Modules2__r m2
                    ORDER  BY m2.Start_Date__c
                    )
                FROM    Training_Event__c evt
                WHERE   evt.Id = :id];
    }

    //Retrieve training venue address to pass to SAP ShipTo address (Vimlesh on 11 Oct 2016)
    public static Training_Venue__c venueDetails(String venueId)
    {
        // Query to retrieve training event venue to pass to SAP ShipTo information
        return [
            Select
                Id,
                Name,
                Venue_Contact_Name__c,
                Venue_Contact_Email__c,
                Phone__c,
                Venue_Street__c,
                Venue_city__c,
                Venue_State__c,
                Venue_Country__c,
                Venue_Postal_Zip_code__c
            FROM
                Training_Venue__c evtVenue WHERE evtVenue.Id = :venueId];
    }

    // Try to commit the order to SAP asynchronously
    @Future (callout=true)
    public static void sapOrder(String id)
    {
        // Retrieve the booking, event and delegate details
        TrainingBooking__c booking = bookingDetails(id);
        Training_Event__c event = eventDetails(booking.Training_Event__c);
        String delegateNames = '';
        for (TrainingDelegate__c d : [
          SELECT  d.First_Name__c,
                    d.Last_Name__c,
                    d.Accommodation_Required__c
            FROM    TrainingDelegate__c d
            WHERE   d.Training_Booking__c = :id])
        {
          delegateNames += (delegateNames == '' ? '' : '; ') + d.First_Name__c + ' ' + d.Last_Name__c;
        }

        TrainingBookingUtilities.EventWrapper selectedEvent = new TrainingBookingUtilities.EventWrapper(booking);
        
        // Get the configuration
        TrainingBookingUtilities.Configuration config = new TrainingBookingUtilities.Configuration();
        TrainingBookingUtilities.Country selectedCountry = new TrainingBookingUtilities.Country(config.supportedCountries.get(booking.Booking_Country__c), booking.Booking_Language__c, '');
        //system.debug('### duda2_event ' + selectedEvent.event.Course__r.Auto_invoice_when_paid_online__c);   
        system.debug('### event ' + selectedEvent.event.Name);      //JS added 20220519
        //if (selectedCountry.calculateTaxMethod != null && selectedCountry.calculateTaxMethod.containsIgnoreCase('SAP') && selectedEvent.event.Course__r.Auto_invoice_when_paid_online__c ) {   //JS replaced with field on event below
        if (selectedCountry.calculateTaxMethod != null && selectedCountry.calculateTaxMethod.containsIgnoreCase('SAP') && !selectedEvent.event.Disable_auto_invoice__c ) {   //JS added 20220512  && !selectedEvent.event.Disable_auto_invoice__c
                
            // Retrieve the booking for update
            TrainingBooking__c updated = new TrainingBooking__c(Id = id, SAP_Messages__c = booking.SAP_Messages__c);

            try {
            
                // Call the order creator
                // MD 20180327 INSERTED FOR SoW034
                List<TrainingDelegate__c> delegates = [SELECT  d.First_Name__c,
                                                    d.Last_Name__c,
                                                    d.Accommodation_Required__c,
                                                    d.Accommodation_night_before__c,
                                                    d.Online_Exam__c,
                                                    d.Standard__c
                                                    FROM TrainingDelegate__c d
                                                    WHERE d.Training_Booking__c = :id];

                TrainingBookingServices.CreateOrderResult result = TrainingBookingUtilities.SapOrderSend(booking, selectedEvent, delegates, selectedCountry, false);
                // MD 20180327 REMOVED FOR SoW034
                //TrainingBookingServices.CreateOrderResult result = TrainingBookingUtilities.SapOrderSend(booking, selectedEvent, delegateNames, selectedCountry, false);

                // Response is valid if no errors and SAP order no
                if (result.Success && String.isNotBlank(result.SapOrderNo))
                {
                    // Set the fields
                    updated.SAP_Order_No__c = result.SapOrderNo;
                }

                // Log the outcome
                updated.SAP_Messages__c = (String.isBlank(updated.SAP_Messages__c) ? 'CREATE ORDER\n' : updated.SAP_Messages__c + '\nCREATE ORDER\n') + result.Messages;
            } catch(Exception e) {
                // Log the failure
                updated.SAP_Messages__c = (String.isBlank(updated.SAP_Messages__c) ? 'CREATE ORDER\n' : updated.SAP_Messages__c + '\nCREATE ORDER\n') + e.getMessage();
            }

            // Update the booking

            update updated;
        }
    }

    /*
     * Send a booking for an event to sap. You need an event wrapper for the event, the booking itself, a string
     * of delegate names a country the event is in a whether or not this is a real call to book the booking
     * or not this does a dummy call just to get the tax denoted by the boolean dummyCall
     */
    /* MD REPLACED THIS LINE FOR SoW034
     * public static TrainingBookingServices.CreateOrderResult SapOrderSend(TrainingBooking__c booking, TrainingBookingUtilities.EventWrapper selectedEvent, String delegateNames, TrainingBookingUtilities.Country selectedCountry, Boolean dummyCall)
     */
    public static TrainingBookingServices.CreateOrderResult SapOrderSend(TrainingBooking__c booking, TrainingBookingUtilities.EventWrapper selectedEvent, List<TrainingDelegate__c> delegates, TrainingBookingUtilities.Country selectedCountry, Boolean dummyCall)
    {

        Decimal unitDiscount = getUnitDiscount(booking);
        String sapTarget = selectedCountry.sapTarget;
        String sapTimezone = selectedCountry.sapTimezone;

        // Add the order details
        TrainingBookingServices.TrainingBookingOrder ordr = new TrainingBookingServices.TrainingBookingOrder();
        ordr.SalesOrg = selectedEvent.event.SAP_Company_Code__c;
        ordr.Currency_x = booking.CurrencyIsoCode;

        ordr.Language = booking.Booking_Language__c;
        if (!String.isBlank(booking.Language_For_Invoice__c) && selectedCountry.invoiceOptionsMap.containsKey(booking.Language_For_Invoice__c))
        {
            ordr.Language = selectedCountry.invoiceOptionsMap.get(booking.Language_For_Invoice__c);
        }
        if (dummyCall)
        {
            // Add dummy details for tax calculation
            ordr.PoNumber = '123456';
            ordr.OrderNumber = '123456';
            ordr.OrderDate = DateTime.now();
            ordr.StartDate = DateTime.now();
            ordr.EndDate = DateTime.now();
            ordr.CcAuthorisedType = 'VISA';
            ordr.CcAuthorisedName = 'DUMMY';
            ordr.CcAuthorisedDate = DateTime.now();
            ordr.CcAuthorisedAmount = 0;
            ordr.CcAuthorisationNo = '123456';
        }
        else
        {
            ordr.PoNumber = booking.PO_Number__c;
            ordr.OrderNumber = selectedCountry.gateway == 'Asperato' ? booking.Payment_Name__c : booking.Name;
            ordr.OrderDate = DateTime.valueOf(DateTime.now().format('yyyy-MM-dd HH:mm:ss', sapTimezone));
            ordr.StartDate = selectedEvent.event.Start_Date__c;
            ordr.EndDate = selectedEvent.event.End_Date3__c;
            if (selectedEvent.event.Course__r.Delivery_Method__c == 'Distance Learning' || selectedEvent.event.Course__r.Delivery_Method__c == 'eLearning')
            {
                ordr.StartDate = Date.newInstance(ordr.OrderDate.year(), ordr.OrderDate.month(), ordr.OrderDate.day());
                ordr.EndDate = ordr.StartDate;
            }
            ordr.CcAuthorisedType = String.isNotBlank(booking.Payment_Card__c) ? booking.Payment_Card__c : 'VISA';
            ordr.CcAuthorisedName = String.isNotBlank(booking.Payment_Name__c) ? booking.Payment_Name__c : booking.First_Name__c + ' ' + booking.Last_Name__c;
            ordr.CcAuthorisedDate = DateTime.valueOf(DateTime.now().format('yyyy-MM-dd HH:mm:ss', sapTimezone));
            ordr.CcAuthorisedAmount = booking.Total_Price__c;
            ordr.CcAuthorisationNo = booking.Payment_Order_No__c;
        }

        /* Commented by Vimlesh 11 Oct 2016 to add new code for online booking
        // Add the ship-to details
        TrainingBookingServices.TrainingBookingAddress shipTo = new TrainingBookingServices.TrainingBookingAddress();
        shipTo.Salutation = booking.Salutation__c;
        shipTo.Contact = booking.First_Name__c + ' ' + booking.Last_Name__c;
        shipTo.Email = booking.Email_Address__c;
        shipTo.Phone = booking.Contact_Phone__c;
        shipTo.Company = booking.Company_Name__c;
        shipTo.Street = booking.Company_Street__c;
        shipTo.City = booking.Company_City__c;
        shipTo.Region = booking.Company_Region_Code__c;
        shipTo.Postcode = booking.Company_Postcode__c;
        shipTo.Country = booking.Company_Country_Code__c;
        shipTo.VatNumber = booking.VAT_Number__c;
        shipTo.LocalTaxNo = booking.Codice_Fiscale__c;
        shipTo.Overseas = booking.Company_Is_Overseas__c;

        // Add the sold-to details
        TrainingBookingServices.TrainingBookingAddress soldTo = new TrainingBookingServices.TrainingBookingAddress();
        soldTo.Salutation = booking.Salutation__c;
        soldTo.Contact = booking.First_Name__c + ' ' + booking.Last_Name__c;
        soldTo.Email = booking.Email_Address__c;
        soldTo.Phone = booking.Contact_Phone__c;
        soldTo.Company = booking.Billing_Name__c;
        soldTo.Street = booking.Billing_Street__c;
        soldTo.City = booking.Billing_City__c;
        soldTo.Region = booking.Billing_Region_Code__c;
        soldTo.Postcode = booking.Billing_Postcode__c;
        soldTo.Country = booking.Billing_Country_Code__c;
        soldTo.VatNumber = booking.VAT_Number__c;
        soldTo.LocalTaxNo = booking.Codice_Fiscale__c;
        soldTo.Overseas = booking.Billing_Is_Overseas__c;
        */

         // New code Vimlesh 11 Oct 2016
            /* Below is the code for conditions regarding shipTo and soldTo address mapping
             * Case 1 If Event and customer is from EU country (or course is distance learning)
             *       then billing address mapped to both shipTo and soldTo party
             *       VAT recorded against soldTo
             * Case 2 If Event is from EU country and customer from Non EU country then
             *       a) venue address mapped to shipTo if customer providing Non EU billing address
             *       b) billing address mapped to shipTo if customer providing EU billing address
             * Case 3 If Event is from Non EU country and no matter customer routing
             *       then company address (Mailing address) mapped to shipTo and billing address mapped to soldTo party
             *       No VAT recorded
             * VAT recorded against soldTo in all above cases
             */
             // line added by vimlesh on 11 Oct 2016 to retrieve venue details
            Training_Venue__c venue = venueDetails(selectedEvent.event.Training_Venue__c);    // venueDetails(String venueId) method call to retrieve venue details

            string eventcountry = '';
            string billingCountry = '';
            string customerCountry = '';
            string bookingCountry = '';

            TrainingBookingServices.TrainingBookingAddress shipTo = new TrainingBookingServices.TrainingBookingAddress();
            TrainingBookingServices.TrainingBookingAddress soldTo = new TrainingBookingServices.TrainingBookingAddress();

            // code to match UK country code in SAP. it is GB in SAP for UK.
            if(selectedEvent.event.Event_Country__c == 'UK') {
                eventcountry = 'GB';}
            else{
                eventcountry = selectedEvent.event.Event_Country__c;}

            if(booking.Billing_Country_Code__c == 'UK') {
                billingCountry = 'GB';}
            else{
                billingCountry = booking.Billing_Country_Code__c;}

            if(booking.Booking_Country__c == 'UK') {
                bookingCountry = 'GB';}
            else{
                bookingCountry = booking.Booking_Country__c;}

            if(booking.Company_Country_Code__c == 'UK') {
                customerCountry = 'GB';}
            else{
                customerCountry = booking.Company_Country_Code__c;}

            // code to validate if event from EU country
            boolean isEventFromEUCountry = validateEUCountryCodes(eventcountry);

            // code to validate if customer from EU country
            boolean isCustomerFromEUCountry = validateEUCountryCodes(customerCountry);

            boolean isBillingCountryEU = validateEUCountryCodes(billingCountry);

            // shipTo contact details same in all cases.
            shipTo.Salutation = booking.Salutation__c;
            shipTo.Contact = booking.First_Name__c + ' ' + booking.Last_Name__c;
            shipTo.Email = booking.Email_Address__c;
            shipTo.Phone = booking.Contact_Phone__c;
            if(selectedEvent.event.Event_Country__c == 'IT') {
                shipTo.LocalTaxNo = booking.Codice_Fiscale__c;}
            else{
                shipTo.LocalTaxNo = booking.VAT_Number2__c;
                              System.debug('### soldTo.LocalTaxNo ' + soldTo.LocalTaxNo);
                              System.debug('### shipTo.LocalTaxNo ' + shipTo.LocalTaxNo);
                }  //JS 28062021 send VAT_Number2__c  for tax
            shipTo.Overseas = booking.Company_Is_Overseas__c;

            // soldTo mapped to Billing address in all cases
            soldTo.Salutation = booking.Salutation__c;
            soldTo.Contact = booking.First_Name__c + ' ' + booking.Last_Name__c;
            soldTo.Email = booking.Email_Address__c;
            soldTo.Phone = booking.Contact_Phone__c;
            soldTo.Company = booking.Billing_Name__c;
            soldTo.Street = booking.Billing_Street__c;
            soldTo.City = booking.Billing_City__c;
            soldTo.Region = booking.Billing_Region_Code__c;
            soldTo.Postcode = booking.Billing_Postcode__c;
            soldTo.Overseas = booking.Billing_Is_Overseas__c;
            soldTo.Country = billingCountry;

            // VAT Number held against soldTo in all cases (SAP hold VAT number against shipTo party partner function.. problem is in middle where webservice created for callout request .. it takes VAT number in soldTo from SFDC and pass it to shipTo in SAP web call  )

            if(eventcountry == 'ME')  //JS 11012018 to send VAT_Number2__c for MEA for tax
            {soldTo.VatNumber = booking.VAT_Number2__c;
            }
                if(eventcountry == 'PH')  //JS 28062021 to send VAT_Number2__c for PH TIN as local tax no for tax
                {soldTo.LocalTaxNo = booking.VAT_Number2__c;
                }
                    else
                    {soldTo.VatNumber = booking.VAT_Number__c;
                              System.debug('### soldTo.LocalTaxNo ' + soldTo.LocalTaxNo);
                              System.debug('### shipTo.LocalTaxNo ' + shipTo.LocalTaxNo);
                    }

            if(isEventFromEUCountry)
            {
                 if(isBillingCountryEU)
                 {
                    // shipTo address mapping - Case 1  and case 2(b)
                shipTo.Company = booking.Billing_Name__c;
                shipTo.Street = booking.Billing_Street__c;
                shipTo.City = booking.Billing_City__c;
                shipTo.Region = booking.Billing_Region_Code__c;
                shipTo.Postcode = booking.Billing_Postcode__c;
                shipTo.Country = billingCountry;
                 }
                 else
                 {
                    // shipTo address mapping - Case 2 (a)
                shipTo.Company = venue.Name;
                shipTo.Street = venue.Venue_Street__c;
                shipTo.City = venue.Venue_city__c;
                shipTo.Region = venue.Venue_State__c;
                shipTo.Postcode = venue.Venue_Postal_Zip_code__c;
                shipTo.Country = bookingCountry;
                 }

            }
            else
            {

                // shipTo case 3 (VAT NOT REQUIRED)
                shipTo.Company = booking.Company_Name__c;
                shipTo.Street = booking.Company_Street__c;
                shipTo.City = booking.Company_City__c;
                shipTo.Region = booking.Company_Region_Code__c;
                shipTo.Postcode = booking.Company_Postcode__c;
                shipTo.Country = customerCountry;

                              System.debug('### soldTo.LocalTaxNo ' + soldTo.LocalTaxNo);
                              System.debug('### shipTo.LocalTaxNo ' + shipTo.LocalTaxNo);
            }


        // Vimlesh code ends here 11 Oct 2016

        // Add the items
        List<TrainingBookingServices.TrainingBookingItem> parItems = new List<TrainingBookingServices.TrainingBookingItem>();

        // MD ADDED FOR SoW034, AMENDED 20190315 TO BUILD ALL STRINGS AT THE SAME TIME AND REPLACE delegateNames WITH delegateNamesWithoutExam
    // COULD ALSO USE CONSISTENT METHOD

        // String delegateNames = '';
        String delegateNamesWithAccomodation = '';
        String delegateNamesWithExtraNight = '';
        List<String> delegateNamesWithOnlineExam = new List<String>();
        List<String> delegateNamesWithOnlineStandard = new List<String>();
        List<String> delegateNamesWithoutOnlineExam = new List<String>();

        for (TrainingDelegate__c d : delegates)
        {
            // delegateNames += d.First_Name__c + ' ' + d.Last_Name__c + '; ';
            if (d.Accommodation_Required__c)
            {
                delegateNamesWithAccomodation += (delegateNamesWithAccomodation == '' ? '' : '; ') + d.First_Name__c + ' ' + d.Last_Name__c;
            }
            if (d.Accommodation_night_before__c)
            {
                delegateNamesWithExtraNight += (delegateNamesWithExtraNight == '' ? '' : '; ') + d.First_Name__c + ' ' + d.Last_Name__c;
            }

            if (d.Online_Exam__c)
            {
                delegateNamesWithOnlineExam.add(d.First_Name__c + ' ' + d.Last_Name__c);
            }
            else
            {
                delegateNamesWithoutOnlineExam.add(d.First_Name__c + ' ' + d.Last_Name__c);
            }

            if (d.Standard__c)
            {
                delegateNamesWithOnlineStandard.add(d.First_Name__c + ' ' + d.Last_Name__c);
            }

        }

        // MD END OF THIS BIT OF SoW034

        if (booking.Number_of_Delegates__c > booking.Delegates_Inc_Exam__c)
        {
            // MD 20190315 Send the course without exam first (not sent if all delegates taking exam)
            TrainingBookingServices.TrainingBookingItem item = new TrainingBookingServices.TrainingBookingItem();
            item.Description = selectedEvent.price.Product2.Short_Name_For_Training_SMO__c;
            item.Material = ('000000000000000000' + selectedEvent.event.SMO_Service_Material__c).right(18);
            item.Quantity = (booking.Number_of_Delegates__c - booking.Delegates_Inc_Exam__c);
            item.Price = booking.Price_Per_Delegate__c;  // needs to be the course price
            item.Discount = unitDiscount * (booking.Number_of_Delegates__c - booking.Delegates_Inc_Exam__c); // ?needs to be the course price minus discount?
            item.Currency_x = booking.CurrencyIsoCode;
            item.SmoNumber = ('000000000000' + selectedEvent.event.SAP_SMO_Number__c).right(12);
            item.Delegates = String.join(delegateNamesWithoutOnlineExam, ';');
            parItems.add(item);

        }

        // 28/07/2017 ADS - SoW034 - Online Exam Enhancements - Start

        if (booking.Delegates_Inc_Exam__c > 0)
        {
            // MD 20190315 Send the course with exam next
            TrainingBookingServices.TrainingBookingItem item = new TrainingBookingServices.TrainingBookingItem();
            item.Description = selectedEvent.event.Course__r.Short_Name_For_Training_SMO_With_Exam__c; // NEW FIELD
            item.Material = ('000000000000000000' + selectedEvent.event.SMO_Service_Material__c).right(18);
            // item.Material = ('000000000000000000' + selectedEvent.Event.Course__r.Online_Exam__r.Assembly_Material__c).right(18);
            item.Quantity = booking.Delegates_Inc_Exam__c;
            item.Price = (booking.Price_Per_Delegate__c + selectedEvent.onlineExamPrice.unitPrice);
            
            item.Discount = unitDiscount * booking.Delegates_Inc_Exam__c;
            item.Currency_x = booking.CurrencyIsoCode;
            item.SmoNumber = ('000000000000' + selectedEvent.Event.SAP_SMO_Number__c).right(12);
            item.Delegates = String.join(delegateNamesWithOnlineExam, ';');
            parItems.add(item);
        }

        if (booking.Delegates_Inc_Standard__c > 0)
        {
            TrainingBookingServices.TrainingBookingItem item = new TrainingBookingServices.TrainingBookingItem();
            item.Description = selectedEvent.Event.Course__r.Online_Standard__r.Short_Name_For_Training_SMO__c;
            item.Material = ('000000000000000000' + selectedEvent.Event.Course__r.Online_Standard__r.Assembly_Material__c).right(18);
            item.Quantity = booking.Delegates_Inc_Standard__c;
            item.Price = selectedEvent.onlineStandardPrice.unitPrice;
            item.Discount = 0;
            item.Currency_x = booking.CurrencyIsoCode;
            item.SmoNumber = ('000000000000' + selectedEvent.event.SAP_SMO_Number__c).right(12);
            item.Delegates = String.join(delegateNamesWithOnlineStandard, ';');
            parItems.add(item);
        }

        // 28/07/2017 ADS - SoW034 - Online Exam Enhancements - Finish

        if (selectedEvent.event.course__r.Training_Event_Residential__c)  //JS where is this set?  Need to send the course, exam and standard then accomm then extra night
        {
            if (booking.Delegates_Inc_Accommodation__c > 0)
            {
                // then send the accomm during
                TrainingBookingServices.TrainingBookingItem item = new TrainingBookingServices.TrainingBookingItem();
                item.Description = selectedEvent.base.Product2.Short_Name_For_Training_SMO__c;
                item.Material = ('000000000000000000' + selectedEvent.base.Product2.Assembly_Material__c).right(18);   // needs to be accomm SAP material - event.Course__r.Base_Product__r.Assembly_Material__c
                item.Quantity = booking.Delegates_Inc_Accommodation__c * (selectedEvent.event.Course_Duration_days__c - 1);//This needs to be number of nights accommodation.  = No of Delegates with accommoodation during * Course Duration - 1
                item.Price = selectedEvent.base.unitPrice;// Where is this set - needs to be the price of the Course__r.Base_Product__r
                item.Discount = 0; // No discount on accomm
                item.Currency_x = booking.CurrencyIsoCode;
                item.SmoNumber = ('000000000000' + selectedEvent.event.SAP_SMO_Number__c).right(12);
                // 14 Nov 2016 Vim added delegate names who have booked accomodation
                item.Delegates = delegateNamesWithAccomodation;
                // Vim code ends here
                parItems.add(item);
            }
            if (booking.Delegates_inc_extra_night__c > 0)
            {
                // then send the extra night
                TrainingBookingServices.TrainingBookingItem item = new TrainingBookingServices.TrainingBookingItem();
                item.Description = selectedEvent.extraNightPrice.Product2.Short_Name_For_Training_SMO__c;
                item.Material = ('000000000000000000' + selectedEvent.extraNightPrice.Product2.Assembly_Material__c).right(18);   // needs to be extra night Sap Material -  event.Course__r.Extra_Night__r.Assembly_Material__c
                item.Quantity = booking.Delegates_inc_extra_night__c;//This should be the number of nights extra night accomm = No of delegates with extra night
                item.Price = selectedEvent.extraNightCost; // Where is this set - needs to be the price of Course__r.Extra_Night__r
                item.Discount = 0; // No discount on accomm
                item.Currency_x = booking.CurrencyIsoCode;
                item.SmoNumber = ('000000000000' + selectedEvent.event.SAP_SMO_Number__c).right(12);
                // 14 Nov 2016 Vim added delegate names who have booked accomodation
                item.Delegates = delegateNamesWithExtraNight;
                // Vim code ends here
                parItems.add(item);
            }
        }

        TrainingBookingServices.ArrayOfTrainingBookingItem parArrayOfItems = new TrainingBookingServices.ArrayOfTrainingBookingItem();
        parArrayOfItems.TrainingBookingItem = parItems;

        system.debug(logginglevel.ERROR, 'sapTarget: ' + selectedCountry.sapTarget + ' ordr: ' + ordr + ' shipto: ' + shipTo + ' soldTo: ' + soldTo + 'parArrayOfItems:' + parArrayOfItems);

        // Create an instance of the CreateOrder service
        if(selectedCountry.sapMethod == 'REST'){
            TrainingBookingServices.TrainingBookingServiceREST calculator = new TrainingBookingServices.TrainingBookingServiceREST();
            return calculator.CreateOrder(selectedCountry.sapTarget, dummyCall, ordr, shipTo, soldTo, parItems, selectedCountry.azureRevision);
        } else {
            TrainingBookingServices.TrainingBookingServiceSoap calculator = new TrainingBookingServices.TrainingBookingServiceSoap();
            calculator.timeout_x = 60000 ; // timeout in milliseconds

            // Add the authentication header
            TrainingBookingServices.AuthenticationHeader header = new TrainingBookingServices.AuthenticationHeader();
            SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
            header.UserName = ss.Pointglobal_Username__c;
            header.Password = ss.Pointglobal_Password__c;
            calculator.AuthenticationHeader = header;
            // Call the calculator
            return calculator.CreateOrder(selectedCountry.sapTarget, dummyCall, ordr, shipTo, soldTo, parArrayOfItems);
        }
    }

    /*
     * Get the disount per person for a Training Booking
     */
    public static Decimal getUnitDiscount(TrainingBooking__c booking)
    {
        return booking.Discount_Value__c + (booking.Price_Per_Delegate__c * booking.Discount_Percentage__c);
    }

    /*
     * Calcualate the prices for accomodation, the course, extra night fees, online exams and standards.
     */
    public static TrainingBooking__c calculateBookingPrices(TrainingBooking__c booking, TrainingBookingUtilities.EventWrapper selectedEvent)
    {
        // Declare working variables
        Boolean itemiseDiscounts = true;
        Decimal unitPriceIncAccommodation;
        Decimal sumDiscountIncAccommodation;
        Decimal unitPriceExcAccommodation;
        Decimal sumDiscountExcAccommodation;
        Decimal unitPriceNonResidential;
        Decimal sumDiscountNonResidential;

        Decimal unitDiscount = getUnitDiscount(booking);
        Decimal courseCost = (booking.Price_Per_Delegate__c * booking.Number_of_Delegates__c);
        Decimal accommodationCost = (booking.Price_Per_Delegate_Accommodation__c * booking.Delegates_Inc_Accommodation__c);
        Decimal extraNightCost = (booking.Price_Per_Delegate_Extra_Night__c * booking.Delegates_inc_extra_night__c);

        Decimal onlineExamCost = (null != booking.Price_Per_Delegate_Online_Exam__c ? booking.Price_Per_Delegate_Online_Exam__c : 0.0) *
            (null != booking.Delegates_Inc_Exam__c ? booking.Delegates_Inc_Exam__c : 0.0);
        Decimal onlineStandardCost = (null != booking.Price_Per_Delegate_Online_Standard__c ? booking.Price_Per_Delegate_Online_Standard__c : 0.0) *
            (null != booking.Delegates_Inc_Standard__c ? booking.Delegates_Inc_Standard__c : 0.0);

        // Work out pre-tax values
        if (selectedEvent.event.Course__r.Training_Event_Residential__c)
        {
            // Residential courses
            // CB 02/07/2015
            system.debug(logginglevel.ERROR, '***KD*** ENTERING METHOD TO SET NET PRICE');
            system.debug(logginglevel.ERROR, '***KD***' + courseCost);
            system.debug(logginglevel.ERROR, '***KD***' + accommodationCost);
            system.debug(logginglevel.ERROR, '***KD***' + extraNightCost);
            system.debug(logginglevel.ERROR, '***KD***' + onlineExamCost);
            system.debug(logginglevel.ERROR, '***KD***' + onlineStandardCost);
            system.debug(logginglevel.ERROR, '***KD*** END');
            booking.Net_Price__c = (courseCost + accommodationCost + extraNightCost + onlineExamCost + onlineStandardCost);
            system.debug(logginglevel.ERROR, '***KD*** NET PRICE SET TO ' + booking.Net_Price__c);
            booking.Price_Exc_Accommodation__c = courseCost+ onlineExamCost + onlineStandardCost;
            booking.Price_Inc_Accommodation__c = (courseCost + accommodationCost + extraNightCost + onlineExamCost + onlineStandardCost);
            // Separate out the discounts
            unitPriceIncAccommodation = booking.Price_Inc_Accommodation__c;
            unitPriceExcAccommodation = booking.Price_Per_Delegate__c;

            //discount shouldn't be added to accommodation
            sumDiscountIncAccommodation = unitDiscount * booking.Delegates_Inc_Accommodation__c;

            sumDiscountExcAccommodation = unitDiscount * booking.Delegates_Exc_Accommodation__c;
            booking.Discount__c = sumDiscountIncAccommodation + sumDiscountExcAccommodation;
        }
        else
        {
            // Non-residential courses
            booking.Net_Price__c = (courseCost + accommodationCost + extraNightCost+ onlineExamCost + onlineStandardCost);
            // Separate out the discounts
            unitPriceNonResidential = booking.Price_Per_Delegate__c;
            sumDiscountNonResidential = unitDiscount * booking.Number_of_Delegates__c;
            booking.Discount__c = sumDiscountNonResidential;
        }

        return booking;
    }
    //Vimlesh - 11 Oct 2016 Static Method to validate EU country code
    public static boolean validateEUCountryCodes(string countrycode)
    {
          boolean blnValidEUCountry = false;
            // Get the XML EU countries data
            StaticResource xmlEUData = [
                SELECT  s.Body
                FROM    StaticResource s
                WHERE   s.Name = 'Training_EUCountryList'
                ];
            DOM.Document xmlDoc = new DOM.Document();
            xmlDoc.load(xmlEUData.Body.toString());
            DOM.Xmlnode xmlDataRoot = xmlDoc.getRootElement();
            DOM.Xmlnode xmlEUCountries = xmlDataRoot.getChildElement('countryOptions', null);
            for (DOM.Xmlnode xmlEUCountry : xmlEUCountries.getChildElements())
            {
                string code = xmlEUCountry.getAttributeValue('code', null);
                if(code == countrycode)
                {
                  System.debug(xmlEUCountry.getAttributeValue('code', null));
                  System.debug(xmlEUCountry.getAttributeValue('name', null));
                    blnValidEUCountry = true;
                }
                //supportedEUCountries.put(xmlEUCountry.getAttributeValue('code', null), xmlEUCountry);
            }
          return blnValidEUCountry;

    }
    // Vimlesh validateEUCountryCodes(...) method code end here

    // MB - 19-Feb-2020 - methods to encrypt and decrypt data
    public static String encryptData(String data)
    {
        Blob cryptoKey = Crypto.generateAesKey(256);
        Blob val = Blob.valueOf(data);
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, val);
        return encryptedData.toString();
    }
    public static String decryptData(String encryptedString)
    {
        Blob encryptedData = Blob.valueOf(encryptedString);
        Blob cryptoKey = Crypto.generateAesKey(256);
        Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encryptedData);
        return decryptedData.toString();
    }
    // MB - 19-Feb-2020

    // CLASSES ===========================================================================================================================

    // Class for configuration details
    public class Configuration
    {
        public Map<String, String> supportedLanguages { get; set;}
        public Map<String, DOM.Xmlnode> supportedCountries { get; set; }

        public Configuration()
        {
            // Get the XML configuration data
            StaticResource xmlFile = [
                SELECT  s.Body
                FROM    StaticResource s
                WHERE   s.Name = 'TrainingBookingConfiguration'
                ];
            DOM.Document xmlConfig = new DOM.Document();
            xmlConfig.load(xmlFile.Body.toString());
            DOM.Xmlnode xmlRoot = xmlConfig.getRootElement();

            // Build Map of supported languages
            this.supportedLanguages = new Map<String, String>();
            DOM.Xmlnode xmlLanguages = xmlRoot.getChildElement('languages', null);
            for (DOM.Xmlnode xmlLanguage : xmlLanguages.getChildElements()) this.supportedLanguages.put(xmlLanguage.getAttributeValue('id', null), xmlLanguage.getAttributeValue('sfdcCode', null));

            // Build Map of supported countries
            this.supportedCountries = new Map<String, DOM.Xmlnode>();
            DOM.Xmlnode xmlCountries = xmlRoot.getChildElement('countries', null);
            for (DOM.Xmlnode xmlCountry : xmlCountries.getChildElements()) this.supportedCountries.put(xmlCountry.getAttributeValue('id', null), xmlCountry);
        }
    }

    // Class for country-specific information
    public class Country
    {
        public String id { get; set; }
        public String description { get; set; }
        public String phoneNo { get; set; }
        public String pricebookId { get; set; }
        public String currencyIsoCode { get; set; }
        public String currencyFormat { get; set; }
        public String campaign { get; set; }
        public String countryCode { get; set; }
        public String countryCodePhonePrefix { get; set; }
        public String countryCodeMobilePrefix { get; set; }
        public String countryCodeFaxPrefix { get; set; }
        public String translations { get; set; }
        public String flags { get; set; }
        public Boolean displayVat { get; set; }
        public Boolean calculateTax { get; set; }
        public Boolean isCardAllowed { get; set; }
        public Boolean isInvoiceAllowed { get; set; }
        public Boolean isCheckIpSkipped { get; set; }
        public String calculateTaxMethod { get; set; }
        //Buddy Winter <Cloudshift> 21/10/2021
        public String sapMethod { get; set; }
        public String azureRevision { get; set; }
        public String taxName { get; set; }
        public Double taxRate { get; set; }
        public String gateway { get; set; }
        public String sapTarget { get; set; }
        public String sapTimezone { get; set; }
        public String privacyUrl { get; set; }
        public String cookieUrl { get; set; }
        public String accessibilityUrl { get; set; }
        public String termsUrl { get; set; }
        public String siteMapUrl { get; set; }
        public String enquiryUrl { get; set; }
        public String bookingTermsUrl { get; set; }
        public String bookingDataPolicyUrl { get; set; }
        public Integer advanceBookingDays { get; set; }
        public List<SelectOption> countryOptions { get; set; }
        public Map<String, CountryOption> countryOptionsMap { get; set; }
        public String countryOptionsDefault { get; set; }
        public List<SelectOption> invoiceOptions { get; set; }
        public Map<String, String> invoiceOptionsMap { get; set; }
        public String invoiceOptionsDefault { get; set; }
        public Integer maxNumberOfDelegates { get; set; }
        public Integer futureEventDays { get; set; }
        public Integer showEventRows { get; set; }
        public Boolean blockCrossBorderBookings { get; set; }
        public String allowedCrossBorderCountries { get; set; }
        public String allowedPaymentCards { get; set; }
        public Boolean portalLogin { get; set; }
        public String localEntityDetails { get; set; }

        private String sapCode;

        public Country(DOM.Xmlnode myXmlCountry, String myParamLanguage, String sapCode)
        {
            // Set basic properties
            this.id = myXmlCountry.getAttributeValue('id', null);
            this.sapCode = sapCode;

            // get Custom Metadata for country
            Training_Booking_Country_Settings__mdt tbcs = [
                SELECT Id, DeveloperName, Label,
                    Accessibility_Url__c, Advance_Booking_Days__c, Booking_Data_Policy_Url__c, Booking_Terms_Url__c,
                    Calculate_Tax__c, Calculate_Tax_Method__c, Campaign__c, Card_Allowed__c, Cookie_Url__c, Country_Code_Picklist__c,
                    Currency_Format__c, Currency_Iso_Code__c, Display_Vat__c, Enquiry_Url__c, Flags__c,
                    Future_Event_Days__c, Gateway__c, Invoice_Allowed__c, Skip_IP_check__c, Max_Number_Of_Delegates__c, Phone_Number__c,
                    Pricebook__c, Privacy_Url__c, Sap_Target__c, Sap_Timezone__c, Show_Event_Rows__c, Site_Map_Url__c,
                    Tax_Name__c, Tax_Rate__c, Terms_Url__c, Translations__c, Block_Cross_Border_Bookings__c, Allowed_cross_border_Countries__c,
                  Allowed_Payment_Cards__c, Portal_Login__c, Local_Entity_Details__c, SAP_Method__c, REST_Method_Revision__c
                FROM Training_Booking_Country_Settings__mdt
                WHERE DeveloperName = :this.id
            ];

            this.description = tbcs.Label;
            this.countryCode = tbcs.Country_Code_Picklist__c;
            this.countryCodePhonePrefix = tbcs.Country_Code_Picklist__c;
            this.countryCodeMobilePrefix = tbcs.Country_Code_Picklist__c;
            this.countryCodeFaxPrefix = tbcs.Country_Code_Picklist__c;
            this.phoneNo = tbcs.Phone_Number__c;
            this.currencyIsoCode = tbcs.Currency_Iso_Code__c;
            this.currencyFormat = tbcs.Currency_Format__c;
            this.flags = tbcs.Flags__c != null ? tbcs.Flags__c : '';

            this.accessibilityUrl = tbcs.Accessibility_Url__c;
            this.bookingDataPolicyUrl = tbcs.Booking_Data_Policy_Url__c;
            this.bookingTermsUrl = tbcs.Booking_Terms_Url__c;
            this.cookieUrl = tbcs.Cookie_Url__c;
            this.enquiryUrl = tbcs.Enquiry_Url__c;
            this.privacyUrl = tbcs.Privacy_Url__c;
            this.siteMapUrl = tbcs.Site_Map_Url__c;
            this.termsUrl = tbcs.Terms_Url__c;

            this.gateway = tbcs.Gateway__c;
            this.sapTarget = tbcs.Sap_Target__c;
            this.sapTimezone = tbcs.Sap_Timezone__c;

            this.pricebookId = tbcs.Pricebook__c;
            this.campaign = tbcs.Campaign__c;
            this.translations = tbcs.Translations__c;

            this.calculateTax = tbcs.Calculate_Tax__c;
            this.calculateTaxMethod = tbcs.Calculate_Tax_Method__c;
            //Buddy Winter <Cloudshift> 21/10/2021
            this.sapMethod = tbcs.SAP_Method__c;
            this.azureRevision = tbcs.REST_Method_Revision__c;
            this.taxName = tbcs.Tax_Name__c;
            this.taxRate = tbcs.Tax_Rate__c;
            this.displayVat = tbcs.Display_Vat__c;
            this.isCardAllowed = tbcs.Card_Allowed__c;
            this.isInvoiceAllowed = tbcs.Invoice_Allowed__c;
            //EN 29/04/2021
            this.isCheckIpSkipped = tbcs.Skip_IP_check__c;
            //JE 21/01/2021
            this.blockCrossBorderBookings = tbcs.Block_Cross_Border_Bookings__c;
            this.allowedCrossBorderCountries = tbcs.Allowed_cross_border_Countries__c;
            this.allowedPaymentCards = tbcs.Allowed_Payment_Cards__c;
            this.portalLogin = tbcs.Portal_Login__c;
            this.localEntityDetails = tbcs.Local_Entity_Details__c;

            this.advanceBookingDays = tbcs.Advance_Booking_Days__c > 0 ? (Integer)tbcs.Advance_Booking_Days__c : EVENT_DEFAULT_ADVANCE_BOOKING_DAYS;
            this.futureEventDays = tbcs.Future_Event_Days__c > 0 ? (Integer)tbcs.Future_Event_Days__c : EVENT_DEFAULT_FUTURE_EVENT_DAYS;
            this.maxNumberOfDelegates = tbcs.Max_Number_Of_Delegates__c > 0 ? (Integer)tbcs.Max_Number_Of_Delegates__c : EVENT_MAX_DELEGATES;
            this.showEventRows = tbcs.Show_Event_Rows__c > 0 ? (Integer)tbcs.Show_Event_Rows__c : EVENT_MAX_ROWS_DEFAULT;

            this.countryOptions = new List<SelectOption>();
            this.countryOptionsMap = new Map<String, CountryOption>();
            this.invoiceOptions = new List<SelectOption>();
            this.invoiceOptionsMap = new Map<String, String>();

            /*
            this.description = myXmlCountry.getAttributeValue('description', null);
            this.phoneNo = myXmlCountry.getAttributeValue('phoneNo', null);
            this.emailAddress = myXmlCountry.getAttributeValue('emailAddress', null);
            this.pricebookId = myXmlCountry.getAttributeValue('pricebook', null);
            this.currencyIsoCode = myXmlCountry.getAttributeValue('currency', null);
            this.currencyFormat = myXmlCountry.getAttributeValue('currencyFormat', null);
            this.campaign = myXmlCountry.getAttributeValue('campaign', null);
            this.translations = myXmlCountry.getAttributeValue('translations', null);
            this.flags = myXmlCountry.getAttributeValue('flags', null);
            this.displayVat = (myXmlCountry.getAttributeValue('displayVat', null) == 'true');
            this.Vat2Display = (myXmlCountry.getAttributeValue('Vat2Display', null) == 'true'); //JS added for MEA and SA who use VAT Number 2 20180116
            this.calculateTax = (myXmlCountry.getAttributeValue('calculateTax', null) == 'true');
            this.isCardAllowed = (myXmlCountry.getAttributeValue('cardAllowed', null) == 'true');
            this.isInvoiceAllowed = (myXmlCountry.getAttributeValue('invoiceAllowed', null) == 'true');
            this.gateway = myXmlCountry.getAttributeValue('gateway', null);
            this.sapTarget = myXmlCountry.getAttributeValue('sapTarget', null);
            this.sapTimezone = myXmlCountry.getAttributeValue('sapTimezone', null);
            this.countryOptions = new List<SelectOption>();
            this.countryOptionsMap = new Map<String, CountryOption>();
            this.invoiceOptions = new List<SelectOption>();
            this.invoiceOptionsMap = new Map<String, String>();

            // CP 16/02/16 added advanced booking days
            String bookingDays = myXmlCountry.getAttributeValue('advanceBookingDays', null);
            this.advanceBookingDays = getIntegerValue(bookingDays, EVENT_DEFAULT_ADVANCE_BOOKING_DAYS);
            String maxDelegates = myXmlCountry.getAttributeValue('maxNumberOfDelegates', null);
            this.maxNumberOfDelegates = getIntegerValue(maxDelegates, EVENT_MAX_DELEGATES);

            // MD 04/03/18 added futureEventDays and showEventRows
            String futureEventDays = myXmlCountry.getAttributeValue('futureEventDays', null);
            this.futureEventDays  = getIntegerValue(futureEventDays, EVENT_DEFAULT_FUTURE_EVENT_DAYS);
            String showEventRows = myXmlCountry.getAttributeValue('showEventRows', null);
            this.showEventRows = getIntegerValue(showEventRows, EVENT_MAX_ROWS_DEFAULT);
            */

            // Parse children
            for (DOM.Xmlnode xmlCountryChild : myXmlCountry.getChildElements())
            {
                /*
                // Check to see if this is a navigation URL list for the supplied language
                if (xmlCountryChild.getName() == 'navigationUrls' && xmlCountryChild.getAttributeValue('lang' , null) == myParamLanguage)
                {
                    // This is the list of navigation URLs for the supplied language
                    DOM.Xmlnode xmlPrivacyUrl = xmlCountryChild.getChildElement('privacyUrl', null);
                    if (xmlPrivacyUrl != null) this.privacyUrl = xmlPrivacyUrl.getText();
                    DOM.Xmlnode xmlCookieUrl = xmlCountryChild.getChildElement('cookieUrl', null);
                    if (xmlCookieUrl != null) this.cookieUrl = xmlCookieUrl.getText();
                    DOM.Xmlnode xmlAccessibilityUrl = xmlCountryChild.getChildElement('accessibilityUrl', null);
                    if (xmlAccessibilityUrl != null) this.accessibilityUrl = xmlAccessibilityUrl.getText();
                    DOM.Xmlnode xmlTermsUrl = xmlCountryChild.getChildElement('termsUrl', null);
                    if (xmlTermsUrl != null) this.termsUrl = xmlTermsUrl.getText();
                    DOM.Xmlnode xmlSiteMapUrl = xmlCountryChild.getChildElement('siteMapUrl', null);
                    if (xmlSiteMapUrl != null) this.siteMapUrl = xmlSiteMapUrl.getText();
                    DOM.Xmlnode xmlEnquiryUrl = xmlCountryChild.getChildElement('enquiryUrl', null);
                    if (xmlEnquiryUrl != null) this.enquiryUrl = xmlEnquiryUrl.getText();
                    DOM.Xmlnode xmlBookingTermsUrl = xmlCountryChild.getChildElement('bookingTermsUrl', null);
                    if (xmlBookingTermsUrl != null) this.bookingTermsUrl = xmlBookingTermsUrl.getText();
                    DOM.Xmlnode xmlBookingDataPolicyUrl = xmlCountryChild.getChildElement('bookingDataPolicyUrl', null);
                    if (xmlBookingDataPolicyUrl != null) this.bookingDataPolicyUrl = xmlBookingDataPolicyUrl.getText();
                }
                */

                // Check to see if this is a invoice option list for the supplied language
                if (xmlCountryChild.getName() == 'invoiceOptions' && xmlCountryChild.getAttributeValue('lang', null) == myParamLanguage)
                {
                    // This is the list of valid invoice languages for the supplied language
                    this.invoiceOptionsDefault = xmlCountryChild.getAttributeValue('default', null);
                    for (DOM.Xmlnode xmlInvoiceOption : xmlCountryChild.getChildElements())
                    {
                        // Add one invoice language
                        this.invoiceOptions.add(new SelectOption(xmlInvoiceOption.getAttributeValue('id', null), xmlInvoiceOption.getAttributeValue('id', null)));
                        this.invoiceOptionsMap.put(xmlInvoiceOption.getAttributeValue('id', null), xmlInvoiceOption.getAttributeValue('sapCode', null));
                    }
                }

                // Check to see if this is a country option list for the supplied language
                if (xmlCountryChild.getName() == 'countryOptions' && xmlCountryChild.getAttributeValue('lang', null) == myParamLanguage)
                {
                    // This is the list of valid countries for the supplied language
                    for (DOM.Xmlnode xmlCountryOption : xmlCountryChild.getChildElements())
                    {
                        if (xmlCountryOption.getAttributeValue('sapCode', null) == this.sapCode) {
                            this.countryOptionsDefault = xmlCountryOption.getAttributeValue('id', null);
                        }
                        // Add one country
                        this.countryOptions.add(new SelectOption(xmlCountryOption.getAttributeValue('id', null), xmlCountryOption.getAttributeValue('id', null)));
                        this.countryOptionsMap.put(xmlCountryOption.getAttributeValue('id', null), new CountryOption(xmlCountryOption, xmlCountryChild.getAttributeValue('default', null)));
                    }
                    if (this.countryOptionsDefault == null) {
                        this.countryOptionsDefault = xmlCountryChild.getAttributeValue('default', null);
                    }
                }
            }
        }

        /*
         * Get the integer value from a string if the string isn't a number use the default integer passed in
         */
        private Integer getIntegerValue(String numberString, Integer defaultInteger)
        {
            Integer integerValue = defaultInteger;
            if (numberString.isNumeric())
            {
                integerValue = Double.valueOf(numberString).round().intValue();
            }
            return integerValue;
        }
    }

    // Class for country drop-down options
    public class CountryOption
    {
        public String id { get; set; }
        public String sapCode { get; set; }
        public String pcRegex { get; set; }
        public Boolean rgRequired { get; set; }
        public List<SelectOption> regionOptions { get; set; }
        public Map<String, String> regionOptionsMap { get; set; }

        public CountryOption(DOM.Xmlnode myXmlCountryOption, String myDefault)
        {
            // Set basic properties
            this.id = myXmlCountryOption.getAttributeValue('id', null);
            this.sapCode = myXmlCountryOption.getAttributeValue('sapCode', null);
            this.pcRegex = myXmlCountryOption.getAttributeValue('pcRegex', null);

            // Build Map of region options
            this.rgRequired = false;
            this.regionOptions = new List<SelectOption>();
            this.regionOptionsMap = new Map<String, String>();
            DOM.Xmlnode xmlRegionOptions = myXmlCountryOption.getChildElement('regionOptions', null);
            if (xmlRegionOptions != null)
            {
              // See whether region is required
              this.rgRequired = (xmlRegionOptions.getAttributeValue('required', null) == 'true');

                // This is the list of valid regions
                this.regionOptions.add(new SelectOption('', ''));
                for (DOM.Xmlnode xmlRegionOption : xmlRegionOptions.getChildElements())
                {
                    // Add one region
                    this.regionOptions.add(new SelectOption(xmlRegionOption.getAttributeValue('id' , null), xmlRegionOption.getAttributeValue('id' , null)));
                    this.regionOptionsMap.put(xmlRegionOption.getAttributeValue('id' , null), xmlRegionOption.getAttributeValue('sapCode' , null));
                }
            }
        }
    }

    // Wrapper class for Training Events
    public class EventWrapper
    {
        public Training_Event__c event { set; get; }
        public PricebookEntry price { set; get; } // Course price
        public PricebookEntry base { set; get; } // Accomdation Price
        public PricebookEntry premiumPrice { set; get; } // premium price
        public PricebookEntry extraNightPrice { set; get; } // extra night price

        public PricebookEntry onlineExamPrice { set; get; }
        public PricebookEntry onlineStandardPrice { set; get; }

        public Integer freeSeats { set; get; }
        public Boolean shortNotice { set; get; }

        private String flags;

       // 28/07/2017 ADS - SoW034 - Online Exam Enhancements - Start
        public Boolean onlineExamAvailable {
            get {
                return null != this.event.Course__r.Online_Exam__c;
            }
        }

        public Decimal onlineExamCost {
            get {
                Decimal total = 0.0;

                if (null != onlineExamPrice && onlineExamAvailable)
                {
                    total = onlineExamPrice.UnitPrice;
                }

                return total.setScale(2);
            }
        }

        public Boolean onlineStandardAvailable {
            get {
                return null != this.event.Course__r.Online_Standard__c;
            }
        }

        public Decimal onlineStandardCost {
            get {
                Decimal total = 0.0;

                if (null != onlineStandardPrice && onlineStandardAvailable)
                {
                    total = onlineStandardPrice.UnitPrice;
                }

                return total.setScale(2);
            }
        }
        // 28/07/2017 ADS - SoW034 - Online Exam Enhancements - Finish

        public Boolean accommodationAvailable {
            get{
                Boolean accommAvail = false;
                // if the event is not excluded from online booking and the course is enabled for online booking
                if(!event.Exclude_from_online_booking__c && event.Course__r.Enable_Online_Booking__c)
                {
                    // if the status is not pending or cancelled
                    if(EVENT_STATUS_PLANNING != event.Event_status__c && EVENT_STATUS_CANCELLED != event.Event_status__c)
                    {
                        if(event.Accommodation_available_for_this_event__c && null != event.Course__r.Base_Product__c && event.Course_Duration_days__c > 1)
                        {
                            if(event.Remaining_Accommodation__c >= 1)
                            {
                                accommAvail = true;
                            }
                        }
                    }
                }
                return accommAvail;
            }
        }

        public Boolean extraNightAvailable {
            get{
                Boolean accommAvail = false;
                // if the event is not excluded from online booking and the course is enabled for online booking
                if(!event.Exclude_from_online_booking__c && event.Course__r.Enable_Online_Booking__c)
                {
                    // if the status is not pending or cancelled
                    if(EVENT_STATUS_PLANNING != event.Event_status__c && EVENT_STATUS_CANCELLED != event.Event_status__c)
                    {
                        if(null != event.Course__r.Extra_Night__c && event.Accommodation_available_for_this_event__c)
                        {
                            if(event.Remaining_Accommodation__c >= 1)
                            {
                                accommAvail = true;
                            }
                        }
                    }
                }
                return accommAvail;
            }
        }

        public Decimal totalPriceCourse {
          get
            {
                Decimal total = 0;
                if(null!=price)
                {
                    total = price.unitPrice;
                }
                if(null!=premiumPrice && event.Premium_Priced_Event__c)
                {
                    if(null!=event.Course_Duration_days__c)
                    {
                        total = total  + (premiumPrice.UnitPrice * event.Course_Duration_days__c);
                    }
                    else
                    {
                        total = total + premiumPrice.UnitPrice;
                    }
                }
                if(String.isNotBlank(flags) && flags.contains('IncludeExam')) total += onlineExamCost;
                return total.setScale(2);
            }
        }

        public Decimal accommodationCost {
            get
            {
                Decimal total = 0;
                if(null!=base && event.Accommodation_available_for_this_event__c)
                {
                    total = base.unitPrice;
                }
                if(null!=event.Course_Duration_days__c)
                {
                    if(event.Course_Duration_days__c > 1)
                    {
                        total = total * (event.Course_Duration_days__c -1);
                    }
                }
                return total.setScale(2);
            }
        }

        public Decimal extraNightCost {
            get
            {
                Decimal total = 0;
                if(null!=extraNightPrice)
                {
                    total = extraNightPrice.unitPrice;
                }
                return total.setScale(2);
            }
        }

        public Decimal totalPriceWithAccom {
          get
            {
                Decimal total = 0;
                if(null!=base)
                {
                    total = (totalPriceCourse + accommodationCost);
                }
                return total;
            }
        }

        public Decimal totalPriceWithExtraNight {
          get
            {
                Decimal total = 0;
                if(null!=extraNightPrice)
                {
                    total = (totalPriceCourse + extraNightCost);
                }
                return total;
            }
        }

        public Decimal totalPriceWithAccomAndExtraNight {
          get
            {
                Decimal total = 0;
                if(null!=extraNightPrice && null!=base)
                {
                    total = (totalPriceCourse + accommodationCost + extraNightCost);
                }
                return total;
            }
        }

        public EventWrapper(TrainingBooking__c pTrainingBooking)
        {
            Set<Id> pbeIds = new Set<Id>();

            this.event = eventDetails(pTrainingBooking.Training_Event__c);

            pbeIds.add(pTrainingBooking.Pricebook_Entry__c);
            pbeIds.add(pTrainingBooking.Pricebook_Inc_Accommodation__c);
            pbeIds.add(pTrainingBooking.Pricebook_Entry_Extra_Night__c);
            pbeIds.add(pTrainingBooking.Pricebook_Entry_Premium_Product__c);
            pbeIds.add(pTrainingBooking.Pricebook_Entry_Online_Exam__c);
            pbeIds.add(pTrainingBooking.Pricebook_Entry_Online_Standard__c);

            Map<Id,PricebookEntry> eventCoursePricebookEntryMap = new Map<Id,PricebookEntry>();
            for(PricebookEntry pbe : [SELECT Id,
                                             Product2Id,
                                             UnitPrice,
                                             Product2.Short_Name_For_Training_SMO__c,
                                             Product2.Assembly_Material__c
                                      FROM PricebookEntry
                                      WHERE Id IN : pbeIds])
            {
                eventCoursePricebookEntryMap.put(pbe.Product2Id,pbe);
            }

            if(eventCoursePricebookEntryMap.containsKey(this.event.Course__c))
            {
                price = eventCoursePricebookEntryMap.get(this.event.Course__c);
            }

            if(eventCoursePricebookEntryMap.containsKey(this.event.Course__r.Base_Product__c))
            {
                base = eventCoursePricebookEntryMap.get(this.event.Course__r.Base_Product__c);
            }

            if(eventCoursePricebookEntryMap.containsKey(this.event.Course__r.Extra_Night__c))
            {
                extraNightPrice = eventCoursePricebookEntryMap.get(this.event.Course__r.Extra_Night__c);
            }

            if(eventCoursePricebookEntryMap.containsKey(this.event.Course__r.Premium_Product__c))
            {
                premiumPrice = eventCoursePricebookEntryMap.get(this.event.Course__r.Premium_Product__c);
            }

            if(eventCoursePricebookEntryMap.containsKey(this.event.Course__r.Online_Exam__c))
            {
                onlineExamPrice = eventCoursePricebookEntryMap.get(this.event.Course__r.Online_Exam__c);
            }

            if(eventCoursePricebookEntryMap.containsKey(this.event.Course__r.Online_Standard__c))
            {
                onlineStandardPrice = eventCoursePricebookEntryMap.get(this.event.Course__r.Online_Standard__c);
            }

            // Is this short notice?
            setShortNotice(EVENT_DEFAULT_ADVANCE_BOOKING_DAYS);

            // Calculate availability
            Integer maxSeats = (null != this.event.Max_seats__c) ? this.event.Max_seats__c.intValue() : 0;
            Integer enrollmentCount = (null != this.event.Enrollment_Count__c) ? this.event.Enrollment_Count__c.intValue() : 0;
            Integer onHoldForPayment = (null != this.event.On_Hold_for_Payment__c) ? this.event.On_Hold_for_Payment__c.intValue() : 0;
            Integer enrollmentPending = (null != this.event.Enrollment_Pending__c) ? this.event.Enrollment_Pending__c.intValue() : 0;

            this.freeSeats = (maxSeats - (enrollmentCount + onHoldForPayment + enrollmentPending));
        }

        public EventWrapper(Training_Event__c pEvent, Map<Id,PricebookEntry> pPricebookEntryMap)
        {
            this.event = pEvent;
            system.debug(logginglevel.ERROR, '##$$ TBU : event - '+this.event);

            if(null != this.event.Course__c)
            {
                if(pPricebookEntryMap.containsKey(this.event.Course__c))
                {
                    price = pPricebookEntryMap.get(this.event.Course__c);
                }
            }
            if(null != this.event.Course__r.Base_Product__c)
            {
                if(pPricebookEntryMap.containsKey(this.event.Course__r.Base_Product__c))
                {
                    base = pPricebookEntryMap.get(this.event.Course__r.Base_Product__c);
                }
            }
            if(null != this.event.Course__r.Extra_Night__c)
            {
                if(pPricebookEntryMap.containsKey(this.event.Course__r.Extra_Night__c))
                {
                    extraNightPrice = pPricebookEntryMap.get(this.event.Course__r.Extra_Night__c);
                }
            }
            if(null != this.event.Course__r.Premium_Product__c)
            {
                if(pPricebookEntryMap.containsKey(this.event.Course__r.Premium_Product__c))
                {
                    premiumPrice = pPricebookEntryMap.get(this.event.Course__r.Premium_Product__c);
                }
            }
            if(null != this.event.Course__r.Online_Exam__c)
            {
                if(pPricebookEntryMap.containsKey(this.event.Course__r.Online_Exam__c))
                {
                    onlineExamPrice = pPricebookEntryMap.get(this.event.Course__r.Online_Exam__c);
                }
            }
            if(null != this.event.Course__r.Online_Standard__c)
            {
                if(pPricebookEntryMap.containsKey(this.event.Course__r.Online_Standard__c))
                {
                    onlineStandardPrice = pPricebookEntryMap.get(this.event.Course__r.Online_Standard__c);
                }
            }

            // Is this short notice?
            setShortNotice(EVENT_DEFAULT_ADVANCE_BOOKING_DAYS);

            Integer maxSeats = (null != this.event.Max_seats__c) ? this.event.Max_seats__c.intValue() : 0;
            Integer enrollmentCount = (null != this.event.Enrollment_Count__c) ? this.event.Enrollment_Count__c.intValue() : 0;
            Integer onHoldForPayment = (null != this.event.On_Hold_for_Payment__c) ? this.event.On_Hold_for_Payment__c.intValue() : 0;
            Integer enrollmentPending = (null != this.event.Enrollment_Pending__c) ? this.event.Enrollment_Pending__c.intValue() : 0;

            // Calculate availability
            this.freeSeats = (maxSeats - (enrollmentCount + onHoldForPayment + enrollmentPending));
        }

        // country flag constructor
        public EventWrapper(Training_Event__c pEvent, Map<Id,PricebookEntry> pPricebookEntryMap, String flags)
        {
            this(pEvent, pPricebookEntryMap);
            this.flags = flags;
        }

        // Default constructor
        public EventWrapper(Training_Event__c myEvent, PricebookEntry MyPrice, PricebookEntry myBase)
        {
            // Set basic properties
            this.event = myEvent;
            this.price = myPrice;
            this.base = null;

            // Only show accommodation options if price is with and base is without
            if (myEvent.Accommodation_available_for_this_event__c && myBase != null && myPrice.Product2.Training_Event_Residential__c && !myBase.Product2.Training_Event_Residential__c)
            {
                this.base = myBase;
                /* 21/11/2014 NF */
                Decimal accommodationPrice = base.UnitPrice;
                Decimal priceWithoutAccomm = price.UnitPrice;

                PricebookEntry pbe = new PricebookEntry();
                pbe.Pricebook2Id = myBase.Pricebook2Id;
                pbe.Product2Id = myBase.Product2Id;
                pbe.Id = myBase.Id;
                this.base = pbe;

                PricebookEntry coursePbe = new PricebookEntry();
                coursePbe.Product2Id = myPrice.Product2Id;
                coursePbe.Id = myPrice.Id;
                coursePbe.UnitPrice = priceWithoutAccomm;
                this.price = coursePbe;


                base.UnitPrice = priceWithoutAccomm;
                //price.UnitPrice += accommodationPrice;
                if(myEvent.Course_Duration_Days__c > 1)
                {
                  price.UnitPrice += (accommodationPrice * (myEvent.Course_Duration_Days__c - 1));
                }
                /* END */
            }

            // Calculate availability
            this.freeSeats = myEvent.Max_Seats__c.intValue() - myEvent.Enrollment_Count__c.intValue() - myEvent.On_Hold_for_Payment__c.intValue() - myEvent.Enrollment_Pending__c.intValue();

            // Is this short notice?EVENT_DEFAULT_ADVANCE_BOOKING_DAYS
            setShortNotice(EVENT_DEFAULT_ADVANCE_BOOKING_DAYS);
        }

        // Fixed price constructor
        public EventWrapper(Id eventId, Id mainPbe, Id basePbe, String currencyIsoCode, Decimal mainPrice, Decimal basePrice)
        {
            this.event = eventDetails(eventId);
            if (basePbe == null)
            {
                // Not residential
                this.price = new PricebookEntry();
                this.price.CurrencyIsoCode = currencyIsoCode;
                this.price.unitPrice = mainPrice;
                this.base = null;
            }
            else
            {
                // Residential
                this.price = new PricebookEntry();
                this.price.CurrencyIsoCode = currencyIsoCode;
                this.price.UnitPrice = mainPrice;
                this.base = new PricebookEntry();
                this.base.CurrencyIsoCode = currencyIsoCode;
                this.base.UnitPrice = basePrice;
            }
            this.freeSeats = 0;
            this.shortNotice = false;
        }

        //Set short notice if the event is within the advanced booking days
        public void setShortNotice(Integer advanceBookingDays)
        {
            this.shortNotice = Date.today().daysBetween(this.event.Start_Date__c) < advanceBookingDays;
            return;
        }

    }
}