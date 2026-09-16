-- KREIRANJE BAZE PODATAKA ===================================================================================================

CREATE DATABASE MoviePlatform

GO

USE MoviePlatform

-- KREIRANJE TABELA ==========================================================================================================

CREATE TABLE Movie (
	id INT PRIMARY KEY IDENTITY(1, 1),
	title VARCHAR(100) NOT NULL,
	director VARCHAR(100),
	status VARCHAR(100) CHECK ( status IN ('Trending', 'Rising', 'Falling', 'Classic') )
)

CREATE TABLE [User] (
	id INT PRIMARY KEY IDENTITY(1, 1),
	username VARCHAR(100) UNIQUE NOT NULL,
	numberOfAwards INT NOT NULL DEFAULT 0
)

CREATE TABLE Genre (
	id INT PRIMARY KEY IDENTITY(1, 1),
	name VARCHAR(100) UNIQUE NOT NULL
)

CREATE TABLE Tag (
	id INT PRIMARY KEY IDENTITY(1, 1),
	name VARCHAR(100) UNIQUE NOT NULL
)

CREATE TABLE WatchList (
	idU INT NOT NULL FOREIGN KEY REFERENCES [User](id) ON UPDATE CASCADE ON DELETE NO ACTION,
	idM INT NOT NULL FOREIGN KEY REFERENCES Movie(id) ON UPDATE CASCADE ON DELETE NO ACTION,
	PRIMARY KEY (idU, idM)
)

CREATE TABLE MovieRating (
	idU INT NOT NULL FOREIGN KEY REFERENCES [User](id) ON UPDATE NO ACTION ON DELETE NO ACTION,
	idM INT NOT NULL FOREIGN KEY REFERENCES Movie(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
	rating INT NOT NULL CHECK (rating BETWEEN 1 AND 10),
	date DATETIME NOT NULL DEFAULT GETDATE(),
	PRIMARY KEY(idU, idM)
)

CREATE TABLE MovieGenre (
	idM INT NOT NULL FOREIGN KEY REFERENCES Movie(id) ON UPDATE CASCADE ON DELETE NO ACTION,
	idG INT NOT NULL FOREIGN KEY REFERENCES Genre(id) ON UPDATE CASCADE ON DELETE NO ACTION,
	PRIMARY KEY (idM, idG)
)

CREATE TABLE MovieTag (
	idM INT NOT NULL FOREIGN KEY REFERENCES Movie(id) ON UPDATE CASCADE ON DELETE NO ACTION,
	idT INT NOT NULL FOREIGN KEY REFERENCES Tag(id) ON UPDATE CASCADE ON DELETE NO ACTION,
	PRIMARY KEY (idM, idT)
)

-- KREIRANJE FUNKCIJA ========================================================================================================

GO

CREATE FUNCTION FUNC_CHECK_RATING_VALIDITY(
	@idU INT,
	@idG INT
)
RETURNS INT
AS
BEGIN
	DECLARE @ratings TABLE (rating INT)

	INSERT INTO @ratings
	SELECT mr.rating
	FROM MovieRating mr
	JOIN Movie m ON  mr.idM = m.id
	JOIN MovieGenre mg ON m.id = mg.idM
	WHERE mr.idU = @idU AND mg.idG = @idG

	DECLARE @numberOfExtremeRatings INT = (
		SELECT COUNT(*)
		FROM @ratings
		WHERE rating IN (1, 10)
	)

	DECLARE @numberOfNeutralRatings INT = (
		SELECT COUNT(*)
		FROM @ratings
		WHERE rating IN (6, 7, 8)
	)

	IF (@numberOfExtremeRatings > 3 AND @numberOfNeutralRatings < 3) RETURN 0
	RETURN 1
END

GO

CREATE FUNCTION FUNC_IS_MOVIE_TREND_RISING(
	@idM INT
)
RETURNS INT
AS
BEGIN
	DECLARE @RISING_THRESHOLD INT = 5

	DECLARE @recentAverageRating DECIMAL(10, 3) = (
		SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
		FROM (
			SELECT TOP (@RISING_THRESHOLD) rating
			FROM MovieRating
			WHERE idM = @idM
			ORDER BY date DESC
		) AS T
	)

	DECLARE @averageRating DECIMAL(10, 3) = (
		SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
		FROM MovieRating
		WHERE idM = @idM
	)

	IF @recentAverageRating >= @averageRating + 1
		RETURN 1

	RETURN 0
END

GO

CREATE FUNCTION FUNC_IS_MOVIE_TREND_FALLING(
	@idM INT
)
RETURNS INT
AS
BEGIN
	DECLARE @FALLING_THRESHOLD INT = 5

	DECLARE @recentAverageRating DECIMAL(10, 3) = (
		SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
		FROM (
			SELECT TOP (@FALLING_THRESHOLD) rating
			FROM MovieRating
			WHERE idM = @idM
			ORDER BY date DESC
		) AS T
	)

	DECLARE @averageRating DECIMAL(10, 3) = (
		SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
		FROM MovieRating
		WHERE idM = @idM
	)

	IF @recentAverageRating <= @averageRating - 1
		RETURN 1

	RETURN 0
END

GO

CREATE FUNCTION FUNC_IS_MOVIE_TREND_CLASSIC(
	@idM INT
)
RETURNS INT
AS
BEGIN
	DECLARE @numberOfRatings INT = (
		SELECT COUNT(*)
		FROM MovieRating
		WHERE idM = @idM
	)	

	DECLARE @averageRating DECIMAL(10, 3) = (
		SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
		FROM MovieRating
		WHERE idM = @idM
	)

	IF @numberOfRatings >= 3 AND @averageRating >= 8
		RETURN 1
	
	RETURN 0
END

GO

CREATE FUNCTION FUNC_IS_MOVIE_TREND_TRENDING(
	@idM INT
)
RETURNS INT
AS
BEGIN
	DECLARE @TRENDING_THRESHOLD INT = 5
	DECLARE @TRENDING_SPAN INT = 30

	IF @idM IN (
		SELECT TOP (@TRENDING_THRESHOLD) WITH TIES idM
		FROM MovieRating
		WHERE DATEDIFF(DAY, date, GETDATE()) <= @TRENDING_SPAN
		GROUP BY idM
		ORDER BY COUNT(*) DESC
	)
		RETURN 1

	RETURN 0
END

GO

CREATE FUNCTION FUNC_GET_MOVIE_TREND(
	@idM INT
)
RETURNS VARCHAR(100)
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM Movie WHERE id = @idM)
		RETURN NULL

	RETURN CASE
		       WHEN dbo.FUNC_IS_MOVIE_TREND_RISING(@idM) = 1 THEN 'Rising'
		       WHEN dbo.FUNC_IS_MOVIE_TREND_FALLING(@idM) = 1 THEN 'Falling'
		       WHEN dbo.FUNC_IS_MOVIE_TREND_CLASSIC(@idM) = 1 THEN 'Classic'
		       WHEN dbo.FUNC_IS_MOVIE_TREND_TRENDING(@idM) = 1 THEN 'Trending'
			   ELSE NULL
		   END
END

GO

CREATE FUNCTION FUNC_DOES_GENRE_EXIST
(
	@name VARCHAR(100)
)
RETURNS INT
AS
BEGIN
	RETURN CASE
			   WHEN EXISTS(SELECT * FROM Genre WHERE name = @name) THEN 1
			   ELSE 0
		   END
END

--SELECT dbo.FUNC_DOES_GENRE_EXIST('aca')

GO

CREATE FUNCTION FUNC_GET_GENRE_ID
(
	@name VARCHAR(100)
)
RETURNS INT
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM Genre WHERE name = @name)
		RETURN NULL

	RETURN (SELECT id FROM Genre WHERE name = @name)
END

--SELECT dbo.FUNC_GET_GENRE_ID('Animacija')

GO

CREATE FUNCTION FUNC_GET_ALL_GENRE_IDS()
RETURNS TABLE
AS
RETURN (SELECT id FROM Genre)

--SELECT *
--FROM dbo.FUNC_GET_ALL_GENRE_IDS()

GO

CREATE FUNCTION FUNC_HAS_TAG
(
	@idM INT,
	@name VARCHAR(100)
)
RETURNS INT
AS
BEGIN

	IF NOT EXISTS(
		SELECT *
		FROM MovieTag
		WHERE idM = @idM AND idT = (
			SELECT id
			FROM Tag
			WHERE name = @name
		)
	)
		RETURN 0

	RETURN 1
END

GO

CREATE FUNCTION FUNC_GET_TAGS_FOR_MOVIE(
	@idM INT
)
RETURNS TABLE
AS
RETURN (
	SELECT t.name AS tag
	FROM MovieTag mt
	JOIN Tag t ON mt.idT = t.id
	WHERE mt.idM = @idM
)

GO

CREATE FUNCTION FUNC_GET_MOVIE_IDS_BY_TAG(
	@name VARCHAR(100)
)
RETURNS TABLE
AS
RETURN (
	SELECT mt.idM AS idM
	FROM MovieTag mt
	JOIN Tag t ON mt.idT = t.id
	WHERE t.name = @name
)

GO

CREATE FUNCTION FUNC_GET_ALL_TAGS()
RETURNS TABLE
AS
RETURN (
	SELECT DISTINCT t.name AS name
	FROM MovieTag mt
	JOIN Tag t ON mt.idT = t.id
)

GO

CREATE FUNCTION FUNC_IS_MOVIE_IN_WATCH_LIST(
	@idU INT,
	@idM INT
)
RETURNS INT
AS
BEGIN
	RETURN CASE
		       WHEN EXISTS(SELECT * FROM WatchList WHERE idU = @idU AND idM = @idM) THEN 1
			   ELSE 0
		   END
END

GO

CREATE FUNCTION FUNC_GET_MOVIES_IN_WATCH_LIST(
	@idU INT
)
RETURNS TABLE
AS
RETURN (
	SELECT idM
	FROM WatchList
	WHERE idU = @idU
)

GO

CREATE FUNCTION FUNC_GET_USERS_WITH_MOVIE_IN_WATCH_LIST(
	@idM INT
)
RETURNS TABLE
AS
RETURN (
	SELECT idU
	FROM WatchList
	WHERE idM = @idM
)

GO

CREATE FUNCTION FUNC_GET_MOVIE_IDS(
	@title VARCHAR(100),
	@director VARCHAR(100)
)
RETURNS TABLE
AS
RETURN (
	SELECT id
	FROM Movie
	WHERE title = @title AND director = @director
)

GO

CREATE FUNCTION FUNC_GET_ALL_MOVIE_IDS()
RETURNS TABLE
AS
RETURN (SELECT id FROM Movie)

GO

CREATE FUNCTION FUNC_GET_MOVIE_IDS_BY_GENRE(
	@idG INT
)
RETURNS TABLE
AS
RETURN (
	SELECT idM
	FROM MovieGenre
	WHERE idG = @idG
)

GO

CREATE FUNCTION FUNC_GET_GENRE_IDS_FOR_MOVIE(
	@idM INT
)
RETURNS TABLE
AS
RETURN (
	SELECT idG
	FROM MovieGenre
	WHERE idM = @idM
)

GO

CREATE FUNCTION FUNC_GET_MOVIE_IDS_BY_DIRECTOR(
	@director VARCHAR(100)
)
RETURNS TABLE
AS
RETURN (
	SELECT id
	FROM Movie
	WHERE director = @director
)

GO

CREATE FUNCTION FUNC_GET_RATING
(
	@idU INT,
	@idM INT
)
RETURNS INT
AS
BEGIN
	IF NOT EXISTS(
		SELECT *
		FROM MovieRating
		WHERE idU = @idU AND idM = @idM
	)
		RETURN NULL

	RETURN (
		SELECT rating
		FROM MovieRating
		WHERE idU = @idU AND idM = @idM
	)
END

GO

CREATE FUNCTION FUNC_GET_RATED_MOVIES_BY_USER(
	@idU INT
)
RETURNS TABLE
AS
RETURN (
	SELECT idM
	FROM MovieRating
	WHERE idU = @idU
)

GO

CREATE FUNCTION FUNC_GET_USERS_WHO_RATED_MOVIES(
	@idM INT
)
RETURNS TABLE
AS
RETURN (
	SELECT idU
	FROM MovieRating
	WHERE idM = @idM
)

GO

CREATE FUNCTION FUNC_DOES_USER_EXIST
(	
	@username VARCHAR(100)
)
RETURNS INT
AS
BEGIN
	IF EXISTS(
		SELECT *
		FROM [User]
		WHERE username = @username
	)
		RETURN 1

	RETURN 0
END

GO

CREATE FUNCTION FUNC_GET_USER_ID
(
	@username VARCHAR(100)
)
RETURNS INT
AS
BEGIN
	IF NOT EXISTS(
		SELECT *
		FROM [User]
		WHERE username = @username
	)
		RETURN NULL

	RETURN (
		SELECT id
		FROM [User]
		WHERE username = @username
	)
END

GO

CREATE FUNCTION FUNC_GET_ALL_USER_IDS()
RETURNS TABLE
AS
RETURN (SELECT id FROM [User])

GO

CREATE FUNCTION FUNC_GET_USER_DESCRIPTION(
	@idU INT
)
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @userRatings TABLE(idM INT, idT INT)
	
	INSERT INTO @userRatings
	SELECT mr.idM, mt.idT
	FROM MovieRating mr
	LEFT JOIN MovieTag mt ON mr.idM = mt.idM
	WHERE mr.idU = @idU

	DECLARE @numberOfRatedMovies INT = (
		SELECT COUNT(DISTINCT idM)
		FROM @userRatings
	)

	DECLARE @numberOfRatedTags INT = (
		SELECT COUNT(DISTINCT idT)
		FROM @userRatings
	)

	RETURN CASE
		       WHEN @numberOfRatedMovies >= 10 AND @numberOfRatedTags >= 10 THEN 'curious'
			   WHEN @numberOfRatedMovies >= 10 AND @numberOfRatedTags < 10 THEN 'focused'
			   WHEN @numberOfRatedMovies < 10 THEN 'undefined'			   
		   END
END

GO

CREATE FUNCTION FUNC_GET_THEMATIC_SPECIALIZATIONS(
	@idU INT
)
RETURNS TABLE
AS
RETURN (
	SELECT t.name AS tag
	FROM MovieRating mr
	JOIN MovieTag mt ON mr.idM = mt.idM
	JOIN Tag t ON mt.idT = t.id
	WHERE mr.rating >= 8 AND mr.idU = @idU
	GROUP BY t.name
	HAVING COUNT(*) >= 2
)

GO

CREATE FUNCTION FUNC_GET_RECOMMENDED_MOVIES_FROM_FAVORITE_GENRES(
	@idU INT
)
RETURNS @movies TABLE (idM INT, avgRating DECIMAL(10, 3))
AS
BEGIN
	DECLARE @favoriteGenres TABLE (idG INT)

	INSERT INTO @favoriteGenres
	SELECT mg.idG
	FROM MovieRating mr
	JOIN MovieGenre mg ON mr.idM = mg.idM
	WHERE mr.idU = @idU
	GROUP BY mg.idG
	HAVING AVG(CAST(mr.rating AS DECIMAL(10, 3))) >= 8

	DECLARE @recommendations TABLE (idM INT)

	INSERT INTO @recommendations
	SELECT DISTINCT m.id
	FROM Movie m
	JOIN MovieGenre mg ON m.id = mg.idM
	WHERE mg.idG IN (SELECT idG FROM @favoriteGenres)
		  AND
		  NOT EXISTS(
		      SELECT *
			  FROM MovieRating mr
			  WHERE mr.idM = m.id AND mr.idU = @idU
		  )
		  AND
		  NOT EXISTS(
		      SELECT *
			  FROM WatchList wl
			  WHERE wl.idM = m.id AND wl.idU = @idU
		  )		  

	INSERT INTO @movies
	SELECT r.idM, AVG(CAST(mr.rating AS DECIMAL(10, 3)))
	FROM @recommendations r
	JOIN MovieRating mr ON r.idM = mr.idM
	GROUP BY r.idM
	HAVING (COUNT(*) >= 4 AND AVG(CAST(mr.rating AS DECIMAL(10, 3))) >= 7.5) OR (COUNT(*) < 4 AND AVG(CAST(mr.rating AS DECIMAL(10, 3))) >= 9)	

	RETURN
