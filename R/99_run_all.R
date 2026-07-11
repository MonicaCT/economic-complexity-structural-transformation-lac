options(stringsAsFactors = FALSE, scipen = 999, datatable.print.nrows = 50)

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x)) y else x
args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl('^--file=', args)]
this_file <- if (length(file_arg)) normalizePath(sub('^--file=', '', file_arg[1]), winslash = '/') else normalizePath('R/99_run_all.R', winslash = '/')
PROJECT_ROOT <- normalizePath(file.path(dirname(this_file), '..'), winslash = '/', mustWork = TRUE)

required <- c('data.table', 'arrow', 'Matrix', 'igraph', 'ggplot2', 'fixest', 'openxlsx', 'countrycode')
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop('Missing required local R packages: ', paste(missing, collapse = ', '), call. = FALSE)

suppressPackageStartupMessages({
  library(data.table)
  library(Matrix)
  library(ggplot2)
  library(igraph)
  library(yaml)
})

path <- function(...) file.path(PROJECT_ROOT, ...)
ensure_dir <- function(x) if (!dir.exists(x)) dir.create(x, recursive = TRUE, showWarnings = FALSE)
for (d in c('data/processed','data/interim','data/metadata','outputs/tables/csv','outputs/tables/xlsx','outputs/tables/html','outputs/figures/png','outputs/figures/pdf','outputs/networks','outputs/models','outputs/reports','logs','paper','dashboard/data')) ensure_dir(path(d))

log_file <- path('logs', 'run_all.log')
log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), '%Y-%m-%d %H:%M:%S'), ' | ', paste(..., collapse = ''))
  cat(msg, '\n')
  cat(msg, '\n', file = log_file, append = TRUE)
}

needs_update <- function(output, inputs) {
  if (!file.exists(output)) return(TRUE)
  out_time <- file.info(output)$mtime
  any(file.info(inputs)$mtime > out_time, na.rm = TRUE)
}

lac_iso3 <- c('ARG','BOL','BRA','CHL','COL','CRI','ECU','SLV','GTM','HND','MEX','NIC','PAN','PRY','PER','DOM','URY','VEN','CUB','JAM','TTO','BRB','BHS','BLZ','GUY','SUR','HTI')
comparators <- c('KOR','CHN','VNM','MYS','THA','TUR','ZAF')

paths_file <- path('config', 'paths.local.yml')
if (!file.exists(paths_file)) paths_file <- path('config', 'paths.example.yml')
paths_cfg <- yaml::read_yaml(paths_file)
atlas_dir <- paths_cfg$atlas_dir
trade_file <- paths_cfg$trade_hs92_country_product_year_4
product_file <- paths_cfg$product_hs92_dictionary
country_file <- paths_cfg$country_dictionary
macro_file <- paths_cfg$cepii_country_year

for (f in c(trade_file, product_file, country_file, macro_file)) if (!file.exists(f)) stop('Essential source file not found: ', f, call. = FALSE)

hs_section <- function(code) {
  chapter <- suppressWarnings(as.integer(substr(sprintf('%04s', code), 1, 2)))
  fifelse(chapter <= 5, 'Animal products',
  fifelse(chapter <= 14, 'Vegetable products',
  fifelse(chapter <= 15, 'Fats and oils',
  fifelse(chapter <= 24, 'Foodstuffs',
  fifelse(chapter <= 27, 'Minerals',
  fifelse(chapter <= 38, 'Chemicals',
  fifelse(chapter <= 40, 'Plastics and rubber',
  fifelse(chapter <= 43, 'Hides and leather',
  fifelse(chapter <= 49, 'Wood and paper',
  fifelse(chapter <= 63, 'Textiles and apparel',
  fifelse(chapter <= 67, 'Footwear and headgear',
  fifelse(chapter <= 70, 'Stone and glass',
  fifelse(chapter <= 71, 'Precious metals',
  fifelse(chapter <= 83, 'Metals',
  fifelse(chapter <= 85, 'Machinery and electrical',
  fifelse(chapter <= 89, 'Transport equipment',
  fifelse(chapter <= 92, 'Instruments',
  fifelse(chapter <= 97, 'Other manufactures', 'Unclassified'))))))))))))))))))
}

