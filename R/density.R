# Stan blocks & included chunks

#' Write the Stan code lines related with Density constants.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
constants          <- function(x) { UseMethod("constants", x) }

#' Write the Stan code lines related with Density generated quantities.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
generated          <- function(x) { UseMethod("generated", x) }

#' Write the Stan code lines related with Density parameters.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
parameters         <- function(x) { UseMethod("parameters", x) }

#' Write the Stan code lines related with Density log likelihood.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
logLike            <- function(x) { UseMethod("logLike", x) }

#' Write the Stan code lines related with Density no log likelihood.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
noLogLike          <- function(x) { UseMethod("noLogLike", x) }

#' Write the Stan code lines related with Density link function.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
link               <- function(x) { UseMethod("link", x) }

#' Write the Stan code lines related with Density free parameters.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
freeParameters     <- function(x) { UseMethod("freeParameters", x) }

#' Write the Stan code lines related with Density fixed parameters.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
fixedParameters    <- function(x) { UseMethod("fixedParameters", x) }

#' Write the Stan code lines related with Density priors.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A character string.
prior              <- function(x) { UseMethod("prior", x) }

# Other (not directly related to Stan code)

#' Create a representation of a probability mass or density function for a
#' continuous univariate random variable.
#'
#' It can be used to specify either a
#' prior distribution for a model parameter or a likelihood function for an
#' observation model.
#'
#' @param name A character string with the name of the density.
#' @param ordered (optional) A logical setting an increasing ordering constraint on any univariate parameter and any unconstrained parameter vector. Ordered simplices (e.g. \code{\link{Categorical}}, \code{\link{Multinomial}}, \code{\link{Dirichlet}}) are currently not implemented. Most useful for location parameters to break symmetries and fix label switching as shown in Betancourt (2017). It defaults to unordered parameters.
#' @param equal (optional) A logical setting whether the parameter takes the same value in every hidden state, i.e. the parameter is shared across states. It defaults to unequal parameters.
#' @param bounds (optional) A list with two elements specifying the lower and upper bound for the parameter space. Use either a fixed value for a finite bound or NULL for no bounds. It defaults to an unbounded parameter space.
#' @param trunc (optional) A list with two elements specifying the lower and upper bound for the domain of the density function. Use either a fixed value for a finite bound or NULL for no truncation. It defaults to an unbounded domain.
#' @param k (optional) The number of the hidden state for which this density should be used. This argument is mostly for internal use: you should not use it unless you are acquainted with the internals of this software.
#' @param r (optional) The dimension of the observation vector dimension for which this density should be used. This argument is mostly for internal use: you should not use it unless you are acquainted with the internals of this software.
#' @param param (optional) The name of the parameter. This argument is mostly for internal use: you should not use it unless you are acquainted with the internals of this software.
#' @param ...  Other arguments for the density.
#' @return A \code{\link{Density}} object.
#' @references
#' Betancourt, Michael (2017) Identifying Bayesian Mixture Models \emph{Stan Case Studies} \bold{Volume 4}. \href{https://mc-stan.org/users/documentation/case-studies/identifying_mixture_models.html}{Link}.
#' @family Density
#' @note The examples are merely illustrative and should not be taken for prior choice recommendations. If you are looking for some, you may start with \href{https://github.com/stan-dev/stan/wiki/Prior-Choice-Recommendations}{Stan's Prior Choice Recommendation}.
Density <- function(name, ordered = NULL, equal = NULL, bounds = list(NULL, NULL), trunc  = list(NULL, NULL), k = NULL, r = NULL, param = NULL, ...) {
  # Evaluate nested expressions (Densities)
  dots <- list(...)
  for (i in seq_along(dots)) {
    if (is.language(dots[[i]])) {
      dots[[i]] <- eval(dots[[i]])
    }
  }

  densityParams <- c(dots, list(ordered = ordered, equal = equal, bounds = bounds, trunc = trunc, k = k, r = r, param = param))

  # # Check for generic parameters
  # check_list(dots[["bounds"]], 2, "bounds")
  # check_list(dots[["trunc"]], 2, "trunc")

  structure(
    c(list(name = name), densityParams),
    class = c(name, "Density")
  )
}

#' Explain a Density object in human readable format.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @param print An optional logical indicating whether the description should be printing out.
#' @return A character string.
explain_density            <- function(x, print = TRUE) { UseMethod("explain_density", x) }

