select *
from portfolio.dbo.covid_deaths
order by 3,4

select *
from portfolio.dbo.CovidVaccinations
order by 3,4

-- Select Data we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio..covid_deaths
Order by 1,2

-- Looking at total cases vs total death
-- shows the likelihood of diying if you contract covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Portfolio..covid_deaths
where location like '%India%'
Order by 1,2


-- lookin at total cases vs population
-- Shows what percentage of population got covid

select location, date, total_cases, total_deaths, population, (total_cases/population)*100 as CountryPositivityRate
FROM Portfolio..covid_deaths
--where location like '%India%'
where continent is not null
Order by 1,2

-- what country has the highest infection rate compared to population

select	Location, Population, MAX(total_cases) as HighestInfesctionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From Portfolio..covid_deaths
Group by Location, population
Order by 1,2


-- showing countries with highest death  count by population

select	Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio..covid_deaths
where continent is null
-- (I have done (is null) it should be is not null but coz there was wrong data we had to use is null )
Group by Location
Order by TotalDeathCount Desc


-- LET'S Break things down by continent




-- Showing continenets with the highest death count
select	continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio..covid_deaths
where continent is not null
Group by continent
Order by TotalDeathCount Desc

-- Global NUMBERS

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathRateGlobal 
FROM Portfolio..covid_deaths
--where location like '%India%'
where continent is not null
--group by date
Order by 1,2

-- joining the two tables


Select *
from portfolio..covid_deaths dea
join portfolio..covidvaccinations vac
-- dea and vac above is alias (as)
 on  dea.location  = vac.location 
 and dea.date = vac.date

 -- looking total population vs vaccination

 Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
 -- if you put just 'date' above it will give you an error coz there are two dates in the table thats why we have to specify which date we are talking about
from portfolio..covid_deaths dea
join portfolio..covidvaccinations vac
-- dea and vac above is alias (as)
 on  dea.location  = vac.location 
 and dea.date = vac.date
where dea.continent is not null
 order by 2,3

 -- partition and rolling count of the vaccination

  Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
 -- if you put just 'date' above it will give you an error coz there are two dates in the table thats why we have to specify which date we are talking about
  , sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
from portfolio..covid_deaths dea
join portfolio..covidvaccinations vac
-- dea and vac above is alias (as)
 on  dea.location  = vac.location 
 and dea.date = vac.date
where dea.continent is not null
 order by 2,3

 -- USE CTE

 With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
 as
 (
 Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
 -- if you put just 'date' above it will give you an error coz there are two dates in the table thats why we have to specify which date we are talking about
  , sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
from portfolio..covid_deaths dea
join portfolio..covidvaccinations vac
-- dea and vac above is alias (as)
 on  dea.location  = vac.location 
 and dea.date = vac.date
where dea.continent is not null
 --order by 2,3
 )

Select *, (Rolling_People_Vaccinated/Population)*100
From PopVsVac

-- TEMP TABLE

Drop  table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population NUMERIC,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, population
 -- if you put just 'date' above it will give you an error coz there are two dates in the table thats why we have to specify which date we are talking about
  , sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
from portfolio..covid_deaths dea
join portfolio..covidvaccinations vac
-- dea and vac above is alias (as)
 on  dea.location  = vac.location 
 and dea.date = vac.date
where dea.continent is not null
 --order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualization in Power Bi

 Create View PercentPopulationVaccinated as
 Select dea.continent, dea.location, dea.date, population
 -- if you put just 'date' above it will give you an error coz there are two dates in the table thats why we have to specify which date we are talking about
  , sum(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
from portfolio..covid_deaths dea
join portfolio..covidvaccinations vac
-- dea and vac above is alias (as)
 on  dea.location  = vac.location 
 and dea.date = vac.date
where dea.continent is not null
 --order by 2,3