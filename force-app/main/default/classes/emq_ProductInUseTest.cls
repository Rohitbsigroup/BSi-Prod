/**
*	Author		: Prasad JN
*	Description	: Test Class for emq_ProductInUse
*/
@isTest(SeeAllData=true)
public with sharing class emq_ProductInUseTest {
	
    static testMethod void testDelete() {
    	Product2 product = [SELECT Id, Name FROM Product2 WHERE Part_in_Blue_Print__c = True LIMIT 1];
    	
    	Test.startTest();
    	try {
	        delete product;
    	} catch(Exception error) {
			System.assert(error.getMessage().contains('This part is in use by Blueprint configurator and cannot be deleted.'));
    	}
    	Test.stopTest();
    }
}