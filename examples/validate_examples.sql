SELECT snils.is_valid('112-233-445 95');
SELECT snils.is_valid('11223344595');
SELECT snils.is_valid(11223344595::bigint);

SELECT snils.get_checksum('112233445');

SELECT *
FROM snils.validate_many(ARRAY[
    '112-233-445 95',
    '112-233-445 96',
    '001-001-998 00'
]);

SET max_parallel_workers_per_gather = 4;

SELECT id, snils_number, snils.is_valid(snils_number)
FROM persons;

SELECT *
FROM snils.validate_table('public.persons', 'snils_number');
