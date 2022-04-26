-- Disable caching
set enable_result_cache_for_session to false;
set search_path = 'tpcds_3tb';


/* 
    Query 1. Compare inventory of consecutive month (TPC-DS query 39.tpl 0.5)
*/
--    Inventory 14.8GB, 103M records
select 
	schemaname, tablename, rowcount, megabytes 
from public.v_space_used_per_tbl 
where 
	schemaname = 'tpcds_3tb' and 
    tablename in ('inventory','item','warehouse','date_dim');

-- Run SQL of query 1
with /* TPC-DS query39.tpl 0.5 */ inv as
(select w_warehouse_name,w_warehouse_sk,i_item_sk,d_moy
       ,stdev,mean, case mean when 0 then null else stdev/mean end cov
 from(select w_warehouse_name,w_warehouse_sk,i_item_sk,d_moy
            ,stddev_samp(inv_quantity_on_hand) stdev,avg(inv_quantity_on_hand) mean
      from inventory
          ,item
          ,warehouse
          ,date_dim
      where inv_item_sk = i_item_sk
        and inv_warehouse_sk = w_warehouse_sk
        and inv_date_sk = d_date_sk
        and d_year =1998
      group by w_warehouse_name,w_warehouse_sk,i_item_sk,d_moy) foo
 where case mean when 0 then 0 else stdev/mean end > 1)
select inv1.w_warehouse_sk,inv1.i_item_sk,inv1.d_moy,inv1.mean, inv1.cov
        ,inv2.w_warehouse_sk,inv2.i_item_sk,inv2.d_moy,inv2.mean, inv2.cov
from inv inv1,inv inv2
where inv1.i_item_sk = inv2.i_item_sk
  and inv1.w_warehouse_sk =  inv2.w_warehouse_sk
  and inv1.d_moy=1
  and inv2.d_moy=1+1
order by inv1.w_warehouse_sk,inv1.i_item_sk,inv1.d_moy,inv1.mean,inv1.cov
        ,inv2.d_moy,inv2.mean, inv2.cov
;

/*
    # UNION 3 sales tables (TPC-DS query60.tpl 0.29)
*/
-- store_sales (545GB, 8.639B records)
-- catalog_sales (364GB, 4.32B records)
-- web_sales (184.9GB, 2.16B records)
select 
	schemaname, tablename, rowcount, megabytes 
from public.v_space_used_per_tbl 
where 
	schemaname = 'tpcds_3tb' and 
    tablename in ('store_sales','catalog_sales','web_sales')
;

-- Run SQL of query 2
with /* TPC-DS query60.tpl 0.29 */ ss as (
 select
          i_item_id,sum(ss_ext_sales_price) total_sales
 from
 	store_sales,
 	date_dim,
         customer_address,
         item
 where
         i_item_id in (select
  i_item_id
from
 item
where i_category in ('Music'))
 and     ss_item_sk              = i_item_sk
 and     ss_sold_date_sk         = d_date_sk
 and     d_year                  = 2001
 and     d_moy                   = 10
 and     ss_addr_sk              = ca_address_sk
 and     ca_gmt_offset           = -6 
 group by i_item_id),
 cs as (
 select
          i_item_id,sum(cs_ext_sales_price) total_sales
 from
 	catalog_sales,
 	date_dim,
         customer_address,
         item
 where
         i_item_id               in (select
  i_item_id
from
 item
where i_category in ('Music'))
 and     cs_item_sk              = i_item_sk
 and     cs_sold_date_sk         = d_date_sk
 and     d_year                  = 2001
 and     d_moy                   = 10
 and     cs_bill_addr_sk         = ca_address_sk
 and     ca_gmt_offset           = -6 
 group by i_item_id),
 ws as (
 select
          i_item_id,sum(ws_ext_sales_price) total_sales
 from
 	web_sales,
 	date_dim,
         customer_address,
         item
 where
         i_item_id               in (select
  i_item_id
from
 item
where i_category in ('Music'))
 and     ws_item_sk              = i_item_sk
 and     ws_sold_date_sk         = d_date_sk
 and     d_year                  = 2001
 and     d_moy                   = 10
 and     ws_bill_addr_sk         = ca_address_sk
 and     ca_gmt_offset           = -6
 group by i_item_id)
  select   
  i_item_id
,sum(total_sales) total_sales
 from  (select * from ss 
        union all
        select * from cs 
        union all
        select * from ws) tmp1
 group by i_item_id
 order by i_item_id
      ,total_sales
;


/* End of test. Reset session environment to original. */
set enable_result_cache_for_session to true;
reset search_path
;