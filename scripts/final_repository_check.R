options(stringsAsFactors=FALSE)
library(data.table)
root <- normalizePath(getwd(), winslash='/', mustWork=TRUE)
p <- function(...) file.path(root,...)
read_status <- function(file) {
  if (!file.exists(p(file))) return(data.table(file=file, status='FAIL', detail='missing'))
  x <- readLines(p(file), warn=FALSE)
  line <- grep('^(Final status|Status):', x, value=TRUE)
  if (!length(line)) return(data.table(file=file, status='PASS', detail='no explicit status line'))
  st <- sub('^.*: *', '', line[1])
  data.table(file=file, status=st, detail=line[1])
}
required <- c('README.md','LICENSE','CITATION.cff','CODE_OF_CONDUCT.md','CONTRIBUTING.md','paper/main.html','paper/main.pdf','paper/policy_brief.html','dashboard/app.R','docs/BOLIVIA_TOP_OPPORTUNITIES_HUMAN_REVIEW.md','outputs/reports/README_VISUAL_CHECK.md','outputs/reports/PDF_VISUAL_CHECK.md','outputs/reports/HTML_VISUAL_CHECK.md','outputs/reports/DASHBOARD_MANUAL_REVIEW.md','outputs/reports/PRE_COMMIT_FILE_AUDIT_SUMMARY.md','outputs/reports/PUBLIC_CONTENT_CHECK.md','outputs/reports/PRIVACY_AND_SECURITY_CHECK.md','outputs/reports/LINK_CHECK.md','outputs/reports/CITATION_CFF_CHECK.md')
missing <- required[!file.exists(p(required))]
tests <- if (file.exists(p('outputs/tables/csv/test_results.csv'))) fread(p('outputs/tables/csv/test_results.csv')) else data.table(status='FAIL')
local_scan <- if (file.exists(p('outputs/tables/csv/local_path_scan.csv'))) fread(p('outputs/tables/csv/local_path_scan.csv')) else data.table(file='missing')
reports <- rbindlist(lapply(c('outputs/reports/README_VISUAL_CHECK.md','outputs/reports/PDF_VISUAL_CHECK.md','outputs/reports/HTML_VISUAL_CHECK.md','outputs/reports/DASHBOARD_MANUAL_REVIEW.md','outputs/reports/PRE_COMMIT_FILE_AUDIT_SUMMARY.md','outputs/reports/PUBLIC_CONTENT_CHECK.md','outputs/reports/PRIVACY_AND_SECURITY_CHECK.md','outputs/reports/LINK_CHECK.md','outputs/reports/CITATION_CFF_CHECK.md'), read_status), fill=TRUE)
fail_count <- length(missing) + sum(tests$status == 'FAIL') + nrow(local_scan) + sum(grepl('FAIL', reports$status))
warning_count <- sum(grepl('WARNING', reports$status))
overall <- if (fail_count == 0) 'READY FOR GITHUB' else 'NOT READY'
lines <- c('# Final Repository Check','',paste0('Overall status: ', overall),'',paste0('- FAIL count: ', fail_count),paste0('- Warning count: ', warning_count),paste0('- Missing required files: ', length(missing)),paste0('- Tests passing: ', sum(tests$status=='PASS'), '/', nrow(tests)),paste0('- Public local path hits: ', nrow(local_scan)),'','## Report Statuses','','| report | status | detail |','|---|---|---|', apply(reports, 1, function(r) paste0('| ', r[['file']], ' | ', r[['status']], ' | ', gsub('\\|','/',r[['detail']]), ' |')),'','No commit or push is performed by this script.')
writeLines(lines, p('outputs/reports/FINAL_REPOSITORY_CHECK.md'), useBytes=TRUE)
cat(paste(lines, collapse='\n'))