({
	// Calculate the span attributes of header cells by iterating  across subgroupings
    calculateSpan: function(cell,verticalColumnHeaders){
    	var colspan = 0;
    	for(var child in cell.groupings){
            colspan += this.calculateSpan(cell.groupings[child]);
		}
        cell.colspan = Math.max(colspan,1);
        cell.rowspan = 1;
        cell.style = verticalColumnHeaders?'writing-mode:vertical-rl;align-items:flex-end':'';
        return cell.colspan;
	},
    countColumns: function(tableHeaders){
        var columns=0;
	    for(var header in tableHeaders){
            var colspan = tableHeaders[header].colspan;
            columns += (Number.isInteger(colspan)?colspan:1);
    	}
    	return columns;
    },
    createColourKeyMap: function(colourRows, colourKey, colourKeyTitle){
        var strArray = colourKey.split(',');
        var rowArray = colourRows.split(',');
        var keyArray = [];
	    for(var i = 0; i<strArray.length; i+=3){
    		keyArray.push({label: strArray[i], value:strArray[i+1], colour:strArray[i+2]});
    	}
        return {rows:rowArray, key:keyArray, title:colourKeyTitle};
    }
})