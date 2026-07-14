const DATA_PATHS = {
  country: "data/country_complexity.csv",
  product: "data/product_complexity_2023.csv",
  opportunities: "data/bolivia_opportunities.csv",
  strategic: "data/bolivia_strategic_bets.csv",
  edges: "data/product_space_edges.csv",
  nodes: "data/product_space_nodes.csv",
  quality: "data/data_quality.csv",
  eciValidation: "data/eci_validation.csv",
  pciValidation: "data/pci_validation.csv"
};

const state = {
  data: {},
  selectedCountry: "BOL",
  selectedRegion: "All",
  selectedSector: "All",
  selectedSpaceSector: "All",
  selectedBoliviaCategory: "All",
  productSearch: "",
  boliviaSearch: "",
  proximityMin: 0
};

function parseCSV(text) {
  const rows = [];
  let row = [];
  let field = "";
  let quoted = false;
  const clean = text.replace(/^\uFEFF/, "");

  for (let i = 0; i < clean.length; i += 1) {
    const char = clean[i];
    const next = clean[i + 1];
    if (quoted) {
      if (char === '"' && next === '"') {
        field += '"';
        i += 1;
      } else if (char === '"') {
        quoted = false;
      } else {
        field += char;
      }
    } else if (char === '"') {
      quoted = true;
    } else if (char === ",") {
      row.push(field);
      field = "";
    } else if (char === "\n") {
      row.push(field);
      rows.push(row);
      row = [];
      field = "";
    } else if (char !== "\r") {
      field += char;
    }
  }

  if (field.length || row.length) {
    row.push(field);
    rows.push(row);
  }

  const headers = rows.shift() || [];
  return rows
    .filter((r) => r.some((value) => value !== ""))
    .map((r) => Object.fromEntries(headers.map((header, index) => [header, r[index] ?? ""])));
}

