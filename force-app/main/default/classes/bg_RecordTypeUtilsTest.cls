/********************************************************************
 * bg_RecordTypeUtilsTest
 *
 * Test class for bg_RecordTypeUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 17-10-2013
 * Changes: 
 ********************************************************************/
@isTest
private class bg_RecordTypeUtilsTest {

    private static testMethod void testGetRecordTypes() {
    	/* 
    		Return Record Type for object
    	*/
		bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_ACCOUNT);
    }
    
}