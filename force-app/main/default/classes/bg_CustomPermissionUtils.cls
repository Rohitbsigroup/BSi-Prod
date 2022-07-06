/** **************************************************************************************************************************
 * bg_CustomPermissionUtils.cls
 *
 * @description: Utility methods for custom permissions 
 * Test class: bg_CustomPermissionUtilsTest
 *
 * @author Chris Bacon
 * @date 25/05/2017
 *
 * Changes:
 *	CPE 04/09/17	Amended HasPermission to use passed in userId parameter rather than the running user id
 *****************************************************************************************************************************/
public class bg_CustomPermissionUtils 
{
	// defined permission developer names
	public static final String CAN_CREATE_MSA='Can_Create_MSA'; 
	
	
	// map of permission set ids keyed by the custom permission developer (unique!) name 
	private static Map<String, List<Id>> permSetIdsByPermDevName;
	
	/*
	 * Pull the custom permissions and the permission sets they are attached to
	 * 
	 */
	private static void SetupPerms()
	{
    	// get the custom permission and associated permission set id
		List<CustomPermission> custPerms=[SELECT Id, DeveloperName,
										  (select Id, ParentId, Parent.Name, Parent.Profile.Name from SetupEntityAccessItems)
										  FROM CustomPermission];
	
		permSetIdsByPermDevName=new Map<String, List<Id>>();
		for (CustomPermission custPerm : custPerms)
		{
			List<Id> permSetIds=new List<Id>();
			for (SetupEntityAccess sea : custPerm.SetupEntityAccessItems)
			{
				permSetIds.add(sea.parentId);
			}
			permSetIdsByPermDevName.put(custPerm.DeveloperName, permSetIds);
		}
	}
	
	/*
	 * @description Does the supplied user have the named custom permission through any of the permission sets that are 
	 *              assigned to them?
	 *
	 * @param userId the user to check
	 * @param permName the developer name of the custom permission
	 */
    public static Boolean HasPermission(Id userId, String permName)
    {
    	Boolean result=false;
    	
    	if (null==permSetIdsByPermDevName)
    	{
    		SetupPerms();
    	}
    	
    	List<Id> permSetIds=permSetIdsByPermDevName.get(permName);
    	
    	if (null!=permSetIds)
    	{
			// now get the permission assignments for the set(s) where the supplied user is the assignee
			List<PermissionSetAssignment> psas=[select Id, AssigneeId
												from PermissionSetAssignment
												where PermissionSetId IN :permSetIds
												  and AssigneeId=:userId];  

			result = !psas.IsEmpty();
    	}
    	
    	return result;
    }

}