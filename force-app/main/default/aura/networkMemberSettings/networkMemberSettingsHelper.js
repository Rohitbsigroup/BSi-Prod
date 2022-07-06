({
    getNetworkMemberRecord : function(cmp, helper) {
        var action = cmp.get("c.getNetworkMember");
        action.setParams({ "userId" : cmp.get("v.recordId"), "networkId" : cmp.get("v.networkId")});        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                let networkMember = helper.invertBooleanPreferences(JSON.parse(response.getReturnValue()));
                cmp.set("v.networkMember", networkMember);
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
        
        /*helper.callServer(
            cmp,
            "c.getNetworkMember",
            function (response) {
                let networkMember = helper.invertBooleanPreferences(JSON.parse(response));
                cmp.set("v.networkMember", networkMember);
            },
            {
                "userId" : cmp.get("v.recordId"),
                "networkId" : cmp.get("v.networkId")
            }
        );*/
    },

    invertBooleanPreferences : function(obj) {

        Object.keys(obj).forEach(function(key) {
            try {
                if(key.startsWith('Preferences')) {
                    obj[key] = !(obj[key]); // negate boolean value
                }
            } catch (err) {
                // skip silently
            }
        });

        return obj;
    },

    handleSaveHelper : function(cmp, helper) {
        const data = helper.invertBooleanPreferences(cmp.get('v.networkMember'));
		
        var action = cmp.get("c.setNetworkMember");
        action.setParams({ "data" : JSON.stringify(data)});        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'Success',
                    type: 'success',
                    message: 'Successfully updated your preferences.'
                });
                helper.toggleViewEdit(cmp);
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
        
        /*helper.callServer(
            cmp,
            "c.setNetworkMember",
            function (response) {
                if(!response) {
                    helper.showSuccessMessage('Successfully updated your preferences.');
                    helper.toggleViewEdit(cmp);
                } else {
                    helper.showErrorMessage(response);
                }
            },
            {
                "data" : JSON.stringify(data)
            }
        );*/
    },

    toggleViewEdit : function(cmp) {
        cmp.set('v.toggleMode', !cmp.get('v.toggleMode'));
    }

});