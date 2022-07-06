@isTest
public class CertificateControllerUniversalTest {

    @isTest
    static void enrollmentTest(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, Label.Enrollment_Booking_Status_Booked);
        e.Certificate_Language__c = 'English';
        update e;
        
        Test.setCurrentPage(Page.certificate);
        ApexPages.currentPage().getParameters().put('id', e.Id);
        
        CertificateControllerUniversal controller = new CertificateControllerUniversal();
        System.assertEquals(controller.id, e.Id);
    }
    
    @isTest
    static void qualificationTest(){
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
        
        Test.setCurrentPage(Page.certificate);
        ApexPages.currentPage().getParameters().put('id', pq.Id);
        
        CertificateControllerUniversal controller = new CertificateControllerUniversal();
        System.assertEquals(controller.id, pq.Id);
    }
}