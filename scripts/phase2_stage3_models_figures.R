options(stringsAsFactors = FALSE, scipen = 999)
set.seed(20260711)
root <- normalizePath(getwd(), winslash = '/', mustWork = TRUE)
p <- function(...) file.path(root, ...)
for (d in c('docs','outputs/tables/csv','outputs/figures/png','outputs/figures/pdf','outputs/models','outputs/reports','outputs/networks')) {
  if (!dir.exists(p(d))) dir.create(p(d), recursive = TRUE)
}

library(data.table)
library(ggplot2)
library(scales)
library(fixest)
library(igraph)

normalize_hs4 <- function(x) {
  x <- trimws(as.character(x))
  ok <- !is.na(x) & grepl('^[0-9]+$', x) & nchar(x) < 4
  x[ok] <- sprintf('%04d', as.integer(x[ok]))
  x
}
rescale01 <- function(x) {
  x <- as.numeric(x)
  rng <- range(x, na.rm = TRUE)
  if (!all(is.finite(rng)) || diff(rng) == 0) return(rep(0.5, length(x)))
  (x - rng[1]) / diff(rng)
}
clean_label <- function(x, n = 48) {
  x <- ifelse(is.na(x) | x == '', 'Unlabeled', x)
  ifelse(nchar(x) > n, paste0(substr(x, 1, n - 3), '...'), x)
}
save_plot <- function(g, stem, width = 8.5, height = 5.5) {
  ggsave(p('outputs/figures/png', paste0(stem, '.png')), g, width = width, height = height, dpi = 300, bg = 'white')
  ggsave(p('outputs/figures/pdf', paste0(stem, '.pdf')), g, width = width, height = height, device = cairo_pdf, bg = 'white')
}
base_theme <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title.position = 'plot', legend.position = 'bottom')

cy <- fread(p('outputs/tables/csv/country_year_indicators.csv'))
panel <- fread(p('data/processed/country_year_panel.csv'))
py <- fread(p('outputs/tables/csv/product_year_indicators.csv'))
opp <- fread(p('outputs/tables/csv/bolivia_opportunities_revised.csv'))
edges <- fread(p('outputs/networks/product_space_visual_edges.csv'))
trade <- as.data.table(arrow::read_parquet(p('data/processed/trade_country_product_year.parquet')))

for (dt in list(py, opp, edges, trade)) {
  if ('product_code' %in% names(dt)) dt[, product_code := normalize_hs4(product_code)]
}
edges[, from := normalize_hs4(from)]
edges[, to := normalize_hs4(to)]

num <- function(x) suppressWarnings(as.numeric(x))
panel[, gdppc := fifelse(is.finite(num(gdp_pc_ppp_current_thousand_int_usd)), num(gdp_pc_ppp_current_thousand_int_usd) * 1000, NA_real_)]
panel[!is.finite(gdppc), gdppc := fifelse(is.finite(num(gdp_ppp_pwt_2011_thousand_usd)) & is.finite(num(population_thousands)) & num(population_thousands) > 0, num(gdp_ppp_pwt_2011_thousand_usd) / num(population_thousands), NA_real_)]
panel[!is.finite(gdppc), gdppc := fifelse(is.finite(num(gdp_pc_current_thousand_usd)), num(gdp_pc_current_thousand_usd) * 1000, NA_real_)]
panel[, log_gdppc := log(gdppc)]
setorder(panel, country_code, year)
panel[, growth_f5 := num(gdp_pc_ppp_growth_f5)]
panel[!is.finite(growth_f5), growth_f5 := shift(log_gdppc, 5, type = 'lead') - log_gdppc, by = country_code]
panel[, growth_1y := log_gdppc - shift(log_gdppc), by = country_code]
roll_sd5 <- function(x) {
  out <- rep(NA_real_, length(x))
  if (length(x) >= 5) {
    for (i in seq_along(x)) {
      if (i >= 5) out[i] <- sd(x[(i - 4):i], na.rm = TRUE)
    }
  }
  out[!is.finite(out)] <- NA_real_
  out
}
panel[, growth_volatility := roll_sd5(growth_1y), by = country_code]
country_names <- panel[!is.na(country) & country != '', .(country = country[1]), by = country_code]
cy <- merge(cy, country_names, by = 'country_code', all.x = TRUE)
cy <- merge(cy, panel[, .(country_code, year, gdppc, log_gdppc)], by = c('country_code','year'), all.x = TRUE)

