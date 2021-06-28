# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of diagCovCoagExposures
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Format and check code ---------------------------------------------------
OhdsiRTools::formatRFolder()
OhdsiRTools::checkUsagePackage("diagCovCoagExposures")
OhdsiRTools::updateCopyrightYearFolder()

# Create manual -----------------------------------------------------------
shell("rm extras/diagCovCoagExposures.pdf")
shell("R CMD Rd2pdf ./ --output=extras/diagCovCoagExposures.pdf")


# Insert cohort definitions from ATLAS into package -----------------------
library(ROhdsiWebApi)
# library(CirceR)
library(dplyr)
library(tidyr)
library(here)
library(readr)
Sys.setenv(TZ='GMT')



# Atlas.ids<-c("9", "13", "14", "15", "16")
Atlas.ids<-c("38", "39", "16", "14") #
baseurl<-Sys.getenv("DB_baseurl")
webApiUsername<-Sys.getenv("DB_webApiUsername")
webApiPassword<-Sys.getenv("DB_webApiPassword")
authorizeWebApi(baseurl,
                authMethod="ad",
                webApiUsername = webApiUsername,
                webApiPassword = webApiPassword)

#trace(getDefinitionsMetadata, edit=TRUE)

bring.in.cohorts<-function(){
  
  # remove any existing cohorts 
  unlink("inst/cohorts/*")
  unlink("inst/sql/sql_server/*")
  unlink("inst/settings/*")
  
  if(file.exists(here("inst/cohorts/InclusionRules.csv"))==FALSE){
    write.csv(data.frame(cohortName=character(),ruleSequence=character(),ruleName=character(),cohortId=character()),
              row.names = FALSE,
              "inst/cohorts/InclusionRules.csv")}
  
  # CohortsToCreate csv 
  # atlasId	atlasName	cohortId	name
  AllCohorts<-getCohortDefinitionsMetaData(baseurl)
  # all cohorts in Atlas
  CohortsToCreate<-AllCohorts %>% 
    filter(id %in% Atlas.ids) %>% 
    select(id, name) %>% 
    rename(atlasId=id,
           atlasName=name) %>% 
    mutate(cohortId=atlasId,
           name=atlasName)
  write.csv(CohortsToCreate,
            row.names = FALSE,
            "inst/settings/CohortsToCreate.csv")
  # trace(insertSqlForCohortTableInPackage, edit=TRUE)
  ROhdsiWebApi::insertCohortDefinitionSetInPackage(fileName = "inst/settings/CohortsToCreate.csv",
                                                   baseUrl = baseurl,
                                                   insertTableSql = TRUE,
                                                   insertCohortCreationR = FALSE,
                                                   generateStats = TRUE)
}
bring.in.cohorts()


# Store environment in which the study was executed -----------------------
OhdsiRTools::insertEnvironmentSnapshotInPackage("diagCovCoagExposures")

# -------
library(dplyr)
CohortsToCreate <- readr::read_csv("inst/settings/cohort_names.csv")
CohortsToCreate <- CohortsToCreate %>% 
  mutate(Name=paste0(ID, ") ", Name)) %>% 
  mutate(Name=factor(Name,
         levels=Name))

load(paste0(outputFolder,"/diagnosticsExport","/PreMerged.RData"))
cohort<-cohort %>% 
  select(cohortId, json, sql,webApiCohortId) %>% 
  left_join(CohortsToCreate %>% 
  select(SIDIAP_ATLAS_ID, Name) %>% 
  rename(cohortId=SIDIAP_ATLAS_ID) %>% 
  rename(cohortName=Name)) %>% 
  select(cohortId, cohortName, json, sql,webApiCohortId) 
rm(CohortsToCreate)  
save.image(
     file=paste0(outputFolder,"/diagnosticsExport","/PreMerged.RData"))
rm(list=ls())


#### ------
library(here)
library(SqlRender)
library(stringr)

# Cohorts -----
# Because of some inconsistencies in bringing in diagnosis cohorts from atlas, 
# here I specify the full set of codes to be used

# Diagnosis cohorts
diag_template_sql<-readSql(here("extras", "template sql", "COVID19 diagnosis template.sql"))
# broad
diag_broad_codes<-"756031,756039,3655975,3655976,3655977,3656667,3656668,3656669,3661405,3661406,3661408,3661631,3661632,3661748,3661885,3662381,3663281,37310254,37310283,37310284,37310286,37310287,37311060,37311061,320651,439676,4100065,37016927,37396171,40479642,700296,700297,704995,704996,37311060, 45763724, 37310268, 37310282"
diag_broad_sql<-str_replace(diag_template_sql, "@codes",
                            diag_broad_codes)
fileConn<-file(here("inst", "sql", "sql_server", "COVID19 diagnosis broad.sql"))
writeLines(diag_broad_sql, fileConn)
close(fileConn)
# narrow
diag_narrow_codes<-"756031,756039,3655975,3655976,3655977,3656667,3656668,3656669,3661405,3661406,3661408,3661631,3661632,3661748,3661885,3662381,3663281,37310254,37310283,37310284,37310286,37310287,37311061,700296,700297,704995,704996"
diag_narrow_sql<-str_replace(diag_template_sql, "@codes",
                             diag_narrow_codes)
fileConn<-file(here("inst", "sql", "sql_server", "COVID19 diagnosis narrow.sql"))
writeLines(diag_narrow_sql, fileConn)
close(fileConn)
