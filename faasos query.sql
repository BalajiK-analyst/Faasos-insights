drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2021 21:30:45','25km','25mins',null),
(8,2,'01-10-2021 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2021 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

--How many rolls was oredered;

select count(order_id) as Total_Rolls_Ordered from customer_orders;

--how many unique customer orders was made;
 
 select count(distinct(customer_id)) as unique_customr_id from customer_orders;

 ---how many successful orders were made by the driver;

 select driver_id,count(distinct(order_id)) as Successful_orders from driver_order
where cancellation not in ('cancellation','customer cancellation')
group by driver_id;

---how many of each type of rolls were delivered

select c.roll_id,count(c.roll_id) as roll_ordered_times from customer_orders c join 
(select * from
(select *,case when cancellation like ('%cancel%') then 'c' else 'nc' end as cancellation_details
from driver_order) a
where cancellation_details != 'c') b on c.order_id=b.order_id
group by c.roll_id

---how many veg and non veg rolls were ordered by each country

select a.customer_id,r.roll_name as roll_type,a.ordered_count from
(select customer_id,roll_id,count(roll_id) as ordered_count from customer_orders
group by customer_id,roll_id) a
join rolls r on a.roll_id=r.roll_id
order by a.customer_id

---what was the maximum number of rolls delivered in a single order

select top 1 d.order_id,count(d.roll_id) as cnt_of_orders from 
(select * from 
(select *,case when cancellation like ('%cancel%') then 'c' else 'nc' end as cancellation_details
from driver_order) a
where cancellation_details != 'c') b  join customer_orders d on b.order_id=d.order_id
group by d.order_id
order by cnt_of_orders desc

---for each customer how many of orders that have atleast one add-on to the rolls(wrap) and had no changes

with temp_customer_orders as 
(select order_id,customer_id,roll_id,order_date,
case when not_include_items = ' ' or not_include_items is NULL then '0' else not_include_items end as not_include_items,
case when extra_items_included = ' ' or extra_items_included is NULL or extra_items_included ='NaN' then '0' else extra_items_included end 
as extra_items_included
from customer_orders),

temp_driver_order as (
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order)

select customer_id,chg_no_chg,count(order_id) as at_least_1_change from
(select *,case when not_include_items='0' and extra_items_included='0' then 'no change' else 'change' end chg_no_chg
from temp_customer_orders where order_id in(
select order_id from temp_driver_order where new_cancellation !=0))a
group by customer_id,chg_no_chg

---how many rolls were delivered that had both excluded toppings and extras toppings

with temp_customer_orders as 
(select order_id,customer_id,roll_id,order_date,
case when not_include_items = ' ' or not_include_items is NULL then '0' else not_include_items end as not_include_items,
case when extra_items_included = ' ' or extra_items_included is NULL or extra_items_included ='NaN' then '0' else extra_items_included end 
as extra_items_included
from customer_orders),

temp_driver_order as (
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order)

select chg_no_chg as changes,count(chg_no_chg) cnt_of_changes from
(select *,case when not_include_items!='0' and extra_items_included!='0' then
'both incl and excl' else 'either 1 incl or exlcl' end chg_no_chg
from temp_customer_orders where order_id in(
select order_id from temp_driver_order where new_cancellation !=0))a
group by chg_no_chg

---what was the total number of rolls ordered for each hour of the day

select hour_bucket as hours,count(hour_bucket) as orders_in_days from
(select *,concat(cast(DATEPART(hour,order_date) as varchar),'-',cast(DATEPART(hour,order_date)+1 as varchar)) hour_bucket from 
customer_orders)a
group by hour_bucket

---which day of the week have the most orders

select day_in_week,count(distinct order_id) as orders from
(select *, datename(dw,order_date) as day_in_week from customer_orders) a
group by day_in_week

---what was the avg time taken in minutes for a driver to arrive to pickup the order from store

select driver_id,(sum(diff)/count(order_id)) avg_time_taken_to_deliver from
(select * from
(select *,ROW_NUMBER() over(partition by order_id order by diff) rnk from
(select c.order_id,c.customer_id,c.roll_id,c.not_include_items,c.extra_items_included,c.order_date,d.driver_id,
d.pickup_time,d.distance,d.duration,d.cancellation,DATEDIFF(MINUTE,c.order_date,d.pickup_time) diff from customer_orders c
join driver_order d
on c.order_id=d.order_id
where d.pickup_time is not null) a) b
where rnk =1) f
group by driver_id

--- is there any relationship between the number of rolls and how long the order taken to prepare
select order_id,count(roll_id) rolls_ordered,sum(diff)/count(roll_id) as prep_time from
(select c.order_id,c.customer_id,c.roll_id,c.not_include_items,c.extra_items_included,c.order_date,d.driver_id,
d.pickup_time,d.distance,d.duration,d.cancellation,DATEDIFF(MINUTE,c.order_date,d.pickup_time) diff from customer_orders c
join driver_order d
on c.order_id=d.order_id
where d.pickup_time is not null) t
group by order_id

---what was the average distance travalled for each customer

select customer_id,sum(distance)/count(order_id) avg_distance from
(select * from
(select *,row_number() over(partition by order_id order by diff) rnk from
(select c.order_id,c.customer_id,c.roll_id,c.not_include_items,c.extra_items_included,c.order_date,d.driver_id,
d.pickup_time,cast(trim(replace(lower(d.distance),'km','')) as decimal(4,2)) distance,d.duration,d.cancellation,DATEDIFF(MINUTE,c.order_date,d.pickup_time) diff from customer_orders c
join driver_order d
on c.order_id=d.order_id
where d.pickup_time is not null) a)b 
where rnk = 1)c
group by customer_id

--- what was the difference btw the longest and shortes duration taken for a order

select max(cast(duration2 as int)) as max_time_taken,min(cast(duration2 as int)) as min_time_taken,
max(cast(duration2 as int))-min(cast(duration2 as int)) as diffrnc from
(select *,case when duration  like '%min%' then left(duration,CHARINDEX('m',duration)-1) else duration end as duration2 from driver_order
where duration is not null) a

---what was the average speed for each driver for each delivery and do you notice any trend for these values

select a.order_id,a.driver_id,a.distance/a.duration speed_avg,b.cnt as no_roll_ordered from
(select order_id,driver_id,cast(trim(replace(lower(distance),'km','')) as decimal(4,2)) distance,
cast(case when duration  like '%min%' then left(duration,CHARINDEX('m',duration)-1) else duration end as int) as duration
from driver_order where distance is not null) a join
(select order_id,count(roll_id) cnt from customer_orders group by order_id) b on a.order_id=b.order_id

---what is the successful delivered percentage for each driver

select driver_id, sum(can_per)*100/count(driver_id) as successful_orders from
(select *,case when lower(cancellation) like '%cancel%' then 0 else 1 end as can_per 
from driver_order) a
group by driver_id