latest_year <- max(cy[country_code == 'BOL' & export_value > 0, year], na.rm = TRUE)
lac_region <- 'Latin America and Caribbean'
lac_codes <- cy[region == lac_region, sort(unique(country_code))]

# Structural peers for Bolivia.
peer_vars <- c('eci','diversity','hhi','primary_share','manufacturing_share')
latest_lac <- cy[region == lac_region & year == latest_year]
peer_base <- latest_lac[complete.cases(latest_lac[, ..peer_vars])]
zstats <- peer_base[, lapply(.SD, function(x) c(mean = mean(x), sd = sd(x))), .SDcols = peer_vars]
bol <- peer_base[country_code == 'BOL']
for (v in peer_vars) {
  m <- mean(peer_base[[v]], na.rm = TRUE)
  s <- sd(peer_base[[v]], na.rm = TRUE)
  peer_base[, paste0('z_', v) := if (is.finite(s) && s > 0) (get(v) - m) / s else 0]
}
bol_z <- peer_base[country_code == 'BOL', paste0('z_', peer_vars), with = FALSE]
peer_base[, structural_distance := sqrt(rowSums((as.matrix(.SD) - as.numeric(bol_z[1]))^2, na.rm = TRUE)), .SDcols = paste0('z_', peer_vars)]
peers <- peer_base[country_code != 'BOL'][order(structural_distance)][1:min(.N, 15)]
peers_out <- peers[, .(peer_rank = .I, peer_country_code = country_code, peer_country = country, structural_distance, eci, diversity, hhi, primary_share, manufacturing_share, export_value)]
for (v in peer_vars) peers_out[, paste0('bolivia_', v) := bol[[v]]]
fwrite(peers_out, p('outputs/tables/csv/bolivia_structural_peers.csv'))

