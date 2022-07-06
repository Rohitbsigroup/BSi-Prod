/**
*
* Author 		: Prasad J N
* Date			: 22 May 2018 
* Description	: Apex class to run after sandbox refresh to rese tthe custom settings, URL, unschedule reports etc.
*
*/
global without sharing class emq_SandboxActivation implements SandboxPostCopy {
	
    global void runApexClass(SandboxContext context) { 
    	String orgId = context.organizationId(); 
        String sandboxId = context.sandboxId(); 
        String sandboxName = context.sandboxName();
        
        updateBlueprintSettings(sandboxName, orgId);
        updateTrainingSettings(sandboxName, orgId);
        unscheduleReports(); 
        updateSysAdminEmailAddresses();
    }
    
 	private static void updateBlueprintSettings(String sandboxName, String orgId) {
 		BPSettings__c blueprintSettings = BPSettings__c.getOrgDefaults();
 		blueprintSettings.Blueprint_Server_Path__c = blueprintSettings.Blueprint_Server_Path__c.replace('_', '_' + sandboxName + '_');
 		blueprintSettings.Blueprint_Server_Path_Legacy__c = blueprintSettings.Blueprint_Server_Path_Legacy__c.replace('_', '_' + sandboxName + '_');
 		blueprintSettings.SalesforceURL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/16.0/' + orgId;
 		
 		update blueprintSettings;
 	}
 	
 	private static void updateTrainingSettings(String sandboxName, String orgId) {
 		LitmosSettings__c litmosSettings = LitmosSettings__c.getOrgDefaults();
 		litmosSettings.API__c = 'https://api.litmos.com/v1.svc/';
 		litmosSettings.API_Key__c = '447c6d82-3a7b-4aa0-ac20-af2d9de67fd4';
 		litmosSettings.Source__c= 'bsisandbox' + sandboxName; 
 		
 		update litmosSettings;
 		
 		SystemSetting__c systemSetting = SystemSetting__c.getOrgDefaults();
 		systemSetting.Pointglobal_TrainingSMOService__c = 'https://pgplus.bsigroup.com/TrainingSMOServiceTest/Service1.asmx';
 		systemSetting.ContentURL__c = URL.getSalesforceBaseUrl().toExternalForm();
 		systemSetting.BlueprintURL__c = systemSetting.BlueprintURL__c.replace('_', '_' + sandboxName + '_');
 		systemSetting.ServerURL__c = URL.getSalesforceBaseUrl().toExternalForm();
 		systemSetting.Ingenico_Ogone_DIRECTLINK_URL__c = 'https://secure.ogone.com/ncol/test/orderdirect.asp';
 		systemSetting.Ingenico_Ogone_ALIASGATEWAY_URL__c = 'https://secure.ogone.com/ncol/test/alias_gateway.asp';
 		
 		update systemSetting;
 	}
 	
 	private static void unscheduleReports() {
 		List<CronTrigger> crons = [SELECT CronJobDetail.Name, CronJobDetail.JobType, StartTime, Id FROM CronTrigger];
		
		for(CronTrigger cron:crons){
		    System.abortJob(cron.id);
		}
 	}
 	
 	private static void updateSysAdminEmailAddresses() {
 		List<User> users = [SELECT Id, Email,Profile.Name FROM User];
 		
 		for(User u: users) {
 			if('System Administrator'.equals(u.Profile.Name))
				u.Email = u.Email.replace('.invalid', '');
				
			u.BlueprintLicence__c = 'Yes';
 		}
 		
 		update users;
 	} 
}