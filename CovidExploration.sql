
/*

Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


-- Checking if my dataset imported correct


SELECT COUNT(iso_code)
FROM coviddeaths;

SELECT COUNT(iso_code)
FROM covidvaccinations;

SELECT COUNT(DISTINCT(iso_code))
FROM coviddeaths;

SELECT COUNT(DISTINCT(iso_code))
FROM covidvaccinations;

SELECT *
FROM coviddeaths
ORDER BY location, date ;

SELECT *
FROM covidvaccinations
ORDER BY location, date ;



-- Select data that I am going to be using.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY location, date ;



-- Looking at Total Cases VS Total Deaths.
-- Shows the likelihood of dying if you contract covid in Greece

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE location like '%Greec%'
-- or "WHERE location = 'Greece' 
ORDER BY location, date ;



-- Looking at Total Cases VS Population
-- Shows what percentage of Population got Covid in Greece

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM coviddeaths
WHERE location like '%Greec%'
ORDER BY location, date ;



-- Looking at Countries with Highest Inflection Rates compared to Population

SELECT location,population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected 
FROM coviddeaths 
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;




-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths 
WHERE location <> "Europe" AND location <> "North America" AND location <> "European Union" AND location <> "South America" AND location <> "Asia"
GROUP BY location
ORDER BY TotalDeathCount DESC;




-- Showing Total Deaths, Percentage of Deaths (deaths/Population) and Mortality Rate (deaths/cases) by Continent

SELECT location, MAX(total_deaths) AS TotalDeathCount, (MAX(total_deaths)/population)*100 AS PercentageOfDeaths
FROM coviddeaths 
WHERE location = "Europe" OR location = "North America" OR location = "European Union" OR location = "South America" OR location = "Asia" OR location = "Africa" OR location = "Oceania"
-- WHERE continent = '' 
GROUP BY location, population
ORDER BY TotalDeathCount DESC;

SELECT location, (MAX(total_deaths)/MAX(total_cases))*100 AS CovidMortalityRate
FROM coviddeaths 
WHERE continent = '' 
-- WHERE location = "Europe" OR location = "North America" OR location = "European Union" OR location = "South America" OR location = "Asia" OR location = "Africa" OR location = "Oceania"
GROUP BY location
ORDER BY CovidMortalityRate DESC;





-- GLOBAL NUMBERS


-- -- Day to Day

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 AS CovidMortalityRate    
FROM coviddeaths    
WHERE continent <> ''    
GROUP BY date
ORDER BY 1,2;



-- -- -- -- In Greece

SELECT cast(date as date), total_cases, total_deaths, (total_deaths/total_cases)*100 AS CovidMortalityRate    
FROM coviddeaths    
WHERE location = 'Greece'
Group By date, total_cases, total_deaths 
ORDER BY 1,2;



-- -- Overall Cases, Deaths and Mortality Rate

SELECT  SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 AS CovidMortalityRate    
FROM coviddeaths    
WHERE continent <> ''      
ORDER BY 1,2;



-- -- -- -- In Greece

SELECT  SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 AS CovidMortalityRate    
FROM coviddeaths    
WHERE location = 'Greece'     
ORDER BY 1,2;




-- LOOKING AT POPULATION VS VACCINATIONS 


-- -- Join coviddeaths table with covidvaccinations table

SELECT *
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;



 -- Showing the course of vaccinations by country
 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea 
JOIN covidvaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date 
WHERE dea.continent <> '' ;



-- Showing the course of vaccinations (%) by country, USING CTE

WITH PopVSVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea 
JOIN covidvaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date 
WHERE dea.continent <> '' 
-- ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVSVac;



-- Showing the course of vaccinations(%) in GREECE, USING CTE

WITH PopVSVacGr (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea 
JOIN covidvaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date 
WHERE dea.location = 'Greece'
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVSVacGr;




-- Showing the course of vaccinations(%) by country, USING TEMPORARY TABLE

DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccination NUMERIC,
RollingPeopleVaccinated NUMERIC
);
 
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations as FLOAT) ,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea 
JOIN covidvaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date 
WHERE dea.continent <> '' ;

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PercentPopulationVaccinated;




-- Showing the course of vaccinations(%) in GREECE, USING TEMPORARY TABLE

DROP TABLE IF EXISTS PercentPopulationVaccinatedGRE;

CREATE TEMPORARY TABLE PercentPopulationVaccinatedGRE
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccination NUMERIC,
RollingPeopleVaccinated NUMERIC
);
 
INSERT INTO PercentPopulationVaccinatedGRE
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS FLOAT) ,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea 
JOIN covidvaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date 
WHERE dea.location = 'Greece';

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PercentPopulationVaccinatedGRE;


-- CREATING VIEWS TO STORE DATA FOR LATTER VISUALIZATIONS


-- 1.
CREATE VIEW  PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations as FLOAT) ,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea 
JOIN covidvaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date 
WHERE dea.continent <> '' ;

SELECT *
FROM percentpopulationvaccinated;



-- 2.
CREATE VIEW MortalityRateGRE AS
SELECT cast(date as date), total_cases, total_deaths, (total_deaths/total_cases)*100 AS CovidMortalityRate    
FROM coviddeaths    
WHERE location = 'Greece'
Group By date, total_cases, total_deaths 
ORDER BY 1,2;

SELECT *
FROM MortalityRateGRE;



-- 3.
CREATE VIEW ContinentTableTotals AS
SELECT location, MAX(total_deaths) AS TotalDeathCount, (MAX(total_deaths)/population)*100 AS PercentageOfDeaths
FROM coviddeaths 
WHERE location = "Europe" OR location = "North America" OR location = "European Union" OR location = "South America" OR location = "Asia" OR location = "Africa" OR location = "Oceania"
-- WHERE continent = '' 
GROUP BY location, population
ORDER BY TotalDeathCount DESC;

SELECT *
FROM ContinentTableTotals;
