/********************************************************************
 * bg_OpportunityCloneController
 * 
 * Author:       Kieran Maguire
 * Company:      BrightGen
 * Date:         11/11/2014
 * Description:  Controller to clone the opportunity with sites, attachments and the master quote     
 * Changes:    
 * 12/11/2014   KM  Clone opportunity attachments method
 ********************************************************************/
public class bg_OpportunityCloneController {
	private Id oldOppId;
    private Id newOppId;
	
	public Boolean hasErrors {get;set;}
    public static final String URL_PARAMETER_OPP_ID = 'Id';
    public static final String URL_PARAMETER_CLONED_FROM_OPP_ID = 'ClonedFromId';
     
    public bg_OpportunityCloneController(ApexPages.StandardController controller) {
        /*
            Gets the old and new opportunity id from the URL and sets them as globals
        */
        hasErrors = false;
        oldOppId = Apexpages.currentPage().getParameters().get(URL_PARAMETER_CLONED_FROM_OPP_ID);
        newOppId = Apexpages.currentPage().getParameters().get(URL_PARAMETER_OPP_ID);
    }
    
    public Pagereference ConfiguratorClone() {
        /*
            Clones the related lists from the old opportunity to the new opportunity
            Returns a configurator clone that returns to the new opportunity - (dev just returns to the new opportunity)
            On error, sets hasErrors to true and returns null
        */
        bg_OpportunityUtils.OpportunityCloneResult result;
        PageReference returnRef;
        try{
        	String returnString;
        	result = bg_OpportunityUtils.CloneRelatedObjects(oldOppId, newOppId, true, true, true, true);     
            //If clone related object doesn't clone a quote then return the new opp, otherwise run a configurator clone
            if(result.clonedQuoteId == null || result.oldQuoteId == null){
                returnString = '/' + newOppId;
            }else{
                //BuildConfigureQuoteProductURL(string quoteId, string productId, string cloneQuoteId, string retUrl)
                returnString = bg_BluePrintUtils.BuildConfigureQuoteProductURL(result.oldQuoteId, null, result.clonedQuoteId, result.clonedOpportunityId);
            }
            returnRef = new PageReference(returnString);
        }catch(Exception e){
        	hasErrors = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
        }
        return returnRef;
    }
}