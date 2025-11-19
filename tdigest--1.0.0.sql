/* tdigest for the double precision */
CREATE OR REPLACE FUNCTION tdigest_add_double(p_pointer internal, p_element double precision, p_compression int)
    RETURNS internal
    AS 'tdigest', 'tdigest_add_double'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_add_double(p_pointer internal, p_element double precision, p_compression int, p_quantile double precision)
    RETURNS internal
    AS 'tdigest', 'tdigest_add_double'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_add_double_array(p_pointer internal, p_element double precision, p_compression int, p_quantile double precision[])
    RETURNS internal
    AS 'tdigest', 'tdigest_add_double_array'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_add_double_values(p_pointer internal, p_element double precision, p_compression int, p_value double precision)
    RETURNS internal
    AS 'tdigest', 'tdigest_add_double_values'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_add_double_array_values(p_pointer internal, p_element double precision, p_compression int, p_value double precision[])
    RETURNS internal
    AS 'tdigest', 'tdigest_add_double_array_values'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_percentiles(p_pointer internal)
    RETURNS double precision
    AS 'tdigest', 'tdigest_percentiles'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_array_percentiles(p_pointer internal)
    RETURNS double precision[]
    AS 'tdigest', 'tdigest_array_percentiles'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_percentiles_of(p_pointer internal)
    RETURNS double precision
    AS 'tdigest', 'tdigest_percentiles_of'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_array_percentiles_of(p_pointer internal)
    RETURNS double precision[]
    AS 'tdigest', 'tdigest_array_percentiles_of'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_combine(a internal, b internal)
    RETURNS internal
    AS 'tdigest', 'tdigest_combine'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_serial(a internal)
    RETURNS bytea
    AS 'tdigest', 'tdigest_serial'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION tdigest_deserial(a bytea, b internal)
    RETURNS internal
    AS 'tdigest', 'tdigest_deserial'
    LANGUAGE C IMMUTABLE STRICT;

