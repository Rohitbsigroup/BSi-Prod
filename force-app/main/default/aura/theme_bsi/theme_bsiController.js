({
    doInit : function(cmp, event, helper) {
        helper.initialiseComponent(cmp, helper);        
    },

    routeChange : function(cmp, event, helper) {
        helper.handleRouteChange(cmp);
    }
});