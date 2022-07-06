/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         05/01/2012
* Description:  Handler class for ContactOpportunity (Custom Contact Roles) Trigger.
*       
**/
public with sharing class ContactOpportunityTriggerHandler {
	
	private Boolean lt_isExecuting = false;
	private Integer BatchSize = 0;
	
	// CONSTRUCTOR
	public ContactOpportunityTriggerHandler(Boolean isExecuting, Integer size){
		lt_isExecuting = isExecuting;
		BatchSize = size;
	}
	
	// BEFORE INSERT
	public void OnBeforeInsert(Contact_Opportunity__c[] newContactRoles){
		// Sync with Standard Contact Roles 
		List<OpportunityContactRole> stdRoles = new List<OpportunityContactRole>();
		for (Contact_Opportunity__c curr : newContactRoles) {
			OpportunityContactRole ocr = new OpportunityContactRole();
			ocr.ContactId = curr.Contact__c;
			ocr.isPrimary = curr.OppPrimary__c;
			ocr.OpportunityId = curr.Opportunity__c;
			ocr.Role = curr.OppRole__c;
			stdRoles.add(ocr);
		}
		insert stdRoles;
	}
	
	// BEFORE UPDATE
	public void OnBeforeUpdate(Contact_Opportunity__c[] updatedContactRoles, Map<Id,Contact_Opportunity__c> oldMap) {
		// Sync with Standard Contact Roles 
		Map<String,OpportunityContactRole> rolesMap = syncStdContactRoles(updatedContactRoles);
		List<OpportunityContactRole> stdRoles = new List<OpportunityContactRole>();
		Set<OpportunityContactRole> tmp = new Set<OpportunityContactRole>();
		for (Contact_Opportunity__c curr : updatedContactRoles) {
			Contact_Opportunity__c old = oldMap.get(curr.Id);
			if (rolesMap.get(old.Contact__c + old.OppRole__c + old.Opportunity__c) != null) {
				OpportunityContactRole ocr = rolesMap.get(old.Contact__c + old.OppRole__c + old.Opportunity__c);
				ocr.ContactId = curr.Contact__c;
				ocr.isPrimary = curr.OppPrimary__c;
				//ocr.OpportunityId = curr.Opportunity__c;
				ocr.Role = curr.OppRole__c;
				tmp.add(ocr);
			}
		}
		stdRoles.addAll(tmp);
		update stdRoles;
	}
	
	// BEFORE DELETE
	public void OnBeforeDelete(Contact_Opportunity__c[] deletedContactRoles, Map<Id,Contact_Opportunity__c> cRolesMap) {
		//Sync with Standard Contact Roles
		Map<String,OpportunityContactRole> rolesMap = syncStdContactRoles(deletedContactRoles);
		List<OpportunityContactRole> stdRoles = new List<OpportunityContactRole>();
		for (Contact_Opportunity__c curr : deletedContactRoles) {
			if (rolesMap.get(curr.Contact__c + curr.OppRole__c + curr.Opportunity__c) != null) {
				stdRoles.add(rolesMap.get(curr.Contact__c + curr.OppRole__c + curr.Opportunity__c));
			}
		}
		delete stdRoles;
	}
	
	// SYNC WITH STANDARD CONTACT ROLES
	public Map<String,OpportunityContactRole> syncStdContactRoles(List<Contact_Opportunity__c> customRoles) {
		Map<String,OpportunityContactRole> rolesMap = new Map<String,OpportunityContactRole>();	
		Set<Id> optyIds = new Set<Id>();
		for (Contact_Opportunity__c curr : customRoles) {
			optyIds.add(curr.Opportunity__c);
		}
		List<OpportunityContactRole> stdRoles = [SELECT ContactId, Role, IsPrimary, OpportunityId FROM OpportunityContactRole WHERE OpportunityId IN:optyIds];			
		for (OpportunityContactRole curr : stdRoles) {
			rolesMap.put(curr.ContactId + curr.Role + curr.OpportunityId,curr);
		}
		
		return rolesMap;
	}
	
}