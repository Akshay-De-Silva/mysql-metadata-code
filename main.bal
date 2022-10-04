import ballerina/io;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;

//final mysql:Client dbClient = check new (host = HOST, user = USER, password = PASSWORD, port = PORT, database = "Company");  <- remove after new client approved

isolated client class MockSchemaClient {
    //*SchemaClient;                        <-uncomment when adding to main code repo

    private final mysql:Client dbClient;
    private final string DATABASE;

    public function init(string HOST, string USER, string PASSWORD, string DATABASE) returns sql:Error? {
        self.DATABASE = DATABASE;
        self.dbClient = check new (HOST, USER, PASSWORD);
    }

    isolated remote function listTables() returns string[]|sql:Error {
        string[] tables = [];
        stream<record {|string table_name;|}, sql:Error?> results = self.dbClient->query(
            `SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = ${DATABASE};`
        );

        do {
            check from record {|string table_name;|} result in results
                do {
                    tables.push(result.table_name.toString());
                };
        } on fail error e {
            return error("Parsing Failed", cause = e);
        }

        do {
            check results.close();
        } on fail error e {
            return error("Closing Failed", cause = e);
        }

        io:println("Tables Names:"); //remove later
        return tables;
    }

    isolated remote function getTableInfo(string tableName, sql:ColumnRetrievalOptions include = sql:COLUMNS_ONLY) returns TableDefinition|sql:Error { //return as sql:TableDefinition
        record {}|sql:Error 'table = self.dbClient->queryRow(
            `SELECT table_type FROM information_schema.tables 
             WHERE (table_schema=${DATABASE} and table_name = ${tableName});`
        );

        TableDefinition data = {
            table_name: tableName,
            table_type: <TableType>'table["TABLE_TYPE"]
        };

        if !(include == sql:NO_COLUMNS) {
            ColumnDefinition[] columns = [];
            stream<ColumnDefinition, sql:Error?> colResults = self.dbClient->query(
                `SELECT * FROM information_schema.columns 
                 WHERE (table_schema=${DATABASE} and table_name = ${tableName});`
            );
            do {
                check from ColumnDefinition result in colResults
                    do {
                        columns.push(result);
                    };
            } on fail error e {
                return error("Parsing Failed", cause = e);
            }
            check colResults.close();

            data.columns = columns;

            if include == sql:COLUMNS_WITH_CONSTRAINTS {
                CheckConstraint[] checkConst = [];
                stream<CheckConstraint, sql:Error?> checkResults = self.dbClient->query(
                    `SELECT * FROM information_schema.check_constraints 
                     WHERE constraint_schema = ${DATABASE};`
                );
                do {
                    check from CheckConstraint result in checkResults
                        do {
                            checkConst.push(result);
                        };
                } on fail error e {
                    return error("Parsing Failed", cause = e);
                }
                check checkResults.close();

                ReferentialConstraint[] refConst = [];
                stream<ReferentialConstraint, sql:Error?> refResults = self.dbClient->query(
                    `SELECT * FROM information_schema.referential_constraints 
                        WHERE constraint_schema = ${DATABASE};`
                );
                do {
                    check from ReferentialConstraint result in refResults
                        do {
                            refConst.push(result);
                        };
                } on fail error e {
                    return error("Parsing Failed", cause = e);
                }
                check refResults.close();

                _ = checkpanic from ColumnDefinition column in <ColumnDefinition[]>data.columns

                    do {
                        ReferentialConstraint[]? refConstraints = refConst[column.column_name];
                        if !(refConstraints is ()) && refConstraints.length() != 0 {
                            column.referentialConstraints = refConstraints;
                        }

                        CheckConstraint[]? checkConstraints = checkConst[column.column_name];
                        if !(checkConstraints is ()) && checkConstraints.length() != 0 {
                            column.checkConstraints = checkConstraints;
                        }
                    };
            }
        }

        sql:TableDefinition sqlData = data;
        return data;
    }

    isolated remote function listRoutines() returns string[]|sql:Error {
        string[] routines = [];
        stream<record {|string routine_name;|}, sql:Error?> results = self.dbClient->query(
            `SELECT * FROM information_schema.routines 
            WHERE routine_schema = ${DATABASE};`
        );
        do {
            check from record {|string routine_name;|} result in results
                do {
                    routines.push(result.routine_name.toString());
                };
        } on fail error e {
            return error("Parsing Failed", cause = e);
        }
        check results.close();

        io:println("Routine Names:");
        return routines;
    }

    isolated remote function getRoutineInfo(string name) returns RoutineDefinition|sql:Error {
        string[] parameters = [];

        RoutineDefinition|sql:Error routine = self.dbClient->queryRow(
            `SELECT * FROM information_schema.routines where routine_name = ${name};`
        );

        stream<ParameterDefinition, sql:Error?> paramResults = self.dbClient->query(
            `SELECT * FROM information_schema.parameters 
            WHERE (specific_name=${name});`
        );
        do {
            check from ParameterDefinition 'parameter in paramResults
                do {
                    parameters.push('parameter.toString());
                };
        } on fail error e {
            return error("Parsing Failed", cause = e);
        }
        check paramResults.close();

        io:println("Parameter Metadata:\n");
        foreach string 'parameter in parameters {
            io:println('parameter);
            io:println("\n");
        }
        io:println("\n\n");

        return routine;
    }
}

public function main() {

    // MockSchemaClient ("HOST", "USER", "PASSWORD", "DATABASE");

    //string[]|error tableNames = listTables();
    //io:println(tableNames);

    // TableDefinition|error t = getTableInfo("Employees", include = COLUMNS_WITH_CONSTRAINTS);
    // io:println("Table Definition:\n");
    // io:println(t);

    //string[]|error routineNames = listRoutines();
    //io:println(routineNames);

    // RoutineDefinition|error r = getRoutineInfo("GetEmployeeByFirstName");
    // io:println("Routine Definition:\n");
    // io:println(r);
}

