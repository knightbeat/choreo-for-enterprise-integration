import ballerina/io;
import ballerina/http;

public function main() {
    io:println("Hello, World!");
}

service /composite on new http:Listener(8081) {

    resource function get customers/[string id](http:Caller caller, http:Request req) returns error? {
        http:Client cdpClient = check new ("http://localhost:8080");
        http:Response cdpResponse = check cdpClient->get("/cdp/customers/" + id);
        json response = check cdpResponse.getJsonPayload();
        checkpanic caller->respond(response);
    }
}
