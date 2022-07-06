/*
* Created By : PC K2 (July 2020)
* This class will perform Training Event Mimeo Update logic
* 
* changelog
*/

public class TrainingEventMimeoBatchUpdateSchedule implements Schedulable {

    private List<Id> eventIds;

    public TrainingEventMimeoBatchUpdateSchedule(List<Id> eventIds){
        this.eventIds= eventIds;
    }

    public void execute(SchedulableContext sc){
        System.debug('### TrainingEventMimeoBatchUpdateSchedule.execute');
        System.debug('### CronTriggerId: ' + sc.getTriggerId());
        
        //synchronous callouts from Scheduled Apex are not supported, running @future callout
        TrainingEventMimeoBatch.createMimeoDistributionBulk(eventIds, sc.getTriggerId());
    }
}