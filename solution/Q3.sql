-- Q3)
   
-- Creating the table then import the comma separated file
create table purchasings(
    cust_id varchar(15),
    calender_dt varchar(15),
    amt_le float(10)
);
commit

-- I imported a portion of the file ( around 21K rows)  to save time

-- A)

WITH consecutiveOrNot AS (                                  -- This will add a one beside the consecutive transaction and zero otherwise
    SELECT cust_id, amt_le, calender_dt,
    CASE WHEN duration > 1 or duration IS NULL  THEN 0 ELSE 1  END AS consecutive
    FROM (
        -- To get number of days between the transaction and the preceding one 
        SELECT cust_id, amt_le , calender_dt, to_date(calender_dt, 'yyyy-mm-dd') - 
                                                           LAG(to_date(calender_dt, 'yyyy-mm-dd'), 1) OVER( PARTITION BY cust_id ORDER BY to_date(calender_dt, 'yyyy-mm-dd' ) ) duration  
        FROM purchasings
    )
),

addOrder AS (                                                       -- This will add an ordered sequence for each customer based on date order 
  SELECT calender_dt, cust_id, consecutive,
         ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY to_date(calender_dt, 'yyyy-mm-dd') ) num
  FROM consecutiveOrNot
),

addIntervals AS (                                                   -- Treat 'consecutive or not' as a state and get a start and end date for each one 
    SELECT cust_id, max(consecutive) con, MIN(to_date(calender_dt, 'yyyy-mm-dd') ) start_dt, MAX(to_date(calender_dt, 'yyyy-mm-dd') ) end_dt
        FROM (
          SELECT calender_dt, cust_id, consecutive, num,
                 ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY to_date(calender_dt, 'yyyy-mm-dd') ) -
                 ROW_NUMBER() OVER (PARTITION BY cust_id, consecutive ORDER BY to_date(calender_dt, 'yyyy-mm-dd') ) grp
          FROM addOrder
        )
        GROUP BY cust_id, consecutive , grp
        ORDER BY cust_id, start_dt
),

getDiff AS (                                            -- To get the difference between start and end date
    SELECT cust_id, con, 
            CASE WHEN con = 1 THEN end_dt - start_dt + 1 
            ELSE end_dt - start_dt END as duration
    FROM addIntervals
)

SELECT cust_id , MAX(duration) Max_consecutive_days    -- Get the maximum number of consecutive days for each customer
FROM getDiff
WHERE rownum <= 100
GROUP BY cust_id
ORDER BY Max_consecutive_days




            -- ********************************************************************************** 

-- B)

with runningTotal as (                                                      -- This will calculate the running total of purchases for each customer
    select cust_id, amt_le, calender_dt, 
             sum(amt_le)  over(partition by cust_id order by to_date(calender_dt , 'yyyy-mm-dd') rows unbounded preceding)  
             as commulativeSum
    from purchasings
    where rownum <= 1000
),

addDayNum as (                                                              -- Add the number of days ordered by the date
    select cust_id, amt_le, calender_dt, commulativeSum, 
             row_number() over(partition by cust_id order by  to_date(calender_dt , 'yyyy-mm-dd') )  dayNum
    from runningTotal
),

getThreshold as (                                                           -- Get the day number that breaks the threshold of commulative sum
    select cust_id, min(daynum) days  from addDayNum 
    where commulativeSum >=250
    group by cust_id
)

-- Get the average number of days to reach a spent threshold of 250 L.E.
select avg(days) "Average # of days " from getThreshold 


