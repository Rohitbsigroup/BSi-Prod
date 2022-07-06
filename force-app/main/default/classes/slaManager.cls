public without sharing class slaManager {
	//public static Integer SLA_HOURS = 12;
	//public static Integer SLA_HOURS_WARNING = 9;
	private static Set<String> SUCCESSFUL_CONTACT_STATUS = new Set<String>
                                {'Open-Contacted', 
                                 'Closed-Not Converted', 
                                 'Closed-Converted',
                                 'Closed-No Contact Details',
                                 'Unqualified'}; //statues that count as first contact for purpose of SLA
	
	private static boolean getRecalcLeadSLATrigger() {
    	BSIPermissions__c perms = BSIPermissions__c.getInstance();
    	Boolean retVal = perms.RecalcLeadSLATrigger__c;
    	system.debug('getRecalcLeadSLATrigger...' + retVal);
    	return retVal;
    }
    
	public static void calcFirstContactSLA(Map<Id, Lead> newLeads, Map<Id, Lead> oldLeads) {
    	/*
    	check that the lead was reassigned from System user to queue or user on update
    	This is requeired as informatica create leads are first owned by create user then reassigned using rules
    	informatica user has business hours = N/A so it SLA Date will be null
    	*/
    	List<Lead> recalcSLALeads = new List<Lead>();
    	
    	for (Lead newLead:newLeads.values()) {
    		Lead oldLead=oldLeads.get(newLead.Id);
    		if (newLead.SLATargetDate__c==null && 
    			newLead.OwnerId!=oldLead.OwnerId) {
    			
    			/*
    			1. SLA has not yet been calculated
    			2. Owner has changed
    			3. Current user is set to recalc trigger
    			
    			*/
    			if (getRecalcLeadSLATrigger()) {
    				recalcSLALeads.add(newLead);
    			}
    		}
    	}
    	
    	if (!recalcSLALeads.isEmpty()) calcFirstContactSLA(recalcSLALeads);
    }
    public static void calcFirstContactSLA(List<Lead> newLeads) {
        /*
        This method received a list of newLeads from an insert trigger
        The method will find the appropriate Business Hours record based on Lead Owner
        will then calculate the SLA based on the owenrs business hours
        */
        system.debug('calcFirstContactSLA...newLeads...' + newLeads);
        
        if (newLeads!=null && !newLeads.isEmpty()) {

            Set<Id> ownerIds = new Set<Id>();
            Set<String> businessHourNames = new Set<String>();
            
            //strip out the ownerid from each lead
            for (Lead lead:newLeads) {
                ownerIds.add(lead.OwnerId);
            }
            
            system.debug('calcFirstContactSLA...ownerIds...' + ownerIds);
            Map<Id, BusinessHours> businessHoursToUserIdMap = getUserOrQueueBusinessHoursMap(ownerIds);
            Map<Id,ConversionScore__c> countryDefault 		= getCountrySLA(ownerIds);
            
            if (businessHoursToUserIdMap!=null && businessHoursToUserIdMap.size()>0) {
                //reloop the list of new leads
                for (Lead lead:newLeads) {
                    BusinessHours businessHour 			= businessHoursToUserIdMap.get(lead.OwnerId); 
                    ConversionScore__c slaValues		= countryDefault.get(lead.OwnerId);              	
                    
                    if (businessHour != null && slaValues != null 
                    	&& slaValues.SLAHours__c != null && slaValues.SLAHoursWarning__c != null) {
                    	Integer SLA_HOURS 	 		= Integer.valueOf(slaValues.SLAHours__c);
                    	Integer SLA_HOURS_WARNING	= Integer.valueOf(slaValues.SLAHoursWarning__c);
                        //add 12 business hours to created date
                        datetime createdDate=lead.CreatedDate; //updates will have a value
                        if (createdDate==null) { //will be null for newly created leads
                        	createdDate=datetime.now();
                        }
                        
                        Datetime slaDatetime = BusinessHours.add(businessHour.id, createdDate, SLA_HOURS * 60 * 60 * 1000L);
                        Datetime slaWarningDatetime = BusinessHours.add(businessHour.id, createdDate, SLA_HOURS_WARNING * 60 * 60 * 1000L);
                        lead.SLATargetDate__c = slaDatetime;
                        lead.SLAWarningDate__c = slaWarningDatetime;
                    	lead.SLADuration__c = null;
                    	lead.SLATargetDuration__c = SLA_HOURS;
                    } else {
                        
                        //if no business hours found then set duration as -1
                        //this can be reported on or identified in SLA Status
                        lead.SLADuration__c = -1;
                        lead.SLATargetDate__c = null;
                        lead.SLAWarningDate__c = null;
                        lead.SLATargetDuration__c = null;
                    }
                }
            }
        }
    }
    
    // SLA Hours for each Country
    private static Map<Id,ConversionScore__c> getCountrySLA(Set<Id> ownerIds) {
		Map<Id,ConversionScore__c> countrySLAMap 		= new Map<Id,ConversionScore__c>();		
		Map<String,ConversionScore__c> countryDefault 	= ConversionScore__c.getAll();
		Map<String, QueueBusinessHours__c> queueBH 		= QueueBusinessHours__c.getAll();
		
		Set<Id> userIds 	= new Set<Id>();
		Set<Id> queueIds 	= new Set<Id>();
		
		for (Id curr : ownerIds) {
			// This is a Queue
			if (curr != null && string.valueOf(curr).startsWith('00G')) {
				queueIds.add(curr);
			} else if(curr != null){
				userIds.add(curr);
			}
		}
		
		if (!userIds.isEmpty()) {
			for (User curr : [SELECT OperationCountry__c FROM User WHERE Id IN :userIds]) {
				countrySLAMap.put(curr.Id,countryDefault.get(curr.OperationCountry__c));
			}
		} 
		if (!queueIds.isEmpty()) {
			for(Group curr:[SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN :queueIds ]) {
				string country = bg_Globals.REGION_US;
				if(queueBH.get(curr.Name) != null) {
					country = queueBH.get(curr.Name).Country__c;
				}
				countrySLAMap.put(curr.Id, countryDefault.get(country));				
			}
		}
		
		return countrySLAMap;
	}
    
    
    /*
    Method: getUserOrQueueBusinessHoursMap
    Description: Takes a set of User or Queue Ids and returns a map of the Id with corresponding Business Hours.
                 
    Parameters:  userOrQueueIds - set of user or queue Ids
    Author:      A Mahood
    Date:        24 Jan 2012
    */
    public static Map<Id, BusinessHours> getUserOrQueueBusinessHoursMap(Set<Id> userOrQueueIds) {
		
		system.debug('getUserOrQueueBusinessHoursMap...userOrQueueIds...' + userOrQueueIds);
		
		Set<Id> userIds = new Set<Id>();
		Set<Id> queueIds = new Set<Id>();
		//split list of Ids into Users and Queues
		for (Id userOrQueueId : userOrQueueIds) {
			system.debug('getUserOrQueueBusinessHoursMap...userOrQueueId...' + userOrQueueId);
			
			if (userOrQueueId != null && string.valueOf(userOrQueueId).startsWith('00G')) {
				//this is a queue
				queueIds.add(userOrQueueId);
			} else if(userOrQueueId != null){
				userIds.add(userOrQueueId);
			}
		}
		
		Map<String, Set<Id>> userOrQueueIdsToBusinessHourNameMap = new Map<String, Set<Id>>();
		Map<Id, BusinessHours> businessHoursToUserQueueIdMap = new Map<Id, BusinessHours>();
		
		if (userIds!=null && userIds.size()>0) {
			userOrQueueIdsToBusinessHourNameMap.putAll(getUserBusinessHoursNameMap(userIds));
		}
		if (queueIds!=null && queueIds.size()>0) {
			userOrQueueIdsToBusinessHourNameMap.putAll(getQueueBusinessHoursNameMap(queueIds));
		}
		
		system.debug('getUserOrQueueBusinessHoursMap...userOrQueueIdsToBusinessHourNameMap...' + userOrQueueIdsToBusinessHourNameMap);
		
		for (BusinessHours businessHour:[SELECT Id, Name
												FROM BusinessHours 
												WHERE IsActive = true
												AND Name IN :userOrQueueIdsToBusinessHourNameMap.keyset() ]) {
													
			system.debug('getUserOrQueueBusinessHoursMap...businessHour...' + businessHour);
			
			Set<Id> userOrQueueIdSet = userOrQueueIdsToBusinessHourNameMap.get(businessHour.Name);
			if (userOrQueueIdSet!=null) {
				for (Id uId:userOrQueueIdSet) {
					businessHoursToUserQueueIdMap.put(uId, businessHour);
				}
			}
		}
		
		//handle the invaid users or queues
		//these are usually where the queue mapping isnot correct or busines value not set on user
		Set<Id> invalid_userOrQueueIdsSet = userOrQueueIdsToBusinessHourNameMap.get('INVALID_HOURS');
		system.debug('getUserOrQueueBusinessHoursMap...invalid_userOrQueueIdsSet...' + invalid_userOrQueueIdsSet);
		if (invalid_userOrQueueIdsSet!=null) {
			for (Id uId:invalid_userOrQueueIdsSet) {
				businessHoursToUserQueueIdMap.put(uId, null);
			}
		}
		
		return businessHoursToUserQueueIdMap;
	}
	
	private static Map<String, Set<Id>> getUserBusinessHoursNameMap(Set<Id> userIds) {
		Map<String, Set<Id>> userIdsToBusinessHourNameMap = new Map<String, Set<Id>>();
		
		//now going to get the correct business hours for each lead owner
		if (userIds!=null && !userIds.isEmpty()) {
			//get the owners territroy so we can choose the business hours
			
			for (User u:[SELECT Id, Name, BusinessHours__c
									FROM User 
									WHERE Id IN :userIds ]) {
				
				system.debug('getUserBusinessHoursNameMap...u...' + u);
				if (u.BusinessHours__c!=null) {
					Set<Id> uIds = userIdsToBusinessHourNameMap.get(u.BusinessHours__c);
					if (uIds==null) {
						uIds=new Set<Id>();
					}
					uIds.add(u.Id);
					userIdsToBusinessHourNameMap.put(u.BusinessHours__c, uIds);
				} else {
					system.debug('WARNING: Business Hours not set-up for ' + u);
					
					//add a special map value for invalid users
					Set<Id> uIds = userIdsToBusinessHourNameMap.get('INVALID_HOURS');
					if (uIds==null) {
						uIds=new Set<Id>();
					}
					uIds.add(u.Id);
					userIdsToBusinessHourNameMap.put('INVALID_HOURS', uIds);
				}
				
			}
			
			return userIdsToBusinessHourNameMap;
		} else {
			System.debug('Warning: getUserBusinessHoursMap received no user Ids');
		}
		
		return null; //if got here return null
	}
	private static Map<String, Set<Id>> getQueueBusinessHoursNameMap(Set<Id> queueIds) {
		Map<String, Set<Id>> queueIdsToBusinessHourNameMap = new Map<String, Set<Id>>();
		
		//now going to get the correct business hours for each lead owner
		if (queueIds!=null && !queueIds.isEmpty()) {
			//get the owners territroy so we can choose the business hours
			
			Map<String, QueueBusinessHours__c> queueBusinessHoursByNameMap = QueueBusinessHours__c.getAll();
			system.debug('getQueueBusinessHoursNameMap...queueBusinessHoursByNameMap...' + queueBusinessHoursByNameMap);
			
			for (Group q:[SELECT Id, Name
						  FROM Group 
						  WHERE Type = 'Queue'
						  AND Id IN :queueIds ]) {
				
				system.debug('getQueueBusinessHoursNameMap...q...' + q);
				
				QueueBusinessHours__c qBusinessHours = queueBusinessHoursByNameMap.get(q.Name);
					
				system.debug('getQueueBusinessHoursNameMap...qBusinessHours...' + qBusinessHours);
									
				if (qBusinessHours!=null) {
					Set<Id> qIds = queueIdsToBusinessHourNameMap.get(qBusinessHours.BusinessHours__c);
					if (qIds==null) {
						qIds=new Set<Id>();
					}
					qIds.add(q.Id);
					queueIdsToBusinessHourNameMap.put(qBusinessHours.BusinessHours__c, qIds);
				} else {
					system.debug('WARNING: Business Hours not set-up for queue ' + q);
				
					//add a special map value for invalid queues
					Set<Id> qIds = queueIdsToBusinessHourNameMap.get('INVALID_HOURS');
					if (qIds==null) {
						qIds=new Set<Id>();
					}
					qIds.add(q.Id);
					queueIdsToBusinessHourNameMap.put('INVALID_HOURS', qIds);
				}
				
			}
			
			return queueIdsToBusinessHourNameMap;
		} else {
			System.debug('Warning: getUserBusinessHoursMap received no user Ids');
		}
		
		return null; //if got here return null
	}
	
	public static void stampFirstContactSLA(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap) {
        /*
        This method received a map of newLeads and oldLeads from an update trigger
        The method check if status has changed to a defined value
        if it has wil stamp the first contact date and how long it took in business hours
        */
        system.debug('stampFirstContact...newLeads...' + newLeadMap);
        
        if (newLeadMap!=null && !newLeadMap.isEmpty()) {
                
            Set<Id> ownerIds = new Set<Id>();
            List<Lead> firstContactLeads = new List<Lead>();
            
            for (Id leadId:newLeadMap.keyset()) {
                Lead newLead = newLeadMap.get(leadId);
                Lead oldLead = oldLeadMap.get(leadId);
                
                if (newLead.Status!=oldLead.Status) {
                    //lead status has changed
                    if (SUCCESSFUL_CONTACT_STATUS.contains(newLead.Status) 
	                            && newLead.FirstContactDate__c==null) {
                        
                        system.debug('stampFirstContact...SUCCESSFUL_CONTACT_STATUS...' + newLead);
                        //contact has been made for the first time
                        firstContactLeads.add(newLead);
                        ownerIds.add(newLead.OwnerId);
                    }
                }
            }
            
            Map<Id, BusinessHours> businessHoursToUserIdMap = getUserOrQueueBusinessHoursMap(ownerIds);
            
            system.debug('stampFirstContact...businessHoursToUserIdMap...' + businessHoursToUserIdMap);
            if (businessHoursToUserIdMap!=null && businessHoursToUserIdMap.size()>0) {
                //loop the list of first contact leads
                for (Lead lead:firstContactLeads) {
                    BusinessHours businessHour = businessHoursToUserIdMap.get(lead.OwnerId);
                    
                    if (businessHour!=null) {
                        Long slaDuration = BusinessHours.diff(businessHour.id, lead.CreatedDate, datetime.now());
                        lead.SLADuration__c = slaDuration / 60 / 60 / 1000L;
                        lead.FirstContactDate__c = datetime.now();
                    } else {
                        
                        //if no business hours found then set duration as -1
                        //this can be reported on or identified in SLA Status
                        lead.SLADuration__c = -1;
                    }
                }
            }
        }
    }
}