#' @keywords internal
#' @inherit explain_density
explain_density.Density <- function(x, print = TRUE) {
  freeParam  <- getFreeParameters(x)
  fixedParam <- getFixedParameters(x)

  free_parameter_declaration <- function(x) {
    # Early stop if the density is not part of a model (no Stan Code available)
    if (is.null(x$k) | is.null(x$r)) {
      return(rep("", length(getFreeParameters(x))))
    }

    trimws(
      gsub(
        "(.+);(.+)",
        "\\1",
        split_return_line(
          freeParameters(x)
        )
      )
    )
  }

  strBounds <- paste(
    if (is.null(x$bounds[[1]])) { "(-infty" } else { sprintf("[%s", x$bounds[[1]]) },
    if (is.null(x$bounds[[2]])) { "infty)"  } else { sprintf("%s]", x$bounds[[2]]) },
    sep = ", "
  )

  strTrunc  <- paste(
    if (is.null(x$trunc[[1]])) { "(-infty" } else { sprintf("[%s", x$trunc[[1]]) },
    if (is.null(x$trunc[[2]])) { "infty)"  } else { sprintf("%s]", x$trunc[[2]]) },
    sep = ", "
  )

  strFreeParam <-
    if (is.null(freeParam) || length(freeParam) == 0 || unique(freeParam) == "") {
      NULL
    } else {
      l <- lapply(1:length(freeParam), function(p) {
        paramName    <- names(freeParam)[p]
        strStructure <- free_parameter_declaration(x)[p]
        strExplain   <- explain_density(freeParam[[paramName]], print = FALSE)

        e <- sprintf(
          "\n\t\t%-5s : %s\n\t\t%s",
          paramName, strStructure, strExplain
        )

        e <- gsub("\t", "\t\t\t", e)
        e <- gsub("^\n\t\t\t\t\t\t", "\n\t\t", e)
        e
      })

      paste(l, collapse = ", ")
    }

  strFixedParam <-
    if (is.null(fixedParam) || length(fixedParam) == 0 || unique(fixedParam) == "") {
      NULL
    } else {
      l <- lapply(names(fixedParam), function(paramName) {
        sprintf(
          "%s = %s",
          paramName, numeric_to_stan(fixedParam[[paramName]])
        )
      })

      paste(l, sep = "", collapse = ", ")
    }

  block1 <-
    sprintf(
      "%sDensity: %s %s",
      if (is.null(x$param)) { "Variable " } else { "Prior " },
      x$name,
      if (all(sapply(x$trunc, is.null))) { strBounds } else { strTrunc }
    )

  block2 <-
    if (!is.null(freeParam) && length(freeParam) != 0)
      sprintf(
        "\tFree parameters: %d (%s)%s",
        length(freeParam),
        paste(names(freeParam), collapse = ", "),
        strFreeParam
      )

  block3 <-
    if (!is.null(fixedParam) && length(fixedParam) != 0)
      sprintf(
        # "\tFixed parameters: %d (%s)",
        "\t\t\tFixed parameters: %d (%s)",
        length(fixedParam),
        strFixedParam
      )

  strOut <- collapse(c(block1, block2, block3))

  if (print)
    cat(strOut)

  invisible(strOut)
}

#' Return the names of both free and fixed parameters in the Density object.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A vector of character strings.
#' @examples
#' \dontrun{
#' getParameterNames(
#'   Gaussian(
#'     mu    = Gaussian(mu = 0, sigma = 10),
#'     sigma = 1
#'   )
#' )
#' }
getParameterNames  <- function(x) { UseMethod("getParameterNames", x) }

#' @keywords internal
#' @inherit getParameterNames
getParameterNames.Density <- function(x) {
  warning(
    sprintf(
      "getParameterNames not implemented for the %s density.",
      x$name
    )
  )
}

#' Return the names of the free parameters in the Density object.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A vector of character strings.
#' @examples
#' \dontrun{
#' getFreeParameters(
#'   Gaussian(
#'     mu    = Gaussian(mu = 0, sigma = 10),
#'     sigma = 1
#'   )
#' )
#' }
getFreeParameters  <- function(x) { UseMethod("getFreeParameters", x) }

#' @keywords internal
#' @inherit getFreeParameters
getFreeParameters.Density <- function(x) {
  l <-
    sapply(
      getParameterNames(x),
      function(paramName) {
        if (is.Density(x[[paramName]])) {
          eval(x[[paramName]])
        }
      },
      simplify = FALSE
    )

  l <- l[!sapply(l, is.null)]

  if (is.empty(l)) {
    return(list())
  } else {
    dl <-
      if (length(l) == 1 ) {
        `+.Density`(l)
      } else {
        Reduce(`+.Density`, l)
      }
    names(dl) <- names(l)
    return(dl)
  }
}

