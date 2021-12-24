Before we start recommending things, we need to find out what is interesting in our data to see what kinds of things we can and want to recommend. 

Find a single actor like Tom Hanks.

MATCH (tom:Person {name: 'Tom Hanks'})
RETURN tom

Retrieve all his movies by starting from the Tom Hanks node and following the ACTED_IN relationships. 

MATCH (tom:Person {name: 'Tom Hanks'})-[r:ACTED_IN]->(movie:Movie)
RETURN tom, r, movie

Tom has colleagues who acted with him in his movies. Find Tom’s co-actors.

MATCH (tom:Person {name: 'Tom Hanks'})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(coActor:Person)
RETURN coActor.name


To find the "co-co-actors", i.e. the second-degree actors in Tom’s network. 

Show all the actors Tom Hanks may not have worked with yet (specify a criteria to be sure he hasn’t directly acted with the person)
 
MATCH (tom:Person {name: 'Tom Hanks'})-[:ACTED_IN]->(movie1:Movie)<-[:ACTED_IN]-(coActor:Person)-[:ACTED_IN]->(movie2:Movie)<-[:ACTED_IN]-(coCoActor:Person)
WHERE tom <> coCoActor
AND NOT (tom)-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(coCoActor)
RETURN coCoActor.name

NOTE: There are a few names appear multiple times. This is because there are multiple paths to follow from Tom Hanks to these actors.

One of those “co-co-actors” is Tom Cruise. Find out which movies and actors are between the two Toms to find out who can introduce them.

Find out which co-co-actors appear most often in Tom’s network. (Take frequency of occurrences by counting the number of paths between Tom Hanks and each coCoActor and ordering them by highest to lowest value.

MATCH (tom:Person {name: 'Tom Hanks'})-[:ACTED_IN]->(movie1:Movie)<-[:ACTED_IN]-(coActor:Person)-[:ACTED_IN]->(movie2:Movie)<-[:ACTED_IN]-(coCoActor:Person)
WHERE tom <> coCoActor
AND NOT (tom)-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(coCoActor)
RETURN coCoActor.name, count(coCoActor) as frequency
ORDER BY frequency DESC
LIMIT 5

Find a single actor like Tom Hanks.

MATCH (tom:Person {name: 'Tom Hanks'})-[:ACTED_IN]->(movie1:Movie)<-[:ACTED_IN]-(coActor:Person)-[:ACTED_IN]->(movie2:Movie)<-[:ACTED_IN]-(cruise:Person {name: 'Tom Cruise'})
WHERE NOT (tom)-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(cruise)
RETURN tom, movie1, coActor, movie2, cruise

The graph displays how many hops exist between people. We create two recommendation algorithms:
Who to meet/work with next
How to meet them
