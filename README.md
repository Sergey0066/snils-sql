# SNILS

Проверка контрольного числа СНИЛС на PL/pgSQL.

## Состав

- `sql/snils.sql` - функции проверки и расчета контрольного числа
- `examples/validate_examples.sql` - примеры запросов
- `examples/trigger_example.sql` - пример проверки через триггер
- `tests/snils_tests.sql` - простые проверки

## Установка

```sql
\i sql/snils.sql
```

Или из консоли:

```bash
psql -d database_name -f sql/snils.sql
```

## Использование

```sql
SELECT snils.is_valid('112-233-445 95');
SELECT snils.is_valid('11223344595');
SELECT snils.get_checksum('112233445');
```

Массовая проверка массива:

```sql
SELECT *
FROM snils.validate_many(ARRAY[
    '112-233-445 95',
    '112-233-445 96'
]);
```

Проверка таблицы:

```sql
SELECT *
FROM snils.validate_table('public.persons', 'snils_number');
```

Для больших таблиц можно включить параллельное выполнение:

```sql
SET max_parallel_workers_per_gather = 4;

SELECT id, snils_number, snils.is_valid(snils_number)
FROM persons;
```

## Алгоритм

Для первых 9 цифр СНИЛС считается сумма произведений цифр на веса от 9 до 1. Сумма делится по модулю на 101. Если результат равен 100, контрольное число считается равным 00.

Контрольное число проверяется только для номеров больше 001-001-998.
