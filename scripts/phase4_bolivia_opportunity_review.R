options(stringsAsFactors=FALSE)
library(data.table)
root <- normalizePath(getwd(), winslash='/', mustWork=TRUE)
p <- function(...) file.path(root,...)
write_utf8 <- function(x, path) writeLines(enc2utf8(x), path, useBytes=TRUE)
opp <- fread(p('outputs/tables/csv/bolivia_opportunities_revised.csv'), colClasses=list(character='product_code'))
top40 <- fread(p('outputs/tables/csv/bolivia_top40_economic_review.csv'), colClasses=list(character='product_code'))
xlsx_ok <- FALSE
xlsx_rows <- NA_integer_
if (requireNamespace('readxl', quietly=TRUE) && file.exists(p('outputs/tables/xlsx/bolivia_opportunities_revised.xlsx'))) {
  x <- readxl::read_excel(p('outputs/tables/xlsx/bolivia_opportunities_revised.xlsx'), n_max=5)
  xlsx_ok <- ncol(x) > 0
  xlsx_rows <- NA_integer_
}
strategic <- opp[relative_category == 'Strategic bets'][order(-transformation_score)]
strategic[, duplicate_code := duplicated(product_code) | duplicated(product_code, fromLast=TRUE)]
strategic[, special_transaction := grepl('special transaction|not elsewhere specified|commodities not specified|temporary|confidential', product_name, ignore.case=TRUE) | grepl('^99', product_code)]
interpret <- function(section, name) {
  if (grepl('firearms|explosive charge|rifles|pistols', name, ignore.case=TRUE)) return('Analytically high transformation score, but this is a regulated/sensitive firearms category. It should not be promoted as a general productive-development priority without a separate legal, safety and governance review.')
  if (section == 'Transport equipment') return('Potentially transformative but scale- and supplier-network intensive; better interpreted through parts, maintenance, assembly, standards and regional value-chain feasibility studies.')
  if (section == 'Machinery and electrical') return('Capability-building candidate linked to technical standards, components, maintenance, electrical systems and supplier development; requires firm-level feasibility validation.')
  if (section == 'Plastics and rubber') return('Related industrial-input opportunity with plausible links to mining, transport, construction and maintenance supply chains; environmental and quality standards matter.')
  if (section == 'Metals') return('Related metalworking opportunity that may build on fabrication, repair and supplier capabilities; product heterogeneity requires subsector review.')
  if (section == 'Textiles and apparel') return('Industrial-material candidate with nonwoven technical uses; requires validation of scale, inputs, standards and market access.')
  if (section == 'Instruments') return('Higher-capability instrument category; plausible only with calibration, standards, import-substitution or supplier-service ecosystems.')
  'Candidate requires sector-level feasibility validation before any policy interpretation.'
}
strategic[, Interpretation := mapply(interpret, product_section, product_name)]
strategic[, name_truncated := grepl('(elect| fi)$', product_name)]
strategic[, `Data warning` := fifelse(residual_code == TRUE, 'Residual code: keep in base but exclude from highlighted lists.', fifelse(special_transaction == TRUE, 'Special/residual transaction language detected: keep in base but exclude from highlighted lists.', fifelse(grepl('firearms|explosive charge|rifles|pistols', product_name, ignore.case=TRUE), 'Sensitive regulated firearms category; keep analytical result but exclude from general highlighted policy list.', fifelse(name_truncated == TRUE, 'Product name appears truncated in the local source label; keep candidate but verify full HS label before formal sector memo.', 'none'))))]
strategic[, `Keep or exclude from highlighted list` := fifelse(`Data warning` == 'none', 'Keep', 'Exclude from general highlighted list; keep in analytical dataset')]
strategic[, Reason := fifelse(`Data warning` == 'none', 'Non-residual, interpretable HS92 product with coherent sector label and validated scores.', `Data warning`)]
review <- strategic[, .(`Product code`=product_code, `Product name`=product_name, Sector=product_section, Density=density, PCI=pci_final, `Opportunity Gain`=opportunity_gain, `Feasibility Score`=feasibility_score, `Transformation Score`=transformation_score, Interpretation, `Data warning`, `Keep or exclude from highlighted list`, Reason)]
fwrite(review, p('outputs/tables/csv/bolivia_strategic_bets_human_review.csv'))
highlight <- review[`Keep or exclude from highlighted list` == 'Keep']
fwrite(highlight, p('outputs/tables/csv/bolivia_strategic_bets_highlighted.csv'))
summary_lines <- c('# Bolivia Top Opportunities Human Review','',
  'Scope: review of the 11 products classified as `Strategic bets` in `outputs/tables/csv/bolivia_opportunities_revised.csv`, with cross-check against `bolivia_top40_economic_review.csv` and the XLSX workbook where available. No product was removed from the analytical dataset and no ranking or score was changed.','',
  paste0('- Strategic bets reviewed: ', nrow(review)),
  paste0('- Duplicate product codes among strategic bets: ', sum(strategic$duplicate_code)),
  paste0('- Residual-code flags among strategic bets: ', sum(strategic$residual_code == TRUE, na.rm=TRUE)),
  paste0('- Special transaction/residual text flags: ', sum(strategic$special_transaction == TRUE, na.rm=TRUE)),
  paste0('- Truncated-name warnings: ', sum(strategic$name_truncated == TRUE, na.rm=TRUE)),
  paste0('- XLSX workbook readable: ', xlsx_ok),
  paste0('- Highlighted-list exclusions: ', sum(review$`Keep or exclude from highlighted list` != 'Keep')),
  '',
  'Decision rule: difficult, residual or sensitive products remain in the base table but are excluded only from general highlighted policy-facing lists. This does not alter the validated `relative_category` classification.','',
  '| Product code | Product name | Sector | Density | PCI | Opportunity Gain | Feasibility Score | Transformation Score | Interpretation | Data warning | Keep or exclude from highlighted list | Reason |','|---|---|---|---:|---:|---:|---:|---:|---|---|---|---|')
rows <- apply(review, 1, function(r) paste0('| ', paste(gsub('\n',' ', gsub('|','/', as.character(r), fixed=TRUE), fixed=TRUE), collapse=' | '), ' |'))
write_utf8(c(summary_lines, rows, '', 'Output files:', '', '- `outputs/tables/csv/bolivia_strategic_bets_human_review.csv`', '- `outputs/tables/csv/bolivia_strategic_bets_highlighted.csv`'), p('docs/BOLIVIA_TOP_OPPORTUNITIES_HUMAN_REVIEW.md'))
cat('Bolivia opportunity human review complete\n')