# Econometric model audit.
model_all <- copy(panel[region == lac_region])
model_all[, country_code := as.factor(country_code)]
model_all[, year := as.factor(year)]
model_vars <- c('log_gdppc','growth_f5','growth_volatility','eci','hhi','diversity','primary_share','manufacturing_share')
missingness <- rbindlist(lapply(model_vars, function(v) {
  x <- model_all[[v]]
  data.table(variable = v, rows = nrow(model_all), missing_or_nonfinite = sum(!is.finite(num(x))), share_missing_or_nonfinite = mean(!is.finite(num(x))))
}))
fwrite(missingness, p('outputs/tables/csv/model_missingness.csv'))
sample_comp <- model_all[, .(rows = .N, countries = uniqueN(country_code), min_year = min(as.integer(as.character(year))), max_year = max(as.integer(as.character(year))), rows_with_log_gdppc = sum(is.finite(log_gdppc)), rows_with_growth_f5 = sum(is.finite(growth_f5)), rows_with_volatility = sum(is.finite(growth_volatility))), by = region]
fwrite(sample_comp, p('outputs/tables/csv/model_sample_composition.csv'))
models <- list()
models$income_level <- feols(log_gdppc ~ eci + hhi + log1p(diversity) + manufacturing_share | country_code + year, data = model_all, vcov = ~country_code, notes = FALSE)
models$future_growth <- feols(growth_f5 ~ eci + log_gdppc + hhi + log1p(diversity) | country_code + year, data = model_all, vcov = ~country_code, notes = FALSE)
models$growth_volatility <- feols(growth_volatility ~ eci + hhi + log1p(diversity) | country_code + year, data = model_all, vcov = ~country_code, notes = FALSE)
coef_dt <- rbindlist(lapply(names(models), function(nm) {
  ct <- as.data.table(coeftable(models[[nm]]), keep.rownames = 'term')
  setnames(ct, old = names(ct), new = make.names(names(ct)))
  data.table(model = nm, term = ct$term, estimate = ct$Estimate, std_error = ct$Std..Error, statistic = ct$t.value, p_value = ct$Pr...t.., nobs = nobs(models[[nm]]), r2 = as.numeric(fitstat(models[[nm]], 'r2')[[1]]), within_r2 = as.numeric(fitstat(models[[nm]], 'wr2')[[1]]))
}), fill = TRUE)
fwrite(coef_dt, p('outputs/tables/csv/econometric_model_summary.csv'))
saveRDS(models, p('outputs/models/phase2_fixed_effects_models.rds'))
writeLines(c(
  '# Econometric Model Audit',
  '',
  'All models are observational fixed-effects regressions over Latin America and the Caribbean. Standard errors are clustered by country. These specifications describe conditional associations and are not causal estimates.',
  '',
  paste0('- Model sample rows: ', sample_comp$rows[1], '; countries: ', sample_comp$countries[1], '; years: ', sample_comp$min_year[1], '-', sample_comp$max_year[1], '.'),
  paste0('- Income-level model observations: ', nobs(models$income_level), '.'),
  paste0('- Five-year-ahead growth model observations: ', nobs(models$future_growth), '.'),
  paste0('- Growth-volatility model observations: ', nobs(models$growth_volatility), '.'),
  '',
  'Main safeguards:',
  '',
  '- Country and year fixed effects absorb time-invariant country heterogeneity and common annual shocks.',
  '- The five-year growth outcome is forward-looking and drops observations without adequate future GDP coverage.',
  '- Coefficients should be read with the validation tables and missingness report, not as policy treatment effects.',
  '',
  'Machine-readable outputs: `outputs/tables/csv/econometric_model_summary.csv`, `outputs/tables/csv/model_missingness.csv`, and `outputs/tables/csv/model_sample_composition.csv`.'
), p('docs/ECONOMETRIC_MODEL_AUDIT.md'), useBytes = TRUE)

# Figures.
highlight <- c('BOL','BRA','MEX','CHL','PER','COL','ARG')
lac_hist <- cy[region == lac_region & !is.na(eci)]
fig1 <- ggplot(lac_hist, aes(year, eci, group = country_code)) +
  geom_line(color = 'grey78', linewidth = 0.35, alpha = 0.65) +
  geom_line(data = lac_hist[country_code %in% highlight], aes(color = country_code), linewidth = 0.9) +
  geom_hline(yintercept = 0, color = 'grey45', linewidth = 0.25) +
  scale_color_manual(values = c(ARG = '#7b3294', BOL = '#c23b22', BRA = '#1b7837', CHL = '#2166ac', COL = '#fdae61', MEX = '#008080', PER = '#5aae61')) +
  labs(title = 'Economic complexity trajectories in Latin America', x = NULL, y = 'ECI', color = NULL) + base_theme
save_plot(fig1, '01_eci_latin_america_trends', 9, 5.4)
file.copy(p('outputs/figures/png/01_eci_latin_america_trends.png'), p('outputs/figures/png/eci_latin_america_trends.png'), overwrite = TRUE)

latest_plot <- cy[year == latest_year & is.finite(eci) & is.finite(log_gdppc) & gdppc > 0]
fig2 <- ggplot(latest_plot, aes(eci, gdppc)) +
  geom_point(aes(color = region == lac_region, size = export_value), alpha = 0.72) +
  geom_point(data = latest_plot[country_code == 'BOL'], shape = 21, fill = '#c23b22', color = 'black', size = 4, stroke = 0.8) +
  geom_smooth(method = 'lm', se = FALSE, color = 'grey35', linewidth = 0.6) +
  scale_y_log10(labels = label_dollar()) +
  scale_size_continuous(labels = label_number(scale_cut = cut_short_scale()), range = c(1.5, 8)) +
  scale_color_manual(values = c('TRUE' = '#2166ac', 'FALSE' = '#8c8c8c'), labels = c('Other regions','Latin America')) +
  labs(title = 'Complexity and income, latest available year', x = 'ECI', y = 'GDP per capita, PPP/proxy', color = NULL, size = 'Exports') + base_theme
