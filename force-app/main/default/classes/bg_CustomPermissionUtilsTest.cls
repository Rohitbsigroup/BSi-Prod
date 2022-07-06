/********************************************************************
 * bg_CustomPermissionUtilsTest
 *
 * Test class for: bg_CustomPermissionUtils
 * Author: Chris Eales
 * Created: 04/09/17
 * Changes:  
 *
 * test methods for bg_CustomPermissionUtils class
 *
 ********************************************************************/
@isTest
private class bg_CustomPermissionUtilsTest 
{
    /*
    	Test HasPermission for user without permission for Create MSA
    */
    static testMethod void testHasPermissionNoAccessCreateMSA()
    {
    	List<Id> permissionSetIds = new List<Id>();
    	List<Id> permittableUsers = new List<Id>();
    	String permissionName = bg_CustomPermissionUtils.CAN_CREATE_MSA;
    	
    	for (CustomPermission cPermission : [SELECT Id, DeveloperName,
										  			(SELECT Id, ParentId, Parent.Name, Parent.Profile.Name 
										  			 FROM	SetupEntityAccessItems)
										     FROM 	CustomPermission
										     WHERE	DeveloperName = :permissionName])
		{
			for (SetupEntityAccess securityEAI : cPermission.SetupEntityAccessItems)
			{
				permissionSetIds.add(securityEAI.ParentId);
			}
		}
		system.assertEquals(permissionSetIds.isEmpty(), false);
		
		for (PermissionSetAssignment pSA : [SELECT	Id, AssigneeId
											FROM 	PermissionSetAssignment
											WHERE 	PermissionSetId IN :permissionSetIds])
		{
			permittableUsers.add(pSA.AssigneeId);
		}
		List<User> usersToCheck = [SELECT	Id, Username, IsActive
								   FROM		User
								   WHERE	Id NOT IN :permittableUsers
								   AND		IsActive = true
								   LIMIT	2];
		system.assertEquals(usersToCheck.isEmpty(), false);
		
		for (User userToCheck : usersToCheck)
		{
			Boolean hasPermission = bg_CustomPermissionUtils.HasPermission(userToCheck.Id, permissionName);
			system.assertEquals(hasPermission, false);
		}

    }
    
    /*
    	Test HasPermission for user with permission for Create MSA
    */
    static testMethod void testHasPermissionWithAccessCreateMSA()
    {
    	List<Id> permissionSetIds = new List<Id>();
    	List<Id> permittableUsers = new List<Id>();
    	String permissionName = bg_CustomPermissionUtils.CAN_CREATE_MSA;
    	
    	for (CustomPermission cPermission : [SELECT Id, DeveloperName,
										  			(SELECT Id, ParentId, Parent.Name, Parent.Profile.Name 
										  			 FROM	SetupEntityAccessItems)
										     FROM 	CustomPermission
										     WHERE	DeveloperName = :permissionName])
		{
			for (SetupEntityAccess securityEAI : cPermission.SetupEntityAccessItems)
			{
				permissionSetIds.add(securityEAI.ParentId);
			}
		}
		system.assertEquals(permissionSetIds.isEmpty(), false);
		
		for (PermissionSetAssignment pSA : [SELECT	Id, AssigneeId
											FROM 	PermissionSetAssignment
											WHERE 	PermissionSetId IN :permissionSetIds])
		{
			permittableUsers.add(pSA.AssigneeId);
		}
		List<User> usersToCheck = [SELECT	Id, Username, IsActive
								   FROM		User
								   WHERE	Id NOT IN :permittableUsers
								   AND		IsActive = true 
								   AND		UserType = 'Standard' AND Profile.UserLicense.Name = 'Salesforce'
								   LIMIT	2];
		system.assertEquals(usersToCheck.isEmpty(), false);
		
		// Add users to permision set
		List<PermissionSetAssignment> forInsert = new List<PermissionSetAssignment>();
		for (Id permissionSetId : permissionSetIds)
		{
			for (User userToAdd : usersToCheck)
			{
				forInsert.add(bg_UnitTestHelper.GetPermissionSetAssignment(permissionSetId, userToAdd.Id ));
			}
		}
		system.assertEquals(forInsert.isEmpty(), false);
		insert forInsert;
		
		for (User userToCheck : usersToCheck)
		{
			Boolean hasPermission = bg_CustomPermissionUtils.HasPermission(userToCheck.Id, permissionName);
			system.assertEquals(hasPermission, true);
		}

    }
}