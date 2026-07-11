options(stringsAsFactors = FALSE, scipen = 999)
root <- normalizePath(getwd(), winslash='/', mustWork=TRUE)
p <- function(...) file.path(root,...)
for (d in c('data/sample','tests','outputs/reports','outputs/tables/csv','R')) if (!dir.exists(p(d))) dir.create(p(d), recursive=TRUE)
library(data.table)
normalize_hs4 <- function(x){x<-trimws(as.character(x)); ok<-!is.na(x)&grepl('^[0-9]+$',x)&nchar(x)<4; x[ok]<-sprintf('%04d',as.integer(x[ok])); x}
write_utf8 <- function(lines, file) writeLines(lines, file, useBytes=TRUE)

# Public samples from processed caches only.
trade <- as.data.table(arrow::read_parquet(p('data/processed/trade_country_product_year.parquet')))
trade[, product_code := normalize_hs4(product_code)]
cy <- fread(p('outputs/tables/csv/country_year_indicators.csv'))
opp <- fread(p('outputs/tables/csv/bolivia_opportunities_revised.csv'), colClasses=list(character='product_code'))
opp[, product_code := normalize_hs4(product_code)]
years <- sort(unique(c(min(trade$year), 2009L, max(trade$year))))
trade_sample <- trade[country_code %in% c('BOL','BRA','CHL','MEX','PER') & year %in% years][order(country_code,year,product_code)]
fwrite(head(trade_sample, 5000), p('data/sample/trade_sample.csv'))
fwrite(cy[country_code %in% c('BOL','BRA','CHL','MEX','PER')][order(country_code,year)], p('data/sample/country_year_sample.csv'))
fwrite(head(opp[eligible==TRUE][order(-feasibility_score)], 200), p('data/sample/bolivia_opportunity_sample.csv'))
write_utf8(c('# Sample Data','','These CSV files are small public samples generated from processed local outputs. They are intended for inspection and demo workflows, not for reproducing the full results.','','- `trade_sample.csv`: selected countries and years from the processed country-product-year panel.','- `country_year_sample.csv`: selected Latin American country-year indicators.','- `bolivia_opportunity_sample.csv`: top eligible Bolivia opportunity candidates by feasibility score.','','The full processed parquet cache is intentionally ignored by Git.'), p('data/sample/README.md'))

# Demo script.
write_utf8(c("library(data.table)","root <- normalizePath(getwd(), winslash='/', mustWork=TRUE)","trade <- fread(file.path(root,'data/sample/trade_sample.csv'), colClasses=list(character='product_code'))","cy <- fread(file.path(root,'data/sample/country_year_sample.csv'))","opp <- fread(file.path(root,'data/sample/bolivia_opportunity_sample.csv'), colClasses=list(character='product_code'))","summary_lines <- c('# Demo Report','',paste0('- Trade sample rows: ', nrow(trade)),paste0('- Country-year sample rows: ', nrow(cy)),paste0('- Opportunity sample rows: ', nrow(opp)),paste0('- Bolivia sample years: ', paste(sort(unique(cy[country_code=='BOL', year])), collapse=', ')),paste0('- Top sample opportunity: ', opp[1, product_code], ' ', opp[1, product_name_short]))","dir.create(file.path(root,'outputs/reports'), recursive=TRUE, showWarnings=FALSE)","writeLines(summary_lines, file.path(root,'outputs/reports/DEMO_REPORT.md'), useBytes=TRUE)","cat(paste(summary_lines, collapse='\\n'))"), p('R/98_run_demo.R'))

