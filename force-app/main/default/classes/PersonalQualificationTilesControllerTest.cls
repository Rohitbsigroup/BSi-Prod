/**
 * @Name:        PersonalQualificationTilesControllerTest
 * @Description: This class handles the test for the PersonalQualificationTilesController class
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 20/04/2020   Andrei Budescu     Created Class
 */

@IsTest
public class PersonalQualificationTilesControllerTest {

    //Wrapper class for the list of tiles returned
    public class Tile{
        String title;
        String description;
        String url;
        String logoUrl;

        public Tile(String title, String description, String url, String logoUrl){
            this.title = title;
            this.description = description;
            this.url = url;
            this.logoUrl = logoUrl;
        }

    }

    /**
	 * Scenario: An User access a personal qualification and wants to see a list of tiles on the record
	 * Expected Outcome: List of tiles displayed
	 */
    public static testMethod void getPersonalQualificationTilesTest() {

        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        //create master qualification
        Master_Qualification__c masterQualification = new Master_Qualification__c(Name = 'ISO 9001 Internal Auditor Practitioner',
            Taxonomy__c = 'QMS58009ENGX', Product__c = 'ISO 9001', Certificate_Logo__c = 'ISO9001InternalAuditorPractitioner.jpg');
        insert masterQualification;

        //create qualification and link it to the master qualification record
        Qualification__c qualification = new Qualification__c(Name = 'UK - ISO 9001 Internal Auditor Practitioner', 
            Master_Qualification__c =masterQualification.Id, Status__c = 'Active', RecordTypeId = '0124G000000KNfBQAW');
        insert qualification;

        //create personal qualification and link it to the qualification record
        Personal_Qualification__c personalQualification = new Personal_Qualification__c(Qualification__c = qualification.Id,
            Show_Transcript_in_Portal__c = true, Show_Certificate_in_Portal__c = true, Show_Logo_in_Portal__c = true, Delegate__c = contactDelegate.Id);
        insert personalQualification;


        List<Tile> personalQualificationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = PersonalQualificationTilesController.getPersonalQualificationTiles(personalQualification.Id);
            personalQualificationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        StaticResource sr = [SELECT Id,NamespacePrefix,SystemModstamp FROM StaticResource WHERE Name = 'TrainingCertificateQualLogos' LIMIT 1];
        String srPath = '/resource/' + sr.SystemModstamp.getTime() + '/' + 'TrainingCertificateQualLogos/' + personalQualification.Qualification__r.Master_Qualification__r.Certificate_Logo__c; 
        PageReference pg = new PageReference( srPath );

        String logoNameTest = '';
        for(Tile tile : personalQualificationTiles){
            if(tile.title == Label.CLP_PersonalQualification_DownloadLogo){
                logoNameTest = tile.logoUrl;
            }
        }
        System.assertEquals('ISO9001InternalAuditorPractitioner.jpg', logoNameTest);

        System.assertEquals(3, personalQualificationTiles.size());
        
    }

    public static testMethod void getUrlSubstringExceptionTest() {

        Test.startTest();
        PersonalQualificationTilesController.getUrlSubstring(null);
        Test.stopTest();

    }

    @TestSetup 
    private static void generateOrgData(){

        Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
		insert c;

		Contact c2 = new Contact(AccountId = a.Id, FirstName = 'test2', Phone = '07123436542', LastName = 'test2', Email = 'test2@test.com', MailingCountry = 'GB');
		insert c2;

		List<Contact> contacts1 = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
		
        List<User> users = TestData.createPortalUsers(contacts1, true);
        
        List<Contact> contacts2 = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test2@test.com' LIMIT 1];

        List<User> users2 = TestData.createPortalUsersTutors(contacts2, true);
	
	}


}