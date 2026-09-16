package rs.ac.bg.etf.sab;

import rs.ac.bg.etf.sab.operations.*;
import rs.ac.bg.etf.sab.tests.TestHandler;
import rs.ac.bg.etf.sab.tests.TestRunner;
import student.sa220196_GeneralOperations;
import student.sa220196_GenresOperations;
import student.sa220196_MoviesOperations;
import student.sa220196_RatingsOperations;
import student.sa220196_TagsOperations;
import student.sa220196_UsersOperations;
import student.sa220196_WatchlistsOperations;

public class StudentMain {
    public static void main(String[] args) throws Exception {
        GeneralOperations generalOperations = new sa220196_GeneralOperations();
        GenresOperations genresOperations = new sa220196_GenresOperations();
        MoviesOperations moviesOperations = new sa220196_MoviesOperations();
        RatingsOperations ratingsOperation = new sa220196_RatingsOperations();
        TagsOperations tagsOperations = new sa220196_TagsOperations();
        UsersOperations usersOperations = new sa220196_UsersOperations();
        WatchlistsOperations watchlistsOperations = new sa220196_WatchlistsOperations();

        TestHandler.createInstance(
                genresOperations,
                moviesOperations,
                ratingsOperation,
                tagsOperations,
                usersOperations,
                watchlistsOperations,
                generalOperations);
        TestRunner.runTests();
    }
}