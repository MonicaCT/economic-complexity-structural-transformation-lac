.PHONY: inventory all validate render

inventory:
	powershell -ExecutionPolicy Bypass -File scripts/build_inventory.ps1

all:
	Rscript R/99_run_all.R

validate:
	Rscript scripts/validate_project.R

render:
	Rscript scripts/render_project.R
