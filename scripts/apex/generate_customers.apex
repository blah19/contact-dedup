// Anonymous Apex script to insert many Customer__c records with intentional duplicates and variations.
// Save this file and run via SFDX: sfdx force:apex:execute -f scripts/apex/generate_customers.apex
// Or copy/paste into the Developer Console -> Execute Anonymous.

List<Customer__c> toInsert = new List<Customer__c>();

// Note: anonymous Apex doesn't allow top-level static class/method declarations in some contexts.
// We'll inline record construction with object initializers instead of using a helper.

Date baseDate = Date.today().addDays(-200);

// Variations: common names, nickname vs formal, different phone formats, same emails
toInsert.add(new Customer__c(FirstName__c='William', LastName__c='Smith', Email__c='will.smith@example.com', Phone__c='+1 (555) 123-4567', Phone_Normalized__c='15551234567', SignupDate__c=baseDate.addDays(1)));
toInsert.add(new Customer__c(FirstName__c='Bill', LastName__c='Smith', Email__c='will.smith@example.com', Phone__c='555-123-4567', Phone_Normalized__c='15551234567', SignupDate__c=baseDate.addDays(2)));
toInsert.add(new Customer__c(FirstName__c='Will', LastName__c='Smith', Email__c='will.smith@example.com', Phone__c='(555)1234567', Phone_Normalized__c='15551234567', SignupDate__c=baseDate.addDays(3)));

// Same phone but different formatting
toInsert.add(new Customer__c(FirstName__c='Jane', LastName__c='Doe', Email__c='jane.doe@example.com', Phone__c='+44 20 7946 0958', Phone_Normalized__c='442079460958', SignupDate__c=baseDate.addDays(4)));
toInsert.add(new Customer__c(FirstName__c='Jane', LastName__c='Doe', Email__c='jdoe@example.com', Phone__c='020 7946 0958', Phone_Normalized__c='442079460958', SignupDate__c=baseDate.addDays(5)));
toInsert.add(new Customer__c(FirstName__c='J.', LastName__c='Doe', Email__c='jane.doe@example.com', Phone__c='2079460958', Phone_Normalized__c='442079460958', SignupDate__c=baseDate.addDays(6)));

// Similar names
toInsert.add(new Customer__c(FirstName__c='Robert', LastName__c='Brown', Email__c='robert.brown@example.com', Phone__c='(212) 555-0198', Phone_Normalized__c='12125550198', SignupDate__c=baseDate.addDays(7)));
toInsert.add(new Customer__c(FirstName__c='Bob', LastName__c='Brown', Email__c='robert.brown@example.com', Phone__c='212.555.0198', Phone_Normalized__c='12125550198', SignupDate__c=baseDate.addDays(8)));
toInsert.add(new Customer__c(FirstName__c='Rob', LastName__c='Brown', Email__c='rob.brown@example.com', Phone__c='+1-212-555-0198', Phone_Normalized__c='12125550198', SignupDate__c=baseDate.addDays(9)));

// Different people with same email
toInsert.add(new Customer__c(FirstName__c='Alice', LastName__c='Green', Email__c='shared.email@example.com', Phone__c='+1 303 555 0123', Phone_Normalized__c='13035550123', SignupDate__c=baseDate.addDays(10)));
toInsert.add(new Customer__c(FirstName__c='Alicia', LastName__c='Green', Email__c='shared.email@example.com', Phone__c='3035550123', Phone_Normalized__c='13035550123', SignupDate__c=baseDate.addDays(11)));

// Lots of near-duplicates with slight differences
for (Integer i = 0; i < 50; i++) {
    // Compute remainders without using the '%' operator (some environments reported parser errors)
    Integer r3 = i - (i / 3) * 3; // equivalent to i % 3
    Integer r4 = i - (i / 4) * 4; // equivalent to i % 4
    Integer r900 = i - (i / 900) * 900; // equivalent to i % 900

    String first = (r3 == 0) ? 'Bill' : ((r3 == 1) ? 'William' : 'Wm');
    String last = 'Jackson';
    String email = 'bill.jackson+' + i + '@example.com';
    String phoneFmt;
    String phoneNorm = '1555000' + String.valueOf(100 + r900);
    if (r4 == 0) phoneFmt = '+1-555-000-' + String.valueOf(100 + i);
    else if (r4 == 1) phoneFmt = '(555) 000-' + String.valueOf(100 + i);
    else if (r4 == 2) phoneFmt = '555.000.' + String.valueOf(100 + i);
    else phoneFmt = '555' + String.valueOf(100000 + (100 + i));
    toInsert.add(new Customer__c(FirstName__c=first, LastName__c=last, Email__c=email, Phone__c=phoneFmt, Phone_Normalized__c=phoneNorm, SignupDate__c=baseDate.addDays(20 + i)));
}

