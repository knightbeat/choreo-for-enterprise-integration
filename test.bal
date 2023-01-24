import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/salesforce;
import ballerina/log;
import ballerina/sql;
import ballerina/io;

configurable string SF_BASE_URL = "https://demoteam-dev-ed.my.salesforce.com";
configurable string SF_TOKEN = "00D8d000001GOWT!AQcAQOAtW8QpRWMqJrIoPMnthBLJ6n6fqFiNxvMfX42GQNWoSc271dww4hZwyev6UxDYCzXgkSBlFo7MWq22miUCLUnt5ZWN";

type Contact record {
    readonly string contact_id;
    string title;
    string last_name;
    string first_name;
    string phone;
    string email;
};

public function main() returns error? {

    mysql:Client mysqlEp = check new (host = "localhost", user = "root", password = "rootWso2123", database = "choreobase", port = 3306);

    sql:ParameterizedQuery query = `select contact_id,title,last_name,first_name,phone,email from contacts where email='alan@demoteam.com'`;

    Contact|sql:Error contact = mysqlEp->queryRow(query);

    if(contact is Contact){
        error? insertToSalesforceResult = insertToSalesforce(contact, "0018d00000PMp4MAAT");
        if insertToSalesforceResult is error {
            log:printError(insertToSalesforceResult.message());
        }
    }else{
        io:println(contact);
    }
}

function insertToSalesforce(Contact contact, string accountId) returns error? {
    salesforce:Client baseClient = check new (config = {
        baseUrl: SF_BASE_URL,
        auth: {
            token: SF_TOKEN
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