standardize <- function(x) {
  s <- stats::sd(x, na.rm = TRUE)
  m <- mean(x, na.rm = TRUE)
  if (!is.finite(s) || s == 0) return(rep(NA_real_, length(x)))
  as.numeric((x - m) / s)
}

safe_minmax <- function(x) {
  if (all(is.na(x))) return(rep(NA_real_, length(x)))
  r <- range(x, na.rm = TRUE)
  if (!all(is.finite(r)) || diff(r) == 0) return(rep(0.5, length(x)))
  (x - r[1]) / diff(r)
}

# Phase 2: analytical base -------------------------------------------------
trade_parquet <- path('data/processed', 'trade_country_product_year.parquet')
if (needs_update(trade_parquet, trade_file)) {
  log_msg('Importing ATLAS HS92 4-digit country-product-year trade data')
  trade <- fread(trade_file, select = c('country_id','country_iso3_code','product_id','product_hs92_code','year','export_value','import_value','export_rca','pci'), showProgress = FALSE)
  setnames(trade, c('country_id','country_code','product_id','product_code','year','export_value','import_value','source_export_rca','source_pci'))
  trade <- trade[!is.na(country_code) & !is.na(product_code) & !is.na(year)]
  trade[, country_code := toupper(country_code)]
  trade[, product_code := sprintf('%04s', product_code)]
  num_cols <- c('year','export_value','import_value','source_export_rca','source_pci')
  for (cc in num_cols) trade[, (cc) := suppressWarnings(as.numeric(get(cc)))]
  trade[is.na(export_value), export_value := 0]
  trade[is.na(import_value), import_value := 0]
  trade[export_value < 0, export_value := NA_real_]
  trade <- trade[!is.na(export_value)]
  trade <- trade[, .(
    export_value = sum(export_value, na.rm = TRUE),
    import_value = sum(import_value, na.rm = TRUE),
    source_export_rca = mean(source_export_rca, na.rm = TRUE),
    source_pci = mean(source_pci, na.rm = TRUE)
  ), by = .(country_id, country_code, product_id, product_code, year)]
  trade[, total_country_exports := sum(export_value, na.rm = TRUE), by = .(country_code, year)]
  trade[, total_world_exports_product := sum(export_value, na.rm = TRUE), by = .(product_code, year)]
  trade[, total_world_exports := sum(export_value, na.rm = TRUE), by = year]
  trade[, export_share_country := fifelse(total_country_exports > 0, export_value / total_country_exports, NA_real_)]
  trade[, export_share_world_product := fifelse(total_world_exports > 0, total_world_exports_product / total_world_exports, NA_real_)]
  trade[, rca := fifelse(export_share_country > 0 & export_share_world_product > 0, export_share_country / export_share_world_product, 0)]
  trade[, mcp := as.integer(rca >= 1)]
  trade[, mcp_075 := as.integer(rca >= 0.75)]
  trade[, product_chapter := substr(product_code, 1, 2)]
  trade[, product_section := hs_section(product_code)]
  trade[, region := fifelse(country_code %in% lac_iso3, 'Latin America and Caribbean', fifelse(country_code %in% comparators, 'Comparator', 'Rest of world'))]
  arrow::write_parquet(trade, trade_parquet)
  fwrite(trade[country_code %in% lac_iso3], path('data/processed', 'trade_lac_country_product_year.csv'))
  rm(trade); gc()
} else log_msg('Using cached trade_country_product_year.parquet')

log_msg('Loading processed trade data')
trade <- as.data.table(arrow::read_parquet(trade_parquet))
if (any(!is.finite(trade$rca) | is.na(trade$mcp) | is.na(trade$mcp_075))) {
  trade[!is.finite(rca), rca := 0]
  trade[, mcp := as.integer(rca >= 1)]
  trade[, mcp_075 := as.integer(rca >= 0.75)]
  arrow::write_parquet(trade, trade_parquet)
}

