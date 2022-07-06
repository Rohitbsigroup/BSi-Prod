({
	initialiseComponent : function(cmp, event, helper) {

        const initialiseRequest = {
            'recordId'      : cmp.get('v.recordId'),
            'type'          : cmp.get('v.type'),
            'fieldsString'  : cmp.get('v.fieldList'),
            'objectString'  : cmp.get('v.object'),
            'parentObject'  : cmp.get('v.parentObject'),
            'whereString'   : cmp.get('v.whereFilter'),
            'orderByString' : cmp.get('v.orderBy'),
            'editableFields': cmp.get('v.editableFields'),
            'urlExtension'  : cmp.get('v.urlExtension')
		};
		
		console.log('request recordId: ' + cmp.get('v.recordId'));

        let check = false;
        (function(a){if(/(android|bb\d+|meego).+(|iPhone|iPad|iPod|)+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4))) check = true;})(navigator.userAgent||navigator.vendor||window.opera);
        if(check){
            cmp.set('v.isMobile', check);
        }

        let win = window, 
            x = win.innerWidth, 
            y = win.innerHeight;
        let isDimensionsCorrect = 
            (x == 768 && y == 1024) ||
            (x == 820 && y == 1180) ||
            (x == 1024 && y == 1366) ||
            (x == 1112 && y == 834) ||
            (x == 1536 && y == 2048);
        if (isDimensionsCorrect) cmp.set('v.isDimensionsCorrect', false);

        var action = cmp.get("c.initialiseComponent");
        action.setParams({ "initialiseRequest" : JSON.stringify(initialiseRequest)});        
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                cmp.set('v.relatedListResponse', JSON.parse(response.getReturnValue()));
                cmp.set('v.initDone', true);
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
 /*
        helper.callServer(
            cmp,
            "c.initialiseComponent",
            function (response) {
                cmp.set('v.relatedListResponse', JSON.parse(response));
                cmp.set('v.initDone', true);
            },
            {
                "initialiseRequest" : JSON.stringify(initialiseRequest)
            }
        );*/
        console.log('isMobile: ' + check);
    },

    saveEdition: function (cmp, helper, draftValues) {
        var self = this;
        console.log('saveEdition function');

        console.log('draft values saveEd: '  + draftValues);
        draftValues = helper.getRowId(cmp, draftValues);
        console.log('draft var: ' + JSON.stringify(draftValues));
        /* helper.callServer(
            cmp,
            "c.updateRecords",
            function(response){
                //
                //this.initialiseComponent(cmp, event, handler);
                $A.get("e.force:refreshView").fire();

            },
            {
                "draftValues" : JSON.stringify(draftValues),
                "fieldList"  : cmp.get('v.fieldList'),
                "objectString" : cmp.get('v.object')
            }
        ); */

        var action = cmp.get("c.updateRecords");
        action.setParams(
            { 
                "draftValues"  : JSON.stringify(draftValues),
                "fieldList"    : cmp.get('v.fieldList'),
                "objectString" : cmp.get('v.object')
            }
        );
        action.setCallback(this,function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") { 
                $A.get("e.force:refreshView").fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    console.log(JSON.stringify(errors))
                    cmp.set('v.isErrorShown', true);
                    var outputError = '';
                    errors.forEach(errorObJ => {
                        // To Be done if there are field errors or duplicate results
                        // Page errors output
                        if (errorObJ.pageErrors && errorObJ.pageErrors.length) {
                            errorObJ.pageErrors.forEach(pageError => {
                                console.log('pageError111 ' + JSON.stringify(pageError));
                                outputError += pageError.message + '. ';
                            });
                        };
                    });
                    cmp.set('v.errorMessage', outputError);
                } else {
                    throw new Error("Unknown Error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    getRowId: function(cmp, draftValues){

        var relatedListResponse = cmp.get('v.relatedListResponse');
        for(var i=0; i < draftValues.length; i++){
            var rowId = draftValues[i].id.replace("row-", "");
            var recordId = relatedListResponse.data[rowId].Id;
            draftValues[i].recordId = recordId;
        }

        return draftValues;

    }
})