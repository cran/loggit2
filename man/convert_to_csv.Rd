% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{convert_to_csv}
\alias{convert_to_csv}
\title{Write log to csv file}
\usage{
convert_to_csv(
  file,
  logfile = get_logfile(),
  unsanitize = FALSE,
  last_first = FALSE,
  ...
)
}
\arguments{
\item{file}{Path to write csv file to.}

\item{logfile}{Path to log file to read from.}

\item{unsanitize}{Should escaped special characters be unescaped?}

\item{last_first}{Should the last log entry be the first row of the data frame?}

\item{...}{Additional arguments to pass to \code{utils::write.csv()}.}
}
\value{
Invisible \code{NULL}.
}
\description{
Creates a csv file from the ndjson log file.
}
\details{
Unescaping of special characters can lead to unexpected results. Use \code{unsanitize = TRUE} with caution.
}
\examples{
\dontrun{
  convert_to_csv("my_log.csv")

  convert_to_csv("my_log.csv", logfile = "my_log.log", last_first = TRUE)
}

}
