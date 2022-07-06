({
    applyConditionalFormatting: function(cell, colourKeyMap){
        if(!isNaN(cell.label)){
            var value = Number(cell.label);
            var colourKeys = colourKeyMap.key;
            for(var property in colourKeys){
                var colourMap = colourKeys[property];
                if(value<=Number(colourMap.value)){
                	cell.colour = colourMap.colour;
                    return;
                } 
            }
        }
	},
})