if (requireNamespace('ggrepel', quietly = TRUE)) {
  fig2 <- fig2 + ggrepel::geom_text_repel(data = latest_plot[country_code %in% highlight], aes(label = country_code), size = 3, max.overlaps = 20)
}
save_plot(fig2, '02_complexity_income', 8, 5.4)
file.copy(p('outputs/figures/png/02_complexity_income.png'), p('outputs/figures/png/complexity_income.png'), overwrite = TRUE)

fig3_dt <- latest_lac[is.finite(hhi) & is.finite(diversity)]
fig3 <- ggplot(fig3_dt, aes(diversity, hhi)) +
  geom_point(aes(color = primary_share, size = export_value), alpha = 0.78) +
  geom_point(data = fig3_dt[country_code == 'BOL'], shape = 21, fill = '#c23b22', color = 'black', size = 4, stroke = 0.8) +
  scale_color_gradient2(low = '#2c7bb6', mid = '#ffffbf', high = '#d7191c', midpoint = median(fig3_dt$primary_share, na.rm = TRUE), labels = percent) +
  scale_size_continuous(labels = label_number(scale_cut = cut_short_scale()), range = c(1.5, 7)) +
  labs(title = 'Diversity and export concentration in Latin America', x = 'Diversity: HS4 products with RCA >= 1', y = 'HHI export concentration', color = 'Primary share', size = 'Exports') + base_theme
if (requireNamespace('ggrepel', quietly = TRUE)) {
  fig3 <- fig3 + ggrepel::geom_text_repel(data = fig3_dt[country_code %in% c(highlight, peers$country_code[1:3])], aes(label = country_code), size = 3, max.overlaps = 25)
}
save_plot(fig3, '03_diversity_concentration', 8, 5.4)

comp <- latest_lac[export_value > 0, .(country_code, export_value, primary_share, manufacturing_share)]
comp[, other_share := pmax(0, 1 - primary_share - manufacturing_share)]
comp <- comp[order(-export_value)][1:min(.N, 22)]
comp_long <- melt(comp, id.vars = 'country_code', measure.vars = c('primary_share','manufacturing_share','other_share'), variable.name = 'component', value.name = 'share')
comp_long[, component := factor(component, levels = c('primary_share','manufacturing_share','other_share'), labels = c('Primary','Manufacturing','Other'))]
fig4 <- ggplot(comp_long, aes(reorder(country_code, share, sum), share, fill = component)) +
  geom_col(width = 0.78) + coord_flip() + scale_y_continuous(labels = percent) +
  scale_fill_manual(values = c(Primary = '#b35806', Manufacturing = '#1f78b4', Other = '#7f7f7f')) +
  labs(title = 'Export composition among larger Latin American exporters', x = NULL, y = 'Share of exports', fill = NULL) + base_theme
save_plot(fig4, '04_lac_export_composition', 8, 6)

bol_ts <- cy[country_code == 'BOL', .(year, eci, hhi, primary_share, manufacturing_share, diversity)]
reg_ts <- cy[region == lac_region, .(eci = median(eci, na.rm = TRUE), hhi = median(hhi, na.rm = TRUE), primary_share = median(primary_share, na.rm = TRUE), manufacturing_share = median(manufacturing_share, na.rm = TRUE), diversity = median(diversity, na.rm = TRUE)), by = year]
bol_long <- melt(bol_ts, id.vars = 'year', variable.name = 'indicator', value.name = 'value')[, series := 'Bolivia']
reg_long <- melt(reg_ts, id.vars = 'year', variable.name = 'indicator', value.name = 'value')[, series := 'LAC median']
dash <- rbind(bol_long, reg_long)
dash[, indicator := factor(indicator, levels = c('eci','diversity','hhi','primary_share','manufacturing_share'), labels = c('ECI','Diversity','HHI','Primary share','Manufacturing share'))]
fig5 <- ggplot(dash, aes(year, value, color = series)) + geom_line(linewidth = 0.85) +
  facet_wrap(~indicator, scales = 'free_y', ncol = 2) +
  scale_color_manual(values = c('Bolivia' = '#c23b22', 'LAC median' = '#2166ac')) +
  labs(title = 'Bolivia structural transformation dashboard', x = NULL, y = NULL, color = NULL) + base_theme
