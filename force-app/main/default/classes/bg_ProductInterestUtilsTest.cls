/********************************************************************
 * bg_ProductInterestUtilsTest
 *
 * Test class for bg_ProductInterestUtils
 *
 * 
 * Author: Richard Jimenez
 * Created: 11-11-2014 
 ********************************************************************/
@isTest
private class bg_ProductInterestUtilsTest {

    private static testMethod void testGetSuggestedProductClassificationRelationships() {

        BSIPermissions__c cs = BSIPermissions__c.getInstance(UserInfo.getUserId());
        if(cs == null) {        		
	        cs = new BSIPermissions__c();
        }
        cs.CanEditSuggestedProductsEMEA__c = true;
        cs.CanEditSuggestedProductsGLOBAL__c = true;
        upsert cs;
        
		// Create Product Classifications
		Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductA', 'StreamA', 'PortfolioA','ProductAreaA');
		Product_Classification__c pcB = bg_UnitTestHelper.GetProductClassification2('UT-ProductB', 'StreamB', 'PortfolioB','ProductAreaB');
		Product_Classification__c pcC = bg_UnitTestHelper.GetProductClassification2('UT-ProductC', 'StreamC', 'PortfolioC','ProductAreaC');

		// Create Product Classification Relationships
		Product_Classification_Relationship__c pcr1 = new Product_Classification_Relationship__c();
		pcr1.ProductClassification__c = pcA.Id;
		pcr1.SuggestedProductClassification__c = pcC.Id;
		pcr1.Region__c = 'GLOBAL';
		insert pcr1; 	

		Product_Classification_Relationship__c pcr2 = new Product_Classification_Relationship__c();
		pcr2.ProductClassification__c = pcA.Id;
		pcr2.SuggestedProductClassification__c = pcC.Id;
		pcr2.Country__c = 'US;GB';
		pcr2.Sector__c = 'Aerospace;Electronics';
		pcr2.CompanySizeMin__c = 100;
		pcr2.CompanySizeMax__c = 500;
		pcr2.BSIReadiness__c = 'Year 1';
		pcr2.Region__c = 'EMEA';
		insert pcr2;
    	
    	list<Product_Classification_Relationship__c> results;

    	test.startTest();
	    	list<string> pcNames = new list<string>{pcA.Product__c, pcB.Product__c};
	    	results = bg_ProductInterestUtils.GetSuggestedProductClassificationRelationships(pcNames);
			system.assertEquals(1, results.size());
	
	    	results = bg_ProductInterestUtils.GetSuggestedProductClassificationRelationships(pcNames, 'US', 100, 'Aerospace', 'Year 1', '');
			system.assertEquals(1, results.size());

	    	results = bg_ProductInterestUtils.GetSuggestedProductClassificationRelationships(pcNames, new set<string>{'US'}, 100, new set<string>{'Aerospace'}, new set<string>{'Year 1'}, new set<string>{''});
			system.assertEquals(1, results.size());

	    	results = bg_ProductInterestUtils.GetSuggestedProductClassificationRelationships(pcNames, new set<string>{'GB'}, 100, new set<string>{'Aerospace'}, new set<string>{'Year 1'}, new set<string>{''});
			system.assertEquals(1, results.size());

	    	results = bg_ProductInterestUtils.GetSuggestedProductClassificationRelationships(pcNames, new set<string>{'FR'}, 100, new set<string>{'Aerospace'}, new set<string>{'Year 1'}, new set<string>{''});
			system.assertEquals(1, results.size());
		test.stopTest();
    }
}