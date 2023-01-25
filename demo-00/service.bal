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

configurable string SF_BASE_URL = "https://demoteam-dev-ed.my.salesforce.com";
configurable string SF_TOKEN = "00D8d000001GOWT!AQcAQGTs2sSZrRSqN5zs2C3FRCNlCCl.fLx2cSS0HKoTGbvf4xO3VHN_DW.rPhn5qlTcTnK4uzVXrUpoSHfXtnsUFX_c6YDL";


configurable DatabaseConfig dbConfigContacts = ?;
//configurable string DB_HOST = contactsdb.host;
// configurable int DB_PORT = 13928;
// configurable string DB_USER = "root";
// configurable string DB_PASSWORD = "rootWso2123";
// configurable string DB_NAME = "choreobase";

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