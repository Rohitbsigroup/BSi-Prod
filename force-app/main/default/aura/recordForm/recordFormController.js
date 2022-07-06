({
    doInit : function(cmp, event, helper) {
        cmp.set('v.fields', cmp.get('v.fieldList').split(",") );
    },

    handleCancel : function(cmp, event, helper) {
        event.preventDefault();
        helper.toggleViewEdit(cmp);
    },

    handleSuccess : function(cmp, event, helper) {
        //helper.showSuccessMessage('Successfully updated your preferences.');
        $A.get('e.force:showToast').fire({
            type: 'success',
            title: $A.get('$Label.c.CLP_Success'),
            message: $A.get('$Label.c.CLP_SuccessfulUpdate')
        });
        helper.toggleViewEdit(cmp);

        if(cmp.get('v.fields').includes('LanguageCustom__c')){
            if(cmp.get('v.languageOnLoad') != cmp.get('v.languageOnSubmit')){
                location.reload();
            }
        }
        
        
    },

    handleSubmit : function(cmp, event, helper){
        //console.log('EVENT sumbit: ' + JSON.stringify(event));
        //let fieldsCmp = cmp.get('v.fields');
        if(cmp.get('v.fields').includes('LanguageCustom__c')){
            let language = event.getParam('fields').LanguageCustom__c;
            cmp.set('v.languageOnSubmit', language);
            console.log('fields on submit: ' + language);
        }
        

        
        /*var compEvent = cmp.getEvent("editFormCmpEvt");

        compEvent.setParams({"message" : JSON.stringify('messageEvent'), "type" : "submit"});

        compEvent.fire();*/


    },


    handleOnLoad : function(cmp, event, helper){

        //var record = event.getParam("recordUi").record;
        //var recordFields = record.fields;

        if(cmp.get('v.fields').includes('LanguageCustom__c')){
            let language = event.getParam("recordUi").record.fields.LanguageCustom__c;
            cmp.set('v.languageOnLoad', language.value);
            console.log('Field name: ' + language.value);
        }

        /*var compEvent = cmp.getEvent("editFormCmpEvt");

        compEvent.setParams({"message" : JSON.stringify('messageOnLoad'), "type" : "onload"});

        compEvent.fire();*/
        
        /*var appEvent = $A.get('e.c:editFormAppEvt');
        appEvent.setParams({"message" : "messageOnLoad"});

        appEvent.fire();*/
    },

    toggleViewEdit : function(cmp, event, helper) {
        helper.toggleViewEdit(cmp);
    }
});