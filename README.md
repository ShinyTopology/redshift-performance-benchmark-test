# redshift-performance-benchmark-test
PoC that demonstrates the performance of Redshift using TPC-DS 2.13 3TB Benchmark data, and a few other table optimization and performance tuning functions.

## PoC Content
In this PoC, below three things in Redshift is demonstrated
1. **Performance**: Querying TPC-DS 2.13 3TB dataset.
2. **Optimization**: Some table optimization and tunning features (e.g. Caching, EXPLAIN PLAN, ...)
3. **Security**: Column-level permission control.

## Pre-requisites
1. An AWS account
2. A Redshift cluster (RA3.4xlarge x 2 was used)
3. Download testing dataset to Redshift cluster. (Execute ddl_TPC_DS_213_3TB.sql)
4. Create admin view [v_get_obj_priv_by_user.sql](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminViews/v_get_obj_priv_by_user.sql)
5. Create admin view [v_space_used_per_tbl.sql](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminViews/v_space_used_per_tbl.sql)

## Steps
1. Run Redshift performance test in `test/TPC-DS-performance test.sql`
2. Run optimization feature in `test/Redshift-optimization-feature.sql`
3. Run column-level permission control test in `Redshift-column-level-permission-control.sql`

