// Use no conflict to avoid namespace issues 
var j = jQuery.noConflict();

// document ready
j(function( $ ) {
	
	setupSamplingGridModal();
	// add event listener to show sampling command button for on click
		$("[id$=showSamplingTableBtn]").click(function(){				
		// show the popup
		$("[id$=samplingTable]").dialog("open");
	});
});

function setupSamplingGridModal()
{
	// declare the element to be used as a popup
	j("[id$=samplingTable]").dialog({
		autoOpen:false,
		modal:true,
		height:300,
		width:460,
		title: "Sampling Grid",
		resizable:false
	});
}

// override default focus on load
function setFocusOnLoad() {} 

function noenter(ev)  {
    if (window.event && window.event.keyCode == 13 || ev.which == 13) {
        doProductSearch();
        return false;
    } else {
      return true;
    }
}

function openQuestionPopup(url, windowName, product, productType)  {
    if (productType == 'IMS') {
        CreateIMSQuestion(product);
    } else if (productType == 'SAMPLING') {
        CreateSamplingQuestion(product);
    }
		
    var win = window.open(url, windowName, "width=1200,height=700,scrollbars=yes");

    var timer = setInterval(
        function() {
            if(win.closed) {  
                clearInterval(timer);
                window.focus();
                
                if (productType == 'IMS') {
                    RefreshIMSQuestion(product);
                } else if (productType == 'SAMPLING') {
                    RefreshSamplingQuestion(product);
                }
            }
        }, 1000);                           
}