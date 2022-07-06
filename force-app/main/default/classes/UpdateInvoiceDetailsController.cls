public with sharing class UpdateInvoiceDetailsController {

    public Enrollment__c dummyEnrollment {get;set;}

    public UpdateInvoiceDetailsController(ApexPages.StandardSetController stdController){
        dummyEnrollment = new Enrollment__c();
    }
}