function num(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function fmt(value, digits = 2) {
  const parsed = num(value);
  if (parsed === null) return value || "NA";
  return parsed.toLocaleString("en-US", { maximumFractionDigits: digits });
}

function pct(value) {
  const parsed = num(value);
  if (parsed === null) return "NA";
  return `${(parsed * 100).toLocaleString("en-US", { maximumFractionDigits: 1 })}%`;
}

function unique(values) {
  return [...new Set(values.filter((value) => value !== "" && value !== null && value !== undefined))].sort();
}

function byNumberDesc(key) {
  return (a, b) => (num(b[key]) ?? -Infinity) - (num(a[key]) ?? -Infinity);
}

function colorFor(value) {
  const text = String(value || "").toLowerCase();
  if (text.includes("strategic")) return "#b23a48";
  if (text.includes("incremental")) return "#1f7a8c";
  if (text.includes("transform")) return "#6d597a";
  if (text.includes("middle")) return "#d18b2f";
  if (text.includes("low")) return "#596474";
  if (text.includes("exclude")) return "#8d99ae";
  if (text.includes("machinery")) return "#274c77";
  if (text.includes("chemical")) return "#4f772d";
  if (text.includes("transport")) return "#b23a48";
  if (text.includes("textile")) return "#d18b2f";
  return "#1f7a8c";
}

function setHTML(id, html) {
  const element = document.getElementById(id);
  if (element) element.innerHTML = html;
}

function makeKPI(label, value, note = "") {
  return `<article class="kpi"><span>${label}</span><strong>${value}</strong>${note ? `<span>${note}</span>` : ""}</article>`;
}

function makeTable(columns, rows, formatter = {}) {
  const head = columns.map((column) => `<th>${column.label}</th>`).join("");
  const body = rows.map((row) => {
    const cells = columns.map((column) => {
      const raw = row[column.key];
      const value = formatter[column.key] ? formatter[column.key](raw, row) : raw;
      return `<td>${value ?? ""}</td>`;
    }).join("");
    return `<tr>${cells}</tr>`;
  }).join("");
  return `<table><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table>`;
}

function populateSelect(id, values, selected = "All") {
  const select = document.getElementById(id);
  if (!select) return;
  select.innerHTML = values.map((value) => `<option value="${value}">${value}</option>`).join("");
  select.value = values.includes(selected) ? selected : values[0];
}

function initTabs() {
  document.querySelectorAll(".tab").forEach((button) => {
    button.addEventListener("click", () => {
      document.querySelectorAll(".tab").forEach((item) => item.classList.remove("is-active"));
      document.querySelectorAll(".view").forEach((view) => view.classList.remove("is-active"));
      button.classList.add("is-active");
      document.getElementById(`view-${button.dataset.view}`).classList.add("is-active");
    });
  });
}

function initControls() {
  const countries = unique(state.data.country.map((row) => row.country_code));
  const regions = ["All", ...unique(state.data.country.map((row) => row.region))];
  const sectors = ["All", ...unique(state.data.product.map((row) => row.product_section))];
  const spaceSectors = ["All", ...unique(state.data.nodes.map((row) => row.product_section))];
  const categories = ["All", ...unique(state.data.opportunities.map((row) => row.relative_category))];

  populateSelect("country-select", countries, countries.includes("BOL") ? "BOL" : countries[0]);
  populateSelect("region-select", regions);
  populateSelect("sector-select", sectors);
  populateSelect("space-sector-select", spaceSectors);
  populateSelect("bolivia-category-select", categories);

  document.getElementById("country-select").addEventListener("change", (event) => {
    state.selectedCountry = event.target.value;
    renderCountry();
  });
  document.getElementById("region-select").addEventListener("change", (event) => {
    state.selectedRegion = event.target.value;
    renderCountry();
  });
  document.getElementById("sector-select").addEventListener("change", (event) => {
    state.selectedSector = event.target.value;
    renderProduct();
  });
  document.getElementById("product-search").addEventListener("input", (event) => {
    state.productSearch = event.target.value.toLowerCase();
    renderProduct();
  });
  document.getElementById("space-sector-select").addEventListener("change", (event) => {
    state.selectedSpaceSector = event.target.value;
    renderProductSpace();
  });
  document.getElementById("proximity-min").addEventListener("input", (event) => {
    state.proximityMin = Number(event.target.value);
    renderProductSpace();
  });
  document.getElementById("bolivia-category-select").addEventListener("change", (event) => {
    state.selectedBoliviaCategory = event.target.value;
    renderBolivia();
  });
  document.getElementById("bolivia-search").addEventListener("input", (event) => {
    state.boliviaSearch = event.target.value.toLowerCase();
    renderBolivia();
  });
}

function renderOverview() {
  const countryYears = state.data.country.length;
  const countries = unique(state.data.country.map((row) => row.country_code)).length;
  const products = state.data.product.length;
  const years = state.data.country.map((row) => num(row.year)).filter((value) => value !== null);
  const minYear = Math.min(...years);
  const maxYear = Math.max(...years);
  const boliviaRows = state.data.country.filter((row) => row.country_code === "BOL");
  const latestBolivia = boliviaRows.sort((a, b) => num(b.year) - num(a.year))[0];

  setHTML("overview-kpis", [
    makeKPI("Country-year rows", fmt(countryYears, 0), "public derived panel"),
    makeKPI("Countries", fmt(countries, 0), "country codes"),
    makeKPI("HS92 products", fmt(products, 0), "latest product panel"),
    makeKPI("Period", `${minYear}-${maxYear}`, "country-year coverage"),
    makeKPI("Bolivia ECI 2023", latestBolivia ? fmt(latestBolivia.eci, 3) : "NA", "relative annual position"),
    makeKPI("Visual Product Space edges", fmt(state.data.edges.length, 0), "communication subset"),
    makeKPI("Opportunity candidates", fmt(state.data.opportunities.length, 0), "Bolivia screen"),
    makeKPI("Highlighted strategic bets", fmt(state.data.strategic.length, 0), "human-review table")
  ].join(""));

  const counts = new Map();
  state.data.opportunities.forEach((row) => {
    const category = row.relative_category || "Unclassified";
    counts.set(category, (counts.get(category) || 0) + 1);
  });
  const maxCount = Math.max(...counts.values());
  const bars = [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .map(([label, count]) => {
      const width = maxCount ? (count / maxCount) * 100 : 0;
      return `<div class="bar-row"><span>${label}</span><div class="bar-track"><div class="bar-fill" style="width:${width}%;background:${colorFor(label)}"></div></div><strong>${count}</strong></div>`;
    }).join("");
  setHTML("category-bars", bars);
}

function renderCountry() {
  const selectedRows = state.data.country
    .filter((row) => row.country_code === state.selectedCountry)
    .sort((a, b) => num(a.year) - num(b.year));
  const latest = selectedRows[selectedRows.length - 1];

  if (!latest) return;

  setHTML("country-kpis", [
    makeKPI("Latest year", latest.year),
    makeKPI("ECI", fmt(latest.eci, 3)),
    makeKPI("Diversity", fmt(latest.diversity, 0)),
    makeKPI("HHI", fmt(latest.hhi, 3)),
    makeKPI("Primary share", pct(latest.primary_share)),
    makeKPI("Manufacturing share", pct(latest.manufacturing_share))
  ].join(""));

  drawLineChart("country-chart", selectedRows, "year", "eci", "ECI");

  const latestYear = Math.max(...state.data.country.map((row) => num(row.year)));
  let ranking = state.data.country.filter((row) => num(row.year) === latestYear);
  if (state.selectedRegion !== "All") {
    ranking = ranking.filter((row) => row.region === state.selectedRegion);
  }
  ranking = ranking.sort(byNumberDesc("eci")).slice(0, 25).map((row, index) => ({ ...row, rank: index + 1 }));
  setHTML("country-table", makeTable([
    { key: "rank", label: "Rank" },
    { key: "country_code", label: "Country" },
    { key: "region", label: "Region" },
    { key: "eci", label: "ECI" },
    { key: "diversity", label: "Diversity" },
    { key: "hhi", label: "HHI" },
    { key: "primary_share", label: "Primary share" }
  ], ranking, {
    eci: (v) => fmt(v, 3),
    diversity: (v) => fmt(v, 0),
    hhi: (v) => fmt(v, 3),
    primary_share: (v) => pct(v)
  }));
}

function renderProduct() {
  let rows = [...state.data.product];
  if (state.selectedSector !== "All") rows = rows.filter((row) => row.product_section === state.selectedSector);
  if (state.productSearch) {
    rows = rows.filter((row) => `${row.product_code} ${row.product_section} ${row.product_chapter}`.toLowerCase().includes(state.productSearch));
  }
  rows = rows.sort(byNumberDesc("pci_final"));
  drawHorizontalBars("product-bars", rows.slice(0, 12), "product_code", "pci_final", "PCI final");
  setHTML("product-table", makeTable([
    { key: "product_code", label: "Product" },
    { key: "product_section", label: "Section" },
    { key: "product_chapter", label: "Chapter" },
    { key: "pci_final", label: "PCI final" },
    { key: "ubiquity", label: "Ubiquity" },
    { key: "world_export_value", label: "World exports" }
  ], rows.slice(0, 35), {
    pci_final: (v) => fmt(v, 3),
    ubiquity: (v) => fmt(v, 0),
    world_export_value: (v) => fmt(v, 0)
  }));
}

function renderProductSpace() {
  const sector = state.selectedSpaceSector;
  let nodes = state.data.nodes;
  if (sector !== "All") nodes = nodes.filter((row) => row.product_section === sector);
  const nodeCodes = new Set(nodes.map((row) => row.product_code));
  let edges = state.data.edges.filter((row) => nodeCodes.has(row.from) && nodeCodes.has(row.to));
  edges = edges.filter((row) => (num(row.proximity) ?? 0) >= state.proximityMin);

  const width = 1100;
  const height = 620;
  const centerX = width / 2;
  const centerY = height / 2;
  const maxPci = Math.max(...nodes.map((row) => num(row.pci_final) ?? 0), 1);
  const minPci = Math.min(...nodes.map((row) => num(row.pci_final) ?? 0), -1);
  const spread = Math.max(maxPci - minPci, 1);
  const positioned = new Map();

  nodes.forEach((node, index) => {
    const angle = hashNumber(node.product_code) * Math.PI * 2;
    const pci = num(node.pci_final) ?? 0;
    const norm = (pci - minPci) / spread;
    const radius = 120 + (1 - norm) * 190 + (index % 9) * 5;
    positioned.set(node.product_code, {
      ...node,
      x: centerX + Math.cos(angle) * radius,
      y: centerY + Math.sin(angle) * radius,
      r: 3.5 + Math.max(0, norm) * 4
    });
  });

  const edgeSvg = edges.map((edge) => {
    const a = positioned.get(edge.from);
    const b = positioned.get(edge.to);
    if (!a || !b) return "";
    const opacity = Math.max(.08, Math.min(.45, num(edge.proximity) || .1));
    return `<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" stroke="#8d99ae" stroke-opacity="${opacity}" stroke-width="1"><title>${edge.from} to ${edge.to}: ${fmt(edge.proximity, 3)}</title></line>`;
  }).join("");

  const nodeSvg = [...positioned.values()].map((node) => {
    return `<circle cx="${node.x}" cy="${node.y}" r="${node.r}" fill="${colorFor(node.product_section)}" opacity=".9"><title>${node.product_code} - ${node.product_name_short} | PCI ${fmt(node.pci_final, 2)} | ${node.relative_category}</title></circle>`;
  }).join("");

  const labels = [...positioned.values()]
    .sort(byNumberDesc("pci_final"))
    .slice(0, 10)
    .map((node) => `<text x="${node.x + 7}" y="${node.y + 4}" class="point-label">${node.product_code}</text>`)
    .join("");

  setHTML("product-space-network", `<svg viewBox="0 0 ${width} ${height}" role="img" aria-label="Product Space visual edge subset">${edgeSvg}${nodeSvg}${labels}</svg>`);
}

function renderBolivia() {
  let rows = [...state.data.opportunities];
  if (state.selectedBoliviaCategory !== "All") rows = rows.filter((row) => row.relative_category === state.selectedBoliviaCategory);
  if (state.boliviaSearch) {
    rows = rows.filter((row) => `${row.product_code} ${row.product_name} ${row.product_name_short}`.toLowerCase().includes(state.boliviaSearch));
  }
  rows = rows.sort(byNumberDesc("opportunity_score"));
  drawScatter("bolivia-scatter", rows.slice(0, 240), "feasibility_score", "transformation_score", "Feasibility", "Transformation");
  setHTML("bolivia-table", makeTable([
    { key: "product_code", label: "Product" },
    { key: "product_name_short", label: "Name" },
    { key: "product_section", label: "Section" },
    { key: "relative_category", label: "Category" },
    { key: "density", label: "Density" },
    { key: "pci_final", label: "PCI" },
    { key: "opportunity_score", label: "Score" },
    { key: "feasibility_score", label: "Feasibility" },
    { key: "transformation_score", label: "Transformation" }
  ], rows.slice(0, 35), {
    density: (v) => fmt(v, 3),
    pci_final: (v) => fmt(v, 3),
    opportunity_score: (v) => fmt(v, 3),
    feasibility_score: (v) => fmt(v, 3),
    transformation_score: (v) => fmt(v, 3)
  }));
}

function renderQuality() {
  setHTML("quality-table", makeTable([
    { key: "category", label: "Category" },
    { key: "metric", label: "Metric" },
    { key: "value", label: "Value" },
    { key: "status", label: "Status" },
    { key: "source_file", label: "Source" }
  ], state.data.quality));

  const latestEci = [...state.data.eciValidation].sort((a, b) => num(b.year) - num(a.year))[0];
  const latestPci = [...state.data.pciValidation].sort((a, b) => num(b.year) - num(a.year))[0];
  const rows = [
    { indicator: "ECI", year: latestEci.year, units: latestEci.countries, mean: latestEci.mean_eci, sd: latestEci.sd_eci, infinite: latestEci.infinite },
    { indicator: "PCI", year: latestPci.year, units: latestPci.products, mean: latestPci.mean_pci, sd: latestPci.sd_pci, infinite: latestPci.infinite }
  ];
  setHTML("validation-summary", makeTable([
    { key: "indicator", label: "Indicator" },
    { key: "year", label: "Latest year" },
    { key: "units", label: "Units" },
    { key: "mean", label: "Mean" },
    { key: "sd", label: "SD" },
    { key: "infinite", label: "Infinite values" }
  ], rows, {
    mean: (v) => fmt(v, 3),
    sd: (v) => fmt(v, 3)
  }));
}

function drawLineChart(id, rows, xKey, yKey, label) {
  const width = 980;
  const height = 330;
  const margin = { top: 18, right: 24, bottom: 38, left: 58 };
  const xs = rows.map((row) => num(row[xKey])).filter((value) => value !== null);
  const ys = rows.map((row) => num(row[yKey])).filter((value) => value !== null);
  const xMin = Math.min(...xs);
  const xMax = Math.max(...xs);
  const yMin = Math.min(...ys);
  const yMax = Math.max(...ys);
  const scaleX = (value) => margin.left + ((value - xMin) / Math.max(1, xMax - xMin)) * (width - margin.left - margin.right);
  const scaleY = (value) => height - margin.bottom - ((value - yMin) / Math.max(.001, yMax - yMin)) * (height - margin.top - margin.bottom);
  const points = rows.map((row) => `${scaleX(num(row[xKey]))},${scaleY(num(row[yKey]))}`).join(" ");
  const dots = rows.map((row) => `<circle cx="${scaleX(num(row[xKey]))}" cy="${scaleY(num(row[yKey]))}" r="3" fill="#b23a48"><title>${row[xKey]} ${row[xKey] === "year" ? row.year : ""}: ${fmt(row[yKey], 3)}</title></circle>`).join("");
  const grid = [0, .25, .5, .75, 1].map((ratio) => {
    const y = margin.top + ratio * (height - margin.top - margin.bottom);
    return `<line class="grid-line" x1="${margin.left}" y1="${y}" x2="${width - margin.right}" y2="${y}"></line>`;
  }).join("");
  setHTML(id, `<svg viewBox="0 0 ${width} ${height}" role="img" aria-label="${label} line chart">${grid}<line class="axis" x1="${margin.left}" y1="${height - margin.bottom}" x2="${width - margin.right}" y2="${height - margin.bottom}"></line><line class="axis" x1="${margin.left}" y1="${margin.top}" x2="${margin.left}" y2="${height - margin.bottom}"></line><polyline fill="none" stroke="#274c77" stroke-width="3" points="${points}"></polyline>${dots}<text x="${margin.left}" y="${height - 10}" class="point-label">${xMin}</text><text x="${width - margin.right - 32}" y="${height - 10}" class="point-label">${xMax}</text><text x="8" y="${margin.top + 8}" class="point-label">${label}</text></svg>`);
}

function drawHorizontalBars(id, rows, labelKey, valueKey, valueLabel) {
  const width = 980;
  const height = Math.max(300, rows.length * 28 + 40);
  const margin = { top: 16, right: 80, bottom: 28, left: 94 };
  const values = rows.map((row) => num(row[valueKey]) ?? 0);
  const minValue = Math.min(...values, 0);
  const maxValue = Math.max(...values, 1);
  const spread = Math.max(.001, maxValue - minValue);
  const barHeight = 18;
  const bars = rows.map((row, index) => {
    const value = num(row[valueKey]) ?? 0;
    const y = margin.top + index * 26;
    const x = margin.left;
    const w = ((value - minValue) / spread) * (width - margin.left - margin.right);
    return `<text x="8" y="${y + 13}" class="point-label">${row[labelKey]}</text><rect x="${x}" y="${y}" width="${w}" height="${barHeight}" fill="${colorFor(row.product_section)}"><title>${row[labelKey]}: ${fmt(value, 3)}</title></rect><text x="${x + w + 5}" y="${y + 13}" class="point-label">${fmt(value, 2)}</text>`;
  }).join("");
  setHTML(id, `<svg viewBox="0 0 ${width} ${height}" role="img" aria-label="${valueLabel} bar chart">${bars}</svg>`);
}

function drawScatter(id, rows, xKey, yKey, xLabel, yLabel) {
  const width = 980;
  const height = 420;
  const margin = { top: 18, right: 26, bottom: 50, left: 60 };
  const valuesX = rows.map((row) => num(row[xKey])).filter((value) => value !== null);
  const valuesY = rows.map((row) => num(row[yKey])).filter((value) => value !== null);
  const xMin = Math.min(...valuesX, 0);
  const xMax = Math.max(...valuesX, 1);
  const yMin = Math.min(...valuesY, 0);
  const yMax = Math.max(...valuesY, 1);
  const scaleX = (value) => margin.left + ((value - xMin) / Math.max(.001, xMax - xMin)) * (width - margin.left - margin.right);
  const scaleY = (value) => height - margin.bottom - ((value - yMin) / Math.max(.001, yMax - yMin)) * (height - margin.top - margin.bottom);
  const dots = rows.map((row) => {
    const x = scaleX(num(row[xKey]) ?? 0);
    const y = scaleY(num(row[yKey]) ?? 0);
    return `<circle cx="${x}" cy="${y}" r="5" fill="${colorFor(row.relative_category)}" opacity=".78"><title>${row.product_code} - ${row.product_name_short}: ${row.relative_category}</title></circle>`;
  }).join("");
  const labels = rows.slice(0, 10).map((row) => `<text x="${scaleX(num(row[xKey]) ?? 0) + 7}" y="${scaleY(num(row[yKey]) ?? 0) + 4}" class="point-label">${row.product_code}</text>`).join("");
  setHTML(id, `<svg viewBox="0 0 ${width} ${height}" role="img" aria-label="Bolivia opportunity scatter"><line class="axis" x1="${margin.left}" y1="${height - margin.bottom}" x2="${width - margin.right}" y2="${height - margin.bottom}"></line><line class="axis" x1="${margin.left}" y1="${margin.top}" x2="${margin.left}" y2="${height - margin.bottom}"></line>${dots}${labels}<text x="${width / 2 - 50}" y="${height - 12}" class="point-label">${xLabel}</text><text x="8" y="${margin.top + 8}" class="point-label">${yLabel}</text></svg>`);
}

function hashNumber(text) {
  let hash = 0;
  for (let i = 0; i < String(text).length; i += 1) {
    hash = ((hash << 5) - hash + String(text).charCodeAt(i)) | 0;
  }
  return Math.abs(hash % 10000) / 10000;
}

function renderAll() {
  renderOverview();
  renderCountry();
  renderProduct();
  renderProductSpace();
  renderBolivia();
  renderQuality();
}

async function loadData() {
  const entries = await Promise.all(Object.entries(DATA_PATHS).map(async ([key, path]) => {
    const response = await fetch(path);
    if (!response.ok) throw new Error(`Unable to load ${path}`);
    return [key, parseCSV(await response.text())];
  }));
  state.data = Object.fromEntries(entries);
}

document.addEventListener("DOMContentLoaded", async () => {
  initTabs();
  try {
    await loadData();
    initControls();
    renderAll();
  } catch (error) {
    setHTML("overview-kpis", `<article class="kpi"><span>Status</span><strong>Data load warning</strong><span>${error.message}</span></article>`);
  }
});
