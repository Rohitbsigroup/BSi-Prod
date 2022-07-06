trigger setClientFunctionOpportunityLookup on Opportunity (before insert, before update) {
    Map<Id, Map<String, Map<String, Set<Opportunity>>>> accountMap = new Map<Id, Map<String, Map<String, Set<Opportunity>>>>();
    System.Debug('setClientFunctionOpportunityLookup has '+Trigger.new.size()+' records to process.');
    Set<Id> accIds = new Set<Id>(); 
    Set<Client_Function_Opportunity__c> cfoSet = new Set<Client_Function_Opportunity__c>();
    for (Opportunity opp : Trigger.new){
        accIds.add(opp.AccountId);
    }
    System.Debug('setClientFunctionOpportunityLookup found '+accIds.size()+ 'related accounts');
    
    // Get all Client_Function_Opportunities related to the accounts referenced by the opportunities.
    List<Client_Function_Opportunity__c> cfos = [SELECT Id, Account__r.id, Client_Function__c, Client_Subfunction__c FROM Client_Function_Opportunity__c where Account__r.id in :accIds];
    System.Debug('setClientFunctionOpportunityLookup found '+cfos.size()+ 'related CFOs');
    
    // Set the opportunities' Client_Function_Opportunity lookups accordingly.
    for (Opportunity opp : Trigger.new){
        opp.Client_Function_Opportunity__c=null;
        if(!String.isBlank(opp.Client_Function__c) && !String.isBlank(opp.Client_Subfunction__c)){
            for(Client_Function_Opportunity__c cfo: cfos ){
                if(cfo.account__r.id==opp.AccountId && cfo.Client_Function__c == opp.Client_Function__c && cfo.Client_Subfunction__c == opp.Client_Subfunction__c){
                    opp.Client_Function_Opportunity__c = cfo.id;
                    System.Debug('setClientFunctionOpportunityLookup updated opp "'+opp.Name+ '", linking it to CFO '+cfo.id);
                    break;
                } 
            }
        }
    }
}