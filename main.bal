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
            return error("Closing of the Stream Failed", cause = e);
        }

        return tables;
    }

    isolated remote function getTableInfo(string tableName, sql:ColumnRetrievalOptions include = sql:COLUMNS_ONLY) returns sql:TableDefinition|sql:Error { //return as sql:TableDefinition
        record {}|sql:Error 'table = self.dbClient->queryRow(
            `SELECT TABLE_TYPE FROM information_schema.tables 
             WHERE (table_schema=${self.database} and table_name = ${tableName});`
        );

        if 'table is sql:Error {
            return error("Tablename is incorrect");
        } else if 'table == {} {
            return <sql:NoRowsError>error("Selected Table does not exist or the user does not have privilages of viewing the Table");
        } else {
            sql:TableDefinition tableDef = {
                name: tableName,
                'type: <TableType>'table["TABLE_TYPE"]
            };

            if !(include == sql:NO_COLUMNS) {
                sql:ColumnDefinition[] columns = [];
                stream<record {}, sql:Error?> colResults = self.dbClient->query(
                    `SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT, IS_NULLABLE FROM information_schema.columns 
                     WHERE (table_schema=${self.database} and table_name = ${tableName});`
                );
                do {
                    check from record {} result in colResults
                        do {
                            sql:ColumnDefinition column = {
                                name: <string>result["COLUMN_NAME"],
                                'type: <string>result["DATA_TYPE"],
                                defaultValue: result["COLUMN_DEFAULT"],
                                nullable: (<string>result["IS_NULLABLE"]) == "YES" ? true : false
                            };
                            columns.push(column);
                        };
                } on fail error e {
                    return error("Error - recieved sql data is of type SQL:Error", cause = e);
                }
                check colResults.close();

                tableDef.columns = columns;

                if include == sql:COLUMNS_WITH_CONSTRAINTS {                                            //NEED TO ADD ERROR CHECKING LIKE EXAMPLE
                    map<sql:CheckConstraint[]> checkConstMap = {};

                    stream<record {}, sql:Error?> checkResults = self.dbClient->query(
                        `SELECT CONSTRAINT_NAME, CHECK_CLAUSE FROM information_schema.check_constraints 
                        WHERE CONSTRAINT_SCHEMA=${self.database};`
                    );
                    do {
                        check from record {} result in checkResults
                            do {
                                sql:CheckConstraint 'check = {
                                    name: <string>result["CONSTRAINT_NAME"],
                                    clause: <string>result["CHECK_CLAUSE"]
                                };
                                //checkConst.push('check);

                                string colName = <string>result["COLUMN_NAME"];
                                if checkConstMap[colName] is () {
                                    checkConstMap[colName] = [];
                                }
                                checkConstMap.get(colName).push('check);
                            };
                    } on fail error e {
                        return error("Error - recieved sql data is of type SQL:Error", cause = e);
                    }
                    check checkResults.close();

                    _ = checkpanic from sql:ColumnDefinition col in <sql:ColumnDefinition[]>tableDef.columns                        //NEW
                        do {
                            sql:CheckConstraint[]? checkConst = checkConstMap[col.name];
                            if !(checkConst is ()) && checkConst.length() != 0 {
                                col.checkConstraints = checkConst;
                            }
                            //col.checkConstraints = checkConst;
                        };


                    map<sql:ReferentialConstraint[]> refConstMap = {};

                    stream<record {}, sql:Error?> refResults = self.dbClient->query(
                        `SELECT kcu.CONSTRAINT_NAME, kcu.TABLE_NAME, kcu.COLUMN_NAME, rc.UPDATE_RULE, rc.DELETE_RULE
                        FROM information_schema.referential_constraints rc 
                        JOIN information_schema.key_column_usage as kcu
                        ON kcu.CONSTRAINT_CATALOG = rc.CONSTRAINT_CATALOG 
                        AND kcu.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
                        AND kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
                        WHERE (rc.CONSTRAINT_SCHEMA=${self.database}  and kcu.TABLE_NAME = ${tableName});`
                    );
                    do {
                        check from record {} result in refResults
                            do {
                                sql:ReferentialConstraint ref = {
                                    name: <string>result["CONSTRAINT_NAME"],
                                    tableName: <string>result["TABLE_NAME"],
                                    columnName: <string>result["COLUMN_NAME"],
                                    updateRule: <sql:ReferentialRule>result["UPDATE_RULE"],
                                    deleteRule: <sql:ReferentialRule>result["DELETE_RULE"]
                                };
                                //refConst.push(ref);
                                
                                string colName = <string>result["COLUMN_NAME"];
                                if refConstMap[colName] is () {
                                    refConstMap[colName] = [];
                                }
                                refConstMap.get(colName).push(ref);
                            };
                    } on fail error e {
                        return error sql:Error("Error - recieved sql data is of type SQL:Error", cause = e);
                    }

                    _ = checkpanic from sql:ColumnDefinition col in <sql:ColumnDefinition[]>tableDef.columns                    //NEW
                        do {
                            sql:ReferentialConstraint[]? refConst = refConstMap[col.name];
                            if !(refConst is ()) && refConst.length() != 0 {
                                col.referentialConstraints = refConst;
                            }
                            //col.referentialConstraints = refConst;
                        };

                    check refResults.close();
                }
            }

            //sql:TableDefinition sqlData = {name: data.table_name, 'type: <TableType>data.table_type};
            // if data.columns is ColumnDefinition[] {
            //     sqlData.columns = <sql:ColumnDefinition[]>data.columns; 
            // }
            //sqlData.columns = data.columns is ColumnDefinition[] ? <sql:ColumnDefinition[]>data.columns : ;       CANT USE TERNARY OPERATOR BECAUSE DONT HAVE ELSE

            return tableDef;
        }
    }

    isolated remote function listRoutines() returns string[]|sql:Error {
        string[] routines = [];
        stream<record {|string routine_name;|}, sql:Error?> results = self.dbClient->query(
            `SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES
            WHERE ROUTINE_SCHEMA = ${self.database};`
        );

        do {
            check from record {|string routine_name;|} result in results
                do {
                    routines.push(result.routine_name.toString());
                };
        } on fail error e {
            return error("Parsing Failed", cause = e);
        }

        do {
            check results.close();
        } on fail error e {
            return error("Closing of the Stream Failed", cause = e);
        }

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

    // string[]|error tableNames = client1->listTables();
    // io:println("Table Names:\n");
    // io:println(tableNames);
    // io:println("");

    // sql:TableDefinition|sql:Error tableDef = client1->getTableInfo("employees", include = COLUMNS_WITH_CONSTRAINTS);
    // io:println("Table Definition:\n");
    // io:println(tableDef);

    string[]|error routineNames = client1->listRoutines();
    io:println("Routine Names:\n");
    io:println(routineNames);
    io:println("");

    // RoutineDefinition|error r = getRoutineInfo("GetEmployeeByFirstName");
    // io:println("Routine Definition:\n");
    // io:println(r);
}

