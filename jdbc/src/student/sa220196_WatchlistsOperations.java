package student;

import rs.ac.bg.etf.sab.operations.WatchlistsOperations;

import java.util.List;
import java.sql.*;
import java.util.ArrayList;

public class sa220196_WatchlistsOperations implements WatchlistsOperations {

    private static final Connection connection = DB.getInstance().getConnection();
    
    @Override
    public boolean addMovieToWatchlist(Integer userId, Integer movieId) {
        String query = "{ CALL SP_ADD_MOVIE_TO_WATCH_LIST(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, userId);
            cs.setInt(2, movieId);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();            
            if(rs.next()) return rs.getObject("wasAdded", Integer.class) == 1;
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return false;
    }

    @Override
    public boolean removeMovieFromWatchlist(Integer userId, Integer movieId) {
        String query = "{ CALL SP_REMOVE_MOVIE_FROM_WATCH_LIST(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, userId);
            cs.setInt(2, movieId);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("wasRemoved", Integer.class) == 1;
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return false;
    }

    @Override
    public boolean isMovieInWatchlist(Integer userId, Integer movieId) {
        String query = "SELECT dbo.FUNC_IS_MOVIE_IN_WATCH_LIST(?,?) AS value";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setInt(2, movieId);

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getInt("value") == 1;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    @Override
    public List<Integer> getMoviesInWatchlist(Integer userId) {
        String query = "SELECT idM FROM dbo.FUNC_GET_MOVIES_IN_WATCH_LIST(?)";        
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
    public List<Integer> getUsersWithMovieInWatchlist(Integer movieId) {
        String query = "SELECT idU FROM dbo.FUNC_GET_USERS_WITH_MOVIE_IN_WATCH_LIST(?)";        
        List<Integer> result = new ArrayList<>();
        try(
            PreparedStatement ps = connection.prepareStatement(query);
        ) {
            ps.setInt(1, movieId);
            
            try(ResultSet rs = ps.executeQuery()){
                while(rs.next())
                    result.add(rs.getInt("idU"));
            }
            
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return result;
    }
    
}
