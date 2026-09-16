

import student.sa220196_UsersOperations;
import student.sa220196_RatingsOperations;
import student.sa220196_WatchlistsOperations;
import student.sa220196_TagsOperations;
import student.sa220196_GeneralOperations;
import student.sa220196_MoviesOperations;
import student.sa220196_GenresOperations;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import rs.ac.bg.etf.sab.operations.GeneralOperations;
import rs.ac.bg.etf.sab.operations.GenresOperations;
import rs.ac.bg.etf.sab.operations.MoviesOperations;
import rs.ac.bg.etf.sab.operations.RatingsOperations;
import rs.ac.bg.etf.sab.operations.TagsOperations;
import rs.ac.bg.etf.sab.operations.UsersOperations;
import rs.ac.bg.etf.sab.operations.WatchlistsOperations;

import java.util.List;

import static org.junit.Assert.*;

/**
 * Rekonstruisano iz .class fajla (dekompilovan bajtkod) radi lakseg debagovanja.
 * Nazivi lokalnih promenljivih su rekonstruisani na osnovu redosleda poziva i
 * konteksta (npr. koji film/zanr/tag se dodaje), tako da odgovaraju originalnoj
 * nameri testa. Ako zelis da uporedis 1:1 sa .class fajlom, koristi
 * `javap -c -p PublicModuleTest.class` pored ovog fajla.
 */
public class TestMovies {

    private GeneralOperations general;
    private UsersOperations users;
    private GenresOperations genres;
    private MoviesOperations movies;
    private RatingsOperations ratings;
    private TagsOperations tags;
    private WatchlistsOperations watchlists;

    public TestMovies() {
    }

    @Before
    public void setUp() {

        general = new sa220196_GeneralOperations();
        genres = new sa220196_GenresOperations();
        movies = new sa220196_MoviesOperations();
        ratings = new sa220196_RatingsOperations();
        tags = new sa220196_TagsOperations();
        users = new sa220196_UsersOperations();
        watchlists = new sa220196_WatchlistsOperations();

        assertNotNull(general);
        assertNotNull(users);
        assertNotNull(genres);
        assertNotNull(movies);
        assertNotNull(ratings);
        assertNotNull(tags);
        assertNotNull(watchlists);

        general.eraseAll();
    }

    @After
    public void tearDown() {
        general.eraseAll();
    }

