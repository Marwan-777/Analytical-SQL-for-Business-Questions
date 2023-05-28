-- Q2)

with features as (                                                        -- Calculate the three features for each customer
    select  distinct customer_id ,count(distinct invoice ) over(partition by customer_id) frequency , 
                                            round(sum(quantity*price) over(partition by customer_id),2) Monetary ,
                                            round(maxdate - max(to_date(invoicedate, 'mm/dd/yyyy hh24:mi'))  over(partition by customer_id)) recency
                                           
    from tableretail, (select max(to_date(invoicedate, 'mm/dd/yyyy hh24:mi')) maxdate from tableretail)
    order by recency
),
addScore as (                                                                 -- Calculating the r score and fm score
    select f.* , ntile(5) over(order by recency desc) r_score,
                    ntile(5) over(order by (frequency + monetary)/2 ) fm_score
    from features f
),
segments as (                       -- Note that r_score = 2 and fm_score = 1 is missing from the given table
    select s.*,
        case 
        when (r_score = 5 and fm_score = 5) or
                (r_score = 5 and fm_score = 4) or
                (r_score = 4 and fm_score = 5) 
        then 'Champions'
        
        when (r_score = 5 and fm_score = 2) or
                (r_score = 4 and fm_score = 2) or
                (r_score = 3 and fm_score = 3) or
                (r_score = 4 and fm_score = 3)
        then 'Potential Loyalists'
        
        when (r_score = 5 and fm_score = 3) or
                (r_score = 4 and fm_score = 4) or
                (r_score = 3 and fm_score = 5) or
                (r_score = 3 and fm_score = 4)
        then 'Loyal Customers'
        
        when (r_score = 5 and fm_score = 1)
        then 'Recent Customers'
        
        when (r_score = 4 and fm_score = 1) or
                (r_score = 3 and fm_score = 1) 
        then 'Promising'
        
        when (r_score = 3 and fm_score = 2) or
                (r_score = 2 and fm_score = 3) or
                (r_score = 2 and fm_score = 2) 
        then 'Customers Needing Attention'
        
        when (r_score = 2 and fm_score = 5) or
                (r_score = 2 and fm_score = 4) or
                (r_score = 1 and fm_score = 3)
        then 'At Risk'
        
        when (r_score = 1 and fm_score = 5) or
                (r_score = 1 and fm_score = 4) 
        then 'Cant Lose Them'
        
        when (r_score = 1 and fm_score = 2) 
        then 'Hibernating'
        
        when (r_score = 1 and fm_score = 1) 
        then 'Lost'
       
        end as Cust_segment
    from addScore s
    
)
select * from segments




