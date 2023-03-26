/**
 * Author       : Kevin Antonioli (braveitnow@pm.me)
 * Description  : Utility class for common operations
 * Created      : 12.29.2021
 *
 * Revisions:
 * Date : Name : Notes
 * 03.10.2023 : Kevin Antonioli (braveitnow@pm.me) : Optimize methods
 */
public without sharing class ApexUtils {
  private static final String ID_STR = 'Id';

  @TestVisible
  private static Map<String, Schema.SObjectType> private_globalDescribe;
  // variable to get global describe and cache it in memory
  public static Map<String, Schema.SObjectType> globalDescribe {
    get {
      if (private_globalDescribe == null) {
        private_globalDescribe = Schema.getGlobalDescribe();
      }
      return private_globalDescribe;
    }
    private set;
  }

  @TestVisible
  private static String private_instanceURL;
  // variable to get the instance URL (ex: https://xyzcompany.my.salesforce.com)
  public static String instanceURL {
    get {
      if (private_instanceURL == null) {
        private_instanceURL = System.URL.getSalesforceBaseURL()
          .toExternalForm();
      }
      return private_instanceURL;
    }
    private set;
  }

  @TestVisible
  private static Boolean private_isSandboxFlag;
  // variable to determine if we're in a sandbox org
  public static Boolean runningInASandbox {
    get {
      if (private_isSandboxFlag == null) {
        private_isSandboxFlag = [SELECT IsSandbox FROM Organization LIMIT 1]
        .IsSandbox;
      }
      return private_isSandboxFlag;
    }
    private set;
  }

  @TestVisible
  private static Profile private_loggedInUserProfile;
  // variable method/variable to get the logged in user profile
  public static Profile loggedInUserProfile {
    get {
      if (private_loggedInUserProfile == null) {
        private_loggedInUserProfile = [
          SELECT Id, Name
          FROM Profile
          WHERE Id = :Userinfo.getProfileId()
        ];
      }
      return private_loggedInUserProfile;
    }
    private set;
  }

  /**
   * @description   Get environment short name from url.
   * Example:
   *   For instance URL: https://xyzcompany.my.salesforce.com
   *   This method will return 'xyzcompany'
   * @param         null
   * @return        String of the environment name
   */
  public static String getEnvironmentName() {
    return instanceURL.substringBetween('https://', '.my.salesforce.com');
  }

  /**
   * @description   Get all fields for an sobject as a list - helpful for dynamic SOQL
   * @param         objApiName  : the object name to get the fields for
   * @return        allFields    : of all fields for the object;
   */
  public static List<String> getAllFieldsForSobj(String objApiName) {
    List<String> allFields = new List<String>(getFieldMap(objApiName).keySet());
    return allFields;
  }

  /**
   * @description   Get all fields for an sobject as a comma-delimited string - helpful for dynamic SOQL
   * @param         objApiName  : the object name to get the fields for
   * @return        String       : comma delimited string of all fields for the object delimited by commas
   */
  public static String getAllFieldsForSObjAsStr(String objApiName) {
    return String.join(getAllFieldsForSobj(objApiName), ', ');
  }

  /**
   * @description   Get all fields for an sobject as a list, except those in the blacklist
   * @param         objApiName  : the object name to get the fields for
   * @param         blackList    : a list of fields to exclude
   * @return        List<String> : a list of all fields (except blacklist) for an SObject
   */
  public static List<String> getAllFieldsExceptBlacklist(
    String objApiName,
    List<String> blackList
  ) {
    Set<string> fields = new Set<String>(getAllFieldsForSobj(objApiName));
    for (String blackListedField : blackList) {
      if (fields.contains(blackListedField)) {
        fields.remove(blackListedField);
      } else if (fields.contains(blackListedField.toLowerCase())) {
        fields.remove(blackListedField.toLowerCase());
      }
    }
    return new List<String>(fields);
  }

  /**
   * @description   Get all fields (except blacklist) for an sobject as a comma-delimited string - helpful for dynamic SOQL
   * @param         objApiName  : the SOBbject name to get the fields for
   * @param         blackList    : a list of fields to exclude
   * @return        String       : comma delimited string of all fields for the SObject (except blacklist)
   */
  public static String getAllFieldsExceptBlacklistAsStr(
    String objApiName,
    List<String> blackList
  ) {
    return String.join(
      getAllFieldsExceptBlacklist(objApiName, blackList),
      ', '
    );
  }

  /**
   * Method to return list of creatable fields for a given object.
   * @param String objApiName
   * @return List of creatable fields for a given SObject.
   */
  public static List<String> getCreatableFields(String objApiName) {
    // Get a map of field name and field token
    Map<String, Schema.SObjectField> fieldMap = getFieldMap(objApiName);

    List<String> creatableFields = new List<String>();
    if (fieldMap != null) {
      for (Schema.SObjectField fieldSchema : fieldMap.values()) {
        Schema.DescribeFieldResult fieldDescribe = fieldSchema.getDescribe(); // describe each field (fd)
        if (
          fieldDescribe.isCreateable() &&
          !(fieldDescribe.isExternalId() && fieldDescribe.isAutoNumber())
        ) {
          // field is creatable
          creatableFields.add(fieldDescribe.getName());
        }
      }
    }
    return creatableFields;
  }

  /**
   * @description   Get all creatable fields for an sobject as a comma-delimited string - helpful for dynamic SOQL
   * @param         objApiName  : the object name to get the fields for
   * @return        String       : comma delimited string of all creatable fields for the object delimited by commas
   */
  public static String getCreatableFieldsAsStr(String objApiName) {
    return String.join(getCreatableFields(objApiName), ', ');
  }

  /**
   * @description: get all updateable fields for an sobject as a list
   * @param  objApiName        API name of SObject to get updateable fields for
   * @return updateableFields   List of updateable fields for a given SObject.
   */
  public static List<String> getUpdateableFields(String objApiName) {
    // Get a map of field name and field token
    Map<String, Schema.SObjectField> fieldMap = getFieldMap(objApiName);

    List<String> updateableFields = new List<String>();
    if (fieldMap != null) {
      for (Schema.SObjectField fieldSchema : fieldMap.values()) {
        Schema.DescribeFieldResult fieldDescribe = fieldSchema.getDescribe(); // describe each field (fd)
        if (
          fieldDescribe.isUpdateable() &&
          !(fieldDescribe.isExternalId() && fieldDescribe.isAutoNumber())
        ) {
          // field is updateable
          updateableFields.add(fieldDescribe.getName());
        }
      }
    }
    return updateableFields;
  }

  /**
   * @description   get all updateable fields for an sobject as a comma-delimited string - helpful for dynamic SOQL
   * @param         objApiName  : the object name to get the fields for
   * @return        String       : comma delimited string of all updateable fields for the object delimited by commas
   */
  public static String getUpdateableFieldsAsStr(String objApiName) {
    return String.join(getUpdateableFields(objApiName), ', ');
  }

  /**
   * @description   given an integer, generate a random string of its length
   * @param   length  How long to make the string
   * @return  String  randomly generated string
   */
  public static String randomString(Integer length) {
    String key = EncodingUtil.base64encode(crypto.generateAesKey(192));
    return key.substring(0, length);
  }

  /**
   * @description   validate that a string is in Salesforce id format
   * @param   Idparam   How long to make the string
   * @return  Boolean   whether id is valid or not
   */
  public static Boolean isIdValid(String Idparam) {
    String id = String.escapeSingleQuotes(Idparam);
    return (Idparam instanceof ID) &&
      (id.length() == 15 ||
      id.length() == 18) &&
      Pattern.matches('^[a-zA-Z0-9]*$', id);
  }

  /**
   * @desciption: Format a date using the format options offered with a Datetime
   *  Format options: https://docs.oracle.com/javase/7/docs/api/java/text/SimpleDateFormat.html
   * @param   d         Date to format
   * @param   format    format to apply to Date (ex: 'yyyy-MM-dd')
   * @return  String    formatted date as a string
   */
  public static String formatDate(Date d, String format) {
    if (d == null) {
      return null;
    }
    return DateTime.newInstance(d, Time.newInstance(1, 0, 0, 0)).format(format);
  }

  /**
   * @desciption: given a list of SObjects and a date field, get the earliest date from those SObjects
   * @param   records   records to analyze and pull earliest date rom
   * @param   field     Date field to use
   * @return  Date      earliest date
   */
  public static Date getEarliestDate(
    List<SObject> items,
    Schema.SObjectField field
  ) {
    return getEarliestDate(items, field, Date.today());
  }
  public static Date getEarliestDate(
    List<SObject> items,
    Schema.SObjectField field,
    Date defaultIfNull
  ) {
    Date outputDate;
    for (SObject obj : items) {
      try {
        if (outputDate == null || outputDate > (Date) obj.get(field)) {
          outputDate = (Date) obj.get(field);
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    outputDate = outputDate != null ? outputDate : defaultIfNull;
    return outputDate;
  }

  /**
   * @desciption: given a list of SObjects and a date field, get the latest date from those SObjects
   * @param   records   records to analyze and pull latest date rom
   * @param   field     Date field to use
   * @return  Date      latest date
   */
  public static Date getLatestDate(
    List<SObject> records,
    Schema.SObjectField field
  ) {
    return getLatestDate(records, field, Date.today());
  }
  public static Date getLatestDate(
    List<SObject> records,
    Schema.SObjectField field,
    Date defaultIfNull
  ) {
    Date outputDate;
    for (SObject obj : records) {
      try {
        if (outputDate == null || outputDate < (Date) obj.get(field)) {
          outputDate = (Date) obj.get(field);
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    outputDate = outputDate != null ? outputDate : defaultIfNull;
    return outputDate;
  }

  /**
   * Find a record where a date is between a start/end date on a given record
   * This method is useful to find a record that exists within some defined range of another set of records
   *
   * @param items
   * @param valueToCompare Date to compare against, usually obtained from a record
   * @param startDateField Field containing a start date
   * @param endDateField field containing an end date
   * @param isInclusive [*optional] Defaults = true. IF true, this uses <= and >= instead of < and >
   *
   * @return
   */
  public static SObject findRecWithDateBetween(
    List<SObject> items,
    Date valueToCompare,
    Schema.SObjectField startDateField,
    Schema.SObjectField endDateField
  ) {
    return findRecWithDateBetween(
      items,
      valueToCompare,
      startDateField,
      endDateField,
      true
    );
  }
  public static SObject findRecWithDateBetween(
    List<SObject> items,
    Date valueToCompare,
    Schema.SObjectField startDateField,
    Schema.SObjectField endDateField,
    Boolean isInclusive
  ) {
    for (SObject obj : items) {
      try {
        if (isInclusive) {
          if (
            valueToCompare >= (Date) obj.get(startDateField) &&
            valueToCompare <= (Date) obj.get(endDateField)
          ) {
            return obj;
          }
        } else {
          if (
            valueToCompare > (Date) obj.get(startDateField) &&
            valueToCompare < (Date) obj.get(endDateField)
          ) {
            return obj;
          }
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return null;
  }

  /**
   * For a given record, compare a decimal field to see if record is between a range of two fields
   * Example: If you have an object with "Start" and "End" (as decimals), then you can pass in a number and find the record that matches that range
   * This is useful when you are working with many records, so you need to perform multiple matches, thus cannot use SOQL to target just one record
   *
   * This method returns the first match, and not multiple matches. Ensure that your orders are sorted appropriately.
   *
   * @param items
   * @param valueToCompare Date to compare against, usually obtained from a record
   * @param startField Field containing a start decimal
   * @param endField Field containing an end decimal
   * @param startIsInclusive [*optional] Defaults = true. If true, this uses <= and >= instead of < and >
   * @param endIsInclusive [*optional] Defaults = true. If true, this uses <= and >= instead of < and >
   * @param allowNullEnd [*optional] Defaults = false. If true, this allows end field to be null
   *
   * @return
   */
  public static SObject findRecWithDecimalBetween(
    List<SObject> items,
    Decimal valueToCompare,
    Schema.SObjectField startField,
    Schema.SObjectField endField
  ) {
    return findRecWithDecimalBetween(
      items,
      valueToCompare,
      startField,
      endField,
      true,
      true
    );
  }
  public static SObject findRecWithDecimalBetween(
    List<SObject> items,
    Decimal valueToCompare,
    Schema.SObjectField startField,
    Schema.SObjectField endField,
    Boolean startIsInclusive,
    Boolean endIsInclusive
  ) {
    return findRecWithDecimalBetween(
      items,
      valueToCompare,
      startField,
      endField,
      startIsInclusive,
      endIsInclusive,
      false
    );
  }
  public static SObject findRecWithDecimalBetween(
    List<SObject> items,
    Decimal valueToCompare,
    Schema.SObjectField startField,
    Schema.SObjectField endField,
    Boolean startIsInclusive,
    Boolean endIsInclusive,
    Boolean allowNullEnd
  ) {
    for (SObject obj : items) {
      try {
        if (startIsInclusive) {
          if (endIsInclusive) {
            if (allowNullEnd) {
              if (
                valueToCompare >= (Decimal) obj.get(startField) &&
                (obj.get(endField) == null ||
                valueToCompare <= (Decimal) obj.get(endField))
              ) {
                return obj;
              }
            } else {
              if (
                valueToCompare >= (Decimal) obj.get(startField) &&
                (obj.get(endField) != null &&
                valueToCompare <= (Decimal) obj.get(endField))
              ) {
                return obj;
              }
            }
          } else {
            if (allowNullEnd) {
              if (
                valueToCompare >= (Decimal) obj.get(startField) &&
                (obj.get(endField) == null ||
                valueToCompare < (Decimal) obj.get(endField))
              ) {
                return obj;
              }
            } else {
              if (
                valueToCompare >= (Decimal) obj.get(startField) &&
                (obj.get(endField) != null &&
                valueToCompare < (Decimal) obj.get(endField))
              ) {
                return obj;
              }
            }
          }
        } else {
          if (endIsInclusive) {
            if (allowNullEnd) {
              if (
                valueToCompare > (Decimal) obj.get(startField) &&
                (obj.get(endField) == null ||
                valueToCompare <= (Decimal) obj.get(endField))
              ) {
                return obj;
              }
            } else {
              if (
                valueToCompare > (Decimal) obj.get(startField) &&
                (obj.get(endField) != null &&
                valueToCompare <= (Decimal) obj.get(endField))
              ) {
                return obj;
              }
            }
          } else {
            if (allowNullEnd) {
              if (
                valueToCompare > (Decimal) obj.get(startField) &&
                (obj.get(endField) == null ||
                valueToCompare < (Decimal) obj.get(endField))
              ) {
                return obj;
              }
            } else {
              if (
                valueToCompare > (Decimal) obj.get(startField) &&
                (obj.get(endField) != null &&
                valueToCompare < (Decimal) obj.get(endField))
              ) {
                return obj;
              }
            }
          }
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return null;
  }

  /**
   * @description   generate a UUID in the followng format: ce7f2e9d-70b1-4264-9ad6-5c4f9ee5f0c8
   * @param         null
   * @return        guid
   */
  public static String generateUUID() {
    String h = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));
    String guid =
      h.SubString(0, 8) +
      '-' +
      h.SubString(8, 12) +
      '-' +
      h.SubString(12, 16) +
      '-' +
      h.SubString(16, 20) +
      '-' +
      h.substring(20);
    return guid;
  }

  /**
   * @description: method to return files associated to a record
   * @param   parentRecordId  : the id of record we're retrieving files for
   * @param   fileExtension   : Optional file extension to filter by, optional
   * @return  cvList          : list of files associated to record
   */
  public static List<ContentVersion> getFilesOnRecord(Id parentRecordId) {
    return getFilesOnRecord(parentRecordId, null);
  }
  public static List<ContentVersion> getFilesOnRecord(
    Id parentRecordId,
    String fileExtensionParam
  ) {
    Set<Id> cdIds = new Set<Id>();
    for (ContentDocumentLink cdl : [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :parentRecordId
    ]) {
      cdIds.add(cdl.ContentDocumentId);
    }

    List<ContentVersion> cvList = new List<ContentVersion>();
    for (ContentVersion cv : [
      SELECT ContentDocumentId, Title, VersionData
      FROM ContentVersion
      WHERE ContentDocumentId IN :cdIds
    ]) {
      // if specific file extension specified, filter by it:
      if (fileExtensionParam != null) {
        String fileExtension = cv.Title.substringAfterLast('.');
        if (fileExtension == fileExtensionParam) {
          cvList.add(cv);
        }
      } else {
        cvList.add(cv);
      }
    }
    return cvList;
  }

  /**
   * @description: Given a list and an SObjectField, return a set of the extracted ids
   *  (Example: Given a list of contacts where prop=Contact.AccountId, return a set of the account ids)
   * @param   records a list of SObject records to extract ids from
   * @param   prop    id field (ex: AccountId) to derive the id values from
   * @return  ids     set of extracted ids
   */
  public static Set<Id> pluckIdSet(
    List<SObject> records,
    Schema.SObjectField prop
  ) {
    Set<Id> ids = new Set<Id>();
    for (SObject obj : records) {
      try {
        if (obj.get(prop) != null) {
          ids.add((Id) obj.get(prop));
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return ids;
  }

  /**
   * Given a list and a string property (of an ID field), return a set of the extracted ids
   * (Example: Given a list of contacts where prop='AccountId', return a set of the account Id's)
   * This method allows relationships - Ex. 'Account.CreatedBy.Id'
   * @param  records  a list of SObject records to extract ids from
   * @param  prop     id field (ex: AccountId) to derive the id values from
   * @return ids      set of extracted ids
   */
  public static Set<Id> pluckIdSet(List<SObject> records, String prop) {
    Set<Id> ids = new Set<Id>();
    for (SObject obj : records) {
      try {
        if (prop.contains('.')) {
          SObject currObj = obj;
          for (String field : prop.split('\\.')) {
            try {
              currObj = (SObject) currObj.getSobject(field);
            } catch (Exception ex) {
              ids.add((Id) currObj.get(field));
            }
          }
        } else if (obj.get(prop) != null) {
          ids.add((Id) obj.get(prop));
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return ids;
  }

  /**
   * Given a list and a string property (of a String field), return a set of the extracted values
   * (Example: Given a list of contacts where prop=Contact.FirstName, return a set of the contacts first name)
   * @param  records  a list of SObject records to extract values from
   * @param  prop     field (ex: Contact.FirstName) to derive the values from
   * @return ids      set of extracted ids
   */
  public static Set<String> pluckStringSet(
    List<SObject> records,
    Schema.SObjectField prop
  ) {
    Set<String> strings = new Set<String>();
    for (SObject obj : records) {
      try {
        if (obj.get(prop) != null) {
          strings.add((String) obj.get(prop));
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return strings;
  }

  /**
   * Given a list and a string property (of a String field), return a set of the extracted values
   * The string version provides the ability to get relationship fields - e.x. 'Account.CreatedBy.Name'
   * @param   records   a list of SObject records to extract values from
   * @param   prop      string field path (ex: 'Contact.AccountId') to derive the values from
   * @return  strings   extracted strings
   */
  public static Set<String> pluckStringSet(List<SObject> records, String prop) {
    Set<String> strings = new Set<String>();
    for (SObject obj : records) {
      try {
        if (prop.contains('.')) {
          SObject currObj = obj;
          for (String field : prop.split('\\.')) {
            try {
              currObj = (SObject) currObj.getSobject(field);
            } catch (Exception ex) {
              strings.add((String) currObj.get(field));
            }
          }
        } else if (obj.get(prop) != null) {
          strings.add((String) obj.get(prop));
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return strings;
  }

  /**
   * @description: Group a list of queried SObjects by any field or field path on the SObject.
   * For example: group accounts by ParentId
   *  This method also supports passing in a string key with relationship fields
   *  For example, if you want to group Contacts by Account.Owner.Name
   * @param   records               list of SObject records to group
   * @param   fieldApiNameOrPath    property to get a map by (examples: Id, Account.Owner.Name, etc)
   * @return  propToPropMap         records mapped to a specified field or field path
   */
  public static Map<String, List<SObject>> groupBy(
    List<SObject> records,
    String fieldApiNameOrPath
  ) {
    Map<String, List<SObject>> propToPropMap = new Map<String, List<SObject>>();
    for (SObject obj : records) {
      try {
        SObject baseObj = obj;
        SObject tempObj = obj; // if fieldApiNameOrPath has a "." this holds the nested objects until fields is reached
        String fieldApiName = fieldApiNameOrPath;
        if (fieldApiNameOrPath.contains('.')) {
          // ex: Account.Owner.Name
          fieldApiName = fieldApiNameOrPath.substringAfterLast('.');
          for (
            String pathSegment : fieldApiNameOrPath.substringBeforeLast('.')
              .split('\\.')
          ) {
            // dynamically accommodate for when path contains multiple nested SObjects (ex: Account.Owner.Name)
            tempObj = (SObject) tempObj.getSobject(pathSegment);
          }
        }

        if (tempObj.get(fieldApiName) != null) {
          String fieldValue = (String) tempObj.get(fieldApiName);
          if (!propToPropMap.containsKey(fieldValue)) {
            propToPropMap.put(fieldValue, new List<SObject>());
          }
          propToPropMap.get(fieldValue).add(baseObj);
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' +
          ex.getMessage() +
          ex.getStackTraceString()
        );
      }
    }
    return propToPropMap;
  }

  /**
   * @description   Group a list of SObjects by any field (based on field value) on the SObject.
   * @param         records       : list of SObject records to group
   * @param         sObjField     : field to parse values and group by those values (ex: Account.Industry)
   * @return        propToPropMap : records mapped to a specified field or field path
   */
  public static Map<String, List<SObject>> groupBy(
    List<SObject> records,
    Schema.SObjectField sObjField
  ) {
    Map<String, List<SObject>> propToPropMap = new Map<String, List<SObject>>();
    for (SObject obj : records) {
      try {
        if (obj.get(sObjField) != null) {
          if (!propToPropMap.containsKey((String) obj.get(sObjField))) {
            propToPropMap.put((String) obj.get(sObjField), new List<SObject>());
          }
          propToPropMap.get((String) obj.get(sObjField)).add(obj);
        }
      } catch (Exception e) {
        System.debug(
          'Error processing record, ignoring ' +
          e.getMessage() +
          e.getStackTraceString()
        );
      }
    }
    return propToPropMap;
  }

  /**
   * @description: Determines whether the specified field value has changed from the old object to the new object.
   * @param   oldObject   the old object, typically from Trigger.oldMap
   * @param   newObject   the new object, typically from Trigger.new
   * @param   field       the field which should be checked for a value change
   * @return  Boolean     if the value has changed or not
   */
  public static Boolean fieldValueChanged(
    SObject oldObject,
    SObject newObject,
    Schema.SObjectField field
  ) {
    Object oldValue = oldObject.get(field);
    Object newValue = newObject.get(field);
    return oldValue != newValue;
  }

  /**
   * @description: Determines whether the specified field value has been set from null to non-null value
   * on the new object.
   * @param   oldObject the old object, typically from Trigger.oldMap
   * @param   newObject the new object, typically from Trigger.new
   * @param   field     the field which should be checked as being set
   * @return  Boolean   if the value has been set or not
   */
  public static Boolean fieldValueSet(
    SObject oldObject,
    SObject newObject,
    Schema.SObjectField field
  ) {
    Object oldValue = oldObject.get(field);
    Object newValue = newObject.get(field);
    return (oldValue == null) && (newValue != null);
  }

  /**
   * @description   Get a list of records where the specified field changed
   * @param         records
   * @param         oldItemsMap (trigger.oldMap)
   * @param         fields (string | string[]) : name(s) of property to check
   * @return        changedRecords : a list of changed records
   */
  public static List<SObject> findChangedRecs(
    List<SObject> records,
    Map<Id, SObject> oldItemsMap,
    Schema.SObjectField field
  ) {
    return findChangedRecs(
      records,
      oldItemsMap,
      new List<Schema.SObjectField>{ field }
    );
  }
  public static List<SObject> findChangedRecs(
    List<SObject> records,
    Map<Id, SObject> oldItemsMap,
    List<Schema.SObjectField> fields
  ) {
    List<SObject> changedRecords = new List<SObject>();
    for (SObject obj : records) {
      for (Schema.SObjectField field : fields) {
        try {
          Object newObjValue = obj.get(field);
          Object oldObjValue = oldItemsMap.get((Id) obj.get(ID_STR)).get(field);
          if (newObjValue != oldObjValue) {
            changedRecords.add(obj);
            break; // do not need to continue checking for this record
          }
        } catch (Exception ex) {
          System.debug(
            'Error processing record, ignoring ' + ex.getStackTraceString()
          );
        }
      }
    }
    return changedRecords;
  }

  /**
   * @description Same as findChangedRecs, but check if changed values meet a specific new value
   * @param       records           : List of new records
   * @param       oldItemsMap       : Map of old records
   * @param       field             : The field on the SObject to check
   * @param       expectedNewValue  : The value that is desired on the new records.
   *                                  IF the value on the new record equals this value, then the old record is checked
   *                                  to see if the value is set differently
   * @return      changedRecords    : List of eligible objects, or an empty list
   */
  public static List<SObject> findChangedRecsWithMatchingVal(
    List<SObject> records,
    Map<Id, SObject> oldItemsMap,
    Schema.SObjectField field,
    Object expectedNewValue
  ) {
    List<SObject> changedRecords = new List<SObject>();
    for (SObject obj : records) {
      try {
        Object newObjValue = obj.get(field);
        if (newObjValue == expectedNewValue) {
          Object oldObjValue = oldItemsMap.get((Id) obj.get(ID_STR)).get(field);
          if (newObjValue != oldObjValue) {
            changedRecords.add(obj);
          }
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return changedRecords;
  }

  /**
   * @description   Given a newList and oldMap, return the records that have a matching old value and new value.
   *  This use-case is used when we only want to match records that had a specific value to begin
   *  with where the field was changed to another specified value
   *  Example: Status changed from "Draft" to "Cancelled"
   * @param  records          : List of new records
   * @param  oldItemsMap      : Map of old records
   * @param  field            : The field on the SObject to check
   * @param  oldValue         : Old value of the record that the value should had to be considered to be returned
   * @param  expectedNewValue : Value that the record should have to be returned
   * @return changedRecords   : List of eligible objects, or an empy list
   */
  public static List<SObject> findChangedRecsWithMatchingVal(
    List<SObject> records,
    Map<Id, SObject> oldItemsMap,
    Schema.SObjectField field,
    Object oldValue,
    Object expectedNewValue
  ) {
    List<SObject> changedRecords = new List<SObject>();
    for (SObject obj : records) {
      try {
        Object newObjValue = obj.get(field);
        Object oldObjValue = oldItemsMap.get((Id) obj.get(ID_STR)).get(field);
        if (oldObjValue == oldValue && newObjValue == expectedNewValue) {
          changedRecords.add(obj);
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return changedRecords;
  }

  /**
   * @description:  check SObject list for records that meet a certain value for a specific field
   * @param         records        : List of new records
   * @param         field          : The field to check
   * @param         expectedValue  : Return the record if the field's value equals this value
   * @return        matchedObjects : List of records where the field == expectedValue
   */
  public static List<SObject> findRecsWithMatchingValue(
    List<SObject> records,
    Schema.SObjectField field,
    Object expectedValue
  ) {
    List<SObject> matchedObjects = new List<SObject>();
    for (SObject obj : records) {
      try {
        if (obj.get(field) == expectedValue) {
          matchedObjects.add(obj);
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return matchedObjects;
  }

  /**
   * @description:  Check SObject list for records that do NOT meet a certain value for a specific field
   * @param         records        : List of new records
   * @param         field          : The field to check
   * @param         expectedValue  : Return the record if the field's value does not equals this value
   * @return        matchedObjects : List of records where the field != expectedValue
   */
  public static List<SObject> findRecsWithNonMatchingValue(
    List<SObject> records,
    Schema.SObjectField field,
    Object expectedValue
  ) {
    List<SObject> matchedObjects = new List<SObject>();
    for (SObject obj : records) {
      try {
        if (obj.get(field) != expectedValue) {
          matchedObjects.add(obj);
        }
      } catch (Exception ex) {
        System.debug(
          'Error processing record, ignoring ' + ex.getStackTraceString()
        );
      }
    }
    return matchedObjects;
  }

  /**
   * @description:  Sort an Id to SObject map (containing multiple SObject types) to avoid 'more than 10 chunks' DML error
   * @param         mapToSort : Id to SObject map to sort, in order to consolidate the chunks
   * @return        sortedMap : Id to SObject map with consolidated chunks (1 chunk per object type)
   */
  public static Map<Id, SObject> mapSorter(Map<Id, SObject> mapToSort) {
    List<Id> sortedList = new List<Id>(mapToSort.keyset());
    sortedList.sort();

    Map<Id, SObject> sortedMap = new Map<Id, SObject>();
    for (String idKey : sortedList) {
      sortedMap.put(idKey, mapToSort.get(idKey));
    }

    return sortedMap;
  }

  /**
   * @description:  Sort a string to list map by the number of records in each list ascending.
   * @param         mapToSort : map of String to list of sobjects to sort.
   * @return        sortedMap : a sorted map by the number of records in each of the key's lists ascending
   */
  public static Map<String, List<SObject>> mapSorterByNumOfChildren(
    Map<String, List<SObject>> mapToSort
  ) {
    Map<String, List<SObject>> prepSortedMap = new Map<String, List<SObject>>();
    String placeholderDigits = '00000';
    for (String key : mapToSort.keySet()) {
      List<SObject> childObjList = mapToSort.get(key) == null
        ? new List<SObject>()
        : mapToSort.get(key);
      String numOfChildren = String.valueOf(childObjList.size());
      String keyPrefix =
        placeholderDigits.substring(
          0,
          placeholderDigits.length() - numOfChildren.length()
        ) + numOfChildren;
      prepSortedMap.put(keyPrefix + '*' + key, childObjList);
    }

    List<String> sortedList = new List<String>(prepSortedMap.keyset());
    sortedList.sort();

    Map<String, List<SObject>> sortedMap = new Map<String, List<SObject>>();
    for (String idKey : sortedList) {
      Id idFromIdKey = Id.valueOf(
        idKey.substring(idKey.indexOf('*') + 1, idKey.length())
      );
      sortedMap.put(idFromIdKey, prepSortedMap.get(idKey));
    }

    return sortedMap;
  }

  /**
   * @description:  method to parse field references, even if in dot notation (ex: Contact.Account.Name)
   * @usage:        if I have a queried Task record where I queried Contact.Account.Name from the Task,
   *  if I pass in the Task record and 'Contract.Account.Name', this method will return the value stored in the 'Name'.
   *  Useful for when SObjectRecord.get(field) falls short since it can't do SObjectRecord.get(relationshipField.Field)
   * @param         record          : the record in which to parse the field reference from
   * @param         fieldReference  : the field reference in which to parse. Ex: 'Contact.Account.Name' will get the Name field value parsed
   * @return        fieldVal        : the String, Integer, Boolean, etc parsed value.
   */
  public static Object parseFieldPathForSObject(
    SObject record,
    String fieldReference
  ) {
    SObject tempObj = record;
    Object fieldVal;
    // If provided field is using dot notation, get nested object and field
    if (!fieldReference.contains('.')) {
      return record.get(fieldReference);
    } else {
      List<String> fields = fieldReference.split('\\.');
      for (String splitField : fields) {
        try {
          tempObj = (SObject) tempObj.getSobject(splitField);
        } catch (Exception ex) {
          try {
            fieldVal = tempObj?.get(splitField);
          } catch (Exception exx) {
            return null;
          }
        }
      }
    }
    return fieldVal;
  }

  /**
   * @description -> Method to get properties of a field set.
   * @usage example:
   *  List<Schema.FieldSetMember> fieldSetMemberList =  readFieldSet('SBQQ__LineEditor','SBQQ__Quote__c');
   *  for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList) {
   *      system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()); //api name
   *      system.debug('Label ====>' + fieldSetMemberObj.getLabel());
   *      system.debug('Required ====>' + fieldSetMemberObj.getRequired());
   *      system.debug('DbRequired ====>' + fieldSetMemberObj.getDbRequired());
   *      system.debug('Type ====>' + fieldSetMemberObj.getType());   //type - STRING,PICKLIST
   *  }
   *
   * @param   fieldSetName  name of field set you wish to get the properties (ex: fields) for
   * @param   objApiName    api name of object that field set resides on
   * @return  List<Schema.FieldSetMember -> field set properties to return.
   */
  public static List<Schema.FieldSetMember> readFieldSet(
    String fieldSetName,
    String objApiName
  ) {
    return dynamicDescribe(objApiName)
      .FieldSets.getMap()
      .get(fieldSetName)
      .getFields();
  }

  /**
   * @description: get list of field API names to query, given a Schema.FieldSetMember list:
   * @param   fieldSetName  name of field set you wish to get the properties (ex: fields) for
   * @param   objApiName    api name of object that field set resides on
   * @return  objApiName a list of field API names parsed from the field set parameter
   */
  public static List<String> getFieldSetFieldAPINames(
    String fieldSetName,
    String objApiName
  ) {
    return getFieldSetFieldAPINames(readFieldSet(fieldSetName, objApiName));
  }

  /**
   * @description: get list of field API names to query, given a Schema.FieldSetMember list:
   * @param   fieldSetMemberList    a Schema.FieldSetMember list in which to parse the field API names from
   * @return  fieldSetFieldAPINames a list of field API names parsed from the field set parameter
   */
  public static List<String> getFieldSetFieldAPINames(
    List<Schema.FieldSetMember> fieldSetMemberList
  ) {
    Set<String> fieldSetFieldAPINamesSet = new Set<String>();
    for (Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList) {
      fieldSetFieldAPINamesSet.add(fieldSetMemberObj.getFieldPath());
    }
    List<String> fieldSetFieldAPINames = new List<String>(
      fieldSetFieldAPINamesSet
    );
    return fieldSetFieldAPINames;
  }

  /**
   * @description: given an SObjectField (ex: Account.Name), determine if the field is updateable
   * @param   sObjField   field to check if it is updateable
   * @return  whether or not the field is updateable
   */
  public static Boolean isFieldUpdateable(Schema.SObjectField sObjField) {
    String objApiName = String.valueOf(
      sObjField.getDescribe().getsObjectType()
    );
    String fieldApiName = String.valueOf(
      sObjField.getDescribe().getSobjectField()
    );
    return getFieldMap(objApiName)
      .get(fieldApiName)
      .getDescribe()
      .isUpdateable();
  }

  /**
   * @description: given an SObjectField (ex: Account.Name), determine if the field is accessible
   * @param   sObjField   field to check if it is accessible
   * @return  whether or not the field is accessible
   */
  public static Boolean isFieldAccessible(Schema.SObjectField sObjField) {
    String objApiName = String.valueOf(
      sObjField.getDescribe().getsObjectType()
    );
    String fieldApiName = String.valueOf(
      sObjField.getDescribe().getSobjectField()
    );
    return getFieldMap(objApiName)
      .get(fieldApiName)
      .getDescribe()
      .isAccessible();
  }

  /**
   * @description: given an SObjectField (ex: Account.Name), determine if the field is createable
   * @param   sObjField   field to check if it is createable
   * @return  whether or not the field is createable
   */
  public static Boolean isFieldCreateable(Schema.SObjectField sObjField) {
    String objApiName = String.valueOf(
      sObjField.getDescribe().getsObjectType()
    );
    String fieldApiName = String.valueOf(
      sObjField.getDescribe().getSobjectField()
    );
    return getFieldMap(objApiName)
      .get(fieldApiName)
      .getDescribe()
      .isCreateable();
  }

  /**
   * @description   Given an SObject name, return a Schema.SObjectField field map.
   * @param         objApiName   the name of the SObject in which to return a Schema.SObjectField field map for
   * @return        the Schema.SObjectField field map to return
   */
  public static Map<String, Schema.SObjectField> getFieldMap(
    String objApiName
  ) {
    return dynamicDescribe(objApiName).fields.getMap();
  }

  /**
   * @description   Given an SObject record, return a Schema.SObjectField field map.
   * @param         record   SObject record to get the field map for
   * @return        the Schema.SObjectField field map to return
   */
  public static Map<String, Schema.SObjectField> getFieldMap(SObject record) {
    return dynamicDescribe(record).fields.getMap();
  }

  /**
   * @description   Given an SObject name, return a Schema.DescribeSObjectResult
   * @param         objApiName   SObject name to get the describe for
   * @return        the Schema.DescribeSObjectResult describe to return
   */
  public static Schema.DescribeSObjectResult dynamicDescribe(
    String objApiName
  ) {
    return ((SObject) Type.forName('Schema', objApiName).newInstance())
      .getSObjectType()
      .getDescribe();
  }

  /**
   * @description   Given an SObject record, return a Schema.DescribeSObjectResult
   * @param         record   SObject record to get the describe for
   * @return        the Schema.DescribeSObjectResult describe to return
   */
  public static Schema.DescribeSObjectResult dynamicDescribe(SObject record) {
    return ((SObject) Type.forName(
          'Schema',
          String.valueOf(record.getSObjectType())
        )
        .newInstance())
      .getSObjectType()
      .getDescribe();
  }

  /**
   * @description: validdate email addresses & usernames in email format
   * @param   emailAddress  email address to validate
   * @return  whether or not the email address is valid
   */
  public static Boolean checkValidUsername(String emailAddress) {
    String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';

    Pattern MyPattern = Pattern.compile(emailRegex);
    Matcher MyMatcher = MyPattern.matcher(emailAddress);
    return MyMatcher.matches();
  }

  /**
   * @desciption  Inner class to assist in sheduling apex jobs.
   * @usage       In the following example: we will schedule a schedulable apex class called
   *              'MySchedulableApexClassName' to run 1.5 ours from now:
   *              ParentClassName.Scheduler Scheduler = new ParentClassName.Scheduler(
   *                 'myJob', 'MySchedulableApexClassName').addHours(1).addMinutes(30).run();
   */
  public class Scheduler {
    public DateTime pointInFuture = System.now();
    public Id scheduleId;
    public String className;
    public String strJobName;
    public String strSchedule;
    private final String SECONDS = 'seconds';
    private final String MINUTES = 'minutes';
    private final String HOURS = 'hours';
    private final String DAYS = 'days';

    /**
     * @description   main contructor variation
     * @param         jobName   : the desired name of the schedule
     * @param         className : the desired name of the schedule
     */
    public Scheduler(String jobName, String className) {
      this.className = className;
      this.strJobName =
        jobName +
        '. Date: ' +
        this.pointInFuture.month() +
        '/' +
        this.pointInFuture.day() +
        '/' +
        this.pointInFuture.year() +
        ' ' +
        this.pointInFuture.hour() +
        ':' +
        this.pointInFuture.minute() +
        ':' +
        this.pointInFuture.second();
      this.strSchedule =
        this.pointInFuture.second() +
        ' ' +
        this.pointInFuture.minute() +
        ' ' +
        this.pointInFuture.hour() +
        ' ' +
        this.pointInFuture.day() +
        ' ' +
        this.pointInFuture.month() +
        ' ?' +
        ' ' +
        this.pointInFuture.year();
    }

    /**
     * @description   add seconds to the schedule (push the start time out by a specified number of seconds).
     * @param         hoursToAdd : number of seconds to add to the schedule.
     * @return        the modified job to schedule
     */
    public Scheduler addSeconds(Integer secondsToAdd) {
      this.pointInFuture.addSeconds(secondsToAdd);
      this.strSchedule = buildScheduleString(this.pointInFuture);
      return this;
    }

    /**
     * @description   add minutes to the schedule (push the start time out by a specified number of minutes).
     * @param         hoursToAdd : number of minutes to add to the schedule.
     * @return        the modified job to schedule
     */
    public Scheduler addMinutes(Integer minutesToAdd) {
      this.pointInFuture.addMinutes(minutesToAdd);
      this.strSchedule = buildScheduleString(this.pointInFuture);
      return this;
    }

    /**
     * @description   add hours to the schedule (push the start time out by a specified number of hours).
     * @param         hoursToAdd : number of hours to add to the schedule.
     * @return        the modified job to schedule
     */
    public Scheduler addHours(Integer hoursToAdd) {
      this.pointInFuture.addHours(hoursToAdd);
      this.strSchedule = buildScheduleString(this.pointInFuture);
      return this;
    }

    /**
     * @description   add days to the schedule (push the start time out by a specified number of days).
     * @param         hoursToAdd : number of days to add to the schedule.
     * @return        the modified job to schedule
     */
    public Scheduler addDays(Integer daysToAdd) {
      this.pointInFuture.addDays(daysToAdd);
      this.strSchedule = buildScheduleString(this.pointInFuture);
      return this;
    }

    /**
     * @description   set the point in future that the schedule will run, once the run method is invoked.
     * @param         pointInFuture : the point in the future in which to execute the scheduled job
     * @return        the stringified point in time to execute the scheduled job
     */
    public String buildScheduleString(DateTime pointInFuture) {
      return pointInFuture.second() +
        ' ' +
        pointInFuture.minute() +
        ' ' +
        pointInFuture.hour() +
        ' ' +
        pointInFuture.day() +
        ' ' +
        pointInFuture.month() +
        ' ?' +
        ' ' +
        pointInFuture.year();
    }

    /**
     * @description   queue up the scheduled job
     * @param         void
     * @return        null
     */
    public Scheduler run() {
      Type theType = Type.forName(this.className);
      try {
        this.scheduleId = System.schedule(
          this.strJobName,
          this.strSchedule,
          (Schedulable) theType.newInstance()
        );
      } catch (Exception e) {
        System.debug(
          'ApexUtils.Scheduler: Error scheduling job. ' +
          e.getMessage() +
          ' ' +
          e.getStackTraceString()
        );
      }
      return this;
    }
  }
}