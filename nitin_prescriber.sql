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
	MAX(
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
