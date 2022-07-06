@isTest
private class IRCAEnrolmentExtractTest {

    static testMethod void myUnitTest() {
 
    // Prepare data
    List<Enrollment__c> enrs = new List<Enrollment__c>();

    // Set up a venue
    Training_Venue__c ven = TrainingBookingTestData.createTestVenue();


    // Set up product
    Product2 prd = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);

    //Set up account
    //Account acc = bg_UnitTestHelper.CreateAccount();

    // Set up instrustor
    Contact trainer = bg_UnitTestHelper.CreateContact('Test instructor', null);
    //trainer.RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_CONTACT).get(bg_ContactUtils.RECORD_TYPE_NAME_INSTRUCTOR).Id;
    insert trainer;

    // Set up an event - JS added variables max seats =10 and BG created add instructor above
    Training_Event__c evt = TrainingBookingTestData.createTestEvent(prd, ven, 10, trainer.Id ); 
    
    // Set up an enrolment
    Enrollment__c enr = new Enrollment__c();
    enr.Training_Event__c = evt.Id;
    enr.Booking_status__c = 'Booked';
    enr.Accomodation__c = 'Non-Residential';
    enr.Invoice_status__c = 'Pending';
    insert enr;
    enrs.add(enr);

     // Start test
     Test.startTest();

    // Set the current page
    PageReference addPage = Page.IRCAEnrolmentExtract;
    Test.setCurrentPageReference(addPage);
       ApexPages.currentPage().getParameters().put('retUrl', '');

    // Create an instance of the standard controller and the controller extension
    ApexPages.StandardSetController stdCont = new ApexPages.standardSetController(enrs);
    IRCAEnrolmentExtractExt extCont = new IRCAEnrolmentExtractExt(stdCont);

    // Try without any enrolments selected
    extCont.create();

    // Try without a file name
        stdCont.setSelected(enrs);
        extCont = new IRCAEnrolmentExtractExt(stdCont);
        extCont.fileName = '';
    extCont.create();
    
    // Try with all required parameters
        stdCont.setSelected(enrs);
        extCont = new IRCAEnrolmentExtractExt(stdCont);
        extCont.fileName = 'TestFile.csv';
    extCont.create();

    // Test the output
    extCont.build();
  
     // Stop test
     Test.stopTest();   
    }
}