#' Return the names of the fixed parameters in the Density object.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return A vector of character strings.
#' @examples
#' \dontrun{
#' getFixedParameters(
#'   Gaussian(
#'     mu    = Gaussian(mu = 0, sigma = 10),
#'     sigma = 1
#'   )
#' )
#' }
getFixedParameters <- function(x) { UseMethod("getFixedParameters", x) }

#' @keywords internal
#' @inherit getFixedParameters
getFixedParameters.Density <- function(x) {
  l <-
    sapply(
      getParameterNames(x),
      function(paramName) {
        if (!is.Density(x[[paramName]])) {
          x[[paramName]]
        }
      },
      simplify = FALSE
    )

  l[!sapply(l, is.null)]
}

#' Check if it is a Density object for the transition model.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return TRUE if the object is meant for transition models, FALSE otherwise.
is.link            <- function(x) { UseMethod("is.link", x) }

#' @keywords internal
#' @inherit is.link
is.link.Density                     <- function(x) { FALSE }

#' Check if it is a Density object for discrete random variables.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return TRUE if the object is meant to represent a discrete random variables, FALSE otherwise.
is.discrete        <- function(x) { UseMethod("is.discrete", x) }

#' @keywords internal
#' @inherit is.discrete
is.discrete.Density                 <- function(x) { FALSE }

#' Check if it is a Density object for multivariate random variables.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return TRUE if the object is meant to represent a multivariate random variables, FALSE otherwise.
is.multivariate    <- function(x) { UseMethod("is.multivariate", x) }

#' @keywords internal
#' @inherit is.multivariate
is.multivariate.Density             <- function(x) { FALSE }

#' Check if it is a Density object for a parameter with equal value across hidden states.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return TRUE if the object is meant to represent a parameter shared across states, FALSE otherwise.
is.equal    <- function(x) { UseMethod("is.equal", x) }

#' @keywords internal
#' @inherit is.equal
is.equal.Density             <- function(x) { !is.null(x$equal) && x$equal }

#' Check if it is a Density object for an ordered set of parameters.
#'
#' @keywords internal
#' @param x A \code{\link{Density}} object.
#' @return TRUE if the object is meant to represent an ordered set of parameters, FALSE otherwise.
is.ordered    <- function(x) { UseMethod("is.ordered", x) }

#' @keywords internal
#' @inherit is.ordered
is.ordered.Density             <- function(x) { !is.null(x$ordered) && x$ordered }

#' Check if it is a \code{\link{Density}} object.
#'
#' @keywords internal
#' @param x An object.
#' @return TRUE if the object is a Density object, FALSE otherwise.
is.Density <- function(x) {
  inherits(x, "Density")
}

#' @keywords internal
#' @inherit block_data
block_data.Density <- function(x, noLogLike) {
  if (noLogLike) {
    "// No observation vector"
  } else {
    "matrix[T, R] y;  // observations"
  }
}

#' @keywords internal
#' @inherit noLogLike
noLogLike.Density <- function(x) {
  sprintf("loglike[%s][t] = 1;", x$k)
}

#' @keywords internal
#' @inherit is.TVInitial
is.TVInitial.Density                <- function(x) { FALSE }

#' @keywords internal
#' @inherit is.FixedInitial
is.FixedInitial.Density             <- function(x) { FALSE }

#' @keywords internal
#' @inherit is.TVTransition
is.TVTransition.Density             <- function(x) { FALSE }

#' @keywords internal
#' @inherit is.FixedTransition
is.FixedTransition.Density          <- function(x) { FALSE }

#' @keywords internal
#' @inherit constants
constants.Density                   <- function(x) { ""    }

#' @keywords internal
#' @inherit link
link.Density                        <- function(x) { ""    }

#' Create a representation of a probability mass or density function for a
#' continuous multivariate random variable. It can be used to specify either a
#' prior distribution for a model parameter or a likelihood function for an
#' observation model.
#'
#' @keywords internal
#' @inherit Density
#' @family MultivariateDensity
MultivariateDensity <- function(name, ...) {
  x <- Density(name, ...)
  class(x) <- append(class(x), "MultivariateDensity", 1)
  x
}

#' Create a representation of a probability mass or density function for a
#' discrete univariate random variable. It can be used to specify either a
#' prior distribution for a model parameter or a likelihood function for an
#' observation model.
#'
#' @keywords internal
#' @inherit Density
#' @family DiscreteDensity
DiscreteDensity <- function(name, ...) {
  x <- Density(name, ...)
  class(x) <- append(class(x), "DiscreteDensity", 1)
  x
}

