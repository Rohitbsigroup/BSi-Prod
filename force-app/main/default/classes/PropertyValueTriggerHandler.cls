/********************************************************************
 * PropertyValueTriggerHandler
 *
 * Handler Class for Property Value
 * 
 * 
 * Author: Richard Jimenez
 * Created: 06-01-2014
 * Changes: 
 ********************************************************************/
public with sharing class PropertyValueTriggerHandler {
	
	private boolean isExecuting = false;
	private integer BatchSize = 0;
	
	// CONSTRUCTOR
	public PropertyValueTriggerHandler(boolean isExecuting, integer size) {
		isExecuting = isExecuting;
		BatchSize = size;
	}
	
	// AFTER INSERT
	public void OnAfterInsert(PropertyValue__c[] newPropertyValues){
		if (!bg_PropertyValueUtils.LockPropertyValueTrigger) {
			bg_PropertyValueUtils.PopulateObjectsWithPropertyValues(newPropertyValues);
		}
	}

	// AFTER UPDATE
	public void OnAfterUpdate(PropertyValue__c[] updatedPropertyValues, map<Id, PropertyValue__c> oldMapPropertyValues){
		if (!bg_PropertyValueUtils.LockPropertyValueTrigger) {		
			bg_PropertyValueUtils.PopulateObjectsWithPropertyValues(updatedPropertyValues, oldMapPropertyValues);
		}
	}	
}