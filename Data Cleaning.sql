-- we will create a database
-- import a real dataset
-- 

select * 
from world_layoffs.layoffs;

-- 1. Remove Duplicates if there are any
-- 2. Standardize the data (like if there are any spelling issue in date we will fix that into same formate)
-- 3. Null values or Blank values (sometimes we do populate them and sometime we did not)
-- 4. Remove any unnecessary Rows or Columns


-- Our layoffs table is raw date, so we create a staging table from it and that have same columns 
-- like layoffs then we insert data init:

create table  layoffs_staging
like layoffs;

select * 
from layoffs_staging
; -- it contains all same column name now we can insert data init:

INSERT layoffs_staging
select * 
from layoffs
;-- now layoffs_staging contain all values 

select * 
from layoffs_staging;

-- 1. WE start with checking and removing duplicates

select *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) as row_num
from layoffs_staging;

-- Using CTE:

WITH duplicate_cte as
(
select *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
select * 
from duplicate_cte
where row_num > 1;
-- the above duplicate_cte is actually returning us the duplicate rows

select * 
from layoffs_staging
where company = "Casper"; -- this contain duplicate

select * 
from layoffs_staging
where company = "Cazoo"; -- this contain duplicate

select * 
from layoffs_staging
where company = "Hibob"; -- this contain duplicate

select * 
from layoffs_staging
where company = "Wildlife studios"; -- this contain duplicate

select * 
from layoffs_staging
where company = "Yahoo"; -- this contain duplicate

create table layoffs_staging2
like layoffs_staging;

select * 
from layoffs_staging2;

alter table layoffs_staging2
add column row_num int after funds_raised_millions;

insert into layoffs_staging2 
select *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
stage, country, funds_raised_millions) as row_num
from layoffs_staging;

select *
from layoffs_staging2;

select *
from layoffs_staging2
where row_num > 1;

DELETE
from layoffs_staging2
where row_num > 1;

-- 2. Now we start doing Standardize the data:
-- standardizing data is finding issue in the data and then fixing it

-- in standardizing first thing that we do is we do check column values may have extra blank spaces in start and end or in between
-- so we do need to TRIM that

select company, TRIM(company)
from layoffs_staging2;

UPDATE layoffs_staging2
SET company = trim(company); -- this will trim the company column in layoffs_staging2 column

select *
from layoffs_staging2; -- we can see that company column sucessfully got TRIM

-- we do actually need to TRIM every column that have string values

update layoffs_staging2
set location = trim(location),
	industry = trim(industry),
    stage= trim(stage),
    country = trim(country);
    
select *
from layoffs_staging2;

select distinct industry
from layoffs_staging2
order by 1; -- as we can see that word Crypto and Crypto Currency have same thing but they have both used 
-- so we need to check and update it to mostly used word

select industry
from layoffs_staging2
where industry like "crypto%"
;-- now we can seen that word Crypto is used most of the time instead of Crypto Currency so we update other ones to Crypto

update layoffs_staging2
SET industry = 'Crypto'
where industry like "crypto%"
;

select *
from layoffs_staging2;

-- we have looked at company, industry column now its time to look at location column

select distinct location
from layoffs_staging2
order by 1; -- its looking fine now take a look at country column

select distinct country
from layoffs_staging2
order by 1; -- in it the word United States and United States. used so we need to look at that

select country
from layoffs_staging2
where country like 'United States%'
; -- as we can see that United States is used most of time so we update United States. to it
-- but at above we have used TRIM() on country column also but it does not fixed it so we now use TRIM(TRAILING)

select distinct country, trim(TRAILING '.' from country)
from layoffs_staging2; -- as we can see that now its getting fixed sowe need to update country column

UPDATE layoffs_staging2
set country = trim(TRAILING '.' from country)
where country like "United States%"
;

select distinct country
from layoffs_staging2
order by 1; -- we can see that country column is also got fixed

select * 
from layoffs_staging2; -- our company, location, industry and country columns are fixed now its time for date column
-- as if we go into left side SCHEMES menu and in world_layoffs database, we check the table layoffs_staging2 column of
-- date and see its type is text so we need to update it to date type  

-- for that we need to use str_to_date(`date_column_name_that_need_to_change`, 'and_what_format_we_have_it')

select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2
; -- it changes our date column into standerd date format "YYYY/MM/DD" thisis what we want now update out date column

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

select `date`
from layoffs_staging2; -- it worked perfectly, now if we check the date column time its still text but now its in date format
-- so now we can alter the date column type to date

alter table layoffs_staging2
modify column `date` DATE; -- now out date column type is changed to DATE

select *
from layoffs_staging2;

-- we have fixed our issues with company, industry, date, country columns 
-- we have sucessfully performed 1. Removed Duplicates 2. Standardized it now its time to move on step 
-- 3. Working with Nulls and Blank values

-- so we do need to think of that what are we goona do with those value, should we make them null, or delete them or fill
-- those null, blank values populate them 

select * 
from layoffs_staging2
;

-- lets start with total_laid_off column

select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select *
from layoffs_staging2
where industry is null
or industry = ''; -- as we can see there are only 4 rows which have no values,
-- lets see those company one by one and try to check is they have repeated rows we populate them with the following industry

select *
from layoffs_staging2
where company = 'Airbnb'; -- and see we found 2 rows with 1 have industry name as Travel, so we populate the other also with it

update layoffs_staging2
set industry = null
where industry = '';

select *
from layoffs_staging2 as t1
join layoffs_staging2 as t2
	on t1.company = t2.company
where t1.industry is null
and t2.industry is not null;

update layoffs_staging2 as t1
join layoffs_staging2 as t2
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null
; -- we have sucessfully update the blank null values in industry column, now lets check again 

select *
from layoffs_staging2
where industry is null
or industry = ''; -- now we have only 1 company Bally's Interactive that have industry value null

select *
from layoffs_staging2
where company = "Bally's Interactive"; -- this company is only appears one time in whole table 
-- but other companies that have multiple time in table and have missing value we have fixed them

select *
from layoffs_staging2;

-- now lets back to the column that have total_laid_off and percentage_laid_off both null and we should delet them

select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

Delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select *
from layoffs_staging2;

-- 4. Delete any un-necessary rows or column
-- we do also no need of column row_num, so we can drop it also

alter table layoffs_staging2
drop column row_num;

select *
from layoffs_staging2;

-- finally we can see that our data is clean now
-- and in next project we will do exploratory data analysis on this clean data, we will find trends and patterns