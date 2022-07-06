/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         23/02/2012
* Description:  Handler class for Contact Trigger.
*       
**/
public with sharing class ContactTriggerHandler {
	
	private Boolean isExecuting = false;
	private Integer BatchSize = 0;
	
	// CONSTRUCTOR
	public ContactTriggerHandler(Boolean isExecuting, Integer size){
		isExecuting = isExecuting;
		BatchSize = size;
	}
	
	// BEFORE INSERT
	public void OnBeforeInsert(Contact[] newContacts){
		assignTerritory(newContacts);
	}
	
	// BEFORE UPDATE
	public void OnBeforeUpdate(Contact[] updatedContacts){
		assignTerritory(updatedContacts);
	}
	
	// ACCOUNT TERRITORY ASSIGNMENT
	public void assignTerritory(Contact[] contacts) {
		List<Territory__c> territories = [SELECT Country__c, PostZipCode__c FROM Territory__c];
		Map<String,Id> postcodeMap = Utility.getTerritoryMap(territories);
		if (!postCodeMap.keySet().isEmpty()) {
			for (Contact curr : contacts) {
				curr.MailingPostalCode = Utility.cleanPostcode(curr.MailingPostalCode);
				if (curr.MailingPostalCode == null && postcodeMap.get(curr.MailingCountry) != null) {
					curr.Territory__c = postcodeMap.get(curr.MailingCountry);
				} else if (curr.MailingPostalCode != null && postcodeMap.get(curr.MailingCountry+'#'+Utility.formtZipCode(curr.MailingPostalcode, curr.MailingCountry)) != null) {
					curr.Territory__c = postcodeMap.get(curr.MailingCountry+'#'+Utility.formtZipCode(curr.MailingPostalcode, curr.MailingCountry));
				} else if (curr.MailingState != null && postcodeMap.get(curr.MailingCountry+'#'+curr.MailingState) != null) {
					curr.Territory__c = postcodeMap.get(curr.MailingCountry+'#'+curr.MailingState);
				} else if (curr.MailingPostalCode != null && postcodeMap.get(curr.MailingCountry+'#'+Utility.formtZipCode(curr.MailingPostalcode, curr.MailingCountry)) == null) {
					curr.Territory__c = postcodeMap.get(curr.MailingCountry);
				} else {
					curr.Territory__c = null; // No match found - blank the field
				}
			}
		}
	}

	public void onAfterUpdate(List<Contact> newList, Map<Id, Contact> oldMap) {
		UserContactSync.updateUser(newList, oldMap);
	}
	
}