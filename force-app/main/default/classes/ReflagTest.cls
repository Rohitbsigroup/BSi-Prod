/********************************************************************
 * ReflagTest
 *
 * Unit test class for ContactReflag and LeadReflag Triggers
 *
 * Author: Nebula - Robert Bedding
 * Created: 08-08-2016 
 ********************************************************************/
@istest
public class ReflagTest {
    
    private static LeadSetting__c ls = LeadSetting__c.getInstance();
    
    @istest
    public static void contactCreateTest() {
        bg_CustomSettingsUtils.GetLeadSettings();
        TestObjectGenerator.getContactToLeadFields();
        Account testAccount = TestObjectGenerator.getAccount();
        
        Contact testContact = TestObjectGenerator.getContact();
        
        testContact.Create_Lead__c = true;
        testContact.Pardot_Trigger_Source_Sub_Category__c = 'Test';
        update testContact;
        List<Lead> compareLead = [SELECT Id, Create_Lead__c,Email, Company, LastName, Source_Sub_Category__c, LeadSource FROM Lead];
        system.assertEquals(1,compareLead.size());
        system.assertEquals(false,compareLead[0].Create_Lead__c);
        system.assertEquals(testContact.Email,compareLead[0].Email);
        system.assertEquals(testAccount.Name,compareLead[0].Company);
        system.assertEquals(testContact.LastName,compareLead[0].LastName);
        
        system.assertEquals(System.Label.Pardot_Lead_Source, compareLead[0].LeadSource);
        system.assertEquals(testContact.Pardot_Trigger_Source_Sub_Category__c, compareLead[0].Source_Sub_Category__c);
        
        testContact = [SELECT Id, Create_Lead__c FROM Contact WHERE Id = :testContact.Id];
        system.assertEquals(true,testContact.Create_Lead__c);
    }
    
    @istest
    public static void testContactSchedule() {
        TestObjectGenerator.getContactToLeadFields();
        Contact testCon = TestObjectGenerator.getContact();    
        testCon.Create_Lead__c = true;
        update testCon;
        
        test.startTest();
        
        ContactPardotSyncBatch CRON = new ContactPardotSyncBatch();
        Database.executeBatch(CRON, 200);
        test.stopTest();
        
        List<Lead> allLeads = [SELECT Id FROM Lead];
        system.assertEquals(1,allLeads.size());
        
        Contact comparedCon = [SELECT Id, Create_Lead__c FROM Contact WHERE Id = :testCon.id];
        
        system.assertEquals(comparedCon.Create_Lead__c, false);      
    }
    
    @istest
    public static void testLeadSchedule() {
        bg_UnitTestHelper.SetupCustomSettings();
        TestObjectGenerator.getContactToLeadFields();
        Lead testLead = bg_UnitTestHelper.GetLead('Lead1name');    
        testLead.Create_Lead__c = true;
        update testLead;
        
        test.startTest();
        Lead testLead2 = testLead.clone();
        insert testLead2;
        
        Lead comparedLead2 = [SELECT Id, Create_Lead__c FROM Lead WHERE Id = :testLead2.id];        
        system.assertEquals(comparedLead2.Create_Lead__c, false);  
        
        LeadPardotSyncBatch CRON = new LeadPardotSyncBatch();
        Database.executeBatch(CRON, 200);
        test.stopTest();
        
        List<Lead> allLeads = [SELECT Id FROM Lead];
        system.assertEquals(3, allLeads.size());
        
        Lead comparedLead = [SELECT Id, Create_Lead__c FROM Lead WHERE Id = :testLead.id];        
        system.assertEquals(comparedLead.Create_Lead__c, false);     
        
    }
    
    @istest
    public static void testSchedule() {
        
        test.startTest();   
        ContactPardotSyncSchedule CRON = new ContactPardotSyncSchedule();
        LeadPardotSyncSchedule CRON2 = new LeadPardotSyncSchedule();
        
        CRON.runSelf('test:');
        CRON2.runSelf('test:');
        
        test.stopTest();
    }
}