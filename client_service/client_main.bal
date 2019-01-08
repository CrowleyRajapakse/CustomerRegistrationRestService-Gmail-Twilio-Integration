import wso2/gmail;
import wso2/twilio;
import ballerina/config;
import ballerina/http;
import ballerina/io;
import ballerina/log;

// Host name of the server hosting the customer administration system.
http:Client customerService = new("http://localhost:9292");

twilio:Client twilioClient = new({
        accountSId: config:getAsString(TWILIO_ACCOUNT_SID),
        authToken: config:getAsString(TWILIO_AUTH_TOKEN)
    });

public function main() {
    http:Request req = new;
    int operation = 0;
    while (operation != 6) {
        // Print options menu to choose from.
        io:println("Select operation.");
        io:println("1. Add customer");
        io:println("2. View all customers");
        io:println("3. Exit \n");

        // Read user's choice.
        string choice = io:readln("Enter choice 1 - 3: ");
        if (!isInteger(choice)) {
            io:println("Choice must be of a number");
            io:println();
            continue;
        }
        var intOperation = int.convert(choice);
        if (intOperation is int) {
            io:println(intOperation);
            operation = intOperation;
        } else {
            log:printError("Error in converting the option selected by the user to an integer.", err = intOperation);
        }
        // Program runs until the user inputs 3 to terminate the process.
        match operation {
            1 => addCustomer(req);
            2 => viewAllCustomers();
            3 => break;
            _ => io:println("Invalid choice");
        }
    }
}

// Function to check if the input is an integer.
function isInteger(string input) returns boolean {
    string regEx = "\\d+";
    boolean|error isInt = input.matches(regEx);
    if (isInt is error) {
        log:printError("Error in checking if the type of the input variable is integer", err = isInt);
        return false;
    } else {
        return isInt;
    }

}

// Function to add details of a student to the database.
function addCustomer(http:Request req) {
    // Get customer name, age mobile number, email.
    var name = io:readln("Enter Customer name: ");
    var age = io:readln("Enter Customer age: ");
    var mobile = io:readln("Enter mobile number: ");
    var email = io:readln("Enter Customer Email address: ");
    var ageAsInt = int.convert(age);
    var mobNoAsInt = int.convert(mobile);

    if (ageAsInt is int && mobNoAsInt is int) {
        // Create the request as JSON message.
        json jsonMsg = { "name": name, "age": ageAsInt, "mobNo": mobNoAsInt, "email": email, "id": 0 };
        req.setJsonPayload(jsonMsg);

    } else {
        log:printError("Error in converting the age and the mobile number to integers.", err = ageAsInt);
        return;
    }

    // Sending the request to the students service and getting the response from it.
    var resp = customerService->post("/records/addCustomer", req);

    if (resp is http:Response) {
        // Extracting data from the received JSON object..
        var jsonMsg = resp.getJsonPayload();
        if (jsonMsg is json) {
            string message = "Status: " + jsonMsg["Status"] .toString() + " Added Customer Id :- " +
                jsonMsg["id"].toString();
            io:println(message);
            boolean result = sendSmsToCustomers(sampleQuery);
            if (result) {
                log:printDebug("CustomerRegistration-Twilio Integration -> Promotional SMS sending process successfully completed!");
            } else {
                log:printDebug("CustomerRegistration-Twilio Integration -> Promotional SMS sending process failed!");
            }
        } else {
            log:printError("Error in extracting the JSON payload from the response.", err = jsonMsg);
        }
    } else {
        log:printError("Error in the obtained response", err = resp);
    }
}

// Function to view details of all the customers.
function viewAllCustomers() {
    // Sending a request to list down all customers and get the response from it.
    var response = customerService->post("/records/viewAll", null);
    if (response is http:Response) {
        var jsonMsg = response.getJsonPayload();

        if (jsonMsg is json) {
            string message = "";

            if (jsonMsg.length() >= 1) {
                int i = 0;
                while (i < jsonMsg.length()) {

                    message = "Customer Name: " + jsonMsg[i]["name"] .toString() + ", " + " Customer Age: " +
                        jsonMsg[i]["age"] .toString();

                    io:println(message);
                    i += 1;
                }
            } else {
                // Notify user if no records are available.
                message = "\n Customer record is empty";
                io:println(message);
            }

        } else {
            log:printError("Error in extracting JSON from response", err = jsonMsg);
        }

    } else {
        log:printError("Error in obtained response", err = response);
    }
}