END

GO

CREATE FUNCTION FUNC_GET_REWARDS(
	@idU INT
)
RETURNS INT
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM [User] WHERE id = @idU)
		RETURN 0

	RETURN (SELECT numberOfAwards FROM [User] WHERE id = @idU)
END
-- KREIRANJE PROCEDURA ====================================================================

GO

CREATE PROCEDURE SP_REWARD_USER
	@idU INT,
	@idM INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @numberOfRatings INT = (
		SELECT COUNT(*)
		FROM MovieRating
		WHERE idU = @idU
	)

	IF @numberOfRatings < 10
		RETURN	

	DECLARE @avgMovieRating DECIMAL(10, 3) = (
		SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
		FROM MovieRating
		WHERE idM = @idM AND idU <> @idU
	)

	IF @avgMovieRating >= 6
		RETURN

	DECLARE @favoriteGenres TABLE (idG INT)

	INSERT INTO @favoriteGenres
	SELECT mg.idG
	FROM MovieRating mr
	JOIN MovieGenre mg ON mr.idM = mg.idM
	WHERE mr.idU = @idU
	GROUP BY mg.idG
	HAVING AVG(CAST(mr.rating AS DECIMAL(10, 3))) >= 8

	IF NOT EXISTS(
		SELECT *
		FROM MovieGenre
		WHERE idM = @idM AND idG IN (
			SELECT idG FROM @favoriteGenres
		)
	)
		RETURN

	UPDATE [User]
	SET numberOfAwards = numberOfAwards + 1
	WHERE id = @idU
END

GO

CREATE PROCEDURE SP_ERASE_ALL
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM MovieGenre
	DELETE FROM MovieRating
	DELETE FROM MovieTag
	DELETE FROM WatchList
	DELETE FROM Genre
	DELETE FROM Movie	
	DELETE FROM Tag
	DELETE FROM [User]

	DBCC CHECKIDENT ('Genre', RESEED, 0)
	DBCC CHECKIDENT ('Movie', RESEED, 0)
	DBCC CHECKIDENT ('Tag', RESEED, 0)
	DBCC CHECKIDENT ('[User]', RESEED, 0)
END

--EXECUTE SP_ERASE_ALL

GO

CREATE PROCEDURE SP_ADD_GENRE
	@name VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(SELECT * FROM Genre WHERE name = @name)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	INSERT INTO Genre(name) VALUES (@name)

	SELECT id FROM Genre WHERE name = @name
END

--EXECUTE SP_ADD_GENRE @name='Aca'

GO

CREATE PROCEDURE SP_UPDATE_GENRE
	@id INT,
	@name VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(SELECT * FROM Genre WHERE id = @id)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	IF EXISTS(SELECT * FROM Genre WHERE name = @name AND id <> @id)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	UPDATE Genre
	SET name = @name
	WHERE id = @id

	SELECT id FROM Genre WHERE name = @name
	RETURN
END

--EXECUTE SP_UPDATE_GENRE @id = 13, @name = 'Faca'

GO

CREATE PROCEDURE SP_REMOVE_GENRE
	@id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(SELECT * FROM Genre WHERE id = @id)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	DELETE FROM Genre
	WHERE id = @id

	SELECT @id AS id
END

--EXECUTE SP_REMOVE_GENRE @id = 13

GO

CREATE PROCEDURE SP_ADD_TAG
	@idM INT,
	@name VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM Movie
		WHERE id = @idM
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	IF EXISTS(
		SELECT *
		FROM MovieTag
		WHERE idM = @idM AND idT = (
			SELECT id
			FROM Tag
			WHERE name = @name
		)
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	IF NOT EXISTS(SELECT * FROM Tag WHERE name = @name)
		INSERT INTO Tag(name) VALUES (@name)

	DECLARE @idT INT = (SELECT id FROM Tag WHERE name = @name)

	INSERT INTO MovieTag(idM, idT) VALUES (@idM, @idT)

	SELECT @idM AS id
END

GO

CREATE PROCEDURE SP_REMOVE_TAG
	@idM INT,
	@name VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM MovieTag
		WHERE idM = @idM AND idT = (
			SELECT id
			FROM Tag
			WHERE name = @name
		)
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	DECLARE @idT INT = (SELECT id FROM Tag WHERE name = @name)

	DELETE FROM MovieTag
	WHERE idM = @idM AND idT = @idT

	SELECT @idM AS id
END

GO

CREATE PROCEDURE SP_REMOVE_ALL_TAGS_FOR_MOVIE
	@idM INT
AS
BEGIN
	SET NOCOUNT ON;
	
	IF NOT EXISTS(
		SELECT *
		FROM Movie
		WHERE id = @idM		
	)
	BEGIN
		SELECT 0 AS numberOfRemovedTags
		RETURN
	END

	DELETE FROM MovieTag
	WHERE idM = @idM

	SELECT @@ROWCOUNT AS numberOfRemovedTags
END

GO

CREATE PROCEDURE SP_ADD_MOVIE
	@title VARCHAR(100),
	@idG INT,
	@director VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;	

	IF NOT EXISTS(
		SELECT *
		FROM Genre
		WHERE id = @idG
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	INSERT INTO Movie(title, director) VALUES (@title, @director)
	
	DECLARE @idM INT = (SELECT MAX(id) FROM Movie WHERE title = @title)

	INSERT INTO MovieGenre(idM, idG) VALUES (@idM, @idG)

	SELECT @idM AS id
END

GO

CREATE PROCEDURE SP_ADD_USER
	@username VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(
		SELECT *
		FROM [User]
		WHERE username = @username
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	INSERT INTO [User](username) VALUES (@username)

	DECLARE @id INT = (SELECT id FROM [User] WHERE username = @username)

	SELECT @id AS id
END

GO

CREATE PROCEDURE SP_ADD_MOVIE_TO_WATCH_LIST
	@idU INT,
	@idM INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM [User]
		WHERE id = @idU
	)
	OR
	NOT EXISTS(
		SELECT *
		FROM Movie
		WHERE id = @idM
	)
	BEGIN
		SELECT 0 AS wasAdded
		RETURN
	END

	IF EXISTS(
		SELECT *
		FROM WatchList
		WHERE idU = @idU AND idM = @idM
	)
	BEGIN
		SELECT 0 AS wasAdded
		RETURN
	END

	INSERT INTO WatchList(idU, idM) VALUES (@idU, @idM)
	SELECT 1 AS wasAdded
END

GO

CREATE PROCEDURE SP_REMOVE_MOVIE_FROM_WATCH_LIST
	@idU INT,
	@idM INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM WatchList
		WHERE idU = @idU AND idM = @idM
	)
	BEGIN
		SELECT 0 AS wasRemoved
		RETURN
	END

	DELETE FROM WatchList
	WHERE idU = @idU AND idM = @idM

	SELECT 1 AS wasRemoved
END

GO

CREATE PROCEDURE SP_UPDATE_MOVIE_TITLE
	@id INT,
	@newTitle VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM Movie
		WHERE id = @id
	)
	OR
	EXISTS(
		SELECT *
		FROM Movie
		WHERE title = @newTitle
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	UPDATE Movie
	SET title = @newTitle
	WHERE id = @id

	SELECT @id AS id
END

GO

CREATE PROCEDURE SP_ADD_GENRE_TO_MOVIE
	@idM INT,
	@idG INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM Movie
		WHERE id = @idM
	)
	OR
	NOT EXISTS(
		SELECT *
		FROM Genre
		WHERE id = @idG
	)
	OR
	EXISTS(
		SELECT *
		FROM MovieGenre
		WHERE idM = @idM AND idG = @idG
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	INSERT INTO MovieGenre(idM, idG) VALUES (@idM, @idG)
	
	SELECT @idM AS id
END

GO

CREATE PROCEDURE SP_REMOVE_GENRE_FROM_MOVIE
	@idM INT,
	@idG INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM MovieGenre
		WHERE idM = @idM AND idG = @idG
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	DELETE FROM MovieGenre
	WHERE idM = @idM AND idG = @idG
	
	SELECT @idM AS id
END

GO

CREATE PROCEDURE SP_UPDATE_MOVIE_DIRECTOR
	@id INT,
	@newDirector VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM Movie
		WHERE id = @id
	)	
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	UPDATE Movie
	SET director = @newDirector
	WHERE id = @id

	SELECT @id AS id
