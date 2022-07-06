({
	initialiseComponent : function(cmp, helper) {
		let recordId = cmp.get('v.recordId');
        let tileClicked = cmp.get('v.tileClicked');
        console.log(cmp.get('v.tileClicked'));

        console.log('Record id of the enrollment on custom preview: ' + recordId);
        //
        //console.log('Material list visible: ' + cmp.get('v.materialListVisible'));
		console.log('Field tile: ' + tileClicked);
        var action = cmp.get("c.getMaterialList");
        action.setParams({ "recordId" : recordId, "tileClicked" : tileClicked}); 
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.materialList', JSON.parse(response.getReturnValue()));
                console.log('duda111 ' + JSON.stringify(JSON.parse(response.getReturnValue())));
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Error',
                        type: 'error',
                        message: errors[0].message
                    });
                    toastEvent.fire();
                } else {
                    throw new Error("Unknown Error");
                }
            }
        });
        
        $A.enqueueAction(action);
        /*this.callServer(
            cmp,
            'c.getMaterialList',
            function (response) {
                //let respone = response.getReturnValue();
                console.log('START RESPONSE PREVIEW');
                console.log(response);
                console.log(JSON.parse(response));
				//console.log(JSON.parse(JSON.stringify(response)));
				
				//conditional record type
                
                try{
					let objR = JSON.parse(response);
					
					cmp.set('v.materialList', objR);
					
					//document.getElementById("videoFrame").setAttribute("allowfullscreen", "true");

					
                    
                }catch(error){
                    console.log(error);
                }
                
                
            },
            {
				"recordId" : recordId,
				"tileClicked" : tileClicked
			},
            false
		);*/

        
    }
})