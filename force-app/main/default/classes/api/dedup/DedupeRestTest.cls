@IsTest
private class DedupeRestTest {
    @TestSetup
    static void setupData() {
        Customer__c cA = new Customer__c(FirstName__c='A', LastName__c='Alpha', Email__c='a@x.com');
        Customer__c cB = new Customer__c(FirstName__c='B', LastName__c='Beta',  Email__c='b@x.com');
        Customer__c cC = new Customer__c(FirstName__c='C', LastName__c='Gamma', Email__c='c@x.com');
        Customer__c cD = new Customer__c(FirstName__c='D', LastName__c='Delta', Email__c='d@x.com');
        insert new List<Customer__c>{ cA, cB, cC, cD };

        Duplicate_Match__c m1 = new Duplicate_Match__c(Customer_A__c=cA.Id, Customer_B__c=cB.Id, Match_Score__c=95, Status__c='Pending Review');
        Duplicate_Match__c m2 = new Duplicate_Match__c(Customer_A__c=cC.Id, Customer_B__c=cD.Id, Match_Score__c=90, Status__c='Pending Review');
        insert new List<Duplicate_Match__c>{ m1, m2 };
    }

    @IsTest
    static void get_collection_without_expand() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/duplicate-matches';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DedupeRest.getRoute();
        Test.stopTest();

        String body = RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString();
        Map<String,Object> json = (Map<String,Object>)JSON.deserializeUntyped(body);
        List<Object> items = (List<Object>)json.get('items');
        Assert.isNotNull(items, 'items must exist');
        Assert.areEqual(2, items.size(), 'two pending matches expected');
    }

    @IsTest
    static void get_collection_with_expand() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/duplicate-matches?expand=customerA,customerB';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        DedupeRest.getRoute();
        Test.stopTest();

        String body = RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString();
        Map<String,Object> json = (Map<String,Object>)JSON.deserializeUntyped(body);
        List<Object> items = (List<Object>)json.get('items');
        Map<String,Object> first = (Map<String,Object>)items[0];
        Assert.isTrue(first.containsKey('customerA'), 'customerA expanded');
        Assert.isTrue(first.containsKey('customerB'), 'customerB expanded');
    }

    @IsTest
    static void get_item_with_and_without_expand() {
        Id id0 = [SELECT Id FROM Duplicate_Match__c WHERE Status__c='Pending Review' ORDER BY Match_Score__c DESC LIMIT 1].Id;

        RestRequest req1 = new RestRequest();
        req1.requestUri = '/services/apexrest/v1/duplicate-matches/' + String.valueOf(id0);
        req1.httpMethod = 'GET';
        RestContext.request = req1;
        RestContext.response = new RestResponse();

        Test.startTest();
        DedupeRest.getRoute();
        Test.stopTest();
        String body1 = RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString();
        Map<String,Object> j1 = (Map<String,Object>)JSON.deserializeUntyped(body1);
        Assert.areEqual(String.valueOf(id0), (String)j1.get('id'), 'id matches');

        RestRequest req2 = new RestRequest();
        req2.requestUri = '/services/apexrest/v1/duplicate-matches/' + String.valueOf(id0) + '?expand=customerA,customerB';
        req2.httpMethod = 'GET';
        RestContext.request = req2;
        RestContext.response = new RestResponse();

        Test.startTest();
        DedupeRest.getRoute();
        Test.stopTest();
        String body2 = RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString();
        Map<String,Object> j2 = (Map<String,Object>)JSON.deserializeUntyped(body2);
        Assert.isNotNull(j2.get('customerA'), 'customerA expanded');
        Assert.isNotNull(j2.get('customerB'), 'customerB expanded');
    }

    @IsTest
    static void patch_merged_and_ignored() {
        List<Duplicate_Match__c> ms = [SELECT Id FROM Duplicate_Match__c WHERE Status__c='Pending Review' ORDER BY Match_Score__c DESC LIMIT 2];

        RestRequest p1 = new RestRequest();
        p1.requestUri = '/services/apexrest/v1/duplicate-matches/' + String.valueOf(ms[0].Id);
        p1.httpMethod = 'PATCH';
        p1.requestBody = Blob.valueOf('{"status":"merged"}');
        RestContext.request = p1;
        RestContext.response = new RestResponse();

        Test.startTest();
        DedupeRest.patchRoute();
        Test.stopTest();
        Assert.areEqual(204, RestContext.response.statusCode, 'merged returns 204');

        RestRequest p2 = new RestRequest();
        p2.requestUri = '/services/apexrest/v1/duplicate-matches/' + String.valueOf(ms[1].Id);
        p2.httpMethod = 'PATCH';
        p2.requestBody = Blob.valueOf('{"status":"ignored"}');
        RestContext.request = p2;
        RestContext.response = new RestResponse();

        Test.startTest();
        DedupeRest.patchRoute();
        Test.stopTest();
        Assert.areEqual(204, RestContext.response.statusCode, 'ignored returns 204');

        List<Duplicate_Match__c> updated = [SELECT Status__c FROM Duplicate_Match__c WHERE Id IN :new List<Id>{ms[0].Id, ms[1].Id} ORDER BY Match_Score__c DESC];
        Assert.areEqual('Merged', updated[0].Status__c, 'first merged');
        Assert.areEqual('Ignored', updated[1].Status__c, 'second ignored');
    }

    @IsTest
    static void errors_invalid_status_and_unknown_id() {
        RestRequest bad = new RestRequest();
        bad.requestUri = '/services/apexrest/v1/duplicate-matches/001000000000000AAA';
        bad.httpMethod = 'PATCH';
        bad.requestBody = Blob.valueOf('{"status":"badstatus"}');
        RestContext.request = bad;
        RestContext.response = new RestResponse();

        Test.startTest();
        DedupeRest.patchRoute();
        Test.stopTest();
        Assert.areEqual(400, RestContext.response.statusCode, 'invalid status');

        RestRequest notFound = new RestRequest();
        notFound.requestUri = '/services/apexrest/v1/duplicate-matches/001000000000000AAA';
        notFound.httpMethod = 'GET';
        RestContext.request = notFound;
        RestContext.response = new RestResponse();

        Test.startTest();
        DedupeRest.getRoute();
        Test.stopTest();
        Assert.areEqual(404, RestContext.response.statusCode, 'not found');
    }

    
}
