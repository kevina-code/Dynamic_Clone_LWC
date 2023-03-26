/**
 * Author      : Kevin Antonioli (braveitnow@pm.me)
 * Description : Provides test code coverage for Apex Utility methods (ApexUtils)
 * Created     : 03.11.2023
 */
@isTest
public class ApexUtilsTest {
  @isTest
  static void test_staticGetSetVars() {
    Assert.isNotNull(ApexUtils.instanceURL);
    Assert.isTrue(!String.isBlank(ApexUtils.instanceURL));
    Assert.isNotNull(ApexUtils.runningInASandbox);
    Assert.isNotNull(ApexUtils.loggedInUserProfile);
  }

  @isTest
  static void test_Scheduler() {
    ApexUtils.Scheduler scheduleUsingSeconds = new ApexUtils.Scheduler(
      'Scheduled Run', // String jobName
      'SomeScheduleableApexClassName'
    ); // String className

    Test.startTest();
    scheduleUsingSeconds.addDays(1)
      .addHours(2)
      .addMinutes(5)
      .addSeconds(7)
      .run();
    Test.stopTest();

    Assert.isNotNull(scheduleUsingSeconds.pointInFuture);
    Assert.isNotNull(scheduleUsingSeconds.strSchedule);
    Assert.isNotNull(scheduleUsingSeconds.strJobName);
  }

  @isTest
  static void test_generateUUID() {
    String uuid = ApexUtils.generateUUID();
    Assert.isNotNull(uuid);
    Assert.areEqual(uuid.length(), 36);
  }

  @isTest
  static void test_GetFieldsMethods() {
    Assert.isTrue(ApexUtils.getAllFieldsForSobj('Account').size() > 0);
    Assert.isTrue(ApexUtils.getAllFieldsForSObjAsStr('Account').length() > 0);

    Assert.isFalse(
      ApexUtils.getAllFieldsExceptBlacklist(
          'Account',
          new List<String>{ 'Name' }
        )
        .contains('name')
    );
    Assert.isTrue(
      ApexUtils.getAllFieldsExceptBlacklist(
          'Account',
          new List<String>{ 'Name' }
        )
        .contains('type')
    );

    Assert.isFalse(
      ApexUtils.getAllFieldsExceptBlacklistAsStr(
          'Account',
          new List<String>{ 'Name' }
        )
        .contains('Name,')
    );
    Assert.isTrue(
      ApexUtils.getAllFieldsExceptBlacklistAsStr(
          'Account',
          new List<String>{ 'Name' }
        )
        .contains('type,')
    );

    Assert.isTrue(ApexUtils.getCreatableFieldsAsStr('Account').length() > 0);
    Assert.isTrue(
      ApexUtils.getCreatableFieldsAsStr('Account').contains('Name')
    );
    Assert.isFalse(
      ApexUtils.getCreatableFieldsAsStr('Account').contains('CreatedById')
    );

    Assert.isTrue(ApexUtils.getUpdateableFieldsAsStr('Account').length() > 0);
    Assert.isTrue(
      ApexUtils.getUpdateableFieldsAsStr('Account').contains('Name')
    );
    Assert.isFalse(
      ApexUtils.getUpdateableFieldsAsStr('Account').contains('CreatedById')
    );
  }

  @isTest
  static void test_schemaMethods() {
    List<Account> accounts = createTestAccounts();
    Assert.isFalse(ApexUtils.getFieldMap('Account').isEmpty());
    Assert.isFalse(ApexUtils.getFieldMap(accounts[0]).isEmpty());
    Assert.isNotNull(ApexUtils.dynamicDescribe('Account'));
    Assert.isNotNull(ApexUtils.dynamicDescribe(accounts[0]));
  }

