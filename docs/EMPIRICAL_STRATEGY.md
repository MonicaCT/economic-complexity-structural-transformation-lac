# Empirical Strategy

The econometric module is observational. It tests whether economic complexity is associated with subsequent GDP per capita growth after controlling for export concentration and diversity.

The implemented baseline is:

`future_growth_c,t+5 = beta ECI_ct + gamma HHI_ct + delta log(1 + diversity_ct) + country FE + year FE + error_ct`

The dependent variable is annualized five-year-ahead growth in CEPII GDP per capita PPP. Standard errors are clustered by country. The model is not interpreted as causal because export complexity, income, institutions, and policy choices are jointly determined.

The current run uses 563 Latin America observations, 26 countries, and 22 years with complete model variables.