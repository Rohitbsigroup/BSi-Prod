({
    doInit : function(cmp, event, helper) {
        cmp.set('v.hasPermissions', helper.hasUserEditPermissions(cmp.get('v.recordId')));
    }
    
    /*handleComponentEvent : function(cmp, event){
        console.log(event);
        console.log(JSON.stringify(event));
    },

    handleApplicationEvent : function(cmp, event){
        console.log(JSON.stringify(event));
    }*/
});