save_plot(fig5, '05_bolivia_structural_dashboard', 8.5, 6.2)

current_bol <- unique(trade[country_code == 'BOL' & year == latest_year & mcp == 1, product_code])
vertices <- data.table(product_code = sort(unique(c(edges$from, edges$to))))
g <- graph_from_data_frame(edges[, .(from, to, proximity)], directed = FALSE, vertices = vertices[, .(name = product_code)])
set.seed(20260711)
lay <- layout_with_fr(g, weights = E(g)$proximity, niter = 1500)
nodes <- data.table(product_code = V(g)$name, x = lay[, 1], y = lay[, 2])
latest_py <- py[year == latest_year, .(product_code, product_section, pci_final, world_export_value)]
nodes <- merge(nodes, latest_py, by = 'product_code', all.x = TRUE)
nodes <- merge(nodes, opp[, .(product_code, relative_category, feasibility_score, transformation_score)], by = 'product_code', all.x = TRUE)
nodes[, status := fifelse(product_code %in% current_bol, 'Bolivia RCA >= 1', fifelse(relative_category == 'Strategic bets', 'Strategic bets', fifelse(relative_category == 'Incremental extensions', 'Incremental extensions', fifelse(!is.na(relative_category), 'Other opportunity', 'Other product'))))]
edge_xy <- merge(edges, nodes[, .(from = product_code, x, y)], by = 'from')
edge_xy <- merge(edge_xy, nodes[, .(to = product_code, xend = x, yend = y)], by = 'to')
fig6 <- ggplot() +
  geom_segment(data = edge_xy, aes(x = x, y = y, xend = xend, yend = yend, alpha = proximity), color = 'grey70', linewidth = 0.25) +
  geom_point(data = nodes, aes(x, y, fill = status, size = pmax(world_export_value, 1)), shape = 21, color = 'white', stroke = 0.15, alpha = 0.9) +
  scale_fill_manual(values = c('Bolivia RCA >= 1' = '#c23b22', 'Strategic bets' = '#7b3294', 'Incremental extensions' = '#1b7837', 'Other opportunity' = '#fdae61', 'Other product' = '#737373')) +
  scale_alpha(range = c(0.12, 0.55), guide = 'none') + scale_size_continuous(range = c(1.1, 6), labels = label_number(scale_cut = cut_short_scale())) +
  guides(size = 'none') + coord_equal() +
  labs(title = 'Bolivia in the 2023 Product Space visual network', x = NULL, y = NULL, fill = NULL) +
  theme_void(base_size = 11) + theme(legend.position = 'bottom', plot.title = element_text(face = 'bold', hjust = 0))
save_plot(fig6, '06_bolivia_product_space', 8.5, 6.5)
file.copy(p('outputs/figures/png/06_bolivia_product_space.png'), p('outputs/figures/png/bolivia_product_space.png'), overwrite = TRUE)
file.copy(p('outputs/figures/png/06_bolivia_product_space.png'), p('outputs/figures/png/bolivia_product_space_editorial.png'), overwrite = TRUE)

fig7 <- ggplot(opp[eligible == TRUE], aes(density, pci_final)) +
  geom_point(aes(color = relative_category, size = world_market_size), alpha = 0.72) +
  geom_vline(xintercept = median(opp[eligible == TRUE]$density, na.rm = TRUE), color = 'grey55', linetype = 'dashed') +
  geom_hline(yintercept = median(opp[eligible == TRUE]$pci_final, na.rm = TRUE), color = 'grey55', linetype = 'dashed') +
  scale_color_manual(values = c('Strategic bets' = '#7b3294', 'Incremental extensions' = '#1b7837', 'Transformational long shots' = '#d95f02', 'Middle-range candidates' = '#2166ac', 'Low-priority products' = '#737373')) +
  scale_size_continuous(labels = label_number(scale_cut = cut_short_scale()), range = c(1.5, 7)) +
  labs(title = 'Bolivia opportunity density and complexity', x = 'Density to current capabilities', y = 'PCI', color = NULL, size = 'World market') + base_theme
