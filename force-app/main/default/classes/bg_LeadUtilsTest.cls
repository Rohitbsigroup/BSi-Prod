/********************************************************************
 * bg_LeadUtilsTest
 *
 * Test methods for Lead Utility class
 * 
 * 
 * Author: Rob Earey
 * Created: 24-09-2013
 * Changes: 
 ********************************************************************/
@isTest 
private class bg_LeadUtilsTest  {

	private static testMethod void testleadSubsourceMap1()  {
		/*
			Testing Lead subsource retrieval
		*/
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) {
			Lead leadt1 = bg_UnitTestHelper.GetLead('Lead1name');
			leadt1.Source_Sub_Category__c = 'BSI Employee';
			leadt1.Description = 'Desctest1';
			leadt1.Merged_Lead_Owners__c = 'testingUser1';
			update leadt1;
			Lead leadt2 = bg_UnitTestHelper.GetLead('Lead2name');
			leadt2.Source_Sub_Category__c = 'BPM Lead';
			leadt2.Merged_Lead_Source__c = 'External';
			leadt2.Description = 'Desctest2';
			leadt2.Merged_Source_Sub_category__c = 'Client Manager';
			leadt2.Merged_Lead_Owners__c = 'testingUser2';
			leadt2.Original_Lead_Create_Date__c = date.today();
			update leadt2;
			// Merge leads
			merge leadt1 leadt2;
			Lead leadCheck = [SELECT Id, Name, LeadSource, Source_Sub_Category__c, Merged_Lead_Source__c, Merged_Source_Sub_category__c 
							  FROM Lead 
						      WHERE Id = :leadt1.Id];

			String expectedLeadSource = leadt2.Merged_Lead_Source__c + ';' + leadt1.LeadSource;
			String expectedSourceSubCategory = leadt2.Source_Sub_Category__c + ';' + leadt2.Merged_Source_Sub_category__c;

			System.assertEquals(expectedLeadSource,leadCheck.Merged_Lead_Source__c);			 
			System.assertEquals(expectedSourceSubCategory,leadCheck.Merged_Source_Sub_category__c);
		}
	}  
	
	private static testMethod void testLeadSubsourceMap2() {
		/*
			Testing Lead subsource retrieval
		*/
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) {
			Lead leadt1 = bg_UnitTestHelper.GetLead();
			leadt1.Source_Sub_Category__c = 'BSI Employee';
			leadt1.Description = 'Desctest1A';
			leadt1.Merged_Lead_Source__c = 'Marketing Channels';
			leadt1.Merged_Source_Sub_category__c = 'BSI Employee';
			leadt1.Original_Lead_Create_Date__c = date.today()-5;
			update leadt1;
			Lead leadt2 = bg_UnitTestHelper.GetLead();
			leadt2.Source_Sub_Category__c = 'BPM Lead';
			leadt2.Merged_Lead_Source__c = 'Self Generated';
			leadt2.Description = 'Desctest2A';
			leadt2.Merged_Source_Sub_category__c = 'Client Manager';
			leadt2.Merged_Lead_Owners__c = 'testingUser1';
			leadt2.Original_Lead_Create_Date__c = date.today();
			update leadt2;
			// Merge leads
			test.startTest();
				merge leadt1 leadt2;
			test.stopTest();
			Lead leadCheck = [SELECT Id, Name, LeadSource, Source_Sub_Category__c, Merged_Lead_Source__c, Merged_Source_Sub_category__c,
							  	Description 
							  FROM Lead 
						      WHERE Id = :leadt1.Id];				      		 
			System.assertEquals('Desctest1A',leadCheck.Description);
		}			
	}
	
	private static testMethod void testSaveLead() {
		/*
			Testing Save Lead
		*/
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) {
		 	test.startTest();
	 		 	Lead newLead1 = bg_UnitTestHelper.CreateLead('UT-Lead');
		 		bg_LeadUtils.SaveLead(newLead1);
		 		system.assertNotEquals(null, newLead1.Id);
	 		 	Lead newLead2 = bg_UnitTestHelper.CreateLead('UT-Lead');
		 		bg_LeadUtils.SaveLeads(new list<Lead>{newLead2});
		 		system.assertNotEquals(null, newLead2.Id);
		 	test.stopTest();
		}
	}

/*
	Test Get Existing Customer Services
*/
/*
	// 01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI
	private static testMethod void testGetExistingCustomerServices() {

		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) {
			// Create Lead
			Lead newLead1 = bg_UnitTestHelper.GetLead('UT-Lead');

			// Create ExistingCustomerServices
			list<ExistingCustomerServices__c> insECS = new list<ExistingCustomerServices__c>(); 
			insECS.add(GetExistingCustomerService(newLead1.Id, 'UT-ExistingCertStandard1', 'UT-CertifyingOrganisation1'));
			insECS.add(GetExistingCustomerService(newLead1.Id, 'UT-ExistingCertStandard2', 'UT-CertifyingOrganisation2'));
			insert insECS;

			test.startTest();
				list<ExistingCustomerServices__c> ecsList = bg_LeadUtils.GetExistingCustomerServices(newLead1.Id);		
				system.assertEquals(2, ecsList.size());
			test.stopTest();
		}				
	}
*/


	/*
		return existing customer service instance
	*/
/*
	// 01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI
	private static ExistingCustomerServices__c GetExistingCustomerService(Id recordId, string existingCertStandard, string certifyingOrganisations) 
	{
		ExistingCustomerServices__c ecs = new ExistingCustomerServices__c();
		if(recordId.getSObjectType().getDescribe().getName() == 'Lead') {
			ecs.Lead__c = recordId;
		} else if(recordId.getSObjectType().getDescribe().getName() == 'Account') {
			ecs.Account__c = recordId;
		}
		ecs.ExistingCertStandard__c = existingCertStandard;
		ecs.CertifyingOrganisations__c = certifyingOrganisations;
		ecs.ExistingRegistrationExpiryDate__c = date.today();
		return ecs;
	}
*/	

	/*
		Test Transfer Existing Customer Service To Account
	*/
/*
	// 01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI
	private static testMethod void testTransferExistingCustomerServiceToAccount() 
	{
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) {
			// Create Lead
			Lead newLead1 = bg_UnitTestHelper.GetLead('UT-Lead');

			// Create ExistingCustomerServices
			list<ExistingCustomerServices__c> insECS = new list<ExistingCustomerServices__c>(); 
			insECS.add(GetExistingCustomerService(newLead1.Id, 'UT-ExistingCertStandard1', 'UT-CertifyingOrganisation1'));
			insECS.add(GetExistingCustomerService(newLead1.Id, 'UT-ExistingCertStandard2', 'UT-CertifyingOrganisation2'));
			insert insECS;

			Account acc = bg_UnitTestHelper.GetAccount('UT-LEADUTILS-ACC');

			list<ExistingCustomerServices__c> ecsList = bg_LeadUtils.GetExistingCustomerServices(newLead1.Id);	
			test.startTest();
				bg_LeadUtils.TransferExistingCustomerServiceToAccount(ecsList, acc.Id);
			test.stopTest();

			for(ExistingCustomerServices__c ecs : ecsList) {
				system.assertEquals(acc.Id, ecs.Account__c);
			}
		}		
	}
*/	
}