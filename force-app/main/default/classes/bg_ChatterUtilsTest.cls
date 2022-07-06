/********************************************************************
 * bg_ChatterUtilsTest
 *
 * Test methods for Chatter Utility class
 * 
 * 
 * Author: Richard Jimenez
 * Created: 16-12-2013
 * Changes: 
 ********************************************************************/
@isTest
private class bg_ChatterUtilsTest {

	private static testMethod void testGetChatterPost() {
		/*
			Test GetChatterPost Method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Id parentId = bg_UnitTestHelper.GetAccount('UT-CONTACTUTILS-ACC').Id;
		string title = 'UT-Title';
		string linkURL  = 'UT-URL';
		string postType = bg_ChatterUtils.CHATTER_POSTTYPE_LINKPOST;
		string postBody = 'UT-PostBody';

		test.startTest();
			FeedItem fi = bg_ChatterUtils.GetChatterPost(parentId, title, linkURL, postType, postBody);
		test.stopTest();
		
		system.assertNotEquals(null, fi);
		system.assertEquals(parentId, fi.ParentId);
		system.assertEquals(title, fi.Title);
		system.assertEquals(linkURL, fi.LinkUrl);
		system.assertEquals(postType, fi.Type);
		system.assertEquals(postBody, fi.Body);
	}
}