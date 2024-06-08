## ----include = FALSE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set( #nolint
  collapse = TRUE,
  comment = "#>"
)
old <- options(width = 200L)

## ----echo = -1----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
setwd(tempdir())
old_log <- loggit2::set_logfile(logfile = "logfile.log")
loggit2::loggit(
  log_lvl = "DEBUG",
  log_msg = "This message will be logged to `logfile.log`."
)


loggit2::loggit(
  log_lvl = "DEBUG",
  log_msg = "This message will be logged to `otherlogfile.log`.",
  logfile = "otherlogfile.log"
)


loggit2::with_loggit(logfile = "logfile2.log", {
  base::message("This message will be logged to `logfile2.log`.")
})

loggit2::set_logfile(old_log)

## ----error = TRUE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
old_log_lvl <- loggit2::set_log_level("INFO")
loggit2::message("This message will be logged, since the log level is INFO.")
loggit2::loggit(
  log_lvl = "DEBUG",
  log_msg = "This message will not be logged, since the log level is INFO."
)
loggit2::loggit(
  log_lvl = "DEBUG", "This message will be logged because the log level is ignored.",
  ignore_log_level = TRUE
)
loggit2::warning(
  "This warning message will not be logged, since .loggit = FALSE.",
  .loggit = FALSE
)

loggit2::set_log_level("ERROR")
loggit2::warning("This warning will not be logged, since the log level is set to ERROR.")
loggit2::message("This message will be logged, since .loggit = TRUE.", .loggit = TRUE)
loggit2::stop("This error message will be logged because the log level is set to ERROR.")

loggit2::with_loggit(log_level = "DEBUG", {
  base::message("This message will be logged because the log level is set to DEBUG.")
})

loggit2::set_log_level(old_log_lvl)

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
old_echo <- loggit2::set_echo(FALSE)
loggit2::message("This message will not be logged, but it will be output to the console.")
loggit2::message("This message will be logged and output to the console.", echo = TRUE)

loggit2::set_echo(TRUE, confirm = FALSE)
loggit2::message("This message will be logged and output to the console.")
loggit2::message("This message will be logged, but it will not be echoed.", echo = FALSE)

loggit2::with_loggit(echo = FALSE, {
  base::message("This message will be logged, but it will not be output to the console.")
})

loggit2::set_echo(old_echo)

## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
old_ts <- loggit2::set_timestamp_format("%H:%M:%S")
loggit2::message("This message will be logged with a timestamp in the format HH:MM:SS.")

loggit2::set_timestamp_format(old_ts)

## ----include = FALSE----------------------------------------------------------
options(old)

