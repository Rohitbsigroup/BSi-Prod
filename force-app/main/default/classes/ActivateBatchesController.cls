/********************************************************************
* ActivateBatchesController
*
* Controller class for ActivateLeadAndContactReflagBatches VF page
*
* Test Class : ActivateBatchesControllerTEST
*
* 
* Author: Nebula - Robert Bedding
* Created: 08-08-2016 
********************************************************************/
public class ActivateBatchesController {
    
    public PageReference activateBatches(){   
        try {	
            ContactPardotSyncSchedule cpss = new ContactPardotSyncSchedule();
            LeadPardotSyncSchedule lpss = new LeadPardotSyncSchedule();
            cpss.runself('Run -');
            /* If the batch has not already been run then there will be no errors when running this*/
            lpss.runself('Run -'); 
        } catch (Exception ex) {
            /*Intentional fall through because there will 
               be an instance of schedule batch running if it fails*/
        }
        
        PageReference pageRef = new PageReference('/home/home.jsp');
        pageRef.setRedirect(true);     
        return pageRef;  
    } 
    
}