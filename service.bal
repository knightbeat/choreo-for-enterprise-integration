import ballerinax/salesforce;
import ballerina/http;
import ballerina/log;

configurable string SF_BASE_URL = "https://demoteam-dev-ed.my.salesforce.com";
configurable string SF_TOKEN = "00D8d000001GOWT!AQcAQOAtW8QpRWMqJrIoPMnthBLJ6n6fqFiNxvMfX42GQNWoSc271dww4hZwyev6UxDYCzXgkSBlFo7MWq22miUCLUnt5ZWN";

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function post contacts(@http:Payload json payload) returns error? {
        
        // create Salesforce client
        salesforce:Client salesforceClient = check new (config = {
            baseUrl: SF_BASE_URL,
            auth: {
                token: SF_TOKEN
            }
        });

        record {} contactRecord = {
            "FirstName": "Max",
            "LastName": "Payne",
            "Title": "Mr",
            "Email": "max@demoteam.com",
            "Phone": "+447728202884",
            "AccountId": "0018d00000PMp4MAAT"
        };

        salesforce:CreationResponse|error salesforceResponse = salesforceClient->create("Contact", contactRecord);

        if salesforceResponse is salesforce:CreationResponse {
            log:printInfo(salesforceResponse.toJsonString());
        } else {
            log:printError(msg = salesforceResponse.message());
        }
    }

}
