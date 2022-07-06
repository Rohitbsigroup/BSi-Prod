({
    initialiseComponent : function(cmp, helper) {
        helper.setHeaderLinks(cmp);
        cmp.set('v.currentYear', $A.localizationService.formatDate(new Date(), "YYYY"));
        var currentUserId = $A.get("$SObjectType.CurrentUser.Id");
        console.log(currentUserId);
        
        console.log('before calling the handle route change');
        
        var action = cmp.get("c.getRecordRelatedList");
        action.setCallback(this,function(response) {            
            var state = response.getState();
            console.log('STATE '+ state);
            if (state === "SUCCESS") { 
                console.log('Response: ' + response);
                const responseObj = JSON.parse(JSON.stringify(response.getReturnValue()));
                console.log('Responseobj: ' + responseObj);
                console.log('Response object: ' + JSON.stringify(responseObj));
                
                // TODO - store 1x array of Id's inside aura:attribute
                cmp.set('v.recordIdsAccess', responseObj['recordIdAccess']);
                //debugger;
                console.log('Record Ids: ' + cmp.get('v.recordIdsAccess'));
                
                //store isInternalUser inside aura:attribute
                cmp.set('v.isInternalUser', responseObj['isInternalUser']);
                console.log('Is internal user: ' + cmp.get('v.isInternalUser'));
                
                this.handleRouteChange(cmp);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    //throw new Error("Error" + errors[0].message);
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
        
        /*this.callServer(
            cmp,
            'c.getRecordRelatedList',
            function (response) {
                console.log('Response: ' + response);
                const responseObj = JSON.parse(JSON.stringify(response));
                console.log('Responseobj: ' + responseObj);
                console.log('Response object: ' + JSON.stringify(responseObj));
                
                // TODO - store 1x array of Id's inside aura:attribute
                cmp.set('v.recordIdsAccess', responseObj['recordIdAccess']);
                //debugger;
                console.log('Record Ids: ' + cmp.get('v.recordIdsAccess'));
                
                //store isInternalUser inside aura:attribute
                cmp.set('v.isInternalUser', responseObj['isInternalUser']);
                console.log('Is internal user: ' + cmp.get('v.isInternalUser'));
                
                this.handleRouteChange(cmp);
            },
            {},
            false
        );*/
    },
    
    handleRouteChange : function(cmp) {
        var hasRecordAccess = false;
        let isIdIncluded = false;
        console.log('Record Ids handle Route change: ' + cmp.get('v.recordIdsAccess'));
        try{
            let pagesWithChecks = ['enrollment', 'training-event', 'profile', 'surveybsi'];
            
            let path = window.location.pathname;
            let splitPath = path.split('/');
            let recordsWithAccess = cmp.get('v.recordIdsAccess');
            console.log('Record Ids: ' + cmp.get('v.recordIdsAccess'));
            
            if(window.location.href.includes('/training/s/')) {
                console.log('objName: ' + splitPath[3]);
                console.log('recordId: ' + splitPath[4]);
            } else {
				console.log('objName: ' + splitPath[2]);
                console.log('recordId: ' + splitPath[3]);                
            }
            
            // TODO further checks
            if(pagesWithChecks.includes(splitPath[3]) || pagesWithChecks.includes(splitPath[2])) {
                
                //iterate over the records with access - check if the current record id is in the list or if any of the items contains the record id
                var i;
                for(i=0; i < recordsWithAccess.length; i++){
                    //console.log('rec id: ' + recordsWithAccess[i]);
                    if(recordsWithAccess[i].includes(splitPath[4]) || recordsWithAccess[i].includes(splitPath[3])){
                        console.log('it includes the id');
                        isIdIncluded = true;
                    }
                }
                console.log('is included: ' + isIdIncluded);
                if(recordsWithAccess.includes(splitPath[4]) || recordsWithAccess.includes(splitPath[3]) || isIdIncluded){
                    hasRecordAccess = true;
                } else {
                    hasRecordAccess = false; 
                }
            } else {
                hasRecordAccess = true;
            }
            if(cmp.get('v.isInternalUser')){
                hasRecordAccess = true;
            }
            
            cmp.set('v.hasRecordAccess', hasRecordAccess);
            console.log('hasRecordAccess: ' + hasRecordAccess);
            
        } catch(error) {
            console.log('error: ' + error);
        }
        
        // if no access
        console.log('value of hasRecordAccess var: ' + hasRecordAccess);
        //cmp.set('v.hasRecordAccess', false);
        console.log(window.location.origin + '/training/s/' + cmp.get('v.redirectNoAccess'));
        if(!hasRecordAccess) {
            if(window.location.href.includes('/training/s/')) {
                window.location.href = window.location.origin + '/training/s/' + cmp.get('v.redirectNoAccess');
            } else {
                window.location.href = window.location.origin + '/' + cmp.get('v.redirectNoAccess');
            }
            
            //window.open('/s/' + cmp.get('v.redirectNoAccess'),"_self");
        }
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
        
        //get footer links depending on the user's language
        
        var action = cmp.get("c.getFooterLinks");
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                var responseList = JSON.parse(response.getReturnValue());
                for(var m=0; m<responseList.length; m++){
                    var itemResp = responseList[m];
                    console.log('item response: ' + itemResp);
                    console.log('txt item response: ' + itemResp.txt);
                    console.log('lnk item response: ' + itemResp.lnk);
                    lstFooterLink.push({txt: itemResp.txt, lnk: itemResp.lnk});
                    console.log('listFooterLink: ' + lstFooterLink);
                    cmp.set("v.lstFooterLink", lstFooterLink);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    //throw new Error("Error" + errors[0].message);
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
        
        /*this.callServer(
            cmp,
            'c.getFooterLinks',
            function (response) {
                //console.log('Response: ' + response);
                //const responseObj = JSON.parse(JSON.stringify(response));
                console.log('Response get footer links: ' + response);
                var responseList = JSON.parse(response);
                for(var m=0; m<responseList.length; m++){
                    var itemResp = responseList[m];
                    console.log('item response: ' + itemResp);
                    console.log('txt item response: ' + itemResp.txt);
                    console.log('lnk item response: ' + itemResp.lnk);
                    lstFooterLink.push({txt: itemResp.txt, lnk: itemResp.lnk});
                    console.log('listFooterLink: ' + lstFooterLink);
                    cmp.set("v.lstFooterLink", lstFooterLink);
                }
            },
            {},
            false
        );*/
        
        console.log('JSONDATAFL helper: ' + JSON.stringify(jsonDataFL));
        for (var m = 0; m < jsonDataFL.footerlnk.length; m++) {
            var itemFL = jsonDataFL.footerlnk[m];
            //lstFooterLink.push({ txt: itemFL.txt, lnk: itemFL.lnk });
        }
        
        cmp.set("v.lstMediaChannel", lstMediaChannel);
        //cmp.set("v.lstFooterLink", lstFooterLink);
    }
    
});