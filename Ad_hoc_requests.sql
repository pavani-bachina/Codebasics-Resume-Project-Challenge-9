/* 1. Provide a list of products with a base price greater than 500 and that are featured in promo type of 
'BOGOF' (Buy One Get One Free). */
SELECT distinct p.product_name, e.base_price 
FROM fact_events e
JOIN dim_products p on e.product_code = p.product_code
where e.base_price>500 and promo_type="BOGOF";

/* 2. Generate a report that provides an overview of the number of stores in each city.*/
SELECT city, COUNT(DISTINCT store_id) AS store_count 
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;
SET sql_mode = '';
/* 3. Generate a report that displays each campaign along with the total revenue generated before and after the campaign? */
with pro_prc as
( 
	select *, 
        case
            when promo_type = "500 Cashback" then ROUND(base_price-500,2)
		    when promo_type = "25% OFF" then ROUND(base_price-(base_price*25/100),2)
            when promo_type = "33% OFF" then ROUND(base_price-(base_price*33/100),2)
			else ROUND(base_price/2,2)
		end as promo_price
	from fact_events
)
select 
	c.campaign_name, 
    round(SUM(p.base_price * p.`quantity_sold(before_promo)`)/1000000,2) as total_revenue_before_promotion_millions,
    round(SUM(p.promo_price * p.`quantity_sold(after_promo)`)/1000000,2) as total_revenue_after_promotion_millions
from pro_prc p
join dim_campaigns c on p.campaign_id=c.campaign_id
group by c.campaign_id;

/* 4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. */
with isu_pct as 
(
	select p.product_code,p.category,f.campaign_id,Round(((SUM(f.`quantity_sold(after_promo)`)/SUM(f.`quantity_sold(before_promo)`))-1)*100,2) as `ISU%`
    from fact_events f
    join dim_products p on f.product_code=p.product_code
    where campaign_id="CAMP_DIW_01"
    group by p.category
    
)
select 
	category,
    `ISU%`,
    rank() over ( order by `ISU%` desc) _rank
from isu_pct;


/* 5. Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns.*/ 
with pro_prc as
( 
	select *, 
        case
            when promo_type = "500 Cashback" then ROUND(base_price-500,2)
		    when promo_type = "25% OFF" then ROUND(base_price-(base_price*25/100),2)
            when promo_type = "33% OFF" then ROUND(base_price-(base_price*33/100),2)
			else ROUND(base_price/2,2)
		end as promo_price
	from fact_events
)
select 
	pr.product_name,
    pr.category,
    Round(((SUM(p.promo_price * p.`quantity_sold(after_promo)`)/SUM(p.base_price * p.`quantity_sold(before_promo)`))-1)*100,2) as `IR%`
from pro_prc p
join dim_products pr on p.product_code=pr.product_code
group by pr.product_name
order by `IR%` desc
limit 5;