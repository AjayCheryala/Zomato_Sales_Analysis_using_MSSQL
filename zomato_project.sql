CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);




drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;




1. What is the total amount each customer spent on zomato?

select s.userid, sum(p.price) from sales s 
join product p
on s.product_id = p.product_id
group by (s.userid)

2. How many days has each customer visited zomato?

select userid, count(distinct created_date) as no_of_days from sales
group by userid;


3. What was the first product purchased by each customer?

select * from (
	select *
	, ROW_NUMBER() OVER (PARTITION BY userid ORDER BY created_date) as rn
    from sales) a
where rn = 1;

4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select userid
, product_id as most_purchased
, count(product_id) as no_of_times from sales
where product_id = (select top 1 product_id from sales
					group by product_id
					order by count(product_id) desc
					) 
group by userid, product_id

5. Which item was the most popular for each customer?

select userid, product_id
from (select userid
		, product_id
		, count(product_id)  as cn
		, RANK() over(partition by userid order by count(product_id) desc) as rk
		 from sales
		group by userid, product_id
     ) a
where rk =1;

6. Which item was purchased first by the customer after they become a member?

select * from (
select g.userid, g.gold_signup_date, s.created_date, s.product_id
, ROW_NUMBER() over(partition by g.userid, g.gold_signup_date order by s.created_date) as rn
from goldusers_signup g 
join sales s 
on g.userid = s.userid
where s.created_date >= g.gold_signup_date) a
where rn = 1;

7. Which item was purchased just before the customer became member?

select * from (
select g.userid, g.gold_signup_date, s.created_date, s.product_id
, ROW_NUMBER() over(partition by g.userid, g.gold_signup_date order by s.created_date desc) as rn
from goldusers_signup g 
join sales s 
on g.userid = s.userid
where s.created_date <= g.gold_signup_date) a
where rn = 1;


8. What is the total orders and amount spent for each member before they become a member?

select g.userid
, count(s.product_id) as total_orders
, sum(p.price)        as total_amount
from goldusers_signup 
g join sales s
on g.userid = s.userid
join product p
on s.product_id = p.product_id
where s.created_date < g.gold_signup_date
group by g.userid

9. If buying each product generates points for eg Rs.5 = 2 zomato points and each product has different purchasing points 
for eg for p1 Rs.5 = 1 zomato point, for p2 Rs.10 = 5 zomato points and p3 Rs.5 = 1 zomato point  

calculate points collected by  each customers and for which product most points have been given till now?

with points as (
select *
,   case
		when product_id = 1 then 1*price/5
		when product_id = 2 then 5*price/10
		when product_id = 3 then 1*price/5
	end as points
from product   ) 


select s.userid, sum(p.points)  total_points, sum(p.points)*2.5 money_earned
from sales s
join points p
on s.product_id = p.product_id
group by s.userid

select top 1 s.product_id, sum(p.points)  total_points
from sales s
join points p
on s.product_id = p.product_id
group by s.product_id
order by 2 desc


10. In the first one year after a customer joins the gold program (including their join date) irrespective of 
what the customer has purchased they earn 5 zomato points for every Rs.10 spent,
	Q1. Who earned more 1 or 2?
	Q2. What was their points earnings in their first year?

select g.userid, s.created_date, s.product_id, p.price, 5*p.price/10  points
from goldusers_signup g
join sales s
on g.userid = s.userid
join product p 
on s.product_id = p.product_id
where s.created_date between g.gold_signup_date and dateadd(year, 1, g.gold_signup_date)


11. rnk all the transactions of the customers

select *, rank() over(partition by userid order by created_date) from sales

12. rnk all the transactions for each member whoever they are a zomato gold member for every non gold member transaction mark as na

select *, case when rnk = 0 then 'na' else rnk end as rrnk from
(select s.userid, s.created_date, s.product_id, g.gold_signup_date
,   cast((case
			when g.gold_signup_date is null then 0
			else rank() over(partition by s.userid order by s.created_date desc) 
		  end) as varchar) as  rnk
from sales s
left join goldusers_signup g
on s.userid = g.userid
and s.created_date >= g.gold_signup_date) a






