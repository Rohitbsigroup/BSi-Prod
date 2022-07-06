/********************************************************************
 * EchosignTrigger
 *
 * Trigger to update the related quote when an Echosign Agreement is signed.
 * 
 * Author: Richard Jimenez
 * Created: 13-12-2013
 * Changes: 
 ********************************************************************/
trigger EchosignTrigger on echosign_dev1__SIGN_Agreement__c (before update) {
	
	// Update Quote / Opportunity with agreement status
	bg_DocumentUtils.UpdateQuoteAgreementStatus(trigger.new, trigger.oldMap);
}