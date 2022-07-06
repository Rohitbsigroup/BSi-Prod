/********************************************************************
 * bg_EventUtilsTest
 *
 * Test class for bg_EventUtils
 * 
 * 
 * Author: Kieran Maguire
 * Created: 24-10-2013
 * Changes: 
 ********************************************************************/
@isTest
public class bg_EventUtilsTest {

	private static testMethod void testCloneEvents() {
		bg_UnitTestHelper.GetSiteSettings();
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Opportunity opp2 = bg_UnitTestHelper.GetOpportunity();
		Event event = bg_UnitTestHelper.GetEvent(opp.id);
		test.startTest();
			System.assertEquals(bg_EventUtils.GetCloneEventsByOpportunity(opp2.id).size(), 0);
			System.assertEquals(bg_EventUtils.GetCloneEventsByOpportunity(opp.id).size(), 1);
			insert bg_EventUtils.CloneEvents(opp.id, opp2.id);
			System.assertEquals(1, bg_EventUtils.GetCloneEventsByOpportunity(opp.id).size());
			System.assertEquals(1, bg_EventUtils.GetCloneEventsByOpportunity(opp2.id).size());
		test.stopTest();
	}
}