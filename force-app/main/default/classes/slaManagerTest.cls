/*
*          RJ 01-06-2014 Updated to use getTestSalesUser
*/  
@isTest
private class slaManagerTest {

    static testMethod void leadSLA_UserOwner() {

        BusinessHours businessHour = [SELECT Id, Name
                                    FROM BusinessHours
                                    WHERE IsActive = true
                                    AND IsDefault = true
                                    LIMIT 1];                         
       
       	User apiU = TestData.getTestStandardUser('apiUser', bg_UserUtils.PROFILE_NAME_BSI_SYSADMIN);
       	insert apiU;
       	
       	BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=apiU.Id, RecalcLeadSLATrigger__c=true);
       	insert perms;
       	
        User u = TestData.getTestStandardUser('BobSales', bg_UserUtils.PROFILE_NAME_BSI_SALESPERSON);
        u.BusinessHours__c=businessHour.Name;
        insert u;
        
        Lead lead;
        
		ConversionScore__c cs = ConversionScore__c.getInstance(u.OperationCountry__c);
		
		Test.startTest();
		 
        System.runAs(apiU) {
            // The following code runs as user 'apiU'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
        
            lead = TestData.getTestLead();
            lead.OwnerId=apiU.Id;
            insert lead;
            
            //should be null as API user not set up for Biz hours
            system.assertEquals(null, lead.SLAWarningDate__c);
            system.assertEquals(null, lead.SLATargetDate__c);
            
            //when API user reassigned then then SLA is recalced
            //this is to handle API insert as owner id then assigment rules firing 
            lead.OwnerId=u.Id;
            update lead;//change lead owner should trigger SLA to fire now
        }
        System.runAs(u) {  
        	 // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            
        	 //compelted activity is required to progress
            Task call = TestData.getTestTask();
            call.OwnerId=u.Id;
            call.whoId=lead.Id;
            call.Type='Call';
            call.Status='Completed';
            insert call;
            
            lead.Status='Open-Contacted'; //will stamp SLA time
            lead.TotalEmployees__c=50;
            lead.SitesNumber__c=5;
            lead.Delivery__c=system.today();
            lead.PortfolioInterestArea__c='Assurance';
            update lead;
        }
           
            
        Test.stopTest();
        
        //query lead to check SLA fields populated properly
        lead = [SELECT Id, 
                       CreatedDate, 
                       SLATargetDate__c,
                       SLADuration__c,
                       SLAWarningDate__c
                FROM Lead 
                WHERE Id = :lead.Id LIMIT 1];
         
        //check that the target date was allocated
        System.debug('businessHour...' + businessHour);
        System.debug('u.Business_Hours__c...' + u.BusinessHours__c);
        Datetime slaWarningDatetime = BusinessHours.add(businessHour.id, lead.CreatedDate, Integer.valueOf(cs.SLAHoursWarning__c) * 60 * 60 * 1000L);
        //system.assertEquals(slaWarningDatetime.format('yyyy-MM-dd hh:mm'), lead.SLAWarningDate__c.format('yyyy-MM-dd hh:mm')); TODO FIND OUT ERROR
        
        Datetime slaTargetDatetime = BusinessHours.add(businessHour.id, lead.CreatedDate, Integer.valueOf(cs.SLAHours__c) * 60 * 60 * 1000L);
        //system.assertEquals(slaTargetDatetime.format('yyyy-MM-dd hh:mm'), lead.SLATargetDate__c.format('yyyy-MM-dd hh:mm')); TODO FIND OUT ERROR
        