CREATE AGGREGATE tdigest_percentile(double precision, int, double precision) (
    SFUNC = tdigest_add_double,
    STYPE = internal,
    FINALFUNC = tdigest_percentiles,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE AGGREGATE tdigest_percentile(double precision, int, double precision[]) (
    SFUNC = tdigest_add_double_array,
    STYPE = internal,
    FINALFUNC = tdigest_array_percentiles,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE AGGREGATE tdigest_percentile_of(double precision, int, double precision) (
    SFUNC = tdigest_add_double_values,
    STYPE = internal,
    FINALFUNC = tdigest_percentiles_of,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE AGGREGATE tdigest_percentile_of(double precision, int, double precision[]) (
    SFUNC = tdigest_add_double_array_values,
    STYPE = internal,
    FINALFUNC = tdigest_array_percentiles_of,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE TYPE tdigest;

CREATE OR REPLACE FUNCTION tdigest_in(cstring)
    RETURNS tdigest
    AS 'tdigest', 'tdigest_in'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION tdigest_out(tdigest)
    RETURNS cstring
    AS 'tdigest', 'tdigest_out'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION tdigest_send(tdigest)
    RETURNS bytea
    AS 'tdigest', 'tdigest_send'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION tdigest_recv(internal)
    RETURNS tdigest
    AS 'tdigest', 'tdigest_recv'
    LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE tdigest (
    INPUT = tdigest_in,
    OUTPUT = tdigest_out,
    RECEIVE = tdigest_recv,
    SEND = tdigest_send,
    INTERNALLENGTH = variable,
    STORAGE = external
);

CREATE OR REPLACE FUNCTION tdigest_digest(p_pointer internal)
    RETURNS tdigest
    AS 'tdigest', 'tdigest_digest'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE tdigest(double precision, int) (
    SFUNC = tdigest_add_double,
    STYPE = internal,
    FINALFUNC = tdigest_digest,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE OR REPLACE FUNCTION tdigest_add_digest(p_pointer internal, p_element tdigest)
    RETURNS internal
    AS 'tdigest', 'tdigest_add_digest'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_add_digest(p_pointer internal, p_element tdigest, p_quantile double precision)
    RETURNS internal
    AS 'tdigest', 'tdigest_add_digest'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_add_digest_array(p_pointer internal, p_element tdigest, p_quantile double precision[])
    RETURNS internal
    AS 'tdigest', 'tdigest_add_digest_array'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_add_digest_values(p_pointer internal, p_element tdigest, p_value double precision)
    RETURNS internal
    AS 'tdigest', 'tdigest_add_digest_values'
    LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION tdigest_add_digest_array_values(p_pointer internal, p_element tdigest, p_value double precision[])
    RETURNS internal
    AS 'tdigest', 'tdigest_add_digest_array_values'
    LANGUAGE C IMMUTABLE;

CREATE AGGREGATE tdigest_percentile(tdigest, double precision) (
    SFUNC = tdigest_add_digest,
    STYPE = internal,
    FINALFUNC = tdigest_percentiles,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE AGGREGATE tdigest_percentile(tdigest, double precision[]) (
    SFUNC = tdigest_add_digest_array,
    STYPE = internal,
    FINALFUNC = tdigest_array_percentiles,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE AGGREGATE tdigest_percentile_of(tdigest, double precision) (
    SFUNC = tdigest_add_digest_values,
    STYPE = internal,
    FINALFUNC = tdigest_percentiles_of,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE AGGREGATE tdigest_percentile_of(tdigest, double precision[]) (
    SFUNC = tdigest_add_digest_array_values,
    STYPE = internal,
    FINALFUNC = tdigest_array_percentiles_of,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE AGGREGATE tdigest(tdigest) (
    SFUNC = tdigest_add_digest,
    STYPE = internal,
    FINALFUNC = tdigest_digest,
    SERIALFUNC = tdigest_serial,
    DESERIALFUNC = tdigest_deserial,
    COMBINEFUNC = tdigest_combine,
    PARALLEL = SAFE
);

CREATE OR REPLACE FUNCTION tdigest_count(tdigest)
    RETURNS bigint
    AS 'tdigest', 'tdigest_count'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION equiwidth_histogram(p_digest tdigest, p_bins int)
RETURNS TABLE (bin_start double precision,
               bin_end double precision,
               bin_density double precision)
AS $$

    WITH
      range  AS (SELECT tdigest_percentile(p_digest, 0.0) AS min_value, tdigest_percentile(p_digest, 1.0) AS max_value),
      bounds AS (SELECT
                     range.min_value + (i - 1) * (range.max_value - range.min_value) / p_bins AS bin_start,
                     range.min_value + i * (range.max_value - range.min_value) / p_bins AS bin_end
                 FROM range, generate_series(1,p_bins) AS s(i))
      SELECT
          bounds.bin_start,
          bounds.bin_end,
          tdigest_percentile_of(p_digest, bounds.bin_end) - tdigest_percentile_of(p_digest, bounds.bin_start)
      FROM bounds
      GROUP BY 1, 2
      ORDER BY 1, 2;

$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION tdigest_merge(tdigests tdigest[])
RETURNS tdigest
AS $$

DECLARE
    ret tdigest;
    current tdigest;

BEGIN

    IF array_length(tdigests, 1) IS NULL THEN
        RETURN NULL;
    END IF;

    ret := tdigests[1];

    FOR i IN 2..array_upper(tdigests, 1) LOOP
        current := tdigests[i];
        IF current IS NOT NULL THEN
            ret := tdigest_union(ret, current);
        END IF;
    END LOOP;

    RETURN ret;

END;

$$ LANGUAGE plpgsql;

--- SELECT equiwidth_histogram(merged_td, 10) FROM (
---         SELECT tdigest_merge(array_agg(td)) AS merged_td
---         FROM tdigests
---     )
--- ;


CREATE OR REPLACE FUNCTION equiheight_histogram(p_digest tdigest, p_bins int)
RETURNS TABLE (bin_start double precision,
               bin_end double precision,
               bin_density double precision)
AS $$

    WITH
      freqs AS (SELECT
                     (i - 1)::double precision / p_bins AS freq_start,
                     i::double precision / p_bins AS freq_end
                 FROM generate_series(1,p_bins) AS s(i))
      SELECT
          tdigest_percentile(p_digest, freqs.freq_start),
          tdigest_percentile(p_digest, freqs.freq_end),
          freqs.freq_end - freqs.freq_start
      FROM freqs
      GROUP BY freqs.freq_start, freqs.freq_end
      ORDER BY 1, 2;

$$ LANGUAGE sql;