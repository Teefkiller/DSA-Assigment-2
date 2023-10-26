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
