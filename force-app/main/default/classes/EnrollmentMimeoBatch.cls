/*
* Enrollment Mimeo Batch
* Description: Batch to find Enrollments eligible for Mimeo Key assignment 
* Created: PC K2 (May 2020)
*
* changelog
* PC K2      07-25-2020 bulkify record processing to minimize number of apex jobs
* PC K2      08-14-2020 use custom settings, check max scope, check job limit, send warning email
*/

public class EnrollmentMimeoBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    public final static Integer MAX_SCOPE = 2000;
    public final Integer MAX_JOBS = 100;
    public Integer scopeTotalSize = 0;
    public Boolean isJobOverLimit = false;
    public Map<String, Integer> countryKeyDaysMap;

    //schedulable interface
    public void execute(SchedulableContext sc){
        Database.executeBatch(this, MAX_SCOPE);
    }

    //batchable interface
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Course_Start_Date__c, Training_Event__r.Event_Country__c FROM Enrollment__c ' +
                        'WHERE Mimeo_Key_Assignment__c = false ' +
                        'AND Mimeo_Key_Created_Date__c = null ' +
                        'AND Booking_status__c LIKE \'%Booked%\' ' + 
                        'AND Training_Event__r.Event_Status__c = \'Active\' ' +
                        'AND Training_Event__r.Start_date__c > TODAY ' +
                        'AND Training_Event__r.Mimeo_Distribution_Created_Date__c != null ' +
                        'AND (Training_Event__r.Event_Country__c = \'UK\' OR (Training_Event__r.Event_Country__c != \'UK\' AND Training_Event__r.Event_Confirmed__c = true))';

        //check if a single batch execution can handle all pending records
        List<Enrollment__c> allScope = Database.query(query);
        if(!allScope.isEmpty() && allScope.size()>MAX_SCOPE) scopeTotalSize = allScope.size();

        return Database.getQueryLocator(query + (Test.isRunningTest() ? ' LIMIT 1' : ' LIMIT ' + MAX_SCOPE));
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        System.debug('### EnrollmentMimeoBatch.execute START ' + DateTime.now());
        System.debug('### scope size ' + scope.size());
        
        Mimeo_Settings__c ms = Mimeo_Settings__c.getOrgDefaults();
        //set how many records will be processed in each Scheduled Apex Job
        Integer maxListSize = ms.Enrollment_Batch_Update_Max_List_Size__c > 0 ? (Integer)ms.Enrollment_Batch_Update_Max_List_Size__c : 15;
        //set delay in seconds between each Apex Job
        Integer secondDelay = ms.Enrollment_Batch_Update_Second_Delay__c > 0 ? (Integer)ms.Enrollment_Batch_Update_Second_Delay__c : 20;

        if(countryKeyDaysMap == null){
            countryKeyDaysMap = new Map<String, Integer>();
            List<Mimeo_Country_Settings__mdt> mcsList = [SELECT Label, Key_Assignment_Days__c FROM Mimeo_Country_Settings__mdt];
            for(Mimeo_Country_Settings__mdt mcs : mcsList){
                countryKeyDaysMap.put(mcs.Label, (Integer)mcs.Key_Assignment_Days__c);
            }
        }

        List<Id> enrollmentIdsToUpdate = new List<Id>();
        for(Enrollment__c e : (List<Enrollment__c>) scope){
            System.debug('### Enrollment: ' + e);
            if(Math.abs(e.Course_Start_Date__c.daysBetween(Date.today())) == countryKeyDaysMap.get(e.Training_Event__r.Event_Country__c)){
                System.debug('### Mimeo Key Assignment: true');
                enrollmentIdsToUpdate.add(e.Id);
            }
        }

        //divide scope into groups
        List<List<Id>> enrollmentMasterList = new List<List<Id>>();
        List<Id> enrollmentIdList = new List<Id>();

        for(Integer i=0; i<enrollmentIdsToUpdate.size(); i++){
            if(enrollmentIdList.size() == maxListSize){
                enrollmentMasterList.add(enrollmentIdList);
                enrollmentIdList = new List<Id>();
            }

            enrollmentIdList.add(enrollmentIdsToUpdate.get(i));

            //handle last element
            if(i == enrollmentIdsToUpdate.size()-1){
                enrollmentMasterList.add(enrollmentIdList);
            }
        }

        Integer i = 0;
        Integer jobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.JobType = '7'];
        for(List<Id> enrollmentIds : enrollmentMasterList){
            System.debug('### current scheduled jobs: ' + jobs);
            if(jobs < MAX_JOBS){
                DateTime dt = DateTime.now().addSeconds(20 + secondDelay * i);
                String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());
                i++;

                //process records in groups to minimize number of Scheduled Apex Jobs
                EnrollmentMimeoBatchUpdateSchedule mimeoJob = new EnrollmentMimeoBatchUpdateSchedule(enrollmentIds);
                System.schedule('Enrollment Mimeo Batch Update. List ' + i + ' scope ' + enrollmentIds.size() + '. ' + String.valueOf(Integer.valueOf(Math.random()*100)), cron, mimeoJob);
                jobs++;
            }else{
                isJobOverLimit = true;
            }
        }
        System.debug('### EnrollmentMimeoBatch.execute END ' + DateTime.now());
    }

    public void finish(Database.BatchableContext batchContext){
        System.debug('### EnrollmentMimeoBatch.finish ' + DateTime.now());
        System.debug('### scopeTotalSize (0 means below MAX): ' + scopeTotalSize);
        System.debug('### isJobOverLimit: ' + isJobOverLimit);

        //send warning email if not all eligible records were processed (overflow scenario)
        //send warning email if max concurrent scheduled jobs limit reached
        Mimeo_Settings__c ms = Mimeo_Settings__c.getOrgDefaults();
        if((scopeTotalSize > 0 || isJobOverLimit) && ms != null && ms.Batch_Update_Email__c != null){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSaveAsActivity(false);
            email.subject = 'Enrollment Mimeo Batch Update warning';
            email.plainTextBody = 'Salesforce organization Id: ' + UserInfo.getOrganizationId() + '\r\n';
            email.plainTextBody += 'Username: ' + UserInfo.getUserName() + '\r\n\r\n';
            email.plainTextBody += 'Enrollment Mimeo Batch Update finished: ' + DateTime.now() + '\r\n';

            if(scopeTotalSize > 0){
                email.plainTextBody += 'Warning: not all eligible records were processed. \r\n';
                email.plainTextBody += 'Eligible records: ' + scopeTotalSize + ', Max supported: ' + MAX_SCOPE + '\r\n';
            }

            if(isJobOverLimit){
                email.plainTextBody += 'Warning: maximum limit of concurrent Scheduled Apex Jobs reached: ' + MAX_JOBS + '\r\n';
            }

            email.toAddresses = new List<String>{ms.Batch_Update_Email__c};
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            System.debug('### warning email sent');
        }
    }


    //this @future method can be called from Scheduled Apex Job or Trigger only (cannot call @future from batch)
    @future(callout=true)
    public static void assignMimeoKeysToUsersBulk(List<Id> enrollmentIds, String cronTriggerId){
        System.debug('### assignMimeoKeysToUsersBulk size: ' + enrollmentIds.size());

        Map<Id, Enrollment__c> enrollmentMap = new Map<Id, Enrollment__c>([SELECT Delegate_Email__c, Delegate_name__c, Training_Event__c FROM Enrollment__c WHERE Id IN :enrollmentIds]);
        List<Enrollment__c> enrollmentsToUpdate = new List<Enrollment__c>();

        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> trainingEventIdSet = new Set<Id>();
        for(Enrollment__c e : enrollmentMap.values()){
            contactIdSet.add(e.Delegate_name__c);
            trainingEventIdSet.add(e.Training_Event__c);
        }
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT FirstName, FirstNameLocal, LastName, LastNameLocal FROM Contact WHERE Id IN :contactIdSet]);
        Map<Id, Training_Event__c> trainingEventMap = new Map<Id, Training_Event__c>([SELECT Event_Country__c, Mimeo_Distribution_Id__c FROM Training_Event__c WHERE Id IN :trainingEventIdSet]);

        try{
            for(Enrollment__c e : enrollmentMap.values()){
                Contact c = contactMap.get(e.Delegate_name__c);
                Training_Event__c event = trainingEventMap.get(e.Training_Event__c);
                String firstName = String.isBlank(c.FirstNameLocal) ? c.FirstName : c.FirstNameLocal;
                String lastName = String.isBlank(c.LastNameLocal) ? c.LastName : c.LastNameLocal;

                MimeoAPI mAPI = new MimeoAPI(event.Event_Country__c);
                MimeoAPI.ResponseWrapper responseWrapper = mAPI.assignKeysToUsers(e.Delegate_Email__c, firstName, lastName, event.Mimeo_Distribution_Id__c);

                if(responseWrapper.statusCode == 200){
                    List<MimeoAPI.AssignKeysResponse200> responseList = (List<MimeoAPI.AssignKeysResponse200>)JSON.deserialize(responseWrapper.json, List<MimeoAPI.AssignKeysResponse200>.class);
                    e.Mimeo_Key_Assignment__c = true;
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

                enrollmentsToUpdate.add(e);
                System.debug('### Enrollment to update: ' + e);
            }

            if(!enrollmentsToUpdate.isEmpty()){
                //disable trigger
                EnrollmentTrigHandler.isManageMimeoKeyAssignmentFirstRun = false;

                List<Database.SaveResult> saveResults = Database.update(enrollmentsToUpdate, false);
                for(Integer i=0; i<saveResults.size(); i++){
                    if(saveResults[i].isSuccess()) System.debug('### Enrollment ' + enrollmentsToUpdate[i].Id + ' updated successfully');
                    else System.debug('### Enrollment ' + enrollmentsToUpdate[i].Id + ' update failed: ' + saveResults[i].getErrors()[0].getMessage());
                }
            }
        }catch(Exception e){
            System.debug('### Exception in assignMimeoKeysToUsersBulk: ' + e.getMessage());
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