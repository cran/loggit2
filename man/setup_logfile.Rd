% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setup.R
\name{setup_logfile}
\alias{setup_logfile}
\title{Set up the logfile for the application}
\usage{
setup_logfile()
}
\value{
Invisible the previous log file path.
}
\description{
This function retrieves the logfile path from the environment variable "FILE_LOGGIT2".
If the environment variable is set, it will be used as the logfile path.
If the environment variable is not set, the logfile path will be set to the default value.
}
\keyword{internal}
