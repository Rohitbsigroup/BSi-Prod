/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-01-18
* @group CloudShiftGroup
* @description - Visualforce page controller used for the Asperato payment gateway
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 18/01/2021    Jadd Ennaciri      Created Class
*
*/

public without sharing class TrainingBookingAsperatoGatewayController {
    
    // URL params
    public transient Map<String, String> params { get; set; }
    public transient String paramMode { get; set; }
    public String paramLanguage { get; set; }
    public String paramCountry { get; set; }
    public String paramId { get; set; }
    public String paramPaymentId { get; set; }
    
    // Page settings
    public transient String pageUrl { get; set; }
    public transient Boolean pageIsValid { get; set; }
    public transient String pageLanguage { get; set; }
    public transient Integer pageStep { get; set; }
    public transient Boolean pageShowSelection { get; set; }
    
    // Asperato payment record
    public asp04__Payment__c asperatoPayment { get; set; }
    public String paymentUrl { get; set; }
    
    // accepted card types
    public Boolean showVisa { get; set; }
    public Boolean showMastercard { get; set; }
    public Boolean showAmex { get; set; }
    public Boolean showDiners { get; set; }
    public Boolean showDiscover { get; set; }
    public Boolean showCup { get; set; }
    public Boolean showJcb { get; set; }
    public Boolean showGrabpay { get; set; }
    public Boolean showPayeasy { get; set; }
    public Boolean showAfterpay { get; set; }
    
    public transient String courseName { get; set; }
    public transient Boolean courseAccommodation { get; set; }
    public transient TrainingBooking__c objBooking { get; set; }
    public TrainingBookingUtilities.Country selectedCountry { get; set; }
    public transient TrainingBookingUtilities.EventWrapper selectedEvent { get; set; }
    
    public TrainingBookingAsperatoGatewayController() {
        // Set defaults
        pageIsValid = true;
        pageLanguage = 'en_US';
        pageStep = 5;
        pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingAsperatoGatewayController';
        
        params = ApexPages.currentPage().getParameters();
        System.debug(params);
        paramMode = params.get('MODE');
        paramLanguage = params.get('L');
        paramCountry = params.get('CT');
        paramId = params.get('ID');
        paramPaymentId = params.get('paymentId');
        
        asperatoPayment = [
            SELECT Id, asp04__eCommerce_URL__c, asp04__Company_Name__c, asp04__First_Name__c, asp04__Last_Name__c
            FROM asp04__Payment__c
            WHERE Id = :this.paramPaymentId
            LIMIT 1
        ];
        paymentUrl = asperatoPayment.asp04__eCommerce_URL__c.substringBetween('"', '"').replace('&amp;','&');
        
        // Set payment gateway language - JS set TW to zh-tw
        
        if (paramCountry == 'TW')
        {
          paymentUrl = paymentUrl + '&locale=' + 'zh-tw' /*paramLanguage*/;
        }
        else
        {
            paymentUrl = paymentUrl + '&locale=' + paramLanguage;
        }        
        
        system.debug('### payment URL: ' + paymentUrl);
        
         // Get the configuration
        TrainingBookingUtilities.Configuration config = new TrainingBookingUtilities.Configuration();

        // Validate the language parameter
        if (paramLanguage == null || !config.supportedLanguages.containsKey(paramLanguage.toUpperCase())) {
            // Language cannot be identified - Return invalid page
            pageIsValid = false;
            return;
        }

        // Set the SFDC page language
        pageLanguage = config.supportedLanguages.get(paramLanguage.toUpperCase());

        // Validate the country parameter
        if (paramCountry == null || !config.supportedCountries.containsKey(paramCountry.toUpperCase())) {
            // Country cannot be identified - Return invalid page
            pageIsValid = false;
            return;
        }

        // Get the country-specific settings
        selectedCountry = new TrainingBookingUtilities.Country(config.supportedCountries.get(paramCountry.toUpperCase()), paramLanguage.toUpperCase(), '');
        
        // check allowed payment cards and set flags
        if(String.isNotBlank(this.selectedCountry.allowedPaymentCards)) {
            checkAcceptedCards();
        }
        
        // Validate the id parameter
        if (String.isBlank(paramId)) {
            // Booking cannot be identified - Return invalid page
            pageIsValid = false;
            return;
        }
        // Populate from an existing Booking Event
        objBooking = TrainingBookingUtilities.bookingDetails(paramId);
        if(objBooking == null) {
            // Booking cannot be identified - Return invalid page
            pageIsValid = false;
            return;
        }

        // Re-populate the Course/Event details
        courseAccommodation = objBooking.Is_Residential__c;
        if(courseAccommodation) {
            selectedEvent = new TrainingBookingUtilities.EventWrapper(objBooking.Training_Event__c, objBooking.Pricebook_Inc_Accommodation__c, objBooking.Pricebook_Exc_Accommodation__c, objBooking.CurrencyIsoCode, objBooking.Price_Inc_Accommodation__c, objBooking.Price_Exc_Accommodation__c);
        } else {
            selectedEvent = new TrainingBookingUtilities.EventWrapper(objBooking.Training_Event__c, objBooking.Pricebook_Entry__c, null, objBooking.CurrencyIsoCode, objBooking.Price_Per_Delegate__c, null);
        }
        courseName = selectedEvent.event.Course__r.Product_Name_Local__c;
            
        // Re-populate the page settings
        pageShowSelection = !(selectedEvent.event.Course__r.Delivery_Method__c == 'Distance Learning' || selectedEvent.event.Course__r.Delivery_Method__c == 'eLearning');
    }
    
    // Execute option to invoice instead
    public PageReference invoiceInstead() {
        TrainingBooking__c booking = TrainingBookingUtilities.bookingDetails(paramId);
        // check if the payment has been made for the order
        if(String.isNotBlank(booking.Payment_Order_No__c) ) {
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
    
    // method to handle Invoice payment action
    public PageReference successPageInvoiced() {
        PageReference ref = Page.TrainingBooking6;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true); 
        return ref;
    }
    
    // Return the confirmation page
    public PageReference successPage() {
        this.updatePaymentDetails();
        TrainingBookingUtilities.sapOrder(objBooking.Id);
        PageReference ref = Page.TrainingBooking6;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true);
        return ref;
    }
    
    // To update the payment fields on the training booking record after payment is successfully taken
    public void updatePaymentDetails() {
        asp04__Payment__c paymentDetails = [
            SELECT Id, asp04__Payment_Stage__c, asp04__Payment_Route_Selected__c, asp04__Card_Type__c, asp04__PSP_Reference__c, asp04__Asperato_Reference__c
            FROM asp04__Payment__c
            WHERE Id = :this.paramPaymentId
            LIMIT 1
        ];
        objBooking = TrainingBookingUtilities.bookingDetails(this.paramId);
        objBooking.Payment_Method__c = paymentDetails.asp04__Payment_Route_Selected__c;
        objBooking.Payment_Order_No__c = paymentDetails.asp04__PSP_Reference__c;
        objBooking.Payment_Status__c = paymentDetails.asp04__Payment_Stage__c == 'Collected from customer' ? 'Paid Online' : paymentDetails.asp04__Payment_Stage__c;
        objBooking.Payment_card__c = paymentDetails.asp04__Card_Type__c;
        objBooking.Payment_Name__c = paymentDetails.asp04__Asperato_Reference__c;
        objBooking.Convert_To_On_Hold__c = false;
        update objBooking;
    }
    
    // Return the error page
    public PageReference errorPage() {
        this.updatePaymentDetails();
        PageReference ref = Page.TrainingBooking7;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true);
        return ref;
    }  
    
    // Return the payment cancelled page
    public PageReference paymentCancelledPage() {
        this.updatePaymentDetails();
        objBooking.Payment_Status__c = 'Cancelled';
        update objBooking;
        PageReference ref = Page.TrainingBookingPaymentCancelled;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true);
        return ref;
    }   
    
    public PageReference validatePage() {
        // this will check for page errors
        if(!pageIsValid) return errorPage();
        return null;        
    }
    
    private void addErr(String errMsg) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
    }
    
    // check allowed card types and set flags
    public void checkAcceptedCards() {
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('visa')) {
            this.showVisa = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('mastercard')) {
            this.showMastercard = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('amex')) {
            this.showAmex = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('diners')) {
            this.showDiners = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('discover')) {
            this.showDiscover = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('cup')) {
            this.showCup = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('jcb')) {
            this.showJcb = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('grabpay')) {
            this.showGrabpay = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('payeasy')) {
            this.showPayeasy = true;
        }
        if(this.selectedCountry.allowedPaymentCards.toLowerCase().contains('afterpay')) {
            this.showAfterpay = true;
        }
    }
}