  @isTest
  static void test_fieldSetMethods() {
    try {
      // cannot create field set in test class; this is the best we can do:
      List<Schema.FieldSetMember> fieldSet = ApexUtils.readFieldSet(
        'some_field_set',
        'Account'
      );
    } catch (exception e) {
      Assert.isTrue(
        e.getMessage().contains('Attempt to de-reference a null object')
      );
    }

    try {
      // cannot create field set in test class; this is the best we can do:
      List<String> fieldApiNames = ApexUtils.getFieldSetFieldAPINames(
        'some_field_set',
        'Account'
      );
    } catch (exception e) {
      Assert.isTrue(
        e.getMessage().contains('Attempt to de-reference a null object')
      );
    }
  }

  @isTest
  static void test_getEnvironmentName() {
    Assert.isNotNull(ApexUtils.getEnvironmentName());
  }

  @isTest
  static void test_getFilesOnRecord() {
    Account testAccount = new Account(Name = 'ABC Corp');
    insert testAccount;
    //Create Document/File for CSV
    ContentVersion cvCsv = new ContentVersion();
    cvCsv.Title =
      'census_' +
      System.now().format('yyyy_MM_dd_hh_mm_ss') +
      '.csv';
    cvCsv.PathOnClient =
      'census_' +
      System.now().format('yyyy_MM_dd_hh_mm_ss') +
      '.csv';
    cvCsv.VersionData = Blob.valueOf('Some File Body');
    cvCsv.IsMajorVersion = true;
    insert cvCsv;
    Id cdId = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :cvCsv.Id
    ]
    .ContentDocumentId;
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.LinkedEntityId = testAccount.Id;
    cdl.ContentDocumentId = cdId;
    cdl.shareType = 'V';
    insert cdl;
    Test.startTest();
    List<ContentVersion> files = ApexUtils.getFilesOnRecord(
      testAccount.Id,
      null
    );
    Test.stopTest();

