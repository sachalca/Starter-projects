

-- Global information
Select *
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) 
order by 3, 4


-- Selecting data
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
where total_cases is not null or new_cases is not null or total_deaths is not null
order by 1, 2


-- Cases vs deaths in US
Select location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) and location = 'United States'
order by 1, 2


-- Total cases vs population in France
Select location, date, total_cases, population, (cast(total_cases as float)/cast(population as float))*100 as InfectedPercentage
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) and location = 'France'
order by 1, 2


-- Countries with highest infection rates
Select location, population, MAX(cast(total_cases as int)) as HighestInfectionCount, 
	MAX(cast(total_cases as float)/cast(population as float))*100 as InfectedPercentage
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) 
Group by location, population
order by InfectedPercentage desc


-- Countries with highest infection rates at different dates 
Select location, population, date, MAX(cast(total_cases as int)) as HighestInfectionCount, 
	MAX(cast(total_cases as float)/cast(population as float))*100 as InfectedPercentage
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) 
Group by location, population, date
order by InfectedPercentage desc


-- Countries with highest death count
Select location, MAX(cast(total_deaths as int)) as HighestDeaths
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) and continent is not null
Group by location
order by HighestDeaths desc


-- Countries with highest death count by continent
Select location, continent, MAX(cast(total_deaths as int)) as HighestDeaths
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) and continent is not null
Group by location, continent
order by continent, HighestDeaths desc


-- Countries with highest death count in North America
Select location, MAX(cast(total_deaths as int)) as HighestDeaths
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) and continent = 'North America'
Group by location
order by HighestDeaths desc


-- Using a subquery to find the death count in North America
Select 'North America' as Continent, SUM(HighestDeaths) as TotalDeaths
From 
(
	Select location, MAX(cast(total_deaths as int)) as HighestDeaths
	From PortfolioProject..CovidDeaths
	where (total_cases is not null or new_cases is not null or total_deaths is not null) and continent = 'North America'
	Group by location
)as SubQuery


-- Using a subquery to find the continents with highest death count
Select continent, SUM(HighestDeaths) as TotalDeaths
From 
(
	Select location, continent, MAX(cast(total_deaths as int)) as HighestDeaths
	From PortfolioProject..CovidDeaths
	where (total_cases is not null or new_cases is not null or total_deaths is not null) and continent is not null
	Group by location, continent
)as SubQuery
group by continent
order by TotalDeaths desc


-- Death percentage in the world every week
Select date, SUM(new_cases) as NewCasesWorld, SUM(cast(new_deaths as int)) as NewDeathsWorld, 
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathsPercentage
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) and continent is not null
group by date
order by 1, 2


-- Total death percentage
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
	(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathsPercentage
From PortfolioProject..CovidDeaths
where (total_cases is not null or new_cases is not null or total_deaths is not null) and continent is not null
order by 1, 2


-- Population vs vaccination with rolling count of vaccination
Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, d.date) as TotalVacToDate
From PortfolioProject..CovidDeaths d
Join PortfolioProject..CovidVaccinations v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null and d.location = 'albania'
order by 1,2,3


-- Using CTE to determine vaccination percentage. 
-- Please note that the number is not accurate due to the fact that one person can be vaccinated multiple times.
-- This simply demonstrates my ability to use CTEs.
With PopvsVac(continent, location, date, population, new_vaccinations, TotalVacToDate)
as
(
	Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
		SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, d.date) as TotalVacToDate
	From PortfolioProject..CovidDeaths d
	Join PortfolioProject..CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
	where d.continent is not null
)
Select *, (TotalVacToDate/population)*100 as vaccinationPercentage
From PopvsVac
order by 1, 2, 3



-- Using a temp table to determine vaccination percentage. 
-- Please note that the number is not accurate due to the fact that one person can be vaccinated multiple times.
-- This simply demonstrates my ability to use temp tables.
Drop table if exists #VaccinationPercentage
Create table #VaccinationPercentage
(
	Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, 
	New_vaccinations numeric, TotalVacToDate numeric
)

Insert into #VaccinationPercentage
	Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
		SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, d.date) as TotalVacToDate
	From PortfolioProject..CovidDeaths d
	Join PortfolioProject..CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
	where d.continent is not null

Select *, (TotalVacToDate/population)*100 as vaccinationPercentage
From #VaccinationPercentage
order by 1, 2, 3



-- Creating view
USE PortfolioProject;
GO

Create view VaccinationPercentage as
	Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
		SUM(cast(v.new_vaccinations as bigint)) OVER (Partition by d.location order by d.location, d.date) as TotalVacToDate
	From PortfolioProject..CovidDeaths d
	Join PortfolioProject..CovidVaccinations v
		On d.location = v.location
		and d.date = v.date
	where d.continent is not null


