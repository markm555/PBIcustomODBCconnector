section CDACustomConnector;
//EnableTraceOutput = true;
[DataSource.Kind="CDACustomConnector", Publish="CDACustomConnector.Publish"]

        // , username as text, password as text

    shared CDACustomConnector.Database = (server as text, database as text, username as text, password as text) as table =>
        let


        ConnectionString =
        [
            Driver="ODBC Driver 18 for SQL Server",
            Authentication="ActiveDirectoryServicePrincipal",

            UID=username, // CHANGE THIS LINE
            PWD=password,  // CHANGE THIS LINE

            ColumnEncryption="Enabled",
            KeyStoreAuthentication="KeyVaultClientSecret",

            KeyStorePrincipalid=username,  // CHANGE THIS LINE
            KeyStoreSecret=password,  // CHANGE THIS LINE

            Server = server,
            Database = database

        ],
        // Get the current credential, and check what type of authentication we're using
        Credential = Extension.CurrentCredential(),
        // Credentials are passed to the ODBC driver using the CredentialConnectionString field.
        // If the user has selected SQL auth (i.e. UsernamePassword), we'll set the 
        // UID and PWD connection string properties. This should be standard across ODBC drivers.
        // If the user has selected Windows auth, we'll set the Trusted_Connection property. 
        // Trusted_Connection is specific to the SQL Server Native Client ODBC driver.
        // Other drivers might require additional connection string properties to be set.
        CredentialConnectionString = [

               UID=username,  // CHANGE THIS LINE
               PWD=password],  // CHANGE THIS LINE

//             if (Credential[AuthenticationKind]?) = "UsernamePassword" then 
//                 [ UID = Credential[Username], PWD = Credential[Password] ]
//             else if (Credential[AuthenticationKind]?) = "Windows" then
//                 [ Trusted_Connection="Yes" ]
//             // unknown authentication kind - return an 'unimplemented' error
//             else
//                 ..., 
        // Here our connector is wrapping M's Odbc.DataSource() function. 
        //
        // The first argument will be the connection string. It can be passed in as a record,
        // or an actual text value. When using a record, M will ensure that the values will be 
        // property encoded. 
        // 
        // The second argument is the options record which allows us to set the credential
        // connection string properties, and override default behaviors.  
        OdbcDataSource = Odbc.DataSource(ConnectionString, [
            // Pass the credential-specific part of the connection string
            CredentialConnectionString = CredentialConnectionString,
            // Enables client side connection pooling for the ODBC driver.
            // Most drivers will want to set this value to true.
            ClientConnectionPooling = true,
            // When HierarchialNavigation is set to true, the navigation tree
            // will be organized by Database -> Schema -> Table. When set to false,
            // all tables will be displayed in a flat list using fully qualified names. 
            HierarchicalNavigation = true,
            // Use the SqlCapabilities record to specify driver capabilities that are not
            // discoverable through ODBC 3.8, and to override capabilities reported by
            // the driver. 
            SqlCapabilities = [
                SupportsTop = true,
                Sql92Conformance = 8 /* SQL_SC_SQL92_FULL */,
                GroupByCapabilities = 4 /* SQL_GB_NO_RELATION */,
                FractionalSecondsScale = 3


            ],

            SoftNumbers = true,
            HideNativeQuery = true,
            // Use the SQLGetInfo record to override values returned by the driver.
            SQLGetInfo = [
                SQL_SQL92_PREDICATES = 0x0000FFFF,
                SQL_AGGREGATE_FUNCTIONS = 0xFF
            ]

            
        ]),
        // The first level of the navigation table will be the name of the database the user
        // passed in. Rather than repeating it again, we'll select it ({[Name = database]}) 
        // and access the next level of the navigation table.
        Database = OdbcDataSource{[Name = database]}[Data]
    in
        Database;

// Data Source Kind description
CDACustomConnector = [
    TestConnection = (dataSourcePath) => 
        let
            json = Json.Document(dataSourcePath),
            server = json[server],
            database = json[database]
        in
            { "DirectSQL.Database", server, database }, 

    Authentication = [
        // Key = [],
         UsernamePassword = [],
         Windows = []
        //Implicit = []
    ],
    Label = "Direct Query for SQL",

    // This sample doesn't enable the use of SSL.
    SupportsEncryption = false
];

// Data Source UI publishing description
CDACustomConnector.Publish = [
    SupportsDirectQuery = true,
    Category = "Database",
    ButtonText = { "ODBC", "Direct Query via ODBC sample for SQL Server" },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = CDACustomConnector.Icons,
    SourceTypeImage = CDACustomConnector.Icons
];

CDACustomConnector.Icons = [
    Icon16 = { Extension.Contents("CDACustomConnector16.png"), Extension.Contents("CDACustomConnector20.png"), Extension.Contents("CDACustomConnector24.png"), Extension.Contents("CDACustomConnector32.png") },
    Icon32 = { Extension.Contents("CDACustomConnector32.png"), Extension.Contents("CDACustomConnector40.png"), Extension.Contents("CDACustomConnector48.png"), Extension.Contents("CDACustomConnector64.png") }
