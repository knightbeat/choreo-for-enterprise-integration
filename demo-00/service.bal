import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/salesforce;
import ballerina/sql;
import ballerina/http;

const string RECORD_NOT_FOUND_IN_DB = "The given record was not found in the database";
const string SALESFORCE_QUERY_FOR_CONTACTS = "SELECT Id,FirstName,LastName,Email,Phone FROM Contact";

type DatabaseConfig record {|
    string host;
    int port;
    string user;
    string password;
    string database;
|};

type SalesforceConfig record {|
    string baseUrl;
    string token;
|};

configurable SalesforceConfig sfConfig = ?;
configurable DatabaseConfig dbConfigContacts = ?;

// Contact record type to be used with the database records
type Contact record {
    readonly string contact_id;
    string title;
    string last_name;
    string first_name;
    string phone;
    string email;
};

// Contact Request record type to be used in the request payload
type ContactRequest record {
    string account;
    string email;
};

// Processed Contact record type for Data Mapping
type ProcessedContactRecord record {
    string fullName;
    (anydata|string)? phoneNumber;
    (anydata|string)? email;
    string id;
};

// Processed Contacts Collection record type for Data Mapping
type ProcessedContactsCollection record {
    int numberOfContacts;
    ProcessedContactRecord[] contacts;
};

// Salesforce Contact record type for Data Mapping
type SalesforceContact record {
    record {
        string 'type;
        string url;
    } attributes;
    (anydata|string)? Email;
    string FirstName;
    (anydata|string)? Phone;
    string Id;
    string LastName;
};

// Salesforce Contact(s) Collection response type for Data Mapping
type SalesforceContactsResponse record {
    int totalSize;
    boolean done;
    SalesforceContact[] records;
};

function transform(SalesforceContactsResponse salesforceContactsResponse) returns ProcessedContactsCollection => {
    numberOfContacts: salesforceContactsResponse.totalSize,
    contacts: from var salesforceContactsResponseItem in salesforceContactsResponse.records
        select {
            fullName: salesforceContactsResponseItem.FirstName + " " + salesforceContactsResponseItem.LastName,
            phoneNumber: salesforceContactsResponseItem.Phone,
            email: salesforceContactsResponseItem.Email,
            id: salesforceContactsResponseItem.Id
        }
};


# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # A resource function to generate a contact record in salesforce.
    # + contactRequest - The received `ContactRequest` object
    # + return - Returns an `http:Accepted` or an `error` if there is a failure to serve the request.
    resource function post contacts(@http:Payload ContactRequest contactRequest) returns http:Accepted|error? {

        // retrieve contact details from database
        Contact|error? dataRecord = retrieveContactsFromDatabase(contactRequest);

        if (dataRecord is Contact) {
            // create contact record in salesforce
            salesforce:CreationResponse|error? createSalesforceContactResult = createSalesforceContact(dataRecord, contactRequest.account);
            if createSalesforceContactResult is error {
                return error(createSalesforceContactResult.message());
            } else {
                http:Accepted response = {body: {status: "success"}};
                return response;
            }
        }else{
            return error(RECORD_NOT_FOUND_IN_DB);
        }
    }

    # A resource function to retrieve contacts from salesforce.
    # + return - Returns a `ProcessedContactsCollection` or an `error` if there is a failure to serve the request.
    resource function get contacts() returns ProcessedContactsCollection|error? {
        
        ProcessedContactsCollection|error? salesforceContacts = fetchSalesforceContacts();

        return salesforceContacts;
    }

}

// function to retrieve contact details from database
function retrieveContactsFromDatabase(ContactRequest contactRequest) returns Contact|error? {
    mysql:Client mysqlEp = check new (
            host = dbConfigContacts.host,
        user = dbConfigContacts.user,
        password = dbConfigContacts.password,
        database = dbConfigContacts.database,
        port = dbConfigContacts.port);

        //io:println(contactRequest);
        string email = contactRequest.email;

        sql:ParameterizedQuery query = `select contact_id,title,last_name,first_name,phone,email from contacts where email=${email}`;

        Contact|sql:Error contact = mysqlEp->queryRow(query);

        return contact;
}

// function to create contact record in salesforce
function createSalesforceContact(Contact contact, string accountId) returns salesforce:CreationResponse|error? {
    salesforce:Client baseClient = check new (config = {
        baseUrl: sfConfig.baseUrl,
        auth: {
            token: sfConfig.token
        }
    });

    record {} contactRecord = {
        "FirstName": contact.first_name,
        "LastName": contact.last_name,
        "Title": contact.title,
        "Email": contact.email,
        "Phone": contact.phone,
        "AccountId": accountId
    };

    salesforce:CreationResponse|error response = baseClient->create("Contact", contactRecord);

    return response;
}

// function to retrieve contacts from salesforce
function fetchSalesforceContacts() returns ProcessedContactsCollection|error? {
    //string sFontactsResource = "/services/data/v56.0/query?q=SELECT Id,FirstName,LastName,Email,Phone FROM Contact";

    salesforce:Client salesForceClient = check new (config = {
        baseUrl: sfConfig.baseUrl,
        auth: {
            token: sfConfig.token
        }
    });

    salesforce:SoqlResult|salesforce:Error soqlResult = salesForceClient->getQueryResult(SALESFORCE_QUERY_FOR_CONTACTS);

    if (soqlResult is salesforce:SoqlResult) {

        json results = soqlResult.toJson();

        SalesforceContactsResponse salesforceContactsResponse = check results.cloneWithType(SalesforceContactsResponse);

        ProcessedContactsCollection contacts = transform(salesforceContactsResponse);

        return contacts;
        
    } else {
        return error(soqlResult.message());
    }

}