log_msg('Writing country and product dictionaries')
prod <- fread(product_file, showProgress = FALSE)
prod[, product_hs92_code := sprintf('%04s', product_hs92_code)]
prod[, product_section := hs_section(product_hs92_code)]
prod[, product_chapter := substr(product_hs92_code, 1, 2)]
fwrite(prod, path('data/processed', 'product_dictionary.csv'))
cty <- fread(country_file, showProgress = FALSE)
cty[, region := fifelse(country_iso3_code %in% lac_iso3, 'Latin America and Caribbean', fifelse(country_iso3_code %in% comparators, 'Comparator', 'Rest of world'))]
fwrite(cty, path('data/processed', 'country_dictionary.csv'))

# Phase 3: indicators ------------------------------------------------------
log_msg('Computing country-year diversification and concentration indicators')
cy <- trade[, .(
  export_value = sum(export_value, na.rm = TRUE),
  import_value = sum(import_value, na.rm = TRUE),
  diversity = sum(mcp == 1, na.rm = TRUE),
  diversity_075 = sum(mcp_075 == 1, na.rm = TRUE),
  hhi = sum((export_value / sum(export_value, na.rm = TRUE))^2, na.rm = TRUE),
  entropy = -sum(fifelse(export_value > 0, (export_value / sum(export_value, na.rm = TRUE)) * log(export_value / sum(export_value, na.rm = TRUE)), 0), na.rm = TRUE),
  primary_share = sum(export_value[product_section %in% c('Animal products','Vegetable products','Fats and oils','Foodstuffs','Minerals')], na.rm = TRUE) / sum(export_value, na.rm = TRUE),
  manufacturing_share = sum(export_value[!product_section %in% c('Animal products','Vegetable products','Fats and oils','Foodstuffs','Minerals')], na.rm = TRUE) / sum(export_value, na.rm = TRUE)
), by = .(country_code, year, region)]

py <- trade[, .(
  world_export_value = sum(export_value, na.rm = TRUE),
  ubiquity = sum(mcp == 1, na.rm = TRUE),
  source_pci = mean(source_pci, na.rm = TRUE)
), by = .(product_code, product_section, product_chapter, year)]

compute_complexity_year <- function(y, data) {
  x <- unique(data[year == y & mcp == 1, .(country_code, product_code)])
  if (nrow(x) < 100) return(NULL)
  countries <- sort(unique(x$country_code)); products <- sort(unique(x$product_code))
  i <- match(x$country_code, countries); j <- match(x$product_code, products)
  M <- sparseMatrix(i = i, j = j, x = 1, dims = c(length(countries), length(products)))
  kc <- Matrix::rowSums(M); kp <- Matrix::colSums(M)
  keep_c <- kc > 0; keep_p <- kp > 0
  M <- M[keep_c, keep_p, drop = FALSE]
  countries <- countries[keep_c]; products <- products[keep_p]
  kc <- Matrix::rowSums(M); kp <- Matrix::colSums(M)
  C <- Diagonal(x = 1 / as.numeric(kc)) %*% M %*% Diagonal(x = 1 / as.numeric(kp)) %*% t(M)
  eg <- eigen(as.matrix(C), symmetric = FALSE)
  ord <- order(Re(eg$values), decreasing = TRUE)
  vec <- Re(eg$vectors[, ord[2]])
  eci <- standardize(vec)
  if (is.finite(stats::cor(eci, as.numeric(kc), use = 'complete.obs')) && stats::cor(eci, as.numeric(kc), use = 'complete.obs') < 0) eci <- -eci
  pci_raw <- as.numeric((t(M) %*% eci) / as.numeric(kp))
  pci <- standardize(pci_raw)
  list(
    country = data.table(year = y, country_code = countries, eci = eci, diversity_complexity = as.numeric(kc)),
    product = data.table(year = y, product_code = products, pci = pci, ubiquity_complexity = as.numeric(kp))
  )
}

