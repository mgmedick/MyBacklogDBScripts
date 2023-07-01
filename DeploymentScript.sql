USE GameStatsApp;
-- ALTER DATABASE GameStatsApp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

/*********************************************/
-- create/alter tables
/*********************************************/
-- tbl_User
DROP TABLE IF EXISTS tbl_User;

CREATE TABLE tbl_User(
	ID int NOT NULL AUTO_INCREMENT,
	Username varchar(255) NOT NULL,
	Email varchar(100) NOT NULL,
	`Password` varchar(255) NOT NULL,
	PromptToChange bit NOT NULL,
	Locked bit NOT NULL,
	Active bit NOT NULL,
	Deleted bit NOT NULL,
	CreatedBy int NOT NULL,
	CreatedDate datetime NOT NULL,
	ModifiedBy int NULL,
	ModifiedDate datetime NULL,
	PRIMARY KEY (ID)	
);

-- tbl_User_Setting
DROP TABLE IF EXISTS tbl_User_Setting;

CREATE TABLE tbl_User_Setting(
	UserID int NOT NULL,
	IsDarkTheme bit NOT NULL,
	PRIMARY KEY (UserID)	
);

-- tbl_User_GameService
DROP TABLE IF EXISTS tbl_User_GameService;

CREATE TABLE tbl_User_GameService(
	ID int NOT NULL AUTO_INCREMENT,
	UserID int NOT NULL,
	GameServiceID INT NOT NULL,
	PRIMARY KEY (ID)	
);

-- tbl_DefaultGameList
DROP TABLE IF EXISTS tbl_DefaultGameList;

CREATE TABLE tbl_DefaultGameList 
( 
	ID int NOT NULL,
    Name varchar (100) NOT NULL,
    PRIMARY KEY (ID)      
);


-- tbl_UserGameList
DROP TABLE IF EXISTS tbl_UserGameList;

CREATE TABLE tbl_UserGameList 
( 
	ID int NOT NULL AUTO_INCREMENT,
	UserID int NOT NULL,
    Name varchar (100) NOT NULL,
	DefaultGameListID int NULL,
    PRIMARY KEY (ID)      
);

-- tbl_UserGameList_Game
DROP TABLE IF EXISTS tbl_UserGameList_Game;

CREATE TABLE tbl_UserGameList_Game 
( 
	ID int NOT NULL AUTO_INCREMENT,
	UserGameListID int NOT NULL,
    GameID int NOT NULL,
    PRIMARY KEY (ID)      
);

-- tbl_GameService
DROP TABLE IF EXISTS tbl_GameService;

CREATE TABLE tbl_GameService 
( 
    ID int NOT NULL,
    Name varchar (25) NOT NULL,
    PRIMARY KEY (ID)      
);

-- tbl_Game
DROP TABLE IF EXISTS tbl_Game;

CREATE TABLE tbl_Game 
( 
	ID int NOT NULL AUTO_INCREMENT,
    Name varchar (100) NOT NULL,
    CoverImagePath varchar(80) NULL,
    PRIMARY KEY (ID)      
);

-- tbl_Setting
DROP TABLE IF EXISTS tbl_Setting;

CREATE TABLE tbl_Setting 
( 
    ID int NOT NULL AUTO_INCREMENT,
    Name varchar (50) NOT NULL,
    Str varchar (500) NULL,
    Num int NULL,
    Dte datetime NULL,
  	PRIMARY KEY (ID)     
);

/*********************************************/
-- create/alter views
/*********************************************/
-- vw_User
DROP VIEW IF EXISTS vw_User;

CREATE DEFINER=`root`@`localhost` VIEW vw_User AS

    SELECT ua.ID AS UserID,
	ua.Username,
	ua.Email,
	ua.`Password`,
	ua.PromptToChange,
	ua.Locked,
	ua.Active,
	ua.Deleted,
	ua.CreatedBy,
	ua.CreatedDate,
	ua.ModifiedBy,
	ua.ModifiedDate,
	ue.IsDarkTheme,
	COALESCE(GameServiceIDs.Value, '') AS GameServiceIDs
    FROM tbl_User ua
	LEFT JOIN tbl_User_Setting ue ON ue.UserID = ua.ID
 	LEFT JOIN LATERAL (
		SELECT GROUP_CONCAT(CONVERT(uc.GameServiceID,CHAR) ORDER BY uc.ID SEPARATOR ',') Value
	    FROM tbl_User_GameService uc
		WHERE uc.UserID = ua.ID
	) GameServiceIDs ON TRUE
	WHERE ua.Deleted = 0;

-- vw_UserGameList
DROP VIEW IF EXISTS vw_UserGameList;

CREATE DEFINER=`root`@`localhost` VIEW vw_UserGameList AS

    SELECT ul.ID,
	ul.UserID,
	ul.Name,
	ul.DefaultGameListID,
	COALESCE(GameIDs.Value, '') AS GameIDs
    FROM tbl_UserGameList ul
 	LEFT JOIN LATERAL (
		SELECT GROUP_CONCAT(CONVERT(gl.GameID,CHAR) ORDER BY gl.ID SEPARATOR ',') Value
	    FROM tbl_UserGameList_Game gl
		WHERE gl.UserGameListID = ul.ID
	) GameIDs ON TRUE;

/*********************************************/
-- create/alter procs
/*********************************************/
-- GetUserGameListGames
DROP PROCEDURE IF EXISTS GetUserGameListGames;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE GetUserGameListGames
(
	IN UserGameListID INT
)
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT g.ID,
	g.Name,
	g.CoverImagePath,
	UserGameListIDs.Value AS UserGameListIDs
    FROM tbl_Game g
    JOIN tbl_UserGameList_Game gl ON gl.GameID = g.ID
 	LEFT JOIN LATERAL (
		SELECT GROUP_CONCAT( DISTINCT CONVERT(gl1.UserGameListID,CHAR) ORDER BY gl1.UserGameListID SEPARATOR ',') Value
	    FROM tbl_UserGameList_Game gl1
		WHERE gl1.GameID = g.ID
	) UserGameListIDs ON TRUE
	WHERE gl.UserGameListID = UserGameListID;

END $$
DELIMITER ;

/*********************************************/
-- populate tables
/*********************************************/
INSERT INTO tbl_DefaultGameList(ID, Name)
SELECT 1, 'All Games'
UNION ALL
SELECT 2, 'Backlog'
UNION ALL
SELECT 3, 'Playing'
UNION ALL
SELECT 4, 'Completed';

INSERT INTO tbl_GameService(ID, Name)
SELECT 1, 'Steam'
UNION ALL
SELECT 2, 'Xbox';

INSERT INTO tbl_Game (Name, CoverImagePath)
SELECT Name, gl.CoverImagePath
FROM speedrunapp.tbl_Game g
JOIN speedrunapp.tbl_Game_Link gl ON gl.GameID = g.ID
ORDER BY g.ID;































