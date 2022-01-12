#' Extract secondary calibrations from a `phylo` or `multiPhylo`
#' object with branch lengths proportional to time using [geiger::congruify.phylo()]
#'
#' @description This function extracts node ages for each taxon
#'   pair in `input`. It applies the congruification method described in Eastman et al.
#'   (2013) "Congruification: support for time scaling large phylogenetic trees".
#'   Methods in Ecology and Evolution, 4(7), 688-691, <doi:10.1111/2041-210X.12051>
#'   to create a matrix of suitable secondary calibrations for each taxon pair.
#'   Congruification is implemented with the function [geiger::congruify.phylo()].
#' @param input A `phylo` or `multiPhylo` object with branch lengths
#' proportional to time.
#' @param each Boolean, default to `FALSE`: all calibrations are returned in
#' the same `data.frame`. If `TRUE`, calibrations from each chronogram are returned
#' in separate data frames.
#' @return An object of class `datelifeCalibrations`, i.e., a `data.frame` (if
#'   `each = FALSE`) or a list of `data.frames` (if `each = TRUE`) of secondary
#'   calibrations, for each pair of taxon names in `input`. The attribute
#'   `chronograms` stores the `input` data from which the calibrations were extracted.
#' @export
extract_calibrations_phylo <- function(input = NULL,
                                       each = FALSE) {
  chronograms <- NULL
  if (inherits(input, "multiPhylo")) {
    chronograms <- input
    xx <- sapply(chronograms, "[", "edge.length")
    xx <- unname(sapply(xx, is.null))
    if (all(xx)) {
      warning("trees in 'multiPhylo' input have no branch lengths. \n There are no calibrations to return!")
      return(NA)
    }
    if (any(xx)) {
      ii <- which(xx)
      warning("Some trees in 'multiPhylo' input have no branch lengths.")
      message(
        "Dropping tree(s) ",
        paste(ii, collapse = " - "),
        " out of the analysis."
      )
      chronograms <- chronograms[which(!xx)]
    }
  }
  if (inherits(input, "phylo")) {
    if (is.null(input$edge.length)) {
      warning("'input' tree has no branch lengths. \n There are no calibrations to return!")
      return(NA)
    }
    chronograms <- list(input)
  }
  if (is.null(chronograms)) {
    stop("'input' must be a 'phylo' or 'multiPhylo' object with branch length sproportional to time.")
  }
  if (each) {
    calibrations <- vector(mode = "list")
  } else {
    # we cannot set an empty data frame because nrow depends on the number of nodes available on each tree
    calibrations <- data.frame()
  }
  for (i in seq(length(chronograms))) {
    chronograms[[i]]$tip.label <- gsub(" ", "_", chronograms[[i]]$tip.label) # the battle will never end!
    local_df <- suppressWarnings(
      geiger::congruify.phylo(
        reference = chronograms[[i]],
        target = chronograms[[i]],
        scale = NA,
        ncores = 1
      )
    )$calibrations
    # suppressedWarnings bc of warning message when running
    # geiger::congruify.phylo(reference = chronograms[[i]], target = chronograms[[i]], scale = NA)
    # 		Warning message:
    # In if (class(stock) == "phylo") { :
    # the condition has length > 1 and only the first element will be used
    local_df$reference <- names(chronograms)[i]
    if (each) {
      calibrations <- c(calibrations, list(local_df))
    } else {
      if (i == 1) {
        calibrations <- local_df
      } else {
        calibrations <- rbind(calibrations, local_df)
      }
    }
  }
  if (each) {
    names(calibrations) <- names(chronograms)
  }
  attr(calibrations, "chronograms") <- chronograms
  # TODO check that class data frame is also preserved. Might wanna do:
  class(calibrations) <- c(class(calibrations), "calibrations")
  # instead of using structure()
  return(calibrations)
}

#' Extract secondary calibrations from a given `datelifeResult` object
#'
#' @inherit extract_calibrations_phylo description
#' @details The function calls summarize_datelife_result()] with
#' `summary_format = "phylo_all" to go from a `datelifeResult` object
#' to a `phylo` or `multiPhylo` object that will be passed to
#' [extract_calibrations_phylo()].
#'
#' @param input A `datelifeResult` object.
#' @inheritParams get_all_calibrations
#' @inherit extract_calibrations_phylo return
#' @export
extract_calibrations_dateliferesult <- function(input = NULL,
                                                each = FALSE) {
  phyloall <- suppressMessages(
    summarize_datelife_result(
      datelife_result = input,
      summary_format = "phylo_all"
    )
  )
  res <- extract_calibrations_phylo(
    input = phyloall,
    each = each
  )
  attr(res, "datelife_result") <- input
  class(res) <- c("data.frame", "datelifeCalibrations")
  return(res)
}

#' Search and extract secondary calibrations for a given character
#' vector of taxon names
#'
#' @description The function searches DateLife's local
#' database of phylogenetic trees with branch lengths proportional to time
#' (chronograms) with [datelife_search()], and extracts available node ages
#' for each pair of given taxon names with [extract_calibrations_phylo()].
#'
#' @details The function calls [datelife_search()]
#' with `summary_format = "phylo_all"` to get all chronograms in the database
#' containing at least two taxa in `input`, and generates a `phylo`
#' or `multiPhylo` object object that will be passed to
#' [extract_calibrations_phylo()].
#'
#' @param input A character vector of taxon names.
#' @inheritParams get_all_calibrations
#' @inherit extract_calibrations_phylo return
#' @export
get_calibrations_vector <- function(input = NULL,
                                    each = FALSE) {
  # TODO: is_datelife_search_input function or any type of input format checking
  # function to trap the case were input is a list
  phyloall <- datelife_search(
    input = input,
    summary_format = "phylo_all"
  )

  res <- extract_calibrations_phylo(
    input = phyloall,
    each = each
  )
  attr(res, "datelife_result") <- attributes(phyloall)$datelife_result
  class(res) <- c("data.frame", "datelifeCalibrations")
  return(res)
}
#' Search and extract available secondary calibrations from a given
#' `datelifeQuery` object
#'
#' @param datelife_query A `datelifeQuery` object.
#' @inheritParams get_all_calibrations
#' @inherit get_calibrations_vector description details
#' @inherit extract_calibrations_phylo return
#' @export
get_calibrations_datelifequery <- function(datelife_query = NULL,
                                           each = FALSE) {
  if (suppressMessages(!is_datelife_query(datelife_query))) {
    stop("'datelife_query' is not a 'datelifeQuery' object.")
  }
  phyloall <- datelife_search(
    input = datelife_query,
    summary_format = "phylo_all"
  )
  res <- extract_calibrations_phylo(
    input = phyloall,
    each = each
  )
  attr(res, "datelife_result") <- attributes(phyloall)$datelife_result
  class(res) <- c("data.frame", "datelifeCalibrations")
  return(extract_calibrations_phylo(
    input = phyloall,
    each = each
  ))
}