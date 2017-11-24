-- ===============================
-- 나의 쇼핑 정보 recompile 대상
-- ===============================

/*
 -- 사이트 복구시 나의 쇼핑정보 sp recompile 대상 !
*/


--/neo_my_gd/default.asp

exec sp_recompile [dbo.up_get_message_confirm]
go

exec sp_recompile [dbo.up_get_op_myshopping_contract_list_for_gmarket]
exec sp_recompile [dbo.up_get_op_myshopping_contract_list_new_detail1]
exec sp_recompile [dbo.up_get_op_myshopping_contract_list_new_detail2]
go
exec sp_recompile [dbo.up_neo_get_delivery_status_count_for_mygd_member]
go
exec sp_recompile [dbo.up_get_op_myshopping_claim_state_count]
go
exec sp_recompile [dbo.up_neo_get_auction_succ_bidding_cnt]
go
exec sp_recompile [dbo.up_sttl_get_balance_money]
exec sp_recompile [dbo.up_sttl_get_balance_money_mem]
exec sp_recompile [dbo.up_sttl_get_balance_money_nonmem]
go


--/neo_my_gd/order_contract_list.asp
exec sp_recompile [dbo.up_get_op_myshopping_contract_not_list]
exec sp_recompile [dbo.up_get_op_myshopping_contract_not_list_sub]
go

--/neo_my_gd/order_contract_edit_list.asp
exec sp_recompile [dbo.up_get_op_myshopping_claim_list_for_nonmember_gmarket]
exec sp_recompile [dbo.up_get_op_myshopping_claim_list_for_nonmember_new_datail2]
exec sp_recompile [dbo.up_get_op_myshopping_claim_list_for_nonmember_new_datail1]
go

exec sp_recompile [dbo.up_get_op_myshopping_claim_list]
exec sp_recompile [dbo.up_get_op_myshopping_claim_list_detail1]
exec sp_recompile [dbo.up_get_op_myshopping_claim_list_detail2]
go
exec sp_recompile [dbo.up_get_op_myshopping_claimCR_info]
go

--/neo_my_gd/order_deposit_list.asp
exec sp_recompile [dbo.up_get_op_myshopping_deposit_contract_list_for_my_gd1]
exec sp_recompile [dbo.up_get_op_myshopping_deposit_contract_list_page1_for_my_gd1]
exec sp_recompile [dbo.up_get_op_myshopping_deposit_contract_list_paging_for_my_gd1]
go
exec sp_recompile [dbo.up_get_op_myshopping_foreign_deposit_list]
exec sp_recompile [dbo.up_get_op_myshopping_foreign_deposit_list_page1]
exec sp_recompile [dbo.up_get_op_myshopping_foreign_deposit_list_paging]
go
exec sp_recompile [goodsdaq.up_check_personal_vaccount]
exec sp_recompile [dbo.up_check_personal_vaccount_custno]
exec sp_recompile [dbo.up_check_personal_vaccount_gbankno]
go

--/neo_my_gd/g_bank/G_bankBook.asp
exec sp_recompile [dbo.up_get_op_myshopping_personal_info]
go
exec sp_recompile [dbo.up_neo_get_custom_will_send_money_list_MEM]
go
exec sp_recompile [dbo.up_neo_get_custom_will_send_money_list_NON]
go
exec sp_recompile [dbo.up_neo_get_custom_sended_money_list_member_global]
go
exec sp_recompile [goodsdaq.up_neo_get_custom_sended_money_list]
exec sp_recompile [dbo.up_neo_get_custom_sended_money_list_member]
exec sp_recompile [dbo.up_neo_get_custom_sended_money_list_nonmember]
go

--/neo_my_gd/personal.asp
exec sp_recompile [dbo.up_get_op_myshopping_personal_info]
go
exec sp_recompile [goodsdaq.up_neo_get_sell_money_settlement_bank]
go
exec sp_recompile [goodsdaq.up_get_op_myshopping_mileage_info]
go
exec sp_recompile [goodsdaq.up_neo_get_auction_penalty_info]
go

--/neo_my_gd/webzine/pvw_list.asp
exec sp_recompile [dbo.up_neo_get_pvw_info]
go
exec sp_recompile [dbo.up_neo_get_pvw_list]
go
exec sp_recompile [dbo.up_neo_get_content_goods_pay_c2box_list]
exec sp_recompile [dbo.up_neo_get_content_goods_pay_c2box_list_page]
exec sp_recompile [dbo.up_neo_get_content_goods_pay_c2box_list_pages]
go

--/neo_my_gd/my_bbs_list.asp
exec sp_recompile [goodsdaq.up_get_op_myshopping_bbs_list]
exec sp_recompile [dbo.up_get_op_myshopping_bbs_list_nonmember]
exec sp_recompile [dbo.up_get_op_myshopping_bbs_list_nonmember_page]
exec sp_recompile [dbo.up_get_op_myshopping_bbs_list_nonmember_pages]
exec sp_recompile [dbo.up_get_op_myshopping_bbs_list_member]
exec sp_recompile [dbo.up_get_op_myshopping_bbs_list_member_page]
exec sp_recompile [dbo.up_get_op_myshopping_bbs_list_member_pages]
go

--/neo_search/search_myshopping.asp
exec sp_recompile [dbo.up_neo_get_interest_goods_cnt]
go
exec sp_recompile [dbo.up_SendInterest_GetNewInterestExist]
go
exec sp_recompile [dbo.up_neo_get_interest_goods_list]
go
exec sp_recompile [dbo.up_my_interest_goods_group_list]
go

--/neo_my_gd/default_nonmember.asp
exec sp_recompile [dbo.up_get_op_myshopping_contract_list_for_nonmember_gmarket]
exec sp_recompile [dbo.up_get_op_myshopping_contract_list_for_nonmember_new_datail2]
exec sp_recompile [dbo.up_get_op_myshopping_contract_list_for_nonmember_new_datail1]
go
--/neo_my_gd/order_contract_list_nonmember.asp
exec sp_recompile [dbo.up_get_op_myshopping_contract_not_list_for_nonmember]
go