save_plot(fig7, '07_bolivia_density_pci', 8, 5.7)
file.copy(p('outputs/figures/png/07_bolivia_density_pci.png'), p('outputs/figures/png/bolivia_density_pci.png'), overwrite = TRUE)

matrix_dt <- opp[eligible == TRUE & is.finite(feasibility_score) & is.finite(transformation_score)]
label_dt <- unique(rbind(head(matrix_dt[order(-feasibility_score)], 6), head(matrix_dt[order(-transformation_score)], 6), fill = TRUE), by = 'product_code')
fig8 <- ggplot(matrix_dt, aes(feasibility_score, transformation_score)) +
  geom_point(aes(color = relative_category, size = world_market_size), alpha = 0.68) +
  geom_vline(xintercept = median(matrix_dt$feasibility_score, na.rm = TRUE), color = 'grey55', linetype = 'dashed') +
  geom_hline(yintercept = median(matrix_dt$transformation_score, na.rm = TRUE), color = 'grey55', linetype = 'dashed') +
  scale_color_manual(values = c('Strategic bets' = '#7b3294', 'Incremental extensions' = '#1b7837', 'Transformational long shots' = '#d95f02', 'Middle-range candidates' = '#2166ac', 'Low-priority products' = '#737373')) +
  scale_size_continuous(labels = label_number(scale_cut = cut_short_scale()), range = c(1.2, 6)) +
  labs(title = 'Feasibility versus transformation potential', x = 'Feasibility score', y = 'Transformation score', color = NULL, size = 'World market') + base_theme
if (requireNamespace('ggrepel', quietly = TRUE)) {
  fig8 <- fig8 + ggrepel::geom_text_repel(data = label_dt, aes(label = product_code), size = 2.8, max.overlaps = 20)
}
save_plot(fig8, '08_bolivia_opportunity_matrix', 8, 5.7)

top_opp <- head(matrix_dt[order(-transformation_score)], 15)
top_opp[, label := paste0(product_code, ' ', clean_label(product_name_short, 32))]
fig9 <- ggplot(top_opp, aes(reorder(label, transformation_score), transformation_score, fill = relative_category)) +
  geom_col(width = 0.75) + coord_flip() +
  scale_fill_manual(values = c('Strategic bets' = '#7b3294', 'Incremental extensions' = '#1b7837', 'Transformational long shots' = '#d95f02', 'Middle-range candidates' = '#2166ac', 'Low-priority products' = '#737373')) +
  labs(title = 'Top Bolivia transformation opportunities', x = NULL, y = 'Transformation score', fill = NULL) + base_theme
save_plot(fig9, '09_bolivia_top_opportunities', 8.5, 5.8)

coef_plot <- coef_dt[term != '(Intercept)']
coef_plot[, `:=`(lo = estimate - 1.96 * std_error, hi = estimate + 1.96 * std_error)]
fig10 <- ggplot(coef_plot, aes(estimate, reorder(term, estimate))) +
  geom_vline(xintercept = 0, color = 'grey50', linewidth = 0.35) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.12, color = '#4d4d4d') +
  geom_point(color = '#2166ac', size = 2.2) +
  facet_wrap(~model, scales = 'free_x') +
  labs(title = 'Fixed-effects model coefficients', x = 'Estimate with 95 percent CI', y = NULL) + base_theme
save_plot(fig10, '10_model_coefficients', 8.7, 5.3)

# Peer trajectory figure.
peer_codes <- c('BOL', peers$country_code[1:min(6, nrow(peers))])
peer_traj <- cy[country_code %in% peer_codes]
fig_peer <- ggplot(peer_traj, aes(year, eci, color = country_code)) + geom_line(linewidth = 0.9) +
  scale_color_manual(values = c(BOL = '#c23b22', setNames(hue_pal()(length(setdiff(peer_codes, 'BOL'))), setdiff(peer_codes, 'BOL')))) +
  labs(title = 'Bolivia and nearest structural peers', x = NULL, y = 'ECI', color = NULL) + base_theme