complexity_country_file <- path('data/processed', 'country_year_complexity.csv')
complexity_product_file <- path('data/processed', 'product_year_complexity.csv')
if (needs_update(complexity_country_file, trade_parquet)) {
  log_msg('Computing ECI and PCI by year')
  years <- sort(unique(trade$year))
  comp <- lapply(years, function(y) compute_complexity_year(y, trade))
  comp <- comp[!vapply(comp, is.null, logical(1))]
  eci <- rbindlist(lapply(comp, `[[`, 'country'), fill = TRUE)
  pci <- rbindlist(lapply(comp, `[[`, 'product'), fill = TRUE)
  fwrite(eci, complexity_country_file)
  fwrite(pci, complexity_product_file)
} else {
  eci <- fread(complexity_country_file)
  pci <- fread(complexity_product_file)
}

cy <- merge(cy, eci, by = c('country_code','year'), all.x = TRUE)
py <- merge(py, pci, by = c('product_code','year'), all.x = TRUE)
py[, pci_final := fifelse(!is.na(pci), pci, source_pci)]
fwrite(cy, path('outputs/tables/csv', 'country_year_indicators.csv'))
fwrite(py, path('outputs/tables/csv', 'product_year_indicators.csv'))

# Macro panel --------------------------------------------------------------
log_msg('Building country-year panel with CEPII macro controls')
macro <- fread(macro_file, showProgress = FALSE)
setnames(macro, old = intersect(names(macro), c('iso3c')), new = 'country_code')
macro[, country_code := toupper(country_code)]
macro[, year := as.integer(year)]
keep_macro <- intersect(names(macro), c('country','country_code','year','population_thousands','gdp_current_thousand_usd','gdp_pc_current_thousand_usd','gdp_ppp_current_thousand_int_usd','gdp_pc_ppp_current_thousand_int_usd','gdp_ppp_pwt_2011_thousand_usd','gatt','wto'))
macro <- macro[, ..keep_macro]
for (nm in setdiff(names(macro), c('country','country_code'))) macro[, (nm) := suppressWarnings(as.numeric(get(nm)))]
panel <- merge(cy, macro, by = c('country_code','year'), all.x = TRUE)
setorder(panel, country_code, year)
panel[, gdp_pc_ppp_growth := 100 * (log(gdp_pc_ppp_current_thousand_int_usd) - shift(log(gdp_pc_ppp_current_thousand_int_usd))), by = country_code]
panel[, gdp_pc_ppp_growth_f5 := 100 * (shift(log(gdp_pc_ppp_current_thousand_int_usd), type = 'lead', n = 5) - log(gdp_pc_ppp_current_thousand_int_usd)) / 5, by = country_code]
fwrite(panel, path('data/processed', 'country_year_panel.csv'))

# Phase 4: Product Space and Bolivia opportunities ------------------------
bol_year <- max(trade[country_code == 'BOL' & total_country_exports > 0, year], na.rm = TRUE)
log_msg('Building Product Space for Bolivia reference year ', bol_year)
latest <- unique(trade[year == bol_year & mcp == 1, .(country_code, product_code)])
products <- sort(unique(latest$product_code)); countries <- sort(unique(latest$country_code))
M <- sparseMatrix(i = match(latest$country_code, countries), j = match(latest$product_code, products), x = 1, dims = c(length(countries), length(products)))
kp <- as.numeric(Matrix::colSums(M))
co <- as.matrix(t(M) %*% M)
phi <- pmin(t(t(co) / kp), co / kp)
diag(phi) <- 0
rownames(phi) <- colnames(phi) <- products
phi[!is.finite(phi)] <- 0
threshold <- 0.55
edge_idx <- which(phi >= threshold & upper.tri(phi), arr.ind = TRUE)
edges <- data.table(from = products[edge_idx[,1]], to = products[edge_idx[,2]], proximity = phi[edge_idx])
if (nrow(edges) > 8000) edges <- edges[order(-proximity)][1:8000]
fwrite(edges, path('outputs/networks', 'product_space_edges.csv'))

