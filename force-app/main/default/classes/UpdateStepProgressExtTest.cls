@isTest
public class UpdateStepProgressExtTest {
     static testMethod void UpdateStepProgressExtTestMethod() 
     {
         Personal_Qualification__c pq = TestDataUtility.insertPersonalQualificationWithDependancies();
		 Master_Qualification__c mq = [select id from Master_Qualification__c limit 1];
         List<Step_Progress__c> stepProgressList = new List<Step_Progress__c>();
		 
		 Steps__c step = new Steps__c();
		 step.Name__c = 'Technical Documentation for MDR Exam';
		 step.Format__c	= 'Exam';
		 insert step;
		 
		 Qualification_Step__c qs = new Qualification_Step__c();
		 qs.Master_Qualification__c = mq.id;
		 qs.Step__c = step.id;
		 qs.Order__c = 10;
		 insert qs;
		 
         Step_Progress__c stepProgress1 = new Step_Progress__c();
         stepProgress1.Personal_Qualification__c = pq.id;
         stepProgress1.Order__c = 2;
         stepProgress1.Completed__c = false;
         stepProgress1.Progress__c = 'Complete';
		 stepProgress1.Qualification_Step__c = qs.id;
         stepProgressList.add(stepProgress1);
         Step_Progress__c stepProgress2 = new Step_Progress__c();
         stepProgress2.Personal_Qualification__c = pq.id;
         stepProgress2.Order__c = 1;
         stepProgress2.Completed__c = false;
         stepProgress2.Progress__c = 'Not Complete';
		 stepProgress2.Qualification_Step__c = qs.id;
         stepProgressList.add(stepProgress2);
         insert stepProgressList;
		 
         PageReference testPage = Page.UpdateStepProgress; 
         Test.setCurrentPage(testPage);     
         ApexPages.StandardSetController sc = new  ApexPages.StandardSetController(stepProgressList); 
		 sc.setSelected(stepProgressList);		 
         UpdateStepProgressExt ext = new UpdateStepProgressExt(sc);          
         PageReference pg = ext.save();
         ext.quicksave();
		 system.assert(pg != null,'Pagereference should not be null');
     }
}