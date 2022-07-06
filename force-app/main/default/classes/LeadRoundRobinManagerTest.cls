/*
*          RJ 01-06-2014 Updated to use getTestSalesUser
*/
@isTest
private class LeadRoundRobinManagerTest {

    static testMethod void createAndAssignLead() {
        /* 
        create assignment groups
        create lead with queue as owner and should be assigned automatically
        */
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        User u = TestData.getTestSalesUser();
        User leadOwner1;
        User leadOwner2;
        User leadOwner3;
        Group queue;
        
        QueueBusinessHours__c qb = new QueueBusinessHours__c();
        qb.Name = 'LeadAssignmentQueue';
        qb.BusinessHours__c = 'London';
        qb.Country__c = 'GB';
        insert qb;
        
        System.runAs ( thisUser ) {
            leadOwner1 = TestData.getTestSalesUser();
       		leadOwner2 = TestData.getTestSalesUser();
        	leadOwner3 = TestData.getTestSalesUser();
        	insert new List<User>{leadOwner1, leadOwner2, leadOwner3};
            
            queue = new Group(Name='LeadAssignmentQueue', Type='Queue');
            insert queue;
            QueueSobject mappingObject = new QueueSobject(QueueId = queue.Id, SobjectType = 'Lead');
            insert mappingObject;
        }
        
        Assignment_Group_Name__c ag = new Assignment_Group_Name__c();
        ag.Name='test1';
        ag.Type__c='Lead';
        insert ag;
        
        Assignment_Group_Queues__c agQueue = new Assignment_Group_Queues__c();
        agQueue.Assignment_Group_Name__c=ag.Id;
        agQueue.Name='LeadAssignmentQueue';
        agQueue.Active__c='True';
        insert agQueue;
        
        agQueue = [SELECT Id, Name, Active__c, QueueId__c
        		   FROM Assignment_Group_Queues__c
        		   WHERE Id = :agQueue.Id LIMIT 1];
        
        
        system.assertEquals(agQueue.QueueId__c, queue.Id, 'Queue should be set in trigger from name');
        
        //leadOwner1
        Assignment_Groups__c agAss1 = new Assignment_Groups__c();
        agAss1.Group_Name__c=ag.Id;
        agAss1.Active__c='True';
        agAss1.User__c=leadOwner1.Id;
        //leadOwner2
        Assignment_Groups__c agAss2 = new Assignment_Groups__c();
        agAss2.Group_Name__c=ag.Id;
        agAss2.Active__c='True';
        agAss2.User__c=leadOwner2.Id;
        //leadOwner3
        Assignment_Groups__c agAss3 = new Assignment_Groups__c();
        agAss3.Group_Name__c=ag.Id;
        agAss3.Active__c='True';
        agAss3.User__c=leadOwner3.Id;
		insert new List<Assignment_Groups__c>{agAss1, agAss2, agAss3};
		
        Test.startTest();
		
		List<Lead> leads = new List<Lead>();
		Lead lead1;
		Lead lead2;
		Lead lead3;
		Lead lead4;
        System.runAs(u) {
        	
        	lead1 = TestData.getTestLead();
            lead1.OwnerId=queue.Id;
            
            lead2 = TestData.getTestLead();
            lead2.OwnerId=queue.Id;
            
            lead3 = TestData.getTestLead();
            lead3.OwnerId=queue.Id;
            
            lead4 = TestData.getTestLead();
            lead4.OwnerId=queue.Id;
            lead4.TempOwnerId__c='SKIP';//wil not be assigned
            
            leads.add(lead1);
            leads.add(lead2);
            leads.add(lead3);
            leads.add(lead4);
            insert leads;
        	
        }
        
        Test.stopTest();
        
        leads = [SELECT Id, OwnerId
        		   FROM Lead
        		   WHERE Id IN :leads LIMIT :leads.size()];

        //ensure that the leads are distributed as expected
        //system.assertEquals(leads[0].OwnerId, leadOwner1.Id);
        //system.assertEquals(leads[1].OwnerId, leadOwner2.Id);
        //system.assertEquals(leads[2].OwnerId, leadOwner3.Id);
        //system.assertEquals(leads[3].OwnerId, queue.Id); //was skipped
    }
    
}