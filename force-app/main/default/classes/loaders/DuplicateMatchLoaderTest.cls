@IsTest
public class DuplicateMatchLoaderTest {
  private static Customer__c customerA;
  private static Customer__c customerB;
  private static Duplicate_Match__c match1;
  private static Duplicate_Match__c match2;
  private static Duplicate_Match__c match3;

  @TestSetup
  static void setupTestData() {
    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
      LIMIT 1
    ];
    User u = new User(
      Username = 'testloaderadmin@example.com',
      lastName = 'Admin',
      Email = 'testloaderadmin@example.com',
      Alias = 'tadmin',
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
      customerA = new Customer__c(
        FirstName__c = 'A',
        Email__c = 'a@x.com',
        Phone__c = '(111) 111-1111',
        Phone_Normalized__c = '11111111111',
        SignupDate__c = Date.today(),
        LastName__c = 'Alpha'
      );
      customerB = new Customer__c(
        FirstName__c = 'B',
        Email__c = 'b@x.com',
        Phone__c = '(222) 222-2222',
        Phone_Normalized__c = '12222222222',
        SignupDate__c = Date.today(),
        LastName__c = 'Beta'
      );
      insert new List<Customer__c>{ customerA, customerB };
      
      // Seed matches
      match1 = new Duplicate_Match__c(
        Customer_A__c = customerA.Id,
        Customer_B__c = customerB.Id,
        Match_Score__c = 100,
        Status__c = 'Pending Review'
      );
      match2 = new Duplicate_Match__c(
        Customer_A__c = customerB.Id,
        Customer_B__c = customerA.Id,
        Match_Score__c = 50,
        Status__c = 'Merged'
      );
      match3 = new Duplicate_Match__c(
        Customer_A__c = customerA.Id,
        Customer_B__c = customerB.Id,
        Match_Score__c = 70,
        Status__c = 'Pending Review'
      );
      insert new List<Duplicate_Match__c>{ match1, match2, match3 };
    }
  }

  @IsTest
  static void whenSelectByIdsCalled_thenReturnsMatchingRecords() {
    List<Duplicate_Match__c> allMatches = [SELECT Id FROM Duplicate_Match__c LIMIT 3];
    Set<Id> targetIds = new Set<Id>{ allMatches[0].Id, allMatches[1].Id };
    DuplicateMatchLoader loader = new DuplicateMatchLoader();
    
    Test.startTest();
    List<Duplicate_Match__c> result = loader.selectByIds(targetIds);
    Test.stopTest();
    
    Assert.areEqual(2, result.size(), 'Should return matches by Id');
  }

  @IsTest
  static void whenSelectByIdsCalledWithEmptySet_thenReturnsEmpty() {
    DuplicateMatchLoader loader = new DuplicateMatchLoader();
    
    Test.startTest();
    List<Duplicate_Match__c> result = loader.selectByIds(new Set<Id>());
    Test.stopTest();
    
    Assert.areEqual(0, result.size(), 'Should return empty for no match');
  }

  @IsTest
  static void whenSelectPendingCalled_thenReturnsPendingMatchesOrderedByScore() {
    DuplicateMatchLoader loader = new DuplicateMatchLoader();
    
    Test.startTest();
    List<Duplicate_Match__c> result = loader.selectPending();
    Test.stopTest();
    
    Assert.areEqual(2, result.size(), 'Should return only pending matches');
    Assert.areEqual(100, result[0].Match_Score__c, 'Pending matches ordered by score desc');
    Assert.areEqual(70, result[1].Match_Score__c, 'Pending matches ordered by score desc');
  }

  @IsTest
  static void whenSelectByCustomerCalled_thenReturnsAllMatchesForCustomer() {
    List<Customer__c> customers = [SELECT Id FROM Customer__c LIMIT 2];
    DuplicateMatchLoader loader = new DuplicateMatchLoader();
    
    Test.startTest();
    List<Duplicate_Match__c> resultA = loader.selectByCustomer(customers[0].Id);
    List<Duplicate_Match__c> resultB = loader.selectByCustomer(customers[1].Id);
    Test.stopTest();
    
    Assert.areEqual(3, resultA.size(), 'Should return all matches for customer A');
    Assert.areEqual(3, resultB.size(), 'Should return all matches for customer B');
  }
}
