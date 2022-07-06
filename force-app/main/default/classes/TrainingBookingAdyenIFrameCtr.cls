public with sharing class TrainingBookingAdyenIFrameCtr{
    // Parameters (transient except those used by 'invoice instead' link)
    public transient Map<String, String> params { get; set; }
    public transient String paramMode { get; set; }
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

    // Adyen constants
    private transient String API_KEY;
    private transient String ENDPOINT;
    private transient String MERCHANT_ACCOUNT;
    public transient String CLIENT_KEY { get; set; }
    public transient String ENVIRONMENT { get; set; }
    public transient String LOCALE { get; set; }

    public String returnURL { get; set; }
    public String redirectResponse { get; set; }
    public PaymentResponse paymentStatus { get; set; }

    public String paymentMethods { get; set; }

    static final String ENCODING = 'UTF-8';

    // Default constructor
    public TrainingBookingAdyenIFrameCtr() {
        System.debug('### TrainingBookingAdyen');

        // Set defaults
        this.pageIsValid = true;
        this.pageLanguage = 'en_US';
        this.pageStep = 5;
        this.pageUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/training/TrainingBookingAdyen';

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
        setReturnURL();
        // Get Adyen custom settings values
        System.debug(this.selectedCountry);
        Adyen_Settings__c adyenCS = Adyen_Settings__c.getInstance(this.selectedCountry.description);
        API_KEY = adyenCS.API_KEY__c;
        MERCHANT_ACCOUNT = adyenCS.MERCHANT_ACCOUNT__c;
        CLIENT_KEY = adyenCS.CLIENT_KEY__c;
        ENVIRONMENT = adyenCS.ENVIRONMENT__c;
        LOCALE = adyenCS.LOCALE__c;
        ENDPOINT = adyenCS.ENDPOINT__c;

        // Build a DirectLink request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT + '/v66/paymentMethods');
        req.setMethod('POST');
        req.setCompressed(false);

        PaymentMethodRequest pmr = new PaymentMethodRequest(
            MERCHANT_ACCOUNT,
            this.paramCountry,
            this.objBooking.currencyIsoCode,
            this.objBooking.Total_Price__c,
            'Web',
            this.pageLanguage
        );

        // Send the request and read response (support test class)
        req.setBody(JSON.serialize(pmr).replace('"currency_x":', '"currency":'));
        req.setHeader('Content-Type', 'content-type: application/json');
        req.setHeader('x-API-key', API_KEY);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            this.paymentMethods = res.getBody();
            system.debug('Adyen Response ' + res.getBody());
        } catch(System.CalloutException e) {
            System.debug('Callout error: '+ e);
        }

        // logic to check if payment details callout is required
        if(String.isNotBlank(params.get('redirectResult'))) {
            this.redirectResponse = getPaymentDetails(params.get('redirectResult'));
        }
    }

    // executes payment details callout to Adyen and returns repsonse to VF page
    public String getPaymentDetails(String encodedRedirectResult) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT + '/v67/payments/details');
        req.setMethod('POST');
        req.setCompressed(false);
        req.setBody('{"details": {"redirectResult": "' + encodedRedirectResult + '"}}');
        req.setHeader('Content-Type', 'content-type: application/json');
        req.setHeader('x-API-key', API_KEY);
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Adyen Response: ' + res.getBody());
            this.paymentStatus = (PaymentResponse) JSON.deserialize(res.getBody(), PaymentResponse.class);
            return res.getBody();
        } catch(System.CalloutException e) {
            System.debug('Callout error: '+ e);
            return null;
        }
    }

    // method to execute payment callout to Adyen and return response to VF page
    @RemoteAction
    public static PaymentResponse makePayment(String paymentData, String currencyIsoCode, Decimal paymentAmount, String reference, String returnURL, String selectedCountry) {
        PaymentResponse paymentResponse;
        Adyen_Settings__c adyenCS = Adyen_Settings__c.getInstance(selectedCountry);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(adyenCS.ENDPOINT__c + '/v67/payments');
        req.setMethod('POST');
        req.setCompressed(false);
		req.setBody(buildPaymentRequest(paymentData, currencyIsoCode, paymentAmount, reference, adyenCS.MERCHANT_ACCOUNT__c, returnURL));
        req.setHeader('Content-Type', 'content-type: application/json');
        req.setHeader('x-API-key', adyenCS.API_KEY__c);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Adyen Response ' + res.getBody());
            paymentResponse = (PaymentResponse) JSON.deserialize(res.getBody(), PaymentResponse.class);
            System.debug(paymentResponse);
        } catch(System.CalloutException e) {
            System.debug('Callout error: '+ e);
        }
        return paymentResponse;
    }

    // Builds json String for payment callout request
    private static String buildPaymentRequest(String paymentData, String currencyIsoCode, Decimal paymentAmount, String reference, String merchantAccount, String returnURL) {
        PaymentMethod paymentDetails = (PaymentMethod) JSON.deserialize(paymentData, PaymentMethod.class);
        Map<String, Object> body;
        if(paymentDetails.type == 'kcp_creditcard') {
            body = new Map<String, Object>{
                'amount'=>new Map <String, Object>{
                    'currency'=>currencyIsoCode,
                    'value'=>paymentAmount
                },
                'reference'=>reference,
                'paymentMethod'=>new Map<String, Object>{
                    'type'=>paymentDetails.type
                },
                'returnUrl'=>returnURL,
                'merchantAccount'=>merchantAccount
            };
        } else {
            body = new Map<String, Object>{
                'amount'=>new Map <String, Object>{
                    'currency'=>currencyIsoCode,
                    'value'=>paymentAmount
                },
                'reference'=>reference,
                'paymentMethod'=>new Map<String, Object>{
                    'type'=>paymentDetails.type,
                    'holderName'=>paymentDetails.holderName,
                    'encryptedCardNumber'=>paymentDetails.encryptedCardNumber,
                    'encryptedExpiryMonth'=>paymentDetails.encryptedExpiryMonth,
                    'encryptedExpiryYear'=>paymentDetails.encryptedExpiryYear,
                    'encryptedSecurityCode'=>paymentDetails.encryptedSecurityCode
                },
                'returnUrl'=>returnURL,
                'merchantAccount'=>merchantAccount
            };
        }
        System.debug(JSON.serialize(body));
        return JSON.serialize(body);
    }

    // Execute option to invoice instead
    public PageReference invoiceInstead() {
        TrainingBooking__c booking = TrainingBookingUtilities.bookingDetails(paramId);
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
        updatePaymentDetails();
        TrainingBookingUtilities.sapOrder(paramId);
        PageReference ref = Page.TrainingBooking6;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true);
        return ref;
    }

    // Set return URL for redirect payments
    public void setReturnURL() {
        PageReference ref = Page.TrainingBookingAdyen;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        this.returnURL = ref.getUrl();
    }

    private void addErr(String errMsg) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
    }

    // To update the payment fields on the training booking record after payment is successfully taken
    public void updatePaymentDetails() {
        TrainingBooking__c booking = TrainingBookingUtilities.bookingDetails(paramId);
        booking.Payment_Method__c = 'Card';
        booking.Payment_Order_No__c = this.paymentStatus.pspReference;
        booking.Payment_Status__c = this.paymentStatus.resultCode;
        booking.Convert_To_On_Hold__c = false;
        update booking;
    }

    // Return the error page
    public PageReference errorPage() {
        PageReference ref = Page.TrainingBooking7;
        ref.getParameters().put('ID', paramId);
        ref.getParameters().put('CT', paramCountry);
        ref.getParameters().put('L', paramLanguage);
        ref.setRedirect(true);
        return ref;
    }

    public class PaymentMethodRequest {
        public String merchantAccount;
        public String countryCode;

        public TrainingBookingAdyenIFrameCtr.PaymentMethodRequestAmount amount;
        public String channel;
        public String shopperLocale;

        public PaymentMethodRequest(
            String merchantAccount,
            String countryCode,
            String currencyVal,
            Decimal value,
            String channel,
            String shopperLocale
        ) {
            this.merchantAccount    = merchantAccount;
            this.countryCode        = countryCode;
            this.amount = new TrainingBookingAdyenIFrameCtr.PaymentMethodRequestAmount();
            amount.currency_x       = currencyVal;
            amount.value            = value;
            this.channel            = channel;
            this.shopperLocale      = shopperLocale;
        }
    }

    public class PaymentMethod {
        public String type;
        public String holderName;
        public String encryptedCardNumber;
        public String encryptedExpiryMonth;
        public String encryptedExpiryYear;
        public String encryptedSecurityCode;
    }

    public class PaymentResponse {
        public String pspReference;
        public String resultCode;
        public String merchantReference;
        public String refusalReason;
        public Action action;
    }

    public class Action {
        public String paymentMethodType;
        public String url;
        public String method;
        public String type;
    }

    public class PaymentMethodRequestAmount {
        public String currency_x;
        public Decimal value;
    }
}