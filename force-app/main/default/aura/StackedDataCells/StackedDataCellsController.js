({
    doInit : function(component, event, helper) {
		var factMap = component.get("v.factMap");
        var groupingsAcross = component.get("v.groupingsAcross");
        var stackedDataLabels = component.get("v.stackedDataLabels");
        var colourKeyMap = component.get("v.colourKeyMap");
        var groupingKey = component.get("v.groupingKey");
		if( !$A.util.isEmpty(factMap)){
            var dataRows = [];
            for(var i=0; i < stackedDataLabels.length; i++){
                var dataRow = [];
                dataRow.push({label:stackedDataLabels[i]});
                for(var property in groupingsAcross){
                    var key = groupingKey+'!'+groupingsAcross[property].key;
                    var data = factMap[key].aggregates[i];
                    if(!$A.util.isEmpty(colourKeyMap) && colourKeyMap.rows.includes(String(i))){
                        helper.applyConditionalFormatting(data, colourKeyMap);
                    }
                    dataRow.push(data);
                }
                dataRows.push(dataRow);
            }
            component.set("v.dataRows",dataRows);
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