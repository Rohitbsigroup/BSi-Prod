/********************************************************************
 * bg_CIVLinkUtilsTest
 *
 * Utility class to support CIV Links
 * 
 * 
 * Author: Richard Jimenez
 * Created: 10-10-2014
 * Changes: 
 ********************************************************************/
@isTest
private class bg_CIVLinkUtilsTest {

	private static testMethod void testGetLink() {
		/* Test Get Link */

		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		string objectType = 'Lead';
		Lead lead = bg_UnitTestHelper.GetLead('CIV-UT-LEAD');
		CIV_Link__c parentLink = bg_CIVLinkUtils.CreateParentLink();
		CIV_Link__c testlink = bg_CIVLinkUtils.CreateLink(lead.Id, parentLink.Id);

		test.startTest();
			CIV_Link__c link = bg_CIVLinkUtils.GetLink(lead.Id);
			system.assertNotEquals(null, link);
			system.assertEquals(testlink.Id, link.Id);
			system.assertEquals(lead.Id, link.objectId__c);
			system.assertEquals(lead.Id, link.Lead__c);
			system.assertEquals(objectType, link.objectType__c);			
		test.stopTest();
	}

	private static testMethod void testCreateLink() {
		/* Test Create Link */

		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		string objectType = 'Lead';
		Lead lead = bg_UnitTestHelper.GetLead('CIV-UT-LEAD');
		CIV_Link__c parentLink = bg_CIVLinkUtils.CreateParentLink();

		test.startTest();
			CIV_Link__c link = bg_CIVLinkUtils.CreateLink(lead.Id, parentLink.Id);
			system.assertNotEquals(null, link);
			system.assertNotEquals(null, link.Id);
			system.assertEquals('Link', link.Type__c);
		test.stopTest();
	}

	private static testMethod void testCreateParentLink() {
		/* Test Create Parent Link */

		test.startTest();
			CIV_Link__c parentLink = bg_CIVLinkUtils.CreateParentLink();
			system.assertNotEquals(null, parentLink);
			system.assertNotEquals(null, parentLink.Id);
			system.assertEquals('Parent', parentLink.Type__c);
		test.stopTest();
	}

	private static testMethod void testGetLinks() {
		/* Test Get Links */

		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		Lead lead1 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD1');
		Lead lead2 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD2');
		map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.AddLink(lead1.Id, lead2.Id);
		Id parentId = linkMap.values()[0].Parent__c;

		list<CIV_Link__c> links;
		test.startTest();
			links = bg_CIVLinkUtils.GetLinks(parentId);
			system.assertEquals(2, links.size());			

			links = bg_CIVLinkUtils.GetLinks(parentId, 'Lead');
			system.assertEquals(2, links.size());	
		test.stopTest();
	}

	private static testMethod void testGetLinkMap() {
		/* Test Get Link Map */
		/* Test Get Links */

		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		Lead lead1 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD1');
		Lead lead2 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD2');
		bg_CIVLinkUtils.AddLink(lead1.Id, lead2.Id);

		map<Id, CIV_Link__c> linkMap;
		test.startTest();
			linkMap = bg_CIVLinkUtils.GetLinkMap(lead1.Id);
			system.assertEquals(2, linkMap.size());
			system.assertEquals(true, linkMap.containsKey(lead1.Id));
			system.assertEquals(true, linkMap.containsKey(lead2.Id));			

			linkMap = bg_CIVLinkUtils.GetLinkMap(lead1.Id, Lead.getSObjectType().getDescribe().getName());
			system.assertEquals(2, linkMap.size());	

			linkMap = bg_CIVLinkUtils.GetLinkMap(lead1.Id, Account.getSObjectType().getDescribe().getName());
			system.assertEquals(0, linkMap.size());	
		test.stopTest();
	}

