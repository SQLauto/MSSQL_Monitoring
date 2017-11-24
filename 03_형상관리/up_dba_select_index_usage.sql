/*************************************************************************  
* 프로시저명  : dbo.up_dba_select_index_usage
* 작성정보    : 2011-04-07 by choi bo ra
* 관련페이지  : 
* 내용        : sys.dm_db_index_usage_stats 수집
* 수정정보    :
**************************************************************************/
CREATE PROCEDURE dbo.up_dba_select_index_usage 
    @server_id      int
AS
/* COMMON DECLARE */
SET NOCOUNT ON
SET FMTONLY OFF 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* USER DECLARE */
create table #tmp_index
(
	database_id  int 
,	object_id int 
,	index_id int 
,	index_name varchar(512)
)

/* BODY */


        select identity(int , 1, 1) as db_seq , database_id  
        into #tmp_database
        from sys.databases with(nolock) where state  = 0 and database_id >= 5  
            and name not like 'LiteSpeed%'
            and name not in ('dba', 'dbmon', 'dbadmin')
        
        declare @limit_seq int ,@start_seq int , @end_seq int , @process_size int
        
        set @process_size = 1
        
        -- === 수집 시작
        
        
        -- max값 얻기
        select @limit_seq= isnull(max(db_seq),0) from #tmp_database --with(nolock)
        
        set @start_seq = 1
        set @end_seq = @start_seq + @process_size
        
        
        if @limit_seq > 0 
        begin
            while (1=1)
            begin
    
            			
            			--print 'start' + convert(varchar(10) , @start_seq) + ',contr_no=' + convert(varchar(10) , @contr_no)
            		    declare @database_id int 
            
            			select @database_id = database_id 
            			from #tmp_database with(nolock)
            			where db_seq = @start_seq
            
            
            			declare @sql varchar(max)
            		
                	    set @sql = 'select ' + convert(varchar(10) , @database_id)   
                			+ ' as database_id , i.object_id , i.index_id , i.name  from ' + db_name(@database_id)  
                			+ '.sys.indexes  as i with(nolock)' + char(10)
                			+ 'inner join ' + db_name(@database_id)   + '.sys.tables as t with (nolock) ' + char(10)
                			+ ' on i.object_id = t.object_id ' + char(10)
                			+ ' where i.index_id > 0'
                		  		
            			
            			--print @sql
            			
            			-- DB 상태가 이상할때 제외
            			BEGIN TRY
            				insert into #tmp_index(database_id , object_id , index_id ,index_name)
            				exec(@sql)
        
            			END TRY
            			BEGIN CATCH
            				DECLARE @ErrorMessage NVARCHAR(4000);
        					DECLARE @ErrorSeverity INT;
        					DECLARE @ErrorState INT;
        
        					SELECT @ErrorMessage = ERROR_MESSAGE(),
        						   @ErrorSeverity = ERROR_SEVERITY(),
        						   @ErrorState = ERROR_STATE();
        
            				 RAISERROR (@ErrorMessage, -- Message text.
            				            @ErrorSeverity, -- Severity.
            				            @ErrorState )
                    
        
            				 CONTINUE;
            			
            			END CATCH;
            			
            			--select db_name(@database_id), @@ERROR
            
                       if @end_seq > @limit_seq break;
                       
                       set @start_seq = @end_seq
                       set @end_seq= @start_seq + @process_size
            end
        end
        
        
        select  @server_id as server_id
            , convert(datetime,convert(varchar(10), getdate(), 121)) reg_date
            ,a.database_id
            ,db_name(a.database_id) as database_name 
            ,a.object_id
            ,object_schema_name(a.object_id , a.database_id) as schema_name 
            ,object_name(a.object_id , a.database_id) as object_name 
            ,a.index_id
            ,convert(varchar(256),b.index_name) as index_name
            ,a.user_seeks
            ,a.user_scans
            ,a.user_lookups
            ,a.user_updates
            ,a.last_user_seek
            ,a.last_user_scan
            ,a.last_user_lookup
            ,a.last_user_update
            ,a.system_seeks
            ,a.system_scans
            ,a.system_lookups
            ,a.system_updates
            ,a.last_system_seek
            ,a.last_system_scan
            ,a.last_system_lookup
            ,a.last_system_update
        from sys.dm_db_index_usage_stats  a with(nolock)
            inner join #tmp_index  b with(nolock) 
            on a.database_id = b.database_id and a.object_id  = b.object_id and a.index_id = b.index_id 
        where a.database_id >= 5 and a.object_id >= 100
        order by a.database_id, a.object_id, a.index_id
        
        
        drop table #tmp_index
        drop table #tmp_database

RETURN