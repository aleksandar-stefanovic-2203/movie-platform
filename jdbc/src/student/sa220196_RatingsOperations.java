package student;

import rs.ac.bg.etf.sab.operations.RatingsOperations;

import java.util.List;
import java.sql.*;
import java.util.ArrayList;

public class sa220196_RatingsOperations implements RatingsOperations {

    private static final Connection connection = DB.getInstance().getConnection();
    
    @Override
    public boolean addRating(Integer userId, Integer movieId, Integer score) {
        String query = "{ CALL SP_ADD_RATING(?,?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, userId);
            cs.setInt(2, movieId);
            cs.setInt(3, score);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("wasAdded", Integer.class) == 1;
        } catch (SQLException e){}
        
        return false;
    }

    @Override
    public boolean updateRating(Integer userId, Integer movieId, Integer score) {
        String query = "{ CALL SP_UPDATE_RATING(?,?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, userId);
            cs.setInt(2, movieId);
            cs.setInt(3, score);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();            
            if(rs.next()) return rs.getObject("wasUpdated", Integer.class) == 1;
        } catch (SQLException e){}
        
        return false;
    }

    @Override
    public boolean removeRating(Integer userId, Integer movieId) {
        String query = "{ CALL SP_REMOVE_RATING(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, userId);
            cs.setInt(2, movieId);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();            
            if(rs.next()) return rs.getObject("wasDeleted", Integer.class) == 1;
        } catch (SQLException e){}
        
        return false;
    }

    @Override
    public Integer getRating(Integer userId, Integer movieId) {
        String query = "SELECT dbo.FUNC_GET_RATING(?,?) AS rating";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setInt(2, movieId);

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getObject("rating", Integer.class);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    @Override
    public List<Integer> getRatedMoviesByUser(Integer userId) {
        String query = "SELECT idM FROM dbo.FUNC_GET_RATED_MOVIES_BY_USER(?)";
        List<Integer> result = new ArrayList<>();
        
        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next())
                    result.add(rs.getInt("idM"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return result;
    }

    @Override
    public List<Integer> getUsersWhoRatedMovie(Integer movieId) {
        String query = "SELECT idU FROM dbo.FUNC_GET_USERS_WHO_RATED_MOVIES(?)";
        List<Integer> result = new ArrayList<>();
        
        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, movieId);

            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next())
                    result.add(rs.getInt("idU"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return result;
    }
    
}
