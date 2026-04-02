SET extra_float_digits = 0;

-- 1. equiwidth histogram

-- 10 equiwidth bins on uniform [0,1]
-- check: bin count = requested, densities sum to ~1, counts sum to total
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT * FROM equiwidth_histogram((SELECT d FROM digest), 10))
SELECT
    count(*) AS num_bins,
    abs(sum(bin_density) - 1.0) < 0.01 AS density_sums_to_one,
    abs(sum(bin_count) - 10000.0) < 100 AS count_sums_to_total
FROM hist;

-- bin edges are contiguous and non-overlapping
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT row_number() OVER () AS rn, * FROM equiwidth_histogram((SELECT d FROM digest), 10))
SELECT count(*) AS gaps
FROM hist h1
JOIN hist h2 ON h2.rn = h1.rn + 1
WHERE abs(h1.bin_end - h2.bin_start) > 0.0001;

-- equiwidth bins have equal width
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT *, bin_end - bin_start AS width FROM equiwidth_histogram((SELECT d FROM digest), 5))
SELECT
    count(DISTINCT round((width)::numeric, 6)) = 1 AS all_same_width
FROM hist;

-- density consistent with tdigest_percentile_of
-- bin_density from equiwidth_histogram should
-- match cdf(bin_end) - cdf(bin_start) via tdigest_percentile_of,
-- since both use the same internal CDF computation.
WITH digest AS (SELECT tdigest(pow(i / 1000.0, 2), 100) AS d FROM generate_series(1, 1000) s(i)),
     hist AS (SELECT row_number() OVER () AS rn, * FROM equiwidth_histogram((SELECT d FROM digest), 5)),
     cdf_check AS (
         SELECT
             h.rn,
             h.bin_density,
             (SELECT tdigest_percentile_of(d, h.bin_end) FROM digest)
           - (SELECT tdigest_percentile_of(d, h.bin_start) FROM digest) AS cdf_diff
         FROM hist h
     )
SELECT
    bool_and(abs(bin_density - cdf_diff) < 0.001) AS density_matches_cdf
FROM cdf_check;

-- for uniform data, each equiwidth bin should have roughly 1/nbins density
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT * FROM equiwidth_histogram((SELECT d FROM digest), 10))
SELECT
    bool_and(abs(bin_density - 0.1) < 0.02) AS roughly_uniform
FROM hist;

-- for x^2 data (right-skewed), first bins should be denser
WITH digest AS (SELECT tdigest(pow(i / 1000.0, 2), 100) AS d FROM generate_series(1, 1000) s(i)),
     hist AS (SELECT row_number() OVER () AS rn, * FROM equiwidth_histogram((SELECT d FROM digest), 5))
SELECT
    (SELECT bin_density FROM hist WHERE rn = 1) >
    (SELECT bin_density FROM hist WHERE rn = 5) AS first_bin_denser;

-- with 1 bin, should get exactly 1 row; density/count may not be
-- exactly 1.0/100 due to CDF boundary effects in tdigest, so just
-- check we get a single row with reasonable values
WITH digest AS (SELECT tdigest(i / 100.0, 100) AS d FROM generate_series(1, 100) s(i)),
     hist AS (SELECT * FROM equiwidth_histogram((SELECT d FROM digest), 1))
SELECT
    count(*) AS num_bins,
    bool_and(bin_density > 0.9) AS density_high,
    bool_and(bin_count > 90) AS count_high
FROM hist;

-- with more bins than centroids should still work
WITH digest AS (SELECT tdigest(i / 100.0, 10) AS d FROM generate_series(1, 100) s(i)),
     hist AS (SELECT * FROM equiwidth_histogram((SELECT d FROM digest), 50))
SELECT
    count(*) = 50 AS correct_count,
    abs(sum(bin_density) - 1.0) < 0.05 AS density_sums_to_one
FROM hist;

-- empty digest returns no rows
WITH empty AS (SELECT tdigest(x, 100) AS d FROM (SELECT 1::double precision AS x WHERE false) sub)
SELECT count(*) = 0 AS empty_returns_nothing
FROM equiwidth_histogram((SELECT d FROM empty), 5);

