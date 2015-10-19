CREATE OR REPLACE FUNCTION udf_normalize_timeframes()
RETURNS VOID AS $$
	/* 
	########
	# Author: Clarence Bowen
	########

	The following is a modified code snippet of a PostgreSQL helper function I built to normalize time expressions in www.opencurb.nyc).
	It splits out, into new rows, a row containing a de-normalized time frame in format: 
	"...HH:MI(AM|PM)-HH:MI(AM|PM) & HH:MI(AM|PM)-HH:MI(AM|PM)..."

	For example, given:

		"NO PARKING 02:00AM-03:00AM & 07:00AM-10:00AM & 11:00AM-01:00PM MONDAY 07:00AM-10:00AM & 09:30AM-12:00PM TUESDAY"
	
	executing udf_normalize_timeframes() returns:
	
		"NO PARKING 02:00AM-03:00AM MONDAY 07:00AM-10:00AM TUESDAY"
		"NO PARKING 02:00AM-03:00AM MONDAY 09:30AM-12:00PM TUESDAY"
		"NO PARKING 07:00AM-10:00AM MONDAY 07:00AM-10:00AM TUESDAY"
		"NO PARKING 07:00AM-10:00AM MONDAY 09:30AM-12:00PM TUESDAY"
		"NO PARKING 11:00AM-01:00PM MONDAY 07:00AM-10:00AM TUESDAY"
		"NO PARKING 11:00AM-01:00PM MONDAY 09:30AM-12:00PM TUESDAY"
	*/
BEGIN
	CREATE TEMPORARY TABLE temp1 AS 
		SELECT * FROM tb_normalized_timeframe WHERE 1 = 2;
	
	--normalize row for each occurrence of "...HH:MI(AM|PM)-HH:MI(AM|PM) & HH:MI(AM|PM)-HH:MI(AM|PM)..."
	LOOP
		INSERT INTO temp1(dernomalized_id, rule_desc)
		SELECT dernomalized_id, 
		regexp_replace(rule_desc, '(\d{2}:\d{2}(AM|PM)-\d{2}:\d{2}(AM|PM)((?! [A-Za-z()<]).)+)', tf, 'i') AS new_rule_desc
		FROM (
			--creates new rows with normalized time frames in "tf" column
			SELECT *, 
			regexp_split_to_table(
				( regexp_matches(rule_desc,
				  '(\d{2}:\d{2}(AM|PM)-\d{2}:\d{2}(AM|PM)((?! [A-Za-z()<]).)+)',
				  'i')
				 )[1], ' & '
			) AS tf
			FROM tb_normalized_timeframe
		) dt;

		IF NOT EXISTS (SELECT NULL FROM temp1) THEN
			EXIT;
		END IF;
		
		/*the following DELETE & INSERT mimics an "upsert" replacing de-normalized rows with normalized ones*/
		
		DELETE FROM tb_normalized_timeframe 
		WHERE EXISTS (
			SELECT NULL FROM temp1 t 
			WHERE t.dernomalized_id = tb_normalized_timeframe.dernomalized_id
		);

		INSERT INTO tb_normalized_timeframe(dernomalized_id, rule_desc)
		SELECT dernomalized_id, rule_desc FROM temp1 ;

		TRUNCATE TABLE temp1;
   END LOOP;
   
   DROP TABLE temp1;
END;
$$ LANGUAGE plpgsql;
