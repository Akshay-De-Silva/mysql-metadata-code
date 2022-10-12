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

        return tables;
    }

    isolated remote function getTableInfo(string tableName, sql:ColumnRetrievalOptions include = sql:COLUMNS_ONLY) returns sql:TableDefinition|sql:Error { //return as sql:TableDefinition
        record {} 'table = check self.dbClient->queryRow(
            `SELECT TABLE_TYPE FROM information_schema.tables 
             WHERE (table_schema=${self.database} and table_name = ${tableName});`
        );

        sql:TableDefinition tableDef = {
            name: tableName,
            'type: <TableType>'table["TABLE_TYPE"]
        };

        if !(include == sql:NO_COLUMNS) {
            sql:ColumnDefinition[] columns = [];
            stream<sql:ColumnDefinition, sql:Error?> colResults = self.dbClient->query(
                `SELECT COLUMN_NAME AS name, DATA_TYPE AS type, COLUMN_DEFAULT AS defaultValue, IS_NULLABLE AS nullable FROM information_schema.columns 
                 WHERE (table_schema=${self.database} and table_name = ${tableName});`
            );
            do {
                check from sql:ColumnDefinition result in colResults
                    do {
                        columns.push(result);
                    };
            } on fail error e {
                return error("Error - recieved sql data is of type SQL:Error", cause = e);
            }
            check colResults.close();

            //io:println(columns);

            tableDef.columns = columns;

            if include == sql:COLUMNS_WITH_CONSTRAINTS {                                                //NEED TO ADD ERROR CHECKING LIKE EXAMPLE
                sql:CheckConstraint[] checkConst = [];
                map<sql:CheckConstraint[]> checkConstMap = {};
                stream<sql:CheckConstraint, sql:Error?> checkResults = self.dbClient->query(
                    `SELECT CONSTRAINT_NAME AS name, CHECK_CLAUSE AS clause FROM information_schema.check_constraints 
                     WHERE (CONSTRAINT_SCHEMA=${self.database} and TABLE_NAME = ${tableName});`                                     //CHECK IF WORK
                );
                do {
                    check from sql:CheckConstraint result in checkResults
                        do {
                            checkConst.push(result);
                        };
                } on fail error e {
                    return error("Error - recieved sql data is of type SQL:Error", cause = e);
                }
                check checkResults.close();

                sql:ReferentialConstraint[] refConst = [];
                stream<sql:ReferentialConstraint, sql:Error?> refResults = self.dbClient->query(
                    `SELECT CONSTRAINT_NAME AS name, TABLE_NAME AS tableName, COLUMN_NAME AS columnName, UPDATE_RULE AS updateRule, DELETE_RULE AS deleteRule 
                     FROM information_schema.referential_constraints 
                     WHERE (CONSTRAINT_SCHEMA=${self.database} and TABLE_NAME = ${tableName});`                                                                  //may not work (no native column_name)
                );
                do {
                    check from sql:ReferentialConstraint result in refResults
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

        //sql:TableDefinition sqlData = {name: data.table_name, 'type: <TableType>data.table_type};

        // if data.columns is ColumnDefinition[] {
        //     sqlData.columns = <sql:ColumnDefinition[]>data.columns; 
        // }

        //sqlData.columns = data.columns is ColumnDefinition[] ? <sql:ColumnDefinition[]>data.columns : ;       CANT USE TERNARY OPERATOR BECAUSE DONT HAVE ELSE
        
        return tableDef;
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

    // string[]|error tableNames = client1 -> listTables();
    // io:println("Table Names:\n");
    // io:println(tableNames);
    // io:println("");

    sql:TableDefinition|sql:Error tableDef = client1 -> getTableInfo("employees", include = COLUMNS_WITH_CONSTRAINTS);
    io:println("Table Definition:\n");
    io:println(tableDef);

    //string[]|error routineNames = listRoutines();
    //io:println(routineNames);

    // RoutineDefinition|error r = getRoutineInfo("GetEmployeeByFirstName");
    // io:println("Routine Definition:\n");
    // io:println(r);
}

