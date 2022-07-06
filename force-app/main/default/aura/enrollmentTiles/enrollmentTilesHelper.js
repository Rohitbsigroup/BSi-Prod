({
	initialiseComponent : function(cmp, helper) {
        var currentUserId = $A.get("$SObjectType.CurrentUser.Id");
		console.log(currentUserId);
		
		let recordId = cmp.get('v.recordId');

        console.log('Record id of the enrollment: ' + recordId);
        //
        console.log('Material list visible: ' + cmp.get('v.materialListVisible'));
		
        var action = cmp.get("c.getEnrollmentTiles");
        action.setParams({ "recordId" : recordId });        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                let objR = JSON.parse(response.getReturnValue());
                cmp.set('v.tilesToDisplay', objR);
                let titleTile = objR[0].title;
                console.log('Title: ' + titleTile);
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
            'c.getEnrollmentTiles',
            function (response) {
                console.log('START RESPONSE');
                console.log(response);
                console.log(JSON.stringify(response));
                console.log(JSON.parse(JSON.stringify(response)));
                
                try{
                    let objR = JSON.parse(response);
                    cmp.set('v.tilesToDisplay', objR);
                    let titleTile = objR[0].title;
                    console.log('Title: ' + titleTile);
                }catch(error){
                    console.log(error);
                }
                
                
            },
            {
				"recordId" : recordId
			},
            false
        );*/

        
    },
    
    onClick : function(cmp, event, helper){

        let recordId = cmp.get('v.recordId');
        console.log('Record id: ' + recordId);

        let selectedItem = event.currentTarget.name;
        console.log('Selected item: ' + selectedItem);

        console.log(cmp.get('v.materialListVisible'));
        
        //update checkbox green tile
        
        var action = cmp.get("c.updateGreenTile");
        action.setParams({ "recordId" : recordId, "tileCheckbox" : selectedItem });        
        action.setCallback(this,function(response) {   
            console.log('duda333 ' + response.getReturnValue());
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.tileClicked', response.getReturnValue());
                if(selectedItem == 'Green_Tile_Pre_Course_Learning__c' || selectedItem == 'Green_Tile_Extra_Resources__c'){
                    console.log('duda success222');
                    console.log('v.materialListVisible');
                    cmp.set('v.materialListVisible', true);
                    console.log('materials are visible: ' + cmp.get('v.materialListVisible'));
                }
                this.initialiseComponent(cmp);
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
            'c.updateGreenTile',
            function (response) {
                console.log('START RESPONSE');
                console.log('Label clicked: ' + response);
                console.log(JSON.stringify(response));
                console.log(JSON.parse(JSON.stringify(response)));

                if(response != ''){
                    cmp.set('v.tileClicked', response);
                }
                console.log('Tile clicked enroll: ' + cmp.get('v.tileClicked'));
                if(selectedItem == 'Green_Tile_Pre_Course_Learning__c' || selectedItem == 'Green_Tile_Extra_Resources__c'){
                    console.log('v.materialListVisible');
                    cmp.set('v.materialListVisible', true);
                    console.log('materials are visible: ' + cmp.get('v.materialListVisible'));
                }
                
                this.initialiseComponent(cmp);
            },
            {
                "recordId" : recordId,
                "tileCheckbox" : selectedItem
			},
            false
        );*/

        




    },

    onClickInternetExplorer : function(cmp, event, helper){
        var ua = window.navigator.userAgent;
		var msie = ua.indexOf('MSIE ');	
		var trident = ua.indexOf('Trident/');

		let selectedItem = event.currentTarget.id;
        console.log('selected item: ' + selectedItem);
        let recordId = cmp.get('v.recordId');
        
        let selectedItemField = event.currentTarget.name;
        console.log('Selected item: ' + selectedItemField);

		if(msie > 0 || trident > 0){
			var eUrl= $A.get("e.force:navigateToURL");

			eUrl.setParams({
			"url": selectedItem
			});
            eUrl.fire();
            
            //this.onClick(cmp, event);
            var action = cmp.get("c.updateGreenTile");
            action.setParams({ "recordId" : recordId, "tileCheckbox" : selectedItemField });        
            action.setCallback(this,function(response) {            
                var state = response.getState();
                if (state === "SUCCESS") { 
                    cmp.set('v.tileClicked', response);
                    if(selectedItem == 'Green_Tile_Pre_Course_Learning__c' || selectedItem == 'Green_Tile_Extra_Resources__c'){
                        console.log('v.materialListVisible');
                        cmp.set('v.materialListVisible', true);
                        console.log('materials are visible: ' + cmp.get('v.materialListVisible'));
                    }
                    
                    this.initialiseComponent(cmp);
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
                'c.updateGreenTile',
                function (response) {
                    console.log('START RESPONSE');
                    console.log('Label clicked: ' + response);
                    console.log(JSON.stringify(response));
                    console.log(JSON.parse(JSON.stringify(response)));

                    if(response != ''){
                        cmp.set('v.tileClicked', response);
                    }
                    console.log('Tile clicked enroll: ' + cmp.get('v.tileClicked'));
                    if(selectedItem == 'Green_Tile_Pre_Course_Learning__c' || selectedItem == 'Green_Tile_Extra_Resources__c'){
                        console.log('v.materialListVisible');
                        cmp.set('v.materialListVisible', true);
                        console.log('materials are visible: ' + cmp.get('v.materialListVisible'));
                    }
                    
                    this.initialiseComponent(cmp);
                },
                {
                    "recordId" : recordId,
                    "tileCheckbox" : selectedItemField
                },
                false
            );*/

		}

        
    }
	
	//onClickFunction to update the checkbox as clicked (true)
})