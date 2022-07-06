/**
* Author:       Pawel Chrzanowski (K2)
* Date:         04/09/2018
* Description:  controller class for certificate page
*
* ******************* Change Log *******************
**/


public class CertificateController {

    public Boolean showBg {get;set;}

    public String pageName {get; set;}
    
    public List<Enrollment__c> enrollments {get; set;}


    public CertificateController(ApexPages.StandardController standardController){
        enrollments = new List<Enrollment__c>();
        String recordId  = ApexPages.CurrentPage().getparameters().get('Id');
        enrollments.addAll(getEnrollments(recordId));
        system.debug('Enrollments='+JSON.serializePretty(enrollments));
        showBg = true;

        String bg = ApexPages.currentPage().getParameters().get('bg');
        if(!String.isBlank(bg) && bg == '0') showBg = false;

        this.pageName = ApexPages.currentPage().getParameters().get('pageName');
        

    }

    
    

    // Determines what kind of rendering to use for the page request
    public String renderingService { get; private set; }

    // Allow the page to set the PDF file name
    public String renderedFileName {
        get;
        set { renderedFileName = this.sanitizeFileName(value); }
    }

    // Rendered content MIME type, used to affect HTTP response
    public String renderedContentType {
        get {
            String renderedContentType = 'text/html'; // the default
            if( ! this.renderingAsHtml() ) {
                // Provides a MIME type for a PDF document
                renderedContentType = 'application/pdf';
                // Add a file name for the PDF file
                if( this.renderedFileName != null) {
                    // This is supposed to set the file name, but it doesn't work
                    renderedContentType += '#' + this.renderedFileName;
                    // This is a work-around to set the file name
                    ApexPages.currentPage().getHeaders().put(
                        'content-disposition', 'attachment; filename=' +
                        this.renderedFileName);
                }
            }
            return renderedContentType;
        }
    }

    // Are we rendering to HTML or PDF?
    public Boolean renderingAsHtml() {
        return ( (renderingService == null) ||
                ( ! renderingService.startsWith('PDF')) );
    }

    // Action method to save (or "print") to PDF
    public PageReference saveToPdf() {
        renderingService = 'PDF';
        return null;
    }

    // Private helper -- basic, conservative santization
    private String sanitizeFileName(String unsafeName) {
        String allowedCharacters = '0-9a-zA-Z-_.';
        String sanitizedName =
            unsafeName.replaceAll('[^' + allowedCharacters + ']', '');
        // You might also want to check filename length,
        // that the filename ends in '.pdf', etc.
        return(sanitizedName);
    }

    private List<Enrollment__c> getEnrollments(String recordId) {
        return [
    		SELECT Id, Name, Del_Name__c, PCQ_Question_1__c, PCQ_Question_2__c, PCQ_Question_3__c, Training_Event__c, Training_Event__r.Master_Training_Event__c,
            	Training_Event__r.Country_Office_ISO_code__c, Booking_status__c, Delegate_Email__c, Delegate_Company_Name__c, Dietary_Requirements__c, Accomodation__c, No_of_Nights_Accommodation__c
    		FROM Enrollment__c 
   			WHERE Training_Event__r.Master_Training_Event__c = :recordId OR Training_Event__c = :recordId
		]; 
    }




}