/**
 * Author     : Kevin Antonioli (braveitnow@pm.me)
 * Description: provides apex unit tests for DynamicCloneController.cls
 * Created    : 02.27.2023
 */
@isTest
public class DynamicCloneControllerTest {
  @isTest
  static void test_getChildRelInfo() {
    Account account = new Account(Name = 'ABC Company');
    insert account;

    Contact contact = new Contact(
      FirstName = 'John',
      LastName = 'Doe',
      Email = 'johndoe@testtttt.com',
      AccountId = account.Id
    );
    insert contact;

    Opportunity opp = new Opportunity(
      Name = 'Test Opp 123',
      AccountId = account.Id
    );

    Test.startTest();
    List<DynamicCloneController.ChildInfo> childInfoList = DynamicCloneController.getChildRelInfo(
      account.Id,
      'Contacts, Opportunities'
    );
    Set<String> childRelNames = new Set<String>();
    for (DynamicCloneController.ChildInfo childInfo : childInfoList) {
      childRelNames.add(childInfo.relName);
    }
    Test.stopTest();

    Assert.isTrue(childRelNames.contains('Contacts'));
  }

  @isTest
  static void test_performDynamicClone() {
    Account account = new Account(Name = 'ABC Company');
    insert account;

    Contact contact = new Contact(
      FirstName = 'John',
      LastName = 'Doe',
      Email = 'johndoe@testtttt.com',
      AccountId = account.Id
    );
    insert contact;

    Opportunity opp = new Opportunity(
      Name = 'Test Opp 123',
      AccountId = account.Id
    );

    Test.startTest();
    DynamicCloneController.performDynamicClone(
      account.Id,
      'Contacts,Opportunities'
    );
    Test.stopTest();

    List<Contact> newClones = [SELECT Id FROM Contact WHERE Id != :contact.Id];
    Assert.isTrue(newClones.size() > 0);
  }
}