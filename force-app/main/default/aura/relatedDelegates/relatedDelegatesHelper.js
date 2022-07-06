({
    initializeComponent : function(cmp,event,helper) {
        var recordId = cmp.get('v.recordId');
        console.log('##### init related degs:',recordId);
        var action = cmp.get('c.getChildEvents');
        action.setParams({ "masterEventId" : recordId});        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                cmp.set('v.childEventsList', JSON.parse(response.getReturnValue()));
                cmp.set('v.initDone', true);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Error getting related delegates',
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