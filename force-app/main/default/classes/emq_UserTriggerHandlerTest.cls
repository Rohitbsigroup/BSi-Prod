/**
*
* Author 		: Prasad J N
* Date			: 22 May 2018 
* Description	: Apex test class to check c-code profile is created for new user
*
*/
@isTest
public with sharing class emq_UserTriggerHandlerTest {
    
    static testMethod void testAfterInsert() {
    	Profile profile = [SELECT id FROM profile WHERE name LIKE 'Standard User'];
		
		User user = new User(alias = 'SysAdmin', 
                      email='SysAdmin@bsigroup.com.sf', emailencodingkey='UTF-8', lastname='Administrator',firstname='System', 
                      languagelocalekey='en_US', localesidkey='en_GB', profileid = profile.Id,
                      timezonesidkey='Europe/London', username='SysAdmin@bsigroup.com.sf');
                      
    	Test.startTest();
    	insert user;
    	Test.stopTest();
    	
    	List<CCode_Profile__c> cCodeProfile = [SELECT Id FROM CCode_Profile__c WHERE User__c = :user.Id];
    	System.assertEquals(cCodeProfile.size(), 1);
	} 

	static testMethod void testBeforeUpdate(){
		User u = [SELECT Id, LanguageCustom__c, LanguageLocaleKey, Username FROM User WHERE Username =: 'test@test.com.username'];

		Test.startTest();
		u.LanguageCustom__c = 'fr';
		Database.update(u);
		Test.stopTest();

		User us = [SELECT Id, LanguageLocaleKey, LanguageCustom__c FROM User WHERE Id =:u.Id];
		//System.debug(us.LanguageLocaleKey);
		System.assertEquals(us.LanguageLocaleKey, us.LanguageCustom__c);

	}

	static testMethod void testBeforeInsert(){
		Contact c = [SELECT Id, Email, FirstName, LastName FROM Contact WHERE Email =: 'test2@test.com' LIMIT 1];

        User u = New User(
                    UserName = c.Email,
                    FirstName = c.FirstName,
                    LastName = c.LastName,
                    Alias = c.FirstName,
                    email = c.Email,
                    CommunityNickName = c.FirstName,
                    ProfileID = [Select Id from Profile where Name='BSI Delegate' LIMIT 1].id,
                    ContactId = c.Id,
                    //Mandatory fields - values to be set
                    TimeZoneSidKey = 'America/New_York', 
                    LocaleSidKey = 'en_US', 
                    EmailEncodingKey = 'UTF-8', 
					LanguageLocaleKey = 'en_US',
					Portal_User_Country__c = 'UK'
                );

		Test.startTest();
		Database.insert(u);
		Test.stopTest();

		User us = [SELECT Id, LanguageLocaleKey, LanguageCustom__c FROM User WHERE Id =:u.Id];
		//System.debug(us.LanguageLocaleKey);
		System.assertEquals(us.LanguageLocaleKey, 'en_US');
	}

	@TestSetup 
    private static void generateOrgData(){

        Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
		insert c;

		Contact c2 = new Contact(AccountId = a.Id, FirstName = 'test2', Phone = '07123436542', LastName = 'test2', Email = 'test2@test.com', MailingCountry = 'GB');
		insert c2;

		List<Contact> contacts = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
		
		List<User> users = TestData.createPortalUsers(contacts, true);
	
	}
		
	
}