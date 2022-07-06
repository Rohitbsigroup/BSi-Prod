/********************************************************************
 * bg_CongaTemplateCloneWithItemsController
 *
 * CongaTemplateClone Controller class
 * 
 * 
 * Author: James Thornton
 * Created: 18-05-2016
 * Changes: 
 ********************************************************************/

 public class bg_CongaTemplateCloneWithItemsController 
 {
    
    //added an instance varaible for the standard controller
    private ApexPages.StandardController controller {get; set;}
     // add the instance for the variables being passed by id on the url
    private APXTConga4__Conga_Template__c congaTemplate {get; set;}
    // set the id of the record that is created -- ONLY USED BY THE TEST CLASS
    public ID newRecordId {get;set;}

    public APXTConga4__Conga_Template__c newCongaTemplate {get; set;}
    public List<String> countryList {get; set;}

    // initialize the controller
    public bg_CongaTemplateCloneWithItemsController(ApexPages.StandardController controller) 
    {

        //initialize the stanrdard controller
        this.controller = controller;
        // load the current record
        congaTemplate = (APXTConga4__Conga_Template__c)controller.getRecord();
        cloneWithItems();
        countryList = new List<String>();
        if (!String.isEmpty(congaTemplate.Country__c))
        {
            countryList = congaTemplate.Country__c.Split(',');
        }
    }

    public void cloneWithItems() 
    {
        try 
        {
            //copy the Template - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
            congaTemplate = bg_DocumentUtils.GetCongaTemplate(congaTemplate.id);
            newCongaTemplate = congaTemplate.clone(false);
        } 
        catch (Exception e)
        {
            ApexPages.addMessages(e);
        }
    }

    // method called from the VF's action attribute to clone the template and queries
    public PageReference save() 
    {
        // setup the save point for rollback
        Savepoint sp = Database.setSavepoint();
        try 
        {
            newCongaTemplate.Country__c = String.join(countryList, ',');
            insert newCongaTemplate;

            // set the id of the new po created for testing
            newRecordId = newCongaTemplate.id;
            // copy over the queries - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
            List<Template_Queries__c> templateQueries = new List<Template_Queries__c>();
            for (Template_Queries__c templateQuery : bg_DocumentUtils.GetCongaQueryIdsByTemplateID(congaTemplate.id)) 
            {
                Template_Queries__c newTemplateQuery = templateQuery.clone(false);
                newTemplateQuery.Conga_Template__c = newCongaTemplate.id;
                // strip off the first 2 letters and replace with new language
                // newTemplateQuery.Name = newCongaTemplate.Language__c + newTemplateQuery.Name.substring(2);
                newTemplateQuery.CurrencyIsoCode = newCongaTemplate.CurrencyIsoCode;

                templateQueries.add(newTemplateQuery);
            }
            insert templateQueries;
        } 
        catch (Exception e)
        {
            // roll everything back in case of error
            Database.rollback(sp);
            ApexPages.addMessages(e);
            newCongaTemplate.Id = null;
            return null;
        }
        return new PageReference('/'+newCongaTemplate.id);
    }

    public List<SelectOption> getCountries()
    {
        return bg_DocumentUtils.getCountries();
    }
    
    public List<SelectOption> getLanguages()
    {
        return bg_DocumentUtils.getLanguages();
    }

    public List<SelectOption> getCurrency()
    {
        return bg_DocumentUtils.getCurrency();
    }

    /*public List<SelectOption> getCountries()
    {
        List<SelectOption> options = new List<SelectOption>();
            
        Schema.DescribeFieldResult fieldResult = APXTConga4__Conga_Template__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }       
        return options;
    }

    public List<SelectOption> getLanguages()
    {
        List<SelectOption> options = new List<SelectOption>();
            
        Schema.DescribeFieldResult fieldResult = APXTConga4__Conga_Template__c.Language__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }       
        return options;
    }
    public List<SelectOption> getCurrency()
    {
        List<SelectOption> options = new List<SelectOption>();
            
        Schema.DescribeFieldResult fieldResult = APXTConga4__Conga_Template__c.CurrencyIsoCode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }       
        return options;
    }*/
}