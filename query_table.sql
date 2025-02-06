SELECT *
FROM job_postings_fact
LIMIT 10;

-- Getting the top 10 skills most used in data analysis
SELECT
    skill.skills AS job_skill,
    COUNT(jobs.job_id) AS job_count
FROM
    skills_dim AS skill
LEFT JOIN skills_job_dim AS skill_job
    ON skill.skill_id = skill_job.skill_id
LEFT JOIN job_postings_fact AS jobs 
    ON skill_job.job_id = jobs.job_id
WHERE
    jobs.job_title_short LIKE '%Data%Analyst%'
GROUP BY
    skill.skills
ORDER BY
    job_count DESC
LIMIT 10;

-- Showing the 10 companies with the highest number of data analyst job postings in Brazil
SELECT
    company.name,
    COUNT(job_id) AS counts
FROM
    company_dim AS company    
LEFT JOIN job_postings_fact AS jobs
    ON company.company_id = jobs.company_id 
WHERE
    jobs.job_title_short LIKE '%Data%Analyst%'
    AND job_location IN ('Brazil')   
GROUP BY
    company.name   
ORDER BY
    counts DESC         
LIMIT 10;            

-- Using time
SELECT
    job_title_short AS title,
    job_location AS location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST' AS date,
    EXTRACT(MONTH FROM job_posted_date) AS date_month,
    EXTRACT(YEAR FROM job_posted_date) AS date_year
FROM
    job_postings_fact
LIMIT 5;        
     
-- Checking number of job posts per month
SELECT
    EXTRACT(MONTH FROM job_posted_date) AS month,
    COUNT(job_id)
FROM
    job_postings_fact
WHERE   
    job_title_short = 'Data Analyst'    
GROUP BY   
    month   
ORDER BY
    month;  

/* 
Write a query to find the average salary both
yearly (salary_year_avg) and hourly (salary_hour_avg)
for job postings that where posted after june 1, 2023.
Group the results by job schedule type
*/
SELECT
    job_schedule_type,
    AVG(salary_year_avg),
    AVG(salary_hour_avg)
FROM
    job_postings_fact
WHERE
    job_posted_date > '2023-06-01'
    AND (salary_year_avg IS NOT NULL OR salary_hour_avg IS NOT NULL)
GROUP BY
    job_schedule_type        
LIMIT 10;    

