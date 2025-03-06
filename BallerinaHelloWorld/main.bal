import ballerina/io;
import ballerina/http;

configurable string token = ?;

public function main() {
    io:println("Hello, World!");
}

service /composite on new http:Listener(8081) {

    resource function get customers/[string id](http:Caller caller, http:Request req) returns error? {
        http:Client cdpClient = check new ("https://b48cc93e-fa33-4420-a155-bc653b4d46be-dev.e1-eu-north-azure.choreoapis.dev/chathura/cdp-service/v1");
        http:Response cdpResponse = check cdpClient->get("/customers/" + id, {Authorization: "Bearer " + token});
        json response = check cdpResponse.getJsonPayload();
        checkpanic caller->respond(response);
    }
}
