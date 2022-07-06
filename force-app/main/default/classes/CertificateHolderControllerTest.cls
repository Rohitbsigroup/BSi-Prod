@isTest
public class CertificateHolderControllerTest {

    @isTest
    static void CertificateHolderControllerTest_Enrollment(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');
        update new Contact(Id = e.Delegate_Name__c, Client_Learning_Portal_User_Id__c = UserInfo.getUserId());
        
        Test.setCurrentPage(Page.CertificateHolder);
        
        //no params
        CertificateHolderController controller = new CertificateHolderController();
        
        //certificate not shared
        ApexPages.currentPage().getParameters().put('eId', e.Id);
        ApexPages.currentPage().getParameters().put('uId', UserInfo.getUserId());
        controller = new CertificateHolderController();
        System.assertEquals(controller.holderScript, null);
        
        //certificate shared
        e.Share_Certificate__c = true;
        update e;

        controller = new CertificateHolderController();
        System.assertNotEquals(controller.holderScript, null);
    }
    
    @isTest
    static void CertificateHolderControllerTest_Qualification(){
        Personal_Qualification__c pq = TestDataUtility.insertPersonalQualificationWithDependancies();
        update new Contact(Id = pq.Delegate__c, Client_Learning_Portal_User_Id__c = UserInfo.getUserId());
                
        Test.setCurrentPage(Page.CertificateHolder);
        
        //no params
        CertificateHolderController controller = new CertificateHolderController();
              
        //certificate not shared
        ApexPages.currentPage().getParameters().put('eId', pq.Id);
        ApexPages.currentPage().getParameters().put('uId', UserInfo.getUserId());
        controller = new CertificateHolderController();
        System.assertEquals(controller.holderScript, null);
        
        //certificate shared
        pq.Share_Certificate__c = true;
        update pq;

        controller = new CertificateHolderController();
        System.assertNotEquals(controller.holderScript, null);
    }
}