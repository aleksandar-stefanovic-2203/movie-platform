package student;

import rs.ac.bg.etf.sab.operations.GenresOperations;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class sa220196_GenresOperations implements GenresOperations {

    private static final Connection connection = DB.getInstance().getConnection();
    
    @Override
    public Integer addGenre(String name) {
        String query = "{ CALL SP_ADD_GENRE(?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setString(1, name);
            cs.execute();
            ResultSet rs = cs.getResultSet();            
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer updateGenre(Integer id, String name) {
        String query = "{ CALL SP_UPDATE_GENRE(?, ?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, id);
            cs.setString(2, name);
            cs.execute();
            ResultSet rs = cs.getResultSet();            
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer removeGenre(Integer id) {
        String query = "{ CALL SP_REMOVE_GENRE(?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, id);
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public boolean doesGenreExist(String name) {
        String query = "SELECT dbo.FUNC_DOES_GENRE_EXIST(?) AS value";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setString(1, name);            

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getInt("value") == 1;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    @Override
    public Integer getGenreId(String name) {
        String query = "SELECT dbo.FUNC_GET_GENRE_ID(?) AS id";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setString(1, name);

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getObject("id", Integer.class);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    @Override
    public List<Integer> getAllGenreIds() {
        String query = "SELECT id FROM dbo.FUNC_GET_ALL_GENRE_IDS()";        
        List<Integer> result = new ArrayList<>();
        try(
            Statement st = connection.createStatement();
            ResultSet rs = st.executeQuery(query)
        ) {
            while(rs.next())
                result.add(rs.getInt("id"));
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return result;
    }
    
}
