import ballerina/log;
import ballerina/test;

@test:Config
function testSendSmsToCustomers() {
    log:printDebug("CustomerRegistration-Twilio Integration -> Registration SMS sending process successfully started!");
    string mobile = "+94717313761";
    boolean result = sendSmsToCustomers(mobile);
    test:assertTrue(result, msg = "SMS sending process failed!");
}

@test:Config
function testSendEmailToCustomers() {
    log:printDebug("CustomerRegistration-Twilio Integration -> Registration EMAIL sending process successfully started!");
    string email = "srrajapakse1@gmail.com";
    boolean result = sendNotification(email);
    test:assertTrue(result, msg = "Email sending process failed!");
}
