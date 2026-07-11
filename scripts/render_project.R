root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
if (basename(root) == "scripts") root <- dirname(root)
cat("Static HTML files are available at paper/main.html and paper/policy_brief.html. Quarto is not available on PATH in this environment.\n")