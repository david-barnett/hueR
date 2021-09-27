#' Make HCL palette for groups with multiple levels
#'
#' Makes a palette for dataframe where levels within groups defined by the
#' `group` variable share the same hue but different shades, levels within
#' group based on the `shade` variable.
#'
#' @param df dataframe with at least two variables (treated as categories)
#' @param group variable name used to assign hues
#' @param shade variable name used to assign colour shades of same hue
#' @param maxShades maximum allowed number of shades per hue
#' @param hues hues available to use for unique levels of `group` variable
#' @param huePalFun
#' function used to create single hue palette for levels of `shade` variable
#' @param manual
#' NULL or manual additions or replacements for returned palette
#' in the style of `c(name = value, ....)`
#'
#' @return named character vector of colours
#' @export
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#'
#' # sort countries, within continents, by average population
#' sortedSummary <- gapminder::gapminder %>%
#'   group_by(continent, country) %>%
#'   summarise(AvPop = mean(pop, na.rm = TRUE), .groups = "keep") %>%
#'   group_by(continent) %>%
#'   arrange(.by_group = TRUE, desc(AvPop))
#'
#' # create palettes
#' countryPal6 <- sortedSummary %>%
#'   hueGroupPal(group = "continent", shade = "country", maxShades = 6)
#'
#'
#' # plot population per year
#' gapminder::gapminder %>%
#'   ggplot(aes(
#'     x = factor(year), y = pop,
#'     # setting as factor with levels in correct order ensures ordering of bars
#'     fill = factor(country, levels = names(countryPal6))
#'   )) +
#'   geom_col() +
#'   guides(fill = "none") +
#'   # setting manual scale of course sets correct colours
#'   scale_fill_manual(values = countryPal6) +
#'   ggfittext::geom_fit_text(
#'     aes(ymin = 0, ymax = pop, label = country),
#'     position = "stack", colour = "white"
#'   ) +
#'   theme_classic() +
#'   coord_cartesian(expand = FALSE)
#'
#'
#' # plot population per year as share of world total that year
#' gapminder::gapminder %>%
#'   group_by(year) %>%
#'   mutate(popPerc = pop/sum(pop, na.rm = TRUE)) %>%
#'   ggplot(aes(
#'     x = factor(year), y = popPerc,
#'     # setting as factor with levels in correct order ensures ordering of bars
#'     fill = factor(country, levels = names(countryPal6))
#'   )) +
#'   geom_col() +
#'   guides(fill = "none") +
#'   # setting manual scale of course sets correct colours
#'   scale_fill_manual(values = countryPal6) +
#'   ggfittext::geom_fit_text(
#'     aes(ymin = 0, ymax = popPerc, label = country),
#'     position = "stack", colour = "white"
#'   ) +
#'   theme_classic() +
#'   coord_cartesian(expand = FALSE)
#'
#'
#' # plot with modified palette
#' countryPal6alt <- sortedSummary %>%
#'   hueGroupPal(group = "continent", shade = "country", maxShades = 6,
#'               hues = hueSet(start = 0))
#'
#' gapminder::gapminder %>%
#'   group_by(year) %>%
#'   mutate(popPerc = pop/sum(pop, na.rm = TRUE)) %>%
#'   # dplyr::filter(year > 1970) %>%
#'   ggplot(aes(
#'     x = factor(year), y = popPerc,
#'     # setting as factor with levels in correct order ensures ordering of bars
#'     fill = factor(country, levels = names(countryPal6alt))
#'   )) +
#'   geom_col() +
#'   guides(fill = "none") +
#'   # setting manual scale of course sets correct colours
#'   scale_fill_manual(values = countryPal6alt) +
#'   ggfittext::geom_fit_text(grow = TRUE,
#'                            aes(ymin = 0, ymax = popPerc, label = country),
#'                            position = "stack", colour = "white"
#'   ) +
#'   theme_classic() +
#'   coord_cartesian(expand = FALSE)
hueGroupPal <- function(df,
                        group,
                        shade,
                        maxShades = 5,
                        # otherShadeNamer = function(g) paste0(g, "_other"),
                        hues = hueSet(),
                        huePalFun = huePal(),
                        manual = c("Other" = "lightgrey")) {
  # get name of hue group variable
  if (length(group) > 1) {
    stop("`hue` must be either:
           \n - character name of a variable in `df`
           \n - list of length 1, named after variable in `df`")
  }
  if (is.list(group)) hueVar <- names(group) else hueVar <- group

  # check if hueVar and shade are variables
  if (!hueVar %in% colnames(df)) {
    stop('"', hueVar, '" is not a variable in `df`')
  }
  if (!shade %in% colnames(df)) {
    stop('"', shade, '" is not a variable in `df`')
  }

  # get unique values in hue naming variable
  hueVarLevels <- unique(df[[hueVar]])

  # ensure hueVar is a factor (important for order after split())
  df[[hueVar]] <- factor(df[[hueVar]], levels = hueVarLevels)

  if (length(hueVarLevels) > length(hues)) {
    stop(
      "Fewer `hues` provided unique values in grouping variable:",
      "\n - Grouping variable '", hueVar, "' has: ",
      length(hueVarLevels), " levels",
      "\n - Only", length(hues), " hues were provided in `hues`"
    )
  }

  # get hues (numeric values)
  hues <- hues[seq_len(length(hueVarLevels))]

  # assign hues variable values as names
  names(hues) <- hueVarLevels

  # overwrite some hue name-value pairs if list given
  if (is.list(group)) {
    hues[names(group[[hueVar]])] <- group[[hueVar]]
  }

  # split data by group
  dfList <- split.data.frame(df[, c(hueVar, shade)], f = df[[hueVar]])
  names(dfList) <- hueVarLevels
  #
  # # merge excess levels above maxShades
  # for (name in names(dfList)) {
  #   dfList[[name]][[shade]] <- mergeAfterN(
  #     x = dfList[[name]][[shade]], n = maxShades, other = otherShadeNamer(name)
  #   )
  # }

  # create named single hue gradient palette for each hue
  palettes <- lapply(names(hues), function(hueName) {
    huePalFun(hue = hues[hueName], names = dfList[[hueName]][[shade]],
              n = maxShades)
  })

  # combine and check palettes
  palette <- unlist(palettes)
  if (anyDuplicated(names(palette))) {
    warning(
      "Invalid named palette created, with duplicated names: \n",
      "Values of shade variable: '", shade, "' were duplicated",
      "\nacross levels of hue group variable: '", hueVar, "'"
    )
  }

  # add or replace manually specified values in palette
  palette[names(manual)] <- manual

  return(palette)
}

# mycars <- mtcars %>%
#   dplyr::mutate(
#     dplyr::across(c(cyl, vs, am, gear, carb), .fns = as.character),
#     cyl_carb = interaction(cyl, carb, sep = "_"),
#     carb_gear = interaction(carb, gear, sep = "_")
#   )
#
#
# library(dplyr)
# library(ggplot2)
#
# mycars %>%
#   count(carb, carb_gear) %>%
#   arrange(carb, n) %>%
#   mutate(vehicle = "car",
#          carb_gear = factor(carb_gear, levels = unique(carb_gear))) %>%
#   ggplot(aes(x = vehicle, y = n, fill = carb_gear)) +
#   geom_col() +
#   scale_fill_manual(
#     values = hueGroupPal(
#       df = mycars, group = "carb", shade = "carb_gear"
#     )
#   )
#
# hueGroupPal(df = mycars, group = "carb", shade = "carb_gear")
