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

-- tbl_UserAccount
DROP TABLE IF EXISTS tbl_UserAccount;

CREATE TABLE tbl_UserAccount(
	ID int NOT NULL AUTO_INCREMENT,
	UserID int NOT NULL,
	AccountTypeID INT NOT NULL,
	AccountUserID varchar (800) NULL,
	AccountUserHash varchar (800) NULL,		
	ImportLastRunDate datetime NULL,
	CreatedDate datetime NOT NULL,	
	ModifiedDate datetime NULL,		
	PRIMARY KEY (ID)	
);

-- tbl_UserAccount_Token
DROP TABLE IF EXISTS tbl_UserAccount_Token;

CREATE TABLE tbl_UserAccount_Token(
	ID int NOT NULL AUTO_INCREMENT,
	UserAccountID int NOT NULL,
	TokenTypeID INT NOT NULL,
	Token varchar (5000) NOT NULL,
	IssuedDate datetime NULL,	
	ExpireDate datetime NULL,
	PRIMARY KEY (ID)	
);

-- tbl_UserList
DROP TABLE IF EXISTS tbl_UserList;

CREATE TABLE tbl_UserList 
( 
	ID int NOT NULL AUTO_INCREMENT,
	UserID int NOT NULL,
    Name varchar (100) NOT NULL,
	DefaultListID int NULL,
	AccountTypeID int NULL,	
    SortOrder int NULL,
    Active bit NOT NULL,
	Deleted bit NOT NULL,
	CreatedDate datetime NOT NULL,	
	ModifiedDate datetime NULL,		
    PRIMARY KEY (ID)      
);

-- tbl_UserList_Game
DROP TABLE IF EXISTS tbl_UserList_Game;

CREATE TABLE tbl_UserList_Game 
( 
	ID int NOT NULL AUTO_INCREMENT,
	UserListID int NOT NULL,
    GameID int NOT NULL,
    PRIMARY KEY (ID)      
);

-- tbl_DefaultList
DROP TABLE IF EXISTS tbl_DefaultList;

CREATE TABLE tbl_DefaultList 
( 
	ID int NOT NULL,
    Name varchar (100) NOT NULL,
    PRIMARY KEY (ID)      
);

-- tbl_AccountType
DROP TABLE IF EXISTS tbl_AccountType;

CREATE TABLE tbl_AccountType 
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
    Name varchar (800) NOT NULL,
    ReleaseDate datetime NULL,
    GameCategoryID int NOT NULL,
    CoverImageUrl varchar (250) NULL,
    CoverImagePath varchar(250) NULL,
	CreatedDate datetime NOT NULL DEFAULT (UTC_TIMESTAMP),
	ModifiedDate datetime NULL,    
    PRIMARY KEY (ID)      
);
CREATE INDEX IDX_tbl_Game_ReleaseDate ON tbl_Game (ReleaseDate);

-- tbl_Game_IGDBID
DROP TABLE IF EXISTS tbl_Game_IGDBID;

CREATE TABLE tbl_Game_IGDBID
( 
	GameID int NOT NULL,
	IGDBID int NOT NULL,
    PRIMARY KEY (GameID)   	
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
	ue.IsDarkTheme
    FROM tbl_User ua
	LEFT JOIN tbl_User_Setting ue ON ue.UserID = ua.ID
	WHERE ua.Deleted = 0;

-- vw_UserList
DROP VIEW IF EXISTS vw_UserList;

CREATE DEFINER=`root`@`localhost` VIEW vw_UserList AS

    SELECT ul.ID,
	ul.UserID,
	ul.Name,
	ul.DefaultListID,
	COALESCE(GameIDs.Value, '') AS GameIDs
    FROM tbl_UserList ul
 	LEFT JOIN LATERAL (
		SELECT GROUP_CONCAT(CONVERT(gl.GameID,CHAR) ORDER BY gl.ID SEPARATOR ',') Value
	    FROM tbl_UserList_Game gl
		WHERE gl.UserListID = ul.ID
	) GameIDs ON TRUE;

-- vw_Game
DROP VIEW IF EXISTS vw_Game;

CREATE DEFINER=`root`@`localhost` VIEW vw_Game AS

    SELECT g.ID,
	g.Name,
	COALESCE(g.CoverImagePath, DefaultGameCoverImagePath.Value) AS CoverImagePath,
	g.ReleaseDate
    FROM tbl_Game g
 	LEFT JOIN LATERAL (
		SELECT ts.Str AS Value
	    FROM tbl_Setting ts
		WHERE ts.Name = 'DefaultGameCoverImagePath'
		LIMIT 1
	) DefaultGameCoverImagePath ON TRUE;

-- vw_UserListGame
DROP VIEW IF EXISTS vw_UserListGame;

CREATE DEFINER=`root`@`localhost` VIEW vw_UserListGame AS

    SELECT DISTINCT g.ID,
	g.Name,
	COALESCE(g.CoverImagePath, DefaultGameCoverImagePath.Value) AS CoverImagePath,
	UserListIDs.Value AS UserListIDs,
	ug.ID AS UserListGameID,
	ul.ID AS UserListID,
	ul.Active AS UserListActive
    FROM tbl_Game g
    JOIN tbl_UserList_Game ug ON ug.GameID = g.ID
    JOIN tbl_UserList ul ON ul.ID = ug.UserListID
 	LEFT JOIN LATERAL (
		SELECT ts.Str AS Value
	    FROM tbl_Setting ts
		WHERE ts.Name = 'DefaultGameCoverImagePath'
		LIMIT 1
	) DefaultGameCoverImagePath ON TRUE
 	LEFT JOIN LATERAL (
		SELECT GROUP_CONCAT( DISTINCT CONVERT(gl1.UserListID,CHAR) ORDER BY gl1.UserListID SEPARATOR ',') Value
	    FROM tbl_UserList_Game gl1
	    JOIN tbl_UserList ul1 ON ul1.ID = gl1.UserListID AND ul1.UserID = ul.UserID
		WHERE gl1.GameID = g.ID		
	) UserListIDs ON TRUE;

-- vw_UserAccount
DROP VIEW IF EXISTS vw_UserAccount;

CREATE DEFINER=`root`@`localhost` VIEW vw_UserAccount AS

    SELECT ua.ID,
    ua.UserID,
    gt.ID AS AccountTypeID,
    gt.Name AS AccountTypeName,       
    ua.AccountUserID,
    ua.AccountUserHash,
	AccessToken.Token,
	AccessToken.ExpireDate,
	RefreshToken.Value AS RefreshToken,
	ua.ImportLastRunDate,
	ua.CreatedDate,
	ua.ModifiedDate
    FROM tbl_UserAccount ua
    JOIN tbl_AccountType gt ON gt.ID = ua.AccountTypeID
 	LEFT JOIN LATERAL (
		SELECT ut.Token, ut.ExpireDate
	    FROM tbl_UserAccount_Token ut
		WHERE ut.UserAccountID = ua.ID
		AND ut.TokenTypeID = 1
		LIMIT 1
	) AccessToken ON TRUE
 	LEFT JOIN LATERAL (
		SELECT ut.Token AS Value
	    FROM tbl_UserAccount_Token ut
		WHERE ut.UserAccountID = ua.ID
		AND ut.TokenTypeID = 2
		LIMIT 1
	) RefreshToken ON TRUE;

/*********************************************/
-- create/alter procs
/*********************************************/
-- GetUserListGames
DROP PROCEDURE IF EXISTS GetUserListGames;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE GetUserListGames
(
	IN UserListID INT
)
BEGIN	

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT ug.ID,
	ug.Name,
	ug.CoverImagePath,
	ug.UserListIDs,
	MIN(ug.UserListGameID) AS UserListGameID
    FROM vw_UserListGame ug
	WHERE (UserListID = 0 || ug.UserListID = UserListID)
	AND ug.UserListActive = 1
	GROUP BY ug.ID, ug.Name, ug.CoverImagePath, ug.UserListIDs;

END $$
DELIMITER ;

-- GetAbout
DROP PROCEDURE IF EXISTS GetAbout;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE GetAbout()
BEGIN	
	DECLARE UserCount INT;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT COUNT(DISTINCT tu.ID)
    FROM tbl_User tu
	WHERE tu.Active = 1
	INTO UserCount;

    SELECT UserCount, g.Name AS GameName, ul.Name AS UserListName
    FROM tbl_UserList_Game ug
    JOIN tbl_Game g ON g.ID = ug.GameID
    JOIN tbl_UserList ul ON ul.ID = ug.UserListID
	ORDER BY ug.ID DESC
	LIMIT 1;

END $$
DELIMITER ;

/*********************************************/
-- populate tables
/*********************************************/
INSERT INTO tbl_Setting (Name, Str, Num, Dte)
SELECT 'TwitchAcccessToken', NULL, NULL, NULL 
UNION ALL
SELECT 'TwitchAcccessTokenExpireDate', NULL, NULL, NULL 
UNION ALL
SELECT 'GameLastImportDate', NULL, NULL, NULL 
UNION ALL
SELECT 'ImportLastRunDate', NULL, NULL, NULL 
UNION ALL
SELECT 'DefaultGameCoverImagePath','/dist/images/nocover.jpg',NULL,NULL;

INSERT INTO tbl_DefaultList(ID, Name)
SELECT 1, 'Backlog'
UNION ALL
SELECT 2, 'Playing'
UNION ALL
SELECT 3, 'Completed';

INSERT INTO tbl_AccountType(ID, Name)
SELECT 1, 'Steam'
UNION ALL
SELECT 2, 'Xbox';


































