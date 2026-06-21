\i sql/snils.sql

DO $$
BEGIN
    IF snils.is_valid('112-233-445 95') IS NOT TRUE THEN
        RAISE EXCEPTION 'test failed: valid formatted SNILS';
    END IF;

    IF snils.is_valid('11223344595') IS NOT TRUE THEN
        RAISE EXCEPTION 'test failed: valid plain SNILS';
    END IF;

    IF snils.is_valid('112-233-445 96') IS NOT FALSE THEN
        RAISE EXCEPTION 'test failed: invalid checksum';
    END IF;

    IF snils.get_checksum('112233445') <> '95' THEN
        RAISE EXCEPTION 'test failed: checksum';
    END IF;

    IF snils.is_valid('abc') IS NOT FALSE THEN
        RAISE EXCEPTION 'test failed: invalid input';
    END IF;
END;
$$;

SELECT 'ok' AS result;
