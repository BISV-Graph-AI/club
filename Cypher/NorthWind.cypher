MATCH (c:Customer)-[:PURCHASED]->(o:Order)-[:ORDERS]->(p:Product)
RETURN c.companyName, p.productName, COUNT(o) AS orders
ORDER by orders DESC
LIMIT 5


MATCH (c:Customer)-[:PURCHASED]->(o:Order)-[:ORDERS]->(p:Product)
<-[:ORDERS]-(o2:Order)-[:ORDERS]->(p2:Product)-[:PART_OF]->(:Category)<-[:PART_OF]-(p)
WHERE c.customerID = 'ANTON' AND 
NOT EXISTS ( (c)-[:PURCHASED]->(:Order)-[:ORDERS]->(p2) )
RETURN c.companyName, p.productName AS has_purchased, p2.productName AS has_also_purchased, COUNT(DISTINCT o2) AS occurrences
ORDER BY occurrences DESC
LIMIT 5


MATCH (c:Customer)-[:PURCHASED]->(o:Order)-[:ORDERS]->(p:Product)
WITH c, count(p) as total
MATCH (c)-[:PURCHASED]->(o:Order)-[:ORDERS]->(p:Product)
WITH c, total,p, count(o)*1.0 as orders
MERGE (c)-[rated:RATED]->(p)
ON CREATE SET rated.rating = orders/total
ON MATCH SET rated.rating = orders/total
WITH c.companyName as company, p.productName as product, 
orders, total, rated.rating as rating
ORDER BY rating DESC
RETURN company, product, orders, total, rating LIMIT 10



MATCH (me:Customer)-[r:RATED]->(p:Product)
WHERE me.customerID = 'ANTON'
RETURN p.productName, r.rating limit 10


// See Customer's Similar Ratings to Others
MATCH (c1:Customer {customerID:'ANTON'})-[r1:RATED]->(p:Product)<-[r2:RATED]-(c2:Customer)
RETURN c1.customerID, c2.customerID, p.productName, r1.rating, r2.rating,
CASE WHEN r1.rating-r2.rating < 0 THEN -(r1.rating-r2.rating) ELSE r1.rating-r2.rating END as difference
ORDER BY difference ASC
LIMIT 15


MATCH (c1:Customer)-[r1:RATED]->(p:Product)<-[r2:RATED]-(c2:Customer)
WITH
	SUM(r1.rating*r2.rating) as dot_product,
	SQRT( REDUCE(x=0.0, a IN COLLECT(r1.rating) | x + a^2) ) as r1_length,
	SQRT( REDUCE(y=0.0, b IN COLLECT(r2.rating) | y + b^2) ) as r2_length,
	c1,c2
MERGE (c1)-[s:SIMILARITY]-(c2)
SET s.similarity = dot_product / (r1_length * r2_length)


MATCH (me:Customer)-[r:SIMILARITY]->(them:Customer)
WHERE me.customerID='ANTON'
RETURN me.companyName, them.companyName, r.similarity
ORDER BY r.similarity DESC limit 10


WITH 1 AS neighbours
MATCH (me:Customer)-[:SIMILARITY]->(c:Customer)-[r:RATED]->(p:Product)
WHERE me.customerID = 'ANTON' and NOT EXISTS ( (me)-[:RATED|ORDERS*1..2]->(p:Product) )
WITH p, COLLECT(r.rating)[0..neighbours] AS ratings, COLLECT(c.companyName)[0..neighbours] AS customers
WITH p, customers, ( REDUCE(s=0,i in ratings | s+i) / COUNT(ratings)) AS recommendation
ORDER BY recommendation DESC
RETURN p.productName, customers, recommendation LIMIT 10



