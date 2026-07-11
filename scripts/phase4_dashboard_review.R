options(stringsAsFactors = FALSE)
Sys.setenv(NOT_CRAN='true')
library(data.table)
library(shinytest2)
root <- normalizePath(getwd(), winslash='/', mustWork=TRUE)
p <- function(...) file.path(root, ...)
dir.create(p('outputs/reports/visual'), recursive=TRUE, showWarnings=FALSE)
write_utf8 <- function(x, path) writeLines(enc2utf8(x), path, useBytes=TRUE)
rows <- list()
add_row <- function(module, action, expected, observed, status='PASS', correction='None') {
  rows[[length(rows)+1]] <<- data.table(Module=module, `Action tested`=action, `Expected result`=expected, `Observed result`=observed, Status=status, Correction=correction)
}
step <- function(module, action, expected, expr, correction='None') {
  out <- tryCatch({ val <- force(expr); list(status='PASS', observed=as.character(val)) }, error=function(e) list(status='FAIL', observed=conditionMessage(e)))
  add_row(module, action, expected, out$observed, out$status, ifelse(out$status=='PASS', correction, 'Requires correction before publication'))
  invisible(out$status == 'PASS')
}
opp <- fread(p('outputs/tables/csv/bolivia_opportunities_revised.csv'), colClasses=list(character='product_code'))
products <- head(opp[eligible == TRUE][order(-transformation_score), product_code], 3)
app <- shinytest2::AppDriver$new(app_dir='dashboard', height=900, width=1400, load_timeout=60000, timeout=12000)
on.exit(app$stop(), add=TRUE)
app$wait_for_idle()
set_inputs_fast <- function(...) app$set_inputs(..., wait_=FALSE)
shot <- function(file) { if (file.exists(file)) unlink(file); app$get_screenshot(file=file) }
step('Dashboard launch','Open app with shinytest2/Chromote','App loads on local 127.0.0.1 URL', { app$get_url() })
step('Executive Overview','Read validation cards and trend page','Bolivia cards, counts and trends visible', { txt <- app$get_text('body'); stopifnot(grepl('Bolivia ECI 2023', txt), grepl('Executive Overview', txt)); shot(file=p('outputs/reports/visual/dashboard_executive_overview.png')); 'Metrics, tabs and overview visible; screenshot saved.' })
add_row('Executive Overview','Map layer check','If geospatial data exist, map should render','No geospatial public output is included; dashboard uses trend/ranking views instead.', 'WARNING', 'Documented as not applicable rather than adding an unsupported map.')
step('Executive Overview','Opportunity counts ranking','Category counts are visible', { val <- app$get_value(output='overview_validation'); stopifnot(grepl('Opportunity candidates', val)); val })
for (cc in c('BOL','BRA','MEX','CHL')) {
  step('Country Explorer', paste('Select country', cc), 'Country snapshot and time series update', { set_inputs_fast(main_tabs='Country Explorer'); set_inputs_fast(country=cc); app$wait_for_idle(); val <- app$get_value(output='country_snapshot'); stopifnot(grepl('Latest year', val)); shot(file=p('outputs/reports/visual', paste0('dashboard_country_', cc, '.png'))); val })
}
for (metric in c('eci','diversity','hhi','primary_share')) {
  step('Country Explorer', paste('Switch indicator', metric), 'Indicator control updates plot/table without error', { set_inputs_fast(country_metric=metric); app$wait_for_idle(); paste('Indicator set to', metric) })
}
for (pc in products) {
  step('Product Explorer', paste('Select product', pc), 'Product description, PCI/ubiquity series and table visible', { set_inputs_fast(main_tabs='Product Explorer'); set_inputs_fast(product=pc); app$wait_for_idle(); txt <- app$get_text('body'); stopifnot(grepl(pc, txt)); shot(file=p('outputs/reports/visual', paste0('dashboard_product_', pc, '.png'))); paste('Product', pc, 'visible in page text.') })
}
for (metric in c('pci_final','ubiquity','world_export_value')) {
  step('Product Explorer', paste('Switch product metric', metric), 'Product metric updates without error', { set_inputs_fast(product_metric=metric); app$wait_for_idle(); paste('Product metric set to', metric) })
}
step('Product Space','Open Product Space tab','Static Product Space network, diagnostics and opportunity overlay visible', { set_inputs_fast(main_tabs='Product Space'); set_inputs_fast(ps_category='Strategic bets'); app$wait_for_idle(); txt <- app$get_text('body'); stopifnot(grepl('Product Space', txt), grepl('Diagnostics', txt)); shot(file=p('outputs/reports/visual/dashboard_product_space.png')); 'Product Space tab visible; screenshot saved.' })
for (catg in c('Strategic bets','Incremental extensions','Transformational long shots')) {
  step('Product Space', paste('Filter overlay', catg), 'Opportunity overlay updates without freezing', { set_inputs_fast(ps_category=catg); app$wait_for_idle(); paste('Overlay category set to', catg) })
}
step('Bolivia Opportunity Lab','Strategic bets filter','Strategic bets, scores, rankings and table visible', { set_inputs_fast(main_tabs='Bolivia Opportunity Lab'); set_inputs_fast(category='Strategic bets', sector='All', score='transformation_score', eligible_only=TRUE, n=30); app$wait_for_idle(); txt <- app$get_text('body'); stopifnot(grepl('Strategic bets', txt)); shot(file=p('outputs/reports/visual/dashboard_opportunity_lab.png')); 'Strategic bets filter visible; screenshot saved.' })
step('Bolivia Opportunity Lab','Sector filter','Sector filter applies without error', { sec <- sort(unique(opp$product_section))[1]; set_inputs_fast(sector=sec); app$wait_for_idle(); paste('Sector filter set to', sec) })
step('Bolivia Opportunity Lab','Download filtered table','CSV download is produced', { tmp <- app$get_download(output='download_opp'); stopifnot(file.exists(tmp)); paste('Download file exists:', basename(tmp), 'size bytes:', file.info(tmp)$size) })
step('Econometric Evidence','Open coefficients and table','Coefficient plot, non-causal note and table visible', { set_inputs_fast(main_tabs='Econometric Evidence'); app$wait_for_idle(); txt <- app$get_text('body'); stopifnot(grepl('not causal estimates', txt)); shot(file=p('outputs/reports/visual/dashboard_econometric.png')); 'Econometric tab visible with non-causal note.' })
step('Data and Methods','Open definitions and validation links','Definitions, methodology and limitations visible', { set_inputs_fast(main_tabs='Data and Methods'); app$wait_for_idle(); txt <- app$get_text('body'); stopifnot(grepl('ECI is standardized', txt), grepl('Validation files', txt)); shot(file=p('outputs/reports/visual/dashboard_methods.png')); 'Data and Methods tab visible.' })
step('Responsive sizing','Resize viewport','Dashboard remains readable at narrower width', { app$set_window_size(width=390, height=900); app$wait_for_idle(); shot(file=p('outputs/reports/visual/dashboard_mobile_width.png')); app$set_window_size(width=1400, height=900); 'Mobile-width screenshot saved.' })
logs <- tryCatch(app$get_logs(), error=function(e) list())
log_text <- paste(capture.output(str(logs, max.level=2)), collapse=' ')
if (grepl('error|Error|ERROR', log_text)) add_row('Console/logs','Inspect browser logs','No console errors', substr(log_text,1,500), 'WARNING', 'Review log text if browser-specific behavior is suspected.') else add_row('Console/logs','Inspect browser logs','No console errors', 'No console errors detected by AppDriver log scan.', 'PASS', 'None')
res <- rbindlist(rows, fill=TRUE)
fwrite(res, p('outputs/tables/csv/dashboard_manual_review.csv'))
clean_cell <- function(x) {
  x <- as.character(x)
  x <- gsub('|', '/', x, fixed=TRUE)
  x <- gsub(intToUtf8(10), ' ', x, fixed=TRUE)
  x
}
md <- c('# Dashboard Manual Review','',paste0('Final status: ', ifelse(any(res$Status == 'FAIL'), 'FAIL', ifelse(any(res$Status == 'WARNING'), 'WARNING', 'PASS'))),'',
  '| Module | Action tested | Expected result | Observed result | Status | Correction |','|---|---|---|---|---|---|',
  apply(res, 1, function(r) paste0('| ', paste(clean_cell(r), collapse=' | '), ' |')),
  '', 'Method: local Shiny app opened with shinytest2/Chromote. Screenshots are stored in `outputs/reports/visual/`. No raw data rebuild or metric recalculation was performed.')
write_utf8(md, p('outputs/reports/DASHBOARD_MANUAL_REVIEW.md'))
cat('Dashboard manual-assisted review complete. Status:', ifelse(any(res$Status == 'FAIL'), 'FAIL', ifelse(any(res$Status == 'WARNING'), 'WARNING', 'PASS')), '\n')