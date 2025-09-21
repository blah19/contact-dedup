/**
 * REST API for managing potential duplicate customer records.
 *
 * The original spec was very simple:
 * - GET /duplicates/pending → returns list of customer pairs + match score
 * - POST /duplicates/{id}/resolve → body { "action": "merge" | "ignore" }
 *
 * I decided to structure it a little differently to follow modern REST patterns.
 * Instead of treating these like actions, I modeled duplicate pairs as a resource
 * called duplicate-matches.
 *
 * This allows:
 * - Listing pending matches with a filter, for example:
 *   GET /v1/duplicate-matches?status=pending
 * - Resolving a match by PATCHing its status, for example:
 *   PATCH /v1/duplicate-matches/{id} with {"status":"merged"}
 * - Consistent JSON contracts, standard HTTP semantics, and predictable error handling
 *
 * This approach keeps the API easier to work with from a UI perspective and makes it
 * simpler to extend later, like adding new statuses or pagination, without breaking clients.
 */

@RestResource(urlMapping='/v1/duplicate-matches/*')
global with sharing class DedupeRest {
    @TestVisible private static DuplicateMatchLoader matchLoader = new DuplicateMatchLoader();
    @TestVisible private static CustomerLoader customerLoader = new CustomerLoader();
    @TestVisible private static DuplicateMatchSaver matchSaver = new DuplicateMatchSaver();

    @HttpGet
    global static void getRoute() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String base = '/v1/duplicate-matches/';
        String tail = req.requestURI.contains(base) ? req.requestURI.substringAfter(base) : '';
        if (String.isBlank(tail)) {
            handleGetCollection(req, res);
        } else {
            handleGetItem(req, res, tail);
        }
    }

    @HttpPatch
    global static void patchRoute() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String base = '/v1/duplicate-matches/';
        String idStr = req.requestURI.contains(base) ? req.requestURI.substringAfter(base) : '';
        Id matchId = parseIdOr400(idStr, res);
        if (matchId == null) return;
        // Safely parse the request body as JSON object. If parsing fails we render a problem and return.
        Map<String, Object> body = parseRequestBodyAsMap(req, res);
        if (body == null) return;
        String statusReq = body.containsKey('status') ? String.valueOf(body.get('status')) : null;
        String pick = mapExternalStatusToPicklist(statusReq);
        if (pick == null) {
            renderProblem(res, 400, 'Invalid status value');
            return;
        }
        List<Duplicate_Match__c> rows = matchLoader.selectByIds(new Set<Id>{ matchId });
        if (rows.isEmpty()) {
            renderProblem(res, 404, 'Duplicate match not found');
            return;
        }
        List<Database.SaveResult> sr = matchSaver.updateStatus(new Set<Id>{ matchId }, pick);
        if (sr.isEmpty() || !sr[0].isSuccess()) {
            renderProblem(res, 409, 'Failed to update status');
            return;
        }
        res.statusCode = 204;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf('');
    }

    /**
     * Parse the incoming request body as a JSON object with robust error handling.
     * Returns a Map when successful, or null if an error response has already been written to `res`.
     */
    private static Map<String, Object> parseRequestBodyAsMap(RestRequest req, RestResponse res) {
        String contentType = null;
        if (req.headers != null) {
            for (String k : req.headers.keySet()) {
                if (k != null && k.toLowerCase() == 'content-type') {
                    contentType = req.headers.get(k);
                    break;
                }
            }
        }

        Blob b = req.requestBody;
        if (b == null || b.size() == 0) return new Map<String, Object>();

        String bodyStr;
        try {
            bodyStr = b.toString();
        } catch (Exception e) {
            // Could be binary or otherwise not convertible to string. Log base64 for diagnostics and return 415.
            String b64 = EncodingUtil.base64Encode(b);
            System.debug(LoggingLevel.ERROR, 'DedupeRest.parseRequestBodyAsMap: requestBody not convertible to string; contentType=' + contentType + ' size=' + b.size() + ' base64=' + b64);
            renderProblem(res, 415, 'Unsupported request body encoding');
            return null;
        }

        String trimmed = bodyStr == null ? '' : bodyStr.trim();
        if (trimmed.length() == 0) return new Map<String, Object>();

        // Quick heuristic: check first character to see if it looks like JSON
        String firstChar = trimmed.substring(0,1).toLowerCase();
        Set<String> allowedStart = new Set<String>{'{','[','"','-','0','1','2','3','4','5','6','7','8','9','t','f','n'};
        if (!allowedStart.contains(firstChar)) {
            // Log a short prefix for diagnostics; do not leak huge payloads into logs
            String prefix = trimmed.substring(0, Math.min(200, trimmed.length()));
            System.debug(LoggingLevel.ERROR, 'DedupeRest.parseRequestBodyAsMap: request body does not appear to be JSON. contentType=' + contentType + ' bodyPrefix=' + prefix);
            renderProblem(res, 400, 'Expected JSON body');
            return null;
        }

        try {
            Object parsed = JSON.deserializeUntyped(bodyStr);
            if (parsed == null) return new Map<String, Object>();
            if (parsed instanceof Map<String, Object>) return (Map<String, Object>) parsed;
            // If the payload is a JSON array or primitive, it's not the expected object shape
            renderProblem(res, 400, 'Expected JSON object body');
            return null;
        } catch (Exception e) {
            // Log error message, a short body prefix, and a base64 of the full body for debugging
            String prefix = trimmed.substring(0, Math.min(200, trimmed.length()));
            System.debug(LoggingLevel.ERROR, 'DedupeRest.parseRequestBodyAsMap: JSON parse error: ' + e.getMessage() + ' contentType=' + contentType + ' bodyPrefix=' + prefix);
            String b64 = EncodingUtil.base64Encode(b);
            System.debug(LoggingLevel.ERROR, 'DedupeRest.parseRequestBodyAsMap: full body base64=' + b64);
            renderProblem(res, 400, 'Invalid JSON body');
            return null;
        }
    }

    private static void handleGetCollection(RestRequest req, RestResponse res) {
        String statusParam = req.params != null ? req.params.get('status') : null;
        String expandParam = req.params != null ? req.params.get('expand') : null;
        String statusExt = String.isBlank(statusParam) ? 'pending' : statusParam.toLowerCase();
        if (statusExt != 'pending') {
            renderProblem(res, 400, 'Only pending status is supported');
            return;
        }
        Set<String> expand = parseExpandOr400(expandParam, res);
        if (expand == null) return;
        List<Duplicate_Match__c> matches = matchLoader.selectPending();
        Set<Id> custIds = new Set<Id>();
        if (!expand.isEmpty()) {
            for (Duplicate_Match__c m : matches) {
                if (expand.contains('customera')) custIds.add(m.Customer_A__c);
                if (expand.contains('customerb')) custIds.add(m.Customer_B__c);
            }
        }
        Map<Id, Customer__c> custMap = new Map<Id, Customer__c>();
        if (!custIds.isEmpty()) {
            for (Customer__c c : customerLoader.selectByIds(custIds)) custMap.put(c.Id, c);
        }
        List<Object> items = new List<Object>();
        for (Duplicate_Match__c m : matches) {
            Map<String, Object> obj = new Map<String, Object>();
            obj.put('id', String.valueOf(m.Id));
            obj.put('score', m.Match_Score__c);
            obj.put('status', 'pending');
            obj.put('customerAId', String.valueOf(m.Customer_A__c));
            obj.put('customerBId', String.valueOf(m.Customer_B__c));
            if (expand.contains('customera') && custMap.containsKey(m.Customer_A__c)) obj.put('customerA', toCustomerJson(custMap.get(m.Customer_A__c)));
            if (expand.contains('customerb') && custMap.containsKey(m.Customer_B__c)) obj.put('customerB', toCustomerJson(custMap.get(m.Customer_B__c)));
            items.add(obj);
        }
        Map<String, Object> payload = new Map<String, Object>{ 'items' => items };
        renderJson(res, payload);
    }

    private static void handleGetItem(RestRequest req, RestResponse res, String tail) {
        String idPart = tail.contains('?') ? tail.substringBefore('?') : tail;
        Id matchId = parseIdOr400(idPart, res);
        if (matchId == null) return;
        String expandParam = req.params != null ? req.params.get('expand') : null;
        Set<String> expand = parseExpandOr400(expandParam, res);
        if (expand == null) return;
        List<Duplicate_Match__c> rows = matchLoader.selectByIds(new Set<Id>{ matchId });
        if (rows.isEmpty()) {
            renderProblem(res, 404, 'Duplicate match not found');
            return;
        }
        Duplicate_Match__c m = rows[0];
        Set<Id> custIds = new Set<Id>();
        if (expand.contains('customera')) custIds.add(m.Customer_A__c);
        if (expand.contains('customerb')) custIds.add(m.Customer_B__c);
        Map<Id, Customer__c> custMap = new Map<Id, Customer__c>();
        if (!custIds.isEmpty()) {
            for (Customer__c c : customerLoader.selectByIds(custIds)) custMap.put(c.Id, c);
        }
        Map<String, Object> obj = new Map<String, Object>();
        obj.put('id', String.valueOf(m.Id));
        obj.put('score', m.Match_Score__c);
        obj.put('status', mapPicklistStatusToExternal(m.Status__c));
        obj.put('customerAId', String.valueOf(m.Customer_A__c));
        obj.put('customerBId', String.valueOf(m.Customer_B__c));
        if (expand.contains('customera') && custMap.containsKey(m.Customer_A__c)) obj.put('customerA', toCustomerJson(custMap.get(m.Customer_A__c)));
        if (expand.contains('customerb') && custMap.containsKey(m.Customer_B__c)) obj.put('customerB', toCustomerJson(custMap.get(m.Customer_B__c)));
        renderJson(res, obj);
    }

    private static Set<String> parseExpandOr400(String expandParam, RestResponse res) {
        Set<String> out = new Set<String>();
        if (String.isBlank(expandParam)) return out;
        for (String part : expandParam.split(',')) {
            String v = part == null ? '' : part.trim().toLowerCase();
            if (v != 'customera' && v != 'customerb') {
                renderProblem(res, 400, 'Invalid expand value');
                return null;
            }
            out.add(v);
        }
        return out;
    }

    private static Id parseIdOr400(String idStr, RestResponse res) {
        try {
            return Id.valueOf(idStr);
        } catch (Exception e) {
            renderProblem(res, 400, 'Invalid id');
            return null;
        }
    }

    private static String mapExternalStatusToPicklist(String s) {
        if (String.isBlank(s)) return null;
        String v = s.toLowerCase();
        if (v == 'merged') return 'Merged';
        if (v == 'ignored') return 'Ignored';
        if (v == 'pending') return 'Pending Review';
        return null;
    }

    private static String mapPicklistStatusToExternal(String s) {
        if (String.isBlank(s)) return null;
        String v = s.toLowerCase();
        if (v == 'pending review') return 'pending';
        if (v == 'merged') return 'merged';
        if (v == 'ignored') return 'ignored';
        return null;
    }

    private static Map<String, Object> toCustomerJson(Customer__c c) {
        if (c == null) return null;
        Map<String, Object> m = new Map<String, Object>();
        m.put('id', String.valueOf(c.Id));
        m.put('firstName', c.FirstName__c);
        m.put('lastName', c.LastName__c);
        m.put('email', c.Email__c);
        return m;
    }

    private static void renderJson(RestResponse res, Object obj) {
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(obj));
    }

    private static void renderProblem(RestResponse res, Integer code, String detail) {
        Map<String, Object> err = new Map<String, Object>{
            'type' => 'about:blank',
            'title' => code == 400 ? 'Bad Request' : code == 404 ? 'Not Found' : 'Error',
            'status' => code,
            'detail' => detail
        };
        res.statusCode = code;
        res.addHeader('Content-Type', 'application/problem+json');
        res.responseBody = Blob.valueOf(JSON.serialize(err));
    }
}