---
mode: agent
---

# AI.md
## Purpose
This document captures lessons learned around Salesforce query security and safe assertions to guide future development.

---

## 1. Enforcing FLS and Sharing in SOQL

### Overview
Salesforce now provides **query execution modes** and **security clauses** to ensure field-level security (FLS), object-level permissions, and record sharing are consistently respected at the query level.

---

### WITH USER_MODE
- Runs the query **as the current user**.
- Enforces:
  - Field-level security
  - Object-level CRUD permissions
  - Record-level sharing rules
- Any fields the user does **not** have access to are **automatically removed** from the query results instead of throwing an error.
- Use for **end-user facing features**, e.g., APIs or UI queries.

**Example:**
```
SELECT Id, Name
FROM Account
WHERE CreatedDate = TODAY
WITH USER_MODE
ORDER BY Name
```

---

### WITH SYSTEM_MODE
- Runs the query with **full system permissions**, ignoring FLS and sharing.
- Behaves like a typical Apex query prior to this feature.
- Use for **back-end processes** where you explicitly need to bypass sharing and FLS, such as background data cleanup or integration jobs.

**Example:**
```
SELECT Id, Name
FROM Account
WHERE CreatedDate = TODAY
WITH SYSTEM_MODE
ORDER BY Name
```

---

### WITH SECURITY_ENFORCED
- Strict enforcement of FLS and object permissions.
- **Throws a runtime exception** if any selected field or object is not accessible.
- Use when you need to **fail fast** if a user lacks access to a required field.

**Example:**
```
SELECT Id, Name, Confidential_Field__c
FROM Account
WITH SECURITY_ENFORCED
ORDER BY Name
```

---

## 2. Assert Class vs. System.assert

Salesforce provides the **`Assert` class** in the Apex testing framework.  
This is preferred over `System.assert` because it includes clearer failure messages and is purpose-built for test validation.

### Methods
- `Assert.areEqual(expected, actual, message)`
- `Assert.areNotEqual(notExpected, actual, message)`
- `Assert.isTrue(condition, message)`
- `Assert.isFalse(condition, message)`
- `Assert.isNull(object, message)`
- `Assert.isNotNull(object, message)`

### Example:
```
Integer expected = 5;
Integer actual = someService.calculateTotal();

Assert.areEqual(expected, actual, 'Total should equal 5');
```

**Key Benefit:**  
Test results are easier to interpret, and your tests remain clean and explicit.

