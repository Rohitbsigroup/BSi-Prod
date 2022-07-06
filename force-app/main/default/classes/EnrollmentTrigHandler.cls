public with sharing class EnrollmentTrigHandler {
    
    /*
    * Enrolement Trigger Handler
    * Created By:  Philip Holtom (philip.holtom@opensymmetry.com)
    * Update By Vimlesh Azad (June 2017) - 
    * Purpose: Create a user in Litmos LMS based on an enrolment to an online training  on last day of course training event.
    * Called By: Trigger - EnrollmentTriggers
    * Date: Feb 2013
    * Version History: 
    * 1.0 - Feb 2013 - Created.
    *
    *  change log
    *  PC K2           08-08-18    moved sets of Workflow Rules to OnAfterInsert and OnBeforeUpdate
    *  MD              14-03-19    modified OnAfterUpdate to fix known issues
    *  PC K2           16-07-19    added OnBeforeUpdate - Exam email
    *  PC K2           16-02-20    rewritten onAfterUpdate
    *  JS              17-02-20    updated the Email for Exams to also inlude e-learning
    *  PC K2           16-05-20    added manageMimeoKeyAssignment
    *  PC K2           25-05-20    added manageMimeoRevokeKey
    *  PC K2           03-09-20    updated email code for portal emails
    *  JS              21-10-21    updates for blockchain - tracelabs API logic and emails
    *  JS              23-11-21    updates for emails which were sending for future e-learning courses
    */
    
        public static Boolean bypassTrigger = false;
        public static Boolean isBeforeUpdateFirstRun = true;
        public static Boolean isAfterUpdateFirstRun = true;
        public static Boolean isManageMimeoKeyAssignmentFirstRun = true;
        public static Boolean isManageMimeoRevokeKeyFirstRun = true;
        public static Boolean isUploadEnrollmentCertificatesFirstRun = true;
        private static Boolean m_isExecuting = false;
        public static Integer BatchSize = 0;
        public static Boolean testrunning = true;
        
        
        // Constructor
        public EnrollmentTrigHandler(boolean isExecuting, integer size){
            m_isExecuting = isExecuting;
            BatchSize = size;
            system.debug(' :BatchSize  : ' + BatchSize );
        }
    
        public void onBeforeInsert(List<Enrollment__c> newEnrollmentList){
            System.debug('### EnrollmentTrigHandler.onBeforeInsert');
    
            Set<Id> trainingEventSet = new Set<Id>();
            for(Enrollment__c e : newEnrollmentList){
                trainingEventSet.add(e.Training_Event__c);
            }
    
            Map<Id, Training_Event__c> trainingEventMap = new Map<Id, Training_Event__c>([SELECT Course_Type_Formula__c, Event_Revenue__c FROM Training_Event__c WHERE Id IN :trainingEventSet]);
    
            //PC K2 20181026 calculate Sales Price
            for(Enrollment__c e : newEnrollmentList){
                //In-House Booking Contact of In-House Training Event
                if(e.Inhouse_Booking_Contact__c && (trainingEventMap.get(e.Training_Event__c).Course_Type_Formula__c == Label.In_House)){
                    e.Sales_Price__c = trainingEventMap.get(e.Training_Event__c).Event_Revenue__c;
                }
                //cancelled Enrollment
                if(e.Booking_status__c.containsIgnoreCase('cancelled')){
                    e.Sales_Price__c = 0;
                }
            }
        }

        /**
         * Get Set<Id> with the contacts to create portal users
         *
         * @param newEnrollmentList List<Enrollment__c> list with new enrollments inserted
         * @param newEnrollmentMap  Map<Id, Enrollment__c> newEnrollmentMap map of the enrollments inserted
         *
        * @return Set<Id> ids of contacts to create portal users
        */
        private Set<Id> getEnrollmentContactsInsert(List<Enrollment__c> newEnrollmentList, Map<Id, Enrollment__c> newEnrollmentMap){
            Set<ID> contactIds = new Set<ID>();

            Map<Id, Enrollment__c> enrolllmentMap = new Map<Id, Enrollment__c>(
                [SELECT Available_In_Portal_Override__c, Delegate_name__c, Booking_status__c, Portal_Access__c, 
                    Training_Translations__r.Client_Learning_Portal_on__c, Training_Event__r.Course__r.Show_in_Portal__c 
                FROM Enrollment__c WHERE Id IN :newEnrollmentMap.keySet()]
            );

            for(Enrollment__c e : newEnrollmentList){
                Enrollment__c enr = enrolllmentMap.get(e.Id);
                if(
                    enr.Available_In_Portal_Override__c != 'Hide' && 
                    enr.Booking_status__c.contains('Booked') && 
                    enr.Portal_Access__c == null && 
                    enr.Training_Translations__r.Client_Learning_Portal_on__c && 
                    enr.Training_Event__r.Course__r.Show_in_Portal__c
                ){
                    contactIds.add(enr.Delegate_name__c);
                }
                
            }
            return contactIds;
        }
        
        public void onAfterInsert(List<Enrollment__c> newEnrollmentList, Map<Id, Enrollment__c> newEnrollmentMap){
            System.debug('### EnrollmentTrigHandler.OnAfterInsert');
    
            //CloudShift Logic
            Set<ID> contactIds = getEnrollmentContactsInsert(newEnrollmentList, newEnrollmentMap);
            //call trigger handler to create new users
            if(!contactIds.isEmpty()){
                System.debug('Set of contacts: ' + contactIds);
                if(!System.isFuture()){
                    UserCreationService.createUsersFromEnrollments(contactIds);
                }
            }
            //CloudShift end of the logic
    
            Set<Id> trainingEventSet = new Set<Id>();
            Set<Id> trainingTranslationSet = new Set<Id>();
            for(Enrollment__c e : newEnrollmentList){
                trainingEventSet.add(e.Training_Event__c);
                trainingTranslationSet.add(e.Training_Translations__c);
            }
    
            Map<Id, Training_Event__c> trainingEventMap = new Map<Id, Training_Event__c>([SELECT Cancelled_1_0__c, Course_Type_Formula__c, Enable_pdf_certificate_emails__c, Enable_automated_email_confirmation__c, Event_Confirmed__c, Event_Revenue__c, Event_status__c, MEA_Region__c, Product_Code__c, Course__r.Bespoke_Event__c, Course__r.Course_Format__c, Course__r.Delivery_Method__c, Course__r.Show_in_Portal__c FROM Training_Event__c WHERE Id IN :trainingEventSet]);
            Map<Id, Training_Translations__c> trainingTranslationMap = new Map<Id, Training_Translations__c>([SELECT Additional_Emails__c,Certificate_verification__c, Enable_Booking_Confirmation_BIH_Emails__c, Enable_Booking_Confirmation_IH_Emails__c, Enable_Confirmation_of_Place_Emails__c, Enable_Course_Update_Emails__c, Enable_Delivery_Confirmation_ACC_Emails__c, Enable_Delivery_Confirmation_WCC_Emails__c, Enable_Exam_Emails__c, Enable_PDF_Certificate_Emails__c, Enable_Resit_Confirmation_Emails__c, From_Email_Address__c, Send_Email_to_IH_Booking_Contacts_Only__c FROM Training_Translations__c WHERE Id IN :trainingTranslationSet]);
    
            Set<Id> enrollmentsToEmailIdSet_PlaceConfirmation = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_ResitConfirmation = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_BookingConfirmationIH = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_BookingConfirmationBespokeIH = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_DeliveryConfirmationACC = new Set<Id>();
    
            List<Enrollment__c> enrollmentsToUpdateList = new List<Enrollment__c>();
    
            for(Enrollment__c e : newEnrollmentList){
                Training_Event__c event = trainingEventMap.get(e.Training_Event__c);
                Training_Translations__c translation = trainingTranslationMap.get(e.Training_Translations__c);
                if((event == null) || (translation == null)) continue;
    
                //Send Confirmation of Place email
                if(
                    !e.Available_In_Portal__c && 
                    translation.Enable_Confirmation_of_Place_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    (event.Course_Type_Formula__c != Label.In_House) && 
                    (Integer.valueOf(event.Cancelled_1_0__c) == 0) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) &&
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    !event.Event_Confirmed__c && 
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee)
                ){
                    System.debug('### OnAfterInsert trigger - ' + Label.Confirmation_of_Place);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Email_Confirmation_Sent__c = true));
                    enrollmentsToEmailIdSet_PlaceConfirmation.add(e.Id);
                }
    
                //Send Resit Confirmation email
                if(
                    !e.Available_In_Portal__c && 
                    translation.Enable_Resit_Confirmation_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    (event.Course__r.Delivery_Method__c != Label.Distance_Learning) && 
                    (event.Course_Type_Formula__c != Label.In_House) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_Resit || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee_Resit)
                ){
                    System.debug('### OnAfterInsert trigger - ' + Label.Resit_Confirmation);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Email_Confirmation_Sent__c = true, Course_Confirmed_Email_Sent__c = Datetime.now()));
                    enrollmentsToEmailIdSet_ResitConfirmation.add(e.Id);
                }
    
                //Send Booking Confirmation In-House email
                if(
                    !e.Available_In_Portal__c && 
                    translation.Enable_Booking_Confirmation_IH_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    !event.Course__r.Bespoke_Event__c && 
                    (!translation.Send_Email_to_IH_Booking_Contacts_Only__c || (translation.Send_Email_to_IH_Booking_Contacts_Only__c && e.Inhouse_Booking_Contact__c)) && 
                    (event.Course_Type_Formula__c != null) && 
                    (event.Course_Type_Formula__c.contains(Label.In_House)) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) &&
                    event.course__r.Course_Format__c != 'E-Learning' && 
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked)
                ){
                    System.debug('### OnAfterInsert trigger - ' + Label.Booking_Confirmation_In_House);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Email_Confirmation_Sent__c = true, Course_Confirmed_Email_Sent__c = Datetime.now()));
                    enrollmentsToEmailIdSet_BookingConfirmationIH.add(e.Id);
                }
    
                //Send Booking Confirmation Bespoke In-House email
                if(
                    !e.Available_In_Portal__c && 
                    translation.Enable_Booking_Confirmation_BIH_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    event.Course__r.Bespoke_Event__c && 
                    (!translation.Send_Email_to_IH_Booking_Contacts_Only__c || (translation.Send_Email_to_IH_Booking_Contacts_Only__c && e.Inhouse_Booking_Contact__c)) && 
                    (event.Course_Type_Formula__c != null) && 
                    (event.Course_Type_Formula__c.contains(Label.In_House)) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked)
                ){
                    System.debug('### OnAfterInsert trigger - ' + Label.Booking_Confirmation_Bespoke_In_House);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Email_Confirmation_Sent__c = true, Course_Confirmed_Email_Sent__c = Datetime.now()));
                    enrollmentsToEmailIdSet_BookingConfirmationBespokeIH.add(e.Id);
                }
    
                //Send Delivery Confirmation After Course Confirmed email
                if(
                    !e.Available_In_Portal__c && 
                    translation.Enable_Delivery_Confirmation_ACC_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    (event.Course_Type_Formula__c != Label.In_House) && 
                    (Integer.valueOf(event.Cancelled_1_0__c) == 0) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    event.Event_Confirmed__c &&
                    e.Course_Confirmed_Email_Sent__c == null && 
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee)
                ){
                    System.debug('### OnAfterInsert trigger - ' + Label.Delivery_Confirmation_ACC);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Email_Confirmation_Sent__c = true, Course_Confirmed_Email_Sent__c = Datetime.now()));
                    enrollmentsToEmailIdSet_DeliveryConfirmationACC.add(e.Id);
                }
            }
    
            update enrollmentsToUpdateList;
    
            if(!System.isFuture() && !System.isBatch()){
                if(!enrollmentsToEmailIdSet_PlaceConfirmation.isEmpty()) System.enqueueJob(new EnrollmentEmailService(enrollmentsToEmailIdSet_PlaceConfirmation, Label.Confirmation_of_Place));
                if(!enrollmentsToEmailIdSet_ResitConfirmation.isEmpty()) System.enqueueJob(new EnrollmentEmailService(enrollmentsToEmailIdSet_ResitConfirmation, Label.Resit_Confirmation));
                if(!enrollmentsToEmailIdSet_BookingConfirmationIH.isEmpty()) System.enqueueJob(new EnrollmentEmailService(enrollmentsToEmailIdSet_BookingConfirmationIH, Label.Booking_Confirmation_In_House));
                if(!enrollmentsToEmailIdSet_BookingConfirmationBespokeIH.isEmpty()) System.enqueueJob(new EnrollmentEmailService(enrollmentsToEmailIdSet_BookingConfirmationBespokeIH, Label.Booking_Confirmation_Bespoke_In_House));
                if(!enrollmentsToEmailIdSet_DeliveryConfirmationACC.isEmpty()) System.enqueueJob(new EnrollmentEmailService(enrollmentsToEmailIdSet_DeliveryConfirmationACC, Label.Delivery_Confirmation_ACC));
            }else{
                Map<String, Set<Id>> emailTypeEnrollmentIdsMap = new Map<String, Set<Id>>();
                if(!enrollmentsToEmailIdSet_PlaceConfirmation.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Confirmation_of_Place, enrollmentsToEmailIdSet_PlaceConfirmation);
                if(!enrollmentsToEmailIdSet_ResitConfirmation.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Resit_Confirmation, enrollmentsToEmailIdSet_ResitConfirmation);
                if(!enrollmentsToEmailIdSet_BookingConfirmationIH.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Booking_Confirmation_In_House, enrollmentsToEmailIdSet_BookingConfirmationIH);
                if(!enrollmentsToEmailIdSet_BookingConfirmationBespokeIH.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Booking_Confirmation_Bespoke_In_House, enrollmentsToEmailIdSet_BookingConfirmationBespokeIH);
                if(!enrollmentsToEmailIdSet_DeliveryConfirmationACC.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Delivery_Confirmation_ACC, enrollmentsToEmailIdSet_DeliveryConfirmationACC);
                
                if(!emailTypeEnrollmentIdsMap.isEmpty()){
                    System.debug('### sending EnrollmentEmailServiceSync from onAfterInsert, email size: ' + emailTypeEnrollmentIdsMap.size());
                    EnrollmentEmailServiceSync.sendEmail(emailTypeEnrollmentIdsMap);
                }
            }
        }
        
        public void onBeforeUpdate(Map<Id, Enrollment__c> oldMap, Map<Id, Enrollment__c> newMap){
            System.debug('### EnrollmentTrigHandler.OnBeforeUpdate');
    
            if(isBeforeUpdateFirstRun) isBeforeUpdateFirstRun = false;
            else return;
    

            Set<Id> contactSet = new Set<Id>();
            Set<Id> trainingEventSet = new Set<Id>();
            Set<Id> trainingTranslationSet = new Set<Id>();
            for(Enrollment__c e : newMap.values()){
                contactSet.add(e.Delegate_Name__c);
                trainingEventSet.add(e.Training_Event__c);
                trainingTranslationSet.add(e.Training_Translations__c);
            }

            Map<Id, Training_Event__c> trainingEventMap = new Map<Id, Training_Event__c>([SELECT Cancelled_1_0__c, Course_Type_Formula__c, Change_of_Date__c, Change_of_Venue__c, Enable_pdf_certificate_emails__c, Enable_automated_email_confirmation__c, Event_Confirmed__c, Event_Revenue__c, Event_status__c, MEA_Region__c, Product_Code__c, Course__r.Bespoke_Event__c, Course__r.Course_Format__c, Course__r.Delivery_Method__c, Course__r.Show_in_Portal__c FROM Training_Event__c WHERE Id IN :trainingEventSet]); // JS added in Show in Portal 
            Map<Id, Training_Translations__c> trainingTranslationMap = new Map<Id, Training_Translations__c>([SELECT Additional_Emails__c,Certificate_verification__c, Enable_Booking_Confirmation_BIH_Emails__c, Enable_Booking_Confirmation_IH_Emails__c, Enable_Confirmation_of_Place_Emails__c, Enable_Course_Update_Emails__c, Enable_Delivery_Confirmation_ACC_Emails__c, Enable_Delivery_Confirmation_WCC_Emails__c, Enable_Exam_Emails__c, Enable_PDF_Certificate_Emails__c, Enable_Resit_Confirmation_Emails__c, From_Email_Address__c, Send_Email_to_IH_Booking_Contacts_Only__c FROM Training_Translations__c WHERE Id IN :trainingTranslationSet]);
            Map<Id, User> contactUserMap = new Map<Id, User>();
            for(User u : [SELECT ContactId, LastLoginDate FROM User WHERE ContactId IN :contactSet]){
                contactUserMap.put(u.ContactId, u);
            }
                
            //PC K2 20181026 calculate Sales Price
            for(Enrollment__c e : newMap.values()){
                //In-House Booking Contact of In-House Training Event
                if(e.Inhouse_Booking_Contact__c && (trainingEventMap.get(e.Training_Event__c).Course_Type_Formula__c == Label.In_House)){
                    e.Sales_Price__c = trainingEventMap.get(e.Training_Event__c).Event_Revenue__c;
                }
                //cancelled Enrollment
                if(e.Booking_status__c.containsIgnoreCase('cancelled')){
                    e.Sales_Price__c = 0;
                }
            }
        }


        /**
         * Get Set<Id> with the contacts to create portal users
         *
         * @param enrollmentOldList List<Enrollment__c> list with old existing enrollments
         * @param enrollmentNewMap  Map<Id, Enrollment__c> newEnrollmentMap map of the enrollments updated
         *
        * @return Set<Id> ids of contacts to create portal users
        */
        private Set<Id> getEnrollmentContactsUpdate(List<Enrollment__c> enrollmentOldList, Map<Id, Enrollment__c> enrollmentNewMap){
            Set<Id> contactIds = new Set<Id>();

            Map<Id, Enrollment__c> enrolllmentMap = new Map<Id, Enrollment__c>(
                [SELECT Available_In_Portal_Override__c, Delegate_name__c, Booking_status__c, Portal_Access__c, 
                    Could_not_create_user__c, Training_Translations__r.Client_Learning_Portal_on__c, Training_Event__r.Course__r.Show_in_Portal__c 
                FROM Enrollment__c WHERE Id IN :enrollmentNewMap.keySet()]
            );

            for(Enrollment__c eOld : enrollmentOldList){
                Enrollment__c enr = enrolllmentMap.get(eOld.Id);
                if(
                    enr.Available_In_Portal_Override__c != 'Hide' && 
                    enr.Booking_status__c.contains('Booked') && 
                    (
                        (!enr.Could_not_create_user__c && enr.Could_not_create_user__c != eOld.Could_not_create_user__c) || 
                        (enr.Booking_status__c != eOld.Booking_status__c && enr.Portal_Access__c == null)
                    ) && 
                    enr.Training_Translations__r.Client_Learning_Portal_on__c && 
                    enr.Training_Event__r.Course__r.Show_in_Portal__c

                ){
                    contactIds.add(enr.Delegate_name__c);
                }
            }
            
            return contactIds;
        }
    
        //This handles the situation where an online training assigned tickbox is ticked and enrollment status is booked.
        //Litmos user creation is based on a checkbox value "Online_Training_Assigned__c = true" that will trigger on or after update function
        public void onAfterUpdate(List<Enrollment__c> enrollmentNewList, List<Enrollment__c> enrollmentOldList, Map<Id, Enrollment__c> enrollmentNewMap, Map<Id, Enrollment__c> enrollmentOldMap){
            System.debug('### EnrollmentTrigHandler.OnAfterUpdate');
            System.debug('### BatchSize: ' + BatchSize);
            System.debug('*** First Enrolment ***' + enrollmentNewList[0].Id);
    
            //CloudShift Logic
            //Set of Enrollment Ids - Status is Booked
            Set<ID> contactIds = getEnrollmentContactsUpdate(enrollmentOldList, enrollmentNewMap);
            //call trigger handler to create new users
            if(!contactIds.isEmpty()){
                System.debug('Set of contacts: ' + contactIds);
                if(!System.isFuture()){
                    UserCreationService.createUsersFromEnrollments(contactIds);
                }
            }
            //CloudShift end of the logic
    
            // Abort if trigger is firing recursively or after a post-trigger workflow
            if(isAfterUpdateFirstRun) isAfterUpdateFirstRun = false;
            else return;
            

            //TRIGGER EMAIL REWORK START
            Set<Id> contactSet = new Set<Id>();
            Set<Id> trainingEventSet = new Set<Id>();
            Set<Id> trainingTranslationSet = new Set<Id>();
            for(Enrollment__c e : enrollmentNewMap.values()){
                contactSet.add(e.Delegate_Name__c);
                trainingEventSet.add(e.Training_Event__c);
                trainingTranslationSet.add(e.Training_Translations__c);
            }

            Map<Id, Training_Event__c> trainingEventMap = new Map<Id, Training_Event__c>([SELECT Cancelled_1_0__c, Course_Type_Formula__c, Change_of_Date__c, Change_of_Venue__c, Enable_pdf_certificate_emails__c, Enable_automated_email_confirmation__c, Event_Confirmed__c, Event_Revenue__c, Event_status__c, MEA_Region__c, Product_Code__c, Course__r.Bespoke_Event__c, Course__r.Course_Format__c, Course__r.Delivery_Method__c, Course__r.Show_in_Portal__c FROM Training_Event__c WHERE Id IN :trainingEventSet]);
            Map<Id, Training_Translations__c> trainingTranslationMap = new Map<Id, Training_Translations__c>([SELECT Additional_Emails__c, Certificate_verification__c, Enable_Booking_Confirmation_BIH_Emails__c, Enable_Booking_Confirmation_IH_Emails__c, Enable_Confirmation_of_Place_Emails__c, Enable_Course_Update_Emails__c, Enable_Delivery_Confirmation_ACC_Emails__c, Enable_Delivery_Confirmation_WCC_Emails__c, Enable_Exam_Emails__c, Enable_PDF_Certificate_Emails__c, Enable_Resit_Confirmation_Emails__c, From_Email_Address__c, Send_Email_to_IH_Booking_Contacts_Only__c FROM Training_Translations__c WHERE Id IN :trainingTranslationSet]);
            Map<Id, User> contactUserMap = new Map<Id, User>();
            for(User u : [SELECT ContactId, LastLoginDate FROM User WHERE ContactId IN :contactSet]){
                contactUserMap.put(u.ContactId, u);
            }
            
            Set<Id> enrollmentsToEmailIdSet_BCcert = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_PDFcert = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_PlaceConfirmation = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_ResitConfirmation = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_BookingConfirmationIH = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_BookingConfirmationBespokeIH = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_DeliveryConfirmationACC = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_DeliveryConfirmationWCC = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_CourseUpdate = new Set<Id>();
            Set<Id> enrollmentsToEmailIdSet_Exam = new Set<Id>();
    
            List<Enrollment__c> enrollmentsToUpdateList = new List<Enrollment__c>();
            for(Enrollment__c e : enrollmentNewMap.values()){
                Training_Event__c event = trainingEventMap.get(e.Training_Event__c);
                Training_Translations__c translation = trainingTranslationMap.get(e.Training_Translations__c);
                User u = contactUserMap.get(e.Delegate_Name__c);
                if((event == null) || (translation == null)) continue;
                  
                //Send Confirmation of Place email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_Confirmation_of_Place_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    (event.Course_Type_Formula__c != Label.In_House) && 
                    (Integer.valueOf(event.Cancelled_1_0__c) == 0) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    !event.Event_Confirmed__c && 
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Confirmation_of_Place);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Email_Confirmation_Sent__c = true));
                    enrollmentsToEmailIdSet_PlaceConfirmation.add(e.Id);
                }
    
                //Send Resit Confirmation email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_Resit_Confirmation_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    (event.Course__r.Delivery_Method__c != Label.Distance_Learning) && 
                    (event.Course_Type_Formula__c != Label.In_House) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_Resit || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee_Resit)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Resit_Confirmation);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Course_Confirmed_Email_Sent__c = Datetime.now(), Email_Confirmation_Sent__c = true));
                    enrollmentsToEmailIdSet_ResitConfirmation.add(e.Id);
                }
    
                //Send Booking Confirmation In-House email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_Booking_Confirmation_IH_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    !event.Course__r.Bespoke_Event__c && 
                    (!translation.Send_Email_to_IH_Booking_Contacts_Only__c || (translation.Send_Email_to_IH_Booking_Contacts_Only__c && e.Inhouse_Booking_Contact__c)) && 
                    (event.Course_Type_Formula__c != null) && 
                    (event.Course_Type_Formula__c.contains(Label.In_House)) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Booking_Confirmation_In_House);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Course_Confirmed_Email_Sent__c = Datetime.now(), Email_Confirmation_Sent__c = true));
                    enrollmentsToEmailIdSet_BookingConfirmationIH.add(e.Id);
                }
    
                //Send Booking Confirmation Bespoke In-House email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_Booking_Confirmation_BIH_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    event.Course__r.Bespoke_Event__c && 
                    (!translation.Send_Email_to_IH_Booking_Contacts_Only__c || (translation.Send_Email_to_IH_Booking_Contacts_Only__c && e.Inhouse_Booking_Contact__c)) && 
                    (event.Course_Type_Formula__c != null) && 
                    (event.Course_Type_Formula__c.contains(Label.In_House)) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Booking_Confirmation_Bespoke_In_House);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Course_Confirmed_Email_Sent__c = Datetime.now(), Email_Confirmation_Sent__c = true));
                    enrollmentsToEmailIdSet_BookingConfirmationBespokeIH.add(e.Id);
                }
    
                //Send Delivery Confirmation When Course Confirmed email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_Delivery_Confirmation_WCC_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    (event.Course_Type_Formula__c != Label.In_House) && 
                    (Integer.valueOf(event.Cancelled_1_0__c) == 0) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    event.Event_Confirmed__c &&
                    e.Course_Confirmed_Email_Sent__c == null && 
                    e.Email_Confirmation_Sent__c && 
                    e.Email_Changes__c && !enrollmentOldMap.get(e.Id).Email_Changes__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Delivery_Confirmation_WCC);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Course_Confirmed_Email_Sent__c = Datetime.now()));
                    enrollmentsToEmailIdSet_DeliveryConfirmationWCC.add(e.Id);
                }
    
                //Send Delivery Confirmation After Course Confirmed email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_Delivery_Confirmation_ACC_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    (event.Course_Type_Formula__c != Label.In_House) && 
                    (Integer.valueOf(event.Cancelled_1_0__c) == 0) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.course__r.Course_Format__c != 'E-Learning' &&
                    event.Event_Confirmed__c &&
                    e.Course_Confirmed_Email_Sent__c == null && 
                    !e.Email_Confirmation_Sent__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Delivery_Confirmation_ACC);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Course_Confirmed_Email_Sent__c = Datetime.now(), Email_Confirmation_Sent__c = true));
                    enrollmentsToEmailIdSet_DeliveryConfirmationACC.add(e.Id);
                }
    
                //Send Course Update email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_Course_Update_Emails__c && 
                    (event.Enable_automated_email_confirmation__c == 1) && 
                    (event.Course_Type_Formula__c != Label.In_House) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.Change_of_Date__c || event.Change_of_Venue__c) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    event.Event_Confirmed__c &&
                    (e.Course_Confirmed_Email_Sent__c != null) && 
                    (e.Changes_Emailed__c == null) && 
                    e.Email_Confirmation_Sent__c && 
                    e.Email_Changes__c && 
                    (e.Course_Start_Date__c > Date.today()) && 
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_Partner || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Course_Update);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Changes_Emailed__c = Datetime.now()));
                    enrollmentsToEmailIdSet_CourseUpdate.add(e.Id);
                }
    
                //Send Normal PDF Certificate email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_PDF_Certificate_Emails__c && 
                    //!translation.Certificate_verification__c  &&
                    (!translation.Certificate_verification__c || (translation.Certificate_verification__c && !event.course__r.Show_in_Portal__c))  &&
                    (event.Enable_pdf_certificate_emails__c == 1) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    e.Email_PDF_Certificate__c && !enrollmentOldMap.get(e.Id).Email_PDF_Certificate__c && 
                    !e.Hold_Certificate__c && 
                    e.Delegate_Email__c != null && 
                    e.Certificate_status__c != Label.Sent &&
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_Resit || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee_Resit)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.PDF_Certificate);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Certificate_status__c = Label.Sent, Certificate_Issued_By__c = UserInfo.getFirstName() + '' + UserInfo.getLastName(), PDF_cert_emailed__c = DateTime.now()));
                    enrollmentsToEmailIdSet_PDFcert.add(e.Id);
                }

                //Send Blockchain PDF Certificate email
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_PDF_Certificate_Emails__c && 
                    //translation.Certificate_verification__c  && 
                    (translation.Certificate_verification__c && event.course__r.Show_in_Portal__c) &&
                    e.Show_Certificate_in_Portal__c &&
                    (event.Enable_pdf_certificate_emails__c == 1) && 
                    (event.Event_status__c == Label.Active) && 
                    (event.MEA_Region__c != Label.Abu_Dhabi) && 
                    e.Email_PDF_Certificate__c && !enrollmentOldMap.get(e.Id).Email_PDF_Certificate__c && 
                    !e.Hold_Certificate__c && 
                    e.Delegate_Email__c != null && 
                    e.Certificate_status__c != Label.Sent &&
                    e.Delegate_Email__c.contains('@') && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_Resit || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee_Resit)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Blockchain_Certificate);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Certificate_status__c = Label.Sent, Certificate_Issued_By__c = UserInfo.getFirstName() + '' + UserInfo.getLastName(), PDF_cert_emailed__c = DateTime.now()));
                    enrollmentsToEmailIdSet_BCcert.add(e.Id);
                }
    
                //Send Exam/E-learning email JS Update 20200217 to include all e-learning
                if(
                    (!e.Available_In_Portal__c || (e.Available_In_Portal__c && ((e.Portal_Login_Link__c != null && u != null && u.LastLoginDate != null) || (e.Portal_Set_Password_Link__c != null && u != null && u.LastLoginDate == null)))) && 
                    translation.Enable_Exam_Emails__c && 
                    event.Product_Code__c != null &&
                    //event.Product_Code__c.containsIgnoreCase('EX') && JS 20200217 replaced with line below
                    e.LitmosAccountCreated__c != null &&
                    e.Delegate_Email__c != null && 
                    e.Delegate_Email__c.contains('@') && 
                    e.Online_Training_Assigned__c && 
                    e.RecordTypeId == EnrollmentUtils.recordType_ELearning && 
                    e.Litmos_Login_Key__c != null && 
                    e.Litmos_Details_Emailed__c == null && 
                    (e.Booking_status__c == Label.Enrollment_Booking_Status_Booked || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_Resit || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_Partner || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee || e.Booking_status__c == Label.Enrollment_Booking_Status_Booked_BSI_Employee_Resit)
                ){
                    System.debug('### onAfterUpdate trigger - ' + Label.Exam);
                    enrollmentsToUpdateList.add(new Enrollment__c(Id = e.Id, Litmos_Details_Emailed__c = Datetime.now()));
                    enrollmentsToEmailIdSet_Exam.add(e.Id);
                }
            }
            if(!enrollmentsToUpdateList.isEmpty()){
                bypassTrigger = true;
                update enrollmentsToUpdateList;
            }
            
            Map<String, Set<Id>> emailTypeEnrollmentIdsMap = new Map<String, Set<Id>>();
            if(!enrollmentsToEmailIdSet_BCcert.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Blockchain_Certificate, enrollmentsToEmailIdSet_BCcert);           
            if(!enrollmentsToEmailIdSet_PDFcert.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.PDF_Certificate, enrollmentsToEmailIdSet_PDFcert);            
            if(!enrollmentsToEmailIdSet_PlaceConfirmation.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Confirmation_of_Place, enrollmentsToEmailIdSet_PlaceConfirmation);
            if(!enrollmentsToEmailIdSet_ResitConfirmation.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Resit_Confirmation, enrollmentsToEmailIdSet_ResitConfirmation);
            if(!enrollmentsToEmailIdSet_BookingConfirmationIH.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Booking_Confirmation_In_House, enrollmentsToEmailIdSet_BookingConfirmationIH);
            if(!enrollmentsToEmailIdSet_BookingConfirmationBespokeIH.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Booking_Confirmation_Bespoke_In_House, enrollmentsToEmailIdSet_BookingConfirmationBespokeIH);
            if(!enrollmentsToEmailIdSet_DeliveryConfirmationACC.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Delivery_Confirmation_ACC, enrollmentsToEmailIdSet_DeliveryConfirmationACC);
            if(!enrollmentsToEmailIdSet_DeliveryConfirmationWCC.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Delivery_Confirmation_WCC, enrollmentsToEmailIdSet_DeliveryConfirmationWCC);
            if(!enrollmentsToEmailIdSet_CourseUpdate.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Course_Update, enrollmentsToEmailIdSet_CourseUpdate);
            if(!enrollmentsToEmailIdSet_Exam.isEmpty()) emailTypeEnrollmentIdsMap.put(Label.Exam, enrollmentsToEmailIdSet_Exam);
            
            if(!emailTypeEnrollmentIdsMap.isEmpty()){
                System.debug('### sending EnrollmentEmailServiceSync from onAfterUpdate, email size: ' + emailTypeEnrollmentIdsMap.size());
                EnrollmentEmailServiceSync.sendEmail(emailTypeEnrollmentIdsMap);
            }
            //TRIGGER REWORK END



            // prevent use of future callout for the batch update
            if(System.isBatch() || System.isFuture()) return;
    
            // refetch the trigger Enrollments with related parent records JS 130421 added in isLitmos?
            Map<Id, Enrollment__c> enrollmentRefetchMap = new Map<Id, Enrollment__c>([
                SELECT Booking_status__c, Certificate_status__c, Delegate_name__c, Delivery_Method__c, LitmosAccountCreated__c, Litmos_User_Name__c,  
                    Delegate_name__r.Email, Delegate_name__r.FirstName, Delegate_name__r.LastName, Delegate_name__r.Litmos_User_ID__c, Delegate_name__r.Account.Name, 
                    Online_Training_Assigned__c, Online_Training_Completed_Date__c, Show_Certificate_in_Portal__c, 
                    Training_Event__r.End_Date3__c,Training_Event__r.Course__r.Is_Litmos__c, Training_Event__r.Course__r.Show_in_Portal__c, Training_Event__r.Taxonomy__c, Training_Event__r.Training_Venue__r.Venue_Country__c, 
                    Training_Translations__r.Client_Learning_Portal_on__c, Training_Translations__r.Litmos_Language__c, Training_Translations__r.Certificate_verification__c 
                FROM Enrollment__c 
                WHERE Id IN :enrollmentNewMap.keySet()
            ]);


            //LITMOS integration JS 130421 added in isLitmos?
            Integer i = 0;
            for(Enrollment__c e : enrollmentNewList){
                String bookingStatus = e.Booking_status__c;
                String companyName = enrollmentRefetchMap.get(e.Id).Delegate_name__r.Account.Name;
                String countryCode = enrollmentRefetchMap.get(e.Id).Training_Event__r.Training_Venue__r.Venue_Country__c;
                String delegateId = enrollmentRefetchMap.get(e.Id).Delegate_name__c;
                String deliveryMethod = e.Delivery_Method__c;
                String email = enrollmentRefetchMap.get(e.Id).Delegate_name__r.Email;
                String firstName = enrollmentRefetchMap.get(e.Id).Delegate_name__r.FirstName;
                String lastName = enrollmentRefetchMap.get(e.Id).Delegate_name__r.LastName;
                String language = enrollmentRefetchMap.get(e.Id).Training_Translations__r.Litmos_Language__c;
                Boolean onlineTrainingAssigned = enrollmentRefetchMap.get(e.Id).Online_Training_Assigned__c;
                Boolean isLitmos = enrollmentRefetchMap.get(e.Id).Training_Event__r.Course__r.Is_Litmos__c; //JS 130421 check if litmos product
                String taxonomyCode = enrollmentRefetchMap.get(e.Id).Training_Event__r.Taxonomy__c;
                // PC K2 20200112 litmos-friendly username without special characters
                String username = e.Litmos_User_Name__c;
            
                System.debug('### bookingStatus: ' + bookingStatus);
                System.debug('### companyName: ' + companyName);
                System.debug('### countryCode: ' + countryCode);
                System.debug('### deliveryMethod: ' + deliveryMethod);
                System.debug('### email: ' + email);
                System.debug('### firstName: ' + firstName);
                System.debug('### lastName: ' + lastName);
                System.debug('### language: ' + language);
                System.debug('### onlineTrainingAssigned: ' + onlineTrainingAssigned);
                System.debug('### isLitmos: ' + isLitmos);
                System.debug('### taxonomyCode: ' + taxonomyCode);
                System.debug('### username: ' + username);
    
                // E-Learning JS 130421 AND isLitmos
                if(deliveryMethod == 'E-Learning' && isLitmos == true){
    
                    // create the Litmos User and assign course
                    if(onlineTrainingAssigned && bookingStatus.contains('Booked')  
                        // MD 20190305 ADDED THIS LINE, SO THAT LITMOS CODE ONLY FIRES ON CHANGE OF ONE OF THESE VALUES
                        && (!enrollmentOldMap.get(e.Id).Online_Training_Assigned__c || !enrollmentOldMap.get(e.Id).Booking_status__c.contains('Booked')))
                    {
                        System.debug('### LITMOS Create User / Account');
                        String litmosUserId = enrollmentRefetchMap.get(e.Id).Delegate_name__r.Litmos_User_ID__c;
    
                        if(BatchSize < 6){
                            //LitmosUser(litmosUserId, email, username, firstName, lastName, companyName, taxonomyCode, countryCode, language, e.Id, delegateId, null);
                            LitmosUser(litmosUserId, username, username, firstName, lastName, companyName, taxonomyCode, countryCode, language, e.Id, delegateId, null);
                        }else{
                            // PC K2 20200202 Schedule each Litmos job individually to avoid '503 Rating Limit Exceeded' error
                            // specify delay in seconds between each Litmos calls
                            Integer secondDelay = 20;
                            DateTime dt = DateTime.now().addSeconds(20 + secondDelay * i);
                            String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());
                            //LitmosEnrollmentSchedule litmosJob = new LitmosEnrollmentSchedule(litmosUserId, email, username, firstName, lastName, companyName, taxonomyCode, countryCode, language, e.Id, delegateId);
                            LitmosEnrollmentSchedule litmosJob = new LitmosEnrollmentSchedule(litmosUserId, username, username, firstName, lastName, companyName, taxonomyCode, countryCode, language, e.Id, delegateId);
                            System.schedule('Litmos Enrollment ' + e.Id + '.' + String.valueOf(Integer.valueOf(Math.random()*100)), cron, litmosJob);
                            i++;
                        }
                        // MD 20190315 COMMENTED OUT NEXT LINE, AS THIS CAUSES TRIGGER TO STOP PROCESSING THIS BATCH AFTER THE 1ST RECORD
                        // updateLitmosResponse(EnrId);
                    }
    
                    // remove course
                    if(onlineTrainingAssigned && bookingStatus.contains('Cancelled')){
                        System.debug('### LITMOS Remove Course'); 
                        RemoveCourse(username, taxonomyCode);
                    }
                }
            }
            
            
            //TRACELABS integration
            List<Id> enrollmentIdsToUpload = new List<Id>();
            for(Enrollment__c e : enrollmentNewList){
                Date endDate = enrollmentRefetchMap.get(e.Id).Online_Training_Completed_Date__c != null ? Date.valueOf(enrollmentRefetchMap.get(e.Id).Online_Training_Completed_Date__c) : enrollmentRefetchMap.get(e.Id).Training_Event__r.End_Date3__c;
                if(
                    e.Booking_status__c.contains('Booked') && 
                    enrollmentRefetchMap.get(e.Id).Training_Translations__r.Client_Learning_Portal_on__c && 
                    enrollmentRefetchMap.get(e.Id).Training_Translations__r.Certificate_verification__c && 
                    enrollmentRefetchMap.get(e.Id).Training_Event__r.Course__r.Show_in_Portal__c && 
                    endDate < Date.today() && 
                    //e.Certificate_status__c == 'Sent' && JS commenting out so that the cert does not have to be sent to be pushed to block chain
                    e.Show_Certificate_in_Portal__c &&
                    !e.Show_Certificate_Holder__c
                ){
                    enrollmentIdsToUpload.add(e.Id);
                }
            }
            if(!enrollmentIdsToUpload.isEmpty()){
                if(isUploadEnrollmentCertificatesFirstRun){
                    isUploadEnrollmentCertificatesFirstRun = false;
                    uploadEnrollmentCertificates(enrollmentIdsToUpload);
                }
            }
        }
        
        //This Method updates the LitmosAccountCreated flag on the record
        public static void updateLitmosResponse(string ENRId){
            try{
                Enrollment__c enr = new Enrollment__c(Id = ENRId);
                enr.LitmosAccountCreated__c = true;
                update enr;
                System.debug('** Enrollment Updated***');
            }catch(Exception e){
                System.debug('##Error in update Litmos response to Enrollment##  ' + e.getMessage());
            }
        }
    
        // PC K2 20200202 modified LitmosUser method
        // called from trigger or Schedulable Apex with CronTriggerId to delete completed job
        @future (callout=true)
        public static void LitmosUser(String litmosUserId, String email, String username, String firstName, String lastName, String company, String taxonomyCode, String country, String language, String enrId, String delegateId, String cronTriggerId){
            System.debug('### EnrollmentTrigHandler.LitmosUser');
            System.debug('### ' + litmosUserId + ', ' + email + ', ' + username + ', ' + firstName + ', ' + lastName + ', ' + company + ', ' + taxonomyCode + ', ' + country + ', ' + language + ', ' + enrId);
            Boolean isExistingLitmosUser = false;
            Boolean populateLitmosOnContact = false;
            Boolean populateLitmosOnEnrollment = false;
    
            try{
                LitmosAPI litmos = new LitmosAPI();
                LitmosAPI.LitmosUser litmosUser;
                String courseId = litmos.getCourseId(taxonomyCode, Test.isRunningTest());
    
                if(String.isBlank(litmosUserId)){
                    // create User
                    litmosUser = litmos.createUser(firstName, lastName, email, username, company, country, language, taxonomyCode, courseId, Test.isRunningTest());
    
                    // manage result
                    if(litmosUser.statusCode == 200 || litmosUser.statusCode == 201){
                        populateLitmosOnContact = true;
                    }
                    if(litmosUser.statusCode == 409){
                        litmosUser = litmos.updateUser(litmosUser.Id, firstName, lastName, email, username, company, country, language, Test.isRunningTest());
                        populateLitmosOnEnrollment = true;
                        isExistingLitmosUser = true;
                    }
                }else{
                    // activate existing User
                    litmosUser = litmos.updateUser(litmosUserId, firstName, lastName, email, username, company, country, language, Test.isRunningTest());
                    isExistingLitmosUser = true;
                }
    
                // assign Course
                litmos.assignCourse(litmosUser.Id, courseId, Test.isRunningTest());
    
                // get Course details to update Enrollment
                LitmosAPI.CourseDetails courseDetails = litmos.getCourseDetails(litmosUser.Id, taxonomyCode, courseId, Test.isRunningTest());
    
                System.debug('### EnrollmentTrigHandler / LitmosAPI.LitmosUser: ' + litmosUser);
                if(litmosUser.Id != null && courseDetails.CourseId != null){
                    Enrollment__c e = new Enrollment__c(Id = enrId);
                    e.LitmosAccountCreated__c = true;
                    e.Litmos_Login_Key__c = litmosUser.LoginKey;
                    e.Litmos_Account_Created_Date__c = litmosUser.CreatedDate;
                    e.Online_Training_Expiry_Date__c = courseDetails.AccessTillDate;
                    e.Online_Training_Assigned_Date__c = courseDetails.AssignedDate;
    
                    if(isExistingLitmosUser) e.Existing_Litmos_User__c = true;
                    if(populateLitmosOnEnrollment) e.Litmos__c = litmosUser.Id;
                    
                    System.debug('### EnrollmentTrigHandler.LitmosUser updating Enrollment START');
                    update e;
                    System.debug('### EnrollmentTrigHandler.LitmosUser updating Enrollment STOP');
                }
    
                // save Litmos User Id on Contact
                if(populateLitmosOnContact){
                    System.debug('### save Litmos User Id on Contact');
                    update new Contact(Id = delegateId, Litmos_User_ID__c = litmosUser.Id);
                }
            }catch(exception e){
                System.debug('### LITMOS User Creation Failed: ' + e.getMessage() + ', ' + e.getStackTraceString());
            }
    
            // abort Job if run from Scheduled Apex
            System.debug('### cronTriggerId: ' + cronTriggerId);
            if(!String.isBlank(cronTriggerId)){
                try{
                    System.abortJob(cronTriggerId);
                }catch(Exception e){
                    System.debug('### Scheduled Job abort failed: ' + e.getMessage());
                }
            }
        }
    
        //Async method to remove the user from the course
        @future (callout=true)
        public static void RemoveCourse(string emailaddress, string taxonomyCode){
            //Call the Litmos API
            LitmosAPI LMS = new LitmosAPI();
            if(!Test.isRunningTest())
            {
                //Remove the User from the course.
                LMS.RemoveCourse(emailaddress, taxonomyCode,false);
            }
        }
        
        
    /*** MIMEO ***/


    //detect changes to Enrollment's Mimeo Key Assignment
    public void manageMimeoKeyAssignment(Map<Id, Enrollment__c> oldMap, Map<Id, Enrollment__c> newMap){
        System.debug('### EnrollmentTrigHandler.manageMimeoKeyAssignment');
    
        if(isManageMimeoKeyAssignmentFirstRun) isManageMimeoKeyAssignmentFirstRun = false;
        else return;

        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> trainingEventIdSet = new Set<Id>();
        for(Enrollment__c e : newMap.values()){
            contactIdSet.add(e.Delegate_name__c);
            trainingEventIdSet.add(e.Training_Event__c);
        }
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT FirstName, FirstNameLocal, LastName, LastNameLocal FROM Contact WHERE Id IN :contactIdSet]);
        Map<Id, Training_Event__c> trainingEventMap = new Map<Id, Training_Event__c>([SELECT Event_Country__c, Mimeo_Distribution_Id__c FROM Training_Event__c WHERE Id IN :trainingEventIdSet]);

        for(Id eId : newMap.keySet()){
            if(newMap.get(eId).Mimeo_Key_Assignment__c && !oldMap.get(eId).Mimeo_Key_Assignment__c){
                Enrollment__c e = newMap.get(eId);
                Contact c = contactMap.get(e.Delegate_name__c);
                Training_Event__c event = trainingEventMap.get(e.Training_Event__c);
                String firstName = String.isBlank(c.FirstNameLocal) ? c.FirstName : c.FirstNameLocal;
                String lastName = String.isBlank(c.LastNameLocal) ? c.LastName : c.LastNameLocal;

                assignMimeoKeysToUsers(e.Id, e.Delegate_Email__c, firstName, lastName, event.Mimeo_Distribution_Id__c, event.Event_Country__c);
            }
        }
    }

    //detect changes to Enrollment's Revoke Mimeo Key
    public void manageMimeoRevokeKey(Map<Id, Enrollment__c> oldMap, Map<Id, Enrollment__c> newMap){
        System.debug('### EnrollmentTrigHandler.manageMimeoRevokeKey');

        if(isManageMimeoRevokeKeyFirstRun) isManageMimeoRevokeKeyFirstRun = false;
        else return;

        Set<Id> trainingEventIdSet = new Set<Id>();
        for(Enrollment__c e : newMap.values()){
            trainingEventIdSet.add(e.Training_Event__c);
        }
        Map<Id, Training_Event__c> trainingEventMap = new Map<Id, Training_Event__c>([SELECT Event_Country__c, Mimeo_Distribution_Id__c FROM Training_Event__c WHERE Id IN :trainingEventIdSet]);

        for(Id eId : newMap.keySet()){
            if(newMap.get(eId).Revoke_Mimeo_Key__c && !oldMap.get(eId).Revoke_Mimeo_Key__c && newMap.get(eId).Mimeo_Key_Revoked_Date__c == null){
                Enrollment__c e = newMap.get(eId);
                Training_Event__c event = trainingEventMap.get(e.Training_Event__c);

                revokeMimeoKey(e.Id, e.Mimeo_Key__c, event.Event_Country__c);
            }
        }
    }

    //Mimeo assignKeys callout
    @future (callout=true)
    public static void assignMimeoKeysToUsers(String enrollmentId, String email, String firstName, String lastName, String distributionId, String countryCode){
        System.debug('### EnrollmentTrigHandler.assignKeysToUsers: ' + enrollmentId + ', ' + email + ', ' + firstName + ', ' + lastName + ', ' + distributionId + ', ' + countryCode);

        //call mimeo assign keys
        try{
            MimeoAPI mAPI = new MimeoAPI(countryCode);
            MimeoAPI.ResponseWrapper responseWrapper = mAPI.assignKeysToUsers(email, firstName, lastName, distributionId);

            Enrollment__c e = new Enrollment__c(Id = enrollmentId);

            if(responseWrapper.statusCode == 200){
                List<MimeoAPI.AssignKeysResponse200> responseList = (List<MimeoAPI.AssignKeysResponse200>)JSON.deserialize(responseWrapper.json, List<MimeoAPI.AssignKeysResponse200>.class);
                e.Mimeo_Key__c = responseList[0].EContentCode;
                e.Mimeo_Key_Created_Date__c = DateTime.now();
                e.Mimeo_Error__c = null;
            }else if(responseWrapper.statusCode == 400){
                e.Mimeo_Error__c = 'Error 400. Incorrect body parameters';
            }else if(responseWrapper.statusCode == 401){
                e.Mimeo_Error__c = 'Error 401. API Subscription-Key might be invalid';
            }else if(responseWrapper.statusCode == 500){
                e.Mimeo_Error__c = 'Error 500. There was and issue processing the request in the API';
            }else{
                e.Mimeo_Error__c = 'Assign Key callout failed';
            }

            update e;
        }catch(Exception e){
            System.debug('### assignKeys error: ' + e.getMessage());
            update new Enrollment__c(Id = enrollmentId, Mimeo_Error__c = e.getMessage());
        }
    }

    //Mimeo revokeKey callout
    @future (callout=true)
    public static void revokeMimeoKey(String enrollmentId, String key, String countryCode){
        System.debug('### EnrollmentTrigHandler.assignKeysToUsers: ' + enrollmentId + ', ' + key + ', ' + countryCode);

        //call mimeo revoke keys
        try{
            MimeoAPI mAPI = new MimeoAPI(countryCode);
            MimeoAPI.ResponseWrapper responseWrapper = mAPI.revokeKeysFromDistribution(key);

            Enrollment__c e = new Enrollment__c(Id = enrollmentId);

            if(responseWrapper.statusCode == 200){
                e.Mimeo_Key_Revoked_Date__c = DateTime.now();
                e.Mimeo_Error__c = null;
            }else{
                e.Mimeo_Error__c = 'Revoke Keys callout failed';
            }

            update e;
        }catch(Exception e){
            System.debug('### revokeKeys error: ' + e.getMessage());
            update new Enrollment__c(Id = enrollmentId, Mimeo_Error__c = e.getMessage());
        }
    }
    
    
    /*** TRACELABS ***/
    
    
    //TraceLabs uploadEnrollmentCertificates callout
    @future (callout=true)
    public static void uploadEnrollmentCertificates(List<Id> enrollmentIds){
        System.debug('### EnrollmentTrigHandler.uploadEnrollmentCertificates: ' + enrollmentIds);
    
        //call tracelabs upload certificates
        try{
            TraceLabsAPI tAPI = new TraceLabsAPI();
            TraceLabsAPI.UploadResponse ur = tAPI.uploadEnrollmentCertificates(enrollmentIds);
            
            //get successful Enrollments
            Set<String> successfulEnrollments = new Set<String>();
            if(ur != null && ur.statusCode == 200 && ur.body != null && !ur.body.successfull.isEmpty()){
                for(TraceLabsAPI.UploadResponseBodyItem item : ur.body.successfull){
                    successfulEnrollments.add(item.enrollment_code);
                }
            }
            System.debug('### successfulEnrollments: ' + successfulEnrollments);
            
            //update successful Enrollments
            List<Enrollment__c> enrollmentsToUpdate = new List<Enrollment__c>();
            for(Id id : enrollmentIds){
                String id15 = String.valueOf(id).substring(0,15);
                if(successfulEnrollments.contains(id15)) {
                    enrollmentsToUpdate.add(new Enrollment__c(Id = id, Show_Certificate_Holder__c = true));
                }
            }
            System.debug('### enrollmentsToUpdate: ' + enrollmentsToUpdate);

            if(!enrollmentsToUpdate.isEmpty()){
                Database.update(enrollmentsToUpdate, false);
            }
        }catch(Exception e){
            System.debug('### uploadEnrollmentCertificates error: ' + e.getMessage());
        }
    }
}