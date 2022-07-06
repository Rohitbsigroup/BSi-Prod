/********************************************************************
 * bg_UserUtilsTestTest
 *
 * Test class for bg_UserUtilsTest
 * 
 * 
 * Author: Richard Jimenez
 * Created: 28-10-2013
 * Changes: 
 *	CPE 01-09-2017 New test methods for GetCountryMap
 *	CPE 04-09-2017 New test method for UpdateUserRecordForPs
 *
 ********************************************************************/
@isTest
private class bg_UserUtilsTest {

	private static testMethod void testGetUsers() {
		/*
			Test GetUsers and GetUsersMap methods
		*/
		test.startTest();
			system.assertNotEquals(0, bg_UserUtils.GetUsers(true).size());
			system.assertNotEquals(0, bg_UserUtils.GetUserMap().size());
		test.stopTest();
	}
	
	private static testMethod void testGetUserById() {
		/*
			Test GetUserById methods
		*/
		test.startTest();
			system.assertEquals(UserInfo.getUserId(), bg_UserUtils.GetUserById(UserInfo.getUserId()).Id);
		test.stopTest();
	}
	
	private static testMethod void testIsAdministrator() {
		/*
			Test IsAdministrator method
		*/
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		test.startTest();
			system.assertEquals(false, bg_UserUtils.IsAdministrator(user1.Id));
		test.stopTest();
	}
	
	/*
		Tests getCountryMap returns an empty map if no owners are supplied
	*/
	private static testMethod void testGetCountryMapNoIds()
	{
		Set<Id> ownerIds = new Set<Id>();
		Map<Id, User> results = new Map<Id, User>();
		results = bg_UserUtils.GetCountryMap(ownerIds);
		system.assertEquals(results.isEmpty(), true);
	}
	
	/*
		Tests getCountryMap returns expected results when called once
	*/
	private static testMethod void testGetCountryMapWithIdsOnce()
	{
		Map<Id, User> ownerIds = new Map<Id, User>();
		ownerIds.putAll([SELECT	Id, Name, OperationCountry__c
						 FROM	User
						 WHERE	OperationCountry__c != null
						 LIMIT 10]);
		system.assertEquals(ownerIDs.isEmpty(), false);
		Map<Id, User> results = new Map<Id, User>();
		results = bg_UserUtils.GetCountryMap(ownerIds.keySet());
		system.assertEquals(results.isEmpty(), false);
		system.assertEquals(results.size(), ownerIds.size());
	}
	
	
	/*
		Tests getCountryMap returns expected results when called more than once
	*/
	private static testMethod void testGetCountryMapWithIdsMultiple()
	{
		Set<Id> initialOwnerIds = new Set<Id>();
		Set<Id> secondaryOwnerIds = new Set<Id>();
		Boolean initial = true;
		for (User usr : [SELECT	Id, Name, OperationCountry__c
						 FROM	User
						 WHERE	OperationCountry__c != null
						 LIMIT 10])
		{
			if (initial)
			{
				initialOwnerIds.add(usr.Id);
			}
			else
			{
				secondaryOwnerIds.add(usr.Id);
			}
			initial = !initial;
		}
		system.assertEquals(initialOwnerIds.isEmpty(), false);
		system.assertEquals(initialOwnerIds.isEmpty(), false);
		Map<Id, User> results = new Map<Id, User>();
		results = bg_UserUtils.GetCountryMap(initialOwnerIds);
		system.assertEquals(results.isEmpty(), false);
		system.assertEquals(results.size(), initialOwnerIds.size());
		results = bg_UserUtils.GetCountryMap(secondaryOwnerIds);
		system.assertEquals(results.isEmpty(), false);
		system.assertEquals(results.size(), initialOwnerIds.size() + secondaryOwnerIds.size());
	}	

	/*
		Test the UpdateUserRecordForPs.  First starts of with ensuring PS_Approval_User__c is  not
		set then changes twice.
	*/
	private static testMethod void testUpdateUserRecordForPs()
	{
		List<User> approvers = new List<User>();
		User myUser = [SELECT	Id, PS_Approval_User__c 
					   FROM 	User 
					   WHERE 	Id = :Userinfo.getUserId()];
		if (myUser.PS_Approval_User__c != null)
		{
			myUser.PS_Approval_User__c = null;
			update myUser;
		}
		system.assertEquals(true, myUser.PS_Approval_User__c == null);

		approvers.addAll([SELECT	Id, Username, IsActive
						  FROM		User
						  WHERE		IsActive = true
						  AND		Id != :Userinfo.getUserId()
						  LIMIT	2]);
		
		bg_UserUtils.UpdateUserRecordForPs(approvers[0].Id);
		myUser = [SELECT	Id, PS_Approval_User__c 
				  FROM 		User 
				  WHERE 	Id = :Userinfo.getUserId()];				  
		system.assertEquals(approvers[0].Id, myUser.PS_Approval_User__c);


		bg_UserUtils.UpdateUserRecordForPs(approvers[1].Id);
		myUser = [SELECT	Id, PS_Approval_User__c 
				  FROM 		User 
				  WHERE 	Id = :Userinfo.getUserId()];				  
		system.assertEquals(approvers[1].Id, myUser.PS_Approval_User__c);
	}

	
}