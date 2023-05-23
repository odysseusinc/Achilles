-- 117	Number of persons with at least one day of observation in each month

-- cache min/max OP dates to avoid generating unused date keys
DROP TABLE IF EXISTS #temp_op_dates_117;
SELECT
    MIN(observation_period_start_date) as min_date,
    MAX(observation_period_start_date) as max_date
INTO
    #temp_op_dates_117
FROM
    @cdmDatabaseSchema.observation_period
;

-- generating date key sequences in a cross-dialect compatible fashion
DROP TABLE IF EXISTS #temp_date_keys_117;
WITH century as (select '19' num union select '20' num),
     tens as (select '0' num union select '1' num union select '2' num union select '3' num union select '4' num union select '5' num union select '6' num union select '7' num union select '8' num union select '9' num),
     ones as (select '0' num union select '1' num union select '2' num union select '3' num union select '4' num union select '5' num union select '6' num union select '7' num union select '8' num union select '9' num),
     months as (select '01' as num union select '02' num union select '03' num union select '04' num union select '05' num union select '06' num union select '07' num union select '08' num union select '09' num union select '10' num union select '11' num union select '12' num)
SELECT
    cast(concat(century.num, tens.num, ones.num,months.num) as int) ints,
    cast(concat(century.num, tens.num, ones.num)||'-'||months.num||'-01' as date) as date_begin,
    eomonth(cast(concat(century.num, tens.num, ones.num)||'-'||months.num||'-01' as date)) as date_end
INTO
    #temp_date_keys_117
FROM
    #temp_op_dates_117 op_dates, century cross join tens cross join ones cross join months
WHERE dateadd(m, 1, cast(concat(century.num, tens.num, ones.num)||'-'||months.num||'-01' as date)) >= op_dates.min_date
  AND dateadd(m, 1, eomonth(cast(concat(century.num, tens.num, ones.num)||'-'||months.num||'-01' as date))) <= op_dates.max_date
;

--HINT DISTRIBUTE_ON_KEY(stratum_1)
SELECT
    117 as analysis_id,
    CAST(t1.ints AS VARCHAR(255)) as stratum_1,
    cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
    COALESCE(COUNT_BIG(distinct op1.PERSON_ID),0) as count_value
into @scratchDatabaseSchema@schemaDelim@tempAchillesPrefix_117
FROM #temp_date_keys_117 t1
    left join
    (select t2.ints, op2.*
    from @cdmDatabaseSchema.observation_period op2, #temp_date_keys_117 t2
    where op2.observation_period_start_date <= t2.date_end
    and op2.observation_period_end_date >= t2.date_begin
    ) op1 on op1.ints = t1.ints
group by t1.ints
having COALESCE(COUNT_BIG(distinct op1.PERSON_ID),0) > 0;

TRUNCATE TABLE #temp_op_dates_117;
DROP TABLE #temp_op_dates_117;
TRUNCATE TABLE #temp_date_keys_117;
DROP TABLE #temp_date_keys_117;
