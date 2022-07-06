/********************************************************************
* ActivateBatchesTest
*
* Unit test class for ActivateBatchesController
*
* Author: Nebula - Robert Bedding
* Created: 08-08-2016 
********************************************************************/
@istest 
public class ActivateBatchesTest {
    
    /* This Test relys on the shedule batches not being activated already otherwise it would throw an error on the first pass*/
    
    @istest(SeeAllData=true)
    public static void activateTest() { 
        PageReference pageRef = Page.ActivateLeadAndContactReflagBatches;
        Test.setCurrentPage(pageRef);
        
        ActivateBatchesController controller = new ActivateBatchesController();        
        controller.activateBatches();
        controller.activateBatches();
        List<AsyncApexJob> aaj = [SELECT Id, MethodName FROM AsyncApexJob WHERE JobType = 'ScheduledApex' ];
        system.debug('aaj'+aaj);
        // System.assertEquals(1, ApexPages.getMessages().size());
    }    
}