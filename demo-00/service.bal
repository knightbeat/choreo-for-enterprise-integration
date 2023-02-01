import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/salesforce;
import ballerina/log;
import ballerina/sql;
import ballerina/io;
import ballerina/http;

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

type Contact record {
    readonly string contact_id;
    string title;
    string last_name;
    string first_name;
    string phone;
    string email;
};

type ContactRequest record {
    string account;
    string email;
};

type SaleasforceResponseContactAttributes record {
    string 'type;
    string url;
};

type SaleasforceResponseContactRecord record {
    SaleasforceResponseContactAttributes attributes;
    string Id;
    string FirstName;
    string LastName;
    string Email;
    string Phone;
};

type SaleasforceResponseContacts record {
    int totalSize;
    boolean done;
    SaleasforceResponseContactRecord[] records;
};

type ProcessedContactRecord record {
    string fullName;
    (anydata|string)? phoneNumber;
    (anydata|string)? email;
    string id;
};

type ProcessedContactsCollection record {
    int numberOfContacts;
    ProcessedContactRecord[] contacts;
};

type SalesforceContactResponse record {
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

type SalesforceContactsResponse record {
    int totalSize;
    boolean done;
    SalesforceContactResponse[] records;
};

function transform(SalesforceContactsResponse salesforceContactsResponse) returns ProcessedContactsCollection => {
    numberOfContacts: salesforceContactsResponse.totalSize,
    contacts: from var salesforceContactsResponseItem in salesforceContactsResponse.records
        select {
            fullName: salesforceContactsResponseItem.FirstName +" "+ salesforceContactsResponseItem.LastName,
            phoneNumber: salesforceContactsResponseItem.Phone,
            email: salesforceContactsResponseItem.Email,
            id: salesforceContactsResponseItem.Id
        }
};

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function post contacts(@http:Payload ContactRequest contactRequest) returns error? {

        mysql:Client mysqlEp = check new (
            host = dbConfigContacts.host,
        user = dbConfigContacts.user,
        password = dbConfigContacts.password,
        database = dbConfigContacts.database,
        port = dbConfigContacts.port);

        io:println(contactRequest);
        string email = contactRequest.email;

        sql:ParameterizedQuery query = `select contact_id,title,last_name,first_name,phone,email from contacts where email=${email}`;

        Contact|sql:Error contact = mysqlEp->queryRow(query);

        if (contact is Contact) {
            error? insertToSalesforceResult = insertToSalesforce(contact, contactRequest.account);
            if insertToSalesforceResult is error {
                log:printError(insertToSalesforceResult.message());
            }
        } else {
            io:println(contact);
        }
    }

    resource function get contacts() returns ProcessedContactsCollection|error? {
        error|ProcessedContactsCollection salesforceContacts = getSalesforceContacts();

        return salesforceContacts;
    }

}

function insertToSalesforce(Contact contact, string accountId) returns error? {
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

    salesforce:CreationResponse|error res = baseClient->create("Contact", contactRecord);

    if res is salesforce:CreationResponse {
        log:printInfo(res.toJsonString());
    } else {

        log:printError(msg = res.message());
    }
}

function getSalesforceContacts() returns error|ProcessedContactsCollection {
    //string sFontactsResource = "/services/data/v56.0/query?q=SELECT Id,FirstName,LastName,Email,Phone FROM Contact";

    salesforce:Client baseClient = check new (config = {
        baseUrl: sfConfig.baseUrl,
        auth: {
            token: sfConfig.token
        }
    });

    salesforce:SoqlResult|salesforce:Error soqlResult = baseClient->getQueryResult("SELECT Id,FirstName,LastName,Email,Phone FROM Contact");

    if (soqlResult is salesforce:Error) {
        log:printError(msg = soqlResult.message());
        return error(soqlResult.message());
    } else {
        json results = soqlResult.toJson();

        SalesforceContactsResponse response = check results.cloneWithType(SalesforceContactsResponse);

        ProcessedContactsCollection contacts = transform(response);

        io:println(contacts);

        return contacts;
    }

}
