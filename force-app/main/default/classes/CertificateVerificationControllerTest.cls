@isTest
public class CertificateVerificationControllerTest {

    @isTest
    static void CertificateVerificationControllerTest(){
        String shareId = 'test';
        
        Test.setCurrentPage(Page.CertificateHolder);
        ApexPages.currentPage().getParameters().put('shareId', shareId);
        
        CertificateVerificationController controller = new CertificateVerificationController();
        System.assertNotEquals(controller.verifierScript, null);
    }
}