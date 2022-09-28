//import ballerina/http;

// listener http:Listener httpListener = new (8080);

// service / on httpListener {
//     resource function get sayHi() returns string { 
//         return "Hello, World!"; 
//     }

//     resource function get sayHi/[string name]() returns string { 
//         return "Hello " + name; 
//     }
// }

import ballerina/io;
//import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database="Company");

public type Entity record {
    string TABLE_NAME?;
    string ROUTINE_NAME?;
};

isolated function listTables() returns string[]|error {
    string[] tables = [];
    stream<Entity, error?> results = dbClient->query(
        `SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
         WHERE TABLE_SCHEMA = ${DATABASE};`
    );
    check from Entity result in results
        do {
            tables.push(result.TABLE_NAME.toString());
        };
    check results.close();

    io:println("Tables Names:");
    return tables;
}

isolated function getTableInfo(string tableName, ColumnRetrievalOptions include = COLUMNS_ONLY) returns TableDefinition|error{
    string option = include;

    TableDefinition|error 'table = dbClient->queryRow(
        `SELECT * FROM information_schema.tables WHERE table_name = ${tableName};`
    );
    
    if(option=="COLUMNS_ONLY"|| option=="COLUMNS_WITH_CONSTRAINTS") {
        string[] columns = [];
        stream<ColumnDefinition, error?> colResults = dbClient->query(
            `SELECT * FROM information_schema.columns 
                WHERE (table_schema=${DATABASE} and table_name = ${tableName});`
        );
            check from ColumnDefinition result in colResults
            do {
                columns.push(result.toString());
            };
        check colResults.close();
        io:println("Column Metadata:\n");
        foreach string column in columns {
            io:println(column);
            io:println("\n");
        }
        io:println("\n\n");

        if(option=="COLUMNS_WITH_CONSTRAINTS"){
            string[] checkConstraints = [];
            stream<CheckConstraint, error?> checkResults = dbClient->query(
                `SELECT * FROM information_schema.check_constraints 
                    WHERE constraint_schema = ${DATABASE};`
            );
                check from CheckConstraint result in checkResults
                do {
                    checkConstraints.push(result.toString());
                };
            check checkResults.close();
            io:println("Check Constraints Metadata:\n");
            foreach string 'check in checkConstraints {
                io:println('check);
                io:println("\n");
            }
            io:println("\n\n");

            string[] refConstraints = [];
            stream<ReferentialConstraint, error?> refResults = dbClient->query(
                `SELECT * FROM information_schema.referential_constraints 
                    WHERE constraint_schema = ${DATABASE};`
            );
                check from ReferentialConstraint result in refResults
                do {
                    refConstraints.push(result.toString());
                };
            check refResults.close();
            io:println("Referential Constraints Metadata:\n");
            foreach string ref in refConstraints {
                io:println(ref);
                io:println("\n");
            }
            io:println("\n\n");
        }
    }

    return 'table;
}

public enum ColumnRetrievalOptions {
    NO_COLUMNS,
    COLUMNS_ONLY,
    COLUMNS_WITH_CONSTRAINTS
}

isolated function listRoutines() returns string[]|error {
    string[] routines = [];
    stream<Entity, error?> results = dbClient->query(
        `SELECT * FROM information_schema.routines 
         WHERE routine_schema = ${DATABASE};`
    );
    check from Entity result in results
        do {
            routines.push(result.ROUTINE_NAME.toString());
        };
    check results.close();

    io:println("Routine Names:");
    return routines;
}

public function main() {
    string[]|error tableNames = listTables();
    io:println(tableNames);

    // TableDefinition|error t = getTableInfo("Employees", include = COLUMNS_WITH_CONSTRAINTS);
    // io:println("Table Definition:\n");
    // io:println(t);

    string[]|error routineNames = listRoutines();
    io:println(routineNames);
}

