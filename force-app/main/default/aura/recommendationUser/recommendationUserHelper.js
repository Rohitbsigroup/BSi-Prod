({
	initialiseComponent : function(cmp, helper) {
        var currentUserId = $A.get("$SObjectType.CurrentUser.Id");
		console.log(currentUserId);

		let recordId = cmp.get('v.recordId');
		console.log('recordId: ' + recordId);
		var action = cmp.get("c.getRecommendationTiles");
        action.setParams({ "recordId" : recordId});        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") {
                let listTiles = JSON.parse(response.getReturnValue());
                console.log('DUDA1111 ' + JSON.stringify(JSON.parse(response.getReturnValue())));
				cmp.set('v.recommendedTiles', listTiles);
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
            'c.getRecommendationTiles',
            function (response) {
                console.log('START RESPONSE');
                console.log(response);
				console.log(JSON.parse(response));
				let listTiles = JSON.parse(response);
				cmp.set('v.recommendedTiles', listTiles);
            },
            {
				"recordId" : recordId
			},
            false
        );*/
        var action2 = cmp.get("c.getTrainingTranslation");
        action2.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                cmp.set('v.trainingTranslation', JSON.parse(response.getReturnValue()));
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
        
        $A.enqueueAction(action2);
        /*this.callServer(
            cmp,
            'c.getTrainingTranslation',
            function (response) {
                cmp.set('v.trainingTranslation', response);
            },
            {},
            false
        );*/
	}
})