package student;

import rs.ac.bg.etf.sab.operations.TagsOperations;

import java.util.List;
import java.sql.*;
import java.util.ArrayList;

public class sa220196_TagsOperations implements TagsOperations {

    private static final Connection connection = DB.getInstance().getConnection();
    
    @Override
    public Integer addTag(Integer movieId, String tag) {
        String query = "{ CALL SP_ADD_TAG(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, movieId);
            cs.setString(2, tag);
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public Integer removeTag(Integer movieId, String tag) {
        String query = "{ CALL SP_REMOVE_TAG(?,?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, movieId);
            cs.setString(2, tag);
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("id", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return null;
    }

    @Override
    public int removeAllTagsForMovie(Integer movieId) {
        String query = "{ CALL SP_REMOVE_ALL_TAGS_FOR_MOVIE(?) }";
        try(
            CallableStatement cs = connection.prepareCall(query)
        ) {
            cs.setInt(1, movieId);
            cs.execute();
            ResultSet rs = cs.getResultSet();
            if(rs.next()) return rs.getObject("numberOfRemovedTags", Integer.class);
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return 0;
    }

    @Override
    public boolean hasTag(Integer movieId, String tag) {
        String query = "SELECT dbo.FUNC_HAS_TAG(?,?) AS value";

        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, movieId);
            ps.setString(2, tag);

            try (ResultSet rs = ps.executeQuery()) {
                if(rs.next()) return rs.getInt("value") == 1;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    @Override
    public List<String> getTagsForMovie(Integer movieId) {
        String query = "SELECT tag FROM dbo.FUNC_GET_TAGS_FOR_MOVIE(?)";
        List<String> result = new ArrayList<>();
        
        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setInt(1, movieId);

            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next())
                    result.add(rs.getString("tag"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return result;
    }

    @Override
    public List<Integer> getMovieIdsByTag(String tag) {
        String query = "SELECT idM FROM dbo.FUNC_GET_MOVIE_IDS_BY_TAG(?)";
        List<Integer> result = new ArrayList<>();
        
        try (PreparedStatement ps = connection.prepareStatement(query)) {
            ps.setString(1, tag);

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
    public List<String> getAllTags() {
        String query = "SELECT name FROM dbo.FUNC_GET_ALL_TAGS()";        
        List<String> result = new ArrayList<>();
        try(
            Statement st = connection.createStatement();
            ResultSet rs = st.executeQuery(query)
        ) {
            while(rs.next())
                result.add(rs.getString("name"));
        } catch (SQLException e){
            e.printStackTrace();
        }
        
        return result;
    }
    
}