current_bol <- unique(trade[country_code == 'BOL' & year == bol_year & mcp == 1, product_code])
all_prod <- sort(unique(trade[year == bol_year, product_code]))
product_stats <- merge(py[year == bol_year, .(product_code, product_section, product_chapter, world_export_value, pci_final, ubiquity)], prod[, .(product_code = sprintf('%04s', product_hs92_code), product_name, product_name_short, natural_resource)], by = 'product_code', all.x = TRUE)
world_hist <- trade[year %in% ((bol_year-5):bol_year), .(world_exports = sum(export_value, na.rm = TRUE)), by = .(product_code, year)]
growth <- dcast(world_hist, product_code ~ year, value.var = 'world_exports')
y0 <- as.character(bol_year - 5); y1 <- as.character(bol_year)
if (all(c(y0, y1) %in% names(growth))) growth[, demand_growth := fifelse(get(y0) > 0 & get(y1) > 0, (get(y1) / get(y0))^(1/5) - 1, NA_real_)] else growth[, demand_growth := NA_real_]
product_stats <- merge(product_stats, growth[, .(product_code, demand_growth)], by = 'product_code', all.x = TRUE)

bol_idx <- match(current_bol, products); bol_idx <- bol_idx[!is.na(bol_idx)]
opps <- product_stats[!product_code %in% current_bol]
opps <- opps[product_code %in% products]
opps[, density := vapply(product_code, function(p) { idx <- match(p, products); den <- sum(phi[idx, ], na.rm = TRUE); if (den == 0) 0 else sum(phi[idx, bol_idx], na.rm = TRUE) / den }, numeric(1))]
opps[, opportunity_gain := vapply(product_code, function(p) { idx <- match(p, products); vals <- product_stats[match(products, product_code), pci_final]; sum(phi[idx, ] * pmax(vals, 0), na.rm = TRUE) }, numeric(1))]
opps[, world_market_size := world_export_value]
opps[, `:=`(
  density_n = safe_minmax(density),
  pci_n = safe_minmax(pci_final),
  opportunity_gain_n = safe_minmax(opportunity_gain),
  world_market_n = safe_minmax(log1p(world_market_size)),
  demand_growth_n = safe_minmax(demand_growth)
)]
score_weights <- c(density_n = 0.35, pci_n = 0.25, opportunity_gain_n = 0.20, world_market_n = 0.10, demand_growth_n = 0.10)
opps[, opportunity_score := {
  m <- as.matrix(.SD)
  weighted <- sweep(m, 2, score_weights, `*`)
  denom <- rowSums(sweep(!is.na(m), 2, score_weights, `*`))
  fifelse(denom > 0, rowSums(weighted, na.rm = TRUE) / denom, NA_real_)
}, .SDcols = names(score_weights)]
opps[, distance := 1 - density]
opps[, opportunity_type := fifelse(density_n >= 0.66 & pci_n >= 0.50, 'Quick wins', fifelse(pci_n >= 0.70 & opportunity_gain_n >= 0.60 & density_n >= 0.33, 'Strategic bets', fifelse(density_n >= 0.66 & pci_n < 0.50, 'Low-value extensions', 'Long shots')))]
setorder(opps, -opportunity_score)
fwrite(opps, path('outputs/tables/csv', 'bolivia_opportunities.csv'))
openxlsx::write.xlsx(list(
  top20 = opps[1:min(.N,20)],
  quick_wins = opps[opportunity_type == 'Quick wins'][1:min(.N,10)],
  strategic_bets = opps[opportunity_type == 'Strategic bets'][1:min(.N,10)]
), file = path('outputs/tables/xlsx', 'bolivia_opportunities.xlsx'), overwrite = TRUE)

