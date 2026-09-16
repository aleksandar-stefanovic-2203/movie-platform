# Movie Platform

JDBC + SQL Server implementation of a movie catalog for the SAB (Sistemi baza podataka) course at ETF Belgrade. The database stores movies, users, genres, tags, ratings, and watchlists. Java classes call stored procedures and functions that encode the business rules.

## Tech stack

- Microsoft SQL Server
- Java 21
- JDBC (`mssql-jdbc`)
- NetBeans (`jdbc/` is a NetBeans project named `SAB_PROJEKAT`)
- JUnit 4 public module tests from the course JAR

## Project layout

```
movie-platform/
├── MoviePlatform.sql              # Schema, functions, procedures, triggers, seed data
├── database-model/                # IE data model
├── docs/
│   ├── README.txt                 # Course notes about the public test JAR
│   └── dokumentacija/             # Javadoc for the operations interfaces
└── jdbc/                          # NetBeans Java project
    └── src/
        ├── rs/ac/bg/etf/sab/StudentMain.java   # Runs the public tests
        └── student/
            ├── DB.java                         # SQL Server connection
            ├── sa220196_GeneralOperations.java
            ├── sa220196_GenresOperations.java
            ├── sa220196_MoviesOperations.java
            ├── sa220196_RatingsOperations.java
            ├── sa220196_TagsOperations.java
            ├── sa220196_UsersOperations.java
            └── sa220196_WatchlistsOperations.java
```

Java operations classes are thin JDBC wrappers. Almost all logic lives in `MoviePlatform.sql`.

## Database

`MoviePlatform.sql` creates the `MoviePlatform` database.

| Table | Purpose |
| --- | --- |
| `Movie` | Title, director, trend `status` (`Trending`, `Rising`, `Falling`, `Classic`) |
| `User` | Unique username, award count |
| `Genre` / `Tag` | Catalog dictionaries |
| `MovieGenre` / `MovieTag` | Many-to-many links |
| `MovieRating` | Score 1–10 with timestamp |
| `WatchList` | User–movie pairs |

The script also loads sample genres, tags, movies, users, ratings, and watchlist entries.

## Business rules

**Movie trend** (`TR_UPDATE_MOVIE_TREND` after rating insert/update/delete), first match wins:

- **Rising** — average of the 5 newest ratings is at least 1 above the overall average
- **Falling** — average of the 5 newest ratings is at least 1 below the overall average
- **Classic** — at least 3 ratings and overall average ≥ 8
- **Trending** — among the 5 most-rated movies in the last 30 days

**Extreme ratings** (`TR_BLOCK_EXTREME_RATING`) — a user cannot add another 1 or 10 in a genre if they already have more than 3 extreme ratings (1 or 10) in that genre and fewer than 3 neutral ratings (6, 7, or 8).

**Recommendations** — movies from the user’s favorite genres (average rating ≥ 8) that they have not rated or watchlisted. A movie qualifies if it has at least 4 ratings and average ≥ 7.5, or fewer than 4 ratings and average ≥ 9.

**Rewards** — a user with at least 10 ratings who rates a movie whose other users average below 6, in one of their favorite genres, receives an award.

**User description**

- `curious` — at least 10 rated movies and at least 10 distinct tags
- `focused` — at least 10 rated movies and fewer than 10 distinct tags
- `undefined` — fewer than 10 rated movies

**Thematic specializations** — tags on movies the user rated 8 or higher at least twice.

## Setup

### 1. Database

Install SQL Server, then run `MoviePlatform.sql` (SSMS, Azure Data Studio, or `sqlcmd`). That creates the database, objects, and seed data.

### 2. Connection

Edit `jdbc/src/student/DB.java` so it matches your instance:

```java
private static final String username = "sa";
private static final String password = "...";
private static final String database = "MoviePlatform";
private static final int port = 1433;   // 1433 is default; this repo used 1434
private static final String server = "localhost";
```

TCP must be enabled on the instance, and SQL authentication must be allowed if you use `sa` (or another SQL login).

### 3. Java project

Open `jdbc/` in NetBeans. Put these libraries on the classpath (the project already references copies under `docs/`):

- Microsoft JDBC Driver for SQL Server (`mssql-jdbc-13.4.0.jre11.jar`)
- Course public test JAR (`SAB_projekat_2026_javni_test.jar`)

If you unpack the test JAR instead of using it as a library, add `hamcrest-core-1.3.jar` and `junit-4.12.jar` as described in `docs/README.txt`.

Interface Javadoc is in `docs/dokumentacija/index.html`.

## Running tests

`StudentMain` wires the `sa220196_*` implementations into the course `TestHandler` and runs `TestRunner.runTests()`.

In NetBeans: open `jdbc/`, set `rs.ac.bg.etf.sab.StudentMain` as the main class, then Run.

`jdbc/test/TestMovies.java` is a reconstructed copy of the public module test, useful for local debugging. Tests call `eraseAll()` (`SP_ERASE_ALL`) before and after each run, so they wipe the database.

## Implementation notes

- Mutations go through stored procedures (`SP_*`).
- Reads go through scalar or table-valued functions (`FUNC_*`).
- `DB` is a singleton; operations share one JDBC connection.
- `User` is a reserved word in T-SQL, so it is quoted as `[User]` in SQL.
