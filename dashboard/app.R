library(shiny)
library(data.table)
library(ggplot2)
library(plotly)
library(DT)

root <- normalizePath(if (basename(getwd()) == 'dashboard') file.path(getwd(), '..') else getwd(), winslash = '/', mustWork = FALSE)
if (!file.exists(file.path(root, 'outputs/tables/csv/country_year_indicators.csv'))) {
  root <- normalizePath(file.path(dirname(getwd()), '..'), winslash = '/', mustWork = FALSE)
}
read_csv <- function(file, ...) fread(file.path(root, file), ...)
cy <- read_csv('outputs/tables/csv/country_year_indicators.csv')
prod <- read_csv('outputs/tables/csv/product_year_indicators.csv', colClasses = list(character = 'product_code'))
opp <- read_csv('outputs/tables/csv/bolivia_opportunities_revised.csv', colClasses = list(character = 'product_code'))
models <- read_csv('outputs/tables/csv/econometric_model_summary.csv')
bol_val <- read_csv('outputs/tables/csv/bolivia_2023_indicator_validation.csv')
ps_diag <- read_csv('outputs/tables/csv/product_space_network_diagnostics.csv')
addResourcePath('figures', file.path(root, 'outputs/figures/png'))
latest_year <- max(cy[country_code == 'BOL' & export_value > 0, year], na.rm = TRUE)
fmt <- function(x, digits = 3) format(round(as.numeric(x), digits), big.mark = ',', nsmall = digits, scientific = FALSE)
fmt0 <- function(x) format(round(as.numeric(x), 0), big.mark = ',', scientific = FALSE)
country_choices <- sort(unique(cy$country_code))
product_labels <- opp[order(product_code), paste0(product_code, ' - ', product_name_short)]
names(product_labels) <- opp[order(product_code), product_code]
category_choices <- c('All', sort(unique(opp$relative_category)))
sector_choices <- c('All', sort(unique(opp$product_section)))

metric_box <- function(value, label) span(class = 'metric', strong(value), br(), label)

