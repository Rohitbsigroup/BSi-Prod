/**
*
* Author        : Prasad J N
* Date          : 22 May 2018 
* Description   : Apex test class to Sandbox Activation
*
*/
@isTest
public with sharing class emq_SandboxActivationTest {
    
    @isTest
    static void testSandboxRefreshUpdates(){
        /*BPSettings__c blueprintSettings = new BPSettings__c();
        blueprintSettings.Blueprint_Server_Path__c = 'BSI_Focused';
        blueprintSettings.Blueprint_Server_Path_Legacy__c = 'BSI_Legacy';
        insert blueprintSettings;
        
        LitmosSettings__c litmosSettings = new LitmosSettings__c();
        litmosSettings.API__c = 'https://api.litmos.com/v1.svc/';
        litmosSettings.API_Key__c = '447c6d82-3a7b-4aa0-ac20-af2d9de67fd4';
        litmosSettings.Source__c= 'Some value'; 
        insert litmosSettings;
        
        SystemSetting__c systemSetting = SystemSetting__c.getOrgDefaults();
        systemSetting.ContentURL__c = 'https://bsi--test.cs87.my.salesforce.com/';
        systemSetting.ServerURL__c = 'https://bsi--test.cs87.my.salesforce.com/';
        systemSetting.Ingenico_Ogone_DIRECTLINK_URL__c = 'https://secure.ogone.com/ncol/test/orderdirect.asp';
        systemSetting.Ingenico_Ogone_ALIASGATEWAY_URL__c = 'https://secure.ogone.com/ncol/test/alias_gateway.asp';
        insert systemSetting;
        
        Profile profile = [SELECT id FROM profile WHERE name LIKE 'System Administrator'];
        
        User user = new User(alias = 'SysAdmin', 
                      email='SysAdmin@bsigroup.com.sf', emailencodingkey='UTF-8', lastname='Administrator',firstname='System', 
                      languagelocalekey='en_US', localesidkey='en_GB', profileid = profile.Id,
                      timezonesidkey='Europe/London', username='SysAdmin@bsigroup.com.sf');
        user.OperationCountry__c = 'US';
        insert user;
        
        Test.startTest();       
        System.runAs(user){
            Test.testSandboxPostCopyScript(new emq_SandboxActivation(), UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), 'SandboxTest');
        }
        Test.stopTest();
        
        BPSettings__c blueprintSettingsNew = BPSettings__c.getOrgDefaults();
        System.assertEquals(blueprintSettingsNew.Blueprint_Server_Path__c, 'BSI_SandboxTest_Focused');
        
        LitmosSettings__c litmosSettingsNew = LitmosSettings__c.getOrgDefaults();
        System.assertEquals(litmosSettingsNew.Source__c, 'bsisandboxSandboxTest');*/
    }
}