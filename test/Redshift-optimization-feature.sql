/* Groundwork : Enable resultset caching function */
set enable_result_cache_for_session to true;

-- 1. Accelerate by Resultset caching
-- 1a. Execute query first time. It takes around 4 seconds.
SELECT c_mktsegment, o_orderpriority, sum(o_totalprice)
FROM customer c
JOIN orders o on c_custkey = o_custkey
GROUP BY c_mktsegment, o_orderpriority;

-- 1b. Execute the same query again. It take less than 10ms. Result dataset and compiled plan is cached, giving the results.
 SELECT c_mktsegment, o_orderpriority, sum(o_totalprice)
FROM customer c
JOIN orders o on c_custkey = o_custkey
GROUP BY c_mktsegment, o_orderpriority;


-- 2. Accelerate by compiled plan reusing
-- 2a. Update the table
UPDATE customer
SET c_mktsegment = c_mktsegment
WHERE c_mktsegment = 'MACHINERY';

VACUUM DELETE ONLY customer;

-- 2b. Run the same query again. Execution time is between 1a and 1b. Compiled plan is cached while Resultset is not cached.
SELECT c_mktsegment, o_orderpriority, sum(o_totalprice)
FROM customer c
JOIN orders o on c_custkey = o_custkey
GROUP BY c_mktsegment, o_orderpriority;


-- 3. Compression
-- 3a. Observe table `lineitem`. Column is compressed by pre-defined compression encoding. 
SELECT tablename, "column", encoding
FROM pg_table_def
WHERE schemaname = 'public' AND tablename = 'lineitem';

-- 3b. Observe table `lineitem_v1`. Column is created in original encoding format without compression. 
SELECT tablename, "column", encoding
FROM pg_table_def
WHERE schemaname = 'public' AND tablename = 'lineitem_v1'

--3c. Execute Redshift' ANALYZE COMPRESSION command to determine the encoding for each column which will yield the most compression. 
ANALYZE lineitem_v1;
ANALYZE COMPRESSION lineitem_v1;

-- 3d. Check the data volume with and without compression. The compression is ~3 times. 
SELECT
  CAST(d.attname AS CHAR(50)),
  SUM(CASE WHEN CAST(d.relname AS CHAR(50)) = 'lineitem'
THEN b.size_in_mb ELSE 0 END) AS size_in_mb,
  SUM(CASE WHEN CAST(d.relname AS CHAR(50)) = 'lineitem_v1'
THEN b.size_in_mb ELSE 0 END) AS size_in_mb_v1,
  SUM(SUM(CASE WHEN CAST(d.relname AS CHAR(50)) = 'lineitem'
THEN b.size_in_mb ELSE 0 END)) OVER () AS total_mb,
  SUM(SUM(CASE WHEN CAST(d.relname AS CHAR(50)) = 'lineitem_v1'
THEN b.size_in_mb ELSE 0 END)) OVER () AS total_mb_v1
FROM (
  SELECT relname, attname, attnum - 1 as colid
  FROM pg_class t
  INNER JOIN pg_attribute a ON a.attrelid = t.oid
  WHERE t.relname LIKE 'lineitem%') d
INNER JOIN (
  SELECT name, col, MAX(blocknum) AS size_in_mb
  FROM stv_blocklist b
  INNER JOIN stv_tbl_perm p ON b.tbl=p.id
  GROUP BY name, col) b
ON d.relname = b.name AND d.colid = b.col
GROUP BY d.attname
ORDER BY d.attname;



-- 4. Redshift also has EXPLAIN PLAN function.
EXPLAIN
SELECT c_mktsegment,COUNT(o_orderkey) AS orders_count, sum(l_quantity) as quantity, sum (l_extendedprice) as extendedprice
FROM lineitem
JOIN orders on l_orderkey = o_orderkey
JOIN customer c on o_custkey = c_custkey
WHERE l_commitdate between '1992-01-01T00:00:00Z' and '1992-12-31T00:00:00Z'
GROUP BY c_mktsegment;