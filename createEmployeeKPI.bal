remote function createEmployeeKPI(KPI newKPI) returns string|error {
    // Check if the employee exists
    map<json> employee = check db->find(userCollection, {id: newKPI.employeeId}, {});

    if (employee == ()) {
        return "Employee not found";
    }

    // Insert the new KPI into the database
    map<json> kpiDoc = <map<json>>newKPI.toJson();
    _ = check db->insert(kpiDoc, kpiCollection, "");

    return "KPI created successfully";
}
