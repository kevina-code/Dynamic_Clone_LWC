/**
 * Author       : Kevin Antonioli (braveitnow@pm.me)
 * Description  : Apex controller for Dynamic Clone LWC
 * Created      : 2/27/2023
 *
 * Revisions:
 * Date : Name : Notes
 */
public with sharing class DynamicCloneController {
  /**
   * @Description: get child obj names based on parent record Id
   * @param   parentRecordId  Id of the record the modal was invoked from
   * @return  childInfos      child relationship info
   */
  @AuraEnabled(cacheable=true)
  public static List<ChildInfo> getChildRelInfo(
    Id parentRecordId,
    String childRelationshipNames
  ) {
    List<ChildInfo> childInfos = new List<ChildInfo>();
    try {
      String parentObjApiName = String.valueOf(parentRecordId.getSobjectType());
      SObjectType parentObjType = ApexUtils.globalDescribe.get(
        parentObjApiName
      );
      Schema.DescribeSObjectResult describeResult = parentObjType.getDescribe();

      List<String> preDefinedChildRelNames = new List<String>();
      // if child relationship names defined in configs:
      if (
        childRelationshipNames != null &&
        !String.isBlank(childRelationshipNames)
      ) {
        for (String childRelName : childRelationshipNames.split(',')) {
          preDefinedChildRelNames.add(childRelName);
        }
      }

      // Gather non-null child relationships:
      List<Schema.ChildRelationship> childRelsNonNull = new List<Schema.ChildRelationship>();
      Set<String> childRelNames = new Set<String>();
      for (
        Schema.ChildRelationship childRel : describeResult.getChildRelationships()
      ) {
        if (childRel.getRelationshipName() != null) {
          if (!preDefinedChildRelNames.isEmpty()) {
            if (
              preDefinedChildRelNames.contains(childRel.getRelationshipName())
            ) {
              childRelsNonNull.add(childRel);
              childRelNames.add(childRel.getRelationshipName());
            }
          } else {
            childRelsNonNull.add(childRel);
            childRelNames.add(childRel.getRelationshipName());
          }
        }
      }

      // map break point to list of parent/child record aggregations.
      // Break points in this context are to circumvent the limit of 20 subqueries per sobject query
      Map<Integer, List<SObject>> bpToParentChildRecs = processChildObjs(
        parentRecordId,
        parentObjApiName,
        childRelsNonNull,
        null /*childRelNames*/,
        false /*doClone*/
      );

      // loop through and assemble child info data structures:
      Integer index = 0;
      for (Integer bp : bpToParentChildRecs.keySet()) {
        // break point aggregations loop
        for (SObject parent : bpToParentChildRecs.get(bp)) {
          // parent SObject loop (will be the same parent each time)
          for (String childRelName : childRelNames) {
            // child relationship name loop
            try {
              for (SObject childRec : parent.getSObjects(childRelName)) {
                // child record loop
                ChildInfo childInfo = new ChildInfo();
                childInfo.index = index;
                childInfo.relName = childRelName;
                childInfo.hasRecords = true;
                childInfos.add(childInfo);
              }
            } catch (exception e) {
              System.debug(
                'DynamicCloneController.getChildRelInfo SOFT exception: ' +
                e +
                ', stacktrace: ' +
                e.getStackTraceString()
              );
            }
            Index += 1;
          }
        }
      }
    } catch (Exception e) {
      String msg =
        'DynamicCloneController.getChildRelInfo exception: ' +
        e.getMessage() +
        ', stacktrace:' +
        e.getStackTraceString();
      System.debug(msg);
      throw new AuraHandledException(msg);
    }

    return childInfos;
  }

  /**
   * Data structure to store information about the child relationships
   */
  public class ChildInfo {
    @AuraEnabled
    public Integer index;
    @AuraEnabled
    public String relName;
    @AuraEnabled
    public Boolean hasRecords;
  }

  /**
   * @description: process child object relationships/records
   * @param   parentRecordId      Id of record modal was invoked from
   * @param   parentObjApiName    Object API name of record modal was invoked from
   * @param   childRels           list of child relationships for the parent
   * @param   childRelNames       List of child relationship names
   * @param   doClone             whether to clone children or not
   * @return  bpToParentChildRecs breakpoint key mapped to parent with child records
   */
  private static Map<Integer, List<SObject>> processChildObjs(
    Id parentRecordId,
    String parentObjApiName,
    List<Schema.ChildRelationship> childRels,
    List<String> childRelNames,
    Boolean doClone
  ) {
    // segregate child relationships into chunks of 20 to avoid the 20 max subquery governor limit
    Map<Integer, List<Schema.ChildRelationship>> bpToChildRelList = new Map<Integer, List<Schema.ChildRelationship>>(); // will contain no more than 20 child relationships per map key/break point
    // prettier-ignore
    List<Integer> breakPointsPossible = new List<Integer>{ 20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 220, 240, 260, 280 }; // 301 is the subquery limit so stay a ways below that
    Set<Integer> breakPoints = new Set<Integer>(); // applicable breakPoints
    for (Integer i = 0; i < breakPointsPossible.size(); i++) {
      if (breakPointsPossible[i] <= childRels.size() + 20) {
        breakPoints.add(breakPointsPossible[i]);
        if (breakPoints.size() >= 14) {
          // 14 possible break points given the size of the breakPointsPossible list
          break;
        }
      }
    }

    Integer previousBp = -1;
    // build map of breakpoint to child relationship list
    for (Integer bp : breakPoints) {
      for (Schema.ChildRelationship childRel : childRels) {
        Integer currentIndex = childRels.indexOf(childRel);
        if (currentIndex >= previousBp && currentIndex < bp) {
          List<Schema.ChildRelationship> childRelList = bpToChildRelList.get(
              bp
            ) == null
            ? new List<Schema.ChildRelationship>()
            : bpToChildRelList.get(bp);
          childRelList.add(childRel);
          bpToChildRelList.put(bp, childRelList);
        }
      }
      previousBp = bp;
    }

    Map<Integer, List<SObject>> bpToParentChildRecs = buildAggrMap(
      parentRecordId,
      parentObjApiName,
      bpToChildRelList,
      doClone
    );
    return bpToParentChildRecs;
  }

  /**
   * @description: build subqueries for each set of 20 child objects using the breakpoints and map their results
   * @param   parentRecordId      Id of parent record (the record the quick action was clicked on)
   * @param   parentObjApiName    object name for parent record (the record the quick action was clicked on)
   * @param   bpToChildRelList    aggregation map for child relationship schema
   * @param   doClone             whether or not to perform clone
   * @return  bpToParentChildRecs aggregation map for queried records including subqueries
   */
  private static Map<Integer, List<SObject>> buildAggrMap(
    Id parentRecordId,
    String parentObjApiName,
    Map<Integer, List<Schema.ChildRelationship>> bpToChildRelList,
    Boolean doClone
  ) {
    Map<Integer, List<SObject>> bpToParentChildRecs = new Map<Integer, List<SObject>>(); // map break point to parent with subqueried children
    for (Integer bp : bpToChildRelList.keySet()) {
      String queryWithEmbedded = 'SELECT Id, ';
      List<Schema.ChildRelationship> childRelList = bpToChildRelList.get(bp);
      for (Schema.ChildRelationship childRel : childRelList) {
        Integer currentIndex = childRelList.indexOf(childRel);
        Integer finalIndex = childRelList.size() - 1;
        if (!doClone) {
          queryWithEmbedded +=
            '(SELECT Id FROM ' +
            childRel.getRelationshipName() +
            ' LIMIT 1)';
          if (currentIndex != finalIndex) {
            queryWithEmbedded += ',';
          }
        } else {
          // if doClone, query all fields from all relevant child records
          String childObjName = String.valueOf(childRel.getChildSObject());
          queryWithEmbedded +=
            '(SELECT ' +
            ApexUtils.getAllFieldsForSObjAsStr(childObjName) +
            ' FROM ' +
            childRel.getRelationshipName() +
            ')';
          if (currentIndex != finalIndex) {
            queryWithEmbedded += ',';
          }
        }
      }
      queryWithEmbedded +=
        ' FROM ' +
        parentObjApiName +
        ' WHERE Id = :parentRecordId';

      SObject parentWithChildRecs = Database.query(queryWithEmbedded)[0]; // can't avoid this query being in a loop due to 20 subquery limit
      List<SObject> parentsWithChildRecs = bpToParentChildRecs.get(bp) == null
        ? new List<SObject>()
        : bpToParentChildRecs.get(bp);
      parentsWithChildRecs.add(parentWithChildRecs);
      bpToParentChildRecs.put(bp, parentsWithChildRecs);
    }
    return bpToParentChildRecs;
  }

  /**
   * @Description: method to perform dynamic clone on selected records/objects for Dynamic Clone LWC
   * @param   parentRecordId            the id of the record the modal was invoked from
   * @param   relNamesToCloneRecsFor    the objects the user selected to clone records for
   * @return  void
   */
  @AuraEnabled
  public static void performDynamicClone(
    Id parentRecordId,
    String selectedObjsStr
  ) {
    try {
      String parentObjApiName = String.valueOf(parentRecordId.getSobjectType());
      SObjectType parentObjType = ApexUtils.globalDescribe.get(
        parentObjApiName
      );
      Schema.DescribeSObjectResult describeResult = parentObjType.getDescribe();
      List<String> relNamesToCloneRecsFor = selectedObjsStr.split(',');

      // Gather object relationships selected by user:
      List<Schema.ChildRelationship> childRelsNonNull = new List<Schema.ChildRelationship>();
      Set<String> childRelNames = new Set<String>();
      for (
        Schema.ChildRelationship childRel : describeResult.getChildRelationships()
      ) {
        if (childRel.getRelationshipName() != null) {
          if (relNamesToCloneRecsFor.contains(childRel.getRelationshipName())) {
            childRelsNonNull.add(childRel);
            childRelNames.add(childRel.getRelationshipName());
          }
        }
      }

      // map break point to list of parent/child record aggregations.
      // Break points in this context are to circumvent the limit of 20 subqueries per sobject query
      Map<Integer, List<SObject>> bpToParentChildRecs = processChildObjs(
        parentRecordId,
        parentObjApiName,
        childRelsNonNull,
        relNamesToCloneRecsFor,
        true /*doClone */
      );

      List<SObject> clonesToInsert = new List<SObject>();
      for (Integer bp : bpToParentChildRecs.keySet()) {
        // break point aggregations loop
        for (SObject parent : bpToParentChildRecs.get(bp)) {
          // parent SObject loop (will be the same parent each time)
          for (String childRelName : childRelNames) {
            // child relationship name loop
            try {
              for (SObject childRec : parent.getSObjects(childRelName)) {
                SObject childRecClone = childRec.clone(false, false);
                /*childRecClone.put('Name',childRec.get('Name') +' ' +ApexUtils.generateRandomId(5)); */
                clonesToInsert.add(childRecClone);
              }
            } catch (exception e) {
              System.debug(
                'DynamicCloneController.processChildObjs SOFT exception: ' +
                e +
                ', stacktrace: ' +
                e.getStackTraceString()
              );
            }
          }
        }
      }
      if (!clonesToInsert.isEmpty()) {
        clonesToInsert.sort();
        insert clonesToInsert;
      }
    } catch (Exception e) {
      String msg =
        'DynamicCloneController.performDynamicClone exception: ' +
        e.getMessage() +
        ', stacktrace:' +
        e.getStackTraceString();
      System.debug(msg);
      throw new AuraHandledException(msg);
    }
  }
}