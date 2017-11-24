/*----------------------------------------------------
    Date    : 2007-10-12
    Note    : 로그 쉬핑 복원 내역 조회
    No.     :
*----------------------------------------------------*/
    


use dba
go

SELECT user_db_name, seq_no, log_file, copy_flag,copy_end_time,
		restore_flag, restore_start_time, restore_end_time,restore_duration
FROM logshipping_restore_list  WITH (NOLOCK)
WHERE reg_dt > CONVERT(NVARCHAR(10), GETDATE(), 120) AND user_db_name = 'TIGER'
