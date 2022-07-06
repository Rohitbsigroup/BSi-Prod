({
    initialiseComponent : function(cmp, helper) {
        let currentUserId = $A.get("$SObjectType.CurrentUser.Id");
        console.log('current user Id: ' + currentUserId);
        var action = cmp.get("c.getNotificationRecords");
        action.setParams({ "userId" : currentUserId });        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                let objR = JSON.parse(response.getReturnValue());
                cmp.set('v.notificationItems', objR);
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
            cmp.set('v.hasLoaded', true);
        });
        
        $A.enqueueAction(action);
        
        /*this.callServer(
            cmp,
            'c.getNotificationRecords',
            function (response) {
                console.log('START RESPONSE');
                console.log('RESPONSE NOTIF: ' + JSON.parse(JSON.stringify(response)));
                try{
                    let objR = JSON.parse(response);
                    cmp.set('v.notificationItems', objR);
                }catch(error){
                    console.log(error);
                }
                cmp.set('v.hasLoaded', true);
            },
            {
                "userId" : currentUserId
            },
            false
        );*/
    },

    onClick : function(cmp, event, helper){
        let selectedItem = event.currentTarget.name;
        console.log('Selected item: ' + selectedItem);
        
        //call function to like post
        var action = cmp.get("c.closePost");
        action.setParams({ "notificationRecordId" : selectedItem });        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
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
            'c.closePost',
            function (response) {
                try{
                   
                }catch(error){
                    console.log(error);
                }
                
                this.initialiseComponent(cmp);
            },
            {
                "notificationRecordId" : selectedItem
            },
            false
        );*/
        
        
    },
    
    markAsRead : function(cmp, event, helper){
        let selectedItem = event.currentTarget.id;
        console.log('Selected item: ' + selectedItem);
        
        let selectedItemUrl = event.currentTarget.name;
        
        var res = selectedItemUrl.split("/");
        if(res[3] != 's'){
            //record detail page
            var record = res[3];
            console.log('record id: ' + record);
            // Get the Lightning event that opens a record in a new tab
            var redirect = $A.get("e.force:navigateToSObject");
            // Pass the record ID to the event
            redirect.setParams({
                "recordId": record
            });
            // Open the record
            redirect.fire();
        }else{
            //custom portal page
            window.open(selectedItemUrl, '_self');
        }
        
        
        var action = cmp.get("c.readPost");
        action.setParams({ "notificationRecordId" : selectedItem });        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
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
            'c.readPost',
            function (response) {
                try{
                   
                }catch(error){
                    console.log(error);
                }
                
                this.initialiseComponent(cmp);
            },
            {
                "notificationRecordId" : selectedItem
            },
            false
        );*/

    }
})