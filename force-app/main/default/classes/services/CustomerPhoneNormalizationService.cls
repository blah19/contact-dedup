public class CustomerPhoneNormalizationService {
    public static void normalizePhones(List<Customer__c> customers) {
        for (Customer__c c : customers) {
            String rawPhone = c.Phone__c;
            if (String.isBlank(rawPhone)) {
                c.Phone_Normalized__c = '';
            } else {
                String digits = rawPhone.replaceAll('[^0-9]', '');
                if (digits.length() == 10) {
                    digits = '1' + digits;
                }
                c.Phone_Normalized__c = digits;
            }
        }
    }
}