CREATE SCHEMA IF NOT EXISTS snils;

CREATE OR REPLACE FUNCTION snils.normalize(p_snils text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
    SELECT regexp_replace(coalesce(p_snils, ''), '\D', '', 'g');
$$;

CREATE OR REPLACE FUNCTION snils.calc_checksum(p_number9 text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
AS $$
DECLARE
    v_sum integer := 0;
    v_pos integer;
BEGIN
    IF p_number9 !~ '^\d{9}$' THEN
        RAISE EXCEPTION 'Invalid base SNILS number: %', p_number9;
    END IF;

    FOR v_pos IN 1..9 LOOP
        v_sum := v_sum + substring(p_number9 from v_pos for 1)::integer * (10 - v_pos);
    END LOOP;

    v_sum := v_sum % 101;

    IF v_sum = 100 THEN
        RETURN 0;
    END IF;

    RETURN v_sum;
END;
$$;

CREATE OR REPLACE FUNCTION snils.is_valid(
    p_snils text,
    p_accept_legacy boolean DEFAULT true
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
AS $$
DECLARE
    v_digits text;
    v_number9 text;
    v_control integer;
BEGIN
    v_digits := snils.normalize(p_snils);

    IF v_digits !~ '^\d{11}$' THEN
        RETURN false;
    END IF;

    v_number9 := substring(v_digits from 1 for 9);
    v_control := substring(v_digits from 10 for 2)::integer;

    IF v_number9::integer <= 1001998 THEN
        RETURN p_accept_legacy;
    END IF;

    RETURN snils.calc_checksum(v_number9) = v_control;
END;
$$;

CREATE OR REPLACE FUNCTION snils.is_valid(p_snils bigint)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
    SELECT snils.is_valid(lpad(p_snils::text, 11, '0'));
$$;

CREATE OR REPLACE FUNCTION snils.get_checksum(p_snils text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
AS $$
DECLARE
    v_digits text;
BEGIN
    v_digits := snils.normalize(p_snils);

    IF v_digits !~ '^\d{9,11}$' THEN
        RAISE EXCEPTION 'Invalid SNILS value: %', p_snils;
    END IF;

    RETURN lpad(snils.calc_checksum(substring(v_digits from 1 for 9))::text, 2, '0');
END;
$$;

CREATE OR REPLACE FUNCTION snils.validate_many(p_items text[])
RETURNS TABLE (
    snils_value text,
    is_valid boolean
)
LANGUAGE sql
STABLE
PARALLEL SAFE
AS $$
    SELECT item, snils.is_valid(item)
    FROM unnest(p_items) AS item;
$$;

CREATE OR REPLACE FUNCTION snils.validate_table(
    p_table regclass,
    p_column name
)
RETURNS TABLE (
    row_ctid tid,
    snils_value text,
    is_valid boolean
)
LANGUAGE plpgsql
STABLE
PARALLEL SAFE
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT ctid, %1$I::text, snils.is_valid(%1$I::text) FROM %2$s',
        p_column,
        p_table
    );
END;
$$;
