({
	doInit : function(cmp, event, helper) {
		helper.initialiseComponent(cmp, helper);    

	},
	
	onClickTile : function(cmp, event, helper){
		helper.onClick(cmp, event, helper);
		
	},

	hideModal : function(cmp, event, helper){
		cmp.set('v.materialListVisible', false);
	},

	redirectUser : function(cmp, event, helper){
		helper.onClickInternetExplorer(cmp, event, helper);
	}
})