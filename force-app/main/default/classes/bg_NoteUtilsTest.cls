/********************************************************************
*
* Author:       Kieran Maguire
* Company:      BrightGen
* Date:         17/11/2014
* Description:  Controller to clone the opportunity with sites, attachments and the master quote     
* Changes:    
 * 11/11/2014	KM	Clone opportunity attachments method
 ********************************************************************/
@isTest
public class bg_NoteUtilsTest {
	
	private static testMethod void CloneNotesTest(){
		//CloneNotes test method
		
		bg_UnitTestHelper.GetSiteSettings();
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Opportunity opp2 = bg_UnitTestHelper.GetOpportunity();
		Note doc = bg_UnitTestHelper.GetNote(opp.id);
		
		test.startTest();
			System.assertEquals(bg_NoteUtils.GetCloneNotes(opp.id).size(), 1);
			System.assertEquals(bg_NoteUtils.GetCloneNotes(opp2.id).size(), 0);
			insert bg_NoteUtils.CloneNotes(opp.id, opp2.id);	
			System.assertEquals(1, bg_NoteUtils.GetCloneNotes(opp.id).size());
			System.assertEquals(1, bg_NoteUtils.GetCloneNotes(opp2.id).size());
			System.assertEquals(bg_NoteUtils.GetCloneNotes(opp.id).get(0).title, bg_NoteUtils.GetCloneNotes(opp.id).get(0).title);
		test.stopTest();
	}
	
}