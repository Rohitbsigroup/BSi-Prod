public without sharing class LeadRoundRobinManager {
	
	/*
		Andrew Mahood, Tquila 
		Created: Wed 8th Feb 2012
		assigns leads based on round robin
		code sampled from https://gist.github.com/1562280
	*/
	public static void assignRoundRobinOnUpdate(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap) {
		 //Check if assignment owner has changed
	    //
	    Map<Integer,Id> queueIds = new Map<Integer,Id>();   //Trigger index --> Queue ID
	    
	    Integer idx = 0;
	    for (Lead l : newLeadMap.values())
	    {
	    	Lead oldLead = oldLeadMap.get(l.Id);
            if(l.OwnerId <> oldLead.OwnerId) {
                if (l.TempOwnerId__c == 'SKIP') {
                    l.TempOwnerId__c = '';
                } else {
                    queueIds.put(idx, l.OwnerId);
                }
            }  
            idx++;           
	    }
	    System.debug('>>>>>queueIds: '+queueIds);
	    if (queueIds.isEmpty()) return;
	    processRoundRobin(queueIds, newLeadMap.values());
	}
	public static void assignRoundRobinOnInsert(List<Lead> newLeads) {
		 //Check if assignment owner has changed
	    //
	    Map<Integer,Id> queueIds = new Map<Integer,Id>();   //Trigger index --> Queue ID
	    
	    Integer idx = 0;
	    for (Lead l : newLeads)
	    {
	    	if (l.TempOwnerId__c == 'SKIP') {
	    		l.TempOwnerId__c = '';
	    	} else {
	    		queueIds.put(idx, l.OwnerId); 
	        	idx++;
	    	}
	    }
	    System.debug('>>>>>queueIds: '+queueIds);
	    if (queueIds.isEmpty()) return;
	    processRoundRobin(queueIds, newLeads);
	}
	
	private static void processRoundRobin(Map<Integer,Id> queueIds, List<Lead> newLeads) {
		if (queueIds.isEmpty()) return;
		//
	    //Find active Assignment Group for Queue
	    //
	    Map<Integer,Id> asgnGroupNameIds = new Map<Integer,Id>();   //Trigger index --> Assignment_Group_Name ID
	    Map<Id,Assignment_Group_Queues__c> asgnGroupQueues = new Map<Id,Assignment_Group_Queues__c>(); //Queue ID --> Assignment Group Queues
	    
	    for(Assignment_Group_Queues__c[] agq : [SELECT Assignment_Group_Name__c, QueueId__c, Name
	                                          FROM Assignment_Group_Queues__c 
	                                          WHERE QueueId__c in :queueIds.values()
	                                          AND Active__c = 'True'
	                                          AND Assignment_Group_Name__r.Type__c = 'Lead'])
	    {
	    	system.debug('agq...' + agq);
	        for (Integer i = 0; i < agq.size() ; i++) {
	            asgnGroupQueues.put(agq[i].QueueId__c, agq[i]);
	        }                                           
	    }
	    System.debug('>>>>>asgnGroupQueues: '+asgnGroupQueues); 
	    if (asgnGroupQueues.isEmpty()) return;
		
	    for (Integer i : queueIds.keySet()) {
	        Assignment_Group_Queues__c agq = asgnGroupQueues.get(queueIds.get(i));
	        system.debug('>>>>>INDICE: '+i + ' AND ' + queueIds.get(i));
	        if (agq <> null) {
	            asgnGroupNameIds.put(i, agq.Assignment_Group_Name__c);
	            system.debug('>>>>>INDICEADDED: '+i + ' VALORE: ' + agq.Name);
	        }
	        //else no active assignment group queue error
	    }
	    System.debug('>>>>>asgnGroupNameIds: '+asgnGroupNameIds);
	    if (asgnGroupNameIds.isEmpty()) return;
	    
	    //
	    //Determine next valid user in Queue/Assignment Group for round robin
	    //User with earliest last assignment date wins.
	    //
	    Map<Id,Assignment_Groups__c[]> asgnGroups = new Map<Id,Assignment_Groups__c[]>(); // Assignment Group Name ID --> User ID
	    for(Assignment_Groups__c ag : [SELECT Group_Name__c, User__c, Last_Assignment__c, Millisecond__c, Name 
	                                   FROM Assignment_Groups__c 
	                                   WHERE Group_Name__c in :asgnGroupNameIds.values() 
	                                   AND Active__c = 'True' AND User_Active__c = 'True'
	                                   AND Group_Name__r.Type__c = 'Lead'
	                                   ORDER BY Last_Assignment__c, Millisecond__c])
	    {
            Assignment_Groups__c[] agrps=asgnGroups.get(ag.Group_Name__c);
            if (agrps==null) agrps=new List<Assignment_Groups__c>();
            system.debug('>>>>>>>GROUPNAME: ' + ag.Name);
            agrps.add(ag);
            asgnGroups.put(ag.Group_Name__c, agrps);
	    }
	    System.debug('>>>>>asgnGroups: '+asgnGroups);   
	    if (asgnGroups.isEmpty()) return;
	
	    Map<Id,Assignment_Groups__c> updateAssignmentGroups = new Map<Id,Assignment_Groups__c>();
	    Map<Id, datetime> latestAGDateTime = new Map<Id,datetime>();
	    Integer idx = 0;    
	    for (Integer i : queueIds.keySet())
	    {
	    	system.debug('>>>>>>QUEUEINDEX: ' + i);
	    	system.debug('>>>>>asgnGroupNameIds.get(i)...' + asgnGroupNameIds.get(i));//--> this should never be null...
	        Assignment_Groups__c[] ags = asgnGroups.get(asgnGroupNameIds.get(i));
	        system.debug('ags...' + ags);
	        if (ags != null && ags.size()>0)
	        {   
	            //Choose next user in line if user ID has already been used but not committed in this trigger batch
	            system.debug('math.mod(idx, ags.size()): ' + math.mod(idx, ags.size())); 
	            Assignment_Groups__c ag = ags[math.mod(idx, ags.size())];
	                
	            //Assign User to Lead as the new owner
	            System.debug('>>>>>Owner changed for Lead ' + newLeads[i].Id + ' from '+newLeads[i].OwnerId+' to '+ ag.User__c);
	            newLeads[i].OwnerId = ag.User__c;    
	            newLeads[i].TempOwnerId__c = '';  // don't assign back in an endless loop
	
	            //Set last assignment datetime
	            datetime now = datetime.now();
	            ag.Last_Assignment__c = now;
	            ag.Millisecond__c = now.millisecondGMT();
	            
	            //update only latest Assignment Groups per ID
	            if (latestAGDateTime.containsKey(ag.id)) {
	                if(latestAGDateTime.get(ag.id) < now) {
	                    updateAssignmentGroups.put(ag.id, ag);
	                    latestAGDateTime.put(ag.id, now);
	                }
	            } else {
	                updateAssignmentGroups.put(ag.id, ag);
	                latestAGDateTime.put(ag.id,now);
	            }
	            
	            idx++;
	        }
	    }
	    //Map --> List/Array for DML update
	    List<Assignment_Groups__c> updateAG = new List<Assignment_Groups__c>();
	    for (Id agId : updateAssignmentGroups.keySet()) {
	        updateAG.add(updateAssignmentGroups.get(agId));
	    }
	
	    System.debug('>>>>>Update Assignment Groups: '+updateAG);   
	    
	    //
	    //Update last assignment for Assignment Group in batch
	    //
	    if (updateAG.size()>0) {
	        try {
	            update updateAG;
	        } catch (Exception e){
	            for (Integer i : queueIds.keySet())
	            {
	                Trigger.new[i].addError('ERROR: Could not update Assignment Group records ' + ' DETAIL: '+e.getMessage());  
	            }
	        }
	    }
	}
	
	public static void leadOwnerUpdate(List<Lead> newLeads) {
		/* DONT TIHNK WE NEED THIS
		List<Lead> updateLeads = new List<Lead>();
	    Map<Id,Lead> leads = new Map<Id,Lead>();
	    
	    for (Lead l : newLeads)
	    {
            System.debug('>>>>> Owner ID: '+l.ownerId+' Temp Owner ID: '+ l.TempOwnerId__c);
            if(l.TempOwnerId__c <> null && l.TempOwnerId__c <> '') {
                if(l.OwnerId <> l.TempOwnerId__c) {
                    leads.put(l.id,l);
                }
            }            
	    }
	    if (leads.isEmpty()) return;
	    
	    for (Lead l : [SELECT OwnerId,TempOwnerId__c FROM Lead WHERE id in :leads.keySet()]) {
	        l.OwnerId = leads.get(l.Id).TempOwnerId__c;
	        l.TempOwnerId__c = 'SKIP'; //flag to stop infinite loop upon update
	        updateLeads.add(l);
	    }
	    System.debug('>>>>>Update Leads: '+updateLeads);
	    
	    //
	    //Update last assignment for Assignment Group in batch
	    //
	    if (updateLeads.size() > 0) {
	        try {
	            update updateLeads;
	        } catch (Exception e){
	
	        }
	    }
	    */
	}
}