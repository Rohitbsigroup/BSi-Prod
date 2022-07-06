/********************************************************************
 * TrainingBookingFunctionsV3
 *
 * Apex class that converts training bookings.
 * 
 * Unit Tests: TrainingBookingFunctionsv3Test
 *
 * Author: Chris Bacon
 * Created: 10-06-2015
 *
 * Changes
 * Chris Bacon - 25/06/2015
 *  Reworked to update existing opp products for internal sales - smo dates and training event ids now populated via conversion
 * Josh Adams - 17/02/2016
 *  Changed commitWrappers to fix error handling (case 23827) so that Validation Rules will be displaced gracefully
 * James Thornton - 12/08/2016
 *  Case 26482 - edited convert method to populate new VAT fields on the account
 * Maria Dyer - 27/03/208
 *  COPIED SoW034 UPDATES FROM DEV3
 *  (ADS - 28/07/2017 - SoW034 - Online Exam Enhancements)
 * Maria Dyer - 29/01/2019
 *  CHANGES FOR PROJECT 56 RELATED TO ADDITION OF EXAMINATION OPTION TO PACKAGED TRAINING CONFIGURATOR
 *  CHANGES FOR SALES PRICE ON ENROLMENT
 ********************************************************************/
public with sharing class TrainingBookingFunctionsV3 {
    
    public List<TrainingBooking__c> bookings {get; set;}
    public List<bg_TrainingUtils.TrainingBookingConversionWrapper> conversionWrappers {get; set;}
    public Set<Id> trainingBookingIds {get; set;}
    public Map<Id, Product2> productsById {get; set;}
    public ApexPages.StandardController controller {get; set;} 
    public Boolean initialised{get; set;}

    public class trainingBookingConversionException extends Exception{}
    
    // Constructor for manual conversion - via convert button
    public TrainingBookingFunctionsV3(ApexPages.StandardController pController)
    {
        initialised=false;
        trainingBookingIds = new Set<Id>{pController.getRecord().Id};
        controller = pController;
    }   
    // Constructor for trigger context
    public TrainingBookingFunctionsV3(Set<Id> pTrainingBookingIds)
    {
        initialised=false;
        trainingBookingIds = pTrainingBookingIds;
    }
    
    public void convert()
    {       
        if (!initialised)
        {
            Set<Id> quoteIds = new Set<Id>();
            Set<Id> oppIds = new Set<Id>();
            Set<Id> quotePartIds = new Set<Id>();
            
            List<TrainingBooking__c> bookingsForUpdate = new List<TrainingBooking__c>();
            Map<Id,List<OpportunityLineItem>> trainingBookingId_OppLineItems = new Map<Id,List<OpportunityLineItem>>();
            List<bg_TrainingUtils.TrainingBookingConversionWrapper> conversionWrappersForConvert = new List<bg_TrainingUtils.TrainingBookingConversionWrapper>();

            List<OpportunityLineItem> relatedOppLineItems = new List<OpportunityLineItem>();

            // instantiate list of conversion wrappers
            conversionWrappers = new List<bg_TrainingUtils.TrainingBookingConversionWrapper>();

            // Retrieve the booking record with delegate and quote part sub select
            bookings = bg_TrainingUtils.fetchBookingsWithDelegatesAndQuotePartsForConversion(trainingBookingIds);

            for(TrainingBooking__c tb : bookings)
            {
                for(Quote_Part__c qp : tb.Quote_Parts__r)
                {
                    quotePartIds.add(qp.Id);
                }
            }

            // fetch training booking related opps and opp line items
            // Map< TrainingBookingId -> List<OppLineItem> >
            trainingBookingId_OppLineItems = bg_TrainingUtils.fetchRelatedOppLineItemMap(quotePartIds);

            Set<Id> productIds = new Set<Id>();
            for(List<OpportunityLineItem> olis : trainingBookingId_OppLineItems.Values())
            {
                for(OpportunityLineItem oli : olis)
                {
                    productIds.add(oli.Product2Id);
                }
            }
            
            productsById = new Map<Id,Product2>([SELECT Id, 
                                                        Name,
                                                        Course_Format__c,
                                                        Training_Product_Type__c, 
                                                        Course_Delivery__c, 
                                                        RecordTypeId
                                                FROM Product2
                                                WHERE Id IN :productIds]);      

            // Create conversion wrapper for each training booking
            for(TrainingBooking__c tb : bookings){
                if(trainingBookingId_OppLineItems.containsKey(tb.Id))
                {
                    relatedOppLineItems = trainingBookingId_OppLineItems.get(tb.Id);
                }

                // 2nd parameter pIsManualConversion (was the conversion kicked off manually via convert button - this will ensure page messages are created if necessary)          
                conversionWrappers.add(new bg_TrainingUtils.TrainingBookingConversionWrapper(tb, relatedOppLineItems, (null!=Controller) ));
            }
            
            // validate each wrapper - test if safe to convert
            for(bg_TrainingUtils.TrainingBookingConversionWrapper tbcw : conversionWrappers)
            { 
                tbcw.IsReadyToConvert();
                if(tbcw.isSafeToConvert)
                {
                    conversionWrappersForConvert.add(tbcw);
                }
                else{
                    // if this was not a manual conversion update the booking records as the error flag will be checked if not safe to convert
                    if(!tbcw.isManualConversion)
                    {
                        System.debug(logginglevel.ERROR, 'bg### Isn"t safe to convert');
                        bookingsForUpdate.add(tbcw.booking);
                    }
                }
            }
            // run conversion for wrappers which are safe to convert
            try
            {
                convert(conversionWrappersForConvert);
            }
            catch (Exception e)
            {
                System.debug(logginglevel.ERROR, 'bg### wrappers: ' + conversionWrappersForConvert);
                System.debug(logginglevel.ERROR, 'bg### exception type: ' + e);
                System.debug(logginglevel.ERROR, 'bg### exception getCause: ' + e.getCause());
                System.debug(logginglevel.ERROR, 'bg### exception getLineNumber: ' + e.getLineNumber());
                System.debug(logginglevel.ERROR, 'bg### exception getMessage: ' + e.getMessage());
                System.debug(logginglevel.ERROR, 'bg### exception getStackTraceString: ' + e.getStackTraceString());
                System.debug(logginglevel.ERROR, 'bg### exception getTypeName: ' + e.getTypeName());

                for (bg_TrainingUtils.TrainingBookingConversionWrapper wrapperToAddError : conversionWrappersForConvert)
                {
                    wrapperToAddError.resetBooking();
                    wrapperToAddError.setError(e.getMessage());
                    bookingsForUpdate.add(wrapperToAddError.booking);
                }
            }
            // update any non manual failed bookings
            update bookingsForUpdate;
            initialised=true;
        }
    }
    
    private void convert(List<bg_TrainingUtils.TrainingBookingConversionWrapper> pConversionWrappers)
    {
        for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper : pConversionWrappers)
        {
            boolean accountCreated = false;
            if(bg_TrainingUtils.ONLINE_BOOKING_ROUTE == conversionWrapper.booking.Booking_Route__c){
                // check booking does not have a related conversion account
                if (conversionWrapper.booking.Conversion_Account__c == null)
                {
                    accountCreated = true;
                    bg_TrainingUtils.createConversionAccount(conversionWrapper);
                }
                // Case 26482
                // 27/05/2019 PC added new fields for IT VAT
                else if (conversionWrapper.booking.Conversion_Account__r.VAT_Number__c == null ||
                            conversionWrapper.booking.Conversion_Account__r.VAT_Number_NonEU__c == null ||
                            conversionWrapper.booking.Conversion_Account__r.Codice_Fiscale__c == null ||
                            conversionWrapper.booking.Conversion_Account__r.Invoice_Recipient_Code__c == null ||
                            conversionWrapper.booking.Conversion_Account__r.Registered_Email_for_Invoice__c == null||
                            conversionWrapper.booking.Conversion_Account__r.Branch_Number__c == null) // JS added 25/06/2019 for TH VAT change
                {
                    bg_TrainingUtils.updateConversionAccount(conversionWrapper, conversionWrapper.booking.Conversion_Account__r, true);
                }
                // check booking does not have a related conversion contact
                if (conversionWrapper.booking.Conversion_Contact__c == null)
                {
                    bg_TrainingUtils.createConversionContact(conversionWrapper);
                }
                // check booking does not have a related conversion opportunity
                if(conversionWrapper.booking.Conversion_Opportunity__c == null)
                {
                    bg_TrainingUtils.createConversionOpportunity(conversionWrapper, accountCreated);
                    bg_TrainingUtils.createConversionOppContactRole(conversionWrapper);
                }
                bg_TrainingUtils.createOppLineItems(conversionWrapper);
            }
            
            // create contacts for delegates which do not already have a contact associated
            bg_TrainingUtils.createDelegateContacts(conversionWrapper);
            
            // create enrollments for delegates regardless of booking route
            bg_TrainingUtils.createEnrollmentsForDelegates(conversionWrapper);
        }
        // commit records (DML)
        commitWrappers(pConversionWrappers);
    }
    
    private void commitWrappers(List<bg_TrainingUtils.TrainingBookingConversionWrapper> pConversionWrappers){
        List<Account> accsForInsert = new List<Account>();
        List<Contact> consForInsert = new List<Contact>();
        List<Opportunity> oppsForInsert = new List<Opportunity>();
        Set<Opportunity> oppsToSync = new Set<Opportunity>();
        List<OpportunityContactRole> oppConRolesForInsert = new List<OpportunityContactRole>();
        List<OpportunityLineItem> oppLineItemsForUpsert = new List<OpportunityLineItem>();
        List<Enrollment__c> enrollmentsForInsert = new List<Enrollment__c>();
        List<Enrollment__c> onlineExamEnrollmentsForInsert = new List<Enrollment__c>();
        List<TrainingDelegate__c> delegatesForUpdate = new List<TrainingDelegate__c>();
        List<TrainingBooking__c> bookingsForUpdate = new List<TrainingBooking__c>();
        
        System.SavePoint sp = Database.SetSavePoint();
        try
        {
            // pull out any created conversion accounts 
            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper:pConversionWrappers){
                if(null!=conversionWrapper.conversionAccount && null == conversionWrapper.conversionAccount.Id)
                {
                    accsForInsert.add(conversionWrapper.conversionAccount);
                }
            }
            // insert conversion accounts
            insert accsForInsert;
            
            // After we perform an insert the conversionWrappers will magically update with the record ids for the inserted Sobjects
            // this is due to pass by reference and not pass by value just incase your reading the below and are confused ;)
            
            // pull out all conversion contacts and delegate contacts
            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper:pConversionWrappers){
                if(null!=conversionWrapper.conversionContact && null == conversionWrapper.conversionContact.Id)
                {
                    conversionWrapper.conversionContact.AccountId = conversionWrapper.conversionAccount.Id; 
                    consForInsert.add(conversionWrapper.conversionContact);
                }
                for(Id delegateId : conversionWrapper.delegatesForContactCreation.Keyset())
                {
                    if(conversionWrapper.delegatesForContactCreation.containsKey(delegateId))
                    {
                        Contact delegateContact = conversionWrapper.delegatesForContactCreation.get(delegateId);
                        TrainingDelegate__c td = conversionWrapper.trainingDelegateMap.get(delegateId);
                        // check the contact created from the delegate was not the booker as we already have them in the consForInsert list
                        if(!td.Is_Booker__c)
                        {
                            //if(null!=conversionWrapper.conversionAccount)
                            //{
                                System.debug(logginglevel.error, '**TBF conversionAcc** ' + conversionWrapper.conversionAccount.Id);
                                delegateContact.AccountId = conversionWrapper.conversionAccount.Id;
                            /*}
                            else{
                                delegateContact.AccountId = conversionWrapper.booking.Conversion_Account__c;
                            }*/
                            consForInsert.add(delegateContact);
                        } 
                    }
                }
            }
            // insert contacts
            insert consForInsert;
            
            // pull out all conversion opp and populate lookups
            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper:pConversionWrappers)
            {
                if(null!=conversionWrapper.conversionOpportunity)
                {
                    //if(null!=conversionWrapper.conversionAccount)
                    //{
                        conversionWrapper.conversionOpportunity.AccountId = conversionWrapper.conversionAccount.Id; 
                    //}
                    //else
                    //{
                    //  conversionWrapper.conversionOpportunity.AccountId = conversionWrapper.booking.Conversion_Account__c;
                    //}
                    //if(null!=conversionWrapper.conversionContact)
                    //{
                        conversionWrapper.conversionOpportunity.PrimaryContact__c = conversionWrapper.conversionContact.Id;
                    //}
                    //else
                    //{
                    //  conversionWrapper.conversionOpportunity.PrimaryContact__c = conversionWrapper.booking.Conversion_Contact__c;    
                    //}
                    oppsForInsert.add(conversionWrapper.conversionOpportunity);
                    System.debug(System.LoggingLevel.DEBUG, '*** ADS *** conversionOpportunity: ' + conversionWrapper.conversionOpportunity);
                }
            }
            // insert opps
            insert oppsForInsert;
            
            // need to update delegates with contact ids
            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper : pConversionWrappers)
            {
                for(TrainingDelegate__c td : conversionWrapper.booking.Training_Delegates__r)
                {
                    // check the map for the key, its possible the delegate already had a contact associated - if so they will not be in the map
                    if(conversionWrapper.delegatesForContactCreation.containsKey(td.Id))
                    {
                        if(null!=conversionWrapper.delegatesForContactCreation.get(td.Id))
                        {
                            td.Conversion_Contact__c = conversionWrapper.delegatesForContactCreation.get(td.Id).Id; 
                        }
                        else{
                            td.Conversion_Contact__c = conversionWrapper.booking.Conversion_Contact__c; 
                        }
                        
                        delegatesForUpdate.add(td);
                    }
                }
            }
            // update delegates
            update delegatesForUpdate;
            
            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper : pConversionWrappers)
            {
                conversionWrapper.booking.Converted__c = true;
                conversionWrapper.booking.Status__c = bg_TrainingUtils.CONVERSION_TRAININGBOOKING_CONVERTED_STATUS; 
                if(bg_TrainingUtils.ONLINE_BOOKING_ROUTE == conversionWrapper.booking.Booking_Route__c)
                {
                    if(null==conversionWrapper.booking.Conversion_Account__c)
                    {
                        conversionWrapper.booking.Conversion_Account__c = conversionWrapper.conversionAccount.Id;   
                    }
                    if(null==conversionWrapper.booking.Conversion_Contact__c)
                    {
                        conversionWrapper.booking.Conversion_Contact__c = conversionWrapper.conversionContact.Id;   
                    }
                    if(null==conversionWrapper.booking.Conversion_Opportunity__c)
                    {
                        conversionWrapper.booking.Conversion_Opportunity__c = conversionWrapper.conversionOpportunity.Id;   
                    }
                }
                if(conversionWrapper.booking.Conversion_Error__c){
                    conversionWrapper.booking.Conversion_Error__c = false;
                }
                bookingsForUpdate.add(conversionWrapper.booking);
            }
            // update bookings
            update bookingsForUpdate;

            // pull out opportunity contact roles and opplineitems and set oppIds and conIds
            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper : pConversionWrappers)
            {
                for(Id delegateId : conversionWrapper.delegateEnrollments.Keyset())
                {
                    Enrollment__c enrollment = conversionWrapper.delegateEnrollments.get(delegateId);
                    if(conversionWrapper.delegatesForContactCreation.containsKey(delegateId))
                    {
                        if(null!=conversionWrapper.delegatesForContactCreation.get(delegateId))
                        {
                            enrollment.Delegate_Name__c = conversionWrapper.delegatesForContactCreation.get(delegateId).Id; 
                        }
                        else{
                            if(null!=conversionWrapper.booking.Conversion_Contact__c)
                            {
                                enrollment.Delegate_Name__c = conversionWrapper.booking.Conversion_Contact__c;          
                            }
                        }
                        
                    }
                    else if(conversionWrapper.trainingDelegateMap.containsKey(delegateId))
                    {
                        TrainingDelegate__c td = conversionWrapper.trainingDelegateMap.get(delegateId);
                        if(null != td.Conversion_Contact__c)
                        {
                            enrollment.Delegate_Name__c = td.Conversion_Contact__c;     
                        }
                    }
                    if(null!=conversionWrapper.conversionOpportunity)
                    {
                        enrollment.Opportunity__c = conversionWrapper.conversionOpportunity.Id;
                    }
                    else{
                        enrollment.Opportunity__c = conversionWrapper.booking.conversion_Opportunity__c;
                    }
                    enrollmentsForInsert.add(enrollment); 
                }
            }
            //insert enrollments
            insert enrollmentsForInsert;

            // 28/07/2017 ADS - SoW034 - Online Exam Enhancements - Start

            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper : pConversionWrappers)
            {
                for(Id delegateId : conversionWrapper.delegateOnlineExamEnrollments.Keyset())
                {
                    Enrollment__c onLineExamEnrollment = conversionWrapper.delegateOnlineExamEnrollments.get(delegateId);
                    if(conversionWrapper.delegatesForContactCreation.containsKey(delegateId))
                    {
                        if(null!=conversionWrapper.delegatesForContactCreation.get(delegateId))
                        {
                            onLineExamEnrollment.Delegate_Name__c = conversionWrapper.delegatesForContactCreation.get(delegateId).Id; 
                        }
                        else{
                            if(null!=conversionWrapper.booking.Conversion_Contact__c)
                            {
                                onLineExamEnrollment.Delegate_Name__c = conversionWrapper.booking.Conversion_Contact__c;          
                            }
                        }
                        
                    }
                    else if(conversionWrapper.trainingDelegateMap.containsKey(delegateId))
                    {
                        TrainingDelegate__c td = conversionWrapper.trainingDelegateMap.get(delegateId);
                        if(null != td.Conversion_Contact__c)
                        {
                            onLineExamEnrollment.Delegate_Name__c = td.Conversion_Contact__c;     
                        }
                    }
                    if(null!=conversionWrapper.conversionOpportunity)
                    {
                        onLineExamEnrollment.Opportunity__c = conversionWrapper.conversionOpportunity.Id;
                    }
                    else{
                        onLineExamEnrollment.Opportunity__c = conversionWrapper.booking.conversion_Opportunity__c;
                    }

                    // ADS - Course enrollment as the ID is required to set the Master Enrollment                                        
                    Enrollment__c courseEnrollment = conversionWrapper.delegateEnrollments.get(delegateId);
                    onLineExamEnrollment.Master_Enrollment__c = courseEnrollment.Id;
                    onlineExamEnrollmentsForInsert.add(onLineExamEnrollment); 
                }
            }

            insert onlineExamEnrollmentsForInsert;
            
            
            // 28/07/2017 ADS - SoW034 - Online Exam Enhancements - Finish
                        
            // pull out opportunity contact roles and opplineitems and set oppIds and conIds
            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper : pConversionWrappers)
            {
                //oppcontactrole
                if(null!=conversionWrapper.conversionOppContactRole)
                {
                    if(null!=conversionWrapper.conversionOpportunity)
                    {
                        conversionWrapper.conversionOppContactRole.OpportunityId = conversionWrapper.conversionOpportunity.Id;  
                    }
                    else if(null!=conversionWrapper.booking.Conversion_Opportunity__c)
                    {
                        conversionWrapper.conversionOppContactRole.OpportunityId = conversionWrapper.booking.Conversion_Opportunity__c;     
                    }

                    //if(null!=conversionWrapper.conversionContact)
                    //{
                        conversionWrapper.conversionOppContactRole.ContactId = conversionWrapper.conversionContact.Id;  
                    //}
                    //else if(null!=conversionWrapper.booking.Conversion_Contact__c)
                    //{
                    //  conversionWrapper.conversionOppContactRole.ContactId = conversionWrapper.booking.Conversion_Contact__c; 
                    //}
                    oppConRolesForInsert.add(conversionWrapper.conversionOppContactRole); 
                }
                // for each new opp line item - online bookings
                for(Id delegateId : conversionWrapper.onlineBooking_OppLineItems.Keyset())
                {
                    // Iterate over OppLineItems for delegate
                    for(OpportunityLineItem oppLineItem: conversionWrapper.onlineBooking_OppLineItems.get(delegateId))
                    {
                        // MD 20190128 CHANGED TO USE EXAM ENROLMENT WHERE APPROPRIATE
                        if(oppLineItem.Training_Event__c == conversionWrapper.booking.Training_Event__c)
                            // THIS IS A COURSE OR ACCOMMODATION OLI
                            oppLineItem.Enrollment__c = conversionWrapper.delegateEnrollments.get(delegateId).Id;
                        if (conversionWrapper.trainingDelegateMap.get(delegateId).Online_Exam__c && (oppLineItem.Training_Event__c == conversionWrapper.onlineExamTrainingEvent.Id))
                            // THIS IS AN EXAM OLI
                            oppLineItem.Enrollment__c = conversionWrapper.delegateOnlineExamEnrollments.get(delegateId).Id;
                        oppLineItem.OpportunityId = conversionWrapper.conversionOpportunity.Id;
                        oppLineItemsForUpsert.add(oppLineItem);
                    }
                }

                // MD 20190130 BELIEVE THAT THIS CODE IS ONLY APPLICABLE TO INTERNAL SALES
                if(conversionWrapper.booking.Booking_Route__c == bg_TrainingUtils.INTERNAL_BOOKING_ROUTE)
                {
                //categorize available OpportunityLineItems
                List<OpportunityLineItem> oliAccommodationList = new List<OpportunityLineItem>();
                List<OpportunityLineItem> oliExtraNightList = new List<OpportunityLineItem>();
                List<OpportunityLineItem> oliCourseList = new List<OpportunityLineItem>();
                List<OpportunityLineItem> oliExamList = new List<OpportunityLineItem>();

                // for each existing opp line item (All opp line items for the related opp) - Internal Sales
                for(OpportunityLineItem oli : conversionWrapper.existingOppLineItems){
                    if(oli.ProductAttribute__c.containsIgnoreCase('TrainingAccommodation') && (oli.Enrollment__c == null)) oliAccommodationList.add(oli);
                    if(oli.ProductAttribute__c.containsIgnoreCase('TrainingExtraNight') && (oli.Enrollment__c == null)) oliExtraNightList.add(oli);
                    if(oli.ProductAttribute__c.containsIgnoreCase('TrainingCourse') && (oli.Enrollment__c == null)) oliCourseList.add(oli);
                    if(oli.ProductAttribute__c.containsIgnoreCase('OnlineExam') && (oli.Enrollment__c == null)) oliExamList.add(oli);

                    // find the related quote part which created this opp line item
                    for(Quote_Part__c qp : conversionWrapper.booking.Quote_Parts__r){
                        if(qp.Id == oli.Quote_Part__c){
                            // update the opp line item with the bookings training event id
                            if(conversionWrapper.booking.Convert_To_On_Hold__c) oli.Description = bg_TrainingUtils.ONHOLD_DESCRIPTION;
                            else //MD 20190129 CHOOSE CORRECT TRAINING EVENT
                                {if (oli.ProductAttribute__c.containsIgnoreCase('OnlineExam')) oli.Training_Event__c = conversionWrapper.onlineExamTrainingEvent.Id;
                                 else oli.Training_Event__c = conversionWrapper.booking.Training_Event__c;    
                                }
                            Opportunity oliParentOpp = new Opportunity(Id=oli.OpportunityId);
                            oppsToSync.add(oliParentOpp);
                            oppLineItemsForUpsert.add(oli);
                        }
                    }
                }

                System.debug('### oliAccommodationList.size: ' + oliAccommodationList.size());
                System.debug('### oliExtraNightList.size: ' + oliExtraNightList.size());
                System.debug('### oliCourseList.size: ' + oliCourseList.size());
                System.debug('### oliExamList.size: ' + oliExamList.size());
                //PC K2 20182310 populate Enrollment Id on OpportunityLineItems for Internal Sales
                //loop through all Delegates
                for(TrainingDelegate__c td : conversionWrapper.booking.Training_Delegates__r){
                    //only for Internal Sale and not In-House MD 20190129 STRANGE WAY OF CHECKING FOR INTERNAL SALE - CHANGED TO USE BOOKING_ROUTE
                    //if(!conversionWrapper.onlineBooking_OppLineItems.containsKey(td.Id) && conversionWrapper.booking.Training_Event__r.Course_Type_Formula__c != Label.In_House){
                    if(conversionWrapper.booking.Booking_Route__c == bg_TrainingUtils.INTERNAL_BOOKING_ROUTE  && conversionWrapper.booking.Training_Event__r.Course_Type_Formula__c != Label.In_House){
                        //fetch related Enrollment
                        Id enrollmentId = conversionWrapper.delegateEnrollments.get(td.Id).Id;
                        if(td.Accommodation_Required__c && !oliAccommodationList.isEmpty()){
                            System.debug('### populating oli accommodation');
                            oliAccommodationList[0].Enrollment__c = enrollmentId;
                            oliAccommodationList.remove(0);
                        }
                        if(td.Accommodation_night_before__c && !oliExtraNightList.isEmpty()){
                            System.debug('### populating oli extra night');
                            oliExtraNightList[0].Enrollment__c = enrollmentId;
                            oliExtraNightList.remove(0);
                        }
                        if(!oliCourseList.isEmpty()){
                            System.debug('### populating oli course');
                            oliCourseList[0].Enrollment__c = enrollmentId;
                            oliCourseList.remove(0);
                        }
                        if(td.Online_Exam__c && !oliExamList.isEmpty()){
                            System.debug('### populating oli exam');
                            Id examEnrollmentId = conversionWrapper.delegateOnlineExamEnrollments.get(td.Id).Id;
                            oliExamList[0].Enrollment__c = examEnrollmentId;
                            oliExamList.remove(0);
                        }
                    }
                }
                System.debug('### oliAccommodationList.size: ' + oliAccommodationList.size());
                System.debug('### oliExtraNightList.size: ' + oliExtraNightList.size());
                System.debug('### oliCourseList.size: ' + oliCourseList.size());
                System.debug('### oliExamList.size: ' + oliExamList.size());

                bg_TrainingUtils.setSMOScheduledDate(conversionWrapper, productsById);
            }
            } //MD 20190130 END OF EXTRA IF STATEMENT
            
            // insert opp contact roles
            insert oppConRolesForInsert;
            
            System.debug(System.LoggingLevel.DEBUG, '*** ADS *** oppsToSync: ' + oppsToSync);
            
            // upsert opplineitems - we need to flip the trigger lock and set the opps to sync as it is possible we will be updating opp line items
            Utility.lockOptyTrigger = true;
            bg_OpportunityUtils.SetOpportunitySyncFlag(oppsToSync);
            upsert oppLineItemsForUpsert;
            bg_OpportunityUtils.ClearOpportunitySyncFlag(oppsToSync); 
            
            //if manual conversion set success page message - there should only ever be 1 if a manual conversion
            for(bg_TrainingUtils.TrainingBookingConversionWrapper conversionWrapper : pConversionWrappers)
            {
                if(conversionWrapper.isManualConversion)
                {
                    conversionWrapper.setSuccessMessage(System.Label.TrainingBooking_Success);
                }
            }
            
            if (!oppsForInsert.isEmpty())
            {
                Utility.lockOptyTrigger = true;
                bg_OpportunityUtils.ClearOpportunitySyncFlag(new Set<Opportunity>(oppsForInsert));
            }
            
        }
        catch(DMLException dmlex)
        {

            database.rollback(sp);
            System.debug(logginglevel.ERROR, 'bg### DML Exception: ' + dmlex);
            throw new trainingBookingConversionException(System.Label.TrainingBooking_Conversion_Error + dmlex.getDmlMessage(0));
        }
        catch(Exception ex)
        {
            database.rollback(sp);
            throw new trainingBookingConversionException(System.Label.TrainingBooking_Conversion_Error + ex.getMessage() + ' StackTrace: '+ex.getStacktraceString());
        }
    }
}