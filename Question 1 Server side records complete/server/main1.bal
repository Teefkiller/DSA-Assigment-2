import ballerina/graphql;
import ballerinax/mongodb;
import ballerina/uuid;

type User record {
    string id;
    string firstName;
    string lastName;
    string role; // Add a 'role' field (HoD, Employee, Supervisor)
};

type Objective record {
    string id;
    string department;
    string description;
    float weight;
};

type KPI record {
    string id;
    string employeeId;
    string description;
    string unit;
    float weight;
};

type Score record {
    string id;
    string employeeId;
    string kpiId;
    float value;
};

type Assignment record {
    string id;
    string employeeId;
    string supervisorId;
};


mongodb:ConnectionConfig mongoConfig = {
    connection: {
        host: "localhost",
        port: 27017,
        auth: {
            username: "",
            password: ""
        },
        options: {
            sslEnabled: false,
            serverSelectionTimeout: 5000
        }
    },
    databaseName: "performance-management"
};

mongodb:Client db = check new (mongoConfig);
configurable string userCollection = "Users";
configurable string objectiveCollection = "Objectives";
configurable string kpiCollection = "KPIs";
configurable string scoreCollection = "Scores";
configurable string assignmentCollection = "Assignment";

service /performanceManagement on new graphql:Listener(8080) {