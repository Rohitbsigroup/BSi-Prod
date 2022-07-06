public with sharing class IRCAEnrolmentExtractExt {

    private PageReference returnPage;

    public List<Enrollment__c> selectedEnrolments { get; set; }
    public string fileName { get; set; }
    public String headerRow { get; set; }
    public List<String> csvRows { get; set; }

    public IRCAEnrolmentExtractExt(ApexPages.StandardSetController cntlr) {

        // Build the return page
        returnPage = new PageReference(ApexPages.currentPage().getParameters().get('retUrl'));
        returnPage.setRedirect(true);

        // Set default filename
        this.fileName = 'IRCA_Delegate Data SFDC2.csv';

        // Get the passed Enrolments
        this.selectedEnrolments = [
            SELECT  e.Id
                    , e.Booking_status__c
                    , e.Delegate_name__r.ID //JS added to allow ease of upload of CQI ID
                    , e.CQI_ID__c, e.CQI_Del_Data_Taken__c, e.CQI_Exam_Data_Taken__c
                    , e.Delegate_name__r.Salutation, e.Delegate_name__r.FirstName, e.Delegate_name__r.LastName, e.Delegate_name__r.Email, e.Delegate_name__r.FirstNameLocal, e.Delegate_name__r.LastNameLocal
                    , e.Exam_Mark__c, e.Exam_results__c
                    , e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Start_date__c
                    , e.Original_IRCA_Course_Enrollment__r.Training_Event__r.End_Date3__c
                    , e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Master_Training_Event__c
                    , e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Master_Training_Event__r.Event_Country__c
                    , e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Master_Training_Event__r.Regional_CLL_Event__c
                    , e.Training_Event__r.Course__r.Course_Country__c
                    , e.Training_Event__r.Course__r.Delivery_Method__c
                    , e.Training_Event__r.Course__r.Course_Format__c
                    , e.Training_Event__r.Course__r.IRCA_Number__c
                    , e.Training_Event__r.Course__r.Training_Product_Type__c
                    , e.Training_Event__r.Master_Training_Event__c
                    , e.Training_Event__r.Master_Training_Event__r.Event_Country__c
                    , e.Training_Event__r.Master_Training_Event__r.Regional_CLL_Event__c
                    , e.Training_Event__r.End_Date3__c, e.Training_Event__r.Start_date__c
                    , e.Training_Event__r.Trainer__r.Name
            FROM    Enrollment__c e  
            WHERE   Id IN :cntlr.getSelected()
        ];
    }

    public pageReference create() {

        // Check enrolments have been passed
        if (this.selectedEnrolments.size() == 0) {

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least one Enrolment'));
            return null;
        }
        else if (this.fileName == '') {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must provide a File Name'));
            return null;
        } else {

            // Redirect to the CSV page
            PageReference pr = Page.IRCAEnrolmentExtract2;
            return pr;
        }
    }

    public void build() {

        // Add file name to HTTP headers
        Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=' + this.fileName);

        // Create the header row
        this.headerRow = 'ST_ATP_ID,ST_COURSE_ID,ST_START_DATE,ST_END_DATE,ST_TUTOR_NAME,ST_DELIVERY_METHOD,ST_COURSE_COUNTRY,ST_ATP_DELEGATE_ID,ST_PREFIX,ST_FIRST_NAME,ST_LAST_NAME,ST_EMAIL,ST_OPT_IN,ST_CQI_DELEGATE_ID,ST_RESULT,ST_MARK_SCORE,ST_RESIT';

        // Build data rows
        this.csvRows = new List<String>();
        List<Enrollment__c> toUpdate = new List<Enrollment__c>();
        for (Enrollment__c e : this.selectedEnrolments) {
            
            // Build one row
            String r = '01180271';
            r += ',' + clean(e.Training_Event__r.Course__r.IRCA_Number__c); //JS 20180913 Changed to just the IRCA number

            if(e.Training_Event__r.Course__r.Training_Product_Type__c == 'Exam'){
                r += ',' + e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Start_date__c.format();
                r += ',' + e.Original_IRCA_Course_Enrollment__r.Training_Event__r.End_Date3__c.format();
            }else{
                r += ',' + e.Training_Event__r.Start_date__c.format();
                r += ',' + e.Training_Event__r.End_Date3__c.format();
            }

            r += ',' + clean(e.Training_Event__r.Trainer__r.Name);
            r += ',' + clean(e.Training_Event__r.Course__r.Course_Format__c == 'ILT' ? 'CL' : 'VC'); //MD 20200511 Changed to output VC if course is not classroom based

            String courseCountry = e.Training_Event__r.Course__r.Course_Country__c;
            if (e.Training_Event__r.Master_Training_Event__c != null && e.Training_Event__r.Master_Training_Event__r.Regional_CLL_Event__c) {
                courseCountry = e.Training_Event__r.Master_Training_Event__r.Event_Country__c;
            }
            if (e.Training_Event__r.Course__r.Training_Product_Type__c == 'Exam' && e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Master_Training_Event__c != null && e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Master_Training_Event__r.Regional_CLL_Event__c) {
                courseCountry = e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Master_Training_Event__r.Event_Country__c;
            }

            r += ',' + clean(courseCountry == 'ME' ? 'AE' : courseCountry == 'SA' ? 'ZA' : courseCountry == 'UK' ? 'GB' : courseCountry);
            r += ',' + e.Delegate_name__r.ID; //JS - changed this from ENR id to contact ID to allow easy upload of Del No
            r += ',' + clean(e.Delegate_name__r.Salutation);
            r += ',' + clean(e.Delegate_name__r.FirstName);//JS - removed the local names for TW and CN 11052018
            r += ',' + clean(e.Delegate_name__r.LastName);//JS - removed the local names for TW and CN 11052018
            r += ',' + clean(e.Delegate_name__r.Email);
            r += ',' + 'N';
            r += ',' + clean(e.CQI_ID__c == null ? '0' : e.CQI_ID__c);
            r += ',' + clean(e.CQI_Del_Data_Taken__c != true ? '' : (String.isNotBlank(e.Booking_status__c) && (e.Booking_status__c == 'No Show') ? 'DNA' :  (e.Exam_results__c == 'IRCA - Pass exam & pass CA') ? 'PASS' : 'FAIL')); //JS added in logic to make blank if first extract -  was (String.isNotBlank(e.Booking_status__c) && (e.Booking_status__c == 'No Show') ? 'DNA' : (e.Exam_results__c == 'IRCA - Pass exam & pass CA') ? 'PASS' : 'FAIL');
            r += ',' + clean(e.CQI_Del_Data_Taken__c != true ? '' : e.Exam_Mark__c == null ? '' : e.Exam_Mark__c.format()); //JS added in logic to make blank if first extract  - was clean(e.Exam_Mark__c == null ? '' : e.Exam_Mark__c.format());
            r += ',' + (String.isNotBlank(e.Booking_status__c) && ((e.Booking_status__c == 'Booked - Resit')|| (e.Booking_status__c == 'Booked - BSI Employee Resit')) ? 'Y' : 'N'); //JS added in Employee resit
            this.csvRows.add(r);

            // Check whether enrolment needs to be updated
            // 05 April 2017 Vim updated condition to fix the logic 
            //if (e.CQI_Del_Data_Taken__c != true || ((e.CQI_Exam_Data_Taken__c != true) && (String.isNotBlank(e.CQI_ID__c) || e.CQI_ID__c == '0') && (e.Exam_Mark__c != null)))
            if (e.CQI_Del_Data_Taken__c != true || ((e.CQI_Exam_Data_Taken__c != true) && (String.isNotBlank(e.CQI_ID__c) && e.CQI_ID__c != '0') && (e.Exam_Mark__c != null))) {    
                // Add one update
                Enrollment__c upd = new Enrollment__c(Id = e.Id);
                if (e.CQI_Del_Data_Taken__c != true) upd.CQI_Del_Data_Taken__c = true;
                //28 April 2017 Vim updated code to fix the scenario - when a delegate has a CQI ID and is enrolled to a second course. Both tick boxes were ticked when attendance marked and exam result added
                //The fix is applied below to tick the Del data taken in first pick up and then Exam data taken in second pick up. 
                // if ((e.CQI_Exam_Data_Taken__c != true) && (String.isNotBlank(e.CQI_ID__c) && e.CQI_ID__c != '0') && (e.Exam_Mark__c != null)) upd.CQI_Exam_Data_Taken__c = true;
                if ((e.CQI_Del_Data_Taken__c == true) && (e.CQI_Exam_Data_Taken__c != true) && (String.isNotBlank(e.CQI_ID__c) && e.CQI_ID__c != '0') && (e.Exam_Mark__c != null)) upd.CQI_Exam_Data_Taken__c = true;
                toUpdate.add(upd);
            }
        }
        
        // Update flags
        if (!toUpdate.isEmpty()) update toUpdate;
    }

    // Function to deal with null values and embedded commas
    private static String clean(String input) {

        // Format output
        return input == null ? '' : input.replace(',', ';').replaceAll('(\\r\\n|\\r|\\n)', ';');
    }
}