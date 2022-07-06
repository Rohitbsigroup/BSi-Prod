/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         11/11/2011
* Description:  Handler class for Lead Trigger.
*       
**/ 
public with sharing class LeadTriggerHandler {
	
	private Boolean isExecuting = false;
	private Integer BatchSize = 0;

	// CONSTRUCTOR
	public LeadTriggerHandler(Boolean isExecuting, Integer size){
		isExecuting = isExecuting;
		BatchSize = size;
	}

	// BEFORE INSERT	
	public void OnBeforeInsert(Lead[] newLeads){
		LeadRoundRobinManager.assignRoundRobinOnInsert(newLeads);
		if (!Utility.lockassignTerritory) assignTerritory(newLeads);
		assignManager(newLeads);
		slaManager.calcFirstContactSLA(newLeads);
		bg_ProductUtils.UpdateProductClassification(newLeads, null);
		//LeadConversionScoreCalc.calcConvScore(newLeads);
	}

	// AFTER INSERT
	public void OnAfterInsert(Lead[] newLeads){
		
	}
	
	// BEFORE UPDATE
	public void OnBeforeUpdate(Lead[] oldLeads, Lead[] updatedLeads, Map<ID, Lead> newleadMap, Map<ID, Lead> oldleadMap){
		LeadRoundRobinManager.assignRoundRobinOnUpdate(newLeadMap, oldLeadMap);
		
		if (!Utility.lockassignTerritory) assignTerritory(updatedLeads);
		assignManager(updatedLeads);
		//blockLeadStatusUpdate(updatedLeads, newleadMap, oldleadMap);
		bg_LeadUtils.CheckForCompletedCalls(updatedLeads, newleadMap, oldleadMap);
		
		//Lead First Contact SLA
		slaManager.calcFirstContactSLA(newleadMap, oldleadMap);
		slaManager.stampFirstContactSLA(newleadMap, oldleadMap);	

		bg_ProductUtils.UpdateProductClassification(updatedLeads, oldleadMap);
		
		//LeadConversionScoreCalc.calcConvScore(updatedLeads);	
	}
	
	// AFTER UPDATE
	public void OnAfterUpdate(Lead[] oldLeads, Lead[] updatedLeads, Map<ID, Lead> leadMap){
		LeadRoundRobinManager.leadOwnerUpdate(updatedLeads);
	}
	
	// BEFORE DELETE
	  public void OnBeforeDelete(Lead[] leadsToDelete, Map<ID, Lead> leadMap){ 	
		
	}
	
	// AFTER DELETE
	public void OnAfterDelete(Lead[] deletedLeads, Map<ID, Lead> leadMap){
		// Handle retaining values when lead are merged		
		bg_LeadUtils.MergeLeads(deletedLeads, leadMap);
	}
	
	// (AFTER) UNDELETE
	public void OnUndelete(Lead[] restoredLeads){
		
	}
	
	// -------- BUSINESS LOGIC ----------
	
	// STATUS UPDATE CHECK
	// Status => Contacted 			needed at least 1 completed task
	// Status => Not Converted		needed at least 5 attempted calls or 1 completed task
	// Reason => 5 Call Close		needed at least 5 attempted calls
/*	
	public void blockLeadStatusUpdate(Lead[] updatedLeads, Map<ID, Lead> newleadMap, Map<ID, Lead> oldleadMap) {
		LeadSetting__c ls 		= LeadSetting__c.getInstance();
		ActivitySetting__c ts 	= ActivitySetting__c.getInstance();
		
		// Filtering only the Leads with Status changed to 'Contacted' or 'Not Converted'
		List<Lead> contacted 	= new List<Lead>();
		List<Lead> closing		= new List<Lead>();
		for (Lead l :updatedLeads) {
			if ((l.Status == ls.StatusContacted__c) || // (l.Status == ls.StatusContacted__c && oldleadMap.get(l.Id).Status != ls.StatusContacted__c) ||
				(l.Status == ls.StatusNotConverted__c //&& oldleadMap.get(l.Id).Status != ls.StatusNotConverted__c
				&& l.ReasonClosed__c != ls.FiveCalls__c && l.ReasonClosed__c != ls.ProcessedSF__c 
				&& l.DetailedReasonClosed__c != ls.InsufficientDetailsReason__c && l.ReasonClosed__c != ls.DuplicateReason__c)) { 
				contacted.add(l);
			} else if (l.Status == ls.StatusNotConverted__c && //oldleadMap.get(l.Id).Status != ls.StatusNotConverted__c && --> avoid cheating
						l.ReasonClosed__c == ls.FiveCalls__c && oldleadMap.get(l.Id).ReasonClosed__c != ls.FiveCalls__c) {
				closing.add(l);
			}
		}
		
		List<Task> completedTask = [SELECT Id,WhoId,Status FROM Task WHERE WhoId IN :updatedLeads AND (Status =:ts.StatusComplete__c OR Status =:ts.StatusAttempted__c)];
		Map<Id,List<Task>> leadTasksC = new Map<Id,List<Task>>();
		Map<Id,List<Task>> leadTasksA = new Map<Id,List<Task>>();
		
		for (Task t :completedTask) {
			if (t.Status == ts.StatusComplete__c) {
				if (leadTasksC.containsKey(t.WhoId)) {
					leadTasksC.get(t.WhoId).add(t);
				} else {
					List<Task> temp = new List<Task>();
					temp.add(t);
					leadTasksC.put(t.WhoId,temp);
				}
			}
			if (t.Status == ts.StatusAttempted__c) {
				if (leadTasksA.containsKey(t.WhoId)) {
					leadTasksA.get(t.WhoId).add(t);
				} else {
					List<Task> temp = new List<Task>();
					temp.add(t);
					leadTasksA.put(t.WhoId,temp);
				}
			}
		}
		
		for (Lead l :contacted) {
			l.HasCompletedTask__c = leadTasksC.containsKey(l.Id);			
			//if (l.leadsource != 'Self Generated' && !leadTasksC.containsKey(l.Id)) {
			//	l.addError(Utility.niceErrorMessage('At least one <span style="color:red;">Completed</span> task is needed in order to change Lead status to <span style="color:green;">' + l.Status + '</span>','Lead'));
			//}
		}

		for (Lead l :closing) {
			Integer attemptLeft = 5;
			if (!leadTasksC.containsKey(l.Id)) {
				// There is no completed task so check for attempted calls number
				if (!leadTasksA.containsKey(l.Id) || (leadTasksA.containsKey(l.Id) && leadTasksA.get(l.Id).size() < 5)) {
					if (leadTasksA.containsKey(l.Id)) {
						attemptLeft = 5 - leadTasksA.get(l.Id).size();
					}
					l.addError(Utility.niceErrorMessage('At Least <span style="color:red;font-size:16px">5</span> attempted calls are needed in order to change Lead status to <span style="color:green;">' 
							+ l.Status + '</span>','Lead','You have <span style="font-size:16px;color:red;">' 
							+ attemptLeft + '</span> attempted calls left to close the Lead.'));
				}
			}
			// There is a completed task so check for Reason		
			else {
				if ((!leadTasksA.containsKey(l.Id) && l.ReasonClosed__c == ls.FiveCalls__c) || (leadTasksA.containsKey(l.Id) && l.ReasonClosed__c == ls.FiveCalls__c && leadTasksA.get(l.Id).size() < 5)) {
					attemptLeft = 0;
					if (leadTasksA.containsKey(l.Id)) {
						attemptLeft = leadTasksA.get(l.Id).size();
					}
					l.addError(Utility.niceErrorMessage('At Least <span style="color:red;font-size:16px">5</span> attempted calls are needed in order to change Lead Reason Close to <span style="color:green;">' 
							+ l.ReasonClosed__c + '</span>','Lead','You have <span style="font-size:16px;color:red;">' 
							+ attemptLeft + '</span> attempted call(s).'));
				}
			}
		
		}
	}
*/	
	// LEAD TERRITORY ASSIGNMENT
	public void assignTerritory(Lead[] leads) {
		List<Territory__c> territories = [SELECT Country__c, PostZipCode__c FROM Territory__c];
		Map<String,Id> postcodeMap = Utility.getTerritoryMap(territories);
		
		if (!postCodeMap.keySet().isEmpty()) {
			for (Lead curr : leads) {
				curr.PostalCode = Utility.cleanPostcode(curr.PostalCode);
				if (curr.PostalCode == null && postcodeMap.get(curr.Country) != null) {
					curr.Territory__c = postcodeMap.get(curr.Country);
				} else if (curr.PostalCode != null && postcodeMap.get(curr.Country+'#'+Utility.formtZipCode(curr.Postalcode, curr.Country)) != null) {
					curr.Territory__c = postcodeMap.get(curr.Country+'#'+Utility.formtZipCode(curr.Postalcode, curr.Country));
				} else if (curr.State != null && postcodeMap.get(curr.Country+'#'+curr.State) != null) {
					curr.Territory__c = postcodeMap.get(curr.Country+'#'+curr.State);
				} else if (curr.PostalCode != null && postcodeMap.get(curr.Country+'#'+Utility.formtZipCode(curr.Postalcode, curr.Country)) == null) {
					curr.Territory__c = postcodeMap.get(curr.Country);
				} else {
					curr.Territory__c = null; // No match found - blank the field
				}
			}
		}
	}
	
	// LEAD MANAGER ASSIGNMENT [TIME BASED WORKFLOW EMAIL REQUIREMENT - NOT CONTACTED LEAD]
	public void assignManager(Lead[] leads) {
		Set<Id> ownerIds = new Set<Id>();
		for (Lead curr : leads) {
			ownerIds.add(curr.OwnerId);
		}
		Map<Id,User> managerMap = new Map<Id,User>([SELECT ManagerId FROM User WHERE Id IN :ownerIds]);
		//Map<Id,Id> managerMap = new Map<Id,Id>();
		//List<User> owners = [SELECT ManagerId, FROM User WHERE Id IN :ownerIds];
		//for (User curr : owners) {
		//	managerMap.put(curr.Id,curr.ManagerId);
		//}
		for (Lead curr : leads) {
			if (managerMap.get(curr.OwnerId) != null) {
				curr.Manager__c = managerMap.get(curr.OwnerId).ManagerId;
				curr.ReportingOwner__c = curr.OwnerId;
			} else {
				curr.Manager__c = null;
				curr.ReportingOwner__c = null;
			}
		}
	}
	
	// -------- BUSINESS LOGIC END ----------
}