END

GO

CREATE PROCEDURE SP_REMOVE_MOVIE
	@id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM Movie
		WHERE id = @id
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	DELETE FROM MovieGenre WHERE idM = @id
	DELETE FROM MovieTag WHERE idM = @id
	DELETE FROM MovieRating WHERE idM = @id
	DELETE FROM WatchList WHERE idM = @id

	DELETE FROM Movie
	WHERE id = @id

	SELECT @id AS id
END

GO

CREATE PROCEDURE SP_ADD_RATING
	@idU INT,
	@idM INT,
	@score INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM [User]
		WHERE id = @idU
	)
	OR
	NOT EXISTS(
		SELECT *
		FROM Movie
		WHERE id = @idM
	)
	OR
	EXISTS(
		SELECT *
		FROM MovieRating
		WHERE idM = @idM AND idU = @idU
	)
	BEGIN
		SELECT 0 AS wasAdded
		RETURN
	END	

	INSERT INTO MovieRating(idU, idM, rating) VALUES (@idU, @idM, @score)

	EXECUTE SP_REWARD_USER @idU = @idU, @idM = @idM

	SELECT 1 AS wasAdded
END

GO

CREATE PROCEDURE SP_UPDATE_RATING
	@idU INT,
	@idM INT,
	@score INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM MovieRating
		WHERE idM = @idM AND idU = @idU
	)
	BEGIN
		SELECT 0 AS wasUpdated
		RETURN
	END

	UPDATE MovieRating
	SET rating = @score
	WHERE idU = @idU AND idM = @idM

	SELECT 1 AS wasUpdated
END

GO

CREATE PROCEDURE SP_REMOVE_RATING
	@idU INT,
	@idM INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM MovieRating
		WHERE idM = @idM AND idU = @idU
	)
	BEGIN
		SELECT 0 AS wasDeleted
		RETURN
	END

	DELETE FROM MovieRating
	WHERE idU = @idU AND idM = @idM

	SELECT 1 AS wasDeleted
END

GO

