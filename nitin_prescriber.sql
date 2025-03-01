--For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File]
--(https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). 
--More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

--1. 
--    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT
	PR.NPI AS NPI,
	SUM(PR.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIPTION PR
	INNER JOIN PRESCRIBER PB USING (NPI)
GROUP BY
	PR.NPI
ORDER BY
	TOTAL_CLAIMS DESC LIMIT
	1;


--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT
	PB.NPI AS NPI,
	PB.NPPES_PROVIDER_FIRST_NAME,
	PB.NPPES_PROVIDER_LAST_ORG_NAME,
	PB.SPECIALTY_DESCRIPTION,
	SUM(PR.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIPTION PR
	INNER JOIN PRESCRIBER PB USING (NPI)
GROUP BY
	PB.NPI,
	PB.NPPES_PROVIDER_FIRST_NAME,
	PB.NPPES_PROVIDER_LAST_ORG_NAME,
	PB.SPECIALTY_DESCRIPTION
ORDER BY
	TOTAL_CLAIMS DESC LIMIT
	1;

--2. 
--    a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT
	PB.SPECIALTY_DESCRIPTION AS SPECIALTY,
	SUM(PR.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIPTION PR
	INNER JOIN PRESCRIBER PB USING (NPI)
GROUP BY
	PB.SPECIALTY_DESCRIPTION
ORDER BY
	TOTAL_CLAIMS DESC LIMIT
	1;

-- b. Which specialty had the most total number of claims for opioids?
SELECT
	PB.SPECIALTY_DESCRIPTION AS SPECIALTY,
	SUM(PR.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIPTION PR
	INNER JOIN PRESCRIBER PB USING (NPI)
	INNER JOIN drug d on pr.drug_name = d.drug_name
where d.opioid_drug_flag = 'Y'
GROUP BY
	PB.SPECIALTY_DESCRIPTION
ORDER BY
	TOTAL_CLAIMS DESC LIMIT
	1;

--c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT DISTINCT
	PB1.NPI AS PRESCRIBE_NPI,
	PB1.SPECIALTY_DESCRIPTION AS SPECIALTY,
	PR.NPI AS PRESCRIPTION_NPI
FROM
	(
		SELECT DISTINCT
			NPI,
			SPECIALTY_DESCRIPTION
		FROM
			PRESCRIBER
	) AS PB1
	LEFT JOIN PRESCRIPTION PR USING (NPI)
WHERE
	PR.NPI IS NULL;

--d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty 
--which are for opioids. Which specialties have a high percentage of opioids?

SELECT
	PB.SPECIALTY_DESCRIPTION AS SPECIALTY,
	MAX(PB2.TOT_SPEC_CLAIMS),
	SUM(PR.TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS_PER_SPEC,
	ROUND(
		SUM(PR.TOTAL_CLAIM_COUNT) / MAX(PB2.TOT_SPEC_CLAIMS) * 100,
		2
	) AS PER_TOT_CLAIMS
FROM
	PRESCRIPTION PR
	INNER JOIN PRESCRIBER PB USING (NPI)
	INNER JOIN DRUG D USING (DRUG_NAME)
	INNER JOIN (
		SELECT
			PB1.SPECIALTY_DESCRIPTION,
			SUM(PR1.TOTAL_CLAIM_COUNT) AS TOT_SPEC_CLAIMS
		FROM
			PRESCRIPTION PR1
			INNER JOIN PRESCRIBER PB1 USING (NPI)
			INNER JOIN DRUG USING (drug_name)
		GROUP BY
			SPECIALTY_DESCRIPTION
	) PB2 USING (SPECIALTY_DESCRIPTION)
WHERE
	OPIOID_DRUG_FLAG = 'Y'
GROUP BY
	PB.SPECIALTY_DESCRIPTION
ORDER BY
	PER_TOT_CLAIMS DESC;


--3. 
    --a. Which drug (generic_name) had the highest total drug cost?

SELECT
	D.GENERIC_NAME AS DRUG_GENERIC_NAME,
	MAX(PR.TOTAL_DRUG_COST) AS DRUG_COST
FROM
	DRUG D
	INNER JOIN PRESCRIPTION PR ON PR.DRUG_NAME = D.DRUG_NAME
GROUP BY
	D.GENERIC_NAME
ORDER BY
	DRUG_COST DESC
	LIMIT 1;

	--b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT
	D.GENERIC_NAME AS DRUG_GENERIC_NAME,
	SUM(
		ROUND(PR.TOTAL_DRUG_COST / PR.TOTAL_DAY_SUPPLY, 2)
	) AS DRUG_COST_PER_DAY
FROM
	DRUG D
	INNER JOIN PRESCRIPTION PR ON PR.DRUG_NAME = D.DRUG_NAME
GROUP BY
	D.GENERIC_NAME
ORDER BY
	DRUG_COST_PER_DAY DESC LIMIT
	1;

--4. 
--    a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
-- says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. 
--See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT
	DRUG_NAME,
	CASE
		WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'OPIOID'
		WHEN ANTIBIOTIC_DRUG_FLAG = 'Y' THEN 'ANTIBIOTIC'
		ELSE 'NEITHER'
	END AS DRUG_TYPE FROM
	DRUG;

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.

SELECT
	DRUG2.DRUG_TYPE AS DRUG_TYPE,
	cast(SUM(PR.TOTAL_DRUG_COST) as money) AS DRUG_COST 
FROM
	PRESCRIPTION PR 
	INNER JOIN (
		SELECT
			DRUG_NAME,
			CASE
				WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'OPIOID'
				WHEN ANTIBIOTIC_DRUG_FLAG = 'Y' THEN 'ANTIBIOTIC'
				ELSE 'NEITHER'
			END AS DRUG_TYPE
		FROM
			DRUG
	) AS DRUG2 ON DRUG2.DRUG_NAME = PR.DRUG_NAME
WHERE
	DRUG2.DRUG_TYPE IN ('OPIOID', 'ANTIBIOTIC')
GROUP BY
	DRUG2.DRUG_TYPE
ORDER BY	DRUG_COST DESC;


--5. 
    --a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT
	COUNT(distinct CBSA) AS TOTAL_CBSA
FROM
	CBSA
WHERE
	FIPSCOUNTY IN (
		SELECT DISTINCT
			FIPSCOUNTY
		FROM
			FIPS_COUNTY
		WHERE
			STATE = 'TN'
	);

--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT
	C.CBSA AS CBSA,
	C.CBSANAME AS CBSA_NAME,
	SUM(P.POPULATION) AS TOT_POPULATION
FROM
	CBSA C
	INNER JOIN POPULATION P USING (FIPSCOUNTY)
GROUP BY
	C.CBSA,
	C.CBSANAME
ORDER BY
	TOT_POPULATION DESC;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT
	FP.COUNTY AS COUNTY_NAME,
	P.*
FROM
	FIPS_COUNTY FP
	INNER JOIN POPULATION P USING (FIPSCOUNTY)
WHERE
	P.FIPSCOUNTY NOT IN (
		SELECT
			FIPSCOUNTY
		FROM
			CBSA
	)
ORDER BY
	P.POPULATION DESC
LIMIT
	1;

--6. 
 --   a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT
	DRUG_NAME,
	TOTAL_CLAIM_COUNT
FROM
	PRESCRIPTION
WHERE
	TOTAL_CLAIM_COUNT >=3000;

	
	--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT
	P.DRUG_NAME,
	P.TOTAL_CLAIM_COUNT,
	CASE
		WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'Y'
		ELSE 'N'
	END AS IND_OPIOID
FROM
	PRESCRIPTION P
	INNER JOIN DRUG D USING (DRUG_NAME)
WHERE
	TOTAL_CLAIM_COUNT >= 3000;

--c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT
	P.DRUG_NAME,
	P.TOTAL_CLAIM_COUNT,
	CASE
		WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'Y'
		ELSE 'N'
	END AS IND_OPIOID,
	PR.NPPES_PROVIDER_FIRST_NAME AS FIRST_NAME,
	PR.NPPES_PROVIDER_LAST_ORG_NAME AS LAST_NAME
FROM
	PRESCRIPTION P
	INNER JOIN DRUG D USING (DRUG_NAME)
	INNER JOIN PRESCRIBER PR USING (NPI)
WHERE
	P.TOTAL_CLAIM_COUNT >= 3000;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
--**Hint:** The results from all 3 parts will have 637 rows.

--a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the 
--city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. 
--You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT distinct 
	PR.npi,
	d.drug_name
FROM
	PRESCRIBER PR 
	CROSS JOIN DRUG D 
WHERE
	PR.specialty_description = 'Pain Management'
	and PR.nppes_provider_city = 'NASHVILLE'
	and d.OPIOID_DRUG_FLAG = 'Y';

	SELECT *
FROM
	PRESCRIBER PR 
	CROSS JOIN DRUG D 
WHERE
	PR.specialty_description = 'Pain Management'
	and PR.nppes_provider_city = 'NASHVILLE'
	and d.OPIOID_DRUG_FLAG = 'Y';

--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
--You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT  
	PR.npi,
	d.drug_name,
	P.total_claim_count
FROM
	PRESCRIBER PR
	CROSS JOIN DRUG D
	LEFT JOIN Prescription P USING (NPI,drug_name)
WHERE
	PR.specialty_description = 'Pain Management'
	and PR.nppes_provider_city = 'NASHVILLE'
	and d.OPIOID_DRUG_FLAG = 'Y'
order by 1,2;

--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT  
	PR.npi,
	d.drug_name,
	--P.total_claim_count,
	COALESCE(P.total_claim_count,NULL,0,P.total_claim_count) as total_claim_count
FROM
	PRESCRIBER PR
	CROSS JOIN DRUG D
	LEFT JOIN Prescription P USING (NPI,drug_name)
WHERE
	PR.specialty_description = 'Pain Management'
	and PR.nppes_provider_city = 'NASHVILLE'
	and d.OPIOID_DRUG_FLAG = 'Y'
order by 1,2;



-----------------------------------------------BONUS---------------------------------------------

--1.How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT
	P1.NPI,
	P2.NPI
FROM
	PRESCRIBER P1
	LEFT JOIN PRESCRIPTION P2 USING (NPI)
WHERE
	P2.NPI IS NULL;

--alternative
SELECT
	P1.NPI
FROM
	PRESCRIBER P1
EXCEPT
SELECT
	P2.NPI
FROM
	PRESCRIPTION P2;


--2
--a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT
	D.generic_name AS DRUG,
	PB.SPECIALTY_DESCRIPTION as specialty,
	COUNT(*) AS TOTAL_DRUG
FROM
	PRESCRIBER PB
	INNER JOIN PRESCRIPTION PR USING (NPI)
	INNER JOIN DRUG D ON PR.DRUG_NAME = D.DRUG_NAME
WHERE
	PB.SPECIALTY_DESCRIPTION = 'Family Practice'
GROUP BY
	D.generic_name,PB.SPECIALTY_DESCRIPTION
ORDER BY
	TOTAL_DRUG DESC
LIMIT
	5;

--b.Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT
	D.generic_name AS DRUG,
	PB.SPECIALTY_DESCRIPTION as specialty,
	COUNT(*) AS TOTAL_DRUG
FROM
	PRESCRIBER PB
	INNER JOIN PRESCRIPTION PR USING (NPI)
	INNER JOIN DRUG D ON PR.DRUG_NAME = D.DRUG_NAME
WHERE
	PB.SPECIALTY_DESCRIPTION = 'Cardiology'
GROUP BY
	D.generic_name,PB.SPECIALTY_DESCRIPTION
ORDER BY
	TOTAL_DRUG DESC
LIMIT
	5;

--c.Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
--Combine what you did for parts a and b into a single query to answer this question.

SELECT
	*
FROM
	(
		SELECT
			D.GENERIC_NAME AS DRUG,
			PB.SPECIALTY_DESCRIPTION AS SPECIALTY,
			COUNT(*) AS TOTAL_DRUG
		FROM
			PRESCRIBER PB
			INNER JOIN PRESCRIPTION PR USING (NPI)
			INNER JOIN DRUG D ON PR.DRUG_NAME = D.DRUG_NAME
		WHERE
			PB.SPECIALTY_DESCRIPTION = 'Family Practice'
		GROUP BY
			D.GENERIC_NAME,
			PB.SPECIALTY_DESCRIPTION
		ORDER BY
			TOTAL_DRUG DESC
		LIMIT
			5
	)
UNION ALL
SELECT
	*
FROM
	(
		SELECT
			D.GENERIC_NAME AS DRUG,
			PB.SPECIALTY_DESCRIPTION AS SPECIALTY,
			COUNT(*) AS TOTAL_DRUG
		FROM
			PRESCRIBER PB
			INNER JOIN PRESCRIPTION PR USING (NPI)
			INNER JOIN DRUG D ON PR.DRUG_NAME = D.DRUG_NAME
		WHERE
			PB.SPECIALTY_DESCRIPTION = 'Cardiology'
		GROUP BY
			D.GENERIC_NAME,
			PB.SPECIALTY_DESCRIPTION
		ORDER BY
			TOTAL_DRUG DESC
		LIMIT
			5
	);

---3Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee. 
--a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) 
--across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT
	P.NPI,
	PR.NPPES_PROVIDER_CITY,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIBER PR
	INNER JOIN PRESCRIPTION P USING (NPI)
WHERE
	PR.NPPES_PROVIDER_CITY = 'NASHVILLE'
GROUP BY
	P.NPI,
	PR.NPPES_PROVIDER_CITY
ORDER BY
	TOTAL_CLAIMS DESC
	LIMIT 5;
	
-- Now, report the same for Memphis.

SELECT
	P.NPI,
	PR.NPPES_PROVIDER_CITY,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIBER PR
	INNER JOIN PRESCRIPTION P USING (NPI)
WHERE
	PR.NPPES_PROVIDER_CITY = 'MEMPHIS'
GROUP BY
	P.NPI,
	PR.NPPES_PROVIDER_CITY
ORDER BY
	TOTAL_CLAIMS DESC
	LIMIT 5;


--c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
select * from (
select * from
(
SELECT
	P.NPI,
	PR.NPPES_PROVIDER_CITY,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIBER PR
	INNER JOIN PRESCRIPTION P USING (NPI)
WHERE
	PR.NPPES_PROVIDER_CITY = 'NASHVILLE'
GROUP BY
	P.NPI,
	PR.NPPES_PROVIDER_CITY
ORDER BY
	TOTAL_CLAIMS DESC
	LIMIT 5
)
union
select * from
(
SELECT
	P.NPI,
	PR.NPPES_PROVIDER_CITY,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIBER PR
	INNER JOIN PRESCRIPTION P USING (NPI)
WHERE
	PR.NPPES_PROVIDER_CITY = 'MEMPHIS'
GROUP BY
	P.NPI,
	PR.NPPES_PROVIDER_CITY
ORDER BY
	TOTAL_CLAIMS DESC
	LIMIT 5
)
union
select * from
(
SELECT
	P.NPI,
	PR.NPPES_PROVIDER_CITY,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIBER PR
	INNER JOIN PRESCRIPTION P USING (NPI)
WHERE
	PR.NPPES_PROVIDER_CITY = 'KNOXVILLE'
GROUP BY
	P.NPI,
	PR.NPPES_PROVIDER_CITY
ORDER BY
	TOTAL_CLAIMS DESC
	LIMIT 5
)
union
select * from
(
SELECT
	P.NPI,
	PR.NPPES_PROVIDER_CITY,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIMS
FROM
	PRESCRIBER PR
	INNER JOIN PRESCRIPTION P USING (NPI)
WHERE
	PR.NPPES_PROVIDER_CITY = 'CHATTANOOGA'
GROUP BY
	P.NPI,
	PR.NPPES_PROVIDER_CITY
ORDER BY
	TOTAL_CLAIMS DESC
	LIMIT 5
)) order by 2,3 DESC;

--4.Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT
	FP.COUNTY AS COUNTY,
	ROUND(AVG(OD.OVERDOSE_DEATHS), 2) AS AVG_DEATHS
FROM
	OVERDOSE_DEATHS OD
	INNER JOIN FIPS_COUNTY FP ON TO_CHAR(OD.FIPSCOUNTY, 'FM99999') = FP.FIPSCOUNTY
GROUP BY
	FP.COUNTY
ORDER BY
	AVG_DEATHS DESC;

-- 5a. Write a query that finds the total population of Tennessee.

SELECT
	SUM(POP.POPULATION) AS TOTAL_POPULATION
FROM
	POPULATION POP
	INNER JOIN FIPS_COUNTY FS USING (FIPSCOUNTY)
WHERE
	FS.STATE = 'TN';


SELECT
	SUM(POP.POPULATION) AS TOTAL_POPULATION
FROM
	POPULATION POP
	INNER JOIN FIPS_COUNTY FS USING (FIPSCOUNTY)
WHERE
	FS.STATE = 'TN';
	
--b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
-- its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT
	COUNTY,
	TOTAL_POPULATION,
	ROUND(TOTAL_POPULATION / STATE_POPULATION * 100, 2) AS PER_TN_POP
FROM
	(
		SELECT
			STATE,
			COUNTY,
			TOTAL_POPULATION,
			SUM(TOTAL_POPULATION) OVER (
				PARTITION BY
					STATE
			) AS STATE_POPULATION
		FROM
			(
				SELECT
					FS.STATE AS STATE,
					COUNTY,
					SUM(POP.POPULATION) AS TOTAL_POPULATION
				FROM
					POPULATION POP
					INNER JOIN FIPS_COUNTY FS USING (FIPSCOUNTY)
				WHERE
					FS.STATE = 'TN'
				GROUP BY
					FS.STATE,
					COUNTY
			)
	);

