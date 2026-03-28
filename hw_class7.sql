with customer_satistics as (
	select
		ct.CustomerID,
		datediff("2022-09-01", max(str_to_date(ct.Purchase_Date, '%m/%d/%Y'))) as recency,
		round( count(distinct ct.Transaction) / (TIMESTAMPDIFF(month, str_to_date(cr.created_date, '%m/%d/%Y'), "2022-09-01") / 12),2) as frequency,
		round(sum(ct.GMV) / (TIMESTAMPDIFF(month, str_to_date(cr.created_date, '%m/%d/%Y'), "2022-09-01") / 12), 2) as monetary
	from customer_transaction ct 
	join customer_registered cr on cr.ID = ct.CustomerID 
	where ct.Purchase_Date  is not null
	group by ct.CustomerID 
),

number_RFM as (
	select
		cs.*,
		row_number() over (order by cs.recency desc) as rank_R,
		row_number() over (order by cs.frequency asc) as rank_F,
		row_number() over (order by cs.monetary asc) as rank_M
	from customer_satistics cs
),

customer_RFM as (
	select 
		CustomerID, recency, frequency, monetary,
		case 
			when min(n.recency) <= n.recency and n.recency < (
				select cs.recency from number_RFM cs where cs.rank_R = (select round(max(rank_R)*0.25,0) from number_RFM)
			) then 4
			when (
				select cs.recency from number_RFM cs where cs.rank_R = (select round(max(rank_R)*0.25,0) from number_RFM)
			) <= n.recency and n.recency < (
				select cs.recency from number_RFM cs where cs.rank_R = (select round(max(rank_R)*0.5,0) from number_RFM)
			) then 3
			when (
				select cs.recency from number_RFM cs where cs.rank_R = (select round(max(rank_R)*0.5,0) from number_RFM)
			) <= n.recency and n.recency < (
				select cs.recency from number_RFM cs where cs.rank_R = (select round(max(rank_R)*0.75,0) from number_RFM)
			) then 2 
			else 1
		end as "R",
		case 
			when min(n.frequency) <= n.frequency and n.frequency < (
				select cs.frequency from number_RFM cs where cs.rank_F = (select round(max(rank_F)*0.25,0) from number_RFM)
			) then 1
			when (
				select cs.frequency from number_RFM cs where cs.rank_F = (select round(max(rank_F)*0.25,0) from number_RFM)
			) <= n.frequency and n.frequency < (
				select cs.frequency from number_RFM cs where cs.rank_F = (select round(max(rank_F)*0.5,0) from number_RFM)
			) then 2
			when (
				select cs.frequency from number_RFM cs where cs.rank_F = (select round(max(rank_F)*0.5,0) from number_RFM)
			) <= n.frequency and n.frequency < (
				select cs.frequency from number_RFM cs where cs.rank_F = (select round(max(rank_F)*0.75,0) from number_RFM)
			) then 3
			else 4
		end as "F",
		case 
			when min(n.monetary) <= n.monetary and n.monetary < (
				select cs.monetary from number_RFM cs where cs.rank_M = (select round(max(rank_M)*0.25,0) from number_RFM)
			) then 1
			when (
				select cs.monetary from number_RFM cs where cs.rank_M = (select round(max(rank_M)*0.25,0) from number_RFM)
			) <= n.monetary and n.monetary < (
				select cs.monetary from number_RFM cs where cs.rank_M = (select round(max(rank_M)*0.5,0) from number_RFM)
			) then 2
			when (
				select cs.monetary from number_RFM cs where cs.rank_M = (select round(max(rank_M)*0.5,0) from number_RFM)
			) <= n.monetary and n.monetary < (
				select cs.monetary from number_RFM cs where cs.rank_M = (select round(max(rank_M)*0.75,0) from number_RFM)
			) then 3
			else 4
		end as "M"
	from number_RFM as n
	group by CustomerID
	order by recency desc, monetary asc
)
select 
	*, concat(R,F,M) as RFM 
from customer_RFM



















