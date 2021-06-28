
# Build the package
# Build, install and restart
if("diagCovCoagExposures" %in% (.packages())){
  detach("package:diagCovCoagExposures", unload=TRUE)}
library(CohortDiagnostics)
library(diagCovCoagExposures)

#install.packages("renv") # if not already installed, install renv from CRAN
renv::activate() # activate renv
renv::restore() # this should prompt you to install the various packages required for the study

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(plotly)
library(magrittr)

# Optional: specify where the temporary files will be created:
options(andromedaTempFolder = "C/andromedaTemp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "...",
                                                                server ="..." ,
                                                                user = "...",
                                                                password = "...",
                                                                port = "...",
                                                                pathToDriver = "...")

oracleTempSchema <- NULL
cdmDatabaseSchema <- "..."
cohortDatabaseSchema <- "..."
cohortTable <- "..."
databaseId <- "..."
databaseName <- "..."
databaseDescription <- "..."

outputFolder<-"..."

# Use this to run the cohorttDiagnostics. The results will be stored in the diagnosticsExport subfolder of the outputFolder. This can be shared between sites.
diagCovCoagExposures::runCohortDiagnostics(connectionDetails = connectionDetails,
                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                     cohortDatabaseSchema = cohortDatabaseSchema,
                                     cohortTable = cohortTable,
                                     oracleTempSchema = oracleTempSchema,
                                     outputFolder = outputFolder,
                                     databaseId = databaseId,
                                     databaseName = databaseName,
                                     databaseDescription = databaseDescription,
                                     createCohorts = TRUE,
                                     runInclusionStatistics = TRUE,
                                     runIncludedSourceConcepts = TRUE, 
                                     runOrphanConcepts = TRUE,
                                     runTimeDistributions = TRUE,
                                     runBreakdownIndexEvents = TRUE,
                                     runIncidenceRates = TRUE,
                                     runCohortOverlap = TRUE,
                                     runCohortCharacterization = TRUE,
                                     runTemporalCohortCharacterization = TRUE,
                                     minCellCount = 5)

# To view the results:
# Optional: if there are results zip files from multiple sites in a folder, this merges them, which will speed up starting the viewer:
CohortDiagnostics::preMergeDiagnosticsFiles(file.path(outputFolder, "diagnosticsExport"))
# Use this to view the results. Multiple zip files can be in the same folder. If the files were pre-merged, this is automatically detected: 
CohortDiagnostics::launchDiagnosticsExplorer(file.path(outputFolder, "diagnosticsExport"))