CREATE PROCEDURE SP_UPDATE_USER
	@id INT,
	@newUsername VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM [User]
		WHERE id = @id
	)
	OR
	EXISTS(
		SELECT *
		FROM [User]
		WHERE username = @newUsername
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	UPDATE [User]
	SET username = @newUsername
	WHERE id = @id

	SELECT @id AS id
END

GO

CREATE PROCEDURE SP_REMOVE_USER
	@id INT
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS(
		SELECT *
		FROM [User]
		WHERE id = @id
	)
	BEGIN
		SELECT NULL AS id
		RETURN
	END

	DELETE FROM [User]
	WHERE id = @id

	SELECT @id AS id
END

-- KREIRANJE OKIDACA =========================================================================================================

GO

CREATE TRIGGER TR_BLOCK_EXTREME_RATING
ON MovieRating
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @idU INT, @idG INT

    DECLARE c CURSOR FOR
        SELECT DISTINCT i.idU, mg.idG
        FROM inserted i
        JOIN MovieGenre mg ON i.idM = mg.idM
        WHERE i.rating IN (1,10)

    OPEN c

    FETCH NEXT FROM c INTO @idU, @idG

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF dbo.FUNC_CHECK_RATING_VALIDITY(@idU,@idG)=0
        BEGIN
            RAISERROR('Rating not allowed.',16,1)
            CLOSE c
            DEALLOCATE c
            RETURN
        END

        FETCH NEXT FROM c INTO @idU, @idG
    END

    CLOSE c
    DEALLOCATE c

    INSERT INTO MovieRating(idU,idM,rating)
    SELECT idU,idM,rating
    FROM inserted
END

GO

CREATE TRIGGER TR_UPDATE_MOVIE_TREND
ON MovieRating
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	DECLARE @cursor CURSOR
	DECLARE @idM INT

	SET @cursor = CURSOR FOR
		SELECT idM
		FROM inserted
		UNION
		SELECT idM
		FROM deleted

	OPEN @cursor

	FETCH NEXT FROM @cursor
	INTO @idM

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE Movie
		SET status = dbo.FUNC_GET_MOVIE_TREND(@idM)
		WHERE id = @idM

		FETCH NEXT FROM @cursor
		INTO @idM
	END

	CLOSE @cursor
	DEALLOCATE @cursor
END

GO

-- POPUNJAVANJE TABELA =======================================================================================================

INSERT INTO Genre (name) VALUES
('Akcija'), ('Drama'), ('Komedija'), ('Horor'), ('Naucna fantastika'),
('Triler'), ('Romantika'), ('Animacija'), ('Dokumentarac'), ('Krimi'),
('Avantura'), ('Biografija');

INSERT INTO Tag (name) VALUES
('Oscar'), ('Netflix'), ('Marvel'), ('DC'), ('Indie'),
('Blockbuster'), ('Cult Classic'), ('Based on Book'), ('True Story'), ('Sequel'),
('Prequel'), ('Remake'), ('Foreign'), ('Black and White'), ('Musical'),
('Heist'), ('Time Travel'), ('Zombie'), ('Superhero'), ('Noir');

INSERT INTO Movie (title, director) VALUES
('The Shawshank Redemption', 'Frank Darabont'),
('The Godfather', 'Francis Ford Coppola'),
('The Dark Knight', 'Christopher Nolan'),
('Pulp Fiction', 'Quentin Tarantino'),
('Forrest Gump', 'Robert Zemeckis'),
('Inception', 'Christopher Nolan'),
('Fight Club', 'David Fincher'),
('The Matrix', 'Lana Wachowski'),
('Goodfellas', 'Martin Scorsese'),
('The Silence of the Lambs', 'Jonathan Demme'),
('Interstellar', 'Christopher Nolan'),
('Gladiator', 'Ridley Scott'),
('The Lord of the Rings: The Return of the King', 'Peter Jackson'),
('Schindler''s List', 'Steven Spielberg'),
('Parasite', 'Bong Joon-ho'),
('Whiplash', 'Damien Chazelle'),
('La La Land', 'Damien Chazelle'),
('Get Out', 'Jordan Peele'),
('Mad Max: Fury Road', 'George Miller'),
('Joker', 'Todd Phillips'),
('Avengers: Endgame', 'Anthony Russo'),
('Spider-Man: No Way Home', 'Jon Watts'),
('Dune', 'Denis Villeneuve'),
('Oppenheimer', 'Christopher Nolan'),
('Barbie', 'Greta Gerwig'),
('Everything Everywhere All at Once', 'Daniel Kwan'),
('The Batman', 'Matt Reeves'),
('Top Gun: Maverick', 'Joseph Kosinski'),
('Knives Out', 'Rian Johnson'),
('The Grand Budapest Hotel', 'Wes Anderson'),
('No Country for Old Men', 'Joel Coen'),
('There Will Be Blood', 'Paul Thomas Anderson'),
('The Social Network', 'David Fincher'),
('Arrival', 'Denis Villeneuve'),
('Blade Runner 2049', 'Denis Villeneuve'),
('Se7en', 'David Fincher'),
('The Departed', 'Martin Scorsese'),
('Casino', 'Martin Scorsese'),
('Taxi Driver', 'Martin Scorsese'),
('Raging Bull', 'Martin Scorsese'),
('The Shining', 'Stanley Kubrick'),
('2001: A Space Odyssey', 'Stanley Kubrick'),
('A Clockwork Orange', 'Stanley Kubrick'),
('Apocalypse Now', 'Francis Ford Coppola'),
('Blade Runner', 'Ridley Scott'),
('Alien', 'Ridley Scott'),
('The Terminator', 'James Cameron'),
('Terminator 2: Judgment Day', 'James Cameron'),
('Titanic', 'James Cameron'),
('Avatar', 'James Cameron'),
('Avatar: The Way of Water', 'James Cameron'),
('Jurassic Park', 'Steven Spielberg'),
('E.T. the Extra-Terrestrial', 'Steven Spielberg'),
('Saving Private Ryan', 'Steven Spielberg'),
('Catch Me If You Can', 'Steven Spielberg'),
('The Green Mile', 'Frank Darabont'),
('The Prestige', 'Christopher Nolan'),
('Memento', 'Christopher Nolan'),
('Dunkirk', 'Christopher Nolan'),
('Tenet', 'Christopher Nolan'),
('The Revenant', 'Alejandro Gonzalez Inarritu'),
('Birdman', 'Alejandro Gonzalez Inarritu'),
('Moonlight', 'Barry Jenkins'),
('Spotlight', 'Tom McCarthy'),
('12 Years a Slave', 'Steve McQueen'),
('The Hurt Locker', 'Kathryn Bigelow'),
('Slumdog Millionaire', 'Danny Boyle'),
('Trainspotting', 'Danny Boyle'),
('Oldboy', 'Park Chan-wook'),
('Memories of Murder', 'Bong Joon-ho'),
('The Handmaiden', 'Park Chan-wook'),
('Amelie', 'Jean-Pierre Jeunet'),
('City of God', 'Fernando Meirelles'),
('Pan''s Labyrinth', 'Guillermo del Toro'),
('The Shape of Water', 'Guillermo del Toro'),
('Spirited Away', 'Hayao Miyazaki'),
('My Neighbor Totoro', 'Hayao Miyazaki'),
('Princess Mononoke', 'Hayao Miyazaki'),
('Howl''s Moving Castle', 'Hayao Miyazaki'),
('Your Name', 'Makoto Shinkai'),
('Akira', 'Katsuhiro Otomo'),
('Ghost in the Shell', 'Mamoru Oshii'),
('The Lion King', 'Roger Allers'),
('Toy Story', 'John Lasseter'),
('Finding Nemo', 'Andrew Stanton'),
('Wall-E', 'Andrew Stanton'),
('Up', 'Pete Docter'),
('Inside Out', 'Pete Docter'),
('Coco', 'Lee Unkrich'),
('Ratatouille', 'Brad Bird'),
('The Incredibles', 'Brad Bird'),
('Logan', 'James Mangold'),
('Deadpool', 'Tim Miller'),
('Black Panther', 'Ryan Coogler'),
('Iron Man', 'Jon Favreau'),
('Captain America: The Winter Soldier', 'Anthony Russo'),
('Guardians of the Galaxy', 'James Gunn'),
('Doctor Strange', 'Scott Derrickson'),
('Wonder Woman', 'Patty Jenkins'),
('Man of Steel', 'Zack Snyder'),
('Zodiac', 'David Fincher'),
('Gone Girl', 'David Fincher'),
('Prisoners', 'Denis Villeneuve'),
('Sicario', 'Denis Villeneuve'),
('Her', 'Spike Jonze'),
('Eternal Sunshine of the Spotless Mind', 'Michel Gondry'),
('Lost in Translation', 'Sofia Coppola'),
('Before Sunrise', 'Richard Linklater'),
('Before Sunset', 'Richard Linklater'),
('Before Midnight', 'Richard Linklater'),
('The Big Lebowski', 'Joel Coen'),
('Fargo', 'Joel Coen'),
('Barton Fink', 'Joel Coen'),
('Reservoir Dogs', 'Quentin Tarantino'),
('Kill Bill: Vol. 1', 'Quentin Tarantino'),
('Inglourious Basterds', 'Quentin Tarantino'),
('Django Unchained', 'Quentin Tarantino'),
('Once Upon a Time in Hollywood', 'Quentin Tarantino'),
('The Hateful Eight', 'Quentin Tarantino'),
('Heat', 'Michael Mann'),
('Collateral', 'Michael Mann'),
('The Insider', 'Michael Mann'),
('Scarface', 'Brian De Palma'),
('Carlito''s Way', 'Brian De Palma'),
('The Untouchables', 'Brian De Palma'),
('American Beauty', 'Sam Mendes'),
('American History X', 'Tony Kaye'),
('Requiem for a Dream', 'Darren Aronofsky'),
('Black Swan', 'Darren Aronofsky'),
('The Wrestler', 'Darren Aronofsky'),
('Pi', 'Darren Aronofsky'),
('Donnie Darko', 'Richard Kelly'),
('The Truman Show', 'Peter Weir'),
('Dead Poets Society', 'Peter Weir'),
('Good Will Hunting', 'Gus Van Sant'),
('Milk', 'Gus Van Sant'),
('The Pianist', 'Roman Polanski'),
('Chinatown', 'Roman Polanski'),
('Rosemary''s Baby', 'Roman Polanski'),
('Vertigo', 'Alfred Hitchcock'),
('Psycho', 'Alfred Hitchcock'),
('Rear Window', 'Alfred Hitchcock'),
('North by Northwest', 'Alfred Hitchcock'),
('Citizen Kane', 'Orson Welles'),
('Casablanca', 'Michael Curtiz'),
('Singin'' in the Rain', 'Stanley Donen'),
('Some Like It Hot', 'Billy Wilder'),
('Sunset Boulevard', 'Billy Wilder'),
('The Apartment', 'Billy Wilder'),
('Dr. Strangelove', 'Stanley Kubrick'),
('Full Metal Jacket', 'Stanley Kubrick'),
('Paths of Glory', 'Stanley Kubrick'),
('Lawrence of Arabia', 'David Lean'),
('The Bridge on the River Kwai', 'David Lean'),
('Ben-Hur', 'William Wyler'),
('Gandhi', 'Richard Attenborough'),
('A Beautiful Mind', 'Ron Howard'),
('Apollo 13', 'Ron Howard'),
('Rush', 'Ron Howard'),
('The Imitation Game', 'Morten Tyldum'),
('The Theory of Everything', 'James Marsh'),
('Bohemian Rhapsody', 'Bryan Singer'),
('Rocketman', 'Dexter Fletcher'),
('Elvis', 'Baz Luhrmann'),
('Moulin Rouge!', 'Baz Luhrmann'),
('Romeo + Juliet', 'Baz Luhrmann'),
('The Great Gatsby', 'Baz Luhrmann'),
('Drive', 'Nicolas Winding Refn'),
('Only God Forgives', 'Nicolas Winding Refn'),
('Nightcrawler', 'Dan Gilroy'),
('Poor Things', 'Yorgos Lanthimos');

INSERT INTO [User] (username) VALUES
('filmofil92'), ('kino_kralj'), ('marvel_fanatic'),
('horor_lover'), ('drama_queen'), ('scifi_geek'),
('indie_soul'), ('classic_cinema'), ('netflix_binger'),
('critic_pro'), ('student_filma'), ('balkan_cinephile'),
('animator_dream'), ('noir_nights'), ('romcom_fan'),
('action_hero'), ('docu_watcher'), ('thriller_king'),
('oscar_hunter'), ('retro_reviewer'), ('new_wave'),
('directors_cut'), ('popcorn_time'), ('art_house'),
('blockbuster_boy'), ('serbian_subtitles'), ('midnight_screen'),
('film_club_admin'), ('short_film_fan'), ('podcast_host');

INSERT INTO MovieGenre (idM, idG) VALUES
(1, 2), (1, 10), (2, 2), (2, 10), (3, 1), (3, 6), (4, 2), (4, 10), (4, 6),
(5, 2), (5, 8), (6, 5), (6, 6), (6, 2), (7, 2), (7, 6), (8, 5), (8, 1), (9, 2), (9, 10),
(10, 6), (10, 4), (11, 5), (11, 2), (11, 11), (12, 1), (12, 2), (12, 11), (13, 11), (13, 1),
(13, 5), (14, 2), (14, 10), (14, 9), (15, 2), (15, 6), (15, 10), (16, 2), (17, 7), (17, 2),
(17, 11), (18, 4), (18, 6), (19, 1), (19, 5), (19, 11), (20, 2), (20, 10), (21, 1), (21, 5),
(22, 1), (22, 5), (22, 11), (23, 5), (23, 1), (23, 11), (24, 2), (24, 9), (24, 10), (25, 3),
(25, 7), (26, 5), (26, 2), (26, 3), (27, 1), (27, 6), (27, 10), (28, 1), (28, 11), (29, 3),
(29, 6), (29, 10), (30, 3), (30, 2), (30, 11), (31, 6), (31, 10), (32, 2), (33, 2), (33, 10),
(34, 5), (34, 2), (35, 5), (35, 6), (36, 6), (36, 10), (37, 2), (37, 10), (38, 2), (38, 10),
(39, 2), (40, 2), (40, 12), (41, 4), (41, 6), (42, 5), (43, 5), (43, 6), (44, 2), (44, 11),
(45, 5), (45, 1), (46, 4), (46, 5), (47, 1), (47, 5), (48, 1), (48, 5), (49, 7), (49, 2),
(50, 5), (50, 1), (50, 11), (51, 5), (51, 11), (52, 11), (52, 1), (53, 2), (53, 11), (54, 11),
(54, 2), (55, 2), (55, 11), (56, 2), (57, 5), (57, 6), (58, 5), (58, 6), (59, 2), (59, 11),
(60, 5), (60, 6), (61, 2), (62, 2), (63, 2), (64, 2), (65, 2), (66, 2), (67, 2), (68, 2),
(69, 6), (69, 10), (69, 1), (70, 2), (70, 4), (71, 2), (71, 4), (72, 5), (72, 4), (73, 8),
(73, 11), (74, 8), (74, 11), (75, 8), (75, 5), (76, 8), (76, 5), (77, 8), (77, 7), (78, 8),
(78, 5), (79, 8), (79, 5), (80, 8), (80, 7), (81, 8), (81, 5), (82, 5), (82, 8), (83, 5),
(84, 5), (85, 8), (85, 11), (86, 8), (87, 8), (87, 11), (88, 8), (89, 8), (90, 8), (91, 1),
(91, 5), (92, 1), (92, 5), (93, 1), (93, 5), (94, 1), (94, 5), (95, 1), (95, 5), (96, 1),
(96, 5), (97, 6), (97, 10), (98, 3), (98, 1), (99, 1), (99, 5), (100, 1), (100, 5),
(101, 1), (101, 5), (102, 1), (102, 5), (103, 1), (103, 5), (104, 1), (104, 5),
(105, 6), (105, 10), (106, 6), (106, 2), (107, 6), (107, 10), (108, 7), (108, 2),
(109, 7), (109, 2), (110, 7), (110, 2), (111, 3), (111, 10), (112, 6), (112, 10),
(113, 1), (113, 10), (114, 1), (114, 10), (115, 2), (115, 10), (116, 1), (116, 10),
(117, 1), (117, 2), (118, 1), (118, 2), (119, 1), (119, 2), (120, 1), (120, 2),
(121, 2), (122, 2), (123, 2), (124, 2), (125, 2), (126, 2), (126, 10), (127, 2),
(128, 2), (129, 2), (130, 2), (131, 2), (132, 2), (133, 2), (134, 2), (135, 2),
(136, 2), (137, 2), (138, 2), (139, 2), (140, 2), (141, 2), (142, 2), (143, 2),
(144, 2), (145, 2), (146, 2), (147, 2), (148, 2), (149, 2), (150, 2), (151, 2),
(152, 2), (153, 2), (154, 2), (155, 2), (156, 2), (157, 2), (158, 2), (159, 2),
(160, 2), (161, 2), (162, 2), (163, 2), (164, 2), (165, 2), (166, 2), (167, 2),
(168, 2), (169, 2), (170, 2), (171, 2), (171, 7), (171, 3);

INSERT INTO MovieTag (idM, idT) VALUES
(1, 1), (1, 6), (1, 8), (2, 1), (2, 6), (2, 8), (3, 1), (3, 4), (3, 6), (3, 19),
(4, 1), (4, 6), (4, 7), (5, 1), (5, 6), (5, 9), (6, 1), (6, 6), (6, 17), (7, 6), (7, 7),
(8, 1), (8, 6), (8, 17), (9, 1), (9, 6), (9, 9), (10, 1), (10, 6), (11, 1), (11, 6),
(11, 17), (12, 1), (12, 6), (13, 1), (13, 6), (13, 8), (14, 1), (14, 6), (14, 9),
(15, 1), (15, 6), (15, 13), (16, 1), (16, 5), (17, 1), (17, 15), (18, 1), (18, 5),
(19, 1), (19, 6), (20, 1), (20, 4), (21, 3), (21, 6), (21, 19), (22, 3), (22, 6),
(22, 11), (22, 19), (23, 1), (23, 6), (23, 8), (24, 1), (24, 6), (24, 9), (25, 6),
(26, 1), (26, 5), (27, 4), (27, 6), (28, 6), (28, 11), (29, 5), (29, 8), (30, 1),
(30, 5), (31, 1), (31, 6), (32, 1), (32, 6), (33, 1), (33, 6), (34, 1), (34, 6),
(35, 1), (35, 6), (36, 1), (36, 6), (37, 1), (37, 6), (38, 1), (38, 6), (39, 1),
(39, 6), (40, 1), (40, 6), (40, 9), (41, 1), (41, 6), (41, 7), (42, 1), (42, 6),
(43, 1), (43, 6), (44, 1), (44, 6), (45, 1), (45, 6), (46, 1), (46, 6), (47, 1),
(47, 6), (47, 11), (48, 1), (48, 6), (48, 11), (49, 1), (49, 6), (50, 1), (50, 6),
(51, 1), (51, 6), (51, 10), (52, 1), (52, 6), (53, 1), (53, 6), (53, 9), (54, 1),
(54, 6), (55, 1), (55, 6), (55, 9), (56, 1), (56, 6), (57, 1), (57, 6), (58, 1),
(58, 6), (59, 1), (59, 6), (60, 1), (60, 6), (61, 1), (61, 6), (62, 1), (62, 6),
(63, 1), (63, 6), (64, 1), (64, 6), (65, 1), (65, 6), (66, 1), (66, 6), (67, 1),
(67, 6), (68, 1), (68, 6), (69, 1), (69, 6), (69, 13), (70, 1), (70, 5), (71, 1),
(71, 5), (71, 13), (72, 1), (72, 13), (73, 1), (73, 6), (74, 1), (74, 6), (75, 1),
(75, 6), (76, 1), (76, 6), (77, 1), (77, 6), (78, 1), (78, 6), (79, 1), (79, 6),
(80, 1), (80, 6), (81, 1), (81, 6), (82, 1), (82, 6), (83, 1), (83, 6), (84, 1),
(84, 6), (85, 1), (85, 6), (86, 1), (86, 6), (87, 1), (87, 6), (88, 1), (88, 6),
(89, 1), (89, 6), (90, 1), (90, 6), (91, 3), (91, 6), (91, 19), (92, 3), (92, 6),
(93, 3), (93, 6), (94, 3), (94, 6), (95, 3), (95, 6), (96, 3), (96, 6), (97, 4),
(97, 6), (98, 3), (98, 6), (99, 3), (99, 6), (100, 3), (100, 6), (101, 3), (101, 6),
(102, 3), (102, 6), (103, 3), (103, 6), (104, 3), (104, 6), (105, 6), (105, 20),
(106, 6), (106, 20), (107, 6), (108, 5), (108, 6), (109, 5), (109, 6), (110, 5),
(110, 6), (111, 6), (111, 7), (112, 6), (112, 7), (113, 6), (113, 16), (114, 6),
(114, 16), (115, 6), (115, 9), (116, 6), (116, 16), (117, 6), (117, 16), (118, 6),
(119, 6), (120, 6), (121, 6), (122, 6), (123, 6), (124, 6), (125, 6), (126, 6),
(127, 6), (128, 6), (129, 6), (130, 6), (131, 6), (132, 6), (133, 6), (134, 6),
(135, 6), (136, 6), (137, 6), (138, 6), (139, 6), (140, 6), (141, 6), (142, 6),
(143, 6), (144, 6), (145, 6), (146, 6), (147, 6), (148, 6), (149, 6), (150, 6),
(151, 6), (152, 6), (153, 6), (154, 6), (155, 6), (156, 6), (157, 6), (158, 6),
(159, 6), (160, 6), (161, 6), (162, 6), (163, 6), (164, 6), (165, 6), (166, 6),
(167, 6), (168, 6), (169, 6), (169, 19), (170, 6), (171, 1), (171, 5), (171, 6),
(106, 1), (106, 9), (107, 1), (107, 9), (108, 1), (108, 9),
(112, 20), (113, 20), (114, 20), (170, 20);

INSERT INTO WatchList (idU, idM) VALUES
(1, 6), (1, 11), (1, 24), (1, 28), (2, 1), (2, 2), (2, 3), (2, 9), (2, 14),
(3, 21), (3, 22), (3, 91), (3, 92), (3, 93), (3, 94), (3, 95), (4, 10), (4, 18),
(4, 41), (4, 70), (4, 71), (5, 1), (5, 5), (5, 14), (5, 16), (5, 24), (5, 62),
(6, 6), (6, 8), (6, 11), (6, 23), (6, 34), (6, 35), (6, 42), (7, 15), (7, 16),
(7, 26), (7, 29), (7, 30), (8, 1), (8, 2), (8, 3), (8, 4), (8, 7), (8, 8), (8, 12),
(8, 13), (8, 14), (8, 41), (8, 42), (8, 55), (8, 56), (8, 157), (8, 158), (9, 25),
(9, 28), (9, 98), (9, 99), (10, 1), (10, 2), (10, 3), (10, 6), (10, 11), (10, 14),
(10, 15), (10, 24), (10, 30), (11, 16), (11, 26), (11, 29), (11, 77), (12, 15),
(12, 69), (12, 70), (12, 71), (12, 72), (13, 73), (13, 74), (13, 75), (13, 76),
(13, 77), (13, 78), (13, 79), (13, 80), (14, 105), (14, 106), (14, 107), (14, 112),
(14, 113), (15, 17), (15, 25), (15, 49), (15, 77), (15, 108), (16, 3), (16, 19),
(16, 21), (16, 28), (16, 91), (16, 113), (17, 106), (17, 107), (17, 108), (18, 4),
(18, 10), (18, 18), (18, 27), (18, 29), (18, 36), (18, 97), (19, 1), (19, 2),
(19, 3), (19, 6), (19, 11), (19, 13), (19, 14), (19, 15), (19, 24), (20, 41),
(20, 42), (20, 43), (20, 55), (20, 56), (20, 157), (20, 158), (20, 159), (21, 26),
(21, 34), (21, 77), (21, 108), (22, 6), (22, 57), (22, 58), (22, 59), (22, 60),
(23, 21), (23, 22), (23, 25), (23, 28), (24, 15), (24, 16), (24, 26), (24, 30),
(24, 77), (25, 21), (25, 22), (25, 28), (25, 50), (25, 51), (26, 69), (26, 70),
(26, 72), (27, 4), (27, 7), (27, 18), (27, 41), (27, 97), (28, 1), (28, 2),
(28, 3), (28, 6), (28, 11), (28, 14), (28, 15), (28, 24), (28, 30), (29, 16),
(29, 26), (29, 77), (30, 1), (30, 6), (30, 11), (30, 15), (30, 24);

INSERT INTO MovieRating (idU, idM, rating, date) VALUES
(1, 6, 9, '2026-01-15'), (1, 11, 9, '2026-02-20'), (1, 24, 9, '2026-03-10'),
(1, 28, 8, '2026-04-05'), (2, 1, 9, '2026-06-12'), (2, 2, 9, '2026-06-13'),
(2, 3, 9, '2025-07-01'), (2, 9, 9, '2025-08-15'), (2, 14, 9, '2025-09-20'),
(3, 21, 8, '2026-05-01'), (3, 22, 9, '2026-05-02'), (3, 91, 8, '2026-05-03'),
(3, 92, 7, '2026-05-04'), (3, 93, 9, '2026-05-05'), (4, 10, 9, '2026-01-20'),
(4, 18, 8, '2026-02-14'), (4, 41, 9, '2026-03-01'), (4, 70, 7, '2026-04-10'),
(5, 1, 9, '2026-06-01'), (5, 5, 8, '2026-06-02'), (5, 14, 9, '2026-06-03'),
(5, 16, 9, '2026-06-04'), (5, 24, 9, '2026-06-05'), (6, 6, 9, '2025-07-01'),
(6, 8, 9, '2025-07-02'), (6, 11, 9, '2025-07-03'), (6, 23, 8, '2025-07-04'),
(6, 34, 9, '2025-07-05'), (7, 15, 9, '2025-08-01'), (7, 16, 9, '2025-08-02'),
(7, 26, 9, '2025-08-03'), (7, 29, 8, '2025-08-04'), (8, 1, 9, '2026-01-01'),
(8, 2, 9, '2026-01-02'), (8, 3, 9, '2026-01-03'), (8, 4, 9, '2026-01-04'),
(8, 7, 9, '2026-01-05'), (8, 8, 9, '2026-01-06'), (8, 41, 9, '2026-02-01'),
(8, 42, 9, '2026-02-02'), (9, 25, 7, '2025-09-01'), (9, 28, 9, '2025-09-02'),
(9, 98, 8, '2025-09-03'), (10, 1, 9, '2025-10-01'), (10, 2, 9, '2025-10-02'),
(10, 3, 9, '2025-10-03'), (10, 6, 9, '2025-10-04'), (10, 11, 9, '2025-10-05'),
(10, 14, 9, '2025-10-06'), (10, 15, 9, '2025-10-07'), (10, 24, 9, '2025-10-08'),
(11, 16, 8, '2025-11-01'), (11, 26, 9, '2025-11-02'), (11, 77, 9, '2025-11-03'),
(12, 15, 9, '2025-12-01'), (12, 69, 8, '2025-12-02'), (12, 70, 9, '2025-12-03'),
(13, 73, 9, '2026-01-01'), (13, 74, 9, '2026-01-02'), (13, 75, 9, '2026-01-03'),
(13, 76, 9, '2026-01-04'), (13, 77, 9, '2026-01-05'), (13, 78, 9, '2026-01-06'),
(14, 105, 9, '2026-01-10'), (14, 106, 8, '2026-01-11'), (14, 112, 9, '2026-01-12'),
(15, 17, 7, '2026-02-01'), (15, 25, 6, '2026-02-02'), (15, 77, 9, '2026-02-03'),
(16, 3, 9, '2026-02-10'), (16, 19, 9, '2026-02-11'), (16, 21, 8, '2026-02-12'),
(16, 28, 9, '2026-02-13'), (17, 106, 9, '2026-03-01'), (17, 107, 8, '2026-03-02'),
(17, 108, 9, '2026-03-03'), (18, 4, 9, '2026-03-10'), (18, 10, 9, '2026-03-11'),
(18, 18, 8, '2026-03-12'), (18, 27, 9, '2026-03-13'), (18, 36, 9, '2026-03-14'),
(19, 1, 9, '2026-04-01'), (19, 2, 9, '2026-04-02'), (19, 3, 9, '2026-04-03'),
(19, 6, 9, '2026-04-04'), (19, 11, 9, '2026-04-05'), (19, 13, 9, '2026-04-06'),
(19, 14, 9, '2026-04-07'), (19, 15, 9, '2026-04-08'), (19, 24, 9, '2026-04-09'),
(20, 41, 9, '2026-04-15'), (20, 42, 9, '2026-04-16'), (20, 55, 9, '2026-04-17'),
(20, 157, 9, '2026-04-18'), (21, 26, 9, '2026-05-01'), (21, 34, 9, '2026-05-02'),
(21, 77, 9, '2026-05-03'), (22, 6, 9, '2026-05-10'), (22, 57, 8, '2026-05-11'),
(22, 58, 9, '2026-05-12'), (23, 21, 7, '2026-05-20'), (23, 22, 8, '2026-05-21'),
(23, 25, 6, '2026-05-22'), (24, 15, 9, '2026-06-01'), (24, 16, 9, '2026-06-02'),
(24, 26, 9, '2026-06-03'), (24, 30, 8, '2026-06-04'), (25, 21, 8, '2026-06-10'),
(25, 22, 9, '2026-06-11'), (25, 28, 9, '2026-06-12'), (25, 50, 9, '2026-06-13'),
(26, 69, 9, '2026-06-15'), (26, 70, 8, '2026-06-16'), (27, 4, 9, '2026-06-18'),
(27, 7, 8, '2026-06-19'), (27, 18, 9, '2026-06-20'), (28, 1, 9, '2026-06-21'),
(28, 6, 9, '2026-06-22'), (28, 11, 9, '2026-06-23'), (28, 14, 9, '2026-06-24'),
(29, 16, 9, '2026-06-25'), (29, 26, 9, '2025-06-26'), (30, 1, 9, '2025-06-27'),
(30, 6, 9, '2025-06-28'), (30, 11, 9, '2025-06-29'), (1, 1, 9, '2026-05-01'),
(1, 3, 9, '2026-05-15'), (1, 15, 9, '2026-06-01'), (1, 21, 8, '2026-06-14'),
(2, 6, 9, '2025-10-01'), (2, 11, 9, '2025-10-02'), (2, 15, 9, '2025-07-01'),
(2, 21, 7, '2026-06-15'), (3, 1, 9, '2025-08-01'), (3, 95, 8, '2026-06-01'),
(3, 96, 7, '2026-06-02'), (3, 24, 9, '2026-06-16'), (4, 1, 8, '2025-09-01'),
(4, 71, 8, '2026-05-01'), (4, 24, 8, '2026-06-17'), (5, 62, 9, '2025-07-01'),
(5, 21, 7, '2026-06-18'), (6, 1, 9, '2025-10-01'), (6, 35, 9, '2025-08-01'),
(6, 42, 9, '2025-08-02'), (6, 24, 9, '2026-06-19'), (7, 1, 9, '2025-11-01'),
(7, 30, 9, '2025-09-01'), (7, 24, 9, '2026-06-20'), (8, 12, 9, '2026-03-01'),
(8, 13, 9, '2026-03-02'), (8, 14, 9, '2026-03-03'), (8, 15, 9, '2025-12-01'),
(8, 55, 9, '2026-04-01'), (8, 56, 9, '2026-04-02'), (8, 24, 9, '2026-06-21'),
(9, 1, 7, '2026-01-01'), (9, 99, 7, '2025-10-01'), (9, 24, 8, '2026-06-22'),
(10, 7, 9, '2026-01-01'), (10, 30, 9, '2025-11-01'), (10, 21, 8, '2026-06-23'),
(11, 1, 9, '2026-02-01'), (11, 29, 8, '2025-12-01'), (11, 24, 9, '2026-06-24'),
(12, 1, 8, '2026-03-01'), (12, 71, 9, '2026-01-01'), (12, 72, 8, '2026-01-02'),
(13, 1, 9, '2026-04-01'), (13, 79, 9, '2026-02-01'), (13, 80, 9, '2026-02-02'),
(14, 1, 9, '2026-05-01'), (14, 107, 9, '2026-03-01'), (14, 113, 9, '2026-03-02'),
(14, 114, 8, '2026-03-03'), (15, 1, 7, '2026-02-01'), (15, 49, 8, '2026-04-01'),
(15, 108, 9, '2026-04-02'), (15, 109, 9, '2026-04-03'), (16, 1, 9, '2026-06-01'),
(16, 91, 9, '2026-05-01'), (16, 113, 8, '2026-05-02'), (17, 1, 8, '2026-06-02'),
(18, 1, 9, '2026-06-03'), (18, 29, 9, '2026-06-05'), (18, 97, 8, '2026-06-06'),
(19, 30, 9, '2026-06-10'), (20, 1, 9, '2026-03-01'), (20, 43, 9, '2026-06-12'),
(20, 158, 9, '2026-06-13'), (20, 159, 9, '2026-06-14'), (21, 1, 9, '2026-06-05'),
(21, 108, 9, '2026-06-15'), (22, 1, 8, '2026-06-06'), (22, 59, 8, '2026-06-16'),
(22, 60, 9, '2026-06-17'), (23, 1, 7, '2026-06-07'), (23, 28, 8, '2026-06-18'),
(24, 1, 9, '2026-06-08'), (24, 77, 9, '2026-06-19'), (25, 1, 8, '2026-04-01'),
(25, 51, 8, '2026-06-20'), (26, 1, 8, '2026-06-09'), (26, 72, 9, '2026-06-21'),
(27, 1, 9, '2026-06-10'), (27, 41, 9, '2026-06-22'), (27, 97, 9, '2026-06-23'),
(28, 2, 9, '2026-06-11'), (28, 15, 9, '2026-06-24'), (28, 24, 9, '2026-06-25'),
(28, 30, 9, '2025-06-26'), (29, 1, 9, '2026-06-12'), (29, 77, 9, '2025-06-27'),
(30, 2, 9, '2026-05-01'), (30, 3, 9, '2026-06-13'), (30, 15, 9, '2025-06-28'),
(30, 24, 9, '2025-06-29'), (30, 30, 8, '2025-06-30');

-- TESTIRANJE ================================================================================================================

-- OKIDAC ZA BLOKIRANJE EKSTREMNIH OCENA

--SELECT u.id, u.username, mr.rating, m.id, m.title, g.name
--FROM [User] u
--LEFT JOIN MovieRating mr ON u.id = mr.idU
--JOIN Movie m ON mr.idM = m.id
--LEFT JOIN MovieGenre mg ON m.id = mg.idM
--JOIN Genre g ON mg.idG = g.id
--ORDER BY u.username

--SELECT m.id, m.title, g.name
--FROM Movie m
--JOIN MovieGenre mg ON m.id = mg.idM
--JOIN Genre g ON mg.idG = g.id

--INSERT INTO MovieRating (idU, idM, rating) VALUES (13, 5, 10)

-- OKIDAC ZA AZURIRANJE TRENDA FILMA

--DECLARE @id INT = 8

--SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
--FROM MovieRating
--WHERE idM = @id

--SELECT title
--FROM Movie
--WHERE id = @id

--SELECT idM, date
--FROM MovieRating
--WHERE DATEDIFF(DAY, date, GETDATE()) <= 30
--ORDER BY idM, date

--DECLARE @num INT = 5

--SELECT TOP (@num) idM
--FROM MovieRating
--WHERE DATEDIFF(DAY, date, GETDATE()) <= 30
--GROUP BY idM
--ORDER BY COUNT(*) DESC

--SELECT idM, COUNT(*)
--FROM MovieRating
--WHERE DATEDIFF(DAY, date, GETDATE()) <= 30
--GROUP BY idM
--ORDER BY COUNT(*) DESC

--SELECT COUNT(*)
--FROM MovieRating
--WHERE idM = 2

--SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
--FROM MovieRating
--WHERE idM = 2

--SELECT AVG(CAST(rating AS DECIMAL(10, 3)))
--FROM (
--	SELECT TOP 5 rating
--	FROM MovieRating
--	WHERE idM = 1
--	ORDER BY date DESC
--) AS T