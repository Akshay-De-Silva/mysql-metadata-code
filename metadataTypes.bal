# Represents a table in the database.
#
# + table_name - The name of the table
# + table_type - Whether the table is a base table or a view
# + columns - The columns included in the table
public type TableDefinition record {
    string table_name;
    string table_type;       //figure out space in enum             ****************
    ColumnDefinition[] columns?;
    CheckConstraint[] constraints?;
    string table_catalog;    //unsure of datatype
    string table_schema;
    string engine;           //unsure of datatype
    int 'version?;           //unsure of datatype
    string row_format?;      //unsure of datatype
    int row_num?;
    int avg_row_len?;
    int data_len?;
    int max_data_len?;
    int index_len?;
    int data_free?;
    int auto_incr?;
    string create_time?;     //unsure of datatype
    string|() checksum?;     //unsure of datatype
    string create_options?;  //unsure of datatype
    string table_comment?;
};

public enum TableType {
    BASE_TABLE,             //needs space?
    VIEW
}

# Represents a column in a table.
#
# + column_name - The name of the column  
# + data_type - The SQL data-type associated with the column
# + column_default - The default value of the column  
# + is_nullable - Whether the column is nullable  
# + referentialConstraints - Referential constraints (foreign key relationships) associated with the column
# + checkConstraints - Check constraints associated with the column
public type ColumnDefinition record {
    string column_name;
    string data_type;
    string? column_default;
    string is_nullable;
    ReferentialConstraint[] referentialConstraints?;
    CheckConstraint[] checkConstraints?;
    string table_catalog;
    string table_schema;
    string table_name;
    int ordinal_position;
    int? character_maximum_length?;
    int? character_octet_length?;
    int? numeric_precision?;         //unsure of datatype 
    int? numeric_scale?;             //unsure of datatype
    int? datetime_precision?;       //unsure of datatype
    string? character_set_name?;    //unsure of datatype
    string? collation_name?;        //unsure of datatype
    string column_type?;            //unsure of datatype
    string? column_key;             //unsure of datatype
    string? extra;                  //unsure of datatype
    string? privileges;             //unsure of datatype
    string? column_comment?;           
    string? generation_expression?; //unsure of datatype
    string? srs_id?;                //unsure of datatype
};

# Represents a referential constraint (foriegn key constraint).
# 
# + constraint_name - The name of the constraint
# + table_name - The name of the table which contains the referenced column
# + column_name - The name of the referenced column
# + update_rule - The action taken when an update statement violates the constraint
# + delete_rule - The action taken when a delete statement violates the constraint
public type ReferentialConstraint record {
    string constraint_name;
    string table_name;
    string column_name;
    string update_rule;            //figure out space in enum             ****************
    string delete_rule;            //figure out space in enum             ****************
    string constraint_catalog;
    string constraint_schema;
    string unique_constraint_catalog?;
    string unique_constraint_schema?;
    string unique_constraint_name?;
    string match_option?;
    string? referenced_table_name;
};

public enum ReferentialRule {
    NO_ACTION,                              //need space?
    RESTRICT,
    CASCADE,
    SET_NULL,
    SET_DEFAULT,
    VIEW
}

# Represents a check constraint.
# 
# + constraint_name - The name of the constraint
# + check_clause - The actual text of the SQL definition statement
public type CheckConstraint record {
    string constraint_name;
    string check_clause;
    string constraint_catalog;
    string constraint_schema;
};

# Represents a routine.
# 
# + name - The name of the routine
# + 'type - The type of the routine (procedure or function)
# + returnType - If the routine returns a value, the return data-type. Else ()
# + parameters - The parameters associated with the routine
public type RoutineDefinition record {
    string name;
    RoutineType 'type;
    string? returnType;
    ParameterDefinition[] parameters;
};

public enum RoutineType {
    PROCEDURE,
    FUNCTION
}

# Represents a routine parameter.
# 
# + mode - The mode of the parameter (IN, OUT, INOUT)
# + name - The name of the parameter
# + 'type - The data-type of the parameter
public type ParameterDefinition record {
    ParameterMode mode;
    string name;
    string 'type;
};

public enum ParameterMode {
    IN,
    OUT,
    INOUT
}