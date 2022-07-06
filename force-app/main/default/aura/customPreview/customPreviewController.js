({
	doInit : function(cmp, event, helper) {
		
		helper.initialiseComponent(cmp, helper);  
	},

// JS Controller / Helper
	handleClick : function(cmp, event, helper) {
		var selectedItem = event.currentTarget;// this will give current element
		var recIndex = selectedItem.dataset.record;// this will give the count row index
		console.log('selectedItem file: ' + selectedItem);
		console.log('recIndex file:' + recIndex);

		/*var navService = cmp.find("navService");
		console.log('navigation start');
		var pageReference = {
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview',
			},
			state : {
				recordIds: '0693G0000008qp3QAA', //recIndex, // single record Id
				selectedRecordId: '0693G0000008qp3QAA' //recIndex
				// interesting feature introduces right/left arrows; might be useful
				// recordIds: '0691n00000GReFnAAL,0691n00000EoHuhAAF,0691n00000EoHucAAF', 
			}
			
		};
		//event.preventDefault();
		navService.navigate(pageReference);*/
		console.log('before click');
		$A.get('e.lightning:openFiles').fire({
            recordIds: [recIndex]
        });
		console.log('after click');
	},
	  
})