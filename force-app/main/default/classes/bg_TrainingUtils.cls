/********************************************************************
 * bg_TrainingUtils
 *
 * Apex utilities for training functionality
 * 
 * Unit Tests: bg_TrainingUtilsTEST
 *
 * Author: Nick Fisher
 * Created: 30-10-2014
 * Changes: 
 *  Alexis Lignereux - 10-12-2014
 *      Added the following methods:
 *          trainingEventInstructorAssignmentMessage
 *          productUpdateTrainingEventInstructorMessage
 *          contactUpdateTrainingEventInstructorMessage
 *  Alexis Lignereux - 22-12-2015
 *      Added the following methods:
 *          createConvertEnrollment
 *          getRecordTypeId
 *  Nick Fisher - 04-02-2015
 *      Added method: deleteOrphanedTrainingBookings
 *  Nick Fisher - 11-02-2015
 *      Added method: getEventsForCourse
 *  Richard Jimenez - 25-02-2015
 *      Updated instructor check - observing tutor must have i-codes
 *  Nick Fisher - 22-04-2015
 *      Added SMO Scheduled Date calculation and population
 *  Nick Fisher - 08-05-2015 RJ: REMOVED - CAUSING BUG IN BOOKING
 *      Added check to quote parts to ensure accomodation lines
 *      do not have training bookings created
 *  Chris Bacon - 10-06-2015
 *      Added WrapperClass
 *          TrainingBookingConversionWrapper
 *      Added the following methods for Training Booking Conversion
 *          fetchBookingsWithDelegatesForConversion
 *          createConversionAccount
 *          createConversionContact
 *          createConversionOpportunity
 *          createConversionOppContactRole
 *          createDelegateContacts
 *          createOppLineItems
 *          createEnrollmentsForDelegates
 *  Chris Bacon - 25-06-2015
 *      Commented syncTrainingBookings
 *      Reworked a copy of syncTrainingBookings
 *      Created class QuoteWrapper in order to syncTrainingBookings
 *      Reworked populateTrainingBooking to handle syncTrainingBookings
 *      Reworked syncDelegatesWithTrainingBooking to cater for accommodation and extra night checkboxes on creation
 *      Created new method deriveEnrollmentAccomodationFromDelegate
 *      Created new method fetchRelatedOppLineItemMap
 *  Chris Bacon - 26-06-2015
 *      Reworked a copy of syncTrainingBookings to group quote parts to their training bookings 
 *  Chris Bacon - 29-06-2015
 *      Reworked a copy of syncDelegatesWithTrainingBooking (createDelegatesForTrainingBooking) updated after insert trigger on training booking to call this method
 *      
 *  ASD BrightGen   02-02-16    Made change : populateTrainingEvent() to accept Decimal instead of Integer.
 *  Josh Adams      17-02-16    Made changes to  isReadyToConvert(), createEnrollmentsForDelegates, createConversionOpportunity for changes in case 23827
 *  ASD BrightGen   18-05-16    Made changes as per case 25516
 *  JT BrightGen    10-08-16    Made changes to populateTrainingEvent() to populate the quote id, 
 *                              createEnrollmentsForDelegates to populate the relatedTrainingDelegate__c field on the enrollment,
 *                              createConversionOpportunity modified parameters to take an extra boolean as per case 26482,
 *                              createConversionAccount added call to new method updateConversionAccount,
 *                              fetchBookingsWithDelegatesAndQuotePartsForConversion, added new fields to SOQL call as per case 26482
 *                              New method - updateConversionAccount
 *  JK BrightGen    20-07-17    Updated Lead Source constants to represent new values
 *  MD BSI          27-03-18    COPIED SoW034 UPDATES FROM DEV3
 *                              (ADS BrightGen  28/07/2017  SoW034 - Online Exam Enhancements)
 *  JS BSI          04-06-18    Altered syncDelegatesWithTrainingBooking to query exams and standards
 *  PC K2           08-08-18    added manageEventConfirmation()
 *  PC K2           20-09-18    added support for Manage Government Incentive
 *  PC K2           20-09-18    modified Phone and Mobile support
 *  JS              03-12-18    added a year to the SoW034 lookup for event
 *  JS              03-12-18    commented out code for sales price on ENR
 *  MD              29-01-19    Changes to sale price code in createEnrollmentsForDelegates
 *  MD              30-01-19    Changed setSMOScheduledDate for Project 56 (Online Exam Bookings)
 *  JS              01-04-19    Pulled in Bespoke Course Name for Certificate to map to training event and also Company for in-house course
 *  JS              05-04-19    Updated from DEV to clean up code.
 *  JS              10-08-19    Added line to set flag for exam delegates on ILT ENR
 *  JS              01-04-20    Add in Virtual Learning as a format
 *  PC K2           14-05-20    Added manageMimeoDistributionAssignment, createMimeoDistribution
 ********************************************************************/
public class bg_TrainingUtils 
{
    public static boolean firstRun = true;
    public static Boolean isMimeoDistributionAssignmentFirstRun = true;

    public static final string CONTACT_MASTER_SAP_RECORD_TYPE = 'BSI SAP Master';
    public static final string ACOUNT_CONTACT_RECORD_TYPE = 'Account Contacts';
    public static final string ENROLMENT_E_LEARING_RECORD_TYPE = 'E-Learning';
    public static final string ENROLMENT_E_LEARING_DEVELOPER_RECORD_TYPE = 'E_Learning';
    public static final string ENROLMENT_DISTANCE_LEARNING_RECORD_TYPE = 'Distance Learning';
    public static final string ENROLMENT_INSTRUCTOR_LED_TRAINING_RECORD_TYPE = 'Instructor Led Training';
    public static final string ENROLMENT_BOOKING_STATUS_BOOKED = 'Booked';
    public static final string ENROLMENT_BOOKING_STATUS_BOOKED_RESIT = 'Booked - Resit';
    public static final string ENROLMENT_BOOKING_STATUS_ONHOLD_PAYMENT = 'On Hold - Payment';
    public static final string ENROLMENT_BOOKING_STATUS_ONHOLD_RESIT = 'On Hold - Payment (Resit)';

    public static final string ENROLMENT_ACCOMODATION_DURING = 'During';
    public static final string ENROLMENT_ACCOMODATION_NIGHT_BEFORE_AND_DURING = 'Night before and during';
    public static final string ENROLMENT_ACCOMODATION_NIGHT_BEFORE = 'Night before';
    public static final string ENROLMENT_ACCOMODATION_NON_RESIDENTIAL = 'Non-Residential';
    public static final string ENROLMENT_INVOICE_STATUS_PENDING = 'Pending';
    public static final string ENROLMENT_INVOICE_STATUS_PAYMENT_RECEIVED = 'Payment Received';
    
    public static final String COURSE_FORMAT_ILT = 'ILT';
    public static final String COURSE_FORMAT_DISTANCE_LEARNING = 'Distance Learning';
    public static final String COURSE_FORMAT_VIRTUAL_LEARNING = 'Virtual Learning'; //JS added 01042020
    public static final String COURSE_FORMAT_E_LEARNING = 'E-Learning';
    public static final String COURSE_FORMAT_BLENDED_LEARNING = 'Blended Learning';
    public static final String COURSE_FORMAT_WEBINAR = 'Webinar';
    public static final String COURSE_FORMAT_OTHER = 'Other';
    
    public static final String TRAINING_PRODUCT_CERTIFIED_AUDITOR = 'Certified Auditor';
    public static final String TRAINING_PRODUCT_EXTRA_MATERIALS = 'Extra Materials Charge';
    public static final String TRAINING_PRODUCT_EXPENSES = 'Expenses';
    public static final String TRAINING_PRODUCT_CERTIFIED_CHARGE = 'Certified Charge';
    public static final String TRAINING_PRODUCT_CERTIFICATE = 'Certificate';
    public static final String TRAINING_PRODUCT_STANDARDS = 'Standards';
    public static final String TRAINING_PRODUCT_COURSE_DEV = 'Course Development';
    public static final String TRAINING_PRODUCT_EXAM_MARKING = 'Exam Marking';
    public static final String TRAINING_PRODUCT_TRAVEL_TIME = 'Travel Time';

    public static final String INTERNAL_SALES_PAYMENT_METHOD = 'Invoice';
    public static final String INTERNAL_BOOKING_ROUTE = 'Internal Sales';
    public static final String ONLINE_BOOKING_ROUTE = 'Online';
    public static final String CONVERSION_OPPORTUNITY_STAGENAME = 'Closed Won';
    public static final String CONVERSION_OPPORTUNITY_REGISTRATION_PATH = 'Training';
    public static final String CONVERSION_OPPORTUNITY_LEADSOURCE_BSI_WEBSITE = 'Marketing Channels';
    public static final String CONVERSION_OPPORTUNITY_LEADSOURCE_MARKETING = 'Marketing Channels';
    public static final String CONVERSION_OPPORTUNITY_LEADSOURCE_SUB_WEBSITE = 'Website';
    public static final String CONVERSION_OPPORTUNITY_CUSTOMERTYPE_TRAINING = 'Training';
    public static final String CONVERSION_TRAININGBOOKING_CONVERTED_STATUS = 'Converted';
    public static final String CONVERSION_TRAININGBOOKING_OPEN_STATUS = 'Open';
    public static final String CONVERSION_OPPCONTACTROLE_STATUS = 'Training Course Delegate';
    public static final String ONHOLD_DESCRIPTION = 'On Hold';
    public static final String BOOKING_PAYMENT_PHONE = 'Paid online';
    public static final String BOOKING_PAYMENT_ONLINE = 'Paid on phone';
    public static final String OPP_STAGE_NAME_CLOSED_PROCESSING = 'Closed Processing';
    public static final String STAGENAME_IN_PROGRESS = 'In Progress';

    public static final String QUOTEPART_PRODATTRIBUTE_TRAININGCOURSE = 'TrainingCourse';
    public static final String QUOTEPART_PRODATTRIBUTE_ACCOMMODATION = 'TrainingAccommodation';
    public static final String QUOTEPART_PRODATTRIBUTE_EXTRANIGHT = 'TrainingExtraNight';
    
    public static final String RECORD_TYPE_TRAINING_PRODUCT = 'Training_Course';

    public static final string OBSERVER_TUTOR_OBSERVING = 'Observing';

    public static final string INFO_PARAM_EVENT_CODE   = 'Event Code';
    private static final string INFO_PARAM_DATE         = 'Date';
    private static final string INFO_PARAM_DURATION     = 'Duration';
    private static final string INFO_PARAM_MAX_SEATS    = 'Max Seats';
    private static final string INFO_PARAM_ACCOMODATION = 'Accomodation';
    private static final string INFO_PARAM_BESPOKE_NAME    = 'Bespoke Name'; //JS added 20190402

    public static string ADHOC_TRAINING   = 'ADHOC-TRAIN';
    public static string INHOUSE_TRAINING = 'INHOUSE-TRAIN';

    private static final integer DEFAULT_DURATION_DAYS = 1;

    public static final string TRAINING_STATUS_PLANNING = 'Planning';
    
    //25516
    public static final string QUOTEPART_PRODATTRIBUTE_TUTORTRAVEL = 'TravelTime';
    public static final string QUOTEPART_PRODATTRIBUTE_COURSEDEV = 'DevTime';
    
    // Case 26482
    public static final string TRAINING_PUBLIC = 'Training Public';

    public class trainingException extends Exception{}

    /*
     *  Method to create training delegates against a training booking
     */
    public static void createDelegatesForTrainingBooking(Map<Id, TrainingBooking__c> bookings)
    {
        List<TrainingDelegate__c> delegatesToInsert = new List<TrainingDelegate__c>();

        for(TrainingBooking__c tb : bookings.values())
        {   
            Integer accommodationCount = 0;
            Integer extraNightCount = 0;
            Integer onlineExamCount = 0;
            Integer onlineStandardCount = 0;
            if(tb.Quote__c != null) //Stops creation of blank delegates for web bookings
            {
                for(Integer i = 0 ; i < tb.Number_of_Delegates__c ; i++)
                {
                    TrainingDelegate__c td = createDelegate(tb);

                    if(accommodationCount < tb.Delegates_Inc_Accommodation__c)
                    {
                        td.Accommodation_Required__c = true;
                        accommodationCount++;
                    }
                    if(extraNightCount < tb.Delegates_Inc_Extra_Night__c)
                    {
                        td.Accommodation_night_before__c = true;
                        extraNightCount++;
                    }
                    if (onlineExamCount < tb.Delegates_inc_exam__c)
                    {
                        td.Online_Exam__c = true;
                        onlineExamCount++;
                    }
                    if (onlineStandardCount < tb.Delegates_inc_standard__c)
                    {
                        td.Standard__c = true;
                        onlineStandardCount++;
                    }
                        
                    delegatesToInsert.add(td);
                }
            }
        }
        Database.insert(delegatesToInsert);
    }
     
    public static void syncDelegatesWithTrainingBooking(Map<Id, TrainingBooking__c> pBookings)
    {
        List<TrainingDelegate__c> delegatesToInsert = new List<TrainingDelegate__c>();
        Map<Id, List<TrainingDelegate__c>> delegateMap = new Map<Id, List<TrainingDelegate__c>>();
        
        for(TrainingDelegate__c td : [SELECT Id, Name, Training_Booking__c, Accommodation_Required__c, Accommodation_night_before__c, Online_Exam__c, Standard__c //JS 04062018 added online exam and standard
                                      FROM TrainingDelegate__c
                                      WHERE Training_Booking__c IN :pBookings.keySet()])
        {
            if(!delegateMap.containsKey(td.Training_Booking__c)) delegateMap.put(td.Training_Booking__c, new List<TrainingDelegate__c>());
            delegateMap.get(td.Training_Booking__c).add(td);
        }

        for(TrainingBooking__c tb : pBookings.values()){   
            Integer accommodationCount = 0;
            Integer extraNightCount = 0;
            Integer onlineExamCount = 0;
            Integer onlineStandardCount = 0;

            //Stops creation of blank delegates for web bookings
            if(tb.Quote__c != null){
                if(!delegateMap.containsKey(tb.Id)){
                    //No delegates currently exist
                    for(Integer i = 0 ; i < tb.Number_of_Delegates__c ; i++) delegatesToInsert.add(createDelegate(tb));
                }
                else if(delegateMap.get(tb.Id).size() < tb.Number_of_Delegates__c){
                    for(TrainingDelegate__c td : delegateMap.get(tb.Id)){
                        if(td.Accommodation_Required__c) accommodationCount = accommodationCount + 1;
                        if(td.Accommodation_night_before__c) extraNightCount = extraNightCount + 1;
                        if(td.Online_Exam__c) onlineExamCount = onlineExamCount + 1;
                        if(td.Standard__c) onlineStandardCount = onlineStandardCount + 1;
                    }

                    //Create additional delegates
                    for(Integer i = delegateMap.get(tb.Id).size(); i < tb.Number_of_Delegates__c; i++) delegatesToInsert.add(createDelegate(tb));
                }
            }
            system.debug('### Accommodation Count : '+accommodationCount);
            system.debug('### tb.Delegates_Inc_Accommodation__c : '+tb.Delegates_Inc_Accommodation__c);
            system.debug('### extraNightCount Count : '+extraNightCount);
            system.debug('### tb.Delegates_Inc_Extra_Night__c : '+tb.Delegates_Inc_Extra_Night__c);
            for(TrainingDelegate__c td : delegatesToInsert)
            {
                if(accommodationCount < tb.Delegates_Inc_Accommodation__c)
                {
                    td.Accommodation_Required__c = true;
                    accommodationCount = accommodationCount+1;
                }
                if(extraNightCount < tb.Delegates_Inc_Extra_Night__c)
                {
                    td.Accommodation_night_before__c = true;
                    extraNightCount = extraNightCount+1;
                }
                if(onlineExamCount < tb.Delegates_inc_exam__c)
                {
                    td.Online_Exam__c = true;
                    onlineExamCount = onlineExamCount+1;
                }
                if(onlineStandardCount < tb.Delegates_inc_standard__c)
                {
                    td.Standard__c = true;
                    onlineStandardCount = onlineStandardCount+1;
                }
            }
        }
        insert(delegatesToInsert);
    }

