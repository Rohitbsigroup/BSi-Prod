/********************************************************************
 * bg_TaskUtilsTest
 *
 * Test class for bg_TaskUtils
 * 
 * 
 * Author: Kieran Maguire
 * Created: 24-10-2013
 * Changes: 
 ********************************************************************/
@isTest
public class bg_TaskUtilsTest {
	
	private static testMethod void testCloneOpportunityAttachments() {
		bg_UnitTestHelper.GetSiteSettings();
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Opportunity opp2 = bg_UnitTestHelper.GetOpportunity();
		Task task = bg_UnitTestHelper.GetTask(opp.id);
		test.startTest();
			System.assertEquals(bg_TaskUtils.GetCloneTasksByOpportunity(opp2.id).size(), 0);
			System.assertEquals(bg_TaskUtils.GetCloneTasksByOpportunity(opp.id).size(), 1);
			insert bg_TaskUtils.CloneTasks(opp.id, opp2.id);
			System.assertEquals(1, bg_TaskUtils.GetCloneTasksByOpportunity(opp2.id).size());
			System.assertEquals(1, bg_TaskUtils.GetCloneTasksByOpportunity(opp.id).size());
		test.stopTest();
	}
}