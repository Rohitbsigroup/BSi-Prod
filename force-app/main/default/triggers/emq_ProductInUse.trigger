/**
*	Author		: Prasad JN
*	Description	: Check if Product is in use in BluePrint and show message product cannot be deleted
*/
trigger emq_ProductInUse on Product2 (before delete) {
    for(Product2 product: Trigger.old){
    	if(product.Part_in_Blue_Print__c)
    		product.addError('This part is in use by Blueprint configurator and cannot be deleted.');
    }
}