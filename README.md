# Precision Pollination Mapping for Agriculture (Version 3)

Spatio-temporal workflow for mapping pollination climate suitability and crop-weighted exposure across Germany, Belgium, and the Netherlands.

## Personas

### Lars Hoffmann (Regional Crop Insurance Analyst)
Lars needs ranked regional exposure metrics for pollination-sensitive crops to support premium differentiation and portfolio risk management.  
He also needs interannual stability signals to separate structural risk from one-off seasonal shocks.

### Dr. Anneke Visser (Regional Agronomy Advisor)
Anneke needs crop-window-specific suitability maps linked to crop presence to benchmark regions and prioritize field support.  
She also needs hotspot detection to design cluster-based advisory campaigns across NL, BE, and western DE.

## Research Questions

- Q1. Where is climate suitability for pollination highest and most stable during crop-specific bloom windows across DE-BE-NL?
- Q2. Where do crop distributions overlap with unsuitable or variable pollination climate, and which NUTS-2 regions carry the greatest crop-weighted deficit exposure?
- Q3. Are crop-weighted suitability and deficit exposure spatially clustered at NUTS-2 level, and where are significant hotspots?

## Data Sources

- E-OBS daily gridded climate (TG, RR), v27.0e: https://doi.org/10.1029/2017JD028200
- SPAM 2020 crop harvested area (RAPE, TEMF, SUNF): https://doi.org/10.7910/DVN/SWPENT
- NUTS 2024 boundaries (Eurostat GISCO): https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/territorial-units-statistics
- SPAM methodology reference: https://doi.org/10.7910/DVN/DHXBJX

## How To Run

```bash
quarto render main.qmd
```

## Output Structure

- `outputs/maps/`: generated raster and LISA maps
- `outputs/plots/`: generated time-series plots
- `outputs/tables/`: generated ranking and comparison tables

## R Package Dependencies

- terra
- sf
- exactextractr
- sfdep
- spdep
- dplyr
- tidyr
- tmap
- ggplot2
- here
- tibble
