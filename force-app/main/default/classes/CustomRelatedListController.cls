/**
 * @Name:        CustomRelatedListController
 * @Description: Aura Controller class to handle server side operations of c:customRelatedList2 component
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 03/01/2018   Andrei Budescu     Created Class
 */
public without sharing class CustomRelatedListController {
    public static final String TYPE_LIST_VIEW            = 'List View';
    public static final String TYPE_RELATED_LIST_VIEW    = 'Related List';
    public static final List<String> OBJECT_STRING_FIRST_COL_NO_CLICKABLE    = new List<String>{'Step_Progress__c','Competency__c'};

    /**
     * To initialise the c:customRelatedList component
     *
     * @param initialiseRequest String of JSON Object including recordId, fieldsString, objectString, etc.
     *
     * @return String of a serialised JSON object in the structure of RelatedListResponse wrapper class
     */
    @AuraEnabled
    public static String initialiseComponent(String initialiseRequest) {
        RelatedListResponse response;
        List<Object> columns = new List<Object>();
        List<Object> data = new List<Object>();
        String fields;

        // parse query attributes from LEX component request
        RelatedListRequest request = ((RelatedListRequest) JSON.deserialize(initialiseRequest, RelatedListRequest.class)).trim();
        fields = request.fieldsString;
        data = getRecordsByPicklistFilter(request.recordId, request.type, Constants.BLANK_STRING, Constants.BLANK_STRING, fields, request.objectString, request.parentObject, request.whereString, request.orderByString, request.urlExtension);
        if (request.fieldsString.contains('Online_Training_Assigned_Date__c') && request.fieldsString.contains('Start_Date__c') &&
            request.fieldsString.contains('Online_Training_Expiry_Date__c') && request.fieldsString.contains('End_Expiry_Date__c')) {
            
                fields = fields.remove('Online_Training_Assigned_Date__c,');
                fields = fields.remove('Online_Training_Expiry_Date__c,');
                data = SubsituteFieldsLabel(data);
        }
        columns = getColumnHeadingsDynamically(request.recordId, request.type, request.urlExtension, request.whereString, fields, request.objectString, request.parentObject, request.editableFields);
        
        response = new RelatedListResponse(columns, data);
        
        System.debug('request: ' + request);
        System.debug('fields String: ' + request.fieldsString);
        //columns = getColumnHeadingsDynamically(request.recordId, request.type, request.whereString, request.fieldsString, request.objectString, request.parentObject, request.editableFields);
        //data = getRecordsByPicklistFilter(request.recordId, Constants.BLANK_STRING, Constants.BLANK_STRING, request.fieldsString, request.objectString, request.parentObject, request.whereString, request.orderByString);
        System.debug('Request recordid: ' + request.recordId);
        System.debug('response='+JSON.serializePretty(response));

        return JSON.serializePretty(response, true);

    }

    /**
     * To get the Column definitions as accepted by lightning:datatable
     *
     * @param fieldsString String of comma-separated Field API Names
     * @param objectString String of SObject API Names
     * @param parentObject String of Parent SObject API Names
     * @param recordId     String - recordId of the current record
     *
     * @return List of Column Headings
     */
    private static List<Object> getColumnHeadingsDynamically(String recordId, String type, String urlExtension, String whereString, String fieldsString, String objectString, String parentObject, String editableFields) {
        List<Object> columns = new List<Object>();
        System.debug(recordId);

        //  
        try{
            // replace all spaces and split String by comma
            List<String> fields = fieldsString.replaceAll('\\s+', '').split(',');

            List<String> editableFieldsList = new List<String>();
            /*if (fieldsString.contains('Status__c')) {
                system.debug('Came here');
                fieldsString = fieldsString.replace('Status__c', 'toLabel(Status__c)');
            }
            system.debug('fieldsString='+fieldsString);*/

            String queryString = '';
            if(type == TYPE_LIST_VIEW){
                //get columns and lookup fields
                queryString = Constants.QUERY_SELECT + 'Id,' + fieldsString;
                queryString += Constants.QUERY_FROM + objectString;
                if (String.isNotBlank(whereString)) {
                    queryString += Constants.QUERY_WHERE + whereString + ' LIMIT 1';
                }else{
                    queryString += ' LIMIT 1';
                }
                System.debug(queryString);
            } else if(type == TYPE_RELATED_LIST_VIEW){
                //get columns and lookup fields
                queryString = Constants.QUERY_SELECT + 'Id,' + fieldsString;
                queryString += Constants.QUERY_FROM + objectString;
                if (String.isNotBlank(whereString)) {
                    queryString += Constants.QUERY_WHERE + whereString + ' AND ' + parentObject +' = ' + '\''+ recordId + '\'' + ' LIMIT 1';
                }
                System.debug(queryString);

                //remove dot for the editable fields
                editableFields = editableFields.replaceAll('\\.', '');
                System.debug(editableFields);
                //list of editable fields
                editableFieldsList = editableFields.replaceAll('\\s+', '').split(',');
                System.debug(editableFieldsList);
            }

            SObject sObjQueried = Database.query(queryString);
            System.debug(sObjQueried);

            Map<String, SObjectField> describeFields = Schema.getGlobalDescribe().get(objectString).getDescribe().fields.getMap();

            for(String field : fields) {
                Map<String, Object> column = new Map<String, Object>();
                // for first column
                if(columns.isEmpty() && type == TYPE_LIST_VIEW && !OBJECT_STRING_FIRST_COL_NO_CLICKABLE.contains(objectString)) {
                    
                    column.put('label', describeFields.get(field).getDescribe().getLabel());
                    column.put('fieldName', 'customUrl');
                    column.put('type', 'url');
                    column.put('sortable', false);
                    column.put('typeAttributes', new Map<String, Object> {
                            'label' => new Map<String, String> { 'fieldName' => field },
                            'target' => '_self'
                    });
                }else{
                    if(field.contains('.')){
                        // subsequent columns (not the first)
                        SObject childObj = getSObjectFromFieldName(sObjQueried, field);
                        System.debug(childObj.getSObjectType());
                        Map<String, SObjectField> describeFieldsChildObj = Schema.getGlobalDescribe().get(String.valueOf(childObj.getSObjectType())).getDescribe().fields.getMap();
                        System.debug(describeFieldsChildObj);
                    
                        column.put('label', describeFieldsChildObj.get(field.substringAfterLast('.')).getDescribe().getLabel()); 
                        System.debug(describeFieldsChildObj.get(field.substringAfterLast('.')).getDescribe().getLabel());
                        column.put('fieldName', field.replaceAll('\\.', '')); 
                        System.debug(field.replaceAll('\\.', ''));
                        column.put('type', 'text');
                        
                        column.put('sortable', false);
    
                        // specify datatype specific column definition
                        String dataType = String.valueOf(describeFieldsChildObj.get(field.substringAfterLast('.')).getDescribe().getType()).toLowerCase();
                        if(dataType == 'boolean') {
                            column.put('type', 'boolean');
                        }else if(dataType == 'double'){
                            column.put('type', 'number');
                        }else if(dataType == 'datetime') {
                            column.put('type', 'date');
                            column.put('typeAttributes', Constants.DATA_TABLE_DATETIME_FORMAT);
                        }
                        if(!editableFieldsList.isEmpty() && editableFieldsList.contains(field.replaceAll('\\.', ''))){
                            column.put('editable', true);
                        }
                        System.debug(column);
                    
                    }else{
                        // subsequent columns (not the first)
                        column.put('label', describeFields.get(field).getDescribe().getLabel());
                        column.put('fieldName', field);
                        column.put('type', 'text');
                        column.put('sortable', false);
                        //column.put('initialWidth', 5);
                        // specify datatype specific column definition
                        String dataType = String.valueOf(describeFields.get(field).getDescribe().getType()).toLowerCase();
                        if(dataType == 'boolean') {
                            column.put('type', 'boolean');
                        }else if(dataType == 'double'){
                            column.put('type', 'number');
                        }else if(dataType == 'datetime') {
                            column.put('type', 'date');
                            column.put('typeAttributes', Constants.DATA_TABLE_DATETIME_FORMAT);
                        }
                        if(!editableFieldsList.isEmpty() && editableFieldsList.contains(field.replaceAll('\\.', ''))){
                            column.put('editable', true);
                        }
                        System.debug(column);
                    }
                }

                columns.add(column);
                System.debug(columns);
            }
 
        } catch (Exception e) {
            // skip silently
        }
        return columns;
    }  

    /**
     * To query a list of records by dynamically specified fields, object, where filter with custom ordering
     *
     * @param picklistValue String Name of topic (Multi-Select) to query
     * @param fieldsString String fields to show in the Related List
     * @param objectString String object to query for the Related List
     * @param parentObject String parent object to query for the Related List
     * @param whereString String filter that shall be included in the WHERE statement
     * @param orderByString String to order records by
     *
     * @return List of Objects which includes the queried SObjects + an additional customUrl attribute used by the name link
     */
    private static List<Object> getRecordsByPicklistFilter(String recordId, String type, String picklistField, String picklistValue, String fieldsString, String objectString, String parentObject, String whereString, String orderByString, String urlExtension) {
        List<Object> returnList = new List<Object>();

        try {
            // replace all spaces and split String by comma
            List<String> fields = fieldsString.replaceAll('\\s+', '').split(',');

            String queryString = '';

            if(type == TYPE_LIST_VIEW){
                queryString = Constants.QUERY_SELECT + 'Id,' + fieldsString;
                queryString += Constants.QUERY_FROM + objectString;
                if (String.isNotBlank(whereString)) {
                    queryString += Constants.QUERY_WHERE + whereString;
                    if(String.isNotBlank(orderByString)){
                        queryString += Constants.QUERY_ORDER_BY + orderByString + ' LIMIT 100';
                    }
                }else{
                    if(String.isNotBlank(orderByString)){
                        queryString += Constants.QUERY_ORDER_BY + orderByString + ' LIMIT 100';
                    }
                } 
                System.debug(queryString);

            }else if(type == TYPE_RELATED_LIST_VIEW){
                queryString = Constants.QUERY_SELECT + 'Id,' + fieldsString;
                queryString += Constants.QUERY_FROM + objectString;
                if (String.isNotBlank(whereString)) {
                    queryString += Constants.QUERY_WHERE + whereString + ' AND ' + parentObject + ' = ' + '\''+ recordId + '\''; 
                    if(String.isNotBlank(orderByString)){
                        queryString += Constants.QUERY_ORDER_BY + orderByString;
                    }
                } 
            }
            //String communityName = Label.CLP_Community_Name;
            Network myNetwork = [Select Id FROM Network WHERE Name = :Label.CLP_Community_Name];
            String communityUrl = Network.getLoginUrl(myNetwork.Id).removeEnd('login');
            for (SObject sobj : Database.query(queryString)) {
                Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sobj));
                if(type == TYPE_LIST_VIEW){
                    objMap.put('customUrl', communityUrl + urlExtension + '/' + sobj.get('Id'));
                }
                for(String field : fields){
                    if(field.contains('.')){
                        Object objV = getFieldFromFieldName(sobj, field);
                        objMap.put(field.replaceAll('\\.', ''), String.valueOf(objV));
                    }
                }
                
                returnList.add(objMap);
            }
            System.debug(returnList);

            
        } catch (Exception e) {
            // skip silently
        }
        return returnList;
    }

    private static Map<String, String> getFieldRelationship(String listFields){
        Map<String, String> apiNamesByColumnName = new Map<String, String>();
        List<String> fields = listFields.replaceAll('\\s+', '').split(',');
        for(String field : fields){
            apiNamesByColumnName.put(field.replaceAll('\\.', ''), field);
        }

        return apiNamesByColumnName;
    }

    private static SObject getSObjectFromFieldName(SObject objectQuery, String fieldRelationship){
        
        SObject childObj = objectQuery;

        if(fieldRelationship.contains('.')){
            for(Integer i=0; i < fieldRelationship.split('\\.').size() - 1; i++){
                childObj = childObj.getSObject(fieldRelationship.split('\\.')[i]);
            }
        }

        return childObj;
    }

    private static Object getFieldFromFieldName(SObject objectQuery, String fieldRelationship){
        
        SObject childObj = objectQuery;
        String fieldName = fieldRelationship;
        
        if(fieldRelationship.contains('.')){
            fieldName = fieldRelationship.substringAfterLast('.');
            for(Integer i=0; i < fieldRelationship.split('\\.').size() - 1; i++){
                childObj = childObj.getSObject(fieldRelationship.split('\\.')[i]);
            }
            
        }
        return childObj.get(fieldName);
    }

    @AuraEnabled
    public static void updateRecords(String draftValues, String fieldList, String objectString){
        System.debug(draftValues);
        System.debug(objectString);
        System.debug(fieldList);

        //fix for invalid Double (null)
        draftValues = draftValues.replaceAll('"Exam_Mark__c":""', '"Exam_Mark__c":"0"');
        
        // replace all spaces and split String by comma
        List<String> fields = fieldList.replaceAll('\\s+', '').split(',');
        System.debug(fields);

        //list of objects updated front-end - draft values
        List<Object> listObject = (List<Object>) JSON.deserializeUntyped(draftValues);
        System.debug(listObject);

        //map with api names of fields from the datatable
        Map<String, String> mapFieldsColumns = getFieldRelationship(fieldList);
        System.debug(mapFieldsColumns);
       
        //list of sobject to update
        List<SObject> recordsToUpdate = new List<SObject>();
        
        //set of ids os sobject to be updated
        Set<Id> setObjIds = new Set<Id>();

        //list of fields to query the object
        List<String> fieldRelationship = new List<String>();

        for(Object obj : listObject){
            //map of fields of the object returned (draft value)
            Map<String, Object> mapObject = (Map<String, Object>) obj;
            system.debug(mapObject);
            
            //field of object matches api names of fields from the table -> query
            for(String key : mapObject.keySet()){
                for(String keyField : mapFieldsColumns.keySet()){
                    if(key == keyField){
                        if(!fieldRelationship.contains(mapFieldsColumns.get(key))){
                            fieldRelationship.add(mapFieldsColumns.get(key));
                        }
                    }
                }
            }
            setObjIds.add(String.valueOf(mapObject.get('recordId')));
            
        }
        System.debug(fieldRelationship);
        //fields to query
        String queryFields = String.join(fieldRelationship, ',');
        //query the record using the record id from the map of the object returned by the draft value
        String queryString = Constants.QUERY_SELECT + 'Id,' + queryFields;
        queryString += Constants.QUERY_FROM + objectString;
        queryString += Constants.QUERY_WHERE + ' Id ' + ' IN :setObjIds';

        Map<Id, SObject> recordsQueried = new Map<Id, SObject>(Database.query(queryString));
        
        for(Object obj : listObject){
            //map of fields of the object returned (draft value)
            Map<String, Object> mapObject = (Map<String, Object>) obj;

            String recordId = String.valueOf(mapObject.get('recordId'));
            for(String field : fieldRelationship){
                SObject childObj = getSObjectFromFieldName(recordsQueried.get(recordId), field);

                Map<String, SObjectField> describeFieldsChildObj = Schema.getGlobalDescribe().get(String.valueOf(childObj.getSObjectType())).getDescribe().fields.getMap();

                String fieldToUpdate = field;
                String fieldMapObject = field;
                if(field.contains('.')){
                    fieldToUpdate = field.substringAfterLast('.');
                    fieldMapObject =field.replaceAll('\\.', '');
                }

                if(mapObject.get(fieldMapObject) != null){
                    System.debug(mapObject.get(fieldMapObject));
                    System.debug(fieldToUpdate);
                    if(String.valueOf(describeFieldsChildObj.get(fieldToUpdate).getDescribe().getType()) == 'DOUBLE'){
                        childObj.put(fieldToUpdate, Double.valueOf(mapObject.get(fieldMapObject)));
                    }else{
                        System.debug(describeFieldsChildObj.get(fieldToUpdate).getDescribe().getType());
                        childObj.put(fieldToUpdate, mapObject.get(fieldMapObject));
                    }
                }
                
                if(!recordsToUpdate.contains(childObj)){
                    recordsToUpdate.add(childObj);
                }
            }
        }
                
            
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }


    }

    public class RelatedListRequest {

        public String recordId;
        public String type;
        public String fieldsString;
        public String objectString;
        public String parentObject;
        public String whereString;
        public String orderByString;
        public String editableFields;
        public String urlExtension;

        public RelatedListRequest trim() {

            recordId = trimValue(recordId);
            type = trimValue(type);
            fieldsString = trimValue(fieldsString);
            objectString = trimValue(objectString);
            parentObject = trimValue(parentObject);
            whereString = trimValue(whereString);
            orderByString = trimValue(orderByString);
            editableFields = trimValue(editableFields);
            urlExtension = trimValue(urlExtension);

            return this;
        }

        private String trimValue(String value) {
            if(String.isBlank(value)) {
                value = Constants.BLANK_STRING;
            }

            return value.trim();
        }

    }

    /**
     * RelatedListResponse Wrapper class to return data from Apex to c:customRelatedList Aura component
     */
    public class RelatedListResponse {

        @AuraEnabled public List<Object> columns { get; private set; }
        @AuraEnabled public List<Object> data { get; private set; }

        public RelatedListResponse(List<Object> columns, List<Object> data) {
            this.columns = columns;
            this.data = data;
        }

    }
    
    private static List<Object> SubsituteFieldsLabel(List<Object> data) {
        List<Map<String, Object>> resultColumn = new List<Map<String, Object>>();
        List<Object> result = new List<Object>();
        for(Object item: data) {
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(item));
            if (dataMap.containsKey('Online_Training_Assigned_Date__c') && dataMap.containsKey('Online_Training_Expiry_Date__c') &&
                (dataMap.get('Learning_Type__c') == 'Online Training' || dataMap.get('Learning_Type__c') == 'Online Exam')) {
                    dataMap.put('Start_Date__c', String.valueof(dataMap.get('Online_Training_Assigned_Date__c')).substring(0,10));
                    dataMap.put('End_Expiry_Date__c', String.valueof(dataMap.get('Online_Training_Expiry_Date__c')).substring(0,10));
            }
            result.add(dataMap);
        }
        return result; 
    }


}