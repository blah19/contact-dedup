@isTest
public class CustomerPhoneNormalizationServiceTest {
    @isTest
    static void testNormalizePhones() {
        // Test with blank phone
        Customer__c blankPhone = new Customer__c(Phone__c = null);
        Customer__c emptyPhone = new Customer__c(Phone__c = '');
        // Test with formatted phone
        Customer__c formattedPhone = new Customer__c(Phone__c = '(234) 567-8910');
        Customer__c dashedPhone = new Customer__c(Phone__c = '234-567-8910');
        Customer__c countryCodePhone = new Customer__c(Phone__c = '+1 234 567 8910');
        List<Customer__c> customers = new List<Customer__c>{blankPhone, emptyPhone, formattedPhone, dashedPhone, countryCodePhone};
        CustomerPhoneNormalizationService.normalizePhones(customers);
        System.assertEquals('', blankPhone.Phone_Normalized__c, 'Blank phone should result in blank normalized');
        System.assertEquals('', emptyPhone.Phone_Normalized__c, 'Empty phone should result in blank normalized');
        System.assertEquals('12345678910', formattedPhone.Phone_Normalized__c, 'Formatted phone should normalize to 12345678910');
        System.assertEquals('12345678910', dashedPhone.Phone_Normalized__c, 'Dashed phone should normalize to 12345678910');
        System.assertEquals('12345678910', countryCodePhone.Phone_Normalized__c, 'Country code phone should normalize to 12345678910');
    }
}