-- nbins < 1  should raise an error
DO $$
BEGIN
    PERFORM * FROM equiwidth_histogram(
        (SELECT tdigest(i::double precision, 100) FROM generate_series(1, 10) s(i)),
        0
    );
    RAISE EXCEPTION 'should have errored';
EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'correctly rejected nbins=0';
END;
$$;


-- Higher compression yields more accurate CDF estimates, which
-- translates to more accurate equiwidth histogram bin densities.
WITH data AS (SELECT pow(i / 1000.0, 2) AS x FROM generate_series(1, 1000) s(i)),
     -- low compression
     d10 AS (SELECT tdigest(x, 10) AS d FROM data),
     h10 AS (SELECT *, sqrt(bin_end) - sqrt(greatest(bin_start, 0)) AS true_density
             FROM equiwidth_histogram((SELECT d FROM d10), 10)),
     err10 AS (SELECT max(abs(bin_density - true_density)) AS max_dev FROM h10),
     -- high compression
     d1000 AS (SELECT tdigest(x, 1000) AS d FROM data),
     h1000 AS (SELECT *, sqrt(bin_end) - sqrt(greatest(bin_start, 0)) AS true_density
               FROM equiwidth_histogram((SELECT d FROM d1000), 10)),
     err1000 AS (SELECT max(abs(bin_density - true_density)) AS max_dev FROM h1000)
SELECT
    err10.max_dev > err1000.max_dev AS higher_compression_more_accurate
FROM err10, err1000;

-- 2. equiheight histogram

-- 10 equiheight bins on uniform [0,1]
-- check: bin count = requested, density = 1/nbins for all bins
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT * FROM equiheight_histogram((SELECT d FROM digest), 10))
SELECT
    count(*) AS num_bins,
    bool_and(abs(bin_density - 0.1) < 0.001) AS all_density_equal,
    bool_and(abs(bin_count - 1000) < 0.1) AS all_count_equal
FROM hist;

-- bin edges are monotonically increasing
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT row_number() OVER () AS rn, * FROM equiheight_histogram((SELECT d FROM digest), 10))
SELECT count(*) AS violations
FROM hist
WHERE bin_start > bin_end;

-- adjacent bins should be contiguous (previous end = next start)
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT row_number() OVER () AS rn, * FROM equiheight_histogram((SELECT d FROM digest), 10))
SELECT count(*) AS gaps
FROM hist h1
JOIN hist h2 ON h2.rn = h1.rn + 1
WHERE abs(h1.bin_end - h2.bin_start) > 0.0001;

-- equiheight histogram splits data at quantile boundaries
-- for 4 bins, the internal edges should be near the 25th, 50th, 75th percentiles
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT row_number() OVER () AS rn, * FROM equiheight_histogram((SELECT d FROM digest), 4))
SELECT
    -- for uniform data [0..1], bin 2 should start near 0.25, bin 3 near 0.5, bin 4 near 0.75
    abs((SELECT bin_start FROM hist WHERE rn = 2) - 0.25) < 0.02 AS edge_at_q25,
    abs((SELECT bin_start FROM hist WHERE rn = 3) - 0.50) < 0.02 AS edge_at_q50,
    abs((SELECT bin_start FROM hist WHERE rn = 4) - 0.75) < 0.02 AS edge_at_q75;

-- uniform data: equiheight bins should be ~equal width
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT *, bin_end - bin_start AS width FROM equiheight_histogram((SELECT d FROM digest), 5))
SELECT
    -- all widths should be roughly the same for uniform data
    -- max - min width should be small relative to bin width (~0.2)
    max(width) - min(width) < 0.05 AS widths_roughly_equal
FROM hist;

-- for x^2 (right-skewed), first bins should be narrower (data concentrated at low end)
WITH digest AS (SELECT tdigest(pow(i / 1000.0, 2), 100) AS d FROM generate_series(1, 1000) s(i)),
     hist AS (SELECT row_number() OVER () AS rn, *, bin_end - bin_start AS width FROM equiheight_histogram((SELECT d FROM digest), 5))
SELECT
    (SELECT width FROM hist WHERE rn = 1) <
    (SELECT width FROM hist WHERE rn = 5) AS first_bin_narrower;

