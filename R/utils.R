#' Merge values of vector after first n unique values
#'
#' @param x vector
#' @param n number of unique values/levels to keep
#' @param other name of new value/level to replace excess values with
#'
#' @return vector
#' @export
#'
#' @examples
#' library(dplyr)
#' letters %>% mergeAfterN(15)
#' LETTERS %>% mergeAfterN(10, other = "?")
#'
#' ## Real data example ##
#' # works for factors too
#' gapminder::gapminder %>%
#'   dplyr::filter(year < 1970) %>%
#'   dplyr::pull(country) %>%
#'   mergeAfterN(10) %>%
#'   head(50)
mergeAfterN <- function(x, n, other = "other"){

  # if x is factor, add `other` as a level
  if (is.factor(x)) levels(x) <- c(levels(x), other)

  # get unique values
  uniq <- unique(x)

  # ensure n not longer than uniq length
  n <- min(n, length(uniq))

  # identify values to keep (not replace)
  keepers <- uniq[seq_len(n)]

  # replace all other values with `other` value
  x[!x %in% keepers] <- other

  return(x)
}

#' Repeat last value in vector to create longer vector
#'
#' Helper function
#'
#' @param x vector
#' @param length.out desired length of vector
#' @export
#' @examples
#' rep_last(letters[1:10], length.out = 15)
rep_last <- function(x, length.out){
  stopifnot(is.vector(x))
  len <- length(x)
  xEnd <- x[len]
  repLength <- length.out - len
  out <- c(x, rep_len(xEnd, length.out = repLength))
  return(out)
}
