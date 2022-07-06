({
    /**
     * Makes an asynchronous call to
     * server-side Apex controller and sets
     * the Javascript callback method.
     *
     * @method callServer
     * @param {Object} cmp - The component to which the controller belongs.
     * @param {String} method - Name of the server side action method to call.
     * @param {function} callback - Pointer reference to the callback function.
     * @param {Object} params - Optional parameters to send with the action.
     * @param {Boolean} refreshView - Optional parameter to refresh view after action.
     */
    callServer: function(cmp, method, callback, params, refreshView){
        const action = cmp.get(method);
        if (params){
            action.setParams(params);
        }
        action.setCallback(this,function(response){
            const state = response.getState();
            if (cmp.isValid() && state === 'SUCCESS') {
                callback.call(this,response.getReturnValue());
            } else if (cmp.isValid() && state === 'ERROR') {
                const errors = response.getError();
                if (errors) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Error',
                        type: 'error',
                        message: errors[0].message
                    });
                    toastEvent.fire();
                } else {
                    throw new Error('Unknown Error');
                }
            }else{
                //For the future
            }

            if (refreshView) {
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * Renders the component.
     *
     * @method showComponent
     * @param {Object} cmp - The component to which the controller belongs.
     **/
    showComponent: function(cmp){
        cmp.set('v.renderFlag', true);
    },

    /**
     * Unrenders the component and
     * displays optional message.
     *
     * @method showComponent
     * @param {Object} cmp - The component to which the controller belongs.
     * @param {String} message - Optional informational message why component is hidden.
     **/
    hideComponent: function(cmp, message){
        cmp.set('v.renderFlag', false);
        if (message) {
            cmp.set('v.renderMessage', message);
        }
    },

    /**
     * General show toast method.
     * @param title Title for toast component.
     * @param message Message details for toast component.
     * @param type Variant type (e.g. info, error)
     */
    showToast: function(title, type, message) {
        $A.get('e.force:showToast').setParams({
            'title': title,
            'type': type,
            'message': message
        }).fire();
    },

     /**
     * displays error message.
     * @param {String} message - Optional informational messagewhy component is hidden.
     **/
    showErrorMessage : function(message, title) {
        //const errorTitle = title || 'Error';
        //this.showToast(errorTitle, 'error', message);
        this.showToast($A.get('$Label.c.CLP_Error'), 'error', $A.get('$Label.c.CLP_ErrorAccess'));
    },

     /**
     * displays success message.
     * @param {String} message - Optional informational messagewhy component is hidden.
     **/
    showSuccessMessage : function(message, title) {
        //const successTitle = title || 'Success';
        //this.showToast(successTitle, 'success', message);
        this.showToast($A.get('$Label.c.CLP_Success'), 'success', $A.get('$Label.c.CLP_SuccessfulUpdate'));
    },

    /**
     * displays info message.
     * @method showInfoMessage
     * @param {Object} cmp - The component to which the controller belongs.
     * @param {String} message - Optional informational message why component is hidden.
     **/
    showInfoMessage : function(message, title) {
        //const infoTitle = title || 'Info';
        //this.showToast(infoTitle, 'info', message);
        this.showToast($A.get('$Label.c.CLP_Info'), 'info', $A.get('$Label.c.CLP_InfoMessage'));
    },

    /**
     * Format a template string.
         * @param stringToFormat Template string to format (e.g. My name is {0})
     * @param formattingArguments List of string values to fill in template string.
     * @return The formatted string with replaced placeholders.
     */
    formatString : function(stringToFormat, formattingArguments) {
        let resultString = stringToFormat;
        for (var i in formattingArguments) {
            if (formattingArguments.hasOwnProperty(i)){
                const currentArg = formattingArguments[i];
                const replacement = Array.isArray(currentArg) ? currentArg.join('\',\'') : currentArg;
                const regex = new RegExp('\\{' +  + '\\}', 'g');
                resultString = resultString.replace(regex, replacement);
            }
        }
        return resultString;
    },

    /**
     * To validate access to a certain LEX component by permission set
     * @param cmp Component reference invoking this function
     * @param permissionSetName such as 'Financial_Configuration_Permission'
     */
    validatePermissions : function(cmp, permissionSetName) {
        this.hideComponent(cmp);
        this.callServer(
            cmp,
            'c.validatePermissionSet',
            function (response) {
                const responseObj = JSON.parse(JSON.stringify(response));
                if(!responseObj) {
                    $A.get('e.force:closeQuickAction').fire();
                    const customLabel = $A.get('$Label.c.ERROR_THIS_SCREEN_REQUIRES_PERMISSION');
                    const permissions = '\'' + permissionSetName.replace(/[_-]/g, ' ') + '\'';
                    this.showErrorMessage(this.formatString(customLabel, [permissions]));
                } else {
                    this.showComponent(cmp);
                }
            },
            {
                permissionSetName: permissionSetName
            },
            false
        );
    },

    /**
     * To validate that a given userId equals belongs to the currently logged in user. This is being used to verify that
     * a current/logged-in Community User has permissions to edit the opened user record.
     * @param recordId String of currently opened User Record Page
     */
    hasUserEditPermissions : function(recordId) {
        const currentUserId = $A.get("$SObjectType.CurrentUser.Id");

        try {
            // only current user has permissions to access the page (comparing on 15-char Id's)
            if(currentUserId.toLowerCase().substring(0, 14) === recordId.toLowerCase().substring(0, 14)) {
                return true;
            }
        } catch(err) {
            // skip silently
        }

        return false;
    },

    /**
     * CSS Styling to extend the width of modal upon initialisation
     * @param cmp Aura.Component Reference
     * @param customCss String to add additional CSS during maximisation of the modal
     */
    maximiseQuickActionModal : function (cmp, customCss) {
        if(!customCss) customCss = '';
        $A.createComponent(
            'aura:unescapedHtml',
            {
                'value': '<style> .slds-modal__container { width:96% !important; min-width: 96% !important; ' +
                         'padding: 45px 0 25px 0 !important; margin-left: 2% !important; margin-right: 2% !important; } ' +
                         '.cuf-content { padding: 0 !important; } .slds-modal__content { padding: 0 !important; } ' +
                         '.slds-docked-form-footer { margin-bottom: 25px !important; } ' + customCss + ' </style>'
            },
            function(styleSheet, status, errorMessage) {
                if (status === 'SUCCESS') {
                    const body = cmp.get('v.body');
                    body.push(styleSheet);
                    cmp.set('v.body', body);
                }
            }
        );

        console.log('MAXIMISED MODAL');
    }
});