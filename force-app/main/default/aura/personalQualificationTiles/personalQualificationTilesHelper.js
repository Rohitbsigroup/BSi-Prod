({
	initialiseComponent : function(cmp, helper) {
        var currentUserId = $A.get("$SObjectType.CurrentUser.Id");
		console.log(currentUserId);
		
		let recordId = cmp.get('v.recordId');

        console.log('Record id of the personal qualif: ' + recordId);
        
        var action = cmp.get("c.getPersonalQualificationTiles");
        action.setParams({ "recordId" : recordId });        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                let objR = JSON.parse(response.getReturnValue());
                cmp.set('v.tilesToDisplay', objR);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    //throw new Error("Error" + errors[0].message);
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
            'c.getPersonalQualificationTiles',
            function (response) {
                //let respone = response.getReturnValue();
                console.log('START RESPONSE');
                console.log(response);
                console.log(JSON.stringify(response));
                console.log(JSON.parse(JSON.stringify(response)));
                
                try{
                    let objR = JSON.parse(response);
                    cmp.set('v.tilesToDisplay', objR);
                }catch(error){
                    console.log(error);
                }
                
            },
            {
				"recordId" : recordId
			},
            false
        );*/

        
    }
})