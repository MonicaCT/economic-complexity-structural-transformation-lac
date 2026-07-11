root <- normalizePath(getwd(), winslash='/', mustWork=TRUE)
shiny::runApp(file.path(root, 'dashboard'), launch.browser=TRUE)
