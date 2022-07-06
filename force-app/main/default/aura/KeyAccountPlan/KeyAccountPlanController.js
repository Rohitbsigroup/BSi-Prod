({
    downloadPdf: function(component, event, helper) {
        var s = component.find("summaryId");
        var t = s.getHtml();
        var sHtml = s.innerHTML;
        
        var summaryHtmlField = component.find("summaryHtmlFieldId");
        var y = summaryHtmlField.innerHTML;

        
//        downloadFile('/apex/KeyAccountPlanPdf');
/*		var summaryHtmlField = component.find("summaryHtmlFieldId");
		var visionHtmlField = component.find("visionHtmlFieldId");
        summaryHtmlField.set("v.value", "It's");
        visionHtmlField.set("v.value", "Priceless");
        var form = document.getElementById('form');
        form.submit();

        var xhttp = new XMLHttpRequest();
          xhttp.onreadystatechange = function() {
              if (this.readyState == 4 && this.status == 200) {
                    document.getElementById("demo").innerHTML = this.responseText;
            }
 		};
		xhttp.open('POST', '/apex/KeyAccountPlanPdf', true);
		xhttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
		xhttp.setRequestHeader('Content-Disposition', 'attachment; filename="TestPDF.pdf"');
        xhttp.responseType = 'blob';
		xhttp.send("summaryHtml=John&visionHtml=Smith");
*/
//		component.find("SummaryHtml").set("v.value", JSON.stringify(summaryHtml));
//      var hiddenFormField = component.find("SummaryHtml"); //
//  	hiddenFormField.value = JSON.stringify(summaryHtml);
//		window.open("/apex/KeyAccountPlanPdf");
//    },
//    downloadFile: function(url){
	let xhr = new XMLHttpRequest();
	xhr.open('POST', '/apex/KeyAccountPlanPdf');
	xhr.responseType = 'blob';
	let formData = new FormData(this);
	xhr.send(formData); 
    xhr.onload = function(e) {
        if (this.status == 200) {
            // Create a new Blob object using the response data of the onload object
            var blob = new Blob([this.response], {type: 'image/pdf'});
            //Create a link element, hide it, direct it towards the blob, and then 'click' it programatically
            let a = document.createElement("a");
            a.style = "display: none";
            document.body.appendChild(a);
            //Create a DOMString representing the blob and point the link element towards it
            let url = window.URL.createObjectURL(blob);
            a.href = url;
            a.download = 'myFile.pdf';
            //programatically click the link to trigger the download
            a.click();
            //release the reference to the file by revoking the Object URL
            window.URL.revokeObjectURL(url);
        }else{
            //deal with your error state here
        }
    };        
}    

})