/**
 * @Name:        LightningUtilityController
 * @Description: Aura Controller class to handle server side operations of c:lightningUtility component
 *
 * @author:      Patrick Fischer
 * @version:     1.0
 * Change Log
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 27/11/2018    Patrick Fischer    Created Class
 */
public with sharing class LightningUtilityController {

    @AuraEnabled
    public static Boolean validatePermissionSet(String permissionSetName) {
        Boolean isValid = false;

        List<PermissionSetAssignment> assignments = [
                SELECT AssigneeId, Assignee.Name, PermissionSetId, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name = :permissionSetName AND AssigneeId = :UserInfo.getUserId()
        ];

        if(!assignments.isEmpty()) {
            isValid = true;
        }

        return isValid;
    }


    /**
     * To dynamically retrieve picklist values by Object and Field Api name
     *
     * @param picklistFields Set of fields specified as Object Api Name concatenated with Field Api Name
     *                       { 'Custom_Object__c.Field_Name1__c', 'Custom_Object__c___Field_Name2__c', ... }
     *
     * @return Wrapper Type of Object___Field-Name
     *  {
     *      "Custom_Object__c.Field_Name1__c" : [ { 'value':'val 1', 'label':'label 1' } , { 'value':'val 2', 'label':'label 2' } ],
     *      "Custom_Object__c.Field_Name2__c" : [ { 'value':'val x', 'label':'label x' } , { 'value':'val y', 'label':'label y' } ]
     *  }
     */
    @AuraEnabled
    public static Map<String, Object> getAllPicklistOptions(Map<String, Object> picklists) {

        Map<String, Object> returnMap = new Map<String, Object>();

        for(String picklist : picklists.keySet()) {
            List<Object> allPicklistValues = new List<Object>();

            try {
                String objectApiName = picklist.split('\\.')[0];
                String fieldApiName = picklist.split('\\.')[1];
                List<Schema.PicklistEntry> pickListValues = Schema.getGlobalDescribe().get(objectApiName).getDescribe()
                        .fields.getMap().get(fieldApiName).getDescribe().getPicklistValues();

                for (Schema.PicklistEntry pickListValue : pickListValues) {
                    allPicklistValues.add(new Map<String, String> {
                            'label' => pickListValue.getLabel(),
                            'value' => pickListValue.getValue()
                    });
                }

            } catch (Exception e) {
                allPicklistValues.add(new Map<String, String> { 'label' => 'An Error Occurred', 'value' => '' } );
                throw new AuraHandledException('Darn it! Something went wrong: ' + e.getMessage());
            }

            returnMap.put(picklist, allPicklistValues);
        }

        return returnMap;
    }
}