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

    // Create user function
    remote function createUser(User newuser) returns error|string {
        // Insert user information into the database
        map<json> userDoc = <map<json>>newuser.toJson();
        _ = check db->insert(userDoc, userCollection, "");
        return string `${newuser.firstName} added successfully`;
    }

    // Mutation to create department objectives
    remote function createDepartmentObjective(Objective depobjective) returns error|string {
        map<json> objectiveDoc = <map<json>>depobjective.toJson();
        _ = check db->insert(objectiveDoc, objectiveCollection, "");
        return "Department objective created successfully";
    }

    
    // Mutation to delete department objectives
    remote function deleteDepartmentObjective(string id) returns error|string {
    mongodb:Error|int deleteItem = db->delete(objectiveCollection, "", {id: id}, false);
    if deleteItem is mongodb:Error {
        return error("Failed to delete Objective lol");
    } else {
        if deleteItem > 0 {
            return string `${id}  objective deleted successfully`;
        } else {
            return string `objective not found`;
        }
    }

    }

    //Function to view Employees Scores 

    resource function  get viewEmployeeTotalScore(string employeeId) returns float|error {

        stream<Score, error?> scoreDocs = check db->find(scoreCollection);

        float totalScore = 0.0;

        check from Score scoreDoc in scoreDocs 
        do {
            float scoreValue = <float>scoreDoc["value"];
            totalScore = totalScore + scoreValue;
        };
        return totalScore;
    }

   
    //Function to assignEmployeeToSupervisor
     remote function assignEmployeeToSupervisor(string employeeId, string supervisorId) returns string|error {
        // Check if the assignment already exists
        stream<Assignment, error?> assignments = check db->find(assignmentCollection, 'limit = 1);
        record { Assignment value; }? existingAssignment = check assignments.next();

        if (existingAssignment == ()) {
            // If the assignment does not exist, create a new assignment record
            Assignment assignment = {
                id: uuid:createType1AsString(),
                employeeId: employeeId,
                supervisorId: supervisorId
            };

            // Insert the assignment record into the database
            map<json> assignmentDoc = <map<json>>assignment.toJson();
            _ = check db->insert(assignmentDoc, assignmentCollection, "");

            return "Employee assigned to supervisor successfully";
        } else {
            // Assignment already exists, you can handle it as needed
            return "Employee is already assigned to a supervisor";
        }
    }

    //Function to approveEmployeeKPIs
    remote function approveEmployeeKPIs(string employeeId, string supervisorId) returns string|error {
        // Check if the provided employee and supervisor exist
        map<json> employee = check db->findOne(userCollection, {id: employeeId, role: "Employee"}, {});
        map<json> supervisor = check db->findOne(userCollection, {id: supervisorId, role: "Supervisor"}, {});

        if (employee == () || supervisor == ()) {
            return "Employee or Supervisor not found";
        }

        // Find unapproved KPIs for the specified employee
        stream<KPI, error?> kpiStream = check db->find(kpiCollection, 'filter=employeeId=="' + employeeId + '" and approved==false');

        var kpis = [KPI]{};

        // Iterate through the KPIs and mark them as approved
        while (true) {
            var kpiResult = kpiStream.next();
            if (kpiResult is KPI) {

                map<json> updatedKpiDoc = <map<json>>{
                    "approved": true
                };
                _ = check db->update(updatedKpiDoc, kpiCollection, "", {id: kpiResult.id}, true, false);

                kpis.add(kpiResult);
            } else {
                break;
            }
        }

        return "KPIs approved successfully";
    }

    
    //Function to deleteEmployeeKPIs
    remote function deleteEmployeeKPIs(string employeeId) returns string|error {

    stream<Assignment, error?> assignments = check db->find(assignmentCollection, "employeeId==" + employeeId);

    record { Assignment value; }? existingAssignment = check assignments.next();

    if (existingAssignment != ()) {

        int deletedCount = check db->delete(kpiCollection, "", {employeeId: employeeId}, false);

        if (deletedCount > 0) {
            return "Employee's KPIs deleted successfully";
        } else {
            return "No KPIs found for the specified employee";
        }
    } else {
        return "Employee is not assigned to a supervisor";
    }
}

    //Function to updateEmployeeKPI
    remote function updateEmployeeKPI(string kpiId, float newValue) returns string|error {
        // Check if the KPI exists and if the supervisor is allowed to update it
        stream<KPI, error?> kpiStream = check db->find(kpiCollection, "kpiId==" + kpiId);
        record { KPI value; }? kpiResult = check kpiStream.next();

        if (kpiResult == ()) {
            return "KPI not found";
        }

        KPI kpi = kpiResult.value;
        string employeeId = kpi.employeeId;
        
        stream<Assignment, error?> assignmentStream = check db->find(assignmentCollection, "supervisorId ==" + supervisorId + " and employeeId=="' + employeeId + '"');
        record { Assignment value; }? assignmentResult = check assignmentStream.next();

        if (assignmentResult == ()) {
            return "Supervisor is not allowed to update this KPI";
        }

        kpi.value = newValue;
        
        // Update the KPI in the database
        map<json> kpiDoc = <map<json>>kpi.toJson();
        int updatedCount = check db->update(kpiDoc, kpiCollection, 'filter=id=="' + kpiId + '"', false, false);

        if (updatedCount > 0) {
            return "KPI updated successfully";
        } else {
            return "Failed to update KPI";
        }
    }

    //Function to viewEmployeeScores
    remote function viewEmployeeScores(string supervisorId) returns typedesc<Score>[]|error {
    // Find all assignments where the supervisor matches the provided supervisorId
    stream<Assignment, error?> assignmentStream = check db->find(assignmentCollection, "supervisorId==" + supervisorId);

    var scores = [Score];{}

    // Iterate through assignments and fetch scores for assigned employees
        while (true) {
        var assignmentResult = assignmentStream.next();

        if (assignmentResult is Assignment) {
            Assignment assignment = assignmentResult;
            // Find scores for the assigned employee
            stream<Score, error?> scoreStream = check db->find(scoreCollection, "employeeId==" + assignment.employeeId);

            while (true) {
                var scoreResult = scoreStream.next();
                if (scoreResult is Score) {
                    scores.push(scoreResult);
                } else {
                    break;
                }
            }
        } else {
            break;
        }
    }

    return scores;
}

    //Function to gradeEmployeeKPIs
    remote function gradeEmployeeKPIs(string employeeId, string kpiId, float grade) returns string|error {

    map<json> employee = check db->find(userCollection, {id: employeeId}, {});
    map<json> kpi = check db->find(kpiCollection, {id: kpiId}, {});

    if (employee == () || kpi == ()) {
        return "Employee or KPI not found";
    }

    //ensure it's within a valid range)
    if (grade < 1.0 || grade > 5.0) {
        return "Invalid grade. Please use a scale from 1 to 5";
    }

    // Update the score for the employee's KPI
    map<json> scoreUpdate = <map<json>>{"$set": {"value": grade}};
    int updatedCount = check db->update(scoreUpdate, scoreCollection, "", {employeeId: employeeId, kpiId: kpiId}, false, false);

    if (updatedCount > 0) {
        return "KPI graded successfully";
    } else {
        return "Failed to grade KPI";
    }
}

    //Function to createEmployeeKPI
    remote function createEmployeeKPI(KPI newKPI) returns string|error {

    map<json> employee = check db->find(userCollection, {id: newKPI.employeeId}, {});

    if (employee == ()) {
        return "Employee not found";
    }

    // Insert the new KPI into the database
    map<json> kpiDoc = <map<json>>newKPI.toJson();
    _ = check db->insert(kpiDoc, kpiCollection, "");

    return "KPI created successfully";
}

    //Function to gradeSupervisor
    remote function gradeSupervisor(string employeeId, string supervisorId, float grade) returns string|error {
   
    map<json> employee = check db->find(userCollection, {id: employeeId}, {});
    map<json> supervisor = check db->find(userCollection, {id: supervisorId}, {});

    if (employee == () || supervisor == ()) {
        return "Employee or Supervisor not found";
    }

    if (grade < 1.0 || grade > 5.0) {
        return "Invalid grade. Please use a scale from 1 to 5";
    }

    // Create a record to store the grade and supervisor information
    map<json> gradeRecord = <map<json>>{
        "employeeId": employeeId,
        "supervisorId": supervisorId,
        "grade": grade
    };

    // Insert the grade record into the database
    _ = check db->insert(gradeRecord, "SupervisorGrades", "");

    return "Supervisor graded successfully";
}

//Function to viewEmployeeOwnScores
remote function viewEmployeeOwnScores(string employeeId) returns [Score]|error {
 
    map<json> employee = check db->find(userCollection, {id: employeeId}, {});

    if (employee == ()) {
        return "Employee not found";
    }

    // Find scores for the specified employee
    stream<Score, error?> scoreStream = check db->find(scoreCollection, 'filter=employeeId=="' + employeeId + '"');

    var scores = [Score]{}; // Initialize an array to collect scores

    // Iterate through the scores and add them to the array
    while (true) {
        var scoreResult = scoreStream.next();
        if (scoreResult is Score) {
            scores.add(scoreResult);
        } else {
            break;
        }
    }

    return scores;
}

}
