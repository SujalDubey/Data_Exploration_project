select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4


--Testing the tables
select location,date,total_cases,new_cases,total_deaths,population
from PortfolioProject..CovidDeaths
order by 1,2

--looking at Total Cases vs Total Deaths
-- shows likelihood of dying if you contact in covid in your country
select location,date,total_cases,population,new_cases,total_deaths,(total_deaths/total_cases)*100 as Deathpercentage
from PortfolioProject..CovidDeaths
where location like'%India%'
and continent is not null
order by 1,2

-- looking at countries with highest infection rate compared to popluation

select location,population,max(total_cases) as highestinfectioncount, max((total_cases/population)*100) as percentpopulationinfected
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by percentpopulationinfected desc

-- Below showing countries with highest death count per population
-- it will print the countries withh highest number of deaths since the beginning of Covid -19
select location,max(cast(total_deaths as int)) as Totaldeathcount 
from PortfolioProject..CovidDeaths
where continent is not null 
group by location
order by Totaldeathcount DESC

--showing continents with highest death as per population

select continent,max(cast(total_deaths as int)) as Totaldeathcount 
from PortfolioProject..CovidDeaths
where continent is not null --it will not read the data whose continent value is null
group by continent
order by Totaldeathcount,population DESC

--Global Numbers
-- Below are the world daily total New Cases, total deaths and death percentage. 
select date, sum(new_cases) as newtotalcases_in_world, sum(cast(new_deaths as float)) as newtotaldeaths_in_world,  (sum(cast(new_deaths as float))/sum(new_cases))
*100 as deathpercentage 
from PortfolioProject..CovidDeaths
where continent is not null 
group by date
order by 1,2

--total new cases and total deaths with its percentage
select  sum(new_cases) as newtotalcases_in_world, sum(cast(new_deaths as float)) as newtotaldeaths_in_world,  (sum(cast(new_deaths as float))/sum(new_cases))
*100 as deathpercentage 
from PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2


-- total population vs total people new vaccinations

select dea.continent,dea.location,dea.date ,dea.population,vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..Covidvaccinations vac
on dea.location = vac.location
and dea.date= vac.date
where dea.continent is not null
order by 2,3

-- this tells us about how many people in INDIA got vaccinated on each day
select dea.continent,dea.location,dea.date ,dea.population,vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..Covidvaccinations vac
on dea.location = vac.location
and dea.date= vac.date
--where dea.continent is not null
and dea.location like '%India%'
order by 2,3

-- total people vaacinated each day grouped by there location
select dea.continent,dea.location,dea.date ,dea.population,vac.new_vaccinations
,sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) 
as rollingpeoplevaccinated 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..Covidvaccinations vac
on dea.location = vac.location
and dea.date= vac.date
where dea.continent is not null
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3*
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

--Temporary Table

drop table if exists #percentpeoplevaccinated
create table #percentpeoplevaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)
insert into #percentpeoplevaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 as peoplevaccinated_vs_population
From #percentpeoplevaccinated

-- create view to store data for tableau visualizations 

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
