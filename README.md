# Contact Deduplication System

A Salesforce application for detecting and managing duplicate customer records with automated phone normalization and comprehensive duplicate matching capabilities.

## Features

- **Custom Objects**: `Customer__c` and `Duplicate_Match__c` with comprehensive field structure
- **Phone Normalization**: Automatic phone number standardization via triggers
- **Duplicate Detection**: Advanced matching algorithm based on names, emails, and normalized phone numbers
- **REST API**: Endpoints for retrieving and managing duplicate matches
- **Permission Management**: Dedicated permission set for deduplication users
- **Comprehensive Testing**: 36 test methods with 100% pass rate

## Quick Start

### Prerequisites
- Salesforce CLI installed and authenticated
- Node.js and npm installed
- VS Code with Salesforce Extensions (recommended)

### Complete Setup (New Environment)
```bash
npm run all
```
This single command will:
1. Create a new scratch org (30-day duration)
2. Deploy all metadata components
3. Assign the DeduplicationUser permission set
4. Run the complete test suite for validation

### Individual Commands

#### Development Environment
```bash
# Create a new scratch org
npm run scratch:create

# Deploy all metadata to the current org
npm run deploy:all

# Assign permissions to the current user
npm run permset:assign
```

#### Testing & Validation
```bash
# Run all Apex tests
npm run tests:apex

# Generate test data with duplicate scenarios
npm run data:generate
```

#### Code Quality
```bash
# Run ESLint on LWC/Aura components
npm run lint

# Format code with Prettier
npm run prettier

# Verify code formatting
npm run prettier:verify
```

## Architecture

### Custom Objects

#### Customer__c
- `FirstName__c` (Text): Customer's first name
- `LastName__c` (Text): Customer's last name  
- `Email__c` (Email): Customer's email address
- `Phone__c` (Phone): Raw phone number as entered
- `Phone_Normalized__c` (Text): Standardized phone format for matching
- `SignupDate__c` (Date): Customer registration date

#### Duplicate_Match__c
- `Customer_A__c` (Lookup): First customer in the potential match
- `Customer_B__c` (Lookup): Second customer in the potential match
- `Match_Score__c` (Number): Confidence score of the duplicate match
- `Status__c` (Picklist): Match status (Pending, Merged, Ignored)

### Core Services

#### CustomerPhoneNormalizationService
Handles phone number standardization:
- Removes formatting characters
- Applies international dialing codes
- Ensures consistent format for matching

#### DuplicateMatchingService  
Implements duplicate detection logic:
- Name similarity matching
- Email exact matching
- Normalized phone matching
- Composite scoring algorithm

### Data Access Layer

#### Loaders
- `CustomerLoader`: SOQL queries for Customer__c records
- `DuplicateMatchLoader`: SOQL queries for Duplicate_Match__c records

#### Savers
- `DuplicateMatchSaver`: DML operations for Duplicate_Match__c records

### REST API

**Base URL**: `/services/apexrest/dedup/`

#### Endpoints
- `GET /matches` - List all duplicate matches
- `GET /matches/{id}` - Get specific duplicate match
- `PATCH /matches/{id}` - Update match status

#### Query Parameters
- `expand=true` - Include related customer details in response

## Test Data Generation

The `scripts/apex/generate_customers.apex` file creates comprehensive test data:

- **65+ customer records** with intentional duplicate scenarios
- **Name variations**: William/Bill/Will Smith
- **Phone format variations**: Same numbers in different formats
- **Email patterns**: Shared emails and variations
- **International data**: Multi-locale phone numbers
- **Edge cases**: Unique records for negative testing

Run with: `npm run data:generate`

## Testing Strategy

### Test Coverage
- **36 total tests** across all components
- **100% pass rate** maintained
- **Isolated test data** using @TestSetup methods
- **Permission-based testing** with user context switching

### Test Categories
1. **Unit Tests**: Individual service and loader methods
2. **Integration Tests**: End-to-end trigger and service workflows  
3. **API Tests**: REST endpoint functionality and error handling
4. **Data Tests**: SOQL query accuracy and edge cases

### Test Naming Convention
Tests follow BDD-style naming:
```apex
whenCustomerInserted_thenPhoneIsNormalized()
whenSelectByEmailCalled_thenReturnsMatchingCustomer()
whenPatchCalledWithInvalidStatus_thenReturns400BadRequest()
```

## Permission Management

### DeduplicationUser Permission Set
Grants access to:
- Custom objects (Customer__c, Duplicate_Match__c)
- All custom fields (Read/Edit permissions)
- Apex classes and REST endpoints
- Standard objects as needed

Assign with: `npm run permset:assign`

## Development Workflow

### For New Team Members
```bash
# Complete environment setup
npm run all

# Generate test data
npm run data:generate

# Start development work
```

### For Ongoing Development
```bash
# Deploy changes
npm run deploy:all

# Run tests after changes
npm run tests:apex

# Validate code formatting
npm run prettier:verify
```

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── api/dedup/          # REST API endpoints
│   ├── interfaces/         # Service interfaces
│   ├── loaders/           # Data access layer
│   ├── savers/            # Data persistence layer
│   └── services/          # Business logic
├── objects/
│   ├── Customer__c/       # Customer object and fields
│   └── Duplicate_Match__c/ # Duplicate match object and fields
├── permissionsets/        # Permission configurations
└── triggers/              # Automated workflows
```

## Contributing

1. Create feature branch from `main`
2. Make changes and add/update tests
3. Run `npm run tests:apex` to ensure all tests pass
4. Run `npm run prettier` to format code
5. Submit pull request

## License

This project is licensed under the MIT License.
