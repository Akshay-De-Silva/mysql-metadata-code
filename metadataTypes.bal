# Represents a table in the database.
#
# + table_name - The name of the table
# + table_type - Whether the table is a base table or a view
# + columns - The columns included in the table
type TableDefinition record {
    string table_name;
    string table_type;       //figure out space in enum             ****************
    ColumnDefinition[] columns?;
};

public enum TableType {
    BASE_TABLE = "BASE TABLE",             //needs space?
    VIEW
}

# Represents a column in a table.
#
# + name - The name of the column  
# + 'type - The SQL data-type associated with the column
# + defaultValue - The default value of the column  
# + nullable - Whether the column is nullable  
# + referentialConstraints - Referential constraints (foreign key relationships) associated with the column
# + checkConstraints - Check constraints associated with the column
type ColumnDefinition record {
    string name;
    string 'type;
    anydata? defaultValue;
    boolean nullable;
    ReferentialConstraint[] referentialConstraints?;
    CheckConstraint[] checkConstraints?;
};

// public enum nullableBool { //can be imported from sql module         CANT USE
//     TRUE = "YES",
//     FALSE = "NO"
// }

public enum ColumnRetrievalOptions { //can be imported from sql module
    NO_COLUMNS,
    COLUMNS_ONLY,
    COLUMNS_WITH_CONSTRAINTS
}

# Represents a referential constraint (foriegn key constraint).
# 
# + name - The name of the constraint
# + tableName - The name of the table which contains the referenced column
# + columnName - The name of the referenced column
# + updateRule - The action taken when an update statement violates the constraint
# + deleteRule - The action taken when a delete statement violates the constraint
type ReferentialConstraint record {
    string name;
    string tableName;
    string columnName;
    ReferentialRule updateRule;
    ReferentialRule deleteRule;          
};

public enum ReferentialRule {
    NO_ACTION = "NO ACTION",                              //need space?
    RESTRICT,
    CASCADE,
    SET_NULL = "SET NULL",
    SET_DEFAULT = "SET DEFAULT",
    VIEW
}

# Represents a check constraint.
# 
# + name - The name of the constraint
# + clause - The actual text of the SQL definition statement
type CheckConstraint record {
    string name;
    string clause;
};

# Represents a routine.
# 
# + routine_name - The name of the routine
# + routine_type - The type of the routine (procedure or function)
# + data_type - If the routine returns a value, the return data-type. Else ()
# + parameters - The parameters associated with the routine
type RoutineDefinition record {
    string routine_name;
    string routine_type;                //error if using enum
    string? data_type;
    ParameterDefinition[] parameters;
};

public enum RoutineType {
    PROCEDURE,
    FUNCTION
}

# Represents a routine parameter.
# 
# + parameter_mode - The mode of the parameter (IN, OUT, INOUT)
# + parameter_name - The name of the parameter
# + data_type - The data-type of the parameter
type ParameterDefinition record {
    string? parameter_mode;             //error if using enum
    string? parameter_name;
    string? data_type;
};

public enum ParameterMode {
    IN,
    OUT,
    INOUT
}