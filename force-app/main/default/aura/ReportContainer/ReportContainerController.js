({
    getReport : function(component, event, helper) {
        //hide report and show spinner while we process
        var loadingSpinner = component.find('loading');
        $A.util.removeClass(loadingSpinner, 'slds-hide');
        var reportContainer = component.find('report');
        $A.util.addClass(reportContainer, 'slds-hide');
        var reportError = component.find('report-error');
        $A.util.addClass(reportError, 'slds-hide');

        //get report data from Apex controller using report ID provided
        var action = component.get('c.getReportData');
        var filterValue = component.get("v.filterValueAttribute");
        action.setParams({ 
            reportId: component.get("v.reportIdAttribute"),
            recordId: component.get("v.recordId"),
            reportParameterOption: component.get("v.reportParameterOption")
        });

        //handle response from Apex controller
        action.setCallback(this, function(response){           
            var groupingsDownAttr=component.get("v.groupingsDown");
            var groupingsAcrossAttr=component.get("v.groupingsAcross");
            var factMapAttr=component.get("v.factMap");
            var verticalColumnHeaders = component.get("v.verticalColumnHeaders")=='Yes';
            var colourRows = component.get("v.colourRows");
            var colourKey = component.get("v.colourKey");
            var colourKeyTitle = component.get("v.colourKeyTitle");
            
            // transform into JSON object
            var resultMap = JSON.parse(response.getReturnValue());
            var returnValue = null;
            var linkQueryString = null;
            
            if(resultMap) {
                returnValue = resultMap.reportResults;
                linkQueryString = resultMap.linkQueryString;
            }
            
            if( returnValue && returnValue.reportExtendedMetadata && returnValue.groupingsDown.groupings ){
                // categorize groupings into levels so we can access them as we go down grouping level
                var isMatrixFormat = (returnValue.reportMetadata.reportFormat=='MATRIX');
				
                var groupingsDown = returnValue.groupingsDown.groupings;
	            var groupingsDownArray = new Array(groupingsDown.length);
                for( var property in groupingsDown ){
                    if( groupingsDown.hasOwnProperty(property) ){
                        var cell = groupingsDown[property];
                        groupingsDownArray[cell.key] = {label:cell.label, value:cell.value, key:cell.key, groupings:cell.groupings};
                    }
                }

                var dataGroupingColumns = returnValue.groupingsAcross.groupings;
                var groupingsAcrossArray = [];
                if(!$A.util.isEmpty(dataGroupingColumns)){
                    for( var heading in dataGroupingColumns ){
                        if( dataGroupingColumns.hasOwnProperty(heading) ){
                            if(dataGroupingColumns[heading].groupings){	// Matrix report with subheadings across
                                for(var subHeading in dataGroupingColumns[heading].groupings){
	                            	var cell = dataGroupingColumns[heading].groupings[subHeading];
    	                        	groupingsAcrossArray.push(cell);
                                }
                            }else{
                            	var cell = dataGroupingColumns[heading];
                            	groupingsAcrossArray.push(cell);
                            }
                        }
                    }
            	}            

                // Start by calculating the report table headers. 
                var tableHeaders = [];
                var stackedDataLabels=[];
                
                var groupingsDownHeaders = returnValue.reportMetadata.groupingsDown;
                var groupingsExt = returnValue.reportExtendedMetadata.groupingColumnInfo;
                // The first one or two headers are for 'key columns' describing row record attributes rather than 'data columns' identifying different column records
                for(var property in groupingsDownHeaders){
                    if(groupingsDownHeaders.hasOwnProperty(property)){
                        var fieldAPIName = groupingsDownHeaders[property].name;
                        var cell = {label:groupingsExt[fieldAPIName].label, value:'', style:'text-align:left'}; 
                        tableHeaders.push(cell);                            
                    }
                }
                if(isMatrixFormat){
                    // Matrix reports work by grouping data in two ways at once: downwards and across. Each can contain further subgroups. 
                    // Any individual cell in such a matrix report some aggregate (eg count, min, max..) of the things that fall into both the across
                    // and down grouping. In fact there may be multiple aggregate function compressed into each cell. We chose to dispay multiple
                    // aggregates as 'stacked values' one on top of each other, all against the same downward grouping. 
                    // To make this work visually we leave one blank header column above a repeating set of the stacked data labels - each label repeated once
                    // for each downward grouping to which it applies.
                    // Here's the blank header column:
                    tableHeaders.push({label:''});
                    // Then we add the across grouping headers:
                    for( var property in dataGroupingColumns){
                        if(dataGroupingColumns.hasOwnProperty(property)){
                            var cell = dataGroupingColumns[property];
                            cell.style = verticalColumnHeaders?'writing-mode:vertical-rl;align-items:flex-end':'';	// display column headers vertically to fit better in the limited page width
                            tableHeaders.push(cell);
                        }
                    }
                    // Now go back over the tableheaders to calculate any row and col span values in the case of subheaders (multiple groupings across)
                    // Count the number of subheader levels using the last header cell
                    var lastCell = tableHeaders[tableHeaders.length-1];
                    var headerDepth=1;

                    while(lastCell.groupings && lastCell.groupings.length>0){
                        lastCell = lastCell.groupings;
                        headerDepth++;
                    }
                    for(var cell in tableHeaders){
                        if(tableHeaders[cell].groupings && tableHeaders[cell].groupings.length>0){  // Found nested subheaders
                            helper.calculateSpan(tableHeaders[cell], verticalColumnHeaders); // helper.calculateSpan(tableHeaders[cell]);								
                        }else{											// Ordinary header
                            tableHeaders[cell].rowspan = headerDepth;
                            tableHeaders[cell].colspan = 1;
                        }
                    }
                    // Finally we record the stacked data labels - but dont add to the TableHeader row
                    var aggregates = returnValue.reportMetadata.aggregates;
                    var customSummaryFormula = returnValue.reportMetadata.customSummaryFormula;
 	                for( var property in aggregates ){
                        if(aggregates.hasOwnProperty(property)){
                            var header = aggregates[property];
	                        var label = customSummaryFormula[header].label;
    	        	        stackedDataLabels.push(label);
                        }
                	} 
                }else{
	                // Assume a SUMMARY or TABULAR report
                    // First add a key column header for each level of 'downward' groupings

                    // Then add the data columns for each record field to be displayed
                    var detailColumns = returnValue.reportMetadata.detailColumns;
	                for( var property in detailColumns ){
                        if(detailColumns.hasOwnProperty(property)){
                            var fieldAPIName = detailColumns[property];
	                        var label = returnValue.reportExtendedMetadata.detailColumnInfo[fieldAPIName].label;
                            tableHeaders.push({label:label});
                        }
                	} 
               }

                // set lightning attributes so we have access to variables in the view
                component.set("v.groupingsDown", groupingsDownArray);
                component.set("v.groupingsAcross", groupingsAcrossArray);
                component.set("v.tableHeaders", tableHeaders);
                component.set("v.stackedDataLabels", stackedDataLabels);
                component.set("v.factMap", returnValue.factMap);
                component.set("v.reportName", returnValue.reportMetadata.name);
                component.set("v.numColumns", helper.countColumns(tableHeaders));
                if(!$A.util.isEmpty(colourRows)){
					component.set("v.colourKeyMap", helper.createColourKeyMap(colourRows, colourKey, colourKeyTitle));
                }
                component.set("v.linkQueryString", linkQueryString);
                
                //hide spinner, reveal data
                $A.util.addClass(loadingSpinner, 'slds-hide');
                $A.util.removeClass(reportContainer, 'slds-hide');
            }
            else {
                $A.util.addClass(loadingSpinner, 'slds-hide');
                $A.util.removeClass(reportError, 'slds-hide');
            }
        })
        $A.enqueueAction(action);
    }
})