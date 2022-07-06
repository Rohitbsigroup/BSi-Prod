/*
* Created By : PC K2 (March 2020)
* This class will perform Litmos Batch Update logic
* 
* changelog
* PC K2      06-10-2020 bulkify record processing to minimize number of apex jobs
*/

global class LitmosBatchEnrollmentUpdateSchedule implements Schedulable {

    private List<Id> enrollmentIds;

    public LitmosBatchEnrollmentUpdateSchedule(List<Id> enrollmentIds){
        this.enrollmentIds = enrollmentIds;
    }

    global void execute(SchedulableContext sc){
        System.debug('### LitmosBatchEnrollmentUpdateSchedule.execute');
        System.debug('### CronTriggerId: ' + sc.getTriggerId());
        
        //synchronous callouts from scheduled Apex are not supported, running future callout
        LitmosBatchUpdate.LitmosBatchEnrollmentUpdate(enrollmentIds, sc.getTriggerId());
    }
}