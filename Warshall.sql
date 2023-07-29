/* TRANSITIVE CLOSURE OF UNDIRECTED GRAPHS */
-----------------------------------------------------
/* Based on Maintaining Transitive Closure of Graphs in SQL of */
/* Guozhu Dong, Leonid Libkiny, Jianwen Suz and Limsoon Wongx */
/* https://www.researchgate.net/publication/2245599_Maintaining_Transitive_Closure_of_Graphs_in_SQL */

USE [master]
GO

CREATE DATABASE [Warshall]
GO

USE [Warshall]
GO

CREATE TYPE [dbo].[TItem] 
	FROM VARCHAR(10) /* Item type can be changed here */
GO

/* The Simetric Relation */
CREATE TABLE [dbo].[Relation](
	[Start] TItem NOT NULL,
	[End] TItem NOT NULL,
 CONSTRAINT [PK_Relation] PRIMARY KEY CLUSTERED 
 (
	[Start] ASC,
	[End] ASC
 ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* The Items Table */
CREATE TABLE [dbo].[Items](
	[Node] TItem NOT NULL,
 CONSTRAINT [PK_Nodes] PRIMARY KEY CLUSTERED 
 (
	[Node] ASC
 ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/*
CREATE TABLE [dbo].[LessThan](
	[Small] TItem NOT NULL,
	[Large] TItem NOT NULL
) ON [PRIMARY]
GO
*/

/* The item type is ordered */
CREATE TABLE [dbo].[Forest](
	[A] TItem NOT NULL,
	[B] TItem NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Through](
	[A] TItem NOT NULL,
	[V] TItem NOT NULL,
	[B] TItem NOT NULL,
 CONSTRAINT [PK_Through] PRIMARY KEY CLUSTERED 
 (
	[A] ASC,
	[V] ASC,
	[B] ASC
 ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Procedimentos ******/

USE [Warshall]
GO

CREATE PROCEDURE [dbo].[Expand](@X TItem) AS
	BEGIN
		IF NOT EXISTS(SELECT * FROM Items WHERE Node=@X)
		BEGIN
			/*
			INSERT INTO LessThan (Small, Large)
				SELECT Small=Node, Large=@X
				FROM Items
				WHERE @X NOT IN (SELECT * FROM Items)
			*/
			INSERT INTO Items (Node) VALUES(@X);
		END
	END;
GO

CREATE PROCEDURE [dbo].[Initial](@X TItem, @Y TItem) AS
	BEGIN
		IF NOT EXISTS(SELECT * FROM Items WHERE Node=@X) AND NOT EXISTS(SELECT * FROM Items WHERE Node=@Y)
		BEGIN
			/*
			INSERT INTO LessThan (Small, Large)
				SELECT DISTINCT Small=@X, Large=@Y
				FROM Relation
				WHERE NOT EXISTS (SELECT * FROM LessThan)
			*/
			INSERT INTO Items (Node) VALUES(@X);
			INSERT INTO Items (Node) VALUES(@Y)
		END
	END;
GO

CREATE PROCEDURE [dbo].[Update_Forest](@A TItem, @B TItem) AS
	BEGIN
		INSERT INTO Forest 
			SELECT A=[Start], B=[End]
				FROM Relation
				WHERE NOT EXISTS (SELECT * FROM Through WHERE A=@A AND B=@B)
					AND ([Start]=@A AND [End]=@B OR [Start]=@B AND [End]=@A) 
	END;
GO

CREATE PROCEDURE [dbo].[Update_Through](@A TItem, @B TItem) AS 
	BEGIN
		BEGIN TRY
			SELECT * INTO #T_STAR
				FROM (SELECT A=N.Node, V=N.Node, B=N.Node
					FROM Items N
				UNION
					SELECT * FROM Through) T;

			INSERT INTO Through
				SELECT A=T1.A, V=N.Node, B=T2.B
					FROM Items AS N, #T_STAR AS T1, #T_STAR AS T2
					WHERE T1.B=@A AND T2.A=@B AND N.Node=T1.V
				UNION
				SELECT A=T1.A, V=N.Node, B=T2.B
					FROM Items AS N, #T_STAR AS T1, #T_STAR AS T2
					WHERE T1.B=@B AND T2.A=@A AND N.Node=T1.V
				UNION
				SELECT A=T1.A, V=N.Node, B=T2.B
					FROM Items AS N, #T_STAR AS T1, #T_STAR AS T2
					WHERE T1.B=@A AND T2.A=@B AND N.Node=T2.V
				UNION
				SELECT A=T1.A, V=N.Node, B=T2.B
					FROM Items AS N, #T_STAR AS T1, #T_STAR AS T2
					WHERE T1.B=@B AND T2.A=@A AND N.Node=T2.V
			END TRY

			BEGIN CATCH
			END CATCH
	END;
GO

CREATE PROCEDURE [dbo].[AddPair](@Start AS TItem, @End AS TItem) AS
	BEGIN
		IF NOT EXISTS(SELECT * FROM Relation WHERE [Start]=@Start AND [End]=@End OR [Start]=@End AND [End]=@Start)
		BEGIN
			INSERT INTO Relation ([Start], [End]) VALUES (@Start, @End);

			/* Items may have been previously entered elsewhere */
			IF (SELECT COUNT(*) FROM Items)=0 
				EXEC Initial @Start, @End
			ELSE
			BEGIN
				EXEC Expand @Start
				EXEC Expand @End
			END

			EXEC Update_Forest @Start, @End
			EXEC Update_Through @Start, @End
		END
	END;
GO

CREATE PROCEDURE [dbo].[RemovePair](@A TItem, @B TItem) AS
	BEGIN
		DELETE FROM Relation WHERE ([Start]=@A AND [End]=@B)
		DELETE FROM Relation WHERE ([Start]=@B AND [End]=@A)

		SELECT * INTO #Rep_All FROM Relation
			WHERE EXISTS (SELECT * FROM Forest  WHERE A=@A AND B=@B);

		/*
		SELECT DISTINCT [Start], [End] INTO #Rep
			FROM #Rep_All AS R, LessThan AS LT
			WHERE NOT EXISTS (SELECT *
				FROM #Rep_All AS R1, LessThan AS LT1
				WHERE R1.[Start]=LT1.Small AND R.[Start]=LT1.Large
					OR (R1.[Start]=R.[Start] AND R1.[End]=LT1.Small AND R.[End]=LT1.Large))
			AND LT.Small=[Start] AND LT.Large=[End]
		*/

		SELECT DISTINCT [Start], [End] INTO #Rep
			FROM #Rep_All AS R
			WHERE NOT EXISTS (SELECT *
				FROM #Rep_All AS R1
				WHERE R1.[Start] < R.[Start]
					OR (R1.[Start]=R.[Start] AND R1.[End] < R.[End]))
			AND [Start] < [End]

		SELECT * INTO #DELTA
			FROM (
				SELECT T.*
					FROM Through AS T, Through AS T1, Through AS T2
					WHERE T1.V = @A AND T1.B = @B AND T2.A = @A AND T2.V = @B
						AND T1.A = T.A AND T2.B = T.B
						AND EXISTS (SELECT * FROM Forest WHERE A = @A AND B = @B)
				UNION
				SELECT T.*
					FROM Through AS T, Through AS T1, Through AS T2
					WHERE T1.V = @A AND T1.B = @B AND T2.A = @A AND T2.V = @B
						AND T1.A = T.B AND T2.B = T.A
						AND EXISTS (SELECT * FROM Forest WHERE A = @A AND B = @B)
			) T

		DELETE FROM Through
			WHERE EXISTS(SELECT * FROM #DELTA WHERE A=Through.A AND V=Through.V AND B= Through.B)

		DECLARE @C TItem
		DECLARE @D TItem

		SET @C = (SELECT TOP (1) [Start] FROM #Rep)
		SET @D = (SELECT TOP (1) [End] FROM #Rep)

		EXEC Update_Forest @C, @D
		EXEC Update_Through @C, @D

		DELETE FROM Forest
			WHERE A=@A AND B=@B OR A=@B AND B=@A
	END;
GO

/****** Funções ******/

USE [Warshall]
GO

CREATE FUNCTION [dbo].[Closure]() 
RETURNS TABLE
AS
	RETURN SELECT [Start], [End] 
		FROM (SELECT DISTINCT [Start]=A, [End]=B FROM Through) T;
GO

CREATE FUNCTION [dbo].[GetEquivalents](@X AS TItem)
RETURNS TABLE
AS
	RETURN SELECT DISTINCT B FROM Through WHERE A=@X
		UNION 
		SELECT DISTINCT A FROM Through WHERE B=@X;
GO
