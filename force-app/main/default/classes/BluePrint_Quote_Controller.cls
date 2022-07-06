/********************************************************************
 * BluePrint_Quote_Controller
 *
 * Visualforce Controller used to set parameters when logging into 
 * BluePrint
 *
 * Author: James Thornton
 * Created: 15-11-2016
 * Changes: 
 ********************************************************************/
public class BluePrint_Quote_Controller 
{
    @TestVisible private Id quoteId;
    private User user;

    public BluePrint_Quote_Controller() 
    {
        quoteId = ApexPages.currentPage().getParameters().get('qid');
    }

    public String getBluePrintLanguage() 
    {
        String quoteLanguage = null;
        if (!String.isBlank(quoteId))
        {
            Quote__c quote = [SELECT quoteLanguage__c FROM Quote__c WHERE id = :quoteId];
            // if quote does not have a language set, use the users language
            if (String.isBlank(quote.quoteLanguage__c))
            {
                quoteLanguage = bg_UserUtils.GetUserById(UserInfo.getUserId()).bluePrint_Language__c;        
            }
            else
            {
                quoteLanguage = quote.quoteLanguage__c;
            }
        }
        return quoteLanguage;
    }
}