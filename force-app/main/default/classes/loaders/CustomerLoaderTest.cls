@IsTest(isParallel=false)
public class CustomerLoaderTest {
  private static Customer__c customer1;
  private static Customer__c customer2;
  private static Customer__c customer3;
  
  @TestSetup
  static void setupTestData() {
    TriggerControl.skipDuplicateMatchTrigger = true;
    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
      LIMIT 1
    ];
    User u = new User(
      Username = 'customerloaderuser-' +
        System.currentTimeMillis() +
        '@example.com',
      Email = 'customerloaderuser@example.com',
      Alias = 'cluser',
      LastName = 'test',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = p.Id
    );
    insert u;
    PermissionSet ps = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'DeduplicationUser'
      LIMIT 1
    ];
    insert new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetId = ps.Id
    );
    System.runAs(u) {
      // Seed customers
      customer1 = new Customer__c(
        FirstName__c = 'Alice',
        LastName__c = 'Smith',
        Email__c = 'alice@example.com',
        Phone__c = '(123) 456-7890',
        Phone_Normalized__c = '11234567890',
        SignupDate__c = Date.today()
      );
      customer2 = new Customer__c(
        FirstName__c = 'Bob',
        LastName__c = 'Smith',
        Email__c = 'bob@example.com',
        Phone__c = '(123) 456-7890',
        Phone_Normalized__c = '11234567890',
        SignupDate__c = Date.today()
      );
      customer3 = new Customer__c(
        FirstName__c = 'Carol',
        LastName__c = 'Jones',
        Email__c = 'carol@example.com',
        Phone__c = '(999) 888-7777',
        Phone_Normalized__c = '19998887777',
        SignupDate__c = Date.today()
      );
      insert new List<Customer__c>{ customer1, customer2, customer3 };
    }
    TriggerControl.skipDuplicateMatchTrigger = false;
  }

  @IsTest
  static void whenSelectAllCalled_thenReturnsAllCustomers() {
    CustomerLoader loader = new CustomerLoader();
    
    Test.startTest();
    List<Customer__c> result = loader.selectAll();
    Test.stopTest();
    
    System.assertEquals(3, result.size(), 'Should return all seeded customers');
  }

  @IsTest
  static void whenSelectByIdsCalled_thenReturnsMatchingCustomers() {
    List<Customer__c> customers = [SELECT Id FROM Customer__c LIMIT 3];
    Set<Id> targetIds = new Set<Id>{ customers[0].Id, customers[2].Id };
    CustomerLoader loader = new CustomerLoader();
    
    Test.startTest();
    List<Customer__c> result = loader.selectByIds(targetIds);
    Test.stopTest();
    
    System.assertEquals(2, result.size(), 'Should return customers by Id');
  }

  @IsTest
  static void whenSelectByEmailCalled_thenReturnsMatchingCustomer() {
    CustomerLoader loader = new CustomerLoader();
    
    Test.startTest();
    List<Customer__c> result = loader.selectByEmail('alice@example.com');
    Test.stopTest();
    
    System.assertEquals(1, result.size(), 'Should return customer by email');
    System.assertEquals('Alice', result[0].FirstName__c, 'Should return correct customer');
  }

  @IsTest
  static void whenSelectByEmailCalledWithNonExistentEmail_thenReturnsEmpty() {
    CustomerLoader loader = new CustomerLoader();
    
    Test.startTest();
    List<Customer__c> result = loader.selectByEmail('notfound@example.com');
    Test.stopTest();
    
    System.assertEquals(0, result.size(), 'Should return empty for no match');
  }

  @IsTest
  static void whenSelectByPhoneNormalizedCalled_thenReturnsMatchingCustomers() {
    CustomerLoader loader = new CustomerLoader();
    
    Test.startTest();
    List<Customer__c> result = loader.selectByPhoneNormalized('11234567890');
    Test.stopTest();
    
    System.assertEquals(2, result.size(), 'Should return customers sharing normalized phone');
  }

  @IsTest
  static void whenSelectByLastNameAndPhoneNormalizedCalled_thenReturnsMatchingCustomers() {
    CustomerLoader loader = new CustomerLoader();
    
    Test.startTest();
    List<Customer__c> result = loader.selectByLastNameAndPhoneNormalized('Smith', '11234567890');
    Test.stopTest();
    
    System.assertEquals(2, result.size(), 'Should return customers sharing last name and phone');
  }

  @IsTest
  static void whenSelectByPhoneNormalizedInCalled_thenReturnsMatchingCustomers() {
    CustomerLoader loader = new CustomerLoader();
    Set<String> phones = new Set<String>{ '11234567890', '19998887777' };
    
    Test.startTest();
    List<Customer__c> result = loader.selectByPhoneNormalizedIn(phones);
    Test.stopTest();
    
    System.assertEquals(3, result.size(), 'Should return all customers with matching normalized phones');
  }

  @IsTest
  static void whenSelectByEmailInCalled_thenReturnsMatchingCustomers() {
    CustomerLoader loader = new CustomerLoader();
    Set<String> emails = new Set<String>{ 'alice@example.com', 'carol@example.com' };
    
    Test.startTest();
    List<Customer__c> result = loader.selectByEmailIn(emails);
    Test.stopTest();
    
    System.assertEquals(2, result.size(), 'Should return customers with matching emails');
  }

  @IsTest
  static void whenSelectByLastNameInCalled_thenReturnsMatchingCustomers() {
    CustomerLoader loader = new CustomerLoader();
    Set<String> lastNames = new Set<String>{ 'Smith', 'Jones' };
    
    Test.startTest();
    List<Customer__c> result = loader.selectByLastNameIn(lastNames);
    Test.stopTest();
    
    System.assertEquals(3, result.size(), 'Should return all customers with matching last names');
  }
}
