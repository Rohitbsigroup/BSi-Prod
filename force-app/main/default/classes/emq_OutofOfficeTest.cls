/**
*	Author		: Prasad JN
*	Description	: Custom APEX for project creation & prod cert product search
*/
@isTest
public with sharing class emq_OutofOfficeTest {
    
    static testMethod void testOutofOffice() {
    	Id id = UserInfo.getUserId();
    	User user = [SELECT Id, OutofOffice__c FROM User WHERE Id = :Id];
    	emq_OutofOffice outofOffice = new emq_OutofOffice(new ApexPages.StandardController(user));
    	
    	Test.startTest();
    	outofOffice.setOutofOffice();
    	user = [SELECT Id, OutofOffice__c FROM User WHERE Id = :Id];
    	System.assertEquals(true, user.OutofOffice__c);
    	
    	outofOffice.unsetOutofOffice();
    	user = [SELECT Id, OutofOffice__c FROM User WHERE Id = :Id];
    	System.assertEquals(false, user.OutofOffice__c);
    	Test.stopTest();
    }
}