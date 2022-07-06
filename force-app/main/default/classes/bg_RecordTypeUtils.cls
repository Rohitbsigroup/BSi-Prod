/********************************************************************
 * bg_RecordTypeUtils
 *
 * Record Type Utility methods to support record type functions
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 ********************************************************************/
public class bg_RecordTypeUtils {
  
  	public static final string OBJECT_NAME_ACCOUNT = 'Account';
  	public static final string OBJECT_NAME_CONTACT = 'Contact';
  	public static final string OBJECT_NAME_OPPORTUNITY = 'Opportunity';
  	public static final string OBJECT_NAME_SITE = 'Site__c';
  	
  	private static map<string, map<string, RecordType>> allRecordTypes;
    
    public static map<string, RecordType> GetRecordTypes(string objectName) {
    	/* 
    		Return Record Type for object
    	*/
		if (allRecordTypes == null) {
			allRecordTypes = new map<string, map<string, RecordType>>();
		} 
		if(!allRecordTypes.containsKey(objectName)) {
        	allRecordTypes.put(objectName, GetRecordTypeStringMap(objectName));
      	}
      	return allRecordTypes.get(objectName);
    }

    private static map<string, RecordType> GetRecordTypeStringMap(string objectName) {
    	/* 
    		Return Record Type String Map for object
    	*/    	
        map<string, RecordType> recordTypes = new map<string, RecordType>();
        for (RecordType rt : [SELECT SobjectType, developerName, IsActive, Id 
                              FROM RecordType
                              WHERE SobjectType = :objectName
                              	AND IsActive = true])
    	{
            recordTypes.put(rt.developerName, rt);
        }
        system.debug(recordTypes);
        return recordTypes;
    }
}