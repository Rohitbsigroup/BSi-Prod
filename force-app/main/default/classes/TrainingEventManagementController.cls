/********************************************************************
* TrainingEventManagementController
*
* Controller that extends Training_Event__c standard controller for Exam 
* Rotation list view button
* 
* Author: Alexis Lignereux
* Created: 26-11-2014
* Changes: 
*  27-11-2014 - Alexis Lignereux
*       Implemented logic if there is not previous event for the course
*       Implemented the confirm and cancel button
*  08-12-2014 - Alexis Lignereux
*       Changed confirm method to handle user entering exam paper number
*           which are greater than allowed for the course
*
********************************************************************/
public with sharing class TrainingEventManagementController
{

    private ApexPages.StandardSetController setController;
    public List<Training_Event__c> events {get; set;}
    public boolean errorFlag {get; set;}
    public boolean noRows {get; set;}
    public String errorsEvent {get; set;}

    public TrainingEventManagementController(ApexPages.StandardSetController standardController)
    {
        setController = standardController;
        events = setController.getSelected();
        errorFlag = false;
        errorsEvent = null;

        if (events.size() > 0 )
        {
            noRows = false;
        }
        else
        {
            noRows = true;
        }
    }

    public PageReference rotateExam()
    {

        if (!noRows)
        {
            if (bg_CustomSettingsUtils.GetPermissionSettings().CanExecuteExamRotation__c)
            {

                // get the last event for the course and check the exam paper ref
                List<Id> courseIds = new List<Id>();
                List<Id> eventIds = new List<Id>();

                for (Training_Event__c selectedEvent : events)
                {
                    courseIds.add(selectedEvent.Course__c);
                    eventIds.add(selectedEvent.Id);
                }

                // Need more fields on events that is available from the list view
                List<Training_Event__c> fullSelectedEvents = [
                    Select Id, Name, Course__c, Course__r.Number_of_Exam_Papers__c, Course__r.Course_Has_Exam__c, Start_Date__c, Event_Status__c, Trainer__c, 
                        Trainer_2nd__c, Is_Full__c, Training_Venue__c, Exam_paper_reference__c 
                    from Training_Event__c 
                    where Id =: eventIds
                    order by Start_Date__c asc
                ];

                // get list of completed training events for each course
                Date todayDate = Date.today();

                List<Training_Event__c> finishedEvents = [
                    Select Id, Name, Course__c, Course__r.Number_of_Exam_Papers__c, Course__r.Course_Has_Exam__c, Start_Date__c, Event_Status__c, Trainer__c, 
                        Trainer_2nd__c, Is_Full__c, Training_Venue__c, Exam_paper_reference__c 
                    from Training_Event__c 
                    where Course__c =: courseIds
						and End_Date__c >: todayDate.addYears(-1) 
                    	and End_Date__c <: todayDate
                    	and Exam_paper_reference__c != null
                    order by Start_Date__c desc];
                    //limit 1];

                // go through the list of finishedEvents remove duplicates
                Map<Id,Training_Event__c> uniqueFinishedEvents = new Map<Id,Training_Event__c>();
                for (Training_Event__c te : finishedEvents)
                {
                    if (!uniqueFinishedEvents.containsKey(te.Course__c))
                    {
                        uniqueFinishedEvents.put(te.Course__c, te);
                    }
                }

                // only update training event where product has exam
                for (Training_Event__c selectedEvent : fullSelectedEvents)
                {
                    if (selectedEvent.Course__r.Course_Has_Exam__c)
                    {
                        if (uniqueFinishedEvents.containsKey(selectedEvent.Course__c))
                        {
                            Training_Event__c te = uniqueFinishedEvents.get(selectedEvent.Course__c);
                            if (te.Exam_paper_reference__c == String.valueOf(te.Course__r.Number_of_Exam_Papers__c) ||
                            	string.IsBlank(te.Exam_paper_reference__c))
                            {
                                selectedEvent.Exam_paper_reference__c = '1';
                            } 
                            else
                            {
                                Integer newExam = Integer.valueOf(te.Exam_paper_reference__c) + 1;
                                selectedEvent.Exam_paper_reference__c = String.valueOf(newExam);
                            }
                            uniqueFinishedEvents.remove(selectedEvent.Course__c);
                        } 
                        else
                        {
                            selectedEvent.Exam_paper_reference__c = '1';
                        }
                        uniqueFinishedEvents.put(selectedEvent.Course__c,selectedEvent);
                    }
                    else
                    {
                        selectedEvent.Exam_paper_reference__c = null;
                    }
                }
                events = fullSelectedEvents;
            } 
            else
            {
                errorFlag = true;
            }
        }
        return null;
    }

    public PageReference confirm()
    {
        // need to ensure that exam paper ref is within course number of papers
        String errorString = '';
        for (Training_Event__c event : events)
        {
            if (event.Exam_paper_reference__c != null)
            {
                if (Integer.valueOf(event.Exam_paper_reference__c) > event.Course__r.Number_of_Exam_Papers__c)
                {
                    if (errorString != '') errorString += ', ';
                    errorString += event.Name;
                }
            }
        }

        if (errorString == '')
        {
            update events;
            return setController.save();
        }
        else
        {
            errorsEvent = string.format(Label.Training_Event_Exam_Rotation_Wrong_Number_of_Exam_Papers, new list<string>{errorString});
            return null;
        }
    }

    public PageReference cancel()
    {
        return setController.cancel();
    }
}