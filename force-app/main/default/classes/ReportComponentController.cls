public with sharing class ReportComponentController {
    static final String REPORT_PARAMETER_OPTION_NONE = 'None';
    static final String REPORT_PARAMETER_OPTION_RECORD = 'Record Id';
    static final String REPORT_PARAMETER_OPTION_ULTIMATE_PARENT = 'Ultimate Parent Id';    

    public static Account updateAccountAncestorFields(String recordId){
        // Iterates up the Account hierarchy from the current Account record to update Ancestors__c and AncestorsCount__c fields
        Account account = [SELECT Id, ParentId, Ancestors__c, Ancestor_Count__c FROM Account where Id = :recordId];
        if(account.ParentId !=null){
            Account parent = updateAccountAncestorFields(account.ParentId);
            account.Ancestor_Count__c = parent.Ancestor_Count__c+1;
            account.Ancestors__c = account.ParentId + (parent.Ancestors__c.length()>0? ','+parent.Ancestors__c : '');
        }else{
            account.Ancestor_Count__c = 0;
            account.Ancestors__c='';
        }
        update account;
        return account;
    }
    
    public static ID getUltimateParentId(String recordId){
        Account account = [SELECT Id, ParentId, Ancestors__c, Ancestor_Count__c FROM Account where Id = :recordId];
      	return account.Ancestor_Count__c>0? account.Ancestors__c.right(18) : account.id;
    }

    @AuraEnabled
    public static String getReportData( Id reportId, String recordId, String reportParameterOption){
        // First update the Account.Ancestors__c and Ancestor_Count__c fields for all parents up to the ultimate parent. 
        // This allows reports to include records linked to parent accounts by filtering on Account.Ancestors Contains <current Accouunr>
        // The Ancestor_Count__c field allows us to order according to the level of the associated account.
        System.debug('Updating Account Ancestor fields...');
        updateAccountAncestorFields(recordId);
        Integer lastFilterIndex=0;			// To help build the link to the actual report, including any filter settings that is to be included in the aura component.
        String filterValue='';
        // Get the report data and filters
        System.debug('Getting report data...');
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);  
        Reports.ReportMetadata reportMetadata = describe.getReportMetadata(); 
        List<Reports.ReportFilter> filters = reportMetadata.getReportFilters();
        if(!reportParameterOption.equals(REPORT_PARAMETER_OPTION_NONE) && filters.size()>0){
            // Overwrite the valule of the last filter in the report with the recordId. Make sure this behaviour is what you need! 
	        System.debug('Setting report filter...');
            lastFilterIndex = filters.size()-1;
            filterValue = reportParameterOption.equals(REPORT_PARAMETER_OPTION_ULTIMATE_PARENT)?getUltimateParentId(recordId):recordId;
            Reports.ReportFilter lastFilter = filters.get(lastFilterIndex);  
            lastFilter.setValue(filterValue);
        }
        Reports.ReportResults reportResults = Reports.ReportManager.runReport(reportId, reportMetadata, true);
        String linkQueryString = filterValue.length()>0?'?fv'+lastFilterIndex+'='+filterValue:'';
        Map<String,Object> resultMap = new Map<String,Object>{'reportResults' => reportResults, 'linkQueryString' => linkQueryString};
        System.debug('Returning...');
        return JSON.serializePretty(resultMap);
    }
}