#' @keywords internal
#' @inherit is.discrete
is.discrete.DiscreteDensity         <- function(x) { TRUE  }

#' @keywords internal
#' @inherit block_data
block_data.DiscreteDensity <- function(x, noLogLike) {
  if (noLogLike) {
    "// No observation vector"
  } else {
    "int y[T, R];     // observations"
  }
}

#' Create a representation of a probability mass or density function for a
#' discrete multivariate random variable. It can be used to specify either a
#' prior distribution for a model parameter or a likelihood function for an
#' observation model.
#'
#' @keywords internal
#' @inherit Density
#' @family MultivariateDiscreteDensity
MultivariateDiscreteDensity <- function(name, ...) {
  x <- DiscreteDensity(name, ...)
  class(x) <- append(class(x), "MultivariateDensity", 1)
  x
}

#' @keywords internal
#' @inherit is.multivariate
is.multivariate.MultivariateDensity <- function(x) { TRUE  }

#' Create a representation of a probability mass or density function for a
#' univariate random variable that may be used only to specify a prior
#' distribution for a model parameter.
#'
#' @keywords internal
#' @inherit Density
#' @family PriorOnlyDensity
PriorOnlyDensity <- function(name, ...) {
  x <- Density(name, ...)
  class(x) <- append(class(x), "PriorOnlyDensity", 1)
  x
}

#' Create a representation of a probability mass or density function for a
#' multivariate random variable that may be used only to specify a prior
#' distribution for a model parameter.
#'
#' @keywords internal
#' @inherit Density
#' @family PriorOnlyDensity
PriorOnlyMultivariateDensity <- function(name, ...) {
  x <- MultivariateDensity(name, ...)
  class(x) <- append(class(x), "PriorOnlyDensity", 1)
  x
}

#' @keywords internal
#' @inherit freeParameters
freeParameters.PriorOnlyDensity     <- function(x) { ""    }

#' @keywords internal
#' @inherit fixedParameters
fixedParameters.PriorOnlyDensity    <- function(x) { ""    }

#' @keywords internal
#' @inherit generated
generated.PriorOnlyDensity          <- function(x) { ""    }

#' @keywords internal
#' @inherit getFreeParameters
getFreeParameters.PriorOnlyDensity  <- function(x) { ""    }

#' @keywords internal
#' @inherit getFreeParameters
getParameterNames.PriorOnlyDensity  <- function(x) { ""    }

#' @keywords internal
#' @inherit logLike
logLike.PriorOnlyDensity            <- function(x) { ""    }

#' Create a representation of a link function that may be used only to specify
#' a transition model.
#'
#' @keywords internal
#' @inherit Density
#' @family LinkDensity
LinkDensity <- function(name, ...) {
  x <- Density(name, ...)
  class(x) <- append(class(x), "LinkDensity", 1)
  x
}

#' @keywords internal
#' @inherit is.link
is.link.LinkDensity                 <- function(x) { TRUE  }

# DensityList -------------------------------------------------------------
#' Append two Density objects.
#'
#' @aliases + DensityList
#' @usage x + y
#' @param x A Density object (e.g. \code{\link{Gaussian}})
#' @param y A Density object (e.g. \code{\link{Gaussian}})
#' @return A DensityList object.
#' @examples Gaussian(0, 1) + Gaussian(0, 1)
`+.Density` <- function(x, y = NULL) {
  if (!is.null(y) & !is.Density(y)) {
    stop("Error: Please use the plus sign to join two Density object")
  }

  l <-
    if (is.null(y)) {
      if (is.DensityList(x)) { x } else { list(x) }
    } else {
      if (is.DensityList(x)) { c(x, list(y)) } else { list(x, y) }
    }
  structure(l, class = c("DensityList"))
}

#' Check if it is a \code{\link{DensityList}} object.
#'
#' @keywords internal
#' @param x An object.
#' @return TRUE if the object is a DensityList object, FALSE otherwise.
is.DensityList <- function(x) {
  all(sapply(x, is.Density))
}

#' @keywords internal
#' @inherit explain_density
explain_density.DensityList <- function(x, print = TRUE){
  lapply(x, explain_density, print = print)
}

#' @keywords internal
#' @inherit is.discrete
is.discrete.DensityList <- function(x) {
  all(sapply(x, is.discrete))
}

#' @keywords internal
#' @inherit is.multivariate
is.multivariate.DensityList <- function(x) {
  all(sapply(x, is.multivariate))
}