/*
Write a query to count the number of job postings for each month in 2023, adjusting the 
job_posted_date to be in 'America/New_York' time zone before extracting (hint) the month. 
Assume the job_posted_date is stored in UTC. Group by and order by month
*/
SELECT
    COUNT(job_id),
    EXTRACT(MONTH FROM (job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York')) AS month
FROM
    job_postings_fact
WHERE
    EXTRACT(YEAR FROM (job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York')) = 2023
GROUP BY
    month
ORDER BY
    month;

/*
Write a query to find companies (include company name) that have posted jobs offering health 
insurance, where these postings were made in the second quarter of 2023. Use date extraction 
to filter by quarter.
*/

SELECT
    *
FROM
    company_dim AS comp
LEFT JOIN job_postings_fact AS jobs
    ON comp.company_id = jobs.company_id
WHERE
    (EXTRACT(MONTH FROM jobs.job_posted_date) BETWEEN 4 AND 6)
    AND jobs.job_health_insurance IS TRUE   
LIMIT 5;  

/*
CREATE TABLES FROM OTHER TABLES
create three tables: Jan 2023 jobs, feb 2023 jobs, mar 2023 jobs

Foreshadowing: This will be used in another practice problem below.
*/
CREATE TABLE january_jobs AS
    SELECT * FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1;

CREATE TABLE february_jobs AS
    SELECT * FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 2;

CREATE TABLE march_jobs AS
    SELECT * FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 3;

/*
Classify the new york jobs as loca, anywhere jobs as remote and else as onsite,
after this return the number of jobs for each category you created.
*/

SELECT
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM 
    job_postings_fact
WHERE
    job_title_short LIKE '%Data%Analyst%'
GROUP BY
    location_category
ORDER BY    
    number_of_jobs DESC
LIMIT 100;

/*
I want to categorize the salaries from each job posting. To see if it fits in my desired salary range.
- Put salary into different buckets
- Define what's a high, standard or low salary with our own conditions
- Why? It is easy to determine which job postings are worth looking at based on salary.
Bucketing is a common practice in data analysis when viewing categories.
- I only want to look at data analyst roles
- Order from highest to lowest
*/

SELECT
    COUNT(job_id) AS number_of_jobs,
    AVG(salary_year_avg) AS average_salary,
    CASE
        WHEN salary_year_avg < 55000 THEN 'Low'
        WHEN salary_year_avg BETWEEN 55000 AND 70000 THEN 'Standard'
        ELSE 'High'
    END AS salary_buckets
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
    AND job_location = 'Brazil'    
GROUP BY
    salary_buckets
ORDER BY
    number_of_jobs DESC
LIMIT 15;   


WITH january_jobs AS (
    SELECT * FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
)
SELECT *
FROM january_jobs;

SELECT *
FROM (
	SELECT *
	FROM job_postings_fact
	WHERE EXTRACT(MONTH FROM job_posted_date) = 1
) AS january_jobs;

/*
SUBQUERIE
Looking for jobs that don't require degree
*/
SELECT 
    company_id,
    name AS company_name
FROM company_dim
WHERE company_id IN (
    SELECT
        company_id
    FROM
        job_postings_fact
    WHERE
        job_no_degree_mention = true
    ORDER BY
        company_id
);
     
/*
CTEs
Finding the companies with the most job openings
*/

WITH company_job_count AS (
    SELECT 
        company_id,
        COUNT(*) AS total_jobs
    FROM
        job_postings_fact
    GROUP BY 
        company_id        
)

SELECT
    company_dim.name AS company_name,
    company_job_count.total_jobs
FROM
    company_dim
LEFT JOIN company_job_count ON company_job_count.company_id = company_dim.company_id
ORDER BY
    total_jobs DESC
LIMIT 100;        

/*
OR....
*/

SELECT
    cd.name,
    COUNT(jobs.job_id) AS number_of_jobs
FROM
    job_postings_fact AS jobs
LEFT JOIN company_dim AS cd
    ON cd.company_id = jobs.company_id    
GROUP BY
    cd.company_id    
ORDER BY
    number_of_jobs DESC;    

/*
Identify the top 5 skills that are most frequently mentioned in job postings. 
Use a subquery to find the skill IDs with the highest counts in the skills_job_dim 
able and then join this result with the skills_sim table to get the skill names.
*/

SELECT 
    sd.skills, 
    top_skills.counts
FROM (
    SELECT 
        sjd.skill_id, 
        COUNT(sjd.job_id) AS counts
    FROM skills_job_dim AS sjd
    GROUP BY sjd.skill_id
    ORDER BY counts DESC
    LIMIT 5
) AS top_skills
LEFT JOIN skills_dim AS sd 
    ON sd.skill_id = top_skills.skill_id
ORDER BY top_skills.counts DESC;

/*
Determine the size category ('Small','Medium', or 'Large') for 
each company by first identifying the number of job postings they have. 
Use a sobquery to calculate the total job postings per company. A company 
considered 'Small' if it has less than 10 job postings, 'Medium' if the number 
of job postings is between 10 and 50, and 'Large' if it has more than 50 job postings. 
implement a subquery to aggregate job counts per company before classifying 
them based on size.
*/


SELECT
    cd.name AS company_name,
    job_counts.counts AS counts,
    CASE
        WHEN counts < 10 THEN 'Small'
        WHEN counts <= 50 THEN 'Medium'
        ELSE 'Large'
    END AS company_size
FROM (
    SELECT
        company_id,
        COUNT(job_id) AS counts
    FROM
        job_postings_fact AS jobs
    GROUP BY
        company_id 
) AS job_counts
LEFT JOIN company_dim AS cd
    ON cd.company_id = job_counts.company_id   

/*
Find the count of the number of remote job postings per skill
- display the top 5 skills by their demand in remote jobs
- include skill ID, name, and count of postings requiring the skill
*/