# Phase 6: cautious econometrics ------------------------------------------
log_msg('Running cautious panel model where macro coverage permits')
model_file <- path('outputs/models', 'growth_panel_model.rds')
model_data <- panel[region == 'Latin America and Caribbean' & is.finite(gdp_pc_ppp_growth_f5) & is.finite(eci) & is.finite(hhi) & is.finite(diversity)]
if (nrow(model_data) > 100 && length(unique(model_data$country_code)) > 5) {
  model <- fixest::feols(gdp_pc_ppp_growth_f5 ~ eci + hhi + log1p(diversity) | country_code + year, cluster = ~country_code, data = model_data)
  saveRDS(model, model_file)
  capture.output(summary(model), file = path('outputs/tables/html', 'growth_panel_model.txt'))
} else {
  model <- NULL
  writeLines('Insufficient complete observations for the planned panel model.', path('outputs/tables/html', 'growth_panel_model.txt'))
}

# Phase 7: figures ---------------------------------------------------------
log_msg('Creating figures')
theme_project <- function() theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), plot.title = element_text(face = 'bold'), plot.subtitle = element_text(color = 'grey30'))

plot_eci <- cy[region == 'Latin America and Caribbean' & !is.na(eci)]
p1 <- ggplot(plot_eci, aes(year, eci, group = country_code)) +
  stat_summary(aes(group = 1), fun = median, geom = 'line', linewidth = 1.1, color = '#1F4E79') +
  geom_line(data = plot_eci[country_code != 'BOL'], color = 'grey70', linewidth = 0.25, alpha = 0.5) +
  geom_line(data = plot_eci[country_code == 'BOL'], color = '#C00000', linewidth = 1.1) +
  labs(title = 'Bolivia trails the regional median in economic complexity', subtitle = 'HS92 4-digit ECI recomputed from local ATLAS export values; blue line is the LAC median', x = NULL, y = 'ECI') + theme_project()
ggsave(path('outputs/figures/png', 'eci_latin_america_trends.png'), p1, width = 8, height = 4.8, dpi = 180)

yr_income <- max(panel[region == 'Latin America and Caribbean' & !is.na(eci) & !is.na(gdp_pc_ppp_current_thousand_int_usd), year], na.rm = TRUE)
p2dat <- panel[year == yr_income & region == 'Latin America and Caribbean' & !is.na(eci) & !is.na(gdp_pc_ppp_current_thousand_int_usd)]
p2 <- ggplot(p2dat, aes(eci, gdp_pc_ppp_current_thousand_int_usd * 1000, label = country_code)) +
  geom_point(aes(color = country_code == 'BOL'), size = 2.5, alpha = 0.85) +
  geom_smooth(method = 'lm', se = TRUE, color = 'grey35', linewidth = 0.6) +
  ggrepel::geom_text_repel(data = p2dat[country_code == 'BOL' | eci > quantile(eci, 0.85, na.rm = TRUE)], size = 3, max.overlaps = 20, show.legend = FALSE) +
  scale_color_manual(values = c('TRUE' = '#C00000','FALSE' = '#6C8EBF'), guide = 'none') +
  scale_y_log10(labels = scales::dollar_format()) +
  labs(title = 'More complex export baskets are associated with higher income in Latin America', subtitle = paste('GDP per capita PPP and recomputed ECI,', yr_income), x = 'ECI', y = 'GDP per capita, PPP') + theme_project()
ggsave(path('outputs/figures/png', 'complexity_income.png'), p2, width = 7, height = 5, dpi = 180)

p3 <- ggplot(opps[1:min(.N, 150)], aes(density, pci_final, color = opportunity_type, size = world_market_size)) +
  geom_point(alpha = 0.75) +
  scale_size_continuous(range = c(1.2, 7)) +
  labs(title = 'Bolivia opportunities cluster by feasibility and complexity', subtitle = paste('Non-RCA products in', bol_year, 'ranked by density, PCI, opportunity gain, market size, and demand growth'), x = 'Density near current capabilities', y = 'Product complexity (PCI)', color = NULL, size = 'World market') + theme_project()
