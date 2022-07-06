({
    doInit : function(component, event, helper) {
		var factMap = component.get("v.factMap");
		var groupingKey = component.get("v.groupingKey");
		if( factMap && groupingKey ){
            var map = factMap[groupingKey+"!T"].rows;
			component.set("v.dataRows", map);
		}
	},
	editRecord : function (component, event, helper) {
		var recordId = event.currentTarget.dataset.recordid;
		var editRecordEvent = $A.get("e.force:editRecord");
		editRecordEvent.setParams({
			 "recordId": recordId
		});
		editRecordEvent.fire();
	}
})