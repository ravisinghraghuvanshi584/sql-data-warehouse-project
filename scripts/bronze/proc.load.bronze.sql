/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    The purpose of this stored procedure is to load data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

CREATE or alter procedure bronze.load_bronze as
begin
declare @start_time date,@end_time date,@batch_start date,@batch_end date;
	begin try
		set @batch_start =getdate();
		print '===================================';
		print'loading bronze layer';
		print '====================================';

		print'--------------------------------------';
		print 'loading CRM tables';
		print '-------------------------------------';

		set @start_time=getdate();
		print '>>> truncating table bronze.crm_cust_info';
		truncate table bronze.crm_cust_info;

		print '>>> inserting data into:table bronze.crm_cust_info';
		bulk insert bronze.crm_cust_info
			from 'D:\f78e076e5b83435d84c6b6af75d8a679\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
			with (
					firstrow = 2,
					fieldterminator =',',
					tablock
				);
			set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
			print'                                         ';

		set @start_time=getdate();
		print '>>> truncating table bronze.crm_prd_info';
		truncate table bronze.crm_prd_info;

		print '>>> inserting data into:table bronze.crm_prd_info';
		bulk insert bronze.crm_prd_info
			from 'D:\f78e076e5b83435d84c6b6af75d8a679\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
			with (
					firstrow = 2,
					fieldterminator =',',
					tablock
				);
		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';
		
		set @start_time=getdate();
		print '>>> truncating table bronze.crm_sales_details';
		truncate table bronze.crm_sales_details;

		print '>>> inserting data into:table bronze.crm_sales_details';
		bulk insert bronze.crm_sales_details
			from 'D:\f78e076e5b83435d84c6b6af75d8a679\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
			with (
					firstrow = 2,
					fieldterminator =',',
					tablock
				);
		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';

			print'--------------------------------------';
			print 'loading ERP tables';
			print '-------------------------------------';

		set @start_time=getdate();
		print '>>> truncating table bronze.erp_cust_az12';
		truncate table bronze.erp_cust_az12;

		print '>>> inserting data into:table bronze.erp_cust_az12';
		bulk insert bronze.erp_cust_az12
			from 'D:\f78e076e5b83435d84c6b6af75d8a679\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
			with (
					firstrow = 2,
					fieldterminator =',',
					tablock
				);
		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';

		set @start_time=getdate();
		print '>>> truncating table bronze.erp_loc_a101';
		truncate table bronze.erp_loc_a101;

		print '>>> inserting data into:table bronze.erp_loc_a101';
		bulk insert bronze.erp_loc_a101
			from 'D:\f78e076e5b83435d84c6b6af75d8a679\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
			with (
					firstrow = 2,
					fieldterminator =',',
					tablock
				);
		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';
		
		set @start_time=getdate();
		print '>>> truncating table bronze.erp_px_cat_g1v2';
		truncate table bronze.erp_px_cat_g1v2;

		print '>>> inserting data into:table bronze.erp_px_cat_g1v2';
		bulk insert bronze.erp_px_cat_g1v2
			from 'D:\f78e076e5b83435d84c6b6af75d8a679\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
			with (
					firstrow = 2,
					fieldterminator =',',
					tablock
				);
		set @end_time = getdate();
			print'>>> load duration: ' + cast(datediff(second,@start_time,@end_time) as nvarchar)+'seconds';
				print'                                         ';

			set @batch_end =getdate();
			print'------------------------------------------------------'
			print' loading bronze layer is completed';
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
