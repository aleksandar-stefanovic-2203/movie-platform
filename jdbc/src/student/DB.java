package student;

import java.sql.*;

public class DB {
    private static final String username = "sa";
    private static final String password = "123";
    private static final String database = "MoviePlatform";
    // KOD MENE:
    // SQLEXPRESS: port 1433
    // MSSQLSERVER: port 1434
    private static final int port = 1434; // Standardan port za MSSQL je 1433, ali ja imam i SQLEXPRESS pa je zato pomeren
    private static final String server = "localhost";
    
    private static final String connectionUrl = "jdbc:sqlserver://%s:%d;encrypt=true;databaseName=%s;trustServerCertificate=true;".formatted(server, port, database);
    
    private Connection connection;

    public Connection getConnection() {
        return connection;
    }
    
    private DB(){
        try {
            connection = DriverManager.getConnection(connectionUrl, username, password);
        } catch (SQLException ex) {
            System.getLogger(DB.class.getName()).log(System.Logger.Level.ERROR, (String) null, ex);
        }
    }
    
    private static DB db = null;
    public static DB getInstance(){
        if(db == null)
            db = new DB();
        
        return db;
    }
}

