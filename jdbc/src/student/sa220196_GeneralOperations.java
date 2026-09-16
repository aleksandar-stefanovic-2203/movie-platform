package student;

import rs.ac.bg.etf.sab.operations.GeneralOperations;
import java.sql.*;

public class sa220196_GeneralOperations implements GeneralOperations {

    private static final Connection connection = DB.getInstance().getConnection();
    
    @Override
    public void eraseAll() {
        String query = "{ CALL SP_ERASE_ALL() }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.execute();
        } catch (SQLException e){
            e.printStackTrace();
        }
    }
    
}
