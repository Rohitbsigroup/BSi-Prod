/**
*	Author		: Prasad JN
*	Description	: Test Class for Fulfillment Status Trigger
*/
@isTest(SeeAllData=true)
public with sharing class emq_ProjectControllerTest {
    static testMethod void testSaveProject() {
    	Project__c project = new Project__c();
    	project.Project_Family__c = 'Professional Services';
    	project.Area_of_Practice__c = 'CSIR';
    	project.Project_Name__c = 'Test';
    	project.Project_Template__c = 'Generic';
    	
    	Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Project__c.getRecordTypeInfosByName();
		ApexPages.currentPage().getParameters().put('RecordType', recordTypes.get('Customized Audits').getRecordTypeId());	
    	
    	Test.startTest();
    	emq_ProjectController controller = new emq_ProjectController(new ApexPages.StandardController(project));
    	controller.project = project;
    	controller.save();
    	
    	project = [SELECT Project_Name__c, Project_Template__c FROM Project__c WHERE Id= :project.Id];
    	
    	System.assertEquals('Test', project.Project_Name__c);
    	System.assertEquals('Generic', project.Project_Template__c);
    	Test.stopTest();
    }
}