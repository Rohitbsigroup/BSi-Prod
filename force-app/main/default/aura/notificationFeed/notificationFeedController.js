({
	doInit : function(cmp, event, helper) {
		helper.initialiseComponent(cmp, helper);  

	},

	closeNotification : function(cmp, event, helper){
		helper.onClick(cmp, event, helper);
	},

	openNotification : function(cmp, event, helper){
		console.log('notitification clicked');
		var notification = document.getElementById('notificationItem');
		helper.markAsRead(cmp, event, helper);
	}

})