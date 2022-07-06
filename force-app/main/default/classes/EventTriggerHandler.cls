/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         28/11/2011
* Description:  Handler class for Event Trigger.
*       
**/
public without sharing class EventTriggerHandler {
	
	private Boolean lt_isExecuting = false;
	private Integer BatchSize = 0;
	
	// CONSTRUCTOR
	public EventTriggerHandler(Boolean isExecuting, Integer size){
		lt_isExecuting = isExecuting;
		BatchSize = size;
	}
	
	// AFTER INSERT
	public void OnAfterInsert(Event[] newEvents){
		// Only if the CreatedBy and WhoId are different then send an email
		SystemSetting__c setting = SystemSetting__c.getInstance();
		List<Event> toSend = new List<Event>();
		for (Event curr:newEvents) {
			if (curr.CreatedById != curr.OwnerId && !setting.SkipValidationRule__c) {
				toSend.add(curr);
			}
		}
		if (!toSend.isEmpty()) sendEmailToAssignee(toSend);
	}
	
	// -------- BUSINESS LOGIC ----------
	
	// Send an email to the Assignee
	public void sendEmailToAssignee(Event[] emailEvents) {
		List<EmailTemplate> template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'AlertEventOwner'];
		if (!template.isEmpty()) {
			List<Messaging.Singleemailmessage> mails = new List<Messaging.Singleemailmessage>();
			for(Event curr:emailEvents) {
				if (curr.WhoId != null || curr.WhatId != null) {					
					Messaging.Singleemailmessage mail = new Messaging.SingleEmailMessage();
					mail.setTemplateId(template.get(0).Id);
					mail.setTargetObjectId(curr.OwnerId);
					mail.setWhatId(curr.Id);
					mail.setSaveAsActivity(false);
					mails.add(mail);
				}
			}	
			Messaging.sendEmail(mails);
		}
	}
	
	// -------- BUSINESS LOGIC END ----------
}