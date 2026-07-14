/*
===============================================================================
Stored Procedure: Load silver Layer (bronze -> silver)
===============================================================================
Script Purpose:
    The purpose of this stored procedure is to load data into the 'silver' schema from bronze schema. 
    It performs the following actions:
    - Truncates the silver tables before loading data.
	- Inserts transformed and cleansed data from bronze into silver layer.
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/


create or alter procedure silver.load_silver as
begin
	declare @start_time date,@end_time date,@batch_start date,@batch_end date;
		begin try
			set @batch_start =getdate();
		print '===================================';
		print'loading silver layer';
		print '====================================';

		print'--------------------------------------';
		print 'loading CRM tables';
		print '-------------------------------------';

		set @start_time=getdate();
		print '>>> truncating table silver.crm_cust_info';
		truncate table silver.crm_cust_info;

		print '>>> inserting data into:table silver.crm_cust_info';

		insert into silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
		)
		select 
			cst_id,
			cst_key,
			trim(cst_firstname) as cst_firstname,
			trim(cst_lastname) as cst_lastname,
			case
			when upper(trim(cst_marital_status)) ='M' then 'Married'
			when upper(trim(cst_marital_status)) ='s' then 'Single'
			else 'n/a'
			end as cst_marital_status,
			case
			when upper(trim(cst_gndr)) ='M' then 'Male'
			when upper(trim(cst_gndr)) ='F' then 'Female'
			else 'n/a'
			end as cst_gndr,
			cst_create_date
			from(
				select *,
				ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) as name_flag
				from bronze.crm_cust_info
			)t
			where name_flag =1 and cst_id is  not null ;

			set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
			print'                                         ';

		set @start_time=getdate();
		print '>>> truncating table silver.crm_prd_info';
		truncate table silver.crm_prd_info;

		print '>>> inserting data into:table silver.crm_prd_info';

		insert into silver.crm_prd_info(
			prd_id ,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		select
			prd_id,
			replace(SUBSTRING(trim(prd_key),1,5),'-','_') as cat_id,
			substring(prd_key,7,len(prd_key)) as prd_key,
			prd_nm,
			isnull(prd_cost,0) as prd_cost,
			case upper(trim(prd_line))
				when 'M' then 'Mountain'
				when 'R' then 'Road'
				when 'S' then 'Other sales'
				when 'T' then 'Touring'
				else 'n/a'
				end As prd_line,
			prd_start_dt,
			  DATEADD(
					DAY, 
					-1,
					LEAD(prd_start_dt) OVER (
						PARTITION BY prd_key 
						ORDER BY prd_start_dt
					)) as prd_end_dt
		from  bronze.crm_prd_info;

		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';
		
		set @start_time=getdate();
		print '>>> truncating table silver.crm_sales_details';
		truncate table silver.crm_sales_details;

		print '>>> inserting data into:table silver.crm_sales_details';

		
		insert into silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		select 
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				case
					when sls_order_dt=0 or len(sls_order_dt)!=8 then null
					else cast(cast(sls_order_dt as varchar) as date)
					end as sls_order_dt,
				case
					when sls_ship_dt=0 or len(sls_ship_dt)!=8 then null
					else cast(cast(sls_ship_dt as varchar) as date)
					end as sls_ship_dt,
				case
					when sls_due_dt =0 or len(sls_due_dt)!=8 then null
					else cast(cast(sls_due_dt as varchar) as date)
					end as sls_due_dt,
				case 
							when sls_sales is null or sls_sales<=0 or sls_sales != sls_quantity*abs(sls_price) then sls_quantity*abs(sls_price)
							else sls_sales
							end as sls_sales,
				case when sls_quantity is null or sls_quantity<=0 then sls_sales/nullif(sls_price,0)
							else sls_quantity
							end as sls_quantity,
				case when sls_price is null or sls_price<=0 then sls_sales/nullif(sls_quantity,0)
							else sls_price
							end as sls_price
		from bronze.crm_sales_details;

		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';

			print'--------------------------------------';
			print 'loading ERP tables';
			print '-------------------------------------';

		set @start_time=getdate();
		print '>>> truncating table silver.erp_cust_az12';
		truncate table silver.erp_cust_az12;

		print '>>> inserting data into:table silver.erp_cust_az12';

		insert into silver.erp_cust_az12(
			cid,
			bdate,
			gen
			)

		select 
			case
				when cid like'NAS%' then substring(cid,4,len(cid))
				else cid
			end as cid,
			case
				when bdate>getdate() then null
				else bdate
			end as bdate,
			case 
			when upper(trim(gen)) in('M','MALE') then 'Male'
			when upper(trim(gen)) in('F','FEMALE') then 'Female'
			when upper(trim(gen)) is null then 'n/a'
			else 'n/a'
			end as gen
		from bronze.erp_cust_az12 ;

		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';

		set @start_time=getdate();
		print '>>> truncating table silver.erp_loc_a101';
		truncate table silver.erp_loc_a101;

		print '>>> inserting data into:table silver.erp_loc_a101';

		insert into silver.erp_loc_a101(
			cid,cntry
		)
		select 
			REPLACE(cid,'-','') as cid,
			case
				when trim(cntry) in('US','USA') THEN 'United States'
				when trim(cntry) ='DE' then'Germany'
				when trim(cntry) is null then'n/a'
				when trim(cntry)='' then 'n/a'
				else trim(cntry)
			end as cntry
		from bronze.erp_loc_a101;

		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';
		
		set @start_time=getdate();
		print '>>> truncating table silver.erp_px_cat_g1v2';
		truncate table silver.erp_px_cat_g1v2;

		print '>>> inserting data into:table silver.erp_px_cat_g1v2';

	   insert into silver.erp_px_cat_g1v2
		(
			id,
			cat,
			subcat,
			maintenance
		)
		select 
			id,
			cat,
			subcat,
			maintenance
		from bronze.erp_px_cat_g1v2


		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';

			set @batch_end =getdate();
			print'------------------------------------------------------'
			print' loading silver layer is completed';
			print'>>>total batch load duration: ' + cast(datediff(second,@batch_start,@batch_end) as nvarchar)+'seconds';
			print'----------------------------------------------------'

	 end try
	 begin catch
		print '================================================';
		print 'error occured during loading bronze layer';
		print 'error messge'+ error_message();
		print 'error number'+ cast(error_number() as nvarchar);
		print 'error state'+ cast(error_state() as nvarchar);
		print '================================================';
	end catch
end
