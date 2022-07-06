({
    doInit : function(cmp, event, helper) {
        cmp.set('v.hasPermissions', helper.hasUserEditPermissions(cmp.get('v.recordId')));
        helper.getNetworkMemberRecord(cmp, helper);
    },

    handleCancel : function(cmp, event, helper) {
        helper.toggleViewEdit(cmp);
        helper.getNetworkMemberRecord(cmp, helper);
    },

    handleSave : function(cmp, event, helper) {
        helper.handleSaveHelper(cmp, helper);
    },

    toggleViewEdit : function(cmp, event, helper) {
        helper.toggleViewEdit(cmp);
    } 
});