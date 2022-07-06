@IsTest
public class PortalAccessControllerTest {
    
    @IsTest public static void testLoginSuccessful() {
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');
        String profileId = [SELECT Id FROM Profile WHERE Name = :Label.BSIUserSettings_ProfileNameDelegate LIMIT 1].Id;
        User newUser = TestDataUtility.createCommunityUser(true,'test12512351235@test.com','test236234624361@te234st.com',
                profileId,e.Delegate_Name__c);
        System.setPassword(newUser.Id, 'Test12345!2');

        Test.startTest();
        PortalAccessController.LoginResultDTO result = PortalAccessController.login('test12512351235@test.com', 'Test12345!2');
        Test.stopTest();

        System.assert(result.isSuccess);
        System.assertEquals('https://test.url.com',result.returnUrl);
        System.assert(String.isBlank(result.errorMessage));
    }
    
    @IsTest public static void testLoginFail() {
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');
        String profileId = [SELECT Id FROM Profile WHERE Name = :Label.BSIUserSettings_ProfileNameDelegate LIMIT 1].Id;
        User newUser = TestDataUtility.createCommunityUser(true,'test12512351235@test.com','test236234624361@te234st.com',
                profileId,e.Delegate_Name__c);
        System.setPassword(newUser.Id, 'Test12345!2');

        Test.startTest();
        PortalAccessController.LoginResultDTO result = PortalAccessController.login(null, null);
        Test.stopTest();

        System.assert(!result.isSuccess);
        System.assertEquals('',result.returnUrl);
        System.assert(!String.isBlank(result.errorMessage));
    }
}