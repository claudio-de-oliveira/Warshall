USE Warshall

DELETE FROM Relation
DELETE FROM Items
DELETE Through
DELETE Forest

EXEC AddPair 'a', 'b'
EXEC AddPair 'c', 'd'
EXEC AddPair 'd', 'e'
EXEC AddPair 'e', 'e'

SELECT * FROM GetEquivalents('a')

EXEC AddPair 'a', 'c'

SELECT * FROM GetEquivalents('a')

EXEC RemovePair 'a', 'c'

SELECT * FROM GetEquivalents('a')

