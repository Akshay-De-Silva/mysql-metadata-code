// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/sql;

@test:Config {
    groups: ["schemaClientTest"]
}
function listTablesTest_Working() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB");
    string [] tableList = check client1->listTables();
    check client1.close();
    test:assertEquals(tableList, ["employees","offices"]);
}

@test:Config {
    groups: ["schemaClientTest"]
}
function listTablesTest_Fail() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB1");
    string [] tableList = check client1->listTables();
    check client1.close();
    test:assertEquals(tableList, []);
}

@test:Config {
    groups: ["schemaClientTest"]
}
function getTableInfo_NoCol() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB");
    sql:TableDefinition|sql:Error 'table = check client1->getTableInfo("employees", include = sql:NO_COLUMNS);
    check client1.close();
    test:assertEquals('table, {"name":"employees","type":"BASE TABLE"});
}

@test:Config {
    groups: ["schemaClientTest"]
}
function getTableInfo_OnlyCol() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB");
    sql:TableDefinition|sql:Error 'table = check client1->getTableInfo("employees", include = sql:COLUMNS_ONLY);
    check client1.close();
    test:assertEquals('table, {"name":"employees","type":"BASE TABLE",
                               "columns":[{"name":"employeeNumber","type":"int","defaultValue":null,"nullable":false},
                               {"name":"lastName","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"firstName","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"extension","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"email","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"officeCode","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"reportsTo","type":"int","defaultValue":null,"nullable":true},
                               {"name":"jobTitle","type":"varchar","defaultValue":null,"nullable":false}]});
}

@test:Config {
    groups: ["schemaClientTest"]
}
function getTableInfo_ColConstraint() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB");
    sql:TableDefinition|sql:Error 'table = check client1->getTableInfo("employees", include = sql:COLUMNS_WITH_CONSTRAINTS);
    check client1.close();
    test:assertEquals('table, {"name":"employees","type":"BASE TABLE",
                               "columns":[{"name":"employeeNumber","type":"int","defaultValue":null,"nullable":false},
                               {"name":"lastName","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"firstName","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"extension","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"email","type":"varchar","defaultValue":null,"nullable":false},
                               {"name":"officeCode","type":"varchar","defaultValue":null,"nullable":false,
                               "referentialConstraints":[{"name":"employees_ibfk_2","tableName":"employees","columnName":"officeCode","updateRule":"NO ACTION","deleteRule":"NO ACTION"}]},
                               {"name":"reportsTo","type":"int","defaultValue":null,"nullable":true,
                               "referentialConstraints":[{"name":"employees_ibfk_1","tableName":"employees","columnName":"reportsTo","updateRule":"NO ACTION","deleteRule":"NO ACTION"}]},
                               {"name":"jobTitle","type":"varchar","defaultValue":null,"nullable":false}]});
}

@test:Config {
    groups: ["schemaClientTest"]
}
function getTableInfo_Fail() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB");
    sql:TableDefinition|sql:Error 'table = check client1->getTableInfo("employee", include = sql:NO_COLUMNS);
    check client1.close();
    if 'table is sql:NoRowsError {
        test:assertEquals('table, "Tablename is incorrect");
    } else {
        test:assertFail("Selected Table does not exist or the user does not have privilages of viewing the Table");
    }
}

@test:Config {
    groups: ["schemaClientTest"]
}
function listRoutinesTest_Working() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB");
    string [] routineList = check client1->listRoutines();
    check client1.close();
    test:assertEquals(routineList, ["getEmpsName"]);
}

@test:Config {
    groups: ["schemaClientTest"]
}
function listRoutinesTest_Fail() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB1");
    string [] routineList = check client1->listRoutines();
    check client1.close();
    test:assertEquals(routineList, []);
}

@test:Config {
    groups: ["schemaClientTest"]
}
function getRoutineInfo_Working() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB");
    sql:RoutineDefinition|sql:Error routine = check client1->getRoutineInfo("getEmpsName");
    check client1.close();
    test:assertEquals(routine, {"name":"getEmpsName","type":"PROCEDURE","returnType":"",
                                "parameters":[{"mode":"IN","name":"empNumber","type":"int"},
                                {"mode":"OUT","name":"fName","type":"varchar"}]});
}

@test:Config {
    groups: ["schemaClientTest"]
}
function getRoutineInfo_Fail() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "testDB");
    sql:RoutineDefinition|sql:Error routine = check client1->getRoutineInfo("getEmpsNames");
    check client1.close();
    if routine is sql:NoRowsError {
        test:assertEquals(routine, "RoutineName is incorrect");
    } else {
        test:assertFail("Selected Routine does not exist or the user does not have privilages of viewing it");
    }
}