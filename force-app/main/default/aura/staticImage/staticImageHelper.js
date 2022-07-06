({

    initialiseComponent : function(cmp, helper) {
        helper.addEventListenerWidthResize(cmp);
        helper.setSubDirectory(cmp);
        helper.setResponsiveSubDirectory(cmp);
        cmp.set('v.initDone', true);
    },

    reInitialiseComponent : function(cmp, helper) {
        cmp.set('v.initDone', false);
        helper.initialiseComponent(cmp, helper);
    },

    addEventListenerWidthResize : function(cmp) {

        // set initial width
        cmp.set('v.width', document.documentElement.clientWidth);

        // add event listener for resizing
        window.addEventListener('resize', $A.getCallback(function() {
            if(cmp.isValid()) {
                cmp.set('v.width', document.documentElement.clientWidth);
            }
        }));
    },

    setSubDirectory : function(cmp) {
        let subDirectory = '';

        const path = window.location.pathname;
        if(cmp.get('v.hasSubDir')) {
            try {
                subDirectory = path.substring(0, (path.substring(1, path.length)).indexOf("/") + 1);
                if(subDirectory === '/s') subDirectory = ''; // remove Salesforce-specific /s paths
            } catch (err) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'Error',
                    type: 'error',
                    message: err[0].message
                });
                toastEvent.fire();
            }
        }
        cmp.set('v.baseUrl', subDirectory + '/resource/');
    },

    setResponsiveSubDirectory : function(cmp) {

        if(cmp.get('v.isResponsive')) {

            const baseUrl = cmp.get('v.baseUrl');

            try {
                const responsiveArray = cmp.get('v.imageName').split(",");
                cmp.set('v.imgSrcSmall', baseUrl + responsiveArray[0]);
                cmp.set('v.imgSrcMedium', baseUrl + responsiveArray[1]);
                cmp.set('v.imgSrcLarge', baseUrl + responsiveArray[2]);
            } catch (err) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'Error',
                    type: 'error',
                    message: err[0].message
                });
                toastEvent.fire();
            }
        }
    }

});