    /*
     *  Method to create a blank training delegate against a training booking
     */
    public static TrainingDelegate__c createDelegate(TrainingBooking__c tb)
    {
        TrainingDelegate__c td = new TrainingDelegate__c();
        td.Training_Booking__c = tb.Id;
        return td;
    }

    private static boolean IsEventCode(string infoVal) 
    {
        return (!String.IsBlank(infoVal) && 
                infoVal.contains('Event Code') &&
                infoVal.split(':').size() == 2);
    }

    public class quotePartWrapper
    {
        // CB - created this wrapper to keep all related info for a quote together for the quotepart to object creation/update process
        public TrainingBooking__c tb {get; set;}
        public List<Quote_Part__c> quoteParts {get; set;}
        public Training_Event__c te {get; set;}
        public Account account {get; set;}
        public Contact contact {get; set;}

        public quotePartWrapper(TrainingBooking__c pTrainingBooking, List<Quote_Part__c> pQuoteParts, Training_Event__c pTrainingEvent, Account pAccount, Contact pContact)
        {
            this.tb = pTrainingBooking;
            this.quoteParts = pQuoteParts;
            this.te = pTrainingEvent;
            this.account = pAccount;
            this.contact = pContact;
        }
    }

    public static void syncTrainingBookingsv2(map<Id, Quote_Part__c> qpMap)
    {
        System.debug('James ****************************************************************');
        Map<Id, Quote_Part__c> quotePartMap = new Map<Id, Quote_Part__c>([
                                                                          SELECT Id,
                                                                                 Quote_Ref__c,
                                                                                 AccountId__c,
                                                                                 ContactId__c,
                                                                                 InfoTxt__c,
                                                                                 InfoVal1__c,
                                                                                 InfoVal2__c,
                                                                                 InfoVal3__c,
                                                                                 InfoVal4__c,
                                                                                 InfoVal9__c,
                                                                                 IsTraining__c,
                                                                                 Training_Booking__c,
                                                                                 Quote_Product__c,
                                                                                 ProductAttribute__c,
                                                                                 OpportunityId__c,
                                                                                 Price__c,
                                                                                 Number__c,
                                                                                 Total_Price__c,
                                                                                 Product2__c,
                                                                                 Product2__r.Training_Product_Type__c,
                                                                                 Product_Name__c,
                                                                                 Country_Code__c 
                                                                          FROM Quote_Part__c
                                                                          WHERE Id IN :qpMap.keySet()]);

        // reworked this method - please see the deprecated commented method above
        Set<TrainingBooking__c> trainingBookingsToUpsert = new Set<TrainingBooking__c>();
        list<Training_Event__c> trainingEventsToUpsert = new list<Training_Event__c>();

        Map<Id, Quote_Part__c> trainingQuotePartMap = new Map<Id, Quote_Part__c>();
        Map<Id, Quote_Part__c> adhocTrainingQuotePartMap = new Map<Id, Quote_Part__c>();
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> trainingBookingIds = new Set<Id>();

        Map<String,List<Quote_Part__c>> quoteProductAndPartNumber_QuoteParts = new Map<String,List<Quote_Part__c>>();
        Map<Id,List<Quote_Part__c>> TrainingBookingId_QuoteParts = new Map<Id,List<Quote_Part__c>>();
        List<quotePartWrapper> qpws = new List<quotePartWrapper>();

        for(Quote_Part__c qp : quotePartMap.values()){
            quoteIds.add(qp.Quote_Ref__c);
            if(null != qp.AccountId__c) accountIds.add(qp.AccountId__c);
            if(null != qp.ContactId__c) contactIds.add(qp.ContactId__c);
            if(null != qp.Training_Booking__c) trainingBookingIds.add(qp.Training_Booking__c);
        }
        
        // get any existing training bookings
        Map<Id,TrainingBooking__c> tbMap = new Map<Id,TrainingBooking__c>([SELECT Id,
                                                                                  Name,
                                                                                  Quote__c,
                                                                                  Training_Event__c,
                                                                                  Training_Event__r.Name,
                                                                                  Conversion_Account__c,
                                                                                  Conversion_Contact__c,
                                                                                  Conversion_Opportunity__c,
                                                                                  Training_Event__r.Course__r.Training_Translations__c
                                                                           FROM TrainingBooking__c
                                                                           WHERE Id IN :trainingBookingIds
                                                                           OR Quote__c IN :quoteIds]);

        for(TrainingBooking__c tb : tbMap.Values())
        {
            accountIds.add(tb.Conversion_Account__c);
            contactIds.add(tb.Conversion_Contact__c);
        }
        
        // get related accounts
        Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id, 
                                                                 Name,
                                                                 NameLocal,
                                                                 BillingStreet,
                                                                 BillingCity,
                                                                 BillingCountry,
                                                                 BillingPostalCode,
                                                                 BillingState 
                                                          FROM Account 
                                                          WHERE Id IN :accountIds]);

        // get related contacts
        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id,
                                                                 Salutation,
                                                                 FirstName,
                                                                 FirstNameLocal,
                                                                 LastName,
                                                                 LastNameLocal,
                                                                 Title,
                                                                 Phone,
                                                                 Email,
                                                                 MobilePhone,
                                                                 Fax,
                                                                 MailingStreet,
                                                                 MailingCity,
                                                                 MailingCountry,
                                                                 MailingPostalCode,
                                                                 MailingState 
                                                          FROM Contact 
                                                          WHERE Id IN :contactIds]);

        // whip round each quote part       
        for(Quote_Part__c qp : quotePartMap.values()) 
        {
            // is this quote part related to training
            // RJ Uncommented: if(qp.IsTraining__c /* && IsEventCode(qp.InfoVal1__c) */)
            if(qp.IsTraining__c && IsEventCode(qp.InfoVal1__c))
            {
                Boolean foundRelatedBooking = false;
                String quotePartEventName = GetInfoValue(INFO_PARAM_EVENT_CODE, qp).trim();
                // Create collections for wrapper creation

                // if the quote part is not related to a training booking (new quote part) then we need to group the quote parts together
                if(null==qp.Training_Booking__c)
                {
                    // even though this is a new quote part it may be related to an existing booking - could be an additional quote part fired in from the configurator i.e. accommodation
                    for(TrainingBooking__c etb : tbMap.values())
                    {
                        // if the quote parts quote reference and training event name is the same as an existing training booking
                        if(etb.Quote__c == qp.Quote_Ref__c && etb.Training_Event__r.Name == quotePartEventName)
                        {
                            foundRelatedBooking = true;
                            if(!TrainingBookingId_QuoteParts.containsKey(etb.Id))
                            {
                                // if not insert tb id as key with empty list of quote part
                                List<Quote_Part__c> qps = new List<Quote_Part__c>();
                                TrainingBookingId_QuoteParts.put(etb.Id, qps);
                            }
                            // fish out list by tb id and add qp to list
                            TrainingBookingId_QuoteParts.get(etb.Id).add(qp);
                        }
                    }
                    if(!foundRelatedBooking)
                    {
                        // get unique grouping number (number at end of product attribute field)
                        Integer quotePartNumber = deriveQuotePartNumber(qp);
                        // we need to use a composite key in order to group the quote parts together to handle multiple configurators - 1 quote product per configurator
                        // does the map contain the composite key of quoteProductId_groupingNumber
                        if(!quoteProductAndPartNumber_QuoteParts.containsKey(qp.Quote_Product__c + '_' + quotePartNumber))
                        {
                            // if not then insert the key and an empty list of quote part
                            List<Quote_Part__c> quoteParts = new List<Quote_Part__c>();
                            quoteProductAndPartNumber_QuoteParts.put(qp.Quote_Product__c + '_' + quotePartNumber, quoteParts);
                        }
                        // fish out our list by key and add the qp
                        quoteProductAndPartNumber_QuoteParts.get(qp.Quote_Product__c + '_' + quotePartNumber).add(qp);
                    }

                }
                else // quote part is already linked to a training booking - populate map TrainingBookingId -> List<Quote_Part__c>
                {
                    //does map contain tb id
                    if(!TrainingBookingId_QuoteParts.containsKey(qp.Training_Booking__c))
                    {
                        // if not insert tb id as key with empty list of quote part
                        List<Quote_Part__c> qps = new List<Quote_Part__c>();
                        TrainingBookingId_QuoteParts.put(qp.Training_Booking__c, qps);
                    }
                    // fish out list by tb id and add qp to list
                    TrainingBookingId_QuoteParts.get(qp.Training_Booking__c).add(qp);
                }
                // collections built

                trainingQuotePartMap.put(qp.Id, qp);
                if(GetInfoValue(INFO_PARAM_EVENT_CODE, qp) == ADHOC_TRAINING || GetInfoValue(INFO_PARAM_EVENT_CODE, qp) == INHOUSE_TRAINING) 
                {
                    //adhocTrainingQuotePartMap.put(qp.Id, qp);
                    //25516 Replaced above line with the following
                    if(!qp.ProductAttribute__c.contains(QUOTEPART_PRODATTRIBUTE_TUTORTRAVEL) && !qp.ProductAttribute__c.contains(QUOTEPART_PRODATTRIBUTE_COURSEDEV) && !(qp.ProductAttribute__c.contains('OnlineExam')&& qp.InfoTxt__c.contains('INHOUSE'))) // JS 20190410 added in In-House exam
                    {
                        adhocTrainingQuotePartMap.put(qp.Id, qp);
                    }
                }
            }
        }
        map<string, Training_Event__c> trainingEventMap = getTrainingEvents(trainingQuotePartMap);

        // create / update adhoc training events
        if(!adhocTrainingQuotePartMap.isEmpty()) {
            for(Quote_Part__c qp : adhocTrainingQuotePartMap.values()) {
                trainingEventsToUpsert.add(populateTrainingEvent(trainingEventMap.get(qp.Id), qp));
            }

            if(!trainingEventsToUpsert.isEmpty()) {
                try {
                    Database.upsert(trainingEventsToUpsert);
                } catch(Exception e) {
                    throw new trainingException('Failed to Insert/Update Training Event: ' + e.getMessage());
                }
            }
        }

        // re-populate map with any new events just added
        trainingEventMap = getTrainingEvents(trainingQuotePartMap);

        // create wrappers for unlinked quote parts collection
        for(String compositeKey : quoteProductAndPartNumber_QuoteParts.keySet())
        {
            Training_Event__c te = null;
            List<Quote_Part__c> groupedQuoteParts = quoteProductAndPartNumber_QuoteParts.get(compositeKey);
            Contact con = null;
            Account acc = null;

            // we need to derive the related account, contact and training event from the quote parts (as they are grouped they should be identical)
            for(Quote_Part__c qp : groupedQuoteParts)
            {
                // whip through the quote parts until find the event, contact and account - this should break after 1 iteration - this is in for belts and braces
                if(null != te && null != con && null != acc) break;

                String quotePartEventName = GetInfoValue(INFO_PARAM_EVENT_CODE, qp).trim();
                // QuotePart event name for public events example : TE-00000001
                // QuotePart event name for inhouse events example : INHOUSE or ADHOC 
                // we can pull out the events by either eventname (public events) or quotepart id (inhouse events)

                // public event
                if(trainingEventMap.containsKey(quotePartEventName)) te = trainingEventMap.get(quotePartEventName);

                // inhouse event
                if(trainingEventMap.containsKey(qp.Id)) te = trainingEventMap.get(qp.Id);

                if(null == te) throw new trainingException('Training Event does not exist in Salesforce: ' + qp);

                if(accountMap.ContainsKey(qp.AccountId__c)) acc = accountMap.get(qp.AccountId__c);
                if(contactMap.ContainsKey(qp.ContactId__c)) con = contactMap.get(qp.ContactId__c);
            }
            quotePartWrapper qpw = new quotePartWrapper(null, groupedQuoteParts, te, acc, con);
            qpws.add(qpw);
        }

        // create wrappers for linked quote parts collection
        for(Id TbId : TrainingBookingId_QuoteParts.keySet())
        {
            Training_Event__c te = null;
            TrainingBooking__c tb = tbMap.get(TbId);
            List<Quote_Part__c> tbQuoteParts = TrainingBookingId_QuoteParts.get(TbId);
            Account acc = accountMap.get(tb.Conversion_Account__c);
            Contact con = contactMap.get(tb.Conversion_Contact__c);
            if(trainingEventMap.containsKey(tb.Training_Event__r.Name))
            {
                te = trainingEventMap.get(tb.Training_Event__r.Name);
            }
            if(null==te)
            {
                String quotePart_TrainingEventName = null;
                for(Quote_Part__c qp : tbQuoteParts)
                {
                    if(qp.Product2__r.Training_Product_Type__c == 'Training Course')
                    {
                        Map<String,String> infoValueMap = fetchInfovalueMap(qp);
                        if(infoValueMap.containsKey(INFO_PARAM_EVENT_CODE))
                        {
                            if(trainingEventMap.containsKey(infoValueMap.get(INFO_PARAM_EVENT_CODE)))
                            {
                                te = trainingEventMap.get(infoValueMap.get(INFO_PARAM_EVENT_CODE));
                                break;
                            }
                            
                        }
                    }
                }
            }

            if(null == te) throw new trainingException('Training Event does not exist in Salesforce: ' + tb.Training_Event__r.Name);

            quotePartWrapper qpw = new quotePartWrapper(tb, tbQuoteParts, te, acc, con);
            qpws.add(qpw);
        }

        // whip round the wrappers collection adding/updating the training bookings
        for(quotePartWrapper qpw : qpws)
        {
            qpw.tb = populateTrainingBooking(qpw.tb, qpw.quoteParts, qpw.te, qpw.account, qpw.contact);
            trainingBookingsToUpsert.add(qpw.tb);    
        }
        try
        {
            List<TrainingBooking__c> tbsForUpsert = new List<TrainingBooking__c>();
            tbsForUpsert.addAll(trainingBookingsToUpsert);
            Database.upsert(tbsForUpsert);
            List<Quote_Part__c> qpsForUpdate = new list<Quote_Part__c>();
            Set<Training_Event__c> uniqueTesForUpdate = new Set<Training_Event__c>();
            List<Training_Event__c> tesForUpdate = new list<Training_Event__c>();
            for(quotePartWrapper qpw : qpws)
            {
                // the trainingEvents will have had their expense field updated during TrainingBooking creation
                uniqueTesForUpdate.add(qpw.te);
                for(Quote_Part__c qp : qpw.quoteParts)
                {
                    if(null == qp.Training_Booking__c)
                    {
                        qp.Training_Booking__c = qpw.tb.Id;
                        qpsForupdate.add(qp);
                    }
                }
            }
            tesForUpdate.addAll(uniqueTesForUpdate);
            // lock the trigger to prevent a second run of code
            Utility.lockQuotePartTrigger = true;
            update qpsForupdate;
            update tesForUpdate;
        }
        catch(Exception e)
        {
            throw new trainingException('Failed to Insert/Update Training Booking: ' + e.getMessage());
        }
    }

    public static Integer deriveQuotePartNumber(Quote_Part__c pQuotePart)
    {
        Integer retVal = null;
        String last2CharsOfProdAttribute = null;
        if(null != pQuotePart.ProductAttribute__c)
        {
            last2CharsOfProdAttribute = pQuotePart.ProductAttribute__c.right(2);
    
            if(last2CharsOfProdAttribute.isNumeric()) retVal = Integer.ValueOf(last2CharsOfProdAttribute);
            else if(last2CharsOfProdAttribute.right(1).isNumeric()) retVal = Integer.ValueOf(last2CharsOfProdAttribute.right(1));
        }
        return retVal;
    }
    /*
     *  Method to create or update a training event record with quote part details
     */
     
    public static RecordType GetTrainingEventRecordType(string configuratorName, string country)
    {
        String recordTypeName;
        RecordType retVal = null;

        String configuratorSettingName = country+'-'+configuratorName;

        TrainingConfiguratorDefaults__c trainingConfigDefaults = (null != TrainingConfiguratorDefaults__c.getValues(configuratorSettingName)) ? TrainingConfiguratorDefaults__c.getValues(configuratorSettingName) : TrainingConfiguratorDefaults__c.getValues(configuratorName);
        
        if(null != trainingConfigDefaults) recordTypeName = trainingConfigDefaults.TrainingEventRecordTypeDevName__c; 
        if(null != recordTypeName) retVal = bg_RecordTypeUtils.GetRecordTypes('Training_Event__c').get(recordTypeName);

        /*if(country == 'GB')
        {
            if(configuratorName == 'Training Global' || configuratorName == 'Training Bespoke')
            {
                recordTypeName = 'UK_In_House'; 
            }
        }
        else
        {
            if(configuratorName == 'Training Global')
            {
                recordTypeName = 'Global_Training_Event';   
            } 
            else if(configuratorName == 'Training Bespoke')
            {
                recordTypeName = 'Global_Training_Event_Bespoke';
            }
        }*/
        return retVal;
    }
    
    public static Training_Event__c populateTrainingEvent(Training_Event__c te, Quote_Part__c qp) 
    {
        Training_Event__c result = new Training_Event__c();
        if(te != null) result = te;

        RecordType eventRecType = GetTrainingEventRecordType(qp.Product_Name__c, qp.Country_Code__c);
        if(null != eventRecType) result.RecordTypeId = eventRecType.Id;
        
        result.Event_Status__c = TRAINING_STATUS_PLANNING;
        result.Training_Venue__c =null;
        result.Quote_Part__c = qp.Id;
        result.Course__c = qp.Product2__c;        
        result.Company_for_In_House_Course__c = qp.AccountId__c; //JS 2019/04/01
                
        // Only populate duration for Bespoke training
        if(GetInfoValue(INFO_PARAM_EVENT_CODE, qp) == ADHOC_TRAINING) {
            //result.Duration_days__c = integer.valueOf(GetInfoValue(INFO_PARAM_DURATION, qp, string.valueOf(DEFAULT_DURATION_DAYS)));
            result.Duration_days__c = decimal.valueOf(GetInfoValue(INFO_PARAM_DURATION, qp, string.valueOf(DEFAULT_DURATION_DAYS)));
            result.Bespoke_Course_Name_for_Certificate__c = string.valueOf(GetInfoValue(INFO_PARAM_BESPOKE_NAME, qp, string.valueOf(qp.InfoVal9__c.removeStart('Bespoke Name:')))); //JS 2019/04/02
            //JS 2019/04/01 result.Bespoke_Course_Name_for_Certificate__c = qp.InfoTxt__c; 
        }
        
        result.Max_seats__c = integer.valueOf(GetInfoValue(INFO_PARAM_MAX_SEATS, qp, string.valueOf(qp.Number__c)));
        result.Start_Date__c = bg_DateUtils.ConvertStringToDate(GetInfoValue(INFO_PARAM_DATE, qp, string.valueOf(date.today())), bg_DateUtils.DATEFORMAT_01);
        
        //25516
        result.Training_Translations__c = result.Course__r.Training_Translations__c;

        //26482
        result.Quote__c = qp.Quote_Ref__c;

        return result;
    }

    public static Map<String,String> fetchInfovalueMap(Quote_Part__c qp)
    {
        Map<String,String> infoValueMap = new Map<String,String>();
        if(null != qp.InfoTxt__c)
        {
            for(String keyValuePair : qp.InfoTxt__c.split(';'))
            {
                List<String> key_value = keyValuePair.split(':');
                if(2 == key_value.Size()) infoValueMap.put(key_value[0],key_value[1]);
            }
        }
        return infoValueMap;
    }

    private static string GetInfoValue(string paramName, Quote_Part__c qp) {
        return  GetInfoValue(paramName, qp, '');
    }

    private static string GetInfoValue(string paramName, Quote_Part__c qp, string defaultValue) {
        /*
            Return Info field value
        */
        string infoValue = '';

        if(paramName == INFO_PARAM_EVENT_CODE) infoValue = GetInfoValue(qp.InfoVal1__c);
        else if(paramName == INFO_PARAM_DATE) infoValue = GetInfoValue(qp.InfoVal2__c);
        else if(paramName == INFO_PARAM_DURATION) infoValue = GetInfoValue(qp.InfoVal3__c);
        else if(paramName == INFO_PARAM_MAX_SEATS) infoValue = GetInfoValue(qp.InfoVal4__c);
        else if(paramName == INFO_PARAM_BESPOKE_NAME) infoValue = GetInfoValue(qp.InfoVal9__c); //JS added 20190402

        return (string.isBlank(infoValue) ? defaultValue : infoValue);
    }

    public static string GetInfoValue(string infoVal) {
        /*
            Return Info field value
        */
        string result = '';
        if(!string.isBlank(infoVal)) {
            list<string> infoVals = infoVal.split(':');
            if(infoVals.size() == 2) result = infoVals[1].trim();
        }
        return result;
    }

    /*
     *  Method to create or update a training booking record with quote part details
     */
    public static TrainingBooking__c populateTrainingBooking(TrainingBooking__c tb, List<Quote_Part__c> qps, Training_Event__c te, Account acc, Contact con)
    {
        TrainingBooking__c result = new TrainingBooking__c();
        if(tb != null) result = tb;

        Decimal TotalPrice = 0;
        Decimal TotalPriceExcludingAccomodation = 0;
        Id QuoteRef = null;
        Id OppId = null;
        Boolean expensesIncluded = false;

        // price info
        for(Quote_Part__c qp : qps)
        {
            Integer delegatesIncAccommodation = 0;
            Integer delegatesIncExtraNight = 0;
            Integer delegatesIncExam = 0;
            Map<String,String> infoValueMap = fetchInfovalueMap(qp);
            String eventCode = null;
            if(infoValueMap.containsKey(INFO_PARAM_EVENT_CODE)) eventCode = infoValueMap.get(INFO_PARAM_EVENT_CODE);
            if(null==QuoteRef) QuoteRef = qp.Quote_Ref__c;
            if(null==OppId) OppId = qp.OpportunityId__c;
            if(qp.ProductAttribute__c.contains(QUOTEPART_PRODATTRIBUTE_TRAININGCOURSE)){
                // this quote part is the course and not an accomodation line item

                // is this an inhouse generated quote part
                if(ADHOC_TRAINING == eventCode || INHOUSE_TRAINING == eventCode)
                {
                    //Integer delegatesIncAccommodation = 0;
                    if(infoValueMap.containsKey('Accomodation')) delegatesIncAccommodation = Integer.valueOf(infoValueMap.get('Accomodation'));
                    if(infoValueMap.containsKey('Extra Nights')) delegatesIncExtraNight = Integer.valueOf(infoValueMap.get('Extra Nights'));
                    if(infoValueMap.containsKey('Examination')) delegatesIncExam = Integer.valueOf(infoValueMap.get('Examination'));
                    result.Delegates_Inc_Accommodation__c = delegatesIncAccommodation;
                    result.Delegates_Inc_Extra_Night__c = delegatesIncExtraNight;
                    result.Delegates_Inc_Exam__c = delegatesIncExam;
                    // update the expenses for the related training event if not set
                    //25516 Removed if null as this needs to be set/checked in all instancese
                    //if(null == te.Expenses__c)
                    //{
                        if(infoValueMap.containsKey('Expenses')) expensesIncluded = !Boolean.valueOf(infoValueMap.get('Expenses'));
                        te.Expenses__c = expensesIncluded ? 'Expenses to be charged' : 'Not chargeable';
                    //}
                }
                else
                {
                    if(infoValueMap.containsKey('Accomodation')) delegatesIncAccommodation = Integer.valueOf(infoValueMap.get('Accomodation'));
                    if(infoValueMap.containsKey('Extra Nights')) delegatesIncExtraNight = Integer.valueOf(infoValueMap.get('Extra Nights'));
                    if(infoValueMap.containsKey('Examination')) delegatesIncExam = Integer.valueOf(infoValueMap.get('Examination'));
                    result.Delegates_Inc_Accommodation__c = delegatesIncAccommodation;
                    result.Delegates_Inc_Extra_Night__c = delegatesIncExtraNight;
                    result.Delegates_Inc_Exam__c = delegatesIncExam;
                }
                result.Price_Per_Delegate__c = qp.Price__c;
                result.Number_of_Delegates__c = qp.Number__c;
                result.Delegates_Exc_Accommodation__c = (result.Number_of_Delegates__c - result.Delegates_Inc_Accommodation__c);
                result.Quote_Part__c = qp.Id;
                TotalPriceExcludingAccomodation = qp.Total_Price__c;
            }
            if(qp.ProductAttribute__c.contains(QUOTEPART_PRODATTRIBUTE_ACCOMMODATION)){
                // this quote part is the accomodation line item
                if(infoValueMap.containsKey('Accomodation')) delegatesIncAccommodation = Integer.valueOf(infoValueMap.get('Accomodation'));
                result.Price_Per_Delegate_Accommodation__c = qp.Total_Price__c;
                result.Delegates_Inc_Accommodation__c = delegatesIncAccommodation;
                result.Accomodation_Quote_Part__c = qp.Id;
            }
            if(qp.ProductAttribute__c.contains(QUOTEPART_PRODATTRIBUTE_EXTRANIGHT)){
                // this quote part is the extra night line item
                if(infoValueMap.containsKey('Extra Nights')) delegatesIncExtraNight = Integer.valueOf(infoValueMap.get('Extra Nights'));
                result.Price_Per_Delegate_Extra_Night__c = qp.Total_Price__c;
                result.Delegates_Inc_Extra_Night__c = delegatesIncExtraNight;
                result.Extra_Night_Quote_Part__c = qp.Id;
            }
            TotalPrice = (TotalPrice + qp.Total_Price__c);
        }

        //map details
        result.Booking_Route__c = INTERNAL_BOOKING_ROUTE;
        result.Training_Event__c = te.Id;
        
        // map contact details
        result.Salutation__c = con.Salutation;
        result.Email_Address__c = con.Email;
        result.Contact_Phone__c = con.Phone;
        result.Salutation__c = con.Salutation;
        result.First_Name__c = con.FirstName;
        result.Last_Name__c = con.LastName;
        result.Contact_Mobile__c = con.MobilePhone;
        result.Contact_Fax__c = con.Fax;
        
        // map contact address details
        result.Company_Name__c = acc.Name;
        result.Company_Name_English__c = acc.NameLocal;
        result.Company_Street__c = acc.BillingStreet;
        result.Company_City__c = acc.BillingCity;
        result.Company_Country__c = acc.BillingCountry;
        result.Company_Region__c = acc.BillingState;
        result.Company_Postcode__c = acc.BillingPostalCode;
        result.Company_Country_Code__c = acc.BillingCountry;
        result.Billing_Street__c = con.MailingStreet;
        result.Billing_City__c = con.MailingCity;
        result.Billing_Country__c = con.MailingCountry;
        result.Billing_Region__c = con.MailingState;
        result.Billing_Postcode__c = con.MailingPostalCode;

        if(null!=con.FirstNameLocal && null!=con.LastNameLocal) result.Billing_Name_English__c = con.FirstNameLocal + con.LastNameLocal;
        else if(null!=con.FirstNameLocal) result.Billing_Name_English__c = con.FirstNameLocal;
        else if(null!=con.LastNameLocal) result.Billing_Name_English__c = con.LastNameLocal; 
        result.Contact_Mobile__c = con.MobilePhone;
        result.Contact_Fax__c = con.Fax;
        
        // map pricing
        result.Total_Price__c = TotalPrice;
        result.Price_Inc_Accommodation__c = TotalPrice;
        result.Price_Exc_Accommodation__c = TotalPriceExcludingAccomodation;
        
        // map payment
        result.payment_method__c = INTERNAL_SALES_PAYMENT_METHOD;
        
        // map conversion
        result.Quote__c = QuoteRef;
        result.Conversion_Opportunity__c = OppId;
        result.Conversion_Account__c = acc.Id;
        result.Conversion_Contact__c = con.Id;
        
        //25516
        result.Training_Translations__c = result.Training_Event__r.Course__r.Training_Translations__c;
        
        return result;
    }
    
    public static map<String, Training_Event__c> getTrainingEvents(map<Id, Quote_Part__c> quotePartMap)
    {
        Set<String> eventCodeSet = new Set<String>();
        
        for(Quote_Part__c qp : quotePartMap.values())
        {
            eventCodeSet.add(GetInfoValue(INFO_PARAM_EVENT_CODE, qp).trim());
        }
        
        map<String, Training_Event__c> trainingEventMap = new map<String, Training_Event__c>();

        for(Training_Event__c te : [SELECT Id, Name, Quote_Part__c, Expenses__c
                                    FROM Training_Event__c
                                    WHERE Name IN :eventCodeSet OR 
                                        Quote_Part__c IN :quotePartMap.keySet()])
        {
            trainingEventMap.put(te.Name, te);
            trainingEventMap.put(te.Quote_Part__c, te);
        }
        
        return trainingEventMap;
    }
    
    public static void trainingEventInstructorAssignmentMessage(List<Training_Event__c> events){
        System.debug('### bg_TrainingUtils.trainingEventInstructorAssignmentMessage');

        if(firstRun) firstRun = false;
        else return;

        List<Id> eventsIds = new List<Id>();
        List<Id> courseIds = new List<Id>();
        List<Id> instructorIds = new List<Id>();
        List<Training_Event__c> eventsToUpdate = new List<Training_Event__c>();

        for(Training_Event__c te : events){
            eventsIds.add(te.Id);
        }

        for (Training_Event__c te : [SELECT id, Instructor_Message__c, Course__r.Bespoke_Event__c, Course__r.I_codes_Required__c, Observer_Tutor__c,
                Trainer__c, Trainer__r.FirstName, Trainer__r.LastName,Trainer__r.I_Codes_text__c, 
                Trainer_2nd__c, Trainer_2nd__r.FirstName, Trainer_2nd__r.LastName, Trainer_2nd__r.I_Codes_text__c,
                Instructor_3rd__c, Instructor_3rd__r.FirstName, Instructor_3rd__r.LastName, Instructor_3rd__r.I_Codes_text__c,
                Instructor_4th__c, Instructor_4th__r.FirstName, Instructor_4th__r.LastName, Instructor_4th__r.I_Codes_text__c,
                Instructor_5th__c, Instructor_5th__r.FirstName, Instructor_5th__r.LastName, Instructor_5th__r.I_Codes_text__c
                FROM Training_Event__c
                WHERE id in :eventsIds]) {

            if(te.Course__r.Bespoke_Event__c) te.Instructor_Message__c = Label.Training_Event_Instructor_Message_Bespoke_Course;
            else{
                if (te.Trainer__c != null || te.Trainer_2nd__c != null 
                    || te.Instructor_3rd__c != null || te.Instructor_4th__c != null
                    || te.Instructor_5th__c != null)
                {
                    if (!bg_StringUtils.IsBlank(te.Course__r.I_codes_Required__c)) {

                        string icodesRequired = te.Course__r.I_codes_Required__c.deleteWhitespace();
                        List<String> courseIcodes = icodesRequired.split(',');
                        Integer requiredIcodes = courseIcodes.size();
                        Integer trainerIcodesNum = 0;
                        Integer trainer2ndIcodesNum = 0;
                        Integer instructor3rdIcodesNum = 0;
                        Integer instructor4thIcodesNum = 0;
                        Integer instructor5thIcodesNum = 0;

                        for (String courseICode : courseIcodes)
                        {
                            if (te.Trainer__c != null) {
                                if (!bg_StringUtils.IsBlank(te.Trainer__r.I_Codes_text__c)) {
                                    if (te.Trainer__r.I_Codes_text__c.contains(courseICode))
                                    {
                                        trainerIcodesNum++;
                                    }
                                }
                            }

                            // only check Trainer_2nd__c if Observer_Tutor__c has not be set (null)
                            // if it has been set then it's qualifications should not be checked
                            if (te.Observer_Tutor__c == null || te.Observer_Tutor__c == OBSERVER_TUTOR_OBSERVING) 
                            {
                                if (te.Trainer_2nd__c != null){
                                    if (!bg_StringUtils.IsBlank(te.Trainer_2nd__r.I_Codes_text__c)) {
                                        if (te.Trainer_2nd__r.I_Codes_text__c.contains(courseICode))
                                        {
                                            trainer2ndIcodesNum++;
                                        }
                                    }
                                }
                            }
                            if (te.Instructor_3rd__c != null) {
                                if (!bg_StringUtils.IsBlank(te.Instructor_3rd__r.I_Codes_text__c)) {
                                    if (te.Instructor_3rd__r.I_Codes_text__c.contains(courseICode))
                                    {
                                        instructor3rdIcodesNum++;
                                    }
                                }
                            }

                            if (te.Instructor_4th__c != null) {
                                if (!bg_StringUtils.IsBlank(te.Instructor_4th__r.I_Codes_text__c)) {
                                    if (te.Instructor_4th__r.I_Codes_text__c.contains(courseICode))
                                    {
                                        instructor4thIcodesNum++;
                                    }
                                }
                            }
                            if (te.Instructor_5th__c != null) {
                                if (!bg_StringUtils.IsBlank(te.Instructor_5th__r.I_Codes_text__c)) {
                                    if (te.Instructor_5th__r.I_Codes_text__c.contains(courseICode))
                                    {
                                        instructor5thIcodesNum++;
                                    }
                                }
                            }
                        }
                        // logic to check that all instructors qualifications match with the course
                        String message = '';
                        if (te.Trainer__c != null)
                        {
                            if (trainerIcodesNum != requiredIcodes)
                            {
                                if (te.Trainer__r.FirstName != null) message += te.Trainer__r.FirstName + ' ';
                                message += te.Trainer__r.LastName;
                            }
                        }
                        if (te.Observer_Tutor__c == null || te.Observer_Tutor__c == OBSERVER_TUTOR_OBSERVING)
                        {
                            if (te.Trainer_2nd__c != null)
                            {
                                if (trainer2ndIcodesNum != requiredIcodes)
                                {
                                    if (message != '') message += ', ';
                                    if (te.Trainer_2nd__r.FirstName != null) message += te.Trainer_2nd__r.FirstName + ' ';
                                    message += te.Trainer_2nd__r.LastName;
                                }
                            }
                        }
                        if (te.Instructor_3rd__c != null)
                        {
                            if (instructor3rdIcodesNum != requiredIcodes)
                            {
                                if (message != '') message += ', ';
                                if (te.Instructor_3rd__r.FirstName != null) message += te.Instructor_3rd__r.FirstName + ' ';
                                message += te.Instructor_3rd__r.LastName;
                            }
                        }
                        if (te.Instructor_4th__c != null)
                        {
                            if (instructor4thIcodesNum != requiredIcodes)
                            {
                                if (message != '') message += ', ';
                                if (te.Instructor_4th__r.FirstName != null) message += te.Instructor_4th__r.FirstName + ' ';
                                message += te.Instructor_4th__r.LastName;
                            }
                        }
                        if (te.Instructor_5th__c != null)
                        {
                            if (instructor5thIcodesNum != requiredIcodes)
                            {
                                if (message != '') message += ', ';
                                if (te.Instructor_5th__r.FirstName != null) message += te.Instructor_5th__r.FirstName + ' ';
                                message += te.Instructor_5th__r.LastName;
                            }
                        }
                        if (message == '') te.Instructor_Message__c = Label.Training_Event_Instructor_Message_All_Good;
                        else te.Instructor_Message__c = string.format(Label.Training_Event_Instructor_Message_Errors, new list<string>{message});
                    }
                    else te.Instructor_Message__c = Label.Training_Event_Instructor_Message_Course_No_ICodes;
                }
                else te.Instructor_Message__c = Label.Training_Event_Instructor_Message_None;
            }
            eventsToUpdate.add(te);
        }
        try
        {
            update eventsToUpdate;
        }
        catch (DmlException e)
        {
            system.debug('bg_TrainingUtils.trainingEventInstructorAssignmentMessage DMLException: ' + e.getMessage());
        }
    }

    public static void productUpdateTrainingEventInstructorMessage(Map<Id, Product2> oldMap, Map<Id, Product2> newMap)
    {

        List<Id> productIds = new List<Id>();
        for (Id productId : newMap.keySet())
        {
            if ( (oldMap.get(productId).Bespoke_Event__c != newMap.get(productId).Bespoke_Event__c)
                || (oldMap.get(productId).I_codes_Required__c != newMap.get(productId).I_codes_Required__c) ) {
                productIds.add(productId);
            }
        }

        if (!productIds.isEmpty())
        {
            List<Training_Event__c> events = [SELECT id from Training_Event__c where Course__c in :productIds
                and Event_Status__c = 'Active'
                and Start_Date__c > TODAY];

            if (!events.isEmpty())
            {
                try
                {
                    update events;
                }
                catch (DMLException e)
                {
                    system.debug('bg_TrainingUtils.productUpdateTrainingEventInstructorMessage DMLException: ' + e.getMessage());
                }
            }
        }
    }

    public static void contactUpdateTrainingEventInstructorMessage(Map<Id, Contact> oldMap, Map<Id, Contact> newMap)
    {
        List<Id> contactIds = new List<Id>();
        for(Id contactId : newMap.keySet()){
            if(oldMap.get(contactId).I_Codes_text__c != newMap.get(contactId).I_Codes_text__c) contactIds.add(contactId);
        }

        if (!contactIds.isEmpty())
        {
            List<Training_Event__c> events = [SELECT id from Training_Event__c where (Trainer__c in :contactIds or Trainer_2nd__c in :contactIds 
                or Instructor_3rd__c in :contactIds or Instructor_4th__c in :contactIds or Instructor_5th__c in :contactIds)
                and Event_Status__c = 'Active'
                and Start_Date__c > TODAY];

            if (!events.isEmpty())
            {
                try
                {
                    update events;
                }
                catch (DmlException e)
                {
                    system.debug('bg_TrainingUtils.contactUpdateTrainingEventInstructorMessage DMLException: ' + e.getMessage());
                }
            }
        }
    }

   /* public static Enrollment__c createConvertEnrollment(String deliveryMethod
        , Id eLearningTypeId, Id distanceTypeId, Id instructorTypeId,
            Id trainingEventId, Id conversionOpportunityId, Id conversionContactId, Boolean convertToOnHold, Boolean accomodationRequired, Decimal courseDurationDays,
            Id trainingTranslationId, String paymentStatus, String sapOrderNumber)
    {
        // Add an enrollment
        Enrollment__c enrollment = new Enrollment__c();

        // Set fields related to delivery type
        if (deliveryMethod == 'eLearning')
        {
            enrollment.RecordTypeId = eLearningTypeId;
        }
        else if (deliveryMethod== 'Distance Learning')
        {
            enrollment.RecordTypeId = distanceTypeId;
        }
        else
        {
            enrollment.RecordTypeId = instructorTypeId;
        }

        // Set mandatory fields            
        enrollment.Training_Event__c = trainingEventId;
        enrollment.Opportunity__c = conversionOpportunityId;
        enrollment.Delegate_Name__c = conversionContactId;
        enrollment.Booking_Status__c = convertToOnHold ? 'On Hold - Payment' : 'Booked';
        enrollment.Accomodation__c = (accomodationRequired ? (Integer.valueof(courseDurationDays) > 1 ? 'During' : 'Night before and during') : 'Non-Residential');
        enrollment.Training_Translations__c = trainingTranslationId;

        // Set fields related to payment status
        if (paymentStatus == 'Paid Online' || paymentStatus == 'Paid on Phone')
        {
            enrollment.Invoice_Status__c = 'Payment Received';
            enrollment.Invoice_Immediately__c = false;
            enrollment.Contract_Number__c = sapOrderNumber;
            if (deliveryMethod == 'Distance Learning')
            {
                enrollment.Distance_Learning_Overall_Status__c = 'In Progress';
                enrollment.Comments__c = 'Paid Online';
            }
        }
        else
        {
            enrollment.Invoice_Status__c = 'Pending';
            enrollment.Invoice_Immediately__c = true;
        }

        return enrollment;
    }*/

    public static Id getRecordTypeId (SObjectType sObjectType, String recordTypeName) {
        if (sObjectType.getDescribe().getRecordTypeInfosByName().get(recordTypeName) != null) {
            return sObjectType.getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        } else {
            return null;
        }
    }
    
    /*
     * Method to delete training bookings whose quote part have been deleted
     */
    public static void deleteOrphanedTrainingBookings(Map<Id, Quote_Part__c> deletedParts)
    {
        system.debug('$$$$$ Map Size: ' + deletedParts.values().size());
        
        List<TrainingBooking__c> results = [SELECT Id
                                             FROM TrainingBooking__c
                                             WHERE Quote_Part__c IN :deletedParts.keySet()];
        
        system.debug('$$$$$ Results Size: ' + results.size());
                                             
        if(!results.IsEmpty())
        {
            try
            {
                Database.delete(results);
            }
            catch(Exception e)
            {
                system.debug('$$$$$ deleteOrphanedTrainingBookings ERROR: ' + e.getMessage());
            }
        }
    }
    
    /*
     *  Method to return a list of future training events for a given course
     */
    public static List<Training_Event__c> getEventsForCourse(Id courseId)
    {
        return ([SELECT Id, Name, Start_Date__c
                 FROM Training_Event__c
                 WHERE Course__c = :courseId
                 AND Start_Date__c > TODAY
                 ORDER BY Start_Date__c ASC]);
    }
    
    /*
     *  Method to return a list of "training events" for a given exam
     *  MD 20190130 Added CourseEndDate parameter and conditions to select Event for the year in which this date falls
     */
    public static List<Training_Event__c> getEventsForOnlineExam(Id examId, Date CourseEndDate)
    {
        return ([SELECT Id, Name, Start_Date__c, End_Date__c
                 FROM Training_Event__c
                 WHERE Course__c = :examId
                 AND Event_Status__c = 'Active'
                 AND Start_Date__c <= :CourseEndDate
                 AND End_Date3__c >= :CourseEndDate
                 ORDER BY Start_Date__c ASC]);
    }
    
    /*
     * Method to return Opportunity Line Item for Enrolment
     */
    public static OpportunityLineItem getEnrollmentOLI(Id enrolmentId)
    {
        return ([SELECT Id, Name, SMOScheduledDate__c, Enrollment__c
                  FROM OpportunityLineItem
                  WHERE Enrollment__c = :enrolmentId
                  LIMIT 1]);
    }

    public static void setSMOScheduledDate(TrainingBookingConversionWrapper pConversionWrapper, Map<Id,Product2> pProductsById)
    {
        // Iterate through OLIs and set SMO date
        for(OpportunityLineItem oli : pConversionWrapper.existingOppLineItems)
        {
            if(pProductsById.get(oli.Product2Id).Course_Format__c == COURSE_FORMAT_ILT ||
               pProductsById.get(oli.Product2Id).Course_Format__c == COURSE_FORMAT_BLENDED_LEARNING ||
               pProductsById.get(oli.Product2Id).Course_Format__c == COURSE_FORMAT_VIRTUAL_LEARNING) //JS added 01042020
            {
                // Use Event Start Date
                if(null != oli.Training_Event__c) oli.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.Start_Date__c;
            }
            else if(pProductsById.get(oli.Product2Id).Course_Format__c == COURSE_FORMAT_DISTANCE_LEARNING || pProductsById.get(oli.Product2Id).Course_Format__c == COURSE_FORMAT_E_LEARNING)
            {
                //MD 20190130 IS THIS AN ONLINE EXAM BOOKED ALONG WITH A COURSE?
                if (oli.ProductAttribute__c.containsIgnoreCase('OnlineExam'))
                    // Online Exam: Use End Date of Course Event
                    oli.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.End_Date3__c;
                else 
                    // Standalone Exam, eLearning of Distance Learning: Use Opp Close Date
                    oli.SMOScheduledDate__c = pConversionWrapper.booking.Conversion_Opportunity__r.CloseDate;
            }
            else if(pProductsById.get(oli.Product2Id).Course_Format__c == COURSE_FORMAT_OTHER)
            {
                if(pProductsById.get(oli.Product2Id).Training_Product_Type__c == TRAINING_PRODUCT_STANDARDS || null == oli.Training_Event__c)
                {
                    // Use Opp Close Date
                    oli.SMOScheduledDate__c = pConversionWrapper.booking.Conversion_Opportunity__r.CloseDate;
                } 
                else if(null != oli.Training_Event__c)
                {                
                    // Use Event Start Date
                    oli.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.Start_Date__c;
                }
                
            }
        }
    }

    public static void SetOpportunitySyncFlag(set<Opportunity> opportunities)
    {
        /*
            Sets the sync flag on opportunity to stop some validation rules firing
        */
        
        for(Opportunity opportunityIterator : opportunities)
        {
            opportunityIterator.Sync_in_Progress__c = true;
        }
        update new list<Opportunity> (opportunities);
    }
    
    public static void ClearOpportunitySyncFlag(set<Opportunity> opportunities)
    {
        /*
            Clears the sync flag on opportunity to allow the validation rules to fire
        */
        
        for(Opportunity opportunityIterator : opportunities)
        {
            opportunityIterator.Sync_in_Progress__c = false;
        }
        update new list<Opportunity>(opportunities);
    }
    
    public class TrainingBookingConversionWrapper
    {
        public TrainingBooking__c booking {get; set;}
        public Account conversionAccount {get; set;}
        public Contact conversionContact {get; set;}
        public Map<Id,Contact> delegatesForContactCreation {get; set;}
        public Opportunity conversionOpportunity {get; set;}
        public OpportunityContactRole conversionOppContactRole {get; set;}
        public Map<Id,Enrollment__c> delegateEnrollments {get; set;}
        public Map<Id,Enrollment__c> delegateOnlineExamEnrollments {get; set;}
        public Map<Id,TrainingDelegate__c> trainingDelegateMap {get; set;}
        public Map<Id,List<OpportunityLineItem>> onlineBooking_OppLineItems {get; set;}
        public List<OpportunityLineItem> existingOppLineItems {get; set;}
        public PricebookEntry coursePriceBook {get; set;}
        public PricebookEntry includingAccommodationPriceBook {get; set;}
        public PricebookEntry excludingAccomodationPriceBook {get; set;}
        public Id contactTypeId {get; set;} 
        public Id enrollmentRecordTypeId {get; private set;}
        public PageReference pr {get; set;}
        public boolean isManualConversion {get; set;}
        public boolean isSafetoConvert {get; set;}
        public Training_Event__c onlineExamTrainingEvent { get; set; }
        
        public TrainingBookingConversionWrapper(TrainingBooking__c pTrainingBookingForConversion, List<OpportunityLineItem> pExistingOppLineItems, boolean pIsManualConversion)
        {   
            this.booking = pTrainingBookingForConversion;
            this.existingOppLineItems = pExistingOppLineItems;
            this.conversionAccount = null;
            this.conversionContact = null;
            this.conversionOpportunity = null;
            this.conversionOppContactRole = null;
            this.delegatesForContactCreation = new Map<Id,Contact>();
            this.delegateEnrollments = new Map<Id,Enrollment__c>();
            this.delegateOnlineExamEnrollments = new Map<Id,Enrollment__c>();
            this.trainingDelegateMap = new Map<Id,TrainingDelegate__c>();
            this.onlineBooking_OppLineItems = new Map<Id,List<OpportunityLineItem>>();
            this.pr = null;
            this.isManualConversion = pIsManualConversion;
            this.contactTypeId = bg_TrainingUtils.getRecordTypeId(Contact.SObjectType, bg_TrainingUtils.ACOUNT_CONTACT_RECORD_TYPE);

            if (bg_RecordTypeUtils.GetRecordTypes('Enrollment__c').containsKey(booking.Enrollment_Record_Type__c))
            {
                this.enrollmentRecordTypeID = bg_RecordTypeUtils.GetRecordTypes('Enrollment__c').get(booking.Enrollment_Record_Type__c).Id;
            }
            else
            {
                this.setError(Label.Enrollment_RecordType_Error);
            }

            // fetch pricebook entries for training booking
            if(null!=this.booking){
                if (this.booking.Pricebook_Entry__c != null) {
                    this.coursePriceBook = [select Id, UnitPrice from PricebookEntry where id =: this.booking.Pricebook_Entry__c ];
                }
                if (this.booking.Pricebook_Inc_Accommodation__c != null) {
                    this.includingAccommodationPriceBook = [select Id, UnitPrice from PricebookEntry where id =: this.booking.Pricebook_Inc_Accommodation__c ];
                }
                if (this.booking.Pricebook_Exc_Accommodation__c != null) {
                    this.excludingAccomodationPriceBook = [select Id, UnitPrice from PricebookEntry where id =: this.booking.Pricebook_Exc_Accommodation__c];
                }
                if(null != this.booking.Conversion_Account__c)
                {
                    this.conversionAccount = this.booking.Conversion_Account__r;
                }
                if(null != this.booking.Conversion_Contact__c)
                {
                    this.conversionContact = this.booking.Conversion_Contact__r;
                }
                for(TrainingDelegate__c td : this.booking.Training_Delegates__r)
                {
                    this.trainingDelegateMap.put(td.Id,td);
                }
                
                // 28/07/2017 ADS - SoW034 - Online Exam Enhancements - Start
                
                if (0 < this.booking.Delegates_Inc_Exam__c && 
                    null != this.booking.Training_Event__r &&
                    null != this.booking.Training_Event__r.Course__r &&
                    null != this.booking.Training_Event__r.Course__r.Online_Exam__c)
                {
                // MD 20190129 Added conditions to select Training Event for correct year (the year in which the Course End Date falls)
                    //List<Training_Event__c> onlineExamTrainingEvents = [SELECT Id, Name, End_Date__c FROM Training_Event__c WHERE Course__c = :this.booking.Training_Event__r.Course__r.Online_Exam__c AND CALENDAR_YEAR(Training_Event__c.Start_Date__c) = :this.booking.Training_Event__r.Start_Date__c.year()];
                    List<Training_Event__c> onlineExamTrainingEvents = [SELECT Id, Name, End_Date__c FROM Training_Event__c 
                                                                        WHERE Course__c = :this.booking.Training_Event__r.Course__r.Online_Exam__c 
                                                                        AND Training_Event__c.Start_Date__c <= :this.booking.Training_Event__r.End_Date3__c 
                                                                        AND Training_Event__c.End_Date3__c >= :this.booking.Training_Event__r.End_Date3__c
                                                                        AND Training_Event__c.Active_1_0__c = 1];
                    
                    if (onlineExamTrainingEvents.isEmpty() ||
                        onlineExamTrainingEvents.size() > 1)
                    {
                        setError(System.Label.Training_Event_Online_Exam_Missing);
                        this.isSafetoConvert = false;
                    }
                    else
                    {
                        this.onlineExamTrainingEvent = onlineExamTrainingEvents[0];
                    }
                    
                }
                
                // 28/07/2017 ADS - SoW034 - Online Exam Enhancements - Finish
            }
        }
        public void isReadytoConvert(){
            this.isSafetoConvert = true;
            // test that the booking has not already been converted    
            if (this.booking.Converted__c)
            {
                setError(System.Label.TrainingBooking_Already_Converted);
                this.isSafetoConvert = false;
            }
            // check booking route has been set
            if(null==this.booking.booking_Route__c || String.IsBlank(this.booking.Booking_Route__c))
            {
                setError(System.Label.TrainingBooking_BookingRoute_Error);
                this.isSafetoConvert = false;
            }
            // are training translations in place
            if(null==this.booking.Training_Translations__c)
            {
                setError(System.Label.TrainingBooking_TrainingTranslations_Error);
                this.isSafetoConvert = false;
            }
            // check num of delegates matches
            if(this.booking.Number_of_Delegates__c != this.booking.Training_Delegates_Count__c)
            {
                setError(System.Label.TrainingBooking_TrainingDelegateCount_Error);
                this.isSafetoConvert = false;
            }
            // check num of delegates with acommodation matches
            if(this.booking.Delegates_Inc_Accommodation__c != this.booking.Delegates_Inc_Accommodation_Count__c)
            {
                setError(System.Label.TrainingBooking_TrainingDelegateAccommodationCount_Error);
                this.isSafetoConvert = false;
            }
            // check num of delegates with extra night matches
            if(this.booking.Delegates_inc_extra_night__c != this.booking.Delegates_Inc_Extra_Night_Count__c)
            {
                setError(System.Label.TrainingBooking_TrainingDelegateExtraNightCount_Error);
                this.isSafetoConvert = false;
            }
            // check num of delegates with examination matches
            if(this.booking.Delegates_inc_exam__c != this.booking.Delegates_Inc_Examination_Count__c)
            {
                setError(System.Label.TrainingBooking_TrainingDelegateExaminationCount_Error);
                this.isSafetoConvert = false;
            }
            // check if all related delegates are ready to convert
            if(!bg_DelegateUtils.DelegatesReadyToConvert(this.booking.Training_Delegates__r))
            {
                setError(System.Label.Delegates_Not_Ready_To_Convert);
                this.isSafetoConvert = false;
            }
        }
        public void setError(String pError){
            if(this.isManualConversion)
            {
                // show error and return back to training booking record
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, pError));
                this.pr = new PageReference('/'+this.booking.Id);
            }
            else
            {
                this.booking.Conversion_Error__c = true;
            }
        }

        /* Resets booking to pre-modified state */
        public void resetBooking()
        {
            this.booking = new TrainingBooking__c(Id = booking.Id);
        }

        /*public boolean delegatesNotConvertedToContacts()
        {
            Boolean retval = true;
            for(TrainingDelegate__c delegate : this.booking.Training_Delegates__r){
                if(null!=delegate.Conversion_Contact__c)
                {
                    retval = false;
                    break;
                }
            }
            return retval;
        }*/
        public void setSuccessMessage(String pSuccessMessage)
        {
            // show success and return back to training booking record
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, pSuccessMessage));
            this.pr = new PageReference('/'+this.booking.Id);
        }
    }
    
    public static List<TrainingBooking__c> fetchBookingsWithDelegatesAndQuotePartsForConversion(Set<Id> pTrainingBookingIds){
        return [
            SELECT  b.Id, 
                    b.Training_Event__c, 
                    b.Training_Event__r.Name, 
                    b.Training_Event__r.Course_Name_for_Certificate__c, 
                    b.Training_Event__r.Max_Seats__c, 
                    b.Training_Event__r.Enrollment_Count__c, 
                    b.Training_Event__r.On_Hold_for_Payment__c, 
                    b.Training_Event__r.Enrollment_Pending__c, 
                    b.Training_Event__r.Start_Date__c, 
                    b.Training_Event__r.End_Date__c, 
                    b.Training_Event__r.End_Date3__c, 
                    b.Training_Event__r.China_Region__c, 
                    b.Training_Event__r.Accommodation__c,
                    b.Training_Event__r.Accommodation_night_prior__c, 
                    b.Training_Event__r.Max_Accommodation__c, 
                    b.Training_Event__r.Course_Duration_Days__c, 
                    b.Training_Event__r.Course_Type_Formula__c, 
                    b.Training_Event__r.Course__r.Delivery_Method__c,
                    b.Training_Event__r.Course__r.Online_Exam__c, 
                    b.Is_Residential__c, 
                    b.CurrencyIsoCode, 
                    b.Total_Delegates__c, 
                    b.Number_of_Delegates__c, 
                    b.Price_Per_Delegate__c, 
                    b.Price_Per_Delegate_Accommodation__c,
                    b.Price_Per_Delegate_Extra_Night__c,
                    b.Pricebook_Entry__c, 
                    b.Delegates_Inc_Accommodation__c, 
                    b.Price_Inc_Accommodation__c, 
                    b.Pricebook_Inc_Accommodation__c, 
                    b.Delegates_Exc_Accommodation__c, 
                    b.Price_Exc_Accommodation__c, 
                    b.Pricebook_Exc_Accommodation__c, 
                    b.Pricebook_Entry_Extra_Night__c,
                    b.Pricebook_Entry_Online_Exam__c,
                    b.Pricebook_Entry_Online_Standard__c,
                    b.Delegates_Inc_Exam__c,
                    b.Delegates_Inc_Standard__c,
                    b.Price_Per_Delegate_Online_Exam__c,
                    b.Price_Per_Delegate_Online_Standard__c,
                    b.Discount_Value__c, 
                    b.Discount_Percentage__c, 
                    b.Net_Price__c, 
                    b.Discount__c, 
                    b.Tax__c, 
                    b.Total_Price__c, 
                    b.Company_Name__c, 
                    b.Company_Name_English__c, 
                    b.Company_Street__c, 
                    b.Company_City__c, 
                    b.Company_Region__c, 
                    b.Company_Postcode__c, 
                    b.Company_Country__c, 
                    b.Company_Country_Code__c,
                    b.Billing_Address__c, 
                    b.Billing_Name__c, 
                    b.Billing_Street__c, 
                    b.Billing_City__c, 
                    b.Billing_Region__c, 
                    b.Billing_Postcode__c, 
                    b.Billing_Country__c, 
                    b.Billing_Country_Code__c, 
                    b.Salutation__c, 
                    b.First_Name__c, 
                    b.Last_Name__c, 
                    b.Email_Address__c, 
                    b.Job_Title__c, 
                    b.Contact_Phone__c, 
                    b.Contact_Mobile__c, 
                    b.Contact_Fax__c, 
                    b.Payment_Method__c,
                    b.Payment_Order_No__c, //JS added 01/02/21 so can map PSP order to ENR
                    b.Payment_Name__c,     //JS added 04/02/21 so can map PSP order to ENR
                    b.Payment_Status__c, 
                    b.SAP_Order_No__c, 
                    b.Training_Translations__c, 
                    b.Converted__c, 
                    b.Convert_To_On_Hold__c, 
                    b.Conversion_Account__c,
                    b.Conversion_Account__r.Id, 
                    b.Conversion_Contact__c,
                    b.Conversion_Contact__r.Id, 
                    b.Conversion_Campaign__c,
                    b.Conversion_Opportunity__c,
                    b.Conversion_Opportunity__r.CloseDate,
                    b.Country_ISO_Code__c,
                    b.Quote__c, 
                    b.Booking_Route__c,
                    b.Conversion_Error__c,
                    b.Delay_Invoice__c,
                    b.Delayed_Invoice_Date__c,
                    b.Quote_Part__c,
                    b.Accomodation_Quote_Part__c,
                    b.Extra_Night_Quote_Part__c,
                    b.Training_Delegates_Count__c,
                    b.Delegates_Inc_Accommodation_Count__c,
                    b.Delegates_inc_extra_night__c,
                    b.Delegates_Inc_Extra_Night_Count__c,
                    b.Delegates_Inc_Examination_Count__c,
                    b.Quote_Part__r.Product2__r.Is_Exam_Resit__c,
                    b.Enrollment_Record_Type__c,
                    b.CC_Enrolment_Emails__c,
                    b.PO_Number__c,
                    b.VAT_Number__c,
                    b.VAT_Number2__c,
                    b.Codice_Fiscale__c,                    
                    b.Manage_Government_Incentive__c,
                    b.Invoice_Recipient_Code__c,
                    b.Registered_Email_for_Invoice__c,
                    b.Branch_Number__c,
                    b.Conversion_Account__r.VAT_Number__c, 
                    b.Conversion_Account__r.VAT_Number_NonEU__c, 
                    b.Conversion_Account__r.Codice_Fiscale__c,                    
                    b.Conversion_Account__r.Invoice_Recipient_Code__c,
                    b.Conversion_Account__r.Registered_Email_for_Invoice__c,
                    b.Conversion_Account__r.Branch_Number__c,
                     
                    (
                        SELECT  d.Id, 
                                d.Salutation__c, 
                                d.First_Name__c, 
                                d.Last_Name__c, 
                                d.First_Name_English__c, 
                                d.Last_Name_English__c, 
                                d.Email_Address__c, 
                                d.Job_Title__c, 
                                d.Mobile_Number__c, 
                                d.Social_Security_Number__c, 
                                d.Accommodation_Required__c, 
                                d.Is_Booker__c, 
                                d.Converted__c, 
                                d.Conversion_Contact__c,
                                d.Ready_For_Conversion__c,
                                d.Accommodation_night_before__c,
                            d.Online_Exam__c,
                            d.Standard__c
                        FROM    Training_Delegates__r d 
                    ),
                    (
                        SELECT q.Id
                        FROM Quote_Parts__r q
                    ) 
            FROM    TrainingBooking__c b 
            WHERE   b.Id IN :pTrainingBookingIds
            ]; 
    }  
    public static void createConversionAccount(TrainingBookingConversionWrapper pConversionWrapper)
    {
        Account account = new Account();
        if (!String.isBlank(pConversionWrapper.booking.Company_Name_English__c))
        {
            account.Name = pConversionWrapper.booking.Company_Name_English__c;
            account.NameLocal = pConversionWrapper.booking.Company_Name__c;
        }
        else
        {
            account.Name = String.isBlank(pConversionWrapper.booking.Company_Name__c) ? 'Unspecified' : pConversionWrapper.booking.Company_Name__c;
        }
        account.BillingStreet = pConversionWrapper.booking.Company_Street__c;
        account.BillingCity = pConversionWrapper.booking.Company_City__c;
        account.BillingState = pConversionWrapper.booking.Company_Region__c;
        account.BillingPostalCode = pConversionWrapper.booking.Company_Postcode__c;
        account.BillingCountry = pConversionWrapper.booking.Company_Country_Code__c;
        account.Local_Street__c = pConversionWrapper.booking.Company_Street__c;
        account.Local_City__c = pConversionWrapper.booking.Company_City__c;
        account.Local_State__c = pConversionWrapper.booking.Company_Region__c;
        account.Local_Post_Code__c = pConversionWrapper.booking.Company_Postcode__c;
        account.Local_Country__c = pConversionWrapper.booking.Company_Country_Code__c;
        account.Phone = pConversionWrapper.booking.Contact_Phone__c;
        account.Fax = pConversionWrapper.booking.Contact_Fax__c;

        //Case 26482
        updateConversionAccount(pConversionWrapper, account, false);

        pConversionWrapper.conversionAccount = account;
    }

    /*
        updates the conversion account VAT fields if not populated as requested in case 26482
        27/05/2019 PC added new fields for IT VAT
    */
    public static void updateConversionAccount(TrainingBookingConversionWrapper pConversionWrapper, Account acc, Boolean isUpdate)
    {
        if(acc.VAT_Number__c == null) acc.VAT_Number__c = pConversionWrapper.booking.VAT_Number__c;
        if(acc.VAT_Number_NonEU__c == null) acc.VAT_Number_NonEU__c = pConversionWrapper.booking.VAT_Number2__c;
        if(acc.Codice_Fiscale__c == null) acc.Codice_Fiscale__c = pConversionWrapper.booking.Codice_Fiscale__c;
        if(acc.Invoice_Recipient_Code__c == null) acc.Invoice_Recipient_Code__c = pConversionWrapper.booking.Invoice_Recipient_Code__c;
        if(acc.Registered_Email_for_Invoice__c == null) acc.Registered_Email_for_Invoice__c = pConversionWrapper.booking.Registered_Email_for_Invoice__c;
        if(acc.Branch_Number__c == null) acc.Branch_Number__c = pConversionWrapper.booking.Branch_Number__c;       
        if(isUpdate) update acc;
    }

    public static void createConversionContact(TrainingBookingConversionWrapper pConversionWrapper)
    {
        // // Get the country-specific settings for Billing country
        // String billingCountryCode = '';
        // if (contact.OtherCountry != null && contact.OtherCountry.length() == 2) {
        //     billingCountryCode = new TrainingBookingUtilities.Country(
        //         config.supportedCountries.get(contact.OtherCountry.toUpperCase()),
        //         this.paramLanguage.toUpperCase()
        //     ).countryOptionsDefault;
        // } else {
        //     billingCountryCode = mailingCountry;
        // }
        Contact contact = new Contact();
        contact.Salutation = pConversionWrapper.booking.Salutation__c;
        contact.FirstName = pConversionWrapper.booking.First_Name__c;
        contact.LastName = pConversionWrapper.booking.Last_Name__c;
        contact.Email = pConversionWrapper.booking.Email_Address__c;
        contact.Phone = pConversionWrapper.booking.Contact_Phone__c;
        contact.MobilePhone = pConversionWrapper.booking.Contact_Mobile__c;
        contact.Fax = pConversionWrapper.booking.Contact_Fax__c;
        contact.Title = pConversionWrapper.booking.Job_Title__c;
        contact.MailingStreet = pConversionWrapper.booking.Company_Street__c;
        contact.MailingCity = pConversionWrapper.booking.Company_City__c;
        contact.MailingState = pConversionWrapper.booking.Company_Region__c;
        contact.MailingPostalCode = pConversionWrapper.booking.Company_Postcode__c;
        contact.MailingCountry = pConversionWrapper.booking.Company_Country_Code__c;
        contact.OtherStreet = pConversionWrapper.booking.Billing_Street__c;
        contact.OtherCity = pConversionWrapper.booking.Billing_City__c;
        contact.OtherState = pConversionWrapper.booking.Billing_Region__c;
        contact.OtherPostalCode = pConversionWrapper.booking.Billing_Postcode__c;
        /*21/07/21 JS updated to be country code instead of country if the booking is online, if internal sale, left as Country   */
        if(pConversionWrapper.booking.Booking_Route__c == 'Internal sales'){
              contact.OtherCountry = pConversionWrapper.booking.Billing_Country__c;
               }
               else{                            
                    contact.OtherCountry = pConversionWrapper.booking.Billing_Country_Code__c;
                      }              
        //contact.OtherCountry = pConversionWrapper.booking.Billing_Country_Code__c;
        contact.Local_Street__c = pConversionWrapper.booking.Company_Street__c;
        contact.Local_City__c = pConversionWrapper.booking.Company_City__c;
        contact.Local_State__c = pConversionWrapper.booking.Company_Region__c;
        contact.Local_Post_Code__c = pConversionWrapper.booking.Company_Postcode__c;
        contact.Local_Countyr__c = pConversionWrapper.booking.Company_Country_Code__c;
        
        // Check for English name on related delegate
        for (TrainingDelegate__c delegate : pConversionWrapper.booking.Training_Delegates__r)
        {
            if (delegate.Is_Booker__c && !String.isBlank(delegate.First_Name_English__c))
            {
                contact.FirstNameLocal = pConversionWrapper.booking.First_Name__c;
                contact.LastNameLocal = pConversionWrapper.booking.Last_Name__c;
                contact.FirstName = delegate.First_Name_English__c;
                contact.LastName = delegate.Last_Name_English__c;
                break;
            }
        }

        //PC 20180920 copy mobile over to phone
        if((pConversionWrapper.booking.Contact_Phone__c == null) && (pConversionWrapper.booking.Contact_Mobile__c != null)){
            contact.Phone = pConversionWrapper.booking.Contact_Mobile__c;
        }

        pConversionWrapper.conversionContact = contact;
     }
     public static void createConversionOpportunity(TrainingBookingConversionWrapper pConversionWrapper, boolean accountCreated)
     {
        Opportunity opportunity = new Opportunity();
        opportunity.Name = String.isBlank(pConversionWrapper.booking.Company_Name__c) ? 'Unspecified' : (pConversionWrapper.booking.Company_Name__c + ' - ' + pConversionWrapper.booking.Training_Event__r.Course_Name_for_Certificate__c).left(120);
        opportunity.AccountId = pConversionWrapper.booking.Conversion_Account__c;
        opportunity.Amount = pConversionWrapper.booking.Net_Price__c;
        opportunity.CurrencyIsoCode = pConversionWrapper.booking.CurrencyIsoCode;
        opportunity.CloseDate = Date.today();
        opportunity.StageName = CONVERSION_OPPORTUNITY_STAGENAME; 
        opportunity.RegistrationPath__c = CONVERSION_OPPORTUNITY_REGISTRATION_PATH;
        opportunity.CampaignId = pConversionWrapper.booking.Conversion_Campaign__c;

        if(pConversionWrapper.booking.Booking_Route__c == ONLINE_BOOKING_ROUTE){
            opportunity.LeadSource = CONVERSION_OPPORTUNITY_LEADSOURCE_MARKETING;
            opportunity.SourceSubCategory__c = CONVERSION_OPPORTUNITY_LEADSOURCE_SUB_WEBSITE;
        }
        else opportunity.LeadSource = CONVERSION_OPPORTUNITY_LEADSOURCE_BSI_WEBSITE;

        opportunity.Sync_In_Progress__c = true;

        // Case 26482 
        if(accountCreated) opportunity.PrevCustomer__c = 'No';
        else opportunity.PrevCustomer__c = 'Yes';

        opportunity.Product_Stream__c = TRAINING_PUBLIC;
        opportunity.DeliveryDateExpectations__c = pConversionWrapper.booking.Training_Event__r.Start_Date__c;
        opportunity.PO_Number__c = pConversionWrapper.booking.PO_Number__c;
        opportunity.BusinessDrivers__c = CONVERSION_OPPORTUNITY_CUSTOMERTYPE_TRAINING;
        opportunity.CreateFollowupOpp__c = 'No';

        pConversionWrapper.conversionOpportunity = opportunity; 
     }
     public static void createConversionOppContactRole(TrainingBookingConversionWrapper pConversionWrapper)
     {
        OpportunityContactRole role = new OpportunityContactRole();
        role.IsPrimary = true;
        role.Role = CONVERSION_OPPCONTACTROLE_STATUS;
        pConversionWrapper.conversionOppContactRole = role; 
     }
     public static void createDelegateContacts(TrainingBookingConversionWrapper pConversionWrapper)
     {
        pConversionWrapper.delegatesForContactCreation = new Map<Id,Contact>();
        for(TrainingDelegate__c delegate : pConversionWrapper.booking.Training_Delegates__r)
        {
            // check delegates do not already have an associated contact
            if(null==delegate.Conversion_Contact__c)
            {
                if (!delegate.Is_Booker__c)
                {
                    Contact contact = new Contact();
                    contact.RecordTypeId = pConversionWrapper.contactTypeId;
                    contact.Salutation = delegate.Salutation__c;
                    contact.FirstName = delegate.First_Name__c;
                    contact.LastName = delegate.Last_Name__c;
                    contact.Email = delegate.Email_Address__c;
                    contact.Phone = pConversionWrapper.booking.Contact_Phone__c;
                    contact.MobilePhone = pConversionWrapper.booking.Contact_Mobile__c;
                    contact.Title = delegate.Job_Title__c;
                    contact.MailingStreet = pConversionWrapper.booking.Company_Street__c;
                    contact.MailingCity = pConversionWrapper.booking.Company_City__c;
                    contact.MailingState = pConversionWrapper.booking.Company_Region__c;
                    contact.MailingPostalCode = pConversionWrapper.booking.Company_Postcode__c;
                    contact.MailingCountry = pConversionWrapper.booking.Company_Country_Code__c;
                    contact.OtherStreet = pConversionWrapper.booking.Billing_Street__c;
                    contact.OtherCity = pConversionWrapper.booking.Billing_City__c;
                    contact.OtherState = pConversionWrapper.booking.Billing_Region__c;
                    contact.OtherPostalCode = pConversionWrapper.booking.Billing_Postcode__c;
                    /*21/07/21 JS updated to be country code instead of country if the booking is online, if internal sale, left as Country   */
                    if(pConversionWrapper.booking.Booking_Route__c == 'Internal sales'){
                        contact.OtherCountry = pConversionWrapper.booking.Billing_Country__c;
                        }
                        else{                            
                            contact.OtherCountry = pConversionWrapper.booking.Billing_Country_Code__c;
                            }
                    contact.Local_Street__c = pConversionWrapper.booking.Company_Street__c;
                    contact.Local_City__c = pConversionWrapper.booking.Company_City__c;
                    contact.Local_State__c = pConversionWrapper.booking.Company_Region__c;
                    contact.Local_Post_Code__c = pConversionWrapper.booking.Company_Postcode__c;
                    contact.Local_Countyr__c = pConversionWrapper.booking.Company_Country_Code__c;

                    //PC 20180920 copy mobile over to phone
                    if((pConversionWrapper.booking.Contact_Phone__c == null) && (pConversionWrapper.booking.Contact_Mobile__c != null)){
                        contact.Phone = pConversionWrapper.booking.Contact_Mobile__c;
                    }

                    // Check for English name
                    if (!String.isBlank(delegate.First_Name_English__c))
                    {
                        contact.FirstNameLocal = delegate.First_Name__c;
                        contact.LastNameLocal = delegate.Last_Name__c;
                        contact.FirstName = delegate.First_Name_English__c;
                        contact.LastName = delegate.Last_Name_English__c;
                    }
                    pConversionWrapper.delegatesForContactCreation.put(delegate.Id,contact);
                }
                else{
                    // if the delegate is a booker we have already created the conversion contact - we still need to add this to the map
                    pConversionWrapper.delegatesForContactCreation.put(delegate.Id,pConversionWrapper.conversionContact);
                }
            }
        }   
     }
     public static void createOppLineItems(TrainingBookingConversionWrapper pConversionWrapper)
     {
        // need Map of ID,List<OppLineItem>
        for(TrainingDelegate__c delegate : pConversionWrapper.booking.Training_Delegates__r)
        {
            List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
            OpportunityLineItem courseItem = new OpportunityLineItem();
            /*if(pConversionWrapper.booking.Is_Residential__c)
            {
                if(pConversionWrapper.coursePriceBook != null) {
                    courseItem.PricebookEntryId = pConversionWrapper.coursePriceBook.Id;
                    courseItem.TotalPrice = ( pConversionWrapper.coursePriceBook.UnitPrice - pConversionWrapper.booking.Discount_Value__c) * (1 - pConversionWrapper.booking.Discount_Percentage__c);
                }
            }
            else
            {*/
                courseItem.PricebookEntryId = pConversionWrapper.booking.Pricebook_Entry__c;

                courseItem.TotalPrice = ( pConversionWrapper.booking.Price_Per_Delegate__c - pConversionWrapper.booking.Discount_Value__c ) * (1 - pConversionWrapper.booking.Discount_Percentage__c);
            //}
            courseItem.Quantity = 1;
            courseItem.Training_Event__c = pConversionWrapper.booking.Convert_To_On_Hold__c ? null : pConversionWrapper.booking.Training_Event__c;
            courseItem.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.Start_Date__c;
            courseItem.China_Region__c = pConversionWrapper.booking.Training_Event__r.China_Region__c;
            courseItem.Description = pConversionWrapper.booking.Convert_To_On_Hold__c ? ONHOLD_DESCRIPTION : '';
            oppLineItems.add(courseItem);                

            // Add opportunity line item for accomodation if is_residential is true and
            // delegate accomodation required is also true
            //if(pConversionWrapper.booking.Is_Residential__c)
            //{
                if (delegate.Accommodation_Required__c)
                {
                    OpportunityLineItem accomodationItem = new OpportunityLineItem();
                    accomodationItem.PricebookEntryId = pConversionWrapper.booking.Pricebook_Inc_Accommodation__c;
                    //accomodationItem.TotalPrice = ( (pConversionWrapper.booking.Price_Inc_Accommodation__c - pConversionWrapper.booking.Price_Exc_Accommodation__c) - pConversionWrapper.booking.Discount_Value__c) * (1 - pConversionWrapper.booking.Discount_Percentage__c);
                    accomodationItem.TotalPrice = pConversionWrapper.booking.Price_Per_Delegate_Accommodation__c;
                    accomodationItem.Quantity = 1;
                    accomodationItem.Training_Event__c = pConversionWrapper.booking.Convert_To_On_Hold__c ? null : pConversionWrapper.booking.Training_Event__c;
                    accomodationItem.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.Start_Date__c;
                    accomodationItem.China_Region__c = pConversionWrapper.booking.Training_Event__r.China_Region__c;
                    accomodationItem.Description = pConversionWrapper.booking.Convert_To_On_Hold__c ? ONHOLD_DESCRIPTION : '';
                    oppLineItems.add(accomodationItem);
                }
                if (delegate.Accommodation_night_before__c)
                {
                    OpportunityLineItem accomodationItem = new OpportunityLineItem();
                    accomodationItem.PricebookEntryId = pConversionWrapper.booking.Pricebook_Entry_Extra_Night__c;
                    //accomodationItem.TotalPrice = ( (pConversionWrapper.booking.Price_Inc_Accommodation__c - pConversionWrapper.booking.Price_Exc_Accommodation__c) - pConversionWrapper.booking.Discount_Value__c) * (1 - pConversionWrapper.booking.Discount_Percentage__c);
                    accomodationItem.TotalPrice = pConversionWrapper.booking.Price_Per_Delegate_Extra_Night__c;
                    accomodationItem.Quantity = 1;
                    accomodationItem.Training_Event__c = pConversionWrapper.booking.Convert_To_On_Hold__c ? null : pConversionWrapper.booking.Training_Event__c;
                    accomodationItem.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.Start_Date__c;
                    accomodationItem.China_Region__c = pConversionWrapper.booking.Training_Event__r.China_Region__c;
                    accomodationItem.Description = pConversionWrapper.booking.Convert_To_On_Hold__c ? ONHOLD_DESCRIPTION : '';
                    oppLineItems.add(accomodationItem);
                }
            if (delegate.Online_Exam__c)
            {
                OpportunityLineItem onlineExamItem = new OpportunityLineItem();
                onlineExamItem.PricebookEntryId = pConversionWrapper.booking.Pricebook_Entry_Online_Exam__c;
                onlineExamItem.TotalPrice = pConversionWrapper.booking.Price_Per_Delegate_Online_Exam__c;
                onlineExamItem.Quantity = 1;
                // ADS 21/08/2017 onlineExamItem.Training_Event__c = pConversionWrapper.booking.Convert_To_On_Hold__c ? null : pConversionWrapper.booking.Training_Event__c;
                onlineExamItem.Training_Event__c = pConversionWrapper.booking.Convert_To_On_Hold__c ? null : pConversionWrapper.onlineExamTrainingEvent.Id;                
                // ADS 21/08/2017 onlineExamItem.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.Start_Date__c;
                // ADS 23/08/2017 onlineExamItem.SMOScheduledDate__c = pConversionWrapper.onlineExamTrainingEvent.End_Date__c;
                onlineExamItem.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.End_Date__c;
                onlineExamItem.China_Region__c = pConversionWrapper.booking.Training_Event__r.China_Region__c;
                onlineExamItem.Description = pConversionWrapper.booking.Convert_To_On_Hold__c ? ONHOLD_DESCRIPTION : '';
                oppLineItems.add(onlineExamItem);                
            }
            if (delegate.Standard__c)
            {
                OpportunityLineItem onlineStandardItem = new OpportunityLineItem();
                onlineStandardItem.PricebookEntryId = pConversionWrapper.booking.Pricebook_Entry_Online_Standard__c;
                onlineStandardItem.TotalPrice = pConversionWrapper.booking.Price_Per_Delegate_Online_Standard__c;
                onlineStandardItem.Quantity = 1;
                // ADS 21/08/2017 onlineStandardItem.Training_Event__c = pConversionWrapper.booking.Convert_To_On_Hold__c ? null : pConversionWrapper.booking.Training_Event__c;
                onlineStandardItem.Training_Event__c = null;
                // ADS 21/08/2017 onlineStandardItem.SMOScheduledDate__c = pConversionWrapper.booking.Training_Event__r.Start_Date__c;
                onlineStandardItem.SMOScheduledDate__c = Date.today();
                onlineStandardItem.China_Region__c = pConversionWrapper.booking.Training_Event__r.China_Region__c;
                onlineStandardItem.Description = pConversionWrapper.booking.Convert_To_On_Hold__c ? ONHOLD_DESCRIPTION : '';
                oppLineItems.add(onlineStandardItem);                                
            }
            //}
            pConversionWrapper.onlineBooking_OppLineItems.put(delegate.Id,oppLineItems);
        }
     }

    public static void createEnrollmentsForDelegates(TrainingBookingConversionWrapper pConversionWrapper)
    {
        ID eLearningRecordTypeId = null;
        Map<String, RecordType> enrollmentRecordTypeMap = bg_RecordTypeUtils.GetRecordTypes('Enrollment__c');

        if(enrollmentRecordTypeMap.containsKey(bg_TrainingUtils.ENROLMENT_E_LEARING_DEVELOPER_RECORD_TYPE)){
            eLearningRecordTypeId = enrollmentRecordTypeMap.get(bg_TrainingUtils.ENROLMENT_E_LEARING_DEVELOPER_RECORD_TYPE).Id;
        }
        else pConversionWrapper.setError(Label.Enrollment_RecordType_Error);
         
        for(TrainingDelegate__c td : pConversionWrapper.booking.Training_Delegates__r)
        {
            // Add an enrollment
            Enrollment__c enrollment = new Enrollment__c();
    
            // Set recordTypeIds - derived by the course delivery method
            enrollment.RecordTypeId = pConversionWrapper.enrollmentRecordTypeId;
            /*if (pConversionWrapper.booking.Training_Event__r.Course__r.Delivery_Method__c == COURSE_FORMAT_E_LEARNING)
            {
                enrollment.RecordTypeId = pConversionWrapper.eLearningTypeId;
            }
            else if (pConversionWrapper.booking.Training_Event__r.Course__r.Delivery_Method__c == COURSE_FORMAT_DISTANCE_LEARNING)
            {
                enrollment.RecordTypeId = pConversionWrapper.distanceTypeId;
            }
            else
            {
                enrollment.RecordTypeId = pConversionWrapper.instructorTypeId;
            }*/
    
            // Set mandatory fields
            enrollment.Training_Event__c = pConversionWrapper.booking.Training_Event__c;
            enrollment.Training_Translations__c = pConversionWrapper.booking.Training_Translations__c;
            enrollment.Accomodation__c = deriveEnrollmentAccomodationFromDelegate(td);
            if (pConversionWrapper.booking.Convert_To_On_Hold__c && pConversionWrapper.booking.Quote_Part__r.Product2__r.Is_Exam_Resit__c)
            {
                enrollment.Booking_Status__c = ENROLMENT_BOOKING_STATUS_ONHOLD_RESIT;
            }
            else if (pConversionWrapper.booking.Quote_Part__r.Product2__r.Is_Exam_Resit__c)
            {
                enrollment.Booking_Status__c = ENROLMENT_BOOKING_STATUS_BOOKED_RESIT;
            }
            else if (pConversionWrapper.booking.Convert_To_On_Hold__c)
            {
                enrollment.Booking_Status__c = ENROLMENT_BOOKING_STATUS_ONHOLD_PAYMENT;
            }
            else
            {
                enrollment.Booking_Status__c = ENROLMENT_BOOKING_STATUS_BOOKED;
            }
            // Set payment related fields
            if (pConversionWrapper.booking.Payment_Status__c == BOOKING_PAYMENT_ONLINE || pConversionWrapper.booking.Payment_Status__c == BOOKING_PAYMENT_PHONE)
            {
                enrollment.Invoice_Status__c = ENROLMENT_INVOICE_STATUS_PAYMENT_RECEIVED;
                enrollment.Invoice_Immediately__c = false;
                enrollment.Payment_Transaction_ID__c = pConversionWrapper.booking.Payment_Name__c;     //JS added 04/02/2021 to map Payment Name (asperato id) and Payment Mode
                enrollment.Payment_Mode__c = pConversionWrapper.booking.Payment_Method__c;             //JS added 01/02/2021 to map Payment No and Payment Mode               
                enrollment.Contract_Number__c = pConversionWrapper.booking.SAP_Order_No__c;
                if (pConversionWrapper.booking.Training_Event__r.Course__r.Delivery_Method__c == COURSE_FORMAT_DISTANCE_LEARNING)
                {
                    enrollment.Distance_Learning_Overall_Status__c = STAGENAME_IN_PROGRESS;
                    enrollment.Comments__c = BOOKING_PAYMENT_ONLINE;
                }
            }
            else
            {
                enrollment.Invoice_Status__c = ENROLMENT_INVOICE_STATUS_PENDING;
                if(pConversionWrapper.booking.Delay_Invoice__c){
                    enrollment.Invoice_Immediately__c = false;
                    enrollment.Delayed_Invoice__c = pConversionWrapper.booking.Delay_Invoice__c;
                    enrollment.Delayed_Invoice_Date__c = pConversionWrapper.booking.Delayed_Invoice_Date__c;
                }
                else
                {
                    enrollment.Invoice_Immediately__c = true;
                }
            }
            //25516
            if(pConversionWrapper.booking.CC_Enrolment_Emails__c) enrollment.Bookers_Email__c = pConversionWrapper.booking.Email_Address__c;

            //26482
            enrollment.RelatedTrainingDelegate__c = td.id;

            //PC 20180920 Manage Government Incentive
            enrollment.Manage_Government_Incentive__c = pConversionWrapper.booking.Manage_Government_Incentive__c;
            
            //JS 20190819 Update exam checkbox if linked exam ENR
            if(td.Online_Exam__c) enrollment.Has_linked_Exam_ENR__c = true;


            //PC 20182409 Sales Price - MD  20190121 REMOVED CALCULATION FOR INTERNAL BOOKINGS AS NOT REQUIRED HERE
                enrollment.Sales_Price__c = 0;
            /*    if(pConversionWrapper.booking.Booking_Route__c == bg_TrainingUtils.INTERNAL_BOOKING_ROUTE){
                    enrollment.Sales_Price__c += pConversionWrapper.booking.Price_Per_Delegate__c;
                    if(td.Accommodation_Required__c) enrollment.Sales_Price__c += (pConversionWrapper.booking.Price_Per_Delegate_Accommodation__c / pConversionWrapper.booking.Delegates_Inc_Accommodation__c);
                    if(td.Accommodation_night_before__c) enrollment.Sales_Price__c += pConversionWrapper.booking.Price_Per_Delegate_Extra_Night__c;
                } */
                if(pConversionWrapper.booking.Booking_Route__c == bg_TrainingUtils.ONLINE_BOOKING_ROUTE){ 
                    for(OpportunityLineItem oli : pConversionWrapper.onlineBooking_OppLineItems.get(td.Id)){
                        if(oli.Training_Event__c == pConversionWrapper.booking.Training_Event__c)
                            // THIS IS A COURSE OR ACCOMMODATION OLI, INCLUDE SALES PRICE IN TOTAL (MD 20190129 ADDED IF STATEMENT)
                            enrollment.Sales_Price__c += oli.TotalPrice;
                    }
                }
    
            // add to wrapper
            pConversionWrapper.delegateEnrollments.put(td.Id,enrollment);
            
            if (td.Online_Exam__c &&
                null != eLearningRecordTypeId) // can't create the enrollment if the expected Record Type is not found
            {
                // MD 20190130 Added End Date parameter to ensure that Training Event for correct year is selected
                List<Training_Event__c> examTrainingEvents = getEventsForOnlineExam(pConversionWrapper.booking.Training_Event__r.Course__r.Online_Exam__c,pConversionWrapper.booking.Training_Event__r.End_Date3__c);
                
                if (!examTrainingEvents.isEmpty())
                {
                    Enrollment__c examEnrollment = enrollment.clone();
                    examEnrollment.Training_Event__c = examTrainingEvents[0].Id;
                    examEnrollment.RecordTypeId = eLearningRecordTypeId;

                    //MD 20190129 Sales Price must be explicitly set for Exam Enrolment
                    examEnrollment.Sales_Price__c = 0;
                    if(pConversionWrapper.booking.Booking_Route__c == bg_TrainingUtils.ONLINE_BOOKING_ROUTE){ 
                        for(OpportunityLineItem oli : pConversionWrapper.onlineBooking_OppLineItems.get(td.Id)){
                            if(oli.Training_Event__c == pConversionWrapper.onlineExamTrainingEvent.Id)
                                // THIS IS THE EXAM OLI, INCLUDE SALES PRICE IN TOTAL
                                examEnrollment.Sales_Price__c += oli.TotalPrice;
                        }}
                    pConversionWrapper.delegateOnlineExamEnrollments.put(td.Id, examEnrollment);
                }
                
            }
                        
        }
     }
     public static Map<Id,List<OpportunityLineItem>> fetchRelatedOppLineItemMap(Set<Id> pQuotePartIds)
     {
        Map<Id,List<OpportunityLineItem>> tbId_OppLineItemMap = new Map<Id,List<OpportunityLineItem>>();
        List<OpportunityLineItem> oppLineItems = [SELECT    Id,
                                                            Enrollment__c,
                                                            OpportunityId,
                                                            Quote_Part__c,
                                                            Quote_Part__r.Training_Booking__c,
                                                            Training_Event__c,
                                                            Product2Id,
                                                            ProductAttribute__c
                                                  FROM OpportunityLineItem
                                                  WHERE Quote_Part__c IN : pQuotePartIds];

        for(OpportunityLineItem oli : oppLineItems)
        {
            if(null!=oli.Quote_Part__r.Training_Booking__c)
            {
                if(!tbId_OppLineItemMap.containsKey(oli.Quote_Part__r.Training_Booking__c))
                {
                    List<OpportunityLineItem> oppLineItemsForTb = new List<OpportunityLineItem>();
                    tbId_OppLineItemMap.put(oli.Quote_Part__r.Training_Booking__c,oppLineItemsForTb);    
                }
                tbId_OppLineItemMap.get(oli.Quote_Part__r.Training_Booking__c).add(oli); 
            }
        }
        return tbId_OppLineItemMap;
     }

     public static String deriveEnrollmentAccomodationFromDelegate(TrainingDelegate__c pDelegate)
     {
        String retVal = '';
        if(pDelegate.Accommodation_night_before__c){
            if(pDelegate.Accommodation_Required__c) retVal = ENROLMENT_ACCOMODATION_NIGHT_BEFORE_AND_DURING;
            else retVal = ENROLMENT_ACCOMODATION_NIGHT_BEFORE;
        }else{
            if(pDelegate.Accommodation_Required__c) retVal = ENROLMENT_ACCOMODATION_DURING;
            else retVal = ENROLMENT_ACCOMODATION_NON_RESIDENTIAL;
        }
        return retVal;
     }
    
    /*
        Method to create SMO Update records for Training
    */
    public static boolean runningTrainingCreateSMOUpdates = true;
    public static void ManageTrainingSMOUpdateRecords(list<Training_Event__c> oldTrainingEvents, list<Training_Event__c> updatedTrainingEvents, Map<ID, Training_Event__c> mappedTrainingEvents){
        System.debug('### bg_TrainingUtils.ManageTrainingSMOUpdateRecords');

        // Abort if trigger is firing recursively or after a post-trigger workflow
        if(runningTrainingCreateSMOUpdates) runningTrainingCreateSMOUpdates = false;
        else return;

        // Create an empty Map to hold the SAP number of the referenced Instructors
        Map<Id, decimal> refInstructors = new Map<Id, decimal>();

        // Get all the referenced Instructors
        for (Integer i = 0; i < updatedTrainingEvents.size(); i++)
        {
            // Add distinct Ids to the Map
            if (oldTrainingEvents[i].Trainer__c != null) refInstructors.put(oldTrainingEvents[i].Trainer__c, null);
            if (updatedTrainingEvents[i].Trainer__c != null) refInstructors.put(updatedTrainingEvents[i].Trainer__c, null);
            if (oldTrainingEvents[i].Instructor_3rd__c != null) refInstructors.put(oldTrainingEvents[i].Instructor_3rd__c, null);
            if (updatedTrainingEvents[i].Instructor_3rd__c != null) refInstructors.put(updatedTrainingEvents[i].Instructor_3rd__c, null);
        }   
        
        // Get all the details
        for (Contact instructor : [select Id, Instructor_SAP_number__c from Contact where Id in : refInstructors.keySet()])
        {
            refInstructors.put(instructor.Id, instructor.Instructor_SAP_number__c);
        }

        // Create an empty List to hold the new SMO Update records
        List<SMO_Update__c> newUpdates = new List<SMO_Update__c>();
        
        // Create an empty Set to remember the identified Training Events
        Set<Id> refEvents = new Set<Id>();
                
        // Step through the changes
        for (Integer i = 0; i < updatedTrainingEvents.size(); i++)
        {
            // Only process Training Events that already had a SMO number
            if (oldTrainingEvents[i].SAP_SMO_number__c != null && updatedTrainingEvents[i].SAP_SMO_number__c == oldTrainingEvents[i].SAP_SMO_number__c)
            {
                // Only process changes where the SMO details have been updated         
                if (updatedTrainingEvents[i].SMO_Short_Text__c != oldTrainingEvents[i].SMO_Short_Text__c 
                    || updatedTrainingEvents[i].SMO_Ship_to__c != oldTrainingEvents[i].SMO_Ship_to__c
                    || updatedTrainingEvents[i].Start_Date__c != oldTrainingEvents[i].Start_Date__c
                    || updatedTrainingEvents[i].Trainer__c != oldTrainingEvents[i].Trainer__c
                    || updatedTrainingEvents[i].SMO_Instructor_2__c != oldTrainingEvents[i].SMO_Instructor_2__c
                    || updatedTrainingEvents[i].Instructor_3rd__c != oldTrainingEvents[i].Instructor_3rd__c
                    || (updatedTrainingEvents[i].Event_status__c != oldTrainingEvents[i].Event_status__c && updatedTrainingEvents[i].Event_status__c == 'Cancelled')
                )
                {
                    // Create a new SMO Update record
                    SMO_Update__c newUpdate = new SMO_Update__c();
                    newUpdate.Training_Event__c = updatedTrainingEvents[i].Id;
                    newUpdate.SMO_Number__c = updatedTrainingEvents[i].SAP_SMO_number__c;
                    newUpdate.Old_Description__c = oldTrainingEvents[i].SMO_Short_Text__c;
                    newUpdate.New_Description__c = updatedTrainingEvents[i].SMO_Short_Text__c;
                    newUpdate.Old_Ship_to__c = oldTrainingEvents[i].SMO_Ship_to__c;
                    newUpdate.New_Ship_to__c = updatedTrainingEvents[i].SMO_Ship_to__c;
                    newUpdate.Old_Start_Date__c = oldTrainingEvents[i].Start_Date__c;
                    newUpdate.New_Start_Date__c = updatedTrainingEvents[i].Start_Date__c;
                    newUpdate.Old_Instructor_1__c = refInstructors.get(oldTrainingEvents[i].Trainer__c);
                    newUpdate.New_Instructor_1__c = refInstructors.get(updatedTrainingEvents[i].Trainer__c);
                    if (oldTrainingEvents[i].SMO_Instructor_2__c != null) newUpdate.Old_Instructor_2__c = decimal.valueOf(oldTrainingEvents[i].SMO_Instructor_2__c);
                    if (updatedTrainingEvents[i].SMO_Instructor_2__c != null) newUpdate.New_Instructor_2__c = decimal.valueOf(updatedTrainingEvents[i].SMO_Instructor_2__c);
                    newUpdate.Old_Instructor_3__c = refInstructors.get(oldTrainingEvents[i].Instructor_3rd__c);
                    newUpdate.New_Instructor_3__c = refInstructors.get(updatedTrainingEvents[i].Instructor_3rd__c);
                    newUpdate.Old_Status__c = oldTrainingEvents[i].Event_status__c;
                    newUpdate.New_Status__c = updatedTrainingEvents[i].Event_status__c;
                    newUpdate.Returned_Status__c = 'Pending';
                    newUpdate.Returned_Message__c = '';

                    // Add to the list
                    newUpdates.add(newUpdate);

                    // Remember the distinct Training Event ID
                    if (!refEvents.contains(updatedTrainingEvents[i].Id)) refEvents.add(updatedTrainingEvents[i].Id);
                }
            }
        }
        
        // Process new records (if any were identified)
        if (newUpdates.size() > 0)
        {
            // Update any outstanding requests as Superseded
            for (SMO_Update__c existing : [select Id, Returned_Status__c from SMO_Update__c where Returned_Status__c in ('Pending','Errored') and Training_Event__c in :refEvents])
            {
                existing.Returned_Status__c = 'Superseded';
                newUpdates.add(existing);
            }   
            // Insert the new SMO Updates
            upsert newUpdates;
        }
    }

    public static Boolean isManageEventConfirmationFirstRun = true;
    public static void manageEventConfirmation(List<Training_Event__c> oldTrainingEvents, Map<Id, Training_Event__c> oldMap, List<Training_Event__c> newTrainingEvents, Map<Id, Training_Event__c> newMap){
        System.debug('### bg_TrainingUtils.manageEventConfirmation');

        //if(isManageEventConfirmationFirstRun) isManageEventConfirmationFirstRun = false;
        //else return;

        RecordType ukRecordType = [SELECT Id FROM RecordType WHERE Name = :Label.UK_Public_Event];

        Set<Id> confirmedEventsSet = new Set<Id>();
        for(Training_Event__c te : newTrainingEvents){
            if(te.Event_Confirmed__c && !oldMap.get(te.Id).Event_Confirmed__c && (te.RecordTypeId != ukRecordType.Id)){
                confirmedEventsSet.add(te.Id);
            }
        }
        if(confirmedEventsSet.isEmpty()) return;

        //update related Enrollments
        List<Enrollment__c> enrollmentsToUpdateList = new List<Enrollment__c>();
        for(Enrollment__c e : [SELECT Id FROM Enrollment__c WHERE Training_Event__c IN :confirmedEventsSet]){
            enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Email_Changes__c = true));
        }
        update enrollmentsToUpdateList;
        System.debug('### bg_TrainingUtils.manageEventConfirmation Enrollments updated: ' + enrollmentsToUpdateList.size());
    }
    // 20181212 Removed commenting out of this addition from PC to manage IN-House Sales Price
    public static void manageEventRevenue(Map<Id, Training_Event__c> oldMap, Map<Id, Training_Event__c> newMap){
        System.debug('### bg_TrainingUtils.manageEventRevenue');

        //handle Event Revenue change for In-House Training Event
        List<Training_Event__c> changedRevenueEvents = new List<Training_Event__c>();
        for(Training_Event__c te : newMap.values()){
            if((te.Course_Type_Formula__c == Label.In_House) && (te.Event_Revenue__c != oldMap.get(te.Id).Event_Revenue__c)){
                changedRevenueEvents.add(te);
            }
        }
        if(changedRevenueEvents.isEmpty()) return;

        //update related Enrollments
        List<Enrollment__c> enrollmentsToUpdateList = new List<Enrollment__c>();
        for(Enrollment__c e : [SELECT Training_Event__c FROM Enrollment__c WHERE Inhouse_Booking_Contact__c = true AND Training_Event__c IN :changedRevenueEvents]){
            enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Sales_Price__c = newMap.get(e.Training_Event__c).Event_Revenue__c));
        }
        update enrollmentsToUpdateList;
        System.debug('### bg_TrainingUtils.manageEventRevenue Enrollments updated: ' + enrollmentsToUpdateList.size());
    }
    
    
    /*** MIMEO ***/


    //detect changes to Training Event's Mimeo Distribution Assignment
    public static void manageMimeoDistributionAssignment(Map<Id, Training_Event__c> oldMap, Map<Id, Training_Event__c> newMap){
        System.debug('### bg_TrainingUtils.manageMimeoDistributionAssignment');
    
        if(isMimeoDistributionAssignmentFirstRun) isMimeoDistributionAssignmentFirstRun = false;
        else return;
        
        for(Id teId : newMap.keySet()){
            if(newMap.get(teId).Mimeo_Distribution_Assignment__c && !oldMap.get(teId).Mimeo_Distribution_Assignment__c){
                Training_Event__c event = newMap.get(teId);
                createMimeoDistribution(event.Id, event.Event_Country__c);
            }
        }
    }
    
    //Mimeo createDistribution callout
    @future (callout=true)
    public static void createMimeoDistribution(String eventId, String countryCode){
        System.debug('### bg_TrainingUtils.createDistribution: ' + eventId + ', ' + countryCode);

        //call mimeo create distribution        
        try{
            MimeoAPI mAPI = new MimeoAPI(countryCode);
            MimeoAPI.CreateDistributionResponse distributionResponse = mAPI.createDistribution(eventId);
            
            Training_Event__c event = new Training_Event__c(Id = eventId);

            if(distributionResponse.Success){
                event.Mimeo_Distribution_Created_Date__c = DateTime.now();
                event.Mimeo_Distribution_Id__c = distributionResponse.DistributionId;
                event.Mimeo_Distribution_Link__c = distributionResponse.RedeemKeyUrl;
                event.Mimeo_Error__c = null;
            }else{
                event.Mimeo_Error__c = distributionResponse.ErrorMessage;
            }

            update event;
        }catch(Exception e){
            System.debug('### createDistribution error: ' + e.getMessage());
            update new Training_Event__c(Id = eventId, Mimeo_Error__c = e.getMessage());
        }
    }
    
}