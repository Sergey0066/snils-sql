CREATE TABLE persons (
    id bigserial PRIMARY KEY,
    full_name text NOT NULL,
    snils_number text
);

CREATE OR REPLACE FUNCTION check_person_snils()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.snils_number IS NOT NULL AND NOT snils.is_valid(NEW.snils_number) THEN
        RAISE EXCEPTION 'Invalid SNILS: %', NEW.snils_number;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_person_snils
BEFORE INSERT OR UPDATE OF snils_number
ON persons
FOR EACH ROW
EXECUTE FUNCTION check_person_snils();
