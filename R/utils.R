#' Merge values of vector after first n unique values
#'
#' @param x vector, character or factor typically
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
#' gapminder::gapminder %>%
#' dplyr::filter(year < 1970) %>%
#'   dplyr::pull(country) %>%
#'   as.character() %>%
#'   mergeAfterN(10) %>%
#'   head(50)
#'
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
