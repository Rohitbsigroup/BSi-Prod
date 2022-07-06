/********************************************************************
* ContactPardotSyncSchedule
*
* Schedule class for ContactPardotSyncBatch every 15 min
*
* Author: Nebula - Robert Bedding
* Created: 08-08-2016 
********************************************************************/
global class ContactPardotSyncSchedule implements Schedulable
{
    global void execute(SchedulableContext scMain) {
        ContactPardotSyncBatch contactBatch  = new ContactPardotSyncBatch();
        Database.executeBatch(contactBatch, 2000);
    }
    
    public void runSelf(string s) {
        ContactPardotSyncSchedule CRON1 = new ContactPardotSyncSchedule();
         ContactPardotSyncSchedule CRON2 = new ContactPardotSyncSchedule();
         ContactPardotSyncSchedule CRON3 = new ContactPardotSyncSchedule();
         ContactPardotSyncSchedule CRON4 = new ContactPardotSyncSchedule();
        
        System.schedule(s +'Updates Contacts for pardot 1', '0 00 * * * ?', CRON1); 
        System.schedule(s +'Updates Contacts for pardot 2', '0 15 * * * ?', CRON2); 
        System.schedule(s +'Updates Contacts for pardot 3', '0 30 * * * ?', CRON3); 
        System.schedule(s +'Updates Contacts for pardot 4', '0 45 * * * ?', CRON4);   
    }
}