-- single bin
WITH digest AS (SELECT tdigest(i / 100.0, 100) AS d FROM generate_series(1, 100) s(i)),
     hist AS (SELECT * FROM equiheight_histogram((SELECT d FROM digest), 1))
SELECT
    count(*) AS num_bins,
    bool_and(abs(bin_density - 1.0) < 0.001) AS full_density,
    bool_and(abs(bin_count - 100) < 0.1) AS full_count
FROM hist;

-- many bins
WITH digest AS (SELECT tdigest(i / 10000.0, 100) AS d FROM generate_series(1, 10000) s(i)),
     hist AS (SELECT * FROM equiheight_histogram((SELECT d FROM digest), 50))
SELECT
    count(*) = 50 AS correct_count,
    abs(sum(bin_density) - 1.0) < 0.001 AS density_sums_to_one,
    abs(sum(bin_count) - 10000) < 0.1 AS count_sums_to_total
FROM hist;

-- empty digest returns no rows
WITH empty AS (SELECT tdigest(x, 100) AS d FROM (SELECT 1::double precision AS x WHERE false) sub)
SELECT count(*) = 0 AS empty_returns_nothing
FROM equiheight_histogram((SELECT d FROM empty), 5);

-- nbins < 1  should raise an error
DO $$
BEGIN
    PERFORM * FROM equiheight_histogram(
        (SELECT tdigest(i::double precision, 100) FROM generate_series(1, 10) s(i)),
        0
    );
    RAISE EXCEPTION 'should have errored';
EXCEPTION WHEN invalid_parameter_value THEN
    RAISE NOTICE 'correctly rejected nbins=0';
END;
$$;

-- feed equiheight bin edges back through tdigest_percentile_of and verify
-- we recover approximately k/nbins.
WITH digest AS (SELECT tdigest(pow(i / 1000.0, 2), 100) AS d FROM generate_series(1, 1000) s(i)),
     -- equiheight bin edges at quantile boundaries 0, 0.25, 0.5, 0.75, 1.0
     eh AS (SELECT row_number() OVER () AS rn, *
            FROM equiheight_histogram((SELECT d FROM digest), 4)),
     -- feed the internal bin edges back through the forward CDF
     edges AS (
         SELECT k, (SELECT bin_start FROM eh WHERE rn = k) AS edge_val
         FROM generate_series(2, 4) k
     ),
     -- compute cdf(edge_val) for each edge; tdigest_percentile_of is an
     -- aggregate, so call it once per edge via a lateral subquery
     round_trip AS (
         SELECT
             e.k,
             (e.k - 1) / 4.0 AS expected_cdf,
             (SELECT tdigest_percentile_of(d, e.edge_val) FROM digest) AS actual_cdf
         FROM edges e
     )
SELECT
    bool_and(abs(actual_cdf - expected_cdf) < 0.03) AS round_trip_consistent
FROM round_trip;


-- 3. combined

-- both histogram types should report ~same total count
WITH digest AS (SELECT tdigest(i / 1000.0, 100) AS d FROM generate_series(1, 500) s(i)),
     ew AS (SELECT sum(bin_count) AS total FROM equiwidth_histogram((SELECT d FROM digest), 10)),
     eh AS (SELECT sum(bin_count) AS total FROM equiheight_histogram((SELECT d FROM digest), 10))
SELECT
    abs(ew.total - 500) < 5 AS equiwidth_total_ok,
    abs(eh.total - 500) < 0.1 AS equiheight_total_ok,
    abs(ew.total - eh.total) < 5 AS totals_consistent
FROM ew, eh;

-- both types should produce bins covering the ~same range
WITH digest AS (SELECT tdigest(i / 1000.0, 100) AS d FROM generate_series(1, 500) s(i)),
     ew AS (SELECT min(bin_start) AS lo, max(bin_end) AS hi FROM equiwidth_histogram((SELECT d FROM digest), 10)),
     eh AS (SELECT min(bin_start) AS lo, max(bin_end) AS hi FROM equiheight_histogram((SELECT d FROM digest), 10))
SELECT
    abs(ew.lo - eh.lo) < 0.01 AS same_lower_bound,
    abs(ew.hi - eh.hi) < 0.01 AS same_upper_bound
FROM ew, eh;