ggsave(path('outputs/figures/png', 'bolivia_density_pci.png'), p3, width = 8, height = 5.2, dpi = 180)

png(path('outputs/figures/png', 'bolivia_product_space.png'), width = 1400, height = 950, res = 160)
if (nrow(edges) > 0) {
  g <- igraph::graph_from_data_frame(edges, directed = FALSE, vertices = product_stats[product_code %in% unique(c(edges$from, edges$to)), .(name = product_code, section = product_section)])
  V(g)$color <- ifelse(V(g)$name %in% current_bol, '#C00000', '#8AA6C1')
  V(g)$size <- ifelse(V(g)$name %in% current_bol, 5, 2)
  plot(g, vertex.label = NA, edge.width = E(g)$proximity * 1.5, edge.color = adjustcolor('grey65', 0.35), main = paste('Bolivia in the HS92 Product Space,', bol_year))
} else plot.new()
dev.off()

# Phase 8: validation and lightweight paper assets -------------------------
log_msg('Writing validation report and documentation assets')
validation <- list(
  trade_rows = nrow(trade),
  countries = uniqueN(trade$country_code),
  products = uniqueN(trade$product_code),
  years = paste(range(trade$year, na.rm = TRUE), collapse = '-'),
  bolivia_year = bol_year,
  negative_exports = nrow(trade[export_value < 0]),
  missing_rca = nrow(trade[!is.finite(rca)]),
  eci_mean_abs_max = max(abs(cy[, mean(eci, na.rm = TRUE), by = year]$V1), na.rm = TRUE),
  opportunity_score_range = paste(round(range(opps$opportunity_score, na.rm = TRUE), 4), collapse = ' to ')
)
html <- c('<html><head><meta charset="utf-8"><title>Validation Report</title></head><body>', '<h1>Validation Report</h1>', '<table border="1" cellspacing="0" cellpadding="4">', paste0('<tr><td>', names(validation), '</td><td>', unlist(validation), '</td></tr>'), '</table>', '<p>All checks are descriptive and tied to locally available data. No external data were downloaded.</p>', '</body></html>')
writeLines(html, path('outputs/reports', 'VALIDATION_REPORT.html'))

summary_lines <- c(
  '# Key Findings', '',
  paste0('- The audit identified a viable ATLAS HS92 trade source covering ', validation$years, ' with Bolivia present through ', bol_year, '.'),
  '- RCA, diversity, ubiquity, HHI, entropy, ECI, PCI approximation, Product Space, density, and opportunity scores were generated from local data.',
  '- Econometric outputs are observational and should not be interpreted causally.'
)
writeLines(summary_lines, path('paper', 'key_findings.md'))
writeLines(c('# Limitations', '', '- Product complexity is recomputed with a country-side eigenvector and product-side projection to keep the workflow tractable without additional eigensolver packages.', '- GDP controls rely on the local CEPII Gravity country-year panel and are not a substitute for a fully harmonized national accounts database.', '- No references were downloaded or verified online.'), path('paper', 'limitations.md'))
writeLines(c('# References To Verify', '', '- Hidalgo, C. A. and Hausmann, R. Economic complexity and the Product Space. Verify bibliographic details before citation.', '- Hausmann, Hidalgo et al. Atlas of Economic Complexity. Verify bibliographic details before citation.'), path('paper', 'references_to_verify.md'))
writeLines(c('---','title: "Economic Complexity and Structural Transformation in Latin America"','format: html','---','','# Abstract','','This draft is generated from local outputs. Fill the abstract after reviewing the final tables and figures.','','# Data','','The project uses local ATLAS HS92 trade files, local CEPII macro controls, and the completed data inventory.','','# Results','','See `outputs/tables/csv`, `outputs/figures/png`, and `outputs/reports/VALIDATION_REPORT.html`.','','# Limitations','','See `paper/limitations.md`.'), path('paper', 'main.qmd'))

log_msg('Pipeline complete')
