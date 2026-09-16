package student;

import rs.ac.bg.etf.sab.operations.UsersOperations;

import java.util.List;
import java.sql.*;
import java.util.ArrayList;

public class sa220196_UsersOperations implements UsersOperations {

    private static final Connection connection = DB.getInstance().getConnection();
    
    @Override
    public Integer addUser(String username) {
        String query = "{ CALL SP_ADD_USER(?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setString(1, username);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();            
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer updateUser(Integer id, String newUsername) {
        String query = "{ CALL SP_UPDATE_USER(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, id);
            cs.setString(2, newUsername);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer removeUser(Integer id) {
        String query = "{ CALL SP_REMOVE_USER(?) }";
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
    public boolean doesUserExist(String username) {
        String query = "SELECT dbo.FUNC_DOES_USER_EXIST(?) AS value";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setString(1, username);            

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getInt("value") == 1;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    @Override
    public Integer getUserId(String username) {
        String query = "SELECT dbo.FUNC_GET_USER_ID(?) AS id";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setString(1, username);

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getObject("id", Integer.class);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    @Override
    public List<Integer> getAllUserIds() {
        String query = "SELECT id FROM dbo.FUNC_GET_ALL_USER_IDS()";        
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

    @Override
    public List<Integer> getRecommendedMoviesFromFavoriteGenres(Integer userId) {
        String query = "SELECT idM FROM dbo.FUNC_GET_RECOMMENDED_MOVIES_FROM_FAVORITE_GENRES(?) ORDER BY avgRating DESC, idM";        
        List<Integer> result = new ArrayList<>();
        try(
            PreparedStatement ps = connection.prepareStatement(query);
        ) {
            ps.setInt(1, userId);
            
            try(ResultSet rs = ps.executeQuery()){
                while(rs.next())
                    result.add(rs.getInt("idM"));
            }
            
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return result;
    }

    @Override
    public Integer getRewards(Integer userId) {
        String query = "SELECT dbo.FUNC_GET_REWARDS(?) AS numberOfAwards";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getObject("numberOfAwards", Integer.class);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    @Override
    public List<String> getThematicSpecializations(Integer userId) {
        String query = "SELECT tag FROM dbo.FUNC_GET_THEMATIC_SPECIALIZATIONS(?)";        
        List<String> result = new ArrayList<>();
        try(
            PreparedStatement ps = connection.prepareStatement(query);
        ) {
            ps.setInt(1, userId);
            
            try(ResultSet rs = ps.executeQuery()){
                while(rs.next())
                    result.add(rs.getString("tag"));
            }
            
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return result;
    }

    @Override
    public String getUserDescription(Integer userId) {
        String query = "SELECT dbo.FUNC_GET_USER_DESCRIPTION(?) AS description";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getObject("description", String.class);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }
    
}
