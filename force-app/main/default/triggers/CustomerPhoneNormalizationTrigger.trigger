trigger CustomerPhoneNormalizationTrigger on Customer__c (before insert, before update) {
    CustomerPhoneNormalizationService.normalizePhones(Trigger.new);
}
