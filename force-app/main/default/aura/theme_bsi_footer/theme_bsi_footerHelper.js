({
    initialiseComponent : function(cmp, helper) {
        helper.setHeaderLinks(cmp);
        cmp.set('v.currentYear', $A.localizationService.formatDate(new Date(), "YYYY"));
        
    },

    setHeaderLinks : function(cmp) {
        var lstMediaChannel = [];
        //var lstHeaderLink = [];
		var lstFooterLink = [];
		//var jsonDataHL = JSON.parse(cmp.get("v.headerLinks"));
		var jsonDataFL = JSON.parse(cmp.get("v.footerLinks"));
		var jsonDataMC = JSON.parse(cmp.get("v.mediaChannels"));
		
		for (var i = 0; i < jsonDataMC.media.length; i++) {
 		    var itemMC = jsonDataMC.media[i];
    		lstMediaChannel.push({ picB: itemMC.picB, picW: itemMC.picW, ref: itemMC.ref });
		}

		for (var m = 0; m < jsonDataFL.footerlnk.length; m++) {
	 	    var itemFL = jsonDataFL.footerlnk[m];
    		lstFooterLink.push({ txt: itemFL.txt, lnk: itemFL.lnk });
		 }

		cmp.set("v.lstMediaChannel", lstMediaChannel);
		cmp.set("v.lstFooterLink", lstFooterLink);
    }
    
});