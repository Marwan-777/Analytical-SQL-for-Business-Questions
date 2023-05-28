-- Question 1)
-- Pareto analysis for different Percentages of customers and total sales

with ranked_customers as                            -- rank customers based on total sales
(
    select customer_id , Total_sales, percent_rank() over( order by Total_sales desc)*100 rank from 
        (
            select distinct customer_id, sum(price*quantity) over(partition by customer_id)  Total_sales from tableretail
        )
),
pct as (                                                    -- To get the rank as a rounded percentage (to the nearest tenth)
    select r.* , 
                case when rank = 0 then 10 
                else ceil( rank/10 )*10  end as  percentage from ranked_customers r 
),
totalSales as                                             -- Calculate the total sales for each percentage
(
     select percentage, sum(Total_sales) total_sales from pct
      group by percentage
),
pareto as (                                               -- Get the running total for total sales . ex: since top 30% is rank 10 + rank 20 + rank 30 
    select percentage "Top N% of Customers" , sum(total_sales) over(order by percentage rows unbounded preceding) "Sales of top N% of Customers"
    from totalsales
)                                                           -- Get the percentage of sales out of grand total 
select p.* ,100* "Sales of top N% of Customers"/(select sum(price*quantity) from tableretail) "Percentage of total sales"
    from pareto p
    
    
    -- *******************************************************************
    
    
-- Question 2)

-- Sales by each month, and the percentage of increase with respect to previous month and the median sales 

-- Note that the data is given from 1 dec 2010 till 9 dec 2011, meaning that dec-2011 is only ten days and not the whole month

select max( to_date(invoicedate, 'mm/dd/yyyy hh24:mi')) , min( to_date(invoicedate, 'mm/dd/yyyy hh24:mi')) from tableretail;

with monthsales as (
    select sum(price*quantity) sales , to_char( to_date(invoicedate, 'mm/dd/yyyy hh24:mi') , 'Mon-yyyy') months from tableretail
    group by to_char( to_date(invoicedate, 'mm/dd/yyyy hh24:mi'), 'Mon-yyyy') 
    order by to_date(months, 'Mon-yyyy') 
),
addlag as (
    select sales, months,  lag(sales, 1) over(order by to_date(months, 'Mon-yyyy')) prev_sales, median(sales) over() Average_sales
    from monthsales
),
addpct as (
    select months, sales , round(100*(sales - prev_sales)/prev_sales,2) "PCT Increase w.r.t. previous",
    round(100* (sales - average_sales)/average_sales,2) " PCT Increase w.r.t. Median"
    from addlag
    order by to_date(months, 'Mon-yyyy') 
)
select * from addpct

-- Notice that sales are increasing with respect to the median as the months pass



        -- *******************************************************************

-- Question 3)

-- Average number of stocks and average sales per invoice for each month

with invoiceInfo as (
    select  max(to_char( to_date(invoicedate, 'mm/dd/yyyy hh24:mi'), 'Mon-yyyy')) months , invoice , sum(quantity) "Stocks Count" ,
                sum(price*quantity) sales 
    from tableretail
    group by invoice
    order by to_date(months, 'Mon-yyyy') 
)
select months,  round(avg("Stocks Count")) "Avg Stocks Count per Invoice" , 
                      round(avg(sales),2) "Avg Sales per Invoice", count(invoice) "Invoice Count" ,
                      sum(sales) "Total Sales"
from invoiceInfo
group by months
order by to_date(months, 'Mon-yyyy') 


-- I also tried to find correlation between avg stocks per invoice with total sales  and invoice count with total sales 
-- But there were almost no difference in correlation coefficient and it makes sense actually
-- Thus I didn't add it as a question

        -- ************************************************************
        
        
-- Question 4)

-- Top Five stocks in sales for each month

with monthSales as (
    select to_char( to_date(invoicedate, 'mm/dd/yyyy hh24:mi'), 'Mon-yyyy') months , stockcode , price*quantity sales from tableretail
),
rankstocks as (
    select m.*, row_number() over(partition by months order by sales desc) rank
    from monthsales m
),
rankedstocks as (
    select months, rank, stockcode from rankstocks
    where rank < 6
    order by to_date(months, 'Mon-yyyy') , rank
)
select  months, 
            "1" as "First ",
            "2" as "Second ",
            "3" as "Third ",
            "4" as "Fourth ",
            "5" as "Fifth "
from
    (
    select * from rankedstocks
    )
pivot ( max(stockcode) for rank in (1,2,3,4,5) ) 
order by to_date(months, 'Mon-yyyy') 

      
        -- ************************************************************
        
        

-- Qeustion 5)

-- Average number of purchases and average sales per customer for each month

with customersinfo as (
select months, customer_id, sum(sales) sales , count(distinct invoice) invoice_count
from
(
    select to_char( to_date(invoicedate, 'mm/dd/yyyy hh24:mi'), 'Mon-yyyy') months, customer_id, price*quantity sales, invoice 
    from tableretail
)
group by months , customer_id
order by to_date(months, 'Mon-yyyy') 
)
select months , round(avg(sales) ,2)"Average sales per Customer" , round(avg(invoice_count)) "Avg Invoice Count per Cust." 
from customersinfo
group by months
order by to_date(months, 'Mon-yyyy') 

