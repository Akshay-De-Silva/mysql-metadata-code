// Copyright (c) 2022 WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
    groups: ["metadata"]
}
function testListTables() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB", 3306, (), ());
    string[] tableList = check client1->listTables();
    check client1.close();
    test:assertEquals(tableList, ["employees", "offices"]);
}

@test:Config {
    groups: ["metadata"]
}
function testListTablesNegative() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB1", 3306, (), ());
    string[] tableList = check client1->listTables();
    check client1.close();
    test:assertEquals(tableList, []);
}

@test:Config {
    groups: ["metadata"]
}
function testGetTableInfoNoColumns() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB", 3306, (), ());
    sql:TableDefinition 'table = check client1->getTableInfo("employees", include = sql:NO_COLUMNS);
    check client1.close();
    test:assertEquals('table, {"name":"employees", "type":"BASE TABLE"});
}

@test:Config {
    groups: ["metadata"]
}
function testGetTableInfoColumnsOnly() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB", 3306, (), ());
    sql:TableDefinition 'table = check client1->getTableInfo("employees", include = sql:COLUMNS_ONLY);
    check client1.close();
    test:assertEquals('table.name, "employees");
    test:assertEquals('table.'type, "BASE TABLE");
    test:assertEquals((<sql:ColumnDefinition[]>'table.columns).length(), 8);  
}

@test:Config {
    groups: ["metadata"]
}
function testGetTableInfoColumnsWithConstraints() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB", 3306, (), ());
    sql:TableDefinition 'table = check client1->getTableInfo("employees", include = sql:COLUMNS_WITH_CONSTRAINTS);
    check client1.close();
    test:assertEquals('table.name, "employees");
    test:assertEquals('table.'type, "BASE TABLE");
    test:assertEquals((<sql:ColumnDefinition[]>'table.columns).length(), 8);
}

@test:Config {
    groups: ["metadata"]
}
function testGetTableInfoNegative() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB", 3306, (), ());
    sql:TableDefinition|sql:Error 'table = client1->getTableInfo("employee", include = sql:NO_COLUMNS);
    check client1.close();
    if 'table is sql:Error {
        test:assertEquals('table.message(), "Selected Table does not exist or the user does not have privilages of viewing the Table");
    } else {
        test:assertFail("Expected result not received");
    }
}

@test:Config {
    groups: ["metadata"]
}
function testListRoutines() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB", 3306, (), ());
    string[] routineList = check client1->listRoutines();
    check client1.close();
    test:assertEquals(routineList, ["getEmpsName", "getEmpsEmail"]);
}

@test:Config {
    groups: ["metadata"]
}
function testListRoutinesNegative() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB1", 3306, (), ());
    string[] routineList = check client1->listRoutines();
    check client1.close();
    test:assertEquals(routineList, []);
}

@test:Config {
    groups: ["metadata"]
}
function testGetRoutineInfo() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB", 3306, (), ());
    sql:RoutineDefinition routine = check client1->getRoutineInfo("getEmpsName");
    check client1.close();
    test:assertEquals(routine.name, "getEmpsName");
    test:assertEquals(routine.'type, "PROCEDURE");
    test:assertEquals((<sql:ParameterDefinition[]>routine.parameters).length(), 2);
}

@test:Config {
    groups: ["metadata"]
}
function testGetRoutineInfoNegative() returns error? {
    SchemaClient client1 = check new("localhost", "root", "password", "metadataDB", 3306, (), ());
    sql:RoutineDefinition|sql:Error routine = client1->getRoutineInfo("getEmpsNames");
    check client1.close();
    if routine is sql:Error {
        test:assertEquals(routine.message(), "Selected Routine does not exist or the user does not have privilages of viewing it");
    } else {
        test:assertFail("Expected result not recieved");
    }
}
