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
    private final string database;

    public function init(string host, string user, string password, string database) returns sql:Error? {
        self.database = database;
        self.dbClient = check new (host, user, password);
    }

    isolated remote function listTables() returns string[]|sql:Error {
        string[] tables = [];
        stream<record {|string table_name;|}, sql:Error?> results = self.dbClient->query(
            `SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = ${self.database};`
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

    isolated remote function getTableInfo(string tableName, sql:ColumnRetrievalOptions include = sql:COLUMNS_ONLY) returns sql:TableDefinition|sql:Error { //return as sql:TableDefinition
        record {} 'table = check self.dbClient->queryRow(
            `SELECT TABLE_TYPE FROM information_schema.tables 
             WHERE (table_schema=${self.database} and table_name = ${tableName});`
        );

        TableDefinition data = {
            table_name: tableName,
            table_type: <TableType>'table["TABLE_TYPE"]
        };

        if !(include == sql:NO_COLUMNS) {
            ColumnDefinition[] columns = [];
            stream<ColumnDefinition, sql:Error?> colResults = self.dbClient->query(
                `SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT, IS_NULLABLE FROM information_schema.columns 
                 WHERE (table_schema=${self.database} and table_name = ${tableName});`
            );
            do {
                check from ColumnDefinition result in colResults
                    do {
                        columns.push(result);
                    };
            } on fail error e {
                return error("Error - recieved sql data is of type SQL:Error", cause = e);
            }
            check colResults.close();

            data.columns = columns;

            if include == sql:COLUMNS_WITH_CONSTRAINTS {                                                //NEED TO ADD ERROR CHECKING LIKE EXAMPLE
                CheckConstraint[] checkConst = [];
                map<CheckConstraint[]> checkConstMap = {};
                stream<CheckConstraint, sql:Error?> checkResults = self.dbClient->query(
                    `SELECT CONSTRAINT_NAME, CHECK_CLAUSE FROM information_schema.check_constraints 
                     WHERE constraint_schema = ${self.database};`
                );
                do {
                    check from CheckConstraint result in checkResults
                        do {
                            checkConst.push(result);
                        };
                } on fail error e {
                    return error("Error - recieved sql data is of type SQL:Error", cause = e);
                }
                check checkResults.close();

                ReferentialConstraint[] refConst = [];
                stream<ReferentialConstraint, sql:Error?> refResults = self.dbClient->query(
                    `SELECT * FROM information_schema.referential_constraints 
                        WHERE constraint_schema = ${self.database};`
                );
                do {
                    check from ReferentialConstraint result in refResults
                        do {
                            refConst.push(result);
                        };
                } on fail error e {
                    return error sql:Error("Error - recieved sql data is of type SQL:Error", cause = e);
                }
                check refResults.close();

                //map<ReferentialConstraint[]> refConstraintsMap = {};
            }
        }

        sql:TableDefinition sqlData = {name: data.table_name, 'type: <TableType>data.table_type};

        if data.columns is ColumnDefinition[] {
            sqlData.columns = <sql:ColumnDefinition[]>data.columns; 
        }
        
        return sqlData;
    }

    isolated remote function listRoutines() returns string[]|sql:Error {
        string[] routines = [];
        stream<record {|string routine_name;|}, sql:Error?> results = self.dbClient->query(
            `SELECT * FROM information_schema.routines 
            WHERE routine_schema = ${self.database};`
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

public function main() returns sql:Error?|error {

    MockSchemaClient client1 = check new (HOST, USER, PASSWORD, DATABASE);

    //string[] listTablesResult = check client1 -> listTables();

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

