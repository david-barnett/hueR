#' Create (named) single-hue gradient palette
#'
#' @description
#' Function to create create HCL palette of `n` colours based on fixed `hue`.
#' Luminance monotonically increases, whilst chroma increases and then decreases.
#'
#' If names provided: return named palette of same length as unique(names),
#' with `n` distinct colours (if n is left null, all colours are unique)
#'
#' If the `hue` value is left as NULL, a function will be returned,
#' which can generate a palette when given a `hue` values and `n` and/or `names`
#'
#' @details
#' Uses `colorspace::sequential_hcl()` with a fixed hue to generate palettes.
#'
#' The palette generated will be roughly centered around the midpoint of
#' the luminance range, and at approximately the maximum chroma.
#'
#' Note that edges of generated palette are cut off so min and max luminances
#' are never returned.
#' This is because they are, by default, too dark/light to be distinguishable
#' across hues.
#'
#' @param hue numeric hue value, or NULL to return palette function
#' @param names names for palette, or NULL for unnamed palette of length `n`
#' @param n number of unique shades in palette
#' @param minChroma minimum Chroma for palette
#' @param maxChroma maximum Chroma for palette
#' @param minLum minimum luminance for palette
#' @param maxLum maximum luminance for palette
#' @param power power used by `colorspace::sequential_hcl()`
#'
#' @return vector of colours, possibly named, or a function
#' @export
#'
#' @examples
#' pal <- huePal(hue = 120, n = 9)
#' scales::show_col(pal, borders = NA)
#
#  # named palette
#  huePal(hue = 120, names = letters[1:9])
#
#  # same palettes, just named and not named (all should be TRUE)
#' huePal(hue = 120, names = letters[1:9]) == huePal(hue = 120, n = 9)
#'
#' # more names than shades --> repeats last shade
#' extendedPal <- huePal(hue = 120, names = letters[1:16], n = 9)
#' scales::show_col(extendedPal, borders = NA)
huePal <- function(hue = NULL,
                   names = NULL,
                   n = NULL,
                   minChroma = 40,
                   maxChroma = 150,
                   minLum = 10,
                   maxLum = 98,
                   power = 0.8) {
  # https://adv-r.hadley.nz/function-factories.html#forcing-evaluation
  force(minChroma)
  force(maxChroma)
  force(minLum)
  force(maxLum)

  # create a hue palette function with palette generating parameters set
  huePalFun <- function(hue,
                        names = NULL,
                        n = NULL
  ) {

    if (identical(names, NULL) && identical(n, NULL)) {
      stop("`names` vector and/or `n` value must be provided to huePal!")
    } else if (!identical(names, NULL)) {
      names <- unique(as.character(names))
      # check at least as many names as n, else set or reduce n
      if (identical(n, NULL) || length(names) < n) n <- length(names)
    }

    # make a palette with 2 more values than needed
    fullRangePal <- colorspace::sequential_hcl(
      n = n + 2, h = hue, c = c(minChroma, maxChroma, NA),
      l = c(minLum, maxLum), power = power,
    )
    # trim off very dark and almost white ends
    trimmedPal <- fullRangePal[2:(n + 1)]

    # add any names given, extending palette if necessary by repeating last val
    if (!identical(names, NULL)) {
      if (length(names) > n){
        trimmedPal <- rep_last(trimmedPal, length.out = length(names))
      }
      names(trimmedPal) <- names
    }
    return(trimmedPal)
  }

  if (identical(hue, NULL)) {
    # return palette generating function if no hue given
    return(huePalFun)
  } else {
    # otherwise evaluate function to return a palette, if hue given
    return(huePalFun(hue, names = names, n = n))
  }
}