    @Test
    public void publicOne() {
        System.out.println(">>> START publicOne");

        Integer alice = users.addUser("alice");
        Integer bob = users.addUser("bob");
        Integer carol = users.addUser("carol");
        System.out.println("Users: alice=" + alice + " bob=" + bob + " carol=" + carol);

        Integer crimeGenre = genres.addGenre("Crime");
        Integer sciFiGenre = genres.addGenre("Sci-Fi");
        Integer dramaGenre = genres.addGenre("Drama");
        Integer adventureGenre = genres.addGenre("Adventure");
        Integer fantasyGenre = genres.addGenre("Fantasy");
        System.out.println("Genres: crime=" + crimeGenre + " sciFi=" + sciFiGenre
                + " drama=" + dramaGenre + " adventure=" + adventureGenre + " fantasy=" + fantasyGenre);

        Integer godfather = movies.addMovie("The Godfather", crimeGenre, "Francis Ford Coppola");
        Integer irishman = movies.addMovie("The Irishman", crimeGenre, "Martin Scorsese");
        Integer pulpFiction = movies.addMovie("Pulp Fiction", crimeGenre, "Quentin Tarantino");
        Integer inBruges = movies.addMovie("In Bruges", crimeGenre, "Martin McDonagh");
        Integer matrix = movies.addMovie("The Matrix", sciFiGenre, "Lana Wachowski");
        Integer bladeRunner = movies.addMovie("Blade Runner 2049", sciFiGenre, "Denis Villeneuve");
        Integer interstellar = movies.addMovie("Interstellar", sciFiGenre, "Christopher Nolan");
        Integer shawshank = movies.addMovie("The Shawshank Redemption", dramaGenre, "Frank Darabont");
        Integer dieHard = movies.addMovie("Die Hard", adventureGenre, "John McTiernan");
        Integer madMax = movies.addMovie("Mad Max: Fury Road", adventureGenre, "George Miller");
        Integer fifthElement = movies.addMovie("The Fifth Element", sciFiGenre, "Luc Besson");
        Integer prisoners = movies.addMovie("Prisoners", dramaGenre, "Denis Villeneuve");
        Integer moon = movies.addMovie("Moon", sciFiGenre, "Duncan Jones");
        Integer jupiterAscending = movies.addMovie("Jupiter Ascending", sciFiGenre, "Lana Wachowski");
        Integer goodfellas = movies.addMovie("Goodfellas", crimeGenre, "Martin Scorsese");
        Integer lotr = movies.addMovie("The Lord of the Rings: The Fellowship of the Ring", fantasyGenre, "Peter Jackson");

        System.out.println("Movies created: godfather=" + godfather + " irishman=" + irishman
                + " pulpFiction=" + pulpFiction + " inBruges=" + inBruges + " matrix=" + matrix
                + " bladeRunner=" + bladeRunner + " interstellar=" + interstellar
                + " shawshank=" + shawshank + " dieHard=" + dieHard + " madMax=" + madMax
                + " fifthElement=" + fifthElement + " prisoners=" + prisoners + " moon=" + moon
                + " jupiterAscending=" + jupiterAscending + " goodfellas=" + goodfellas + " lotr=" + lotr);

        movies.addGenreToMovie(lotr, adventureGenre);

        tags.addTag(matrix, "cyberpunk");
        tags.addTag(bladeRunner, "cyberpunk");
        tags.addTag(interstellar, "space");
        tags.addTag(pulpFiction, "nonlinear");
        tags.addTag(dieHard, "christmas");
        tags.addTag(madMax, "road");
        tags.addTag(fifthElement, "space-opera");
        tags.addTag(inBruges, "dark-comedy");
        tags.addTag(prisoners, "kidnapping");
        tags.addTag(lotr, "fantasy-quest");
        tags.addTag(matrix, "virtual-reality");

        System.out.println(">>> Pocetne ocene (Crime zanr, alice) - testiranje blokade ekstremnih ocena");

        ratings.addRating(alice, godfather, 10);
        ratings.addRating(alice, irishman, 1);
        ratings.addRating(alice, pulpFiction, 10);
        ratings.addRating(alice, inBruges, 1);

        boolean goodfellasBlockedAttempt = ratings.addRating(alice, goodfellas, 10);
        System.out.println("Goodfellas rating=10 (treba da bude blokirano -> false): " + goodfellasBlockedAttempt);
        assertFalse(goodfellasBlockedAttempt);

        boolean goodfellasNeutral = ratings.addRating(alice, goodfellas, 7);
        System.out.println("Goodfellas rating=7 (treba da uspe -> true): " + goodfellasNeutral);
        assertTrue(goodfellasNeutral);

        boolean pulpFictionUpdate = ratings.updateRating(alice, pulpFiction, 8);
        System.out.println("Pulp Fiction update na 8 (treba da uspe -> true): " + pulpFictionUpdate);
        assertTrue(pulpFictionUpdate);

        System.out.println(">>> Sci-Fi ocene (alice, bob, carol)");

        ratings.addRating(alice, matrix, 10);
        ratings.addRating(alice, bladeRunner, 8);
        ratings.addRating(alice, interstellar, 9);

        ratings.addRating(bob, matrix, 9);
        ratings.addRating(carol, matrix, 10);
        ratings.addRating(bob, bladeRunner, 8);
        ratings.addRating(carol, bladeRunner, 8);
        ratings.addRating(bob, interstellar, 7);
        ratings.addRating(carol, interstellar, 8);

        ratings.addRating(alice, lotr, 10);
        ratings.addRating(bob, lotr, 10);
        ratings.addRating(carol, lotr, 10);

        watchlists.addMovieToWatchlist(alice, bladeRunner);

        System.out.println(">>> Prva provera preporuka za alice (ocekuje se prazna lista)");
        List<Integer> recommended = users.getRecommendedMoviesFromFavoriteGenres(alice);
        System.out.println("Recommended (should be empty): " + recommended);
        assertTrue(recommended.size() == 0);

        ratings.addRating(bob, moon, 9);

        System.out.println(">>> Druga provera preporuka za alice (ocekuje se da sadrzi Moon)");
        recommended = users.getRecommendedMoviesFromFavoriteGenres(alice);
        System.out.println("Recommended (should contain moon=" + moon + "): " + recommended);
        assertTrue(recommended.contains(moon));

        Integer dave = users.addUser("dave");
        Integer eve = users.addUser("eve");
        Integer frank = users.addUser("frank");
        Integer grace = users.addUser("grace");
        System.out.println("Users: dave=" + dave + " eve=" + eve + " frank=" + frank + " grace=" + grace);

        ratings.addRating(bob, fifthElement, 9);
        ratings.addRating(carol, fifthElement, 10);
        ratings.addRating(dave, fifthElement, 10);
        ratings.addRating(eve, fifthElement, 9);

        watchlists.addMovieToWatchlist(alice, fifthElement);

        Integer arrival = movies.addMovie("Arrival", sciFiGenre, "Denis Villeneuve");
        System.out.println("Movie arrival=" + arrival);

        ratings.addRating(bob, arrival, 9);
        ratings.addRating(carol, arrival, 8);
        ratings.addRating(dave, arrival, 8);
        ratings.addRating(eve, arrival, 8);

        ratings.updateRating(bob, matrix, 10);
        ratings.addRating(dave, matrix, 10);
        ratings.addRating(eve, matrix, 10);
        ratings.addRating(frank, matrix, 10);
        ratings.addRating(grace, matrix, 10);

        ratings.addRating(dave, lotr, 10);
        ratings.addRating(eve, lotr, 10);
        ratings.addRating(frank, lotr, 10);
        ratings.addRating(grace, lotr, 10);

        System.out.println(">>> Treca provera preporuka za alice (arrival i moon DA, ostalo NE)");
        recommended = users.getRecommendedMoviesFromFavoriteGenres(alice);
        System.out.println("Recommended: " + recommended);
        assertTrue(recommended.contains(arrival));
        assertTrue(recommended.contains(moon));
        assertFalse(recommended.contains(fifthElement));
        assertFalse(recommended.contains(interstellar));
        assertFalse(recommended.contains(bladeRunner));
        assertFalse(recommended.contains(matrix));

        System.out.println(">>> Testiranje nagrade (reward) za alice");
        ratings.addRating(bob, jupiterAscending, 5);
        ratings.addRating(carol, jupiterAscending, 4);
        ratings.addRating(alice, jupiterAscending, 7);

        Integer numberOfAwards = users.getRewards(alice);
        System.out.println("numberOfAwards for alice (should be 1): " + numberOfAwards);
        assertNotNull(numberOfAwards);
        assertTrue(numberOfAwards.intValue() == 1);

        System.out.println(">>> Testiranje tematskih specijalizacija za alice (ocekuje se cyberpunk)");
        List<String> specializations = users.getThematicSpecializations(alice);
        System.out.println("Specializations: " + specializations);
        assertNotNull(specializations);
        assertTrue(specializations.contains("cyberpunk"));

        System.out.println(">>> Jos ocena za alice (ukupno 14 ocenjenih filmova, 9 razlicitih tagova)");
        ratings.addRating(alice, dieHard, 8);
        ratings.addRating(alice, fifthElement, 8);
        ratings.addRating(alice, shawshank, 8);
        ratings.addRating(alice, prisoners, 8);

        System.out.println(">>> Testiranje opisa korisnika za alice (ocekuje se 'focused')");
        String description = users.getUserDescription(alice);
        System.out.println("Description (should be 'focused'): " + description);
        assertEquals("focused", description);

        System.out.println(">>> KRAJ publicOne - SVE PROSLO");
    }
}