import ballerina/graphql;
import ballerina/io;

type userResponse record {|
    record {|anydata dt;|} data;
|};

public function main() returns error? {
    graphql:Client graphqlClient = check new ("localhost:8080/performanceManagement");

    string doc = string `
    mutation addProduct($id:String!,$name:String!,$price:Float!,$quantity:Int!){
        addProduct(newproduct:{id:$id,name:$name,price:$price,quantity:$quantity})
    }`;

    userResponse createUserResponse = check graphqlClient->execute(doc, {"id": "1", "name": "Joe", "lastName":"Momma", "role": "HoD"});

    io:println("Response ", createUserResponse);
}