    Assert.isTrue(!files.isEmpty());
  }

  @isTest
  static void test_pluckIdSet() {
    List<Account> accounts = createTestAccounts();
    Set<Id> accountIds = ApexUtils.pluckIdSet(accounts, Schema.Account.Id);
    Assert.areEqual(3, accountIds.size());
  }

  @isTest
  static void test_pluckIdSetNonMatching() {
    List<Account> accounts = createTestAccounts();
    Set<Id> accountIds = ApexUtils.pluckIdSet(accounts, Schema.Contact.Name);
    Assert.areEqual(0, accountIds.size());
  }

  @isTest
  static void test_pluckIdSetRelationship() {
    List<Contact> contacts = new List<Contact>{
      new Contact(
        LastName = '1',
        Account = new Account(
          Name = 'Account 1',
          Parent = new Account(
            Id = getFakeId(Account.getSObjectType()),
            Name = 'parent-account-1'
          )
        )
      ),
      new Contact(
        LastName = '2',
        Account = new Account(
          Name = 'Account 2',
          Parent = new Account(
            Id = getFakeId(Account.getSObjectType()),
            Name = 'parent-account-2'
          )
        )
      ),
      new Contact(
        LastName = '3',
        Account = new Account(
          Name = 'Account 3',
          Parent = new Account(
            Id = getFakeId(Account.getSObjectType()),
            Name = 'parent-account-3'
          )
        )
      ),
      new Contact(
        LastName = '4',
        Account = new Account(
          Name = 'Account 4',
          Parent = new Account(
            Id = getFakeId(Account.getSObjectType()),
            Name = 'parent-account-4'
          )
        )
      ),
      new Contact(LastName = '5', Account = new Account(Name = 'Account 4')),
      new Contact(LastName = '5')
    };
    Set<Id> userIds = ApexUtils.pluckIdSet(contacts, 'Account.Parent.Id');
    Assert.areEqual(4, userIds.size());
  }

  @isTest
  static void test_pluckStringSet() {
    List<Account> accounts = createTestAccounts();
    Set<String> accountIds = ApexUtils.pluckStringSet(
      accounts,
      Schema.Account.Name
    );
    Assert.areEqual(3, accountIds.size());

    Assert.isTrue(accountIds.contains('1'));
    Assert.isTrue(accountIds.contains('2'));
    Assert.isTrue(accountIds.contains('3'));
  }

  @isTest
  static void test_pluckStringSetRelationship() {
    List<Contact> contacts = new List<Contact>{
      new Contact(
        LastName = '1',
        Account = new Account(
          Name = 'Account 1',
          Parent = new Account(
            Id = getFakeId(Account.getSObjectType()),
            Name = 'parent-account-1'
          )
        )
      ),
      new Contact(
        LastName = '2',
        Account = new Account(
          Name = 'Account 2',
          Parent = new Account(
            Id = getFakeId(Account.getSObjectType()),
            Name = 'parent-account-2'
          )
        )
      ),
      new Contact(
        LastName = '3',
        Account = new Account(
          Name = 'Account 3',
          Parent = new Account(
            Id = getFakeId(Account.getSObjectType()),
            Name = 'parent-account-3'
          )
        )
      ),
      new Contact(
        LastName = '4',
        Account = new Account(
          Name = 'Account 4',
          Parent = new Account(
            Id = getFakeId(Account.getSObjectType()),
            Name = 'parent-account-4'
          )
        )
      ),
      new Contact(LastName = '5', Account = new Account(Name = 'Account 4')),
      new Contact(LastName = '5')
    };
    Set<String> userNames = ApexUtils.pluckStringSet(
      contacts,
      'Account.Parent.Name'
    );
    Assert.areEqual(4, userNames.size());
  }

  @isTest
  static void test_groupByFieldPath() {
    List<Account> accounts = createTestAccounts();

    accounts[0].Parent = new Account();
    accounts[0].Parent.Owner = new User(FirstName = 'Bob');
    accounts[1].Parent = new Account();
    accounts[1].Parent.Owner = new User(FirstName = 'Bob');
    accounts[2].Parent = new Account();
    accounts[2].Parent.Owner = new User(FirstName = 'Sally');

    Test.startTest();
    Map<String, List<SObject>> accountMap = ApexUtils.groupBy(
      accounts,
      'Parent.Owner.FirstName'
    );
    Map<String, List<SObject>> accountMapById = ApexUtils.groupBy(
      accounts,
      'Id'
    );
    Test.stopTest();

    Assert.areEqual(accountMap.get('Bob').size(), 2);
    Assert.areEqual(accountMap.get('Sally').size(), 1);
    Assert.isTrue(!accountMapById.isEmpty());
  }

  @isTest
  static void test_groupByField() {
    List<Account> accounts = createTestAccounts();
    accounts[0].Type = 'Franchise';
    accounts[1].Type = 'Franchise';
    accounts[2].Type = 'Client';

    Map<String, List<SObject>> accountMap = ApexUtils.groupBy(
      accounts,
      Schema.Account.Type
    );

    Assert.areEqual(2, accountMap.get('Franchise').size());
    Assert.areEqual(1, accountMap.get('Client').size());
  }

  @isTest
  static void test_fieldValueChanged() {
    List<Account> accounts = createTestAccounts();
    accounts[0].Name = 'Tracy';
    accounts[1].Name = 'Tracy';

    Assert.isFalse(
      ApexUtils.fieldValueChanged(accounts[0], accounts[1], Account.Name)
    );
  }

  @isTest
  static void test_fieldValueSet() {
    List<Account> accounts = createTestAccounts();
    accounts[0].Name = 'Tracy';
    accounts[1].Name = 'Tracy';

    Assert.isFalse(
      ApexUtils.fieldValueSet(accounts[0], accounts[1], Account.Name)
    );
  }

  @isTest
  static void test_findChangedRecs() {
    List<Account> accounts = createTestAccounts();
    Map<Id, Account> accountMap = new Map<Id, Account>(
      [SELECT Id, Name FROM Account]
    );

    accounts[0].Name = 'CHANGED1';
    accounts[2].Name = 'CHANGED3';

    List<SObject> changedAccounts = ApexUtils.findChangedRecs(
      accounts,
      accountMap,
      Schema.Account.Name
    );

    Assert.areEqual(2, changedAccounts.size());
    Assert.areEqual(accounts[0], changedAccounts[0]);
    Assert.areEqual(accounts[2], changedAccounts[1]);
  }

  @isTest
  static void test_findChangedRecsWithMatchingVal() {
    List<Account> accounts = createTestAccounts();
    Map<Id, Account> accountMap = new Map<Id, Account>(
      [SELECT Id, Name FROM Account]
    );

    accounts[0].Name = 'CHANGED1';
    accounts[2].Name = 'CHANGED3';

    List<SObject> changedAccounts = ApexUtils.findChangedRecsWithMatchingVal(
      accounts,
      accountMap,
      Schema.Account.Name,
      'CHANGED1'
    );

    Assert.areEqual(1, changedAccounts.size());
    Assert.areEqual(accounts[0], changedAccounts[0]);
  }

  @isTest
  static void test_findChangedRecsWithMatchingVal2() {
    List<Account> accounts = createTestAccounts();
    Map<Id, Account> accountMap = new Map<Id, Account>(
      [SELECT Id, Name FROM Account]
    );

    accounts[0].Name = 'CHANGED1';
    accounts[2].Name = 'CHANGED1';

    List<SObject> changedAccounts = ApexUtils.findChangedRecsWithMatchingVal(
      accounts,
      accountMap,
      Schema.Account.Name,
      '1',
      'CHANGED1'
    );

    Assert.areEqual(1, changedAccounts.size());
    Assert.areEqual(accounts[0], changedAccounts[0]);
  }

  @isTest
  static void test_findRecsWithMatchingValue() {
    List<Account> accounts = createTestAccounts();
    accounts[0].Type = 'Franchise';
    accounts[1].Type = 'Franchise';
    accounts[2].Type = 'Client';

    List<SObject> foundObjects1 = ApexUtils.findRecsWithMatchingValue(
      accounts,
      Schema.Account.Type,
      'Franchise'
    );
    List<SObject> foundObjects2 = ApexUtils.findRecsWithMatchingValue(
      accounts,
      Schema.Account.Type,
      'Client'
    );
    List<SObject> foundObjects3 = ApexUtils.findRecsWithMatchingValue(
      accounts,
      Schema.Account.Type,
      'foo-bar'
    );

    Assert.areEqual(accounts[0], foundObjects1[0]);
    Assert.areEqual(accounts[1], foundObjects1[1]);
    Assert.areEqual(2, foundObjects1.size());
    Assert.areEqual(1, foundObjects2.size());
    Assert.areEqual(0, foundObjects3.size());
  }

  @isTest
  static void test_findRecsWithNonMatchingValue() {
    List<Account> accounts = createTestAccounts();
    accounts[0].Type = 'Franchise';
    accounts[1].Type = 'Franchise';
    accounts[2].Type = 'Client';

    List<SObject> foundObjects1 = ApexUtils.findRecsWithNonMatchingValue(
      accounts,
      Schema.Account.Type,
      'Franchise'
    );
    List<SObject> foundObjects2 = ApexUtils.findRecsWithNonMatchingValue(
      accounts,
      Schema.Account.Type,
      'Client'
    );
    List<SObject> foundObjects3 = ApexUtils.findRecsWithNonMatchingValue(
      accounts,
      Schema.Account.Type,
      'foo-bar'
    );

    Assert.areEqual(accounts[2], foundObjects1[0]);
    Assert.areEqual(accounts[0], foundObjects2[0]);
    Assert.areEqual(accounts[1], foundObjects2[1]);
    Assert.areEqual(1, foundObjects1.size());
    Assert.areEqual(2, foundObjects2.size());
    Assert.areEqual(3, foundObjects3.size());
  }

  @isTest
  static void test_validateId() {
    Assert.isTrue(ApexUtils.isIdValid('0011800000dSq2KAAS'));
    Assert.isTrue(ApexUtils.isIdValid('0011800000dSq2K'));
    Assert.isFalse(ApexUtils.isIdValid('0011800000dSq2KAA#'));
    Assert.isFalse(ApexUtils.isIdValid('0011800000dSq2#'));
    Assert.isFalse(ApexUtils.isIdValid('!!!FOO!!!'));
  }

  @isTest
  static void test_formatDate() {
    String dateStr = ApexUtils.formatDate(
      Date.newInstance(2000, 1, 1),
      'yyyy-MM-dd'
    );
    Assert.areEqual(10, dateStr.length());
    Assert.areEqual('2000-01-01', dateStr);
  }

  @isTest
  static void test_getEarliestAndLatestDate() {
    List<Contact> contacts = new List<Contact>{
      new Contact(Birthdate = Date.today().addDays(10)),
      new Contact(Birthdate = Date.today().addDays(-10)),
      new Contact(Birthdate = Date.today().addDays(20))
    };

    Date earliestDate = ApexUtils.getEarliestDate(
      contacts,
      Schema.Contact.Birthdate
    );
    Date latestDate = ApexUtils.getLatestDate(
      contacts,
      Schema.Contact.Birthdate
    );

    Assert.areEqual(contacts[1].Birthdate, earliestDate);
    Assert.areEqual(contacts[2].Birthdate, latestDate);
  }

  @isTest
  static void test_findRecWithDateBetween() {
    List<Asset> assets = new List<Asset>{
      new Asset(
        Id = ApexUtilsTest.getFakeId(Asset.getSObjectType()),
        InstallDate = Date.today().addDays(0),
        UsageEndDate = Date.Today().addDays(29)
      ), // 0
      new Asset(
        Id = ApexUtilsTest.getFakeId(Asset.getSObjectType()),
        InstallDate = Date.today().addDays(30),
        UsageEndDate = Date.Today().addDays(39)
      ), // 1
      new Asset(
        Id = ApexUtilsTest.getFakeId(Asset.getSObjectType()),
        InstallDate = Date.today().addDays(40),
        UsageEndDate = Date.Today().addDays(49)
      ), // 2
      new Asset(
        Id = ApexUtilsTest.getFakeId(Asset.getSObjectType()),
        InstallDate = Date.today().addDays(50),
        UsageEndDate = Date.Today().addDays(59)
      ), // 3
      new Asset(
        Id = ApexUtilsTest.getFakeId(Asset.getSObjectType()),
        InstallDate = Date.today().addDays(60),
        UsageEndDate = Date.Today().addDays(69)
      ), // 4
      new Asset(
        Id = ApexUtilsTest.getFakeId(Asset.getSObjectType()),
        InstallDate = Date.today().addDays(70),
        UsageEndDate = Date.Today().addDays(79)
      ) // 5
    };

    Assert.areEqual(
      assets[0],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(0),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      assets[0],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(29),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      assets[1],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(30),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      assets[1],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(35),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      assets[2],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(45),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      assets[3],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(55),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      assets[4],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(60),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      assets[4],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(69),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      assets[5],
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(75),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );

    Assert.areEqual(
      null,
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(-1),
        Asset.InstallDate,
        Asset.UsageEndDate
      )
    );
    Assert.areEqual(
      null,
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today(),
        Asset.InstallDate,
        Asset.UsageEndDate,
        false
      )
    );
    Assert.areEqual(
      null,
      ApexUtils.findRecWithDateBetween(
        assets,
        Date.today().addDays(29),
        Asset.InstallDate,
        Asset.UsageEndDate,
        false
      )
    );
  }

  @isTest
  static void test_findRecWithDecimalBetween() {
    List<Account> accounts = new List<Account>{
      new Account(
        Id = ApexUtilsTest.getFakeId(Account.getSObjectType()),
        BillingLatitude = 1,
        BillingLongitude = 15
      ),
      new Account(
        Id = ApexUtilsTest.getFakeId(Account.getSObjectType()),
        BillingLatitude = 16,
        BillingLongitude = 30
      ),
      new Account(
        Id = ApexUtilsTest.getFakeId(Account.getSObjectType()),
        BillingLatitude = 31,
        BillingLongitude = null
      )
    };

    // startIsInclusive = true
    //      endIsInclusive = true
    Assert.areEqual(
      accounts[0],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        1,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude
      )
    );
    Assert.areEqual(
      accounts[0],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        1,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        true
      )
    );
    Assert.areEqual(
      accounts[0],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        15,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        true
      )
    );
    Assert.areEqual(
      accounts[1],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        16,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        true
      )
    );
    Assert.areEqual(
      accounts[1],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        30,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        true
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        99,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        true
      )
    );

    // startIsInclusive = true
    //      endIsInclusive = false
    Assert.areEqual(
      accounts[0],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        1,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        false
      )
    );
    Assert.areEqual(
      accounts[1],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        16,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        false
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        15,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        false
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        30,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        false
      )
    );

    // startIsInclusive = false
    //      endIsInclusive = true
    Assert.areEqual(
      accounts[0],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        2,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        true
      )
    );
    Assert.areEqual(
      accounts[1],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        17,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        true
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        1,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        true
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        16,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        true
      )
    );

    // startIsInclusive = false
    //      endIsInclusive = false
    Assert.areEqual(
      accounts[0],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        10,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        false
      )
    );
    Assert.areEqual(
      accounts[1],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        20,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        false
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        1,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        false
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        15,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        false
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        16,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        false
      )
    );
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        30,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        false
      )
    );

    // includeEndIsNullRule = true
    // ( startIsInclusive and endIsInclusive defaults to true )
    Assert.areEqual(
      accounts[2],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        45,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        false,
        true
      )
    );
    Assert.areEqual(
      accounts[2],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        45,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        false,
        true,
        true
      )
    );
    Assert.areEqual(
      accounts[2],
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        45,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        true,
        true
      )
    );
    // includeEndIsNullRule = false
    // ( startIsInclusive and endIsInclusive defaults to true )
    Assert.areEqual(
      null,
      (Account) ApexUtils.findRecWithDecimalBetween(
        accounts,
        45,
        Schema.Account.BillingLatitude,
        Schema.Account.BillingLongitude,
        true,
        true,
        false
      )
    );
  }

  @isTest
  static void test_MapSorters() {
    List<Account> acctList = createTestAccounts();

    List<Contact> contactList = new List<Contact>();
    contactList.add(createTestContact(acctList[0]));
    contactList.add(createTestContact(acctList[0]));
    contactList.add(createTestContact(acctList[0]));
    contactList.add(createTestContact(acctList[2]));
    contactList.add(createTestContact(acctList[2]));
    contactList.add(createTestContact(acctList[1]));
    insert contactList;

    Map<Id, sObject> sObjectMap = new Map<Id, sObject>();
    // put sObjects in the map in a way that incurs 6 chunks (A, C, A, C, A, C):
    sObjectMap.put(acctList[0].Id, acctList[0]);
    sObjectMap.put(contactList[0].Id, contactList[0]);
    sObjectMap.put(acctList[1].Id, acctList[1]);
    sObjectMap.put(contactList[1].Id, contactList[1]);
    sObjectMap.put(acctList[2].Id, acctList[2]);
    sObjectMap.put(contactList[2].Id, contactList[2]);

    Integer counter = 0;
    Integer numberOfChunks = 0;
    Integer numberOfChunksV2 = 0;
    String objectNameVar;
    // Since we have 2 object types in the map (Account and Contact) we should only have 1 switch (2 chunks) in the sorted version:
    for (Id sObjId : sObjectMap.keySet()) {
      String sObjName = sObjId.getSObjectType().getDescribe().getName();
      if (sObjName != objectNameVar) {
        numberOfChunks += 1;
      }
      objectNameVar = sObjName;
    }

    // before sorting, the number of chunks in the sObjectMap should be 6:
    Assert.areEqual(numberOfChunks, 6);

    // sort the sObjects by Id to consolidate the chunks:
    sObjectMap = ApexUtils.mapSorter(sObjectMap);

    counter = 0;
    numberOfChunks = 0;
    objectNameVar = null;
    // Since we have 2 object types in the map (Account and Contact) we should only have 1 switch (2 chunks) in the sorted version:
    for (Id sObjId : sObjectMap.keySet()) {
      String sObjName = sObjId.getSObjectType().getDescribe().getName();
      if (sObjName != objectNameVar) {
        numberOfChunks += 1;
      }
      objectNameVar = sObjName;
    }

    // after sorting, number of chunks in sObjectMap should be 2:
    Assert.areEqual(numberOfChunks, 2);
  }

  @isTest
  static void test_checkValidUsername() {
    Assert.isTrue(ApexUtils.checkValidUsername('foo@bar.com'));
    Assert.isFalse(ApexUtils.checkValidUsername('woooooooo'));
  }

  @isTest
  static void test_MapSorterByNumOfChildren() {
    List<Account> acctList = createTestAccounts();
    List<Contact> contactList = new List<Contact>();
    contactList.add(createTestContact(acctList[0]));
    contactList.add(createTestContact(acctList[0]));
    contactList.add(createTestContact(acctList[0]));
    contactList.add(createTestContact(acctList[2]));
    contactList.add(createTestContact(acctList[2]));
    contactList.add(createTestContact(acctList[1]));
    insert contactList;

    Schema.sObjectField contactField = Contact.AccountId.getDescribe()
      .getSObjectField();
    Map<String, List<sObject>> accountIdToContactsMap = ApexUtils.groupBy(
      contactList,
      contactField
    );
    accountIdToContactsMap = ApexUtils.mapSorterByNumOfChildren(
      accountIdToContactsMap
    ); // sort accounts by number of contacts ascending

    List<Integer> numOfContactsList = new List<Integer>();
    for (String accountId : accountIdToContactsMap.keySet()) {
      Integer numOfContacts = accountIdToContactsMap.get(accountId).size();
      numOfContactsList.add(numOfContacts);
    }

    // Verify the map got sorted by number of contacts ascending:
    Assert.areEqual(numOfContactsList[0], 1);
    Assert.areEqual(numOfContactsList[1], 2);
    Assert.areEqual(numOfContactsList[2], 3);
  }

  @isTest
  static void test_parseFieldPathForSObject() {
    List<Account> accounts = createTestAccounts();

    List<Contact> contactList = new List<Contact>();
    contactList.add(createTestContact(accounts[0]));
    insert contactList;

    Contact queriedContact = [
      SELECT Id, Name, Account.Name
      FROM Contact
      WHERE Id = :contactList[0].Id
      LIMIT 1
    ];

    Test.startTest();
    String accountName = (String) ApexUtils.parseFieldPathForSObject(
      queriedContact,
      'Account.Name'
    );
    String contactName = (String) ApexUtils.parseFieldPathForSObject(
      queriedContact,
      'Name'
    );
    Test.stopTest();

    Assert.areEqual(accountName, queriedContact.Account.Name);
    Assert.areEqual(contactName, queriedContact.Name);
  }

  @isTest
  static void test_fieldPermissionMethods() {
    Assert.isTrue(ApexUtils.isFieldUpdateable(Account.Name));
    Assert.isTrue(ApexUtils.isFieldAccessible(Account.Name));
    Assert.isTrue(ApexUtils.isFieldCreateable(Account.Name));
    Assert.isFalse(ApexUtils.isFieldUpdateable(Account.CreatedDate));
    Assert.isTrue(ApexUtils.isFieldAccessible(Account.CreatedDate));
    Assert.isFalse(ApexUtils.isFieldCreateable(Account.CreatedDate));
  }

  /** HELPER METHODS */
  private static List<Account> createTestAccounts() {
    List<Account> accounts = new List<Account>();
    accounts.add(new Account(Name = '1'));
    accounts.add(new Account(Name = '2'));
    accounts.add(new Account(Name = '3'));

    insert accounts;
    return accounts;
  }

  private static Contact createTestContact(Account account) {
    return new Contact(
      FirstName = account.Name,
      LastName = account.name,
      AccountId = account.Id
    );
  }

  private static Integer sObjectIdCounter = 1;
  private static String getFakeId(Schema.SobjectType sot) {
    String result = String.valueOf(sObjectIdCounter++);
    return sot.getDescribe().getKeyPrefix() +
      '0'.repeat(12 - result.length()) +
      result;
  }
}