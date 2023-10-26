import ballerina/graphql;
import ballerina/io;

type userResponse record {|
    record {|anydata dt;|} data;
|};

type objectiveResponse record {|
    record {|anydata dt;|} data;
|};

type scoreResponse record {|
    record {|anydata dt;|} data;
|};


type kpiResponse record {|
    record {|anydata dt;|} data;
|};

public function main() returns error? {
    graphql:Client graphqlClient = check new ("localhost:8080/performanceManagement");

    // Client for the createUser function
    string createUsers = string `
    mutation createUser($id:String!,$firstName:String!,$lastName:String!,$role:String!){
        createUser(newuser:{id:$id,firstName:$firstName,lastName:$lastName,role:$role})
    }`;

    userResponse createUserResponse = check graphqlClient->execute(createUsers, {"id": "1", "name": "Joe", "lastName":"Momma", "role": "HoD"});

    io:println("Response ", createUserResponse);


    // Client for the createDepartmentObjective function
    string createObjectives = string `{
    mutation createDepartmentObjective($id: String!, $department: String!, $description: String!, $weight: Float!) {
        createDepartmentObjective(depobjective:{id: $id, department: $department, description: $description, weight: $weight})
    }`;
        
    objectiveResponse createObjectiveResponse = check graphqlClient->execute(createObjectives, {"id": "001", "department": "Department of Computer Science", "description": "This objective is fun", "weight": 3.0});
    
    io:println("Response ", createObjectiveResponse);

    // Client for the deleteDepartmentObjective function
    string deleteObjectives = string `{
       mutation deleteDepartmentObjective($department: String!) {
        deleteDepartmentObjective(deleteObjective:{department: $department})
    }`;
    objectiveResponse deleteObjectiveResponse = check graphqlClient->execute(deleteObjectives, {"department": "Faculty of Computer Science"});

    io:println("Response ", deleteObjectiveResponse);

     // Client for the viewEmployeeTotalScores function
    string viewEmployeeTotalScore = string `{
        query viewEmployeeTotalScores($id: String!, $description: String!, $weight: Float!) {
            viewEmployeeTotalScores(EmployeeScore:{id: $id})
    }`;
    scoreResponse viewEmployeeTotalScoresResponse = check graphqlClient->execute(viewEmployeeTotalScore, {"id": "emp123"});
    
    io:println("Response ", viewEmployeeTotalScore);

    // Client for assignEmployeeToSupervisor function
    string assignEmployeeSupervisor = string `{
        mutation assignEmployeeToSupervisor($employeeID: String!, $supervisorID: String!) {
            assignEmployeeToSupervisor(employeeID: $employeeID, supervisorID: $supervisorID)
        }
    }`;

    userResponse assignEmployeeResponse = check graphqlClient->execute(assignEmployeeSupervisor, {"employeeID": "emp123", "supervisorID": "sup123"});
    
    io:println("Response: ", assignEmployeeResponse);
    
    // Client for the approveEmployeeKPI function
    string approveKpi = string `{
        mutation approveEmployeeKPI($kpiID: String!) {
            approveEmployeeKPI(kpiID: $kpiID)
        }
    }`;
    kpiResponse approveKpiResponse = check graphqlClient->execute(approveKpi, {"kpiID": "kpi123"});
    
    io:println("Response: ", approveKpiResponse);

    // Client for deleteEmployeeKPI function
    string deleteKpi = string `{
        mutation deleteEmployeeKPI($kpiID: String!, $employeeID: String!) {
            deleteEmployeeKPI(kpiID: $kpiID, employeeID: $employeeID)
        }
    }`;
    kpiResponse deleteKpiResponse = check graphqlClient->execute(deleteKpi, {"kpiID": "kpi123", "employeeID": "emp123"});
    
    io:println("Response: ", deleteKpiResponse);

    
    // Client for the updateEmployeeKPI function
    string updateKpi = string `{
        mutation updateEmployeeKPI($kpiID: String!, $name: String!, $score: Int!, $approved: Boolean!, $employeeID: String!) {
            updateEmployeeKPI(kpiID: $kpiID, name: $name, score: $score, approved: $approved, employeeID: $employeeID)
        }
    }`;
    kpiResponse updateKpiResponse = check graphqlClient->execute(updateKpi, {"kpiID": "kpi123", "name": "KPI Name", "score": 90, "approved": true, "employeeID": "emp123"});
    
    io:println("Response: ", updateKpiResponse);

    
    // Client for viewEmployeeScores function
    string viewEmployeeScores = string `{
        query viewEmployeeScores($employeeID: String!) {
            viewEmployeeScores(employeeID: $employeeID)
        }
    }`;
    scoreResponse viewScoresResponse = check graphqlClient->execute(viewEmployeeScores, {"employeeID": "emp123"});
    
    io:println("Response: ", viewScoresResponse);

        // Client for createEmployeeKPI function
    string createKpi = string `{
        mutation createEmployeeKPI($employeeID: String!, $kpi: KPIInput!) {
            createEmployeeKPI(employeeID: $employeeID, kpi: $kpi)
        }
    }`;
    kpiResponse createKpiResponse = check graphqlClient->execute(createKpi, {"employeeID": "emp123", "kpi": {"kpiID": "kpi124", "name": "New KPI", "score": 85, "approved": false}});
    
    io:println("Response: ", createKpiResponse);

    
    // Client for gradeSupervisor function
    string gradeSupervisor = string `{
        mutation gradeSupervisor($employeeID: String!, $supervisorID: String!, $grade: Float!) {
            gradeSupervisor(employeeID: $employeeID, supervisorID: $supervisorID, grade: $grade)
        }
    }`;
    userResponse gradeSupervisorResponse = check graphqlClient->execute(gradeSupervisor, {"employeeID": "emp123", "supervisorID": "sup123", "grade": 4.5});
    
    io:println("Response: ", gradeSupervisorResponse);


}




    




