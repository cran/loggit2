#' Get log as `data.frame`
#'
#' Returns a `data.frame` containing all the logs in the provided `ndjson` log file.
#'
#' @inherit read_ndjson return params
#'
#' @details `read_logs()` returns a `data.frame` with the empty character columns "timestamp", "log_lvl" and "log_msg"
#' if the log file has no entries.
#'
#' @examples
#' \dontrun{
#'   read_logs()
#'
#'   read_logs(last_first = TRUE)
#' }
#' @export
read_logs <- function(logfile = get_logfile(), unsanitize = TRUE, last_first = FALSE) {

  base::stopifnot("Log file does not exist" = file.exists(logfile))

  log <- read_ndjson(logfile, unsanitize = unsanitize, last_first = last_first)

  if (nrow(log) == 0L) {
    log <- data.frame(timestamp = character(), log_lvl = character(), log_msg = character(), stringsAsFactors = FALSE)
  }

  return(log)
}


#' Rotate log file
#'
#' Truncates the log file to the line count provided as `rotate_lines`.
#'
#' @param rotate_lines The number of log entries to keep in the logfile.
#' @param logfile Log file to truncate.
#'
#' @return Invisible `NULL`.
#'
#' @examples
#' \dontrun{
#'   rotate_logs()
#'
#'   rotate_logs(rotate_lines = 0L)
#'
#'   rotate_logs(rotate_lines = 1000L, logfile = "my_log.log")
#' }
#' @export
rotate_logs <- function(rotate_lines = 100000L, logfile = get_logfile()) {
  base::stopifnot(rotate_lines >= 0L, "Log file does not exist" = file.exists(logfile))
  if (rotate_lines == 0L) {
    cat(NULL, file = logfile)
    return(invisible(NULL))
  }
  log_df <- readLines(logfile)
  if (length(log_df) <= rotate_lines) {
    return(invisible(NULL))
  }
  log_df <- log_df[seq.int(from = length(log_df) - rotate_lines + 1L, length.out = rotate_lines)]
  write(log_df, logfile, append = FALSE)
}

#' Find the Call of a Parent Function in the Call Hierarchy
#'
#' This function is designed to inspect the call hierarchy and identify the call of a parent function.
#' Any wrapper environments above the global R environment that some IDEs cause are ignored.
#'
#' @return Returns the call of the parent function, or `NULL` if no such call is found.
#'
#' @keywords internal
# Some parts cannot be tested in testthat
find_call <- function() {
  parents <- sys.parents()
  # If there are fewer than 3 calls, it means there's no parent call to return
  if (length(parents) <= 2L) return(NULL) # nocov
  # Ignore any wrapper environments above the global R environment
  # For example necessary in JetBrains IDEs
  id <- match(0L, parents, nomatch = 0L)
  if (id >= length(parents) - 1L) return(NULL) # nocov
  return(sys.call(-2L))
}

#' Write log to csv file
#'
#' Creates a csv file from the ndjson log file.
#'
#' @param file Path to write csv file to.
#' @param ... Additional arguments to pass to `utils::write.csv()`.
#' @inheritParams read_logs
#'
#' @return Invisible `NULL`.
#'
#' @details Unescaping of special characters can lead to unexpected results. Use `unsanitize = TRUE` with caution.
#'
#' @examples
#' \dontrun{
#'   convert_to_csv("my_log.csv")
#'
#'   convert_to_csv("my_log.csv", logfile = "my_log.log", last_first = TRUE)
#' }
#'
#' @export
convert_to_csv <- function(file, logfile = get_logfile(), unsanitize = FALSE, last_first = FALSE, ...) {
  if (!requireNamespace(package = "utils", quietly = TRUE)) {
    stop("Package 'utils' is not available. Please install it, if you want to use this function.") # nocov
  }

  log <- read_logs(logfile = logfile, unsanitize = unsanitize, last_first = last_first)

  utils::write.csv(log, file = file, row.names = FALSE, ...)

  return(invisible(NULL))
}

#' Get Log Level Name
#'
#' @param level Log level as integer.
#'
#' @return The log level name.
#'
#' @keywords internal
get_lvl_name <- function(level) {
  base::stopifnot(is.integer(level), level >= 0L, level <= 4L)
  lvl <- c("NONE", "ERROR", "WARN", "INFO", "DEBUG")
  lvl[level + 1L]
}

