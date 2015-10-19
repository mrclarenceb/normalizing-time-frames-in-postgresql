# Normalizing-time-frames-in-PostgreSQL

###Summary

The following is a *modified code snippet* of a user-defined PostgreSQL function - `udf_normalize_timeframes()` - I built to normalize time expressions in [OpenCurb](http://www.opencurb.nyc). It normalizes table rows with multiple occurences of `HH:MI(AM|PM)-HH:MI(AM|PM) & HH:MI(AM|PM)-HH:MI(AM|PM)`.

For example, executing `udf_normalize_timeframes()` on table:

denormalized_id | rule_desc
------------ | -------------
`1` | `NO PARKING 02:00AM-03:00AM & 07:00AM-10:00AM & 11:00AM-01:00PM Monday 07:00AM-10:00AM & 09:30AM-12:00PM TUESDAY`

returns:

denormalized_id | rule_desc
------------ | -------------
`1`|`NO PARKING 02:00AM-03:00AM MONDAY 07:00AM-10:00AM TUESDAY`
`1`|`NO PARKING 02:00AM-03:00AM MONDAY 09:30AM-12:00PM TUESDAY`
`1`|`NO PARKING 07:00AM-10:00AM MONDAY 07:00AM-10:00AM TUESDAY`
`1`|`NO PARKING 07:00AM-10:00AM MONDAY 09:30AM-12:00PM TUESDAY`
`1`|`NO PARKING 11:00AM-01:00PM MONDAY 07:00AM-10:00AM TUESDAY`
`1`|`NO PARKING 11:00AM-01:00PM MONDAY 09:30AM-12:00PM TUESDAY`

**Note**: There are 3 time frames before "MONDAY" and 2 before "TUESDAY" in the original table resulting in a 2x3 or 6-row time frame normalized table.

###Setup and Testing

1. Create table to be normalized: `create table tb_normalized_timeframe(dernomalized_id serial, rule_desc text);`

2. Insert into table from step 1: `insert into tb_normalized_timeframe (rule_desc) select 'NO PARKING 02:00AM-03:00AM & 07:00AM-10:00AM & 11:00AM-01:00PM MONDAY & TUESDAY 07:00AM-10:00AM & 09:30AM-12:00PM WEDNESDAY';` 
 * Verify table looks as expected: `select * from tb_normalized_timeframe;`
 
3. Load `udf_normalize_times.sql`

4. Run the function: `select udf_normalize_timeframes();`;
 * Verify table is now normalized : `select * from tb_normalized_timeframe;`

**Note**: This is basic code for time frame normalization, and just one of many transformation steps in an ETL data pipeline. It can be amended for more robustness depending on the transformation steps on the table taken prior to executing the function.
