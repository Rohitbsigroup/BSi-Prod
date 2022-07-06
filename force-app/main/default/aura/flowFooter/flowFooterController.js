({
	init : function(cmp, event, helper) {
	   // Figure out which buttons to display
	   var availableActions = cmp.get('v.availableActions');
	   for (var i = 0; i < availableActions.length; i++) {
		  if (availableActions[i] == "NEXT") {
			 cmp.set("v.canNext", true);
		  }
	   }
	},
		 
	onButtonPressed: function(cmp, event, helper) {
	   // Figure out which action was called
	   var actionClicked = event.getSource().getLocalId();
	   // Fire that action
	   var navigate = cmp.get('v.navigateFlow');
	   navigate(actionClicked);
	}
 })