save_plot(fig_peer, 'bolivia_peer_trajectories', 8, 5)

# Interactive Product Space/opportunity HTML.
interactive_file <- p('outputs/figures/png/bolivia_product_space_interactive.html')
tryCatch({
  if (!requireNamespace('plotly', quietly = TRUE) || !requireNamespace('htmlwidgets', quietly = TRUE)) stop('plotly/htmlwidgets unavailable')
  int_dt <- nodes[!is.na(status)]
  int_dt[, text := paste0(product_code, '<br>', ifelse(is.na(product_section), 'Unknown section', product_section), '<br>', status, '<br>PCI: ', round(pci_final, 2))]
  w <- plotly::plot_ly(int_dt, x = ~x, y = ~y, type = 'scatter', mode = 'markers', text = ~text, hoverinfo = 'text', color = ~status, colors = c('#c23b22','#7b3294','#1b7837','#fdae61','#737373'), marker = list(size = 8, opacity = 0.82, line = list(width = 0)))
  w <- plotly::layout(w, title = 'Bolivia Product Space visual network', xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
  htmlwidgets::saveWidget(w, interactive_file, selfcontained = FALSE)
}, error = function(e) {
  writeLines(c('<!doctype html><html><head><meta charset="utf-8"><title>Bolivia Product Space</title></head><body>', '<h1>Bolivia Product Space</h1>', '<p>Interactive Plotly export unavailable in this local R session. See 06_bolivia_product_space.png.</p>', '</body></html>'), interactive_file, useBytes = TRUE)
})

expected <- data.table(
  figure = c('01_eci_latin_america_trends','02_complexity_income','03_diversity_concentration','04_lac_export_composition','05_bolivia_structural_dashboard','06_bolivia_product_space','07_bolivia_density_pci','08_bolivia_opportunity_matrix','09_bolivia_top_opportunities','10_model_coefficients','bolivia_peer_trajectories'),
  purpose = c('regional complexity trends','complexity-income relationship','diversity-concentration map','export composition','Bolivia dashboard','Product Space visual network','density-PCI opportunity cloud','feasibility-transformation matrix','top transformation opportunities','econometric coefficients','peer ECI trajectories')
)
expected[, png_path := file.path('outputs/figures/png', paste0(figure, '.png'))]
expected[, pdf_path := file.path('outputs/figures/pdf', paste0(figure, '.pdf'))]
expected[, png_exists := file.exists(png_path)]
expected[, pdf_exists := file.exists(pdf_path)]
expected[, png_size_bytes := fifelse(png_exists, file.info(png_path)$size, NA_real_)]
expected[, pdf_size_bytes := fifelse(pdf_exists, file.info(pdf_path)$size, NA_real_)]
expected[, status := fifelse(png_exists & pdf_exists & png_size_bytes > 5000 & pdf_size_bytes > 1000, 'PASS', 'CHECK')]
fwrite(expected, p('outputs/tables/csv/figure_audit.csv'))
writeLines(c(
  '# Figure Audit',
  '',
  paste0('Generated on local processed data for latest Bolivia year ', latest_year, '.'),
  '',
  paste0('- Figures passing file-existence and size checks: ', expected[status == 'PASS', .N], '/', nrow(expected), '.'),
  paste0('- Interactive HTML: ', ifelse(file.exists(interactive_file), 'present', 'missing'), '.'),
  '',
  'The Product Space figure is a visual subset for legibility. Computational density and opportunity gain use the full analytical proximity matrix documented in `docs/PRODUCT_SPACE_VALIDATION.md`.',
  '',
  paste(c('| Figure | Purpose | Status |', '|---|---|---|', apply(expected[, .(figure, purpose, status)], 1, function(r) paste0('| ', paste(r, collapse = ' | '), ' |'))), collapse = '\n')
), p('docs/FIGURE_AUDIT.md'), useBytes = TRUE)

cat('Stage 3 models and figures complete\n')