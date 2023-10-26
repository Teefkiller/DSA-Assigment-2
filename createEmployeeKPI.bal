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
remote function approveEmployeeKPIs(string employeeId, string supervisorId) returns string|error {
        // Check if the provided employee and supervisor exist
        map<json> employee = check db->findOne(userCollection, {id: employeeId, role: "Employee"}, {});
        map<json> supervisor = check db->findOne(userCollection, {id: supervisorId, role: "Supervisor"}, {});

        if (employee == () || supervisor == ()) {
            return "Employee or Supervisor not found";
        }

        // Find unapproved KPIs for the specified employee
        stream<KPI, error?> kpiStream = check db->find(kpiCollection, 'filter=employeeId=="' + employeeId + '" and approved==false');

        var kpis = [KPI]{}; // Initialize an array to collect unapproved KPIs

        // Iterate through the KPIs and mark them as approved
        while (true) {
            var kpiResult = kpiStream.next();
            if (kpiResult is KPI) {
                // Mark the KPI as approved by updating the database
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
