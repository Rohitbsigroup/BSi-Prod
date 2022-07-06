@isTest
public class TraceLabsAPITest {

    @isTest
    static void TraceLabsAPITest(){
        insert new TraceLabs_Settings__c(App_Id__c = 'test', API__c = 'test');
        
        TraceLabsAPI tAPI = new TraceLabsAPI();
        System.assert(tAPI.apiURL != null);
    }

    @isTest
    static void getHolderScriptTest(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');
        update new Contact(Id = e.Delegate_Name__c, Client_Learning_Portal_User_Id__c = UserInfo.getUserId());

        Training_Event__c event = [SELECT Course__c FROM Training_Event__c WHERE Id = :e.Training_Event__c];
        event.Mimeo_Distribution_Id__c = 'test';
        update event;

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;
        
        TraceLabsAPI tAPI = new TraceLabsAPI();
        TraceLabsAPI.HolderResponse hr = tAPI.getHolderScript(UserInfo.getUserId(), UserInfo.getUserId(), e.Id);
        System.debug(hr);
    }
    
    @isTest
    static void getVerifierScriptTest(){
        String shareId = 'test';
        
        TraceLabsAPI tAPI = new TraceLabsAPI();
        TraceLabsAPI.VerifierResponse vr = tAPI.getVerifierScript(shareId);
        System.debug(vr);
    }
    
    @isTest
    static void uploadEnrollmentCertificatesTest(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');

        Training_Event__c event = [SELECT Course__c FROM Training_Event__c WHERE Id = :e.Training_Event__c];
        event.Mimeo_Distribution_Id__c = 'test';
        update event;

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;
        
        Training_Translations__c tt = [SELECT Id FROM Training_Translations__c LIMIT 1];
        
        Test.startTest();
            TraceLabsAPI tAPI = new TraceLabsAPI();
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'China (Chinese)');
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'Germany (Deutsch)');
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'Hong Kong (English)');
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'Japan (Japanese)');
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'Korea (Korean)');
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'Singapore (English)');
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'Taiwan (Chinese)');
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'Turkey (Türkçe)');
            tAPI.uploadEnrollmentCertificates(new List<Id>{e.Id});
        Test.stopTest();
    }
    
    @isTest
    static void uploadQualificationCertificates(){
        Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;
        
        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;
        
        List<Contact> contactList = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        List<User> userList = TestData.createPortalUsers(contactList, true);
        
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        Training_Translations__c tt = TestDataUtility.insertTrainingTranslation();

        Master_Qualification__c mq = new Master_Qualification__c(
            Name = 'ISO 9001 Internal Auditor Practitioner',
            Taxonomy__c = 'QMS58009ENGX', 
            Product__c = 'ISO 9001'
        );
        insert mq;

        Qualification__c q = new Qualification__c(
            Name = 'UK - ISO 9001 Internal Auditor Practitioner', 
            Master_Qualification__c = mq.Id, 
            RecordTypeId = '0124G000000KNfBQAW',
            Status__c = 'Active'
        );
        insert q;

        Personal_Qualification__c pq = new Personal_Qualification__c(
            Certificate_Language__c = 'English',
            Delegate__c = contactDelegate.Id,
            Qualification__c = q.Id,
            Show_Transcript_in_Portal__c = true, 
            Show_Certificate_in_Portal__c = true, 
            Show_Logo_in_Portal__c = true, 
            Training_Translations__c = tt.Id
        );
        insert pq;
        
        Test.startTest();
            TraceLabsAPI tAPI = new TraceLabsAPI();
            tAPI.uploadQualificationCertificates(new List<Id>{pq.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'China (Chinese)');
            tAPI.uploadQualificationCertificates(new List<Id>{pq.Id});
        
            update new Training_Translations__c(Id = tt.Id, Name = 'Germany (Deutsch)');
            tAPI.uploadQualificationCertificates(new List<Id>{pq.Id});
            
            update new Training_Translations__c(Id = tt.Id, Name = 'Japan (Japanese)');
            tAPI.uploadQualificationCertificates(new List<Id>{pq.Id});
            
            update new Training_Translations__c(Id = tt.Id, Name = 'Hong Kong (English)');
            tAPI.uploadQualificationCertificates(new List<Id>{pq.Id});

            update new Training_Translations__c(Id = tt.Id, Name = 'Singapore (English)');
            tAPI.uploadQualificationCertificates(new List<Id>{pq.Id});
            
            update new Training_Translations__c(Id = tt.Id, Name = 'Taiwan (Chinese)');
            tAPI.uploadQualificationCertificates(new List<Id>{pq.Id});
        Test.stopTest();
    }
    
    
}