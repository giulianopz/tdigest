CREATE OR REPLACE FUNCTION equiwidth_histogram(tdigest, int)
    RETURNS TABLE (
        bin_start double precision,
        bin_end double precision,
        bin_density double precision,
        bin_count double precision
    )
    AS 'tdigest', 'tdigest_equiwidth_histogram'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION equiheight_histogram(tdigest, int)
    RETURNS TABLE (
        bin_start double precision,
        bin_end double precision,
        bin_density double precision,
        bin_count double precision
    )
    AS 'tdigest', 'tdigest_equiheight_histogram'
    LANGUAGE C IMMUTABLE STRICT;