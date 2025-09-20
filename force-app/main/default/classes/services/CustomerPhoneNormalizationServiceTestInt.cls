@isTest
public class CustomerPhoneNormalizationServiceTestInt {
    @isTest
    static void testInsertCustomerPhoneNormalization() {
            TriggerControl.skipDuplicateMatchTrigger = true;
        Customer__c c = new Customer__c(Phone__c = '(234) 567-8910');
        insert c;
        Customer__c inserted = [SELECT Phone__c, Phone_Normalized__c FROM Customer__c WHERE Id = :c.Id LIMIT 1];
    Assert.areEqual('12345678910', inserted.Phone_Normalized__c, 'Inserted phone should be normalized');
            TriggerControl.skipDuplicateMatchTrigger = false;
    }

    @isTest
    static void testUpdateCustomerPhoneNormalization() {
            TriggerControl.skipDuplicateMatchTrigger = true;
        Customer__c c = new Customer__c(Phone__c = '234-567-8910');
        insert c;
        c.Phone__c = '+1 234 567 8910';
        update c;
        Customer__c updated = [SELECT Phone__c, Phone_Normalized__c FROM Customer__c WHERE Id = :c.Id LIMIT 1];
    Assert.areEqual('12345678910', updated.Phone_Normalized__c, 'Updated phone should be normalized');
            TriggerControl.skipDuplicateMatchTrigger = false;
    }

    @isTest
    static void testBlankPhoneNormalization() {
        TriggerControl.skipDuplicateMatchTrigger = true;
    Customer__c c = new Customer__c(Phone__c = '');
    insert c;
    Customer__c inserted = [SELECT Phone__c, Phone_Normalized__c FROM Customer__c WHERE Id = :c.Id LIMIT 1];
    Assert.areEqual(null, inserted.Phone_Normalized__c, 'Blank phone should result in null normalized');
        TriggerControl.skipDuplicateMatchTrigger = false;
    }
}
