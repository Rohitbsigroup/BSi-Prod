/********************************************************************
 * bg_AttachmentUtilsTest
 *
 * Test class for bg_AttachmentUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 24-10-2013
 * Changes: 
 * 11/11/2014	KM	Clone opportunity attachments testmethod
 ********************************************************************/
@isTest
private class bg_AttachmentUtilsTest {

	private static testMethod void testGetAttachments() {
		/*
			Test GetAttachments method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT-AUT');		
		Attachment doc = bg_UnitTestHelper.GetAttachment(acc.Id, 'UT-DOC-TEST', 'UT-BODY-TEST');
		test.startTest();
			system.assertEquals(doc.Id, bg_AttachmentUtils.GetAttachments(acc.Id)[0].Id);
			system.assertEquals(doc.Id, bg_AttachmentUtils.GetAttachments(acc.Id, 'UT-DOC-TEST')[0].Id);
		test.stopTest();
	}
	
	private static testMethod void testCloneOpportunityAttachments() {
		bg_UnitTestHelper.GetSiteSettings();
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Opportunity opp2 = bg_UnitTestHelper.GetOpportunity();
		Attachment doc = bg_UnitTestHelper.GetAttachment(opp.id, 'Unit', 'Unit Test Body');	
		test.startTest();
			System.assertEquals([SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opp2.id].size(), 0);
			System.assertEquals([SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opp.id].size(), 1);
			bg_AttachmentUtils.CloneOpportunityAttachments(opp.id, opp2.id);
			System.assertEquals(1, [SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opp2.id].size());
			System.assertEquals(1, [SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opp.id].size());
			System.assertEquals([SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opp2.id].get(0).bodylength, [SELECT Id, BodyLength FROM Attachment WHERE ParentId =: opp.id].bodylength);
		test.stopTest();
	}
	
	
}