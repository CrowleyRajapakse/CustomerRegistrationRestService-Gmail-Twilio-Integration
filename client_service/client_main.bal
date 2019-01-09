import wso2/gmail;
import wso2/twilio;
import ballerina/config;
import ballerina/http;
import ballerina/io;
import ballerina/log;

# A valid access token with gmail access.
string accessToken = config:getAsString("ACCESS_TOKEN");

# The client ID for your application.
string clientId = config:getAsString("CLIENT_ID");

# The client secret for your application.
string clientSecret = config:getAsString("CLIENT_SECRET");

# A valid refreshToken with gmail access.
string refreshToken = config:getAsString("REFRESH_TOKEN");

# Sender email address.
string senderEmail = config:getAsString("SENDER");

# The user's email address.
string userId = config:getAsString("USER_ID");

# A valid SID with Twilio
string sid = config:getAsString("TWILIO_ACCOUNT_SID");

# A valid Auth Token with Twilio
string auth = config:getAsString("TWILIO_AUTH_TOKEN");



// Host name of the server hosting the customer administration system.
http:Client customerService = new("http://localhost:9292");

// Twilio REST service configurations .
http:Client httpEndpoint = new("https://api.twilio.com", config = {
        auth: {
            scheme: http:BASIC_AUTH,
            username:sid,
            password:auth
        }
    });

// Twilio Ballerina-Connector Configurations - Not Working Properly
twilio:Client twilioClient = new({

        accountSId: config:getAsString(TWILIO_ACCOUNT_SID),
        authToken: config:getAsString(TWILIO_AUTH_TOKEN)

    });

# GMail client endpoint declaration with oAuth2 client configurations.
gmail:Client gmailClient = new({
        clientConfig: {
            auth: {
                scheme: http:OAUTH2,
                accessToken: accessToken,
                refreshToken: refreshToken,
                clientId: clientId,
                clientSecret: clientSecret
            }
        }
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

// Function to add details of a customer to the database.
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

    // Sending the request to the customer service and getting the response from it.
    var resp = customerService->post("/records/addCustomer", req);

    if (resp is http:Response) {
        // Extracting data from the received JSON object..
        var jsonMsg = resp.getJsonPayload();
        if (jsonMsg is json) {
            string message = "Status: " + jsonMsg["Status"] .toString() + " Added Customer Id :- " +
                jsonMsg["id"].toString();
            log:printInfo(message);

            log:printDebug("CustomerRegistration-Twilio  Integration -> Sending notification to customers");


            boolean resultSMS = sendSmsToCustomers(mobile);
            if (resultSMS) {
                log:printDebug("CustomerRegistration-Twilio Integration -> Registration SMS sending process successfully completed!");
            } else {
                log:printDebug("CustomerRegistration-Twilio Integration -> Registration SMS sending process failed!");
            }

            log:printDebug("CustomerRegistration-Gmail Integration -> Sending notification to customers");
            boolean resultEmail = sendNotification(email);
            if (resultEmail) {
                log:printDebug("CustomerRegistration-Gmail Integration -> Sending email notification to customers successfully completed!");
            } else {
                log:printDebug("CustomerRegistration-Gmail Integration -> Sending email notification to customers failed!");
            }

        } else {
            log:printError("Error in extracting the JSON payload from the response.", err = jsonMsg);
        }
    } else {
        log:printError("Error in the obtained response", err = resp);
    }
}

# Utility function integrate CustomerRegistrationService and Twilio connectors/Rest API and indicates the status of sending.
#
# + return - State of whether the process of sending SMS to customers are success or not
function sendSmsToCustomers(string mobile) returns boolean {

    http:Request req =new;
    json payload ={
        From:config:getAsString(TWILIO_FROM_MOBILE),
        To:config:getAsString(TWILIO_TO_MOBILE)
    } ;
    //var text="From=+18125670972&+94717313761&Body=testing";
    //text.b

    req.setTextPayload("From=%2B18125670972&To=%2B94717313761&Body=testing");
    req.setHeader( "Content-Type", "application/x-www-form-urlencoded");


    var response = httpEndpoint->post("/2010-04-01/Accounts/AC2017862cf42fac3b8b7a497377052064/Messages.json",req);
    if (response is http:Response) {
        var result = response.getPayloadAsString();
        log:printInfo((result is error) ? "Failed to retrieve payload."
                                        : "Sent SMS to the customer");
    } else {
        log:printError("Failed to call the endpoint.", err = response);
    }
    return true;

    //Code Related the ballerina-Twilio-Connector
    //boolean isSuccess= false;
    //string toMobile = mobile;
    //string messageBody = config:getAsString("TWILIO_MESSAGE");
    //string fromMobile = config:getAsString("TWILIO_FROM_MOBILE");
    //string message = messageBody;
    //var response = twilioClient->sendSms(fromMobile, toMobile, message);
    //if (response is twilio:SmsResponse) {
    //    if (response.sid != EMPTY_STRING) {
    //        log:printDebug("Twilio Connector -> SMS successfully sent to " + toMobile);
    //        return true;
    //    }
    //} else {
    //    log:printDebug("Twilio Connector -> SMS failed sent to " + toMobile);
    //    log:printError(<string>response.detail().message);
    //}
    //return isSuccess;
}

# Returns an indication of the status of the sending notification to the customers.
#
# + return - State of whether the process of sending notification is success or not
function sendNotification(string email) returns boolean {

    boolean isSuccess = false;
        string customerEmail = email;
        string subject = "Thank You for Registering ";
        isSuccess = sendMail(customerEmail, subject, getCustomEmailTemplate());
        if (!isSuccess) {
            return false;
        }
        return isSuccess;
}

# Get the customized email template.
#
# + return - String customized email message.
function getCustomEmailTemplate() returns string {
    string emailTemplate = "<h2> Hi New User"+ " </h2>";
    emailTemplate = emailTemplate + "<h3> Thank you for Registering  with us" + " ! </h3>";
    emailTemplate = emailTemplate + "<p> If you still have questions" +
        ", please contact us and we will get in touch with you right away ! </p> ";
    return emailTemplate;
}

# Send email with the given message body to the specified recipient for dowloading the specified product and return the
# indication of sending is succss or not.
#
# + customerEmail - Recipient's email address.
# + subject - Subject of the email.
# + messageBody - Email message body to send.
# + return - The status of sending email success or not
function sendMail(string customerEmail, string subject, string messageBody) returns boolean {
    //Create html message
    gmail:MessageRequest messageRequest = {};
    messageRequest.recipient = customerEmail;
    messageRequest.sender = senderEmail;
    messageRequest.subject = subject;
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint messageRequest);
    string messageId;
    string threadId;
    if (sendMessageResponse is (string, string)) {
        (messageId, threadId) = sendMessageResponse;
        log:printInfo("Sent email to " + customerEmail + " with message Id: " + messageId +
                " and thread Id:" + threadId);
        return true;
    } else {
        log:printInfo(<string>sendMessageResponse.detail().message);
        return false;
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

