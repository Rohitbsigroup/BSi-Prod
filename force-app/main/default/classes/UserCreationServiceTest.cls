@isTest
public with sharing class UserCreationServiceTest {

    @isTest
    static void createUsersFromEnrollmentsTest_createNewUser(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');
        Set<Id> contactIds = new Set<Id>{e.Delegate_Name__c};
        
        //no existing Users
        List<User> userList = [SELECT Id FROM User WHERE ContactId IN :contactIds];
        System.assert(userList.isEmpty());
        
        Test.startTest();
            UserCreationService.createUsersFromEnrollments(contactIds);
        Test.stopTest();
        
        //new User created
        //userList = [SELECT Id FROM User WHERE ContactId IN :contactIds];
        //System.assert(!userList.isEmpty());
    }
    
    @isTest
    static void createUsersFromEnrollmentsTest_existingUser(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');
        Set<Id> contactIds = new Set<Id>{e.Delegate_Name__c};
        
        String profileId = [SELECT Id FROM Profile WHERE Name = :Label.BSIUserSettings_ProfileNameDelegate LIMIT 1].Id;
        User newUser = new User(
            UserName = 'test@test.com',
            FirstName = 'FirstName',
            LastName = 'LastName',
            Alias = 'FL',
            email = 'test@test.com',
            ProfileID = profileId,
            ContactId = e.Delegate_Name__c,
            LanguageLocaleKey = 'en_GB',
            LocaleSidKey = 'en_GB',
            TimeZoneSidKey = 'Europe/London',
            EmailEncodingKey = Label.BSIUserSettings_EmailEncodingKey,
            BluePrint_Language__c = Label.BSIUserSettings_BluePrintLanguage,
            SalesType__c = Label.BSIUserSettings_SalesType,
            Portal_User_Country__c = 'UK',
            CostCentre__c = 'CLP-DEL',
            BusinessHours__c = 'Default'
        );
        insert newUser;
        
        Test.startTest();
            UserCreationService.createUsersFromEnrollments(contactIds);
        Test.stopTest();
        
        e = [SELECT Portal_Access__c FROM Enrollment__c WHERE Id = :e.Id];
        System.assertEquals(e.Portal_Access__c, 'Existing User');
    }
}