	private static testMethod void testTransferLinks() {
		/* Test Transfer Links from old parent to new parent */
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		Lead lead1 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD1');
		Lead lead2 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD2');
		map<Id, CIV_Link__c> linkMap1 = bg_CIVLinkUtils.AddLink(lead1.Id, lead2.Id);

		Lead lead3 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD3');
		Lead lead4 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD4');
		map<Id, CIV_Link__c> linkMap2 = bg_CIVLinkUtils.AddLink(lead3.Id, lead4.Id);

		Id oldParentId = linkMap1.get(lead1.Id).Parent__c;
		Id newParentId = linkMap2.get(lead3.Id).Parent__c;
		
		test.startTest();
	
			bg_CIVLinkUtils.TransferLinks(oldParentId, newParentId);
		
			map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.GetLinkMap(lead1.Id);
			system.assertEquals(4, linkMap.size());
			system.assertEquals(true, linkMap.containsKey(lead1.Id));
			system.assertEquals(true, linkMap.containsKey(lead2.Id));
			system.assertEquals(true, linkMap.containsKey(lead3.Id));
			system.assertEquals(true, linkMap.containsKey(lead4.Id));

			// check old parent deleted
			system.assertEquals(0, [SELECT Id FROM CIV_Link__c WHERE Id = :oldParentId].size());			
		test.stopTest();
											
	}
	
    private static testMethod void testAddLink() {
    	/* Test Add CIV Link */
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		Lead lead1 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD1');
		Lead lead2 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD2');
					
		test.startTest();
			map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.AddLink(lead1.Id, lead2.Id);
			system.assertNotEquals(null, linkMap);
			system.assertEquals(2, linkMap.size());
			system.assertEquals(true, linkMap.containsKey(lead1.Id));
			system.assertEquals(true, linkMap.containsKey(lead2.Id));
			system.assertNotEquals(null, linkMap.get(lead1.Id).Parent__c);
			system.assertNotEquals(null, linkMap.get(lead2.Id).Parent__c);
			system.assertEquals(linkMap.get(lead1.Id).Parent__c, linkMap.get(lead2.Id).Parent__c);	
		test.stopTest();
    }

    private static testMethod void testRemoveLink() {
		/* Test Remove Link */
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		Lead lead1 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD1');
		Lead lead2 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD2');
		Lead lead3 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD2');
		
		bg_CIVLinkUtils.AddLink(lead1.Id, lead2.Id);
		bg_CIVLinkUtils.AddLink(lead2.Id, lead3.Id);
										
		test.startTest();
			bg_CIVLinkUtils.RemoveLink(lead1.Id, lead2.Id);
			
			system.assertEquals(null, bg_CIVLinkUtils.GetLink(lead1.Id));
			
			CIV_Link__c link2 = bg_CIVLinkUtils.GetLink(lead2.Id);
			system.assertNotEquals(null, link2);
			system.assertNotEquals(null, link2.Parent__c);
			
			CIV_Link__c link3 = bg_CIVLinkUtils.GetLink(lead3.Id);
			system.assertNotEquals(null, link3);
			system.assertNotEquals(null, link3.Parent__c);
			
			system.assertEquals(link3.Parent__c, link3.Parent__c);
		test.stopTest();		
    }

    private static testMethod void testCleanUpLinks() {
		/* Test Clean up Link */
		// Initialise Custom Settings
		bg_UnitTestHelper.SetupCustomSettings();

		Lead lead1 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD1');
		Lead lead2 = bg_UnitTestHelper.GetLead('CIV-UT-LEAD2');

		map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.AddLink(lead1.Id, lead2.Id);
		
		delete lead1;
		delete lead2;
									
		test.startTest();
			bg_CIVLinkUtils.CleanUpLinks();			
		test.stopTest();		

		// check links deleted
		system.assertEquals(null, bg_CIVLinkUtils.GetLink(lead1.Id));
		system.assertEquals(null, bg_CIVLinkUtils.GetLink(lead2.Id));

		// check  parent deleted
		Id parentId = linkMap.get(lead1.Id).Parent__c;
		system.assertEquals(0, [SELECT Id FROM CIV_Link__c WHERE Id = :parentId].size());			
    }
    
}