# Focused Phase 2 tests.
write_utf8(c("library(data.table)","root <- normalizePath(getwd(), winslash='/', mustWork=FALSE)","ps <- fread(file.path(root,'outputs/tables/csv/product_space_network_diagnostics.csv'))","val <- function(m) as.numeric(ps[metric==m, value][1])","stopifnot(val('analytical_positive_edges') > val('visual_edges'))","stopifnot(val('visual_edges') >= 500)","stopifnot(val('diag_max_abs') == 0)","stopifnot(val('symmetry_max_abs_diff') < 1e-10)","edges <- fread(file.path(root,'outputs/networks/product_space_visual_edges.csv'), colClasses=list(character=c('from','to')))","stopifnot(!anyDuplicated(edges[, .(pmin(from,to), pmax(from,to))]))"), p('tests/test_product_space.R'))
write_utf8(c("library(data.table)","root <- normalizePath(getwd(), winslash='/', mustWork=FALSE)","opp <- fread(file.path(root,'outputs/tables/csv/bolivia_opportunities_revised.csv'), colClasses=list(character='product_code'))","top40 <- fread(file.path(root,'outputs/tables/csv/bolivia_top40_economic_review.csv'), colClasses=list(character='product_code'))","stopifnot(nrow(opp) == 1138)","stopifnot(opp[eligible==TRUE, .N] > 500)","stopifnot(opp[relative_category=='Strategic bets', .N] > 0)","stopifnot(all(grepl('^[0-9]{4}$', opp$product_code)))","stopifnot(all(c('feasibility_score','transformation_score','relative_category') %in% names(opp)))","stopifnot(nrow(top40) >= 30)","stopifnot(all(is.finite(top40$density)))"), p('tests/test_opportunities.R'))
write_utf8(c("library(data.table)","root <- normalizePath(getwd(), winslash='/', mustWork=FALSE)","ms <- fread(file.path(root,'outputs/tables/csv/econometric_model_summary.csv'))","comp <- fread(file.path(root,'outputs/tables/csv/model_sample_composition.csv'))","stopifnot(all(c('income_level','future_growth','growth_volatility') %in% unique(ms$model)))","stopifnot(all(ms$nobs > 100))","stopifnot(all(is.finite(ms$estimate)))","stopifnot(comp$countries[1] >= 20)","stopifnot(file.exists(file.path(root,'docs/ECONOMETRIC_MODEL_AUDIT.md')))"), p('tests/test_models.R'))

# Cleaner render report script with no user-specific paths in output.
write_utf8(c("options(stringsAsFactors=FALSE)","root <- normalizePath(getwd(), winslash='/', mustWork=TRUE)","report <- file.path(root, 'outputs/reports/PAPER_RENDER_REPORT.md')","tools <- Sys.which(c('quarto','pandoc','pdflatex','xelatex','lualatex'))","lines <- c('# Paper Render Report','',paste0('- quarto: ', nzchar(tools[['quarto']])),paste0('- pandoc: ', nzchar(tools[['pandoc']])),paste0('- pdflatex: ', nzchar(tools[['pdflatex']])))","if (nzchar(tools[['quarto']])) { status <- system2(tools[['quarto']], c('render', file.path(root,'paper/main.qmd'), '--to', 'html'), stdout=FALSE, stderr=FALSE); lines <- c(lines, paste0('- Quarto HTML exit status: ', status)) } else lines <- c(lines, '- Quarto HTML: skipped; prebuilt paper/main.html is used.')","if (nzchar(tools[['pdflatex']]) && file.exists(file.path(root,'paper/main.tex'))) { old <- getwd(); setwd(file.path(root,'paper')); status1 <- system2(tools[['pdflatex']], c('-interaction=nonstopmode','-halt-on-error','main.tex'), stdout=FALSE, stderr=FALSE); status2 <- system2(tools[['pdflatex']], c('-interaction=nonstopmode','-halt-on-error','main.tex'), stdout=FALSE, stderr=FALSE); setwd(old); lines <- c(lines, paste0('- LaTeX PDF exit statuses: ', status1, ', ', status2)) } else lines <- c(lines, '- LaTeX PDF: skipped; no engine or main.tex available.')","lines <- c(lines, paste0('- HTML exists: ', file.exists(file.path(root,'paper/main.html'))), paste0('- PDF exists: ', file.exists(file.path(root,'paper/main.pdf'))))","writeLines(lines, report, useBytes=TRUE)","cat(paste(lines, collapse='\\n'))"), p('scripts/render_paper.R'))