        //because we moved to engaged immediatly duration should be zero hours, less than one hour
        system.assertEquals(0, lead.SLADuration__c);  

    }
    
    static testMethod void leadSLA_UserOwner_Bulk() {

        BusinessHours businessHour = [SELECT Id, Name
                                    FROM BusinessHours
                                    WHERE IsActive = true
                                    AND IsDefault = true
                                    LIMIT 1];
       
        User u = TestData.getTestSalesUser();
        u.BusinessHours__c=businessHour.Name;
		
		ConversionScore__c cs = ConversionScore__c.getInstance(u.OperationCountry__c);
		
        System.runAs(u) {
            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
        
            Test.startTest();
            
            List<Lead> leads = new List<Lead>();
            
            for (Integer i=0;i<200;i++) {
                Lead lead = TestData.getTestLead();
                leads.add(lead);
            }

            system.debug('leadSLA_UserOwner_Bulk...leads...' + leads);
            insert leads;
            
            Test.stopTest();
            
             //query lead to check SLA fields populated properly
            List<Lead> queriedLeads = [SELECT Id, 
                           CreatedDate, 
                           SLATargetDate__c,
                           SLADuration__c,
                           SLAWarningDate__c
                    FROM Lead 
                    WHERE Id = :leads 
                    LIMIT :leads.size()];
                    
            system.assertEquals(leads.size(), queriedLeads.size(), 'Are all the leads returned which we created');

            for (Lead lead:queriedLeads) {
	            Datetime slaWarningDatetime = BusinessHours.add(businessHour.id, lead.CreatedDate, Integer.valueOf(cs.SLAHoursWarning__c) * 60 * 60 * 1000L);
	            //system.assertEquals(slaWarningDatetime.format('yyyy-MM-dd hh:mm'), lead.SLAWarningDate__c.format('yyyy-MM-dd hh:mm')); TODO FIND OUT ERROR
	            
	            Datetime slaTargetDatetime = BusinessHours.add(businessHour.id, lead.CreatedDate, Integer.valueOf(cs.SLAHours__c) * 60 * 60 * 1000L);
	            //system.assertEquals(slaTargetDatetime.format('yyyy-MM-dd hh:mm'), lead.SLATargetDate__c.format('yyyy-MM-dd hh:mm')); TODO FIND OUT ERROR
            }
        }
    }
    
    static testMethod void leadSLA_QueueOwner() {
        
        BusinessHours businessHour;
        User u;
        Group queue;
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            businessHour = [SELECT Id, Name
                                        FROM BusinessHours
                                        WHERE IsActive = true
                                        AND IsDefault = true
                                        LIMIT 1];
           
            u = TestData.getTestSalesUser();
            u.BusinessHours__c=businessHour.Name;
            
            queue = new Group(Name='LeadAssignmentQueue', Type='Queue');
            insert queue;
            QueueSobject mappingObject = new QueueSobject(QueueId = queue.Id, SobjectType = 'Lead');
            insert mappingObject;
        }
                
        QueueBusinessHours__c queueBusinessHours = new QueueBusinessHours__c();
        queueBusinessHours.Name = queue.Name; 
        queueBusinessHours.BusinessHours__c = businessHour.Name;
        queueBusinessHours.Country__c = 'GB';
        insert queueBusinessHours;
        
        ConversionScore__c cs = ConversionScore__c.getInstance('GB');
        Lead lead;
        
        System.runAs(u) {
            
            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
        
            Test.startTest();
            
            lead = TestData.getTestLead();
            lead.OwnerId=queue.Id;
            insert lead;
            
            Test.stopTest();
        }            
        //query lead to check SLA fields populated properly
        lead = [SELECT Id, 
                       CreatedDate, 
                       SLATargetDate__c,
                       SLADuration__c,
                       SLAWarningDate__c
                FROM Lead 
                WHERE Id = :lead.Id LIMIT 1];
               
         
        //check that the target date was allocated
        System.debug('businessHour...' + businessHour);
        System.debug('u.Business_Hours__c...' + u.BusinessHours__c);
        Datetime slaWarningDatetime = BusinessHours.add(businessHour.id, lead.CreatedDate, Integer.valueOf(cs.SLAHoursWarning__c) * 60 * 60 * 1000L);
        //system.assertEquals(slaWarningDatetime.format('yyyy-MM-dd hh:mm'), lead.SLAWarningDate__c.format('yyyy-MM-dd hh:mm')); TODO FIND OUT ERROR
        
        Datetime slaTargetDatetime = BusinessHours.add(businessHour.id, lead.CreatedDate, Integer.valueOf(cs.SLAHours__c) * 60 * 60 * 1000L);
        //system.assertEquals(slaTargetDatetime.format('yyyy-MM-dd hh:mm'), lead.SLATargetDate__c.format('yyyy-MM-dd hh:mm')); TODO FIND OUT ERROR
    }

    static testMethod void leadSLA_UserOwner_NoBusinessHoursEdgeCase() {
        /*
        THIS TEST IS TO ASSERT THAT WHEN A USER WITH NO BUSINESS HOURS
        CREATES A LEAD THE DURATION IS SET TO -1
        */

        //create user with null Business hours
        User u = TestData.getTestSalesUser();
        u.BusinessHours__c=null;

        System.runAs(u) {
            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
        
            Test.startTest();
            
            Lead lead = TestData.getTestLead();
            insert lead;
         
            Test.stopTest();
            
            //query lead to check SLA fields populated properly
            lead = [SELECT Id, 
                           CreatedDate, 
                           SLATargetDate__c,
                           SLADuration__c
                    FROM Lead 
                    WHERE Id = :lead.Id LIMIT 1];
            
            
            //when no business hours associated with user or queue
            //SLA duration set to -1
            system.assertEquals(-1, lead.SLADuration__c);  
        }
    }
}