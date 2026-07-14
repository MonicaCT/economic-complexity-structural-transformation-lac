-- Product Space validation checks for the visual edge subset.
-- Intended for future DuckDB checks; not executed in this phase.

WITH edges AS (
    SELECT
        "from" AS from_product_code,
        "to" AS to_product_code,
        proximity
    FROM read_csv_auto('outputs/networks/product_space_visual_edges.csv', header = true)
)
SELECT 'missing_product_nodes' AS check_name, COUNT(*) AS issue_count
FROM edges
WHERE from_product_code IS NULL OR to_product_code IS NULL
UNION ALL
SELECT 'proximity_out_of_range' AS check_name, COUNT(*) AS issue_count
FROM edges
WHERE proximity < 0 OR proximity > 1
UNION ALL
SELECT 'self_edges' AS check_name, COUNT(*) AS issue_count
FROM edges
WHERE from_product_code = to_product_code;
