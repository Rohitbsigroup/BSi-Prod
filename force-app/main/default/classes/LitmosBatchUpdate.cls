/** 
* Created By:  Philip Holtom (philip.holtom@opensymmetry.com)
* Updated By : Vimlesh Azad - June 2017 
* Purpose: Class to batch update records that have been created in Litmos with the course results
*
* 2019/09/04 JS Updated the query so that data is written back even on the expiry date
* 2020/06/10 PC K2 bulkify record processing to minimize number of apex jobs
* 2020/08/14 PC K2 use custom settings, check max scope, check job limit, send warning email
* 2021/06/23 Case 003315 populate Enrollment Exam_percentage__c and Exam_results__c if Enrollment Learning Type is Onine Exam or Online Exam Resit 
* 2021/10/14 JS also added in E-learning course with exam for exam result update
* 2022/06/01 JS added in code to pick up additional filters at certain times
*/

global class LitmosBatchUpdate implements Database.Batchable<Sobject>, Database.AllowsCallouts, Database.Stateful {

    public final static Integer MAX_SCOPE = 2000;
    public Integer scopeTotalSize = 0;
    public Boolean isJobOverLimit = false;
    public static String EMAIL_SUBJECT = 'Litmos Batch Update warning'; 

    // constructor
    global LitmosBatchUpdate(){}

    global database.Querylocator start(Database.BatchableContext context){
        // use the LitmosAccountCreated__c flag to determine which records need to be updated
        // use Active_Litmos_Enrollment__c to select only relevant Enrollments
        String query = 'SELECT Id FROM Enrollment__c ' +
                        'WHERE Active_Litmos_Enrollment__c = true ' +
                        'AND Online_Training_Complete__c = false ' +
                        'AND LitmosAccountCreated__c = true ' +
                        'AND (Online_Training_Attempts__c <> 2 OR Online_Training_Attempts__c <> 4) ' +
                        'AND Reason_for_Cancelling_Enrolment__c = null ' +
                        'AND (Online_Training_Expiry_Date__c = null OR Online_Training_Expiry_Date__c >= TODAY) ';
        LitmosSettings__c ls = LitmosSettings__c.getOrgDefaults();
        //String additionalFilter = String.isBlank(ls.Additional_filter__C) ? '' : ls.Additional_filter__C; JS replacing with additional filters below
        
        Time t = Datetime.now().time(); //getting time now
        System.debug('### t Datetime.now().time()'+ t);
        System.debug('### t.hour()'+ t.hour());
              
        
        if(t.hour()>22 && t.hour()<=23) // if between 22 and 00
            {            
            String additionalFilter = String.isBlank(ls.Additional_filter__C) ? '' : ls.Additional_filter__C;
            query += additionalFilter;
            }
            
        if(t.hour()>=00 && t.hour()<=5)  // if between 00 and 05 am
            {            
            String additionalFilter = String.isBlank(ls.Additional_filter2__C) ? '' : ls.Additional_filter2__C;
            query += additionalFilter;
            }
            
        if(t.hour()>5 && t.hour()<=19) // if between 05 am and 19
            {            
            String additionalFilter = String.isBlank(ls.Additional_filter3__C) ? '' : ls.Additional_filter3__C;
            query += additionalFilter;
            } 
                 
        if(t.hour()>19 && t.hour()<=22) // if between 19 and 22 change back to >16
            {
            String additionalFilter = String.isBlank(ls.Additional_filter4__C) ? '' : ls.Additional_filter4__C;
            query += additionalFilter;
            }       
                       
        try {
            System.debug('##### query0:' + query);
            //check if a single batch execution can handle all pending records
            List<Enrollment__c> allScope = Database.query(query);
            System.debug('##### query:' + query);
            if(!allScope.isEmpty() && allScope.size()>MAX_SCOPE) scopeTotalSize = allScope.size();
        } catch (Exception e) {
            System.debug('##### exception:' + query);
            sendNotificationEmail(EMAIL_SUBJECT,buildErrorEmailBody(e,query));
            return Database.getQueryLocator('SELECT Id FROM Enrollment__c LIMIT 0');
        }
        return Database.getQueryLocator(query + (Test.isRunningTest() ? ' LIMIT 1' : ' LIMIT ' + MAX_SCOPE));
    }

    //Method to execute the batch
    global void execute(Database.BatchableContext context, Sobject[] scope){
        LitmosSettings__c ls = LitmosSettings__c.getOrgDefaults();
        //set how many records will be processed in each Scheduled Apex Job
        Integer maxListSize = ls.Batch_Update_Max_List_Size__c > 0 ? (Integer)ls.Batch_Update_Max_List_Size__c : 10;
        //set delay in seconds between each Apex Job
        Integer secondDelay = ls.Batch_Update_Second_Delay__c > 0 ? (Integer)ls.Batch_Update_Second_Delay__c : 20;

        //divide scope into groups
        List<List<Id>> enrollmentMasterList = new List<List<Id>>();
        List<Id> enrollmentIdList = new List<Id>();

        for(Integer i=0; i<scope.size(); i++){
            if(enrollmentIdList.size() == maxListSize){
                enrollmentMasterList.add(enrollmentIdList);
                enrollmentIdList = new List<Id>();
            }

            Enrollment__c e = (Enrollment__c)scope.get(i);
            enrollmentIdList.add(e.Id);

            //handle last element
            if(i == scope.size()-1){
                enrollmentMasterList.add(enrollmentIdList);
            }
        }

        Integer i = 0;
        Integer jobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.JobType = '7'];
        for(List<Id> enrollmentIds : enrollmentMasterList){
            if(jobs < ls.Batch_Max_Schedule_Jobs__c){
                // PC K2 20200308 Schedule each Litmos job individually to avoid '503 Rating Limit Exceeded' error
                // specify delay in seconds between each Litmos calls
                // PC K2 20200610 bulkify record processing to minimize number of apex jobs
                
                DateTime dt = DateTime.now().addSeconds(20 + secondDelay * i);
                String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());
                i++;

                LitmosBatchEnrollmentUpdateSchedule litmosJob = new LitmosBatchEnrollmentUpdateSchedule(enrollmentIds);
                System.schedule('Litmos Batch Enrollment Update. List ' + i + ' scope ' + enrollmentIds.size() + '. ' + String.valueOf(Integer.valueOf(Math.random()*100)), cron, litmosJob);
                jobs++;
            }else{
                isJobOverLimit = true;
            }
        }
    }

    //Method to be called after the execute
    global void finish(Database.BatchableContext context){
        //send warning email if not all eligible records were processed (overflow scenario)
        //send warning email if max concurrent scheduled jobs limit reached
        LitmosSettings__c ls = LitmosSettings__c.getOrgDefaults();
        if((scopeTotalSize > 0 || isJobOverLimit) && ls != null && ls.Batch_Update_Email__c != null){
            sendNotificationEmail(EMAIL_SUBJECT, buildFinishEmailBody());
            System.debug('### warning email sent');
        }
    }

    private void sendNotificationEmail(String emailSubject, String emailBody){
        LitmosSettings__c ls = LitmosSettings__c.getOrgDefaults();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSaveAsActivity(false);
        email.subject = emailSubject;
        email.plaintextbody = emailBody;
        email.toAddresses = new List<String>{ls.Batch_Update_Email__c};
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    private String buildFinishEmailBody(){
        LitmosSettings__c ls = LitmosSettings__c.getOrgDefaults();
        String emailPlainTextBody = 'Salesforce organization Id: ' + UserInfo.getOrganizationId() + '\r\n';
        emailPlainTextBody += 'Username: ' + UserInfo.getUserName() + '\r\n\r\n';
        emailPlainTextBody += 'Litmos Batch Update finished: ' + DateTime.now() + '\r\n';
        if(scopeTotalSize > 0){
            emailPlainTextBody += 'Warning: not all eligible records were processed. \r\n';
            emailPlainTextBody += 'Eligible records: ' + scopeTotalSize + ', Max supported: ' + MAX_SCOPE + '\r\n';
        }
        if(isJobOverLimit){
            emailPlainTextBody += 'Warning: maximum limit of concurrent Scheduled Apex Jobs reached: ' + ls.Batch_Max_Schedule_Jobs__c + '\r\n';
        }
        return emailPlainTextBody;
    }
    
    private String buildErrorEmailBody(Exception e, String queryString){
        String emailPlainTextBody = 'Salesforce organization Id: ' + UserInfo.getOrganizationId() + '\r\n';
        emailPlainTextBody += 'Username: ' + UserInfo.getUserName() + '\r\n\r\n';
        emailPlainTextBody += 'Litmos Batch Update: ' + DateTime.now() + '\r\n';
        emailPlainTextBody += 'Error message: ' + e.getMessage() + '\r\n';
        emailPlainTextBody += 'Stacktrace: ' + e.getStackTraceString() + '\r\n';
        emailPlainTextBody += 'Batch query: ' + queryString + '\r\n';
        return emailPlainTextBody;
    }

    //this @future method can be called from Scheduled Apex Job or Trigger only (cannot call @future from batch)
    @future(callout=true)
    global static void LitmosBatchEnrollmentUpdate(List<Id> enrollmentIds, String cronTriggerId){
        Map<Id, Enrollment__c> enrollmentMap = new Map<Id, Enrollment__c>([SELECT Booking_Status__c, 
                                                                                  Litmos__c, 
                                                                                  Litmos_User_Name__c, 
                                                                                  Delegate_name__r.Litmos_User_ID__c, 
                                                                                  Training_Event__r.Taxonomy__c, 
                                                                                  Training_Event__r.Course__r.Litmos_Course_Id__c,
                                                                                  Online_Training_perc_Complete__c,
                                                                                  Online_Training_Completed_Date__c,
                                                                                  Online_Training_Attempts__c,
                                                                                  Exam_percentage__c,
                                                                                  Exam_results__c,
                                                                                  Learning_Type_Formula__c,
                                                                                  Translation_Formula__c,
                                                                                  Training_Event__r.Event_Country__c,
                                                                                  Training_Event__r.Course__c,
                                                                                  Training_Event__r.Course__r.Is_Litmos__c,
                                                                                  Training_Event__r.Course__r.Course_has_Exam__c,
                                                                                  Comments__c
                                                                                  
                                                                           FROM Enrollment__c 
                                                                           WHERE Id IN :enrollmentIds]);
        List<Enrollment__c> enrollmentsToUpdate = new List<Enrollment__c>();
        Map<Id, Product2> coursesToUpdate = new Map<Id, Product2>();

        try{
            LitmosAPI litmos = new LitmosAPI();
        
            for(Id enrollmentId : enrollmentIds){
                Enrollment__c enrollment = enrollmentMap.get(enrollmentId);
                String litmosUserName = enrollment.Litmos_User_Name__c;
                String taxonomy = enrollment.Training_Event__r.Taxonomy__c;
                String userId = String.isBlank(enrollment.Litmos__c) ? enrollment.Delegate_name__r.Litmos_User_ID__c : enrollment.Litmos__c;
                String courseId = enrollment.Training_Event__r.Course__r.Litmos_Course_Id__c;
                String bookingStatus = enrollment.Booking_Status__c;

                // PC K2 20200225 use litmos-friendly username without special characters
                // PC K2 20200610 if Litmos User Id saved in SF is blank, call Litmos and refresh it
                if(String.isBlank(userId)){
                    userId = litmos.getUserId(litmosUserName, Test.isRunningTest());
                }

                // PC K2 20200610 if Litmos Course Id saved in SF is blank, call Litmos and refresh it
                if(String.isBlank(courseId)){
                    courseId = litmos.getCourseId(taxonomy, Test.isRunningTest());
                    if(!String.isBlank(courseId) && !coursesToUpdate.containsKey(enrollment.Training_Event__r.Course__c)){
                        coursesToUpdate.put(
                            enrollment.Training_Event__r.Course__c, 
                            new Product2(Id = enrollment.Training_Event__r.Course__c, Litmos_Course_Id__c = courseId)
                        );
                    }
                }

                // PC K2 20200610 call Litmos for Course Details
                LitmosAPI.CourseDetails courseDetails = litmos.getCourseDetails(userId, taxonomy, courseId, Test.isRunningTest());
                if(courseDetails != null && courseDetails.CourseId != null){
                    enrollment.Online_Training_perc_Complete__c = courseDetails.PercentageComplete;
                    enrollment.Online_Training_Completed_Date__c = courseDetails.DateCompleted;
                    enrollment.Online_Training_Complete__c = courseDetails.Complete;
                    enrollment.Online_Training_Attempts__c = courseDetails.Attempt;

                    // Case 003315 EN 23/06/2021 populate Enrollment Exam_percentage__c and Exam_results__c if Enrollment Learning Type is Onine Exam or Online Exam Resit JS 20211014 also added in E-learning course with exam for exam result update
                    if (enrollment.Learning_Type_Formula__c == Label.CLP_Online_Exam || enrollment.Learning_Type_Formula__c == Label.CLP_Online_Exam_Resit|| 
                    (enrollment.Learning_Type_Formula__c == Label.CLP_Online_Training && enrollment.Training_Event__r.Course__r.Is_Litmos__c && enrollment.Training_Event__r.Course__r.Course_Has_Exam__c)) {
                        enrollment.Exam_percentage__c = courseDetails.Score;
                        //PC K2 20-11-2019 populate Exam Results
                        //PC K2 29-07-2020 use Passmark
                        if(enrollment.Exam_percentage__c >= courseDetails.Passmark && enrollment.Online_Training_Complete__c) enrollment.Exam_results__c = Label.Exam_Result_Non_Pass;
                        if(enrollment.Exam_percentage__c < courseDetails.Passmark && !enrollment.Online_Training_Complete__c && ((bookingStatus == 'Booked' && enrollment.Online_Training_Attempts__c >= 2) || (bookingStatus == 'Booked - Resit' && enrollment.Online_Training_Attempts__c >= 10))) enrollment.Exam_results__c = Label.Exam_Result_Non_Fail;
                    }

                    //PC K2 31-10-2018 add Online Training Expiry Date  
                    if((courseDetails.AccessTillDate != null) && (courseDetails.AccessTillDate > DateTime.newInstance(1900, 1, 1))){
                        enrollment.Online_Training_Expiry_Date__c = courseDetails.AccessTillDate;
                    }
                    
                    enrollmentsToUpdate.add(enrollment);
                }
            }

            if(!enrollmentsToUpdate.isEmpty()){
                List<Database.SaveResult> saveResults = Database.update(enrollmentsToUpdate, false);
                for(Integer i=0; i<saveResults.size(); i++){
                    if(saveResults[i].isSuccess()) System.debug('### Enrollment ' + enrollmentsToUpdate[i].Id + ' updated successfully');
                    else System.debug('### Enrollment ' + enrollmentsToUpdate[i].Id + ' update failed: ' + saveResults[i].getErrors()[0].getMessage());
                }
            }
            if(!coursesToUpdate.isEmpty()){
                List<Database.SaveResult> saveResults = Database.update(coursesToUpdate.values(), false);
            }
        } catch(exception e) {
            System.debug('***Exception in geting Course Details  *** ' + e.getMessage());
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
}