public class BatchUpdateEnrollmentLogin implements Database.Batchable<SObject>{
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Portal_Set_Password_Link__c FROM Enrollment__c WHERE Portal_Set_Password_Link__c != null';
        return Database.getQueryLocator(query);
    }
  
    public void execute(Database.BatchableContext BC, List<Enrollment__c> scope){
        for(Enrollment__c enrollment : scope){
            enrollment.Portal_Set_Password_Link__c = enrollment.Portal_Set_Password_Link__c.replace('login/','s/portalaccess');
        }
        Database.update(scope,false);
    }

    public void finish(Database.BatchableContext BC){
    
    }
}