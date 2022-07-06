/*
* Training Event Mimeo Batch
* Description: Batch to find Training Events eligible for Mimeo Distribution creation 
* Created: PC K2 (May 2020)
*
* changelog
* PC K2      07-25-2020 bulkify record processing to minimize number of apex jobs
* PC K2      08-14-2020 use custom settings, check max scope, check job limit, send warning email
*/

public class TrainingEventMimeoBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    public final static Integer MAX_SCOPE = 2000;
    public final Integer MAX_JOBS = 100;
    public Integer scopeTotalSize = 0;
    public Boolean isJobOverLimit = false;
    public Map<String, Integer> countryDistributionDaysMap;

    //schedulable interface
    public void execute(SchedulableContext sc){
        Database.executeBatch(this, MAX_SCOPE);
    }

    //batchable interface
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Event_Country__c, Start_date__c, Course__c, Course__r.Mimeo_Materials__c FROM Training_Event__c ' +
                        'WHERE Event_Status__c = \'Active\' ' +
                        'AND Course__r.Mimeo_Materials__c = true ' +
                        'AND Start_date__c > TODAY ' +
                        'AND Mimeo_Distribution_Assignment__c = false ' +
                        'AND Mimeo_Distribution_Created_Date__c = null ' +
                        'AND (Event_Country__c = \'UK\' OR (Event_Country__c != \'UK\' AND Event_Confirmed__c = true))';

        //check if a single batch execution can handle all pending records
        List<Training_Event__c> allScope = Database.query(query);
        if(!allScope.isEmpty() && allScope.size()>MAX_SCOPE) scopeTotalSize = allScope.size();

        return Database.getQueryLocator(query + (Test.isRunningTest() ? ' LIMIT 1' : ' LIMIT ' + MAX_SCOPE));
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        System.debug('### TrainingEventMimeoBatch.execute START ' + DateTime.now());
        System.debug('### scope size ' + scope.size());
        
        Mimeo_Settings__c ms = Mimeo_Settings__c.getOrgDefaults();
        //set how many records will be processed in each Scheduled Apex Job
        Integer maxListSize = ms.TrainingEvent_Batch_Update_Max_List_Size__c > 0 ? (Integer)ms.TrainingEvent_Batch_Update_Max_List_Size__c : 10;
        //set delay in seconds between each Apex Job
        Integer secondDelay = ms.TrainingEvent_Batch_Update_Second_Delay__c > 0 ? (Integer)ms.TrainingEvent_Batch_Update_Second_Delay__c : 20;

        if(countryDistributionDaysMap == null){
            countryDistributionDaysMap = new Map<String, Integer>();
            List<Mimeo_Country_Settings__mdt> mcsList = [SELECT Label, Distribution_Creation_Days__c FROM Mimeo_Country_Settings__mdt];
            for(Mimeo_Country_Settings__mdt mcs : mcsList){
                countryDistributionDaysMap.put(mcs.Label, (Integer)mcs.Distribution_Creation_Days__c);
            }
        }

        Set<Id> courseIds = new Set<Id>();
        for(Training_Event__c te : (List<Training_Event__c>) scope){
            courseIds.add(te.Course__c);
        }
        Map<Id, Product2> courseMap = new Map<Id, Product2>([SELECT (SELECT Name, Asset_Id__c FROM Mimeo_Documents__r WHERE Active__c = true) FROM Product2 WHERE Id IN :courseIds]);

        List<Id> eventIdsToUpdate = new List<Id>();
        for(Training_Event__c te : (List<Training_Event__c>) scope){
            System.debug('### Training Event: ' + te);
            if(!courseMap.get(te.Course__c).Mimeo_Documents__r.isEmpty() && Math.abs(te.Start_date__c.daysBetween(Date.today())) == countryDistributionDaysMap.get(te.Event_Country__c)){
                System.debug('### Mimeo Distribution Assignment: true');
                eventIdsToUpdate.add(te.Id);
            }
        }

        //divide scope into groups
        List<List<Id>> eventMasterList = new List<List<Id>>();
        List<Id> eventIdList = new List<Id>();

        for(Integer i=0; i<eventIdsToUpdate.size(); i++){
            if(eventIdList.size() == maxListSize){
                eventMasterList.add(eventIdList);
                eventIdList = new List<Id>();
            }

            eventIdList.add(eventIdsToUpdate.get(i));

            //handle last element
            if(i == eventIdsToUpdate.size()-1){
                eventMasterList.add(eventIdList);
            }
        }

        Integer i = 0;
        Integer jobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.JobType = '7'];
        for(List<Id> eventIds : eventMasterList){
            System.debug('### current scheduled jobs: ' + jobs);
            if(jobs < MAX_JOBS){
                DateTime dt = DateTime.now().addSeconds(20 + secondDelay * i);
                String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());
                i++;

                //process records in groups to minimize number of Scheduled Apex Jobs
                TrainingEventMimeoBatchUpdateSchedule mimeoJob = new TrainingEventMimeoBatchUpdateSchedule(eventIds);
                System.schedule('Training Event Mimeo Batch Update. List ' + i + ' scope ' + eventIds.size() + '. ' + String.valueOf(Integer.valueOf(Math.random()*100)), cron, mimeoJob);
                jobs++;
            }else{
                isJobOverLimit = true;
            }
        }
        System.debug('### TrainingEventMimeoBatch.execute END ' + DateTime.now());
    }

    public void finish(Database.BatchableContext batchContext){
        System.debug('### TrainingEventMimeoBatch.finish ' + DateTime.now());
        System.debug('### scopeTotalSize (0 means below MAX): ' + scopeTotalSize);
        System.debug('### isJobOverLimit: ' + isJobOverLimit);

        //send warning email if not all eligible records were processed (overflow scenario)
        //send warning email if max concurrent scheduled jobs limit reached
        Mimeo_Settings__c ms = Mimeo_Settings__c.getOrgDefaults();
        if((scopeTotalSize > 0 || isJobOverLimit) && ms != null && ms.Batch_Update_Email__c != null){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSaveAsActivity(false);
            email.subject = 'Training Event Mimeo Batch Update warning';
            email.plainTextBody = 'Salesforce organization Id: ' + UserInfo.getOrganizationId() + '\r\n';
            email.plainTextBody += 'Username: ' + UserInfo.getUserName() + '\r\n\r\n';
            email.plainTextBody += 'Training Event Mimeo Batch Update finished: ' + DateTime.now() + '\r\n';

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
    @future (callout=true)
    public static void createMimeoDistributionBulk(List<Id> eventIds, String cronTriggerId){
        System.debug('### createMimeoDistributionBulk size: ' + eventIds.size());

        Map<Id, Training_Event__c> eventMap = new Map<Id, Training_Event__c>([SELECT Event_Country__c FROM Training_Event__c WHERE Id IN :eventIds]);
        List<Training_Event__c> eventsToUpdate = new List<Training_Event__c>();

        try{
            for(Training_Event__c event : eventMap.values()){
                MimeoAPI mAPI = new MimeoAPI(event.Event_Country__c);
                MimeoAPI.CreateDistributionResponse distributionResponse = mAPI.createDistribution(event.Id);

                if(distributionResponse.Success){
                    event.Mimeo_Distribution_Assignment__c = true;
                    event.Mimeo_Distribution_Created_Date__c = DateTime.now();
                    event.Mimeo_Distribution_Id__c = distributionResponse.DistributionId;
                    event.Mimeo_Distribution_Link__c = distributionResponse.RedeemKeyUrl;
                    event.Mimeo_Error__c = null;
                }else{
                    event.Mimeo_Error__c = distributionResponse.ErrorMessage;
                }

                eventsToUpdate.add(event);
                System.debug('### Training Event to update: ' + event);
            }

            if(!eventsToUpdate.isEmpty()){
                //disable trigger
                bg_TrainingUtils.isMimeoDistributionAssignmentFirstRun = false;

                List<Database.SaveResult> saveResults = Database.update(eventsToUpdate, false);
                for(Integer i=0; i<saveResults.size(); i++){
                    if(saveResults[i].isSuccess()) System.debug('### Training Event ' + eventsToUpdate[i].Id + ' updated successfully');
                    else System.debug('### Training Event ' + eventsToUpdate[i].Id + ' update failed: ' + saveResults[i].getErrors()[0].getMessage());
                }
            }
        }catch(Exception e){
            System.debug('### Exception in createMimeoDistributionBulk: ' + e.getMessage());
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