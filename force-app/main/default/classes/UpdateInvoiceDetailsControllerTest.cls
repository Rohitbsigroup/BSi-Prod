@isTest
public class UpdateInvoiceDetailsControllerTest {

    @isTest
    static void testController(){
        List<Enrollment__c> enrollmentList = new List<Enrollment__c>();
        UpdateInvoiceDetailsController controller = new UpdateInvoiceDetailsController(new ApexPages.StandardSetController(enrollmentList));
        System.assert(controller.dummyEnrollment != null);
    }
}