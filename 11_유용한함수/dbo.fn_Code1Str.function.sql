/****** ??:  UserDefinedFunction [dbo].[fn_Code1Str]    ???? ??: 06/21/2007 15:33:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Text                                                                                                                                                                                                                                                            
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
/*
	??? : 2004.04.16
	??? : ???
	??   : ??? ??? ??
	?? :  2004-12-01 RJW  ???? ?? T8 ??
@flag
GetTradWayName    T1:G-Mall T2:?? T3: ??? T4:???? T5:???? T6:???? T8: ????
GetOrderType	  IMM:???? BAR:???? DIS:???? PAK:???? 	
GetGoodsAuctionFlagName   E:?? ????:??
TP_STAT_Code2VALUE
GetSQMStat
Acnt_Way_Code2Value A2: ?? A3:?? A7: ??? ??
Get_custSELLER_TYPE_Flag E:??? V:??
GetCustHOW_FEE_NEW_Flag
sell_GetOrderType
*/
CREATE function dbo.fn_Code1Str(@flag varchar(100), @code varchar(10)) returns varchar(100)
as
begin 

declare @ret_str varchar(100)
set @ret_str=''

-- GetTradWayName
	IF UPPER(@flag)=UPPER('GetTradWayName')
	begin
		select @ret_str=( case  @code when 'T1' then 'G-Mall'
				    when 'T2' then '??'
				    when 'T3' then '???'
				    when 'T4' then '????'
				    when 'T5' then '????'
				    when 'T6' then '????'
				    when 'T8' then '????'			
				end )
	end
--GetOrderType
	else IF UPPER(@flag)=UPPER('GetOrderType'  )
	begin
		select @ret_str=( case  @code when 'IMM' then '????'
				    when 'BAR' then '????'
				    when 'DIS' then '????'
				    when 'PAK' then '????'	
				end )
	end
--GetGoodsAuctionFlagName
	else IF UPPER(@flag)=UPPER('GetGoodsAuctionFlagName'  )
	begin
		select @ret_str=( case  @code when 'E' then '??'
				    ELSE '??'
				end )
	end
--TP_STAT_Code2VALUE
	else IF UPPER(@flag)=UPPER('TP_STAT_Code2VALUE'  )
	begin
		select @ret_str=( case @code when 'D1' then '????' 
					when 'D2' then '????' 
					when 'D3' then '???' 
					when 'D4' then '????' 
					when 'D5' then '????'
					when 'D6' then '????' 
					when 'D8' then '??' 
					when 'D9' then '??'
					when 'DA' then '????' 
					when 'DB' then '????' 
					when 'DC' then '???' 
					when 'D4_B' then '????(???)'
					when 'D4_F' then '????(??)' 

				end )
	end
-- GetSQMStat
	else IF UPPER(@flag)=UPPER('GetSQMStat')
	begin
		select @ret_str=( case  @code when 'T' then '????'
				    when 'M' then '????'
				    when 'F' then '????'	
				end )
	end
--TP_STAT_Code2VALUE_simple
	else IF UPPER(@flag)=UPPER('TP_STAT_Code2VALUE_simple'  )
	begin
		select @ret_str=( case @code when 'D1' then '????' 
					when 'D2' then '????' 
					when 'D3' then '???' 
					when 'D4' then '????' 
					else '????'

				end )
	end
--Acnt_Way_Code2Value
	else IF UPPER(@flag)=UPPER('Acnt_Way_Code2Value'  )
	begin
		select @ret_str=( case @code when 'A2' then '??' 
					when 'A3' then '??' 
					when 'A7' then '?????' 
				end )
	end
--Get_custSELLER_TYPE_Flag
	else IF UPPER(@flag)=UPPER('Get_custSELLER_TYPE_Flag'  )
	begin
		select @ret_str=( case @code when 'E' then '???' 
					when 'V' then '??' 
				end )
	end
--GetCustHOW_FEE_NEW_Flag
	else IF UPPER(@flag)=UPPER('GetCustHOW_FEE_NEW_Flag'  )
	begin
		select @ret_str=( case @code when 'PP' then '???' 
					when 'AP' then 'G??' 
					when 'BP' then '???' 
				end )
	end
--sell_GetOrderType
	else IF UPPER(@flag)=UPPER('sell_GetOrderType'  )
	begin
		select @ret_str=( case @code when 'DIS' then '????' 
					else ''
				end )
	end
	return @ret_str
end








GO
