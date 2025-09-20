trigger CustomerDuplicateMatchTrigger on Customer__c (after insert, after update) {
    if (TriggerControl.skipDuplicateMatchTrigger) return;
    if (Trigger.isAfter) {
        Set<Id> customerIds = new Set<Id>();
        for (Customer__c c : Trigger.new) {
            customerIds.add(c.Id);
        }
        if (!customerIds.isEmpty()) {
            DuplicateMatchingService svc = new DuplicateMatchingService();
            svc.runAndSavePending(customerIds);
        }
    }
}
