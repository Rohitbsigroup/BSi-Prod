global class LeadPardotSyncSchedule implements Schedulable
{
    global void execute(SchedulableContext scMain) {
        LeadPardotSyncBatch leadBatch  = new LeadPardotSyncBatch();
        Database.executeBatch(leadBatch, 2000);
    }
    
    public void runSelf(string s) {
        LeadPardotSyncSchedule CRON1 = new LeadPardotSyncSchedule();
        LeadPardotSyncSchedule CRON2 = new LeadPardotSyncSchedule();
        LeadPardotSyncSchedule CRON3 = new LeadPardotSyncSchedule();
        LeadPardotSyncSchedule CRON4 = new LeadPardotSyncSchedule();
        
        System.schedule(s +'Updates Leads for pardot 1', '0 00 * * * ?', CRON1); 
        System.schedule(s +'Updates Leads for pardot 2', '0 15 * * * ?', CRON2); 
        System.schedule(s +'Updates Leads for pardot 3', '0 30 * * * ?', CRON3); 
        System.schedule(s +'Updates Leads for pardot 4', '0 45 * * * ?', CRON4);   
    }
}