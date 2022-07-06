({
	doInit : function(cmp, event, helper) {
        helper.initialiseComponent(cmp, event, helper);
	},

	handleSaveEdition: function (cmp, event, helper) {
        var draftValues = event.getParam('draftValues');

        helper.saveEdition(cmp, helper, draftValues);
    },
    handleCancelEdition: function (cmp) {
        // do nothing for now...
    }
})