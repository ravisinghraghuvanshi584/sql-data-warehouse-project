/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    The purpose script is to create views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

create view gold.dim_customers as  
  select  
     ROW_NUMBER() over(order by cst_id) as customer_key,  
     cst_id as customer_id,  
     cst_key as customer_number,  
     cst_firstname as first_name,  
     cst_lastname as last_name,  
     cst_marital_status as marital_status,  
     cst_gndr as gender,  
     cntry as country,  
     bdate as birth_date,  
     cst_create_date as create_date  
  from(  
    select   
       ci.cst_id,  
       ci.cst_key,  
       ci.cst_firstname,  
       ci.cst_lastname,  
       ca.bdate,  
       ci.cst_marital_status,  
       case   
        when ci.cst_gndr='n/a' then coalesce(ca.gen,'n/a')  
        else ci.cst_gndr  
       end as cst_gndr,  
       lo.cntry,  
       ci.cst_create_date,  
       row_number() over(partition by ci.cst_key order by cst_create_date) as flag  
     from silver.crm_cust_info as ci  
     left join silver.erp_cust_az12 as ca  
     on ci.cst_key=ca.cid  
     left join silver.erp_loc_a101 as lo  
     on ci.cst_key=lo.cid  
   )t  
   where flag=1  


-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
  
create view gold.dim_products as
  select 
    	row_number() over(order by p.prd_start_dt,p.prd_key) as product_key,
    	p.prd_id as product_id,
    	p.prd_key as product_number,
    	p.prd_nm as product_name,
    	p.cat_id as category_id,
    	cat.cat as category,
    	case
    		when cat.subcat is null then 'n/a'
    		else cat.subcat
    	end as subcategory,
    	case 
    		when cat.maintenance is null then 'n/a'
    		else cat.maintenance
    	end as maintenance,
    	p.prd_cost as cost,
    	p.prd_line as product_line,
    	p.prd_start_dt as product_start_date
  from silver.crm_prd_info as p
  left join silver.erp_px_cat_g1v2 as cat
  on p.cat_id=cat.id
  where p.prd_end_dt is null


-- =============================================================================
-- Create fact: gold.fact_sales
-- =============================================================================
  
create view gold.fact_sales as
  select 
    	sd.sls_ord_num as order_number,
    	pd.product_key,
    	cu.customer_key,
    	sd.sls_order_dt as order_date,
    	sd.sls_ship_dt shipping_date,
    	sd.sls_due_dt as due_date,
    	sd.sls_sales as sales_amount,
    	sd.sls_quantity as quantity,
    	sd.sls_price as price
  from silver.crm_sales_details as sd
  left join gold.dim_customers as cu
  on sd.sls_cust_id=cu.customer_id
  left join gold.dim_products as pd
  on sd.sls_prd_key= pd.product_number