ui <- fluidPage(
  tags$head(tags$style(HTML('
    body{font-family:Arial,sans-serif;color:#1f2933}.small-note{color:#555;font-size:12px}.metric{display:inline-block;margin:6px 18px 10px 0;padding:8px 0}.metric strong{font-size:20px;color:#b21f2d}.section-title{margin-top:8px;color:#17233c}.download-btn{margin-top:10px}.quiet-panel{border:1px solid #d8dde5;padding:12px;margin-bottom:12px}.tab-content{padding-top:14px}.shiny-output-error{color:#8a1f11}
  '))),
  titlePanel('Economic Complexity and Structural Transformation in Latin America'),
  fluidRow(column(12,
    metric_box(fmt(bol_val[indicator == 'ECI', recalculated_value], 3), 'Bolivia ECI 2023'),
    metric_box(fmt0(bol_val[indicator == 'Diversity', recalculated_value]), 'RCA products'),
    metric_box(fmt(bol_val[indicator == 'HHI', recalculated_value], 3), 'HHI'),
    metric_box(paste0(fmt(100 * bol_val[indicator == 'Primary export share', recalculated_value], 1), '%'), 'Primary share')
  )),
  tabsetPanel(id = 'main_tabs',
    tabPanel('Executive Overview',
      fluidRow(
        column(7, plotlyOutput('overview_eci', height = 360)),
        column(5, div(class='quiet-panel', h4('Bolivia opportunity counts'), DTOutput('overview_counts')), div(class='quiet-panel', h4('Validation snapshot'), verbatimTextOutput('overview_validation')))
      ),
      p(class='small-note','ECI is standardized within each year. Product rankings are screening tools, not investment prescriptions.')
    ),
    tabPanel('Country Explorer',
      sidebarLayout(
        sidebarPanel(
          selectInput('country','Country', choices = country_choices, selected = 'BOL'),
          sliderInput('country_years','Years', min = min(cy$year), max = max(cy$year), value = c(min(cy$year), max(cy$year)), sep = ''),
          selectInput('country_metric','Indicator', choices = c('ECI'='eci','Diversity'='diversity','HHI'='hhi','Primary share'='primary_share','Manufacturing share'='manufacturing_share'), selected = 'eci')
        ),
        mainPanel(plotlyOutput('country_plot', height = 360), verbatimTextOutput('country_snapshot'), DTOutput('country_table'))
      )
    ),
    tabPanel('Product Explorer',
      sidebarLayout(
        sidebarPanel(
          selectizeInput('product','Product', choices = NULL, selected = names(product_labels)[1], options = list(placeholder = 'Search product code or name')),
          selectInput('product_metric','Indicator', choices = c('Projected PCI'='pci_final','Ubiquity'='ubiquity','World export value'='world_export_value'), selected = 'pci_final')
        ),
        mainPanel(verbatimTextOutput('product_snapshot'), plotlyOutput('product_plot', height = 360), DTOutput('product_table'), p(class='small-note','Product names come from the Bolivia opportunity table when available. Exporter-level detail is not included in the public dashboard data.'))
      )
    ),
    tabPanel('Product Space',
      fluidRow(
        column(7, h3(class='section-title','Bolivia in the Product Space'), tags$img(src='figures/06_bolivia_product_space.png', width='100%', alt='Bolivia Product Space visual network')),
        column(5, h3(class='section-title','Diagnostics'), DTOutput('ps_table'), h3(class='section-title','Opportunity overlay'), selectInput('ps_category','Category', choices = category_choices, selected = 'Strategic bets'), plotlyOutput('ps_opp_plot', height = 280))
      ),
      p(class='small-note','The visual network is a legibility subset. Density and Opportunity Gain use the full analytical proximity matrix.')
    ),
    tabPanel('Bolivia Opportunity Lab',
      sidebarLayout(
        sidebarPanel(
          selectInput('category','Relative category', choices = category_choices, selected = 'All'),
          selectInput('sector','Sector', choices = sector_choices, selected = 'All'),
          selectInput('score','Rank by', choices = c('Feasibility'='feasibility_score','Transformation'='transformation_score','Original score'='opportunity_score'), selected = 'feasibility_score'),
          checkboxInput('eligible_only','Eligible universe only', TRUE),
          sliderInput('n','Rows', min = 10, max = 100, value = 30),
          downloadButton('download_opp','Download filtered CSV', class = 'download-btn')
        ),
        mainPanel(plotlyOutput('opp_plot', height = 360), DTOutput('opp_table'), p(class='small-note','Product rankings are screening tools, not investment prescriptions. Residual codes remain in the base but should not be highlighted without review.'))
      )
    ),
    tabPanel('Econometric Evidence',
      h3(class='section-title','Fixed-effects associations'),
      plotlyOutput('coef_plot', height = 420),
      DTOutput('model_table'),
      p(class='small-note','Models are observational fixed-effects specifications with country-clustered standard errors. They are not causal estimates.')
    ),
    tabPanel('Data and Methods',
      h3(class='section-title','Coverage'), verbatimTextOutput('coverage'),
      h3(class='section-title','Definitions'),
      tags$ul(tags$li('RCA >= 1 defines revealed specialization in the MCP matrix.'), tags$li('ECI is standardized within each year.'), tags$li('Projected PCI is internal to this workflow.'), tags$li('Opportunity scores are screening diagnostics.')),
      h3(class='section-title','Validation files'),
      tags$ul(tags$li('docs/ECI_PCI_TECHNICAL_VALIDATION.md'), tags$li('docs/PRODUCT_SPACE_VALIDATION.md'), tags$li('docs/BOLIVIA_OPPORTUNITY_AUDIT.md'), tags$li('docs/ECONOMETRIC_MODEL_AUDIT.md'))
    )
  )
)

server <- function(input, output, session) {
  updateSelectizeInput(session, 'product', choices = product_labels, selected = names(product_labels)[1], server = TRUE)
  lac <- reactive(cy[region == 'Latin America and Caribbean' & !is.na(eci)])
  output$overview_eci <- renderPlotly({
    d <- lac()
    p <- ggplot(d, aes(year, eci, group = country_code, text = paste(country_code, year, round(eci,2)))) +
      geom_line(color='grey75', linewidth=.35, alpha=.55) +
      geom_line(data=d[country_code == 'BOL'], color='#b21f2d', linewidth=1.1) +
      geom_hline(yintercept=0, color='grey50', linewidth=.25) +
      theme_minimal() + labs(x=NULL, y='ECI', title='Regional ECI trajectories with Bolivia highlighted')
    ggplotly(p, tooltip='text')
  })
  output$overview_counts <- renderDT({ datatable(opp[, .N, by=relative_category][order(-N)], options=list(dom='t'), rownames=FALSE) })
  output$overview_validation <- renderText({ paste('Panel countries:', uniqueN(cy$country_code), '\nYears:', min(cy$year), '-', max(cy$year), '\nBolivia latest year:', latest_year, '\nOpportunity candidates:', nrow(opp)) })
  country_data <- reactive(cy[country_code == input$country & year >= input$country_years[1] & year <= input$country_years[2]])
  output$country_plot <- renderPlotly({
    d <- country_data(); y <- input$country_metric
    p <- ggplot(d, aes(year, .data[[y]], text = paste(year, '<br>', y, ':', round(.data[[y]],3)))) + geom_line(color='#2166ac', linewidth=1) + geom_point(color='#b21f2d', size=1.6) + theme_minimal() + labs(x=NULL, y=y, title=paste(input$country, y))
    ggplotly(p, tooltip='text')
  })
  output$country_snapshot <- renderText({
    d <- cy[country_code == input$country & year == max(cy[country_code == input$country & export_value > 0, year], na.rm=TRUE)]
    paste('Latest year:', d$year, '\nECI:', round(d$eci,3), '\nDiversity:', d$diversity, '\nHHI:', round(d$hhi,3), '\nPrimary share:', paste0(round(100*d$primary_share,1),'%'))
  })
  output$country_table <- renderDT({ datatable(country_data()[order(-year)], options=list(pageLength=8, scrollX=TRUE), rownames=FALSE) })
  product_data <- reactive({ req(input$product); prod[product_code == input$product] })
  output$product_snapshot <- renderText({
    req(input$product)
    meta <- opp[product_code == input$product][1]
    latest <- prod[product_code == input$product & year == max(year)][1]
    paste('Product code:', input$product,
          '\nProduct name:', ifelse(nrow(meta) && !is.na(meta$product_name), meta$product_name, 'Not available'),
          '\nSector:', ifelse(nrow(meta) && !is.na(meta$product_section), meta$product_section, latest$product_section),
          '\nLatest projected PCI:', round(latest$pci_final, 3),
          '\nLatest ubiquity:', latest$ubiquity,
          '\nRelative category:', ifelse(nrow(meta) && !is.na(meta$relative_category), meta$relative_category, 'Not in Bolivia opportunity table'))
  })
  output$product_plot <- renderPlotly({
    d <- product_data(); y <- input$product_metric
    p <- ggplot(d, aes(year, .data[[y]], text = paste(year, '<br>', y, ':', round(.data[[y]],3)))) + geom_line(color='#2166ac', linewidth=1) + geom_point(color='#b21f2d', size=1.6) + theme_minimal() + labs(x=NULL, y=y, title=paste('Product', input$product, y))
    ggplotly(p, tooltip='text')
  })
  output$product_table <- renderDT({
    latest <- prod[product_code == input$product & year == max(year)]
    meta <- unique(opp[product_code == input$product, .(product_code, product_name, product_section, relative_category, density, pci_final, ubiquity, opportunity_gain, feasibility_score, transformation_score)])
    datatable(rbindlist(list(meta, latest[, .(product_code, product_name=NA_character_, product_section, relative_category=NA_character_, density=NA_real_, pci_final, ubiquity, opportunity_gain=NA_real_, feasibility_score=NA_real_, transformation_score=NA_real_)]), fill=TRUE), options=list(dom='t', scrollX=TRUE), rownames=FALSE)
  })
  filtered_opp <- reactive({
    d <- copy(opp)
    if (isTRUE(input$eligible_only)) d <- d[eligible == TRUE]
    if (input$category != 'All') d <- d[relative_category == input$category]
    if (input$sector != 'All') d <- d[product_section == input$sector]
    head(d[order(-get(input$score))], input$n)
  })
  output$opp_plot <- renderPlotly({
    d <- filtered_opp()
    p <- ggplot(d, aes(density, pci_final, color=relative_category, text=paste(product_code, product_name_short, '<br>Feasibility:', round(feasibility_score,3), '<br>Transformation:', round(transformation_score,3)))) + geom_point(aes(size=world_market_size), alpha=.75) + theme_minimal() + labs(x='Density', y='Projected PCI', color=NULL, size='World market')
    ggplotly(p, tooltip='text')
  })
  output$opp_table <- renderDT({
    cols <- intersect(c('product_code','product_name_short','product_section','density','pci_final','feasibility_score','transformation_score','relative_category','residual_code'), names(filtered_opp()))
    datatable(filtered_opp()[, ..cols], options=list(pageLength=10, scrollX=TRUE), rownames=FALSE)
  })
  output$download_opp <- downloadHandler(filename=function() 'bolivia_filtered_opportunities.csv', content=function(file) fwrite(filtered_opp(), file))
  output$ps_table <- renderDT({ datatable(ps_diag, options=list(dom='t', pageLength=nrow(ps_diag)), rownames=FALSE) })
  output$ps_opp_plot <- renderPlotly({
    d <- if (input$ps_category == 'All') opp[eligible == TRUE] else opp[relative_category == input$ps_category]
    d <- head(d[order(-transformation_score)], 80)
    p <- ggplot(d, aes(density, transformation_score, color=product_section, text=paste(product_code, product_name_short, '<br>Category:', relative_category))) + geom_point(alpha=.75) + theme_minimal() + labs(x='Density', y='Transformation score', color=NULL)
    ggplotly(p, tooltip='text')
  })
  output$coef_plot <- renderPlotly({
    d <- models[term != '(Intercept)']
    d[, `:=`(lo=estimate-1.96*std_error, hi=estimate+1.96*std_error)]
    p <- ggplot(d, aes(estimate, reorder(term, estimate), text=paste(model, term, '<br>Estimate:', round(estimate,3), '<br>SE:', round(std_error,3)))) + geom_vline(xintercept=0, color='grey55', linewidth=.3) + geom_errorbarh(aes(xmin=lo,xmax=hi), height=.1, color='grey40') + geom_point(color='#2166ac', size=2) + facet_wrap(~model, scales='free_x') + theme_minimal() + labs(x='Estimate and 95% interval', y=NULL)
    ggplotly(p, tooltip='text')
  })
  output$model_table <- renderDT({ datatable(models, options=list(pageLength=10, scrollX=TRUE), rownames=FALSE) })
  output$coverage <- renderText({ paste('Countries:', uniqueN(cy$country_code), '\nYears:', min(cy$year), '-', max(cy$year), '\nProducts:', uniqueN(prod$product_code), '\nBolivia latest year:', latest_year, '\nOpportunity candidates:', nrow(opp)) })
}

shinyApp(ui, server)
