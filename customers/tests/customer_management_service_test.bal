import ballerina/io;
import ballerina/http;
import ballerina/test;
import ballerina/log;

http:Client customerService = new("http://localhost:9292");

@test:Config
// Function to test GET request with ViewCustomers.
function testingViewCustomers() {
    boolean status;
    // Initialize the empty HTTP request.
    http:Request request;
    // Send 'GET' request and obtain the response.
    var response = customerService->get("/records/viewAll");
    if (response is http:Response) {
        var result = response.getTextPayload();

        if (result is string) {
            status = true;
        }
        else {
            status=false;
            log:printError("Error in fetching Text from response", err = result);
        }

        test:assertTrue(status, msg = "Request sending process failed!");
    }
}