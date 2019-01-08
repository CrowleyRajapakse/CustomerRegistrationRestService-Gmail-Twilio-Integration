import ballerina/http;
import ballerina/log;
import ballerina/mysql;
import ballerina/io;

// Type Customer is created to store details of a student.
type Customer record {
    int id;
    int age;
    string name;
    int mobNo;
    string email;
};


// Endpoint for MySQL client.
mysql:Client customerDB = new({
        host: "localhost",
        port: 3306,
        name: "testdb",
        username: "root",
        password: "1qaz2wsx@Q",
        dbOptions: { useSSL: false}
    });

// Listener of the customer service port.
listener http:Listener customerServiceListener = new(9292);

// Service configuration of the customer data service..
@http:ServiceConfig {
    basePath: "/records"
}
service customerData on customerServiceListener {
    int errors = 0;
    int requestCounts = 0;

    // Resource configuration for adding customers to the system.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/addCustomer"
    }
    // Add Customers resource used to add customer records to the system.
    resource function addCustomers(http:Caller caller, http:Request request) {
        // Initialize an empty HTTP response message.
        customerData.requestCounts += 1;
        http:Response response = new;

        // Accepting the JSON payload sent from a request.
        json|error payloadJson = request.getJsonPayload();

        if (payloadJson is json) {
            //Converting the payload to Customer type.
            Customer|error customerDetails = Customer.convert(payloadJson);

            if (customerDetails is Customer) {
                io:println(customerDetails);
                // Calling the function insertData to update database.
                json returnValue = insertData(untaint customerDetails.name, untaint customerDetails.age, untaint
                    customerDetails.mobNo, untaint customerDetails.email);
                response.setJsonPayload(untaint returnValue);
            } else {
                log:printError("Error in converting JSON payload to customer type", err = customerDetails);
            }
        } else {
            log:printError("Error obtaining the JSON payload", err = payloadJson);
        }

        // Send the response back to the client with the returned JSON value from insertData function.
        var result = caller->respond(response);
        if (result is error) {
            // Log the error for the service maintainers.
            log:printError("Error in sending response to the client", err = result);
        }
    }

    // Resource configuration for viewing details of all the customers in the system.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/viewAll"
    }
    // View customers resource is to get all the customers details and send to the requested user.
    resource function viewCustomers(http:Caller caller, http:Request request) {
        customerData.requestCounts += 1;

        http:Response response = new;
        json status = {};


        // Sending a request to MySQL endpoint and getting a response with required data table.
        var returnValue = customerDB->select("SELECT * FROM customer", Customer, loadToMemory = true);


        // A table is declared with Customer as its type.
        table<Customer> dataTable = table{};

        if (returnValue is error) {
            log:printError("Error in fetching customers data from the database", err = returnValue);
        } else {
            dataTable = returnValue;
        }

        // Customer details displayed on server side for reference purpose.
        foreach var row in dataTable {
            io:println("Customer:" + row.id + "|" + row.name + "|" + row.age);
        }

        // Table is converted to JSON.
        var jsonConversionValue = json.convert(dataTable);
        if (jsonConversionValue is error) {
            log:printError("Error in converting the data from a tabular format to JSON.", err = jsonConversionValue);
        } else {
            status = jsonConversionValue;
        }
        // Sending back the converted JSON data to the request made to this service.
        response.setJsonPayload(untaint status);
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error in sending the response", err = result);
        }

    }
}
// Function to insert values to the database..
# `insertData()` is a function to add data to customer records database.
#
# + name - This is the name of the customer to be added.
# + age -Customer age.
# + mobNo -Customer mobile number.
# + email - Customer email address.
# + return - This function returns a JSON object. If data is added it returns JSON containing a status and id of customer
#            added. If data is not added , it returns the JSON containing a status and error message.

public function insertData(string name, int age, int mobNo, string email) returns (json) {
    json updateStatus = { "Status": "Data Inserted " };
    int uniqueId = 0;
    string sqlString = "INSERT INTO customer (name, age, mobNo, email) VALUES (?,?,?,?)";

    // Insert data to SQL database by invoking update action.
    var returnValue = customerDB->update(sqlString, name, age, mobNo, email);
    if (returnValue is int) {
        table<Customer> result = getId(untaint mobNo);
        while (result.hasNext()) {
            var returnValue2 = result.getNext();
            if (returnValue2 is Customer) {
                uniqueId = returnValue2.id;
            } else {
                log:printError("Error in obtaining a customer ID from the database for the added customer.");
            }
        }

        if (uniqueId != 0) {
            updateStatus = { "Status": "Data Inserted Successfully", "id": uniqueId };
        } else {
            updateStatus = { "Status": "Data Not inserted" };
        }
    } else {
        log:printError("Error in adding the data to the database", err = returnValue);
    }
    return updateStatus;
}

# `getId()` is a function to get the Id of the customer added in latest.
#
# + mobNo - This is the mobile number of the customer added which is passed as parameter to build up the query.
# + return -This function returns a table with Customer type.

// Function to get the generated Id of the student recently added.
public function getId(int mobNo) returns table<Customer> {
    //Select data from database by invoking select action.

    string sqlString = "SELECT * FROM customer WHERE mobNo = ?";
    // Retrieve customer data by invoking select remote function defined in ballerina sql client
    var returnValue = customerDB->select(sqlString, Customer, mobNo);

    table<Customer> dataTable = table{};
    if (returnValue is error) {
        log:printError("Error in obtaining the customer ID from the database.
        ", err = returnValue);
    } else {
        dataTable = returnValue;
    }
    return dataTable;
}


