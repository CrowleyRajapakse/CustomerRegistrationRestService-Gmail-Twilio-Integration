# CustomerRegistrationRestService-Gmail-Twilio-Integration

This is a project created using Ballerina language which is a compiled, type safe, concurrent programming language designed to
make it simple to write microservices that integrate APIs.

Project includes a Customer Registration Service integrated with a MySQL database to store customer records.

Gmail and Twilio is also integrated with the customer registration process to send email and sms to the customer.

## Getting Started

### Download Ballerina

You can download the Ballerina distribution at http://ballerina.io.

### Setup MySQL

Use the database script given in the resource folder to setup the database

### Setup GMAIL API credentials

### Go through the following steps to obtain credetials and tokens for GMail API.
1. Visit Google API Console, click Create Project, and follow the wizard to create a new project.
2. Enable both GMail and Google Sheets APIs for the project.
3. Go to Credentials -> OAuth consent screen, enter a product name to be shown to users, and click Save.
4. On the Credentials tab, click Create credentials and select OAuth client ID.
5. Select an application type, enter a name for the application, and specify a redirect URI (enter https://developers.google.com/oauthplayground if you want to use OAuth 2.0 playground to receive the authorization code and obtain the access token and refresh token).
6. Click Create. Your client ID and client secret appear.
7. In a separate browser window or tab, visit OAuth 2.0 playground, select the required GMail and Google Sheets API scopes, and then click Authorize APIs.
8. When you receive your authorization code, click Exchange authorization code for tokens to obtain the refresh token and access token.

### You must configure the ballerina.conf configuration file with the above obtained tokens, credentials and other important parameters as follows.  ACCESS_TOKEN="access token"
  ```
  CLIENT_ID="client id"
  CLIENT_SECRET="client secret"
  REFRESH_TOKEN="refresh token"
  SPREADSHEET_ID="spreadsheet id you have extracted from the sheet url"
  SHEET_NAME="sheet name of your Goolgle Sheet. For example in above example, SHEET_NAME="Stats"
  SENDER="email address of the sender"
  USER_ID="mail address of the authorized user. You can give this value as, me"
```

### Setup Twilio API credentials
Create a Twilio account and obtain the following parameters:

Account SId

Auth Token

Set Twilio credentials in ballerina.conf

```
TWILIO_ACCOUNT_SID="your_Twilio_account_id"

TWILIO_AUTH_TOKEN="your_Twilio_Auth"

TWILIO_FROM_MOBILE="your_Twilio_phone_number"

TWILIO_MESSAGE="your_message"
```

## Running

1. First run the customer_management_service module by entering the following command in a terminal.

```
$ ballerina run customers
```

2. You can see service starting up.

Initiating service(s) in 'customers'

[ballerina/http] started HTTP/WS endpoint 0.0.0.0:9292

3. Then, using another terminal run the client module.

```
$ ballerina run client_service
```

## Let's now look at sample log statements we get when running the sample for this scenario.

```
Select operation.
1. Add customer
2. View all customers
3. Exit

Enter choice 1 - 3: 2

Customer Name: Peter,  Customer Age: 20

Customer Name: Kate,  Customer Age: 13

Customer Name: Krish,  Customer Age: 22

Customer Name: Shairam,  Customer Age: 21

Customer Name: Sampath,  Customer Age: 25


Select operation.
1. Add customer
2. View all customers
3. Exit

Enter choice 1 - 3: 1

Enter Customer name: Saman

Enter Customer age: 43

Enter mobile number: 0717313761

Enter Customer Email address: saman@gmail.com

2019-01-09 14:37:49,706 INFO  [Home/client_service] - Status: Data Inserted Successfully Added Customer Id :- 49

2019-01-09 14:37:51,345 INFO  [Home/client_service] - Sent SMS to the customer

2019-01-09 14:37:52,162 INFO  [Home/client_service] - Sent email to saman@gmail.com with message Id: 16831de30897b4dc and thread Id:16831de30897b4dc


Select operation.
1. Add customer
2. View all customers
3. Exit

Enter choice 1 - 3: 3
```

## Testing 

### Invoking the customer management service Tests

You can start test by opening a terminal and executing the following command.

```
$ ballerina test customers/
```

### Invoking the client service Tests

First start the customers module by `ballerina run customers/` command.

Then you can start test by opening a terminal and executing the following command.
 
```
$ ballerina test client_service/
```