#' Get Log Level Integer
#'
#' @param level Log level as character.
#'
#' @return The log level integer.
#'
#' @keywords internal
get_lvl_int <- function(level) {
  base::stopifnot(is.character(level))
  idx <- base::match(level, c("NONE", "ERROR", "WARN", "INFO", "DEBUG"))
  base::stopifnot("Log level not 'NONE', 'ERROR', 'WARN', 'INFO' or 'DEBUG'" = !is.na(idx))
  return(idx - 1L)
}

#' Convert Log Level Input to Integer
#'
#' @param level Log level as character or numeric.
#'
#' @return The log level integer.
#'
#' @keywords internal
convert_lvl_input <- function(level) {
  if (is.numeric(level)) {
    level <- as.integer(level)
    base::stopifnot(level >= 0L, level <= 4L)
  } else {
    level <- get_lvl_int(level)
  }
  level
}

#' Convert Call to String
#'
#' Converts a call object to a string and optionally determines the full call stack.
#'
#' @param call Call object.
#' @param full_stack Include the full call stack?
#' @param default_cutoff Number of calls to cut from the end of the call stack if no matching call is found.
#'
#' @return Deparsed call as string.
#'
#' @details The full call stack can only be determined if the call is in the current context. The default cutoff is 4
#' because the only known case is an primitive error in `with_loggit()` which adds 4 calls to the stack.
#'
#' @keywords internal
call_2_string <- function(call, full_stack = FALSE, default_cutoff = 4L) {
  if (is.null(call)) return(NA_character_)
  call_str <- deparse1(call)
  if (full_stack) {
    # Truncate the call stack after the `call`
    raw_call_stack <- sys.calls()
    call_stack <- vapply(raw_call_stack, deparse1, FUN.VALUE = character(1L))
    call_match <- match(call_str, rev(call_stack))
    call_match_pos <- length(call_stack)
    if (!is.na(call_match)) call_match_pos <- call_match_pos - call_match + 1L
    # Shorten to 150 characters
    call_stack <- vapply(call_stack, substr, FUN.VALUE = character(1L), start = 1L, stop = 150L)
    call_stack <- gsub("\n", "", call_stack, fixed = TRUE)
    call_stack <- gsub("\\s+", " ", call_stack)
    call_stack <- paste0(call_stack, vapply(raw_call_stack, get_file_loc, FUN.VALUE = character(1L)))
    # Ignore any wrapper environments above the global R environment
    # For example necessary in JetBrains IDEs
    parents <- sys.parents()[seq_len(call_match_pos)]
    base_id <- match(0L, parents, nomatch = 0L)
    parents <- parents[base_id:call_match_pos]
    funcs <- lapply(parents, sys.function)
    pkgs <- vapply(funcs, get_package_name, FUN.VALUE = character(1L))
    pkgs[[1L]] <- ""
    call_stack <- paste0(call_stack[base_id:call_match_pos], pkgs)
    if (is.na(call_match)) {
      # Cut the last `default_cutoff` calls from the stack
      call_stack <- call_stack[seq_len(max(length(call_stack) - default_cutoff, 0L))]
      # And add the call to the end
      call_stack <- c(call_stack, paste("Original Call: ", call_str))
    }
    call_str <- paste(call_stack, collapse = "\n")
  }
  return(call_str)
}

#' Get file location
#'
#' Get the file location of a call object.
#'
#' @param x Call object.
#'
#' @return The file location as string.
#'
#' @keywords internal
get_file_loc <- function(x) {
  # This code is adapted from .traceback() in base R
  srcloc <- if (!is.null(srcref <- attr(x, "srcref"))) {
    srcfile <- attr(srcref, "srcfile")
    paste0(" [at ", basename(srcfile[["filename"]]), "#", srcref[[1L]], "]")
  } else {
    ""
  }
}

#' Get package name
#'
#' Get the package name of a function.
#'
#' @param x Function.
#'
#' @return The package location as string.
#'
#' @keywords internal
get_package_name <- function(x) {
  if (is.primitive(x)) {
    return(" [in base]")
  }

  name <- environmentName(environment(x))
  if (nchar(name) == 0L || name %in% c("R_EmptyEnv", "R_GlobalEnv")) {
    return("")
  } else {
    return(paste0(" [in ", name, "]"))
  }
}