# Update gitignore for local/config, large caches, and LaTeX auxiliaries.
gi_path <- p('.gitignore')
gi <- if (file.exists(gi_path)) readLines(gi_path, warn=FALSE) else character()
needed_ignores <- c('config/paths.local.yml','paper/*.pdf','paper/*.aux','paper/*.out','paper/*.toc','paper/*.fls','paper/*.fdb_latexmk','paper/*.synctex.gz')
gi <- unique(c(gi, needed_ignores))
write_utf8(gi, gi_path)

# Sanitize public text files.
text_ext <- c('R','r','md','qmd','yml','yaml','csv','txt','ps1','html','bib','tex','json')
skip_dirs <- c('.git')
files <- list.files(root, recursive=TRUE, full.names=TRUE, all.files=TRUE, no..=TRUE)
files <- files[!grepl(paste0('(^|/|\\\\)(', paste(skip_dirs, collapse='|'), ')(/|\\\\)'), files)]
files <- files[tolower(tools::file_ext(files)) %in% tolower(text_ext)]
files <- files[normalizePath(files, winslash='/', mustWork=FALSE) != normalizePath(p('config/paths.local.yml'), winslash='/', mustWork=FALSE)]
replace_map <- c(
  '${PROJECT_ROOT}'='${PROJECT_ROOT}',
  '${DATA_PART_II}'='${DATA_PART_II}',
  '${DATA_PART_I}'='${DATA_PART_I}',
  '${LOCAL_TINYTEX}'='${LOCAL_TINYTEX}'
)
for (f in files) {
  txt <- tryCatch(readLines(f, warn=FALSE, encoding='UTF-8'), error=function(e) NULL)
  if (is.null(txt)) next
  old <- txt
  for (pat in names(replace_map)) txt <- gsub(pat, replace_map[[pat]], txt, fixed=TRUE)
  if (!identical(old, txt)) write_utf8(txt, f)
}

# Run render report after sanitizing script.
suppressWarnings(source(p('scripts/render_paper.R'), local=TRUE))

# Run all tests.
test_files <- sort(list.files(p('tests'), pattern='\\.R$', full.names=TRUE))
test_results <- rbindlist(lapply(test_files, function(tf){
  msg <- NULL; ok <- tryCatch({sys.source(tf, envir=new.env(parent=globalenv())); TRUE}, error=function(e){msg <<- conditionMessage(e); FALSE})
  data.table(test=basename(tf), status=ifelse(ok,'PASS','FAIL'), message=ifelse(is.null(msg),'',msg))
}))
fwrite(test_results, p('outputs/tables/csv/test_results.csv'))
write_utf8(c('# Test Results','',paste0('- Tests run: ', nrow(test_results)),paste0('- Passing: ', test_results[status=='PASS', .N]),paste0('- Failing: ', test_results[status=='FAIL', .N]),'',paste(apply(test_results, 1, function(r) paste0('- ', r[['test']], ': ', r[['status']], ifelse(nzchar(r[['message']]), paste0(' - ', r[['message']]), ''))), collapse='\n')), p('outputs/reports/TEST_RESULTS.md'))

# Final repository check.
checks <- list()
add_check <- function(area, status, detail) checks[[length(checks)+1]] <<- data.table(area=area, status=status, detail=detail)
required <- c('README.md','paper/main.qmd','paper/main.html','paper/main.pdf','dashboard/app.R','docs/REPRODUCIBILITY.md','docs/DELIVERABLES_AUDIT.md','docs/ECI_PCI_TECHNICAL_VALIDATION.md','docs/PRODUCT_SPACE_VALIDATION.md','docs/BOLIVIA_OPPORTUNITY_AUDIT.md','docs/ECONOMETRIC_MODEL_AUDIT.md','docs/FIGURE_AUDIT.md','outputs/reports/DASHBOARD_TEST_REPORT.md','outputs/reports/TEST_RESULTS.md','outputs/tables/xlsx/bolivia_opportunities_revised.xlsx','data/sample/README.md')
missing <- required[!file.exists(p(required))]
add_check('required_files', ifelse(length(missing)==0,'PASS','FAIL'), ifelse(length(missing)==0,'All priority files are present.', paste('Missing:', paste(missing, collapse=', '))))
fig <- fread(p('outputs/tables/csv/figure_audit.csv'))
add_check('figures', ifelse(all(fig$status=='PASS'),'PASS','FAIL'), paste0(fig[status=='PASS', .N], '/', nrow(fig), ' figure records pass.'))
add_check('tests', ifelse(all(test_results$status=='PASS'),'PASS','FAIL'), paste0(test_results[status=='PASS', .N], '/', nrow(test_results), ' tests pass.'))
pa <- readLines(p('docs/PAPER_COMPLETENESS_AUDIT.md'), warn=FALSE)
add_check('paper_length', ifelse(any(grepl('Status: PASS', pa)), 'PASS', 'WARNING'), grep('Status:', pa, value=TRUE)[1])
scan_files <- files[file.exists(files)]
scan_files <- setdiff(normalizePath(scan_files, winslash='/', mustWork=FALSE), normalizePath(p('outputs/tables/csv/local_path_scan.csv'), winslash='/', mustWork=FALSE))
local_pat <- '([A-Z]:[\\\\/]Users[\\\\/][^\\\\/]+|[A-Z]:[\\\\/]Papers Desarrollo_2026)'
local_hits <- rbindlist(lapply(scan_files, function(f){
  txt <- tryCatch(readLines(f, warn=FALSE, encoding='UTF-8'), error=function(e) character())
  idx <- grep(local_pat, txt)
  if (length(idx)) data.table(file=normalizePath(f, winslash='/', mustWork=FALSE), line=idx[1], text=substr(txt[idx[1]],1,180)) else data.table()
}), fill=TRUE)
if (nrow(local_hits)==0) local_hits <- data.table(file=character(), line=integer(), text=character())
fwrite(local_hits, p('outputs/tables/csv/local_path_scan.csv'))
add_check('local_paths', ifelse(nrow(local_hits)==0,'PASS','FAIL'), ifelse(nrow(local_hits)==0,'No user-specific absolute paths found outside config/paths.local.yml.', paste0(nrow(local_hits), ' files contain local paths.')))
ignore_text <- readLines(p('.gitignore'), warn=FALSE)
ignore_ok <- all(c('config/paths.local.yml','data/raw/','data/processed/*.parquet','paper/*.pdf') %in% ignore_text)
add_check('gitignore', ifelse(ignore_ok,'PASS','FAIL'), 'Checks config local, raw data, processed parquet, and PDF ignore rules.')
large <- file.info(list.files(root, recursive=TRUE, full.names=TRUE, all.files=TRUE, no..=TRUE))
large <- data.table(path=rownames(large), size=large$size)[is.finite(size) & size > 50*1024^2]
large[, rel := substring(normalizePath(path, winslash='/', mustWork=FALSE), nchar(root)+2)]
large_bad <- large[!grepl('^data/processed/.*\\.parquet$|^data/processed/trade_lac_country_product_year\\.csv$|^paper/.*\\.pdf$|^outputs/models/.*\\.rds$', rel)]
add_check('large_files', ifelse(nrow(large_bad)==0,'PASS','WARNING'), ifelse(nrow(large_bad)==0,'Large files are limited to expected ignored artifacts.', paste('Review large files:', paste(large_bad$rel, collapse=', '))))
final <- rbindlist(checks)
fwrite(final, p('outputs/tables/csv/final_repository_check.csv'))
overall <- if (any(final$status=='FAIL')) 'NOT READY' else if (any(final$status=='WARNING')) 'READY WITH WARNINGS' else 'READY'
write_utf8(c('# Final Repository Check','',paste0('Overall status: ', overall),'',paste0('- PASS: ', final[status=='PASS', .N]),paste0('- WARNING: ', final[status=='WARNING', .N]),paste0('- FAIL: ', final[status=='FAIL', .N]),'', '| Area | Status | Detail |','|---|---|---|', apply(final, 1, function(r) paste0('| ', r[['area']], ' | ', r[['status']], ' | ', gsub('\\|','/', r[['detail']]), ' |'))), p('outputs/reports/FINAL_REPOSITORY_CHECK.md'))
cat('Stage 5 samples, tests, cleanup complete. Overall status: ', overall, '\n', sep='')
if (any(final$status=='FAIL')) quit(status=1)
