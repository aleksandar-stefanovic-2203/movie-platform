package student;

import rs.ac.bg.etf.sab.operations.MoviesOperations;

import java.util.List;
import java.sql.*;
import java.util.ArrayList;

public class sa220196_MoviesOperations implements MoviesOperations {

    private static final Connection connection = DB.getInstance().getConnection();
    
    @Override
    public Integer addMovie(String title, Integer genreId, String director) {
        String query = "{ CALL SP_ADD_MOVIE(?,?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setString(1, title);
            cs.setInt(2, genreId);
            cs.setString(3, director);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer updateMovieTitle(Integer id, String newTitle) {
        String query = "{ CALL SP_UPDATE_MOVIE_TITLE(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, id);
            cs.setString(2, newTitle);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer addGenreToMovie(Integer movieId, Integer genreId) {
        String query = "{ CALL SP_ADD_GENRE_TO_MOVIE(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, movieId);
            cs.setInt(2, genreId);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer removeGenreFromMovie(Integer movieId, Integer genreId) {
        String query = "{ CALL SP_REMOVE_GENRE_FROM_MOVIE(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, movieId);
            cs.setInt(2, genreId);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer updateMovieDirector(Integer id, String newDirector) {
        String query = "{ CALL SP_UPDATE_MOVIE_DIRECTOR(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, id);
            cs.setString(2, newDirector);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer removeMovie(Integer id) {
        String query = "{ CALL SP_REMOVE_MOVIE(?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, id);
            
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            //e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public List<Integer> getMovieIds(String title, String director) {
        String query = "SELECT id FROM dbo.FUNC_GET_MOVIE_IDS(?,?)";
        List<Integer> result = new ArrayList<>();
        
        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setString(1, title);
            ps.setString(2, director);

            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next())
                    result.add(rs.getInt("id"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return result;
    }

    @Override
    public List<Integer> getAllMovieIds() {
        String query = "SELECT id FROM dbo.FUNC_GET_ALL_MOVIE_IDS()";        
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
    public List<Integer> getMovieIdsByGenre(Integer genreId) {
        String query = "SELECT idM FROM dbo.FUNC_GET_MOVIE_IDS_BY_GENRE(?)";
        List<Integer> result = new ArrayList<>();
        
        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, genreId);

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
    public List<Integer> getGenreIdsForMovie(Integer movieId) {
        String query = "SELECT idG FROM dbo.FUNC_GET_GENRE_IDS_FOR_MOVIE(?)";
        List<Integer> result = new ArrayList<>();
        
        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, movieId);

            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next())
                    result.add(rs.getInt("idG"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return result;
    }

    @Override
    public List<Integer> getMovieIdsByDirector(String director) {
        String query = "SELECT id FROM dbo.FUNC_GET_MOVIE_IDS_BY_DIRECTOR(?)";
        List<Integer> result = new ArrayList<>();
        
        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setString(1, director);

            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next())
                    result.add(rs.getInt("id"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return result;
    }

    @Override
    public String getMovieTrend(Integer movieId) {
        String query = "SELECT dbo.FUNC_GET_MOVIE_TREND(?) AS status";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, movieId);

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getObject("status", String.class);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }
    
}
