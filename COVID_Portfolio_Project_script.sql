
Select * FROM PortfolioProject..CovidDeaths
ORDER BY 3, 4

--Select * FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4

-- Select Data

Select location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

--Total cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0 
        ELSE (total_deaths / total_cases) * 100 
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

SELECT 
    location, 
    date,
	population,
    total_cases, 
   (total_cases / population) * 100  AS CovidPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;

-- Select countries with highest infection Rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Showing Countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing contintents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Finding out the global total cases and total deaths

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 as DeathPercentage
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY total_cases, total_deaths

-- Looking at Total Population vs Vaccinations
-- Population vs Vaccination CTE

WITH PopvsVac 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeople
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingVaccinatedPeople / Population) * 100 AS RollingVacPercentage
FROM PopvsVac

-- TEMP TABLE to perform aggregate function in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinatedPeople bigint
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeople

From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, 
   (RollingVaccinatedPeople / Population) * 100 AS RollingVacPercentage
FROM #PercentPopulationVaccinated

-- Creating View to store data for visualizations later

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeople
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL