comp <- function(x) Filter(Negate(is.null), x)

ma_base <- function() "https://api.labs.cognitive.microsoft.com"

ma_HTTP <- function(path, args, key, method = "GET", body = list(),
                    encode = "form", ctype = NULL, parse = TRUE, ...) {
  key <- check_key(key)
  cli <- crul::HttpClient$new(
    url = ma_base(),
    headers = list(
      `Ocp-Apim-Subscription-Key` = key
    )
  )
  if (!is.null(ctype)) cli$headers <- c(cli$headers, `Content-Type` = ctype)
  res <- switch(
    method,
    GET = cli$get(path, query = args, ...),
    POST = cli$post(path, query = args, body = body, encode = encode, ...)
  )
  raise_for_status2(res)
  txt <- res$parse("UTF-8")
  if (parse) jsonlite::fromJSON(txt, flatten = TRUE) else txt
}

check_key <- function(x) {
  if (!is.null(x)) {
    return(x)
  } else {
    x <- Sys.getenv("MICROSOFT_ACADEMIC_KEY", "")
    if (nchar(x) == 0) {
      stop("API key needed for Microsoft Academic, see ?microdemic-package")
    } else {
      return(x)
    }
  }
}

dfrbl <- function(x) {
  (xxxxx <- data.table::setDF(
    data.table::rbindlist(x, use.names = TRUE, fill = TRUE)
  ))
}

assert <- function(x, y) {
  if (!is.null(x)) {
    if (!class(x) %in% y) {
      stop(deparse(substitute(x)), " must be of class ",
           paste0(y, collapse = ", "), call. = FALSE)
    }
  }
}

raise_for_status2 <- function(res) {
  if (res$status_code >= 300) {
    er_lst <- tryCatch(
      parse_error_msg(res),
      error = function(e) httpcode::http_code(res$status_code)
    )
    er_msg <- sprintf(
      "%s (HTTP %s)\nExplanation: %s",
      res$status_code, er_lst$message, er_lst$explanation
    )
    stop(er_msg, call. = FALSE)
  }
}

parse_error_msg <- function(res) {
  txt <- res$parse("UTF-8")
  er_vec <- jsonlite::fromJSON(txt)
  return(list(
    message = er_vec$Message,
    explanation = er_vec$InnerException$Message
  ))
}
