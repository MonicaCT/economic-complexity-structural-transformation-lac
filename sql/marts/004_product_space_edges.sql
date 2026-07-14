-- Product Space visual edge mart from existing final outputs.
-- The visual edge list is a reduced subset for communication, not the full analytical matrix.

CREATE OR REPLACE VIEW mart_product_space_visual_edges AS
SELECT
    "from" AS from_product_code,
    "to" AS to_product_code,
    proximity
FROM read_csv_auto('outputs/networks/product_space_visual_edges.csv', header = true);
