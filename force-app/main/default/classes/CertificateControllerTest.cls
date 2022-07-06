/**
* Author:       Pawel Chrzanowski (K2)
* Date:         10/09/2018
* Description:  test class for CertificateController
*
* ******************* Change Log *******************
**/

@isTest
public class CertificateControllerTest {

    @isTest
    static void certificateTest_postitive(){
        Enrollment__c e = new Enrollment__c();
        ApexPages.currentPage().getParameters().put('bg', '0');
        CertificateController controller = new CertificateController(new ApexPages.StandardController(e));
        System.assert(!controller.showBg);

        controller.renderedFileName = 'fileNameTest';
        controller.saveToPdf();
        System.assertEquals('application/pdf#fileNameTest', controller.renderedContentType);
    }
    
    @isTest
    static void certificateTest_negative(){
        Enrollment__c e = new Enrollment__c();
        ApexPages.currentPage().getParameters().put('bg', '1');
        CertificateController controller = new CertificateController(new ApexPages.StandardController(e));
        
        System.assert(controller.showBg);
    }
}