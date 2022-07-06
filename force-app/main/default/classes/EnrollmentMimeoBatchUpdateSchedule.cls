/*
* Created By : PC K2 (July 2020)
* This class will perform Enrollment Mimeo Update logic
* 
* changelog
*/

public class EnrollmentMimeoBatchUpdateSchedule implements Schedulable {

    private List<Id> enrollmentIds;

    public EnrollmentMimeoBatchUpdateSchedule(List<Id> enrollmentIds){
        this.enrollmentIds = enrollmentIds;
    }

    public void execute(SchedulableContext sc){
        System.debug('### EnrollmentMimeoBatchUpdateSchedule.execute');
        System.debug('### CronTriggerId: ' + sc.getTriggerId());
        
        //synchronous callouts from Scheduled Apex are not supported, running @future callout
        EnrollmentMimeoBatch.assignMimeoKeysToUsersBulk(enrollmentIds, sc.getTriggerId());
    }
}