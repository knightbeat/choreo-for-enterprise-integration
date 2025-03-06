import ballerina/http;

// Define a record for customer data
type Customer readonly & record {|
    string id;
    string first_name;
    string last_name;
    string email;
    string phone;
    record {|
        string street;
        string city;
        string postcode;
        string country;
    |} address;
    string created_at;
    decimal last_order_value;
|};

// Define the in-memory table with customer records
table<Customer> key(id) customers = table [
    { id: "001", first_name: "Alice", last_name: "Johnson", email: "alice.johnson@example.com",
      phone: "+44 7911 123456",
      address: { street: "10 Downing Street", city: "London", postcode: "SW1A 2AA", country: "UK" },
      created_at: "2024-02-20T12:30:00Z", last_order_value: 250.75 },
    
    { id: "002", first_name: "Bob", last_name: "Smith", email: "bob.smith@example.com",
      phone: "+44 7922 987654",
      address: { street: "221B Baker Street", city: "London", postcode: "NW1 6XE", country: "UK" },
      created_at: "2023-11-10T09:45:00Z", last_order_value: 180.50 },

    { id: "003", first_name: "Charlie", last_name: "Brown", email: "charlie.brown@example.com",
      phone: "+44 7933 555444",
      address: { street: "50 Example St", city: "Manchester", postcode: "M1 1AA", country: "UK" },
      created_at: "2024-03-01T10:00:00Z", last_order_value: 99.99 },

    { id: "004", first_name: "David", last_name: "Williams", email: "david.williams@example.com",
      phone: "+44 7944 666777",
      address: { street: "25 Queen’s Road", city: "Birmingham", postcode: "B1 2AB", country: "UK" },
      created_at: "2024-01-15T14:20:00Z", last_order_value: 300.00 }
];

// HTTP Service
service /cdp on new http:Listener(8080) {

    // Get all customers
    resource function get customers() returns Customer[] {
        return customers.toArray();
    }

    // Get a specific customer by ID
    resource function get customers/[string id]() returns Customer?|http:NoContentError {
        if customers.hasKey(id) {
            return customers[id];
        }
        return error http:NoContentError("Customer not found!");
    }

}