// Mix of international duplicates
toInsert.add(new Customer__c(FirstName__c='Chen', LastName__c='Li', Email__c='chen.li@example.cn', Phone__c='+86 10 8888 6666', Phone_Normalized__c='861088886666', SignupDate__c=baseDate.addDays(100)));
toInsert.add(new Customer__c(FirstName__c='Chen', LastName__c='Li', Email__c='chenli@example.cn', Phone__c='010-8888-6666', Phone_Normalized__c='861088886666', SignupDate__c=baseDate.addDays(101)));

// Random noisy variations
toInsert.add(new Customer__c(FirstName__c='Elizabeth', LastName__c='Taylor', Email__c='liz.t@example.com', Phone__c='+1 415 555 2671', Phone_Normalized__c='14155552671', SignupDate__c=baseDate.addDays(50)));
toInsert.add(new Customer__c(FirstName__c='Liz', LastName__c='Taylor', Email__c='elizabeth.t@example.com', Phone__c='4155552671', Phone_Normalized__c='14155552671', SignupDate__c=baseDate.addDays(51)));
toInsert.add(new Customer__c(FirstName__c='Beth', LastName__c='Taylor', Email__c='beth.t@example.com', Phone__c='(415) 555-2671', Phone_Normalized__c='14155552671', SignupDate__c=baseDate.addDays(52)));

// Some unique ones
toInsert.add(new Customer__c(FirstName__c='Unique', LastName__c='Person', Email__c='unique.person+'+String.valueOf(Datetime.now().getTime())+'@example.com', Phone__c='+1 999 999 9999', Phone_Normalized__c='19999999999', SignupDate__c=baseDate.addDays(150)));

// Bulk insert in batches to avoid governor limits
Integer BATCH = 200;
Integer successCount = 0;
Integer failureCount = 0;
List<Integer> failedGlobalIndexes = new List<Integer>();

for (Integer i = 0; i < toInsert.size(); i += BATCH) {
    Integer endIndex = Math.min(i + BATCH, toInsert.size());
    List<Customer__c> slice = new List<Customer__c>();
    for (Integer j = i; j < endIndex; j++) slice.add(toInsert[j]);

    // Use partial insert to capture per-record errors instead of aborting entire execution
    Database.SaveResult[] results = Database.insert(slice, false);
    for (Integer k = 0; k < results.size(); k++) {
        if (results[k].isSuccess()) {
            successCount++;
        } else {
            failureCount++;
            Integer globalIndex = i + k;
            failedGlobalIndexes.add(globalIndex);
            // Log which record failed and why
            String which = 'idx=' + String.valueOf(globalIndex) + ' name=' + slice[k].FirstName__c + ' ' + slice[k].LastName__c + ' email=' + slice[k].Email__c;
            for (Database.Error err : results[k].getErrors()) {
                System.debug('Insert error for ' + which + ' : ' + err.getStatusCode() + ' - ' + err.getMessage());
            }
        }
    }
}

System.debug('Insert summary - success=' + successCount + ' failures=' + failureCount + ' total_attempted=' + toInsert.size());
if (!failedGlobalIndexes.isEmpty()) {
    List<String> failedIdxStrings = new List<String>();
    for (Integer fi : failedGlobalIndexes) failedIdxStrings.add(String.valueOf(fi));
    System.debug('Failed global indexes: ' + String.join(failedIdxStrings, ','));
}

// Optional: show total count of records created with matching signup date
Integer created = [SELECT count() FROM Customer__c WHERE SignupDate__c >= :baseDate];
System.debug('Records in org with SignupDate >= baseDate: ' + created);
