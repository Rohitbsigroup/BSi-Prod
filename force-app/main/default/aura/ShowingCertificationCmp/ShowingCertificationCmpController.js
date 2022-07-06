({
	doInit : function(component, event, helper) {
		var action = component.get("c.checkShowCertConditionValidity");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
            	component.set("v.isValidUser", response.getReturnValue().isValidity);
                if (response.getReturnValue().isValidity) {
                    let obj = response.getReturnValue();
                    component.set("v.objectApiName", obj.objectApiName);
                    component.set("v.isShareCert",   obj.isShareCert);
                }
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
    },
    
    shareCertClicked: function(component, event, helper) {
        var action = component.get("c.udpateShareCertificateCheckboxOnRecord");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire(); 
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
    }
})