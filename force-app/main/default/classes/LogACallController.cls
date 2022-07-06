/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         09/11/2011
* Description:  Visualforce Controller used to replace the standard Log a Call
*				feature. All the previous activities will be displayed in the 
*				edit layout. 
*
*       
**/
public without sharing class LogACallController {
	
	public Task		mainTask		{get; set;}
	public Task		followUp		{get; set;}
	
	public String	rObjectId		{get; set;}
	public String	rObjectType		{get; set;}
	
	public Boolean	showFollowUp	{get; set;}
	
	ActivitySetting__c ts = ActivitySetting__c.getInstance();
	LeadSetting__c ls	  = LeadSetting__c.getInstance();
		
	public LogACallController() {	
		
		rObjectId = Apexpages.currentPage().getParameters().get('roid');
		rObjectType = Apexpages.currentPage().getParameters().get('rotype');
		
		mainTask = new Task();
		followUp = new Task();
		
		mainTask.OwnerId = Userinfo.getUserId();
		followUp.OwnerId = Userinfo.getUserId();		
		mainTask.ActivityDate = Date.today();
		mainTask.Type = ts.TypeCall__c;
		mainTask.Status = ts.StatusComplete__c;
		
		showFollowUp = false;
		
		// Choose the right polymorphic field (WhoId - WhatId)
		if (rObjectType == 'Lead' || rObjectType == 'Contact') {
			mainTask.WhoId = rObjectId;
			followUp.WhoId = rObjectId;
		} else {
			mainTask.WhatId = rObjectId;
			followUp.WhatId = rObjectId;
		}
	}
	
	// SELECT TO SHOW FOLLOWUP
	public void followUp() {
		showFollowUp = !showFollowUp;
	}
	
	// SAVE TASK AND FOLLOW UP (IF SELECTED)
	public Pagereference saveAll() {
		Pagereference detailPage;
		
		try {			
			upsert mainTask;
			if (showFollowUp) insert followup;
			if (rObjectType == 'Lead' && mainTask.Status == ts.StatusComplete__c) {
				Lead l = [SELECT Status,Country FROM Lead WHERE Id =: rObjectId];
				l.Status = ls.StatusContacted__c;
				update l;
			} else if (rObjectType == 'Lead' && mainTask.Status == ts.StatusAttempted__c) {
				Lead l = [SELECT FirstContactDate__c,CreatedDate,OwnerId,Country FROM Lead WHERE Id =: rObjectId];
				if(l.FirstContactDate__c == null) {
					Set<Id> owner = new Set<Id>();
					owner.add(l.OwnerId);
					Map<Id, BusinessHours> bhMap = slaManager.getUserOrQueueBusinessHoursMap(owner);					
					BusinessHours businessHour = bhMap.get(l.OwnerId);
                    Long slaDuration = BusinessHours.diff(businessHour.id, l.CreatedDate, datetime.now());
                    l.SLADuration__c = slaDuration / 60 / 60 / 1000L;
                    l.FirstContactDate__c = Datetime.now();
					update l;
				}
			}
			detailPage = new Pagereference('/' + rObjectId);
		} catch (DmlException dml) {
			ApexPages.addMessages(dml);
			detailPage = null;
		}
		
		return detailPage;
	}
	
	// BACK TO DETAIL PAGE
	public Pagereference back() {
		Pagereference detailPage = new Pagereference('/' + rObjectId);
		return detailPage;
	}
}