/**
 * Author       : Kevin Antonioli (braveitnow@pm.me)
 * Description  : provides code coverage for DynamicCloneQueueable.cls
 * Created      : 2/27/2023
 */
@isTest
public class DynamicCloneQueueableTest {
  @isTest
  static void test_DynamicCloneQueueable() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    List<Contact> contacts = new List<Contact>();
    // create 250 contacts to clone:
    for (Integer i = 0; i < 250; i++) {
      contacts.add(
        new Contact(
          FirstName = acct.Name,
          LastName = 'Test' + Math.roundToLong(Math.random() * 10000000),
          AccountId = acct.Id
        )
      );
    }
    insert contacts;
    List<Contact> clones = new List<Contact>();
    for (Contact contact : contacts) {
      clones.add(contact.clone(false, false));
    }

    Test.startTest();
    Id jobId = System.enqueueJob(new DynamicCloneQueueable(clones));
    Test.stopTest();

    Assert.isFalse(
      [SELECT Id FROM Contact WHERE Id NOT IN :contacts].isEmpty()
    );
  }

  @isTest
  static void test_DynamicCloneQueueable_Exception() {
    Account acct = new Account(Name = 'Test Account');
    insert acct;

    List<Contact> contacts = new List<Contact>();
    // create 250 contacts to clone:
    for (Integer i = 0; i < 250; i++) {
      contacts.add(
        new Contact(
          FirstName = acct.Name,
          LastName = 'Test' + Math.roundToLong(Math.random() * 10000000),
          AccountId = acct.Id
        )
      );
    }
    insert contacts;

    Test.startTest();
    // throw a 'cannot specify id in insert call' exception in the class:
    Id jobId = System.enqueueJob(new DynamicCloneQueueable(contacts));
    Test.stopTest();

    Assert.isTrue([SELECT Id FROM Contact WHERE Id NOT IN :contacts].isEmpty());
  }
}