toc.dat                                                                                             0000600 0004000 0002000 00000331112 14644346411 0014447 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP   )    
                |            ballmer_peak    16.3    16.3 %   W           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false         X           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false         Y           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false         Z           1262    41870    ballmer_peak    DATABASE        CREATE DATABASE ballmer_peak WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE ballmer_peak;
                postgres    false         [           0    0    DATABASE ballmer_peak    ACL     F   GRANT ALL ON DATABASE ballmer_peak TO ballmer_peak WITH GRANT OPTION;
                   postgres    false    5210                     2615    51415    pgagent    SCHEMA        CREATE SCHEMA pgagent;
    DROP SCHEMA pgagent;
                postgres    false         \           0    0    SCHEMA pgagent    COMMENT     6   COMMENT ON SCHEMA pgagent IS 'pgAgent system tables';
                   postgres    false    6                    1255    51571    pga_exception_trigger()    FUNCTION       CREATE FUNCTION pgagent.pga_exception_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE

    v_jobid int4 := 0;

BEGIN

     IF TG_OP = 'DELETE' THEN

        SELECT INTO v_jobid jscjobid FROM pgagent.pga_schedule WHERE jscid = OLD.jexscid;

        -- update pga_job from remaining schedules
        -- the actual calculation of jobnextrun will be performed in the trigger
        UPDATE pgagent.pga_job
           SET jobnextrun = NULL
         WHERE jobenabled AND jobid = v_jobid;
        RETURN OLD;
    ELSE

        SELECT INTO v_jobid jscjobid FROM pgagent.pga_schedule WHERE jscid = NEW.jexscid;

        UPDATE pgagent.pga_job
           SET jobnextrun = NULL
         WHERE jobenabled AND jobid = v_jobid;
        RETURN NEW;
    END IF;
END;
$$;
 /   DROP FUNCTION pgagent.pga_exception_trigger();
       pgagent          postgres    false    6         ]           0    0     FUNCTION pga_exception_trigger()    COMMENT     x   COMMENT ON FUNCTION pgagent.pga_exception_trigger() IS 'Update the job''s next run time whenever an exception changes';
          pgagent          postgres    false    285                    1255    51566    pga_is_leap_year(smallint)    FUNCTION       CREATE FUNCTION pgagent.pga_is_leap_year(smallint) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
BEGIN
    IF $1 % 4 != 0 THEN
        RETURN FALSE;
    END IF;

    IF $1 % 100 != 0 THEN
        RETURN TRUE;
    END IF;

    RETURN $1 % 400 = 0;
END;
$_$;
 2   DROP FUNCTION pgagent.pga_is_leap_year(smallint);
       pgagent          postgres    false    6         ^           0    0 #   FUNCTION pga_is_leap_year(smallint)    COMMENT     _   COMMENT ON FUNCTION pgagent.pga_is_leap_year(smallint) IS 'Returns TRUE if $1 is a leap year';
          pgagent          postgres    false    281                    1255    51567    pga_job_trigger()    FUNCTION       CREATE FUNCTION pgagent.pga_job_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.jobenabled THEN
        IF NEW.jobnextrun IS NULL THEN
             SELECT INTO NEW.jobnextrun
                    MIN(pgagent.pga_next_schedule(jscid, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths))
               FROM pgagent.pga_schedule
              WHERE jscenabled AND jscjobid=OLD.jobid;
        END IF;
    ELSE
        NEW.jobnextrun := NULL;
    END IF;
    RETURN NEW;
END;
$$;
 )   DROP FUNCTION pgagent.pga_job_trigger();
       pgagent          postgres    false    6         _           0    0    FUNCTION pga_job_trigger()    COMMENT     U   COMMENT ON FUNCTION pgagent.pga_job_trigger() IS 'Update the job''s next run time.';
          pgagent          postgres    false    283         	           1255    51564    pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[])    FUNCTION     þ8  CREATE FUNCTION pgagent.pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[]) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $_$
DECLARE
    jscid           ALIAS FOR $1;
    jscstart        ALIAS FOR $2;
    jscend          ALIAS FOR $3;
    jscminutes      ALIAS FOR $4;
    jschours        ALIAS FOR $5;
    jscweekdays     ALIAS FOR $6;
    jscmonthdays    ALIAS FOR $7;
    jscmonths       ALIAS FOR $8;

    nextrun         timestamp := '1970-01-01 00:00:00-00';
    runafter        timestamp := '1970-01-01 00:00:00-00';

    bingo            bool := FALSE;
    gotit            bool := FALSE;
    foundval        bool := FALSE;
    daytweak        bool := FALSE;
    minutetweak        bool := FALSE;

    i                int2 := 0;
    d                int2 := 0;

    nextminute        int2 := 0;
    nexthour        int2 := 0;
    nextday            int2 := 0;
    nextmonth       int2 := 0;
    nextyear        int2 := 0;


BEGIN
    -- No valid start date has been specified
    IF jscstart IS NULL THEN RETURN NULL; END IF;

    -- The schedule is past its end date
    IF jscend IS NOT NULL AND jscend < now() THEN RETURN NULL; END IF;

    -- Get the time to find the next run after. It will just be the later of
    -- now() + 1m and the start date for the time being, however, we might want to
    -- do more complex things using this value in the future.
    IF date_trunc('MINUTE', jscstart) > date_trunc('MINUTE', (now() + '1 Minute'::interval)) THEN
        runafter := date_trunc('MINUTE', jscstart);
    ELSE
        runafter := date_trunc('MINUTE', (now() + '1 Minute'::interval));
    END IF;

    --
    -- Enter a loop, generating next run timestamps until we find one
    -- that falls on the required weekday, and is not matched by an exception
    --

    WHILE bingo = FALSE LOOP

        --
        -- Get the next run year
        --
        nextyear := date_part('YEAR', runafter);

        --
        -- Get the next run month
        --
        nextmonth := date_part('MONTH', runafter);
        gotit := FALSE;
        FOR i IN (nextmonth) .. 12 LOOP
            IF jscmonths[i] = TRUE THEN
                nextmonth := i;
                gotit := TRUE;
                foundval := TRUE;
                EXIT;
            END IF;
        END LOOP;
        IF gotit = FALSE THEN
            FOR i IN 1 .. (nextmonth - 1) LOOP
                IF jscmonths[i] = TRUE THEN
                    nextmonth := i;

                    -- Wrap into next year
                    nextyear := nextyear + 1;
                    gotit := TRUE;
                    foundval := TRUE;
                    EXIT;
                END IF;
           END LOOP;
        END IF;

        --
        -- Get the next run day
        --
        -- If the year, or month have incremented, get the lowest day,
        -- otherwise look for the next day matching or after today.
        IF (nextyear > date_part('YEAR', runafter) OR nextmonth > date_part('MONTH', runafter)) THEN
            nextday := 1;
            FOR i IN 1 .. 32 LOOP
                IF jscmonthdays[i] = TRUE THEN
                    nextday := i;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        ELSE
            nextday := date_part('DAY', runafter);
            gotit := FALSE;
            FOR i IN nextday .. 32 LOOP
                IF jscmonthdays[i] = TRUE THEN
                    nextday := i;
                    gotit := TRUE;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            IF gotit = FALSE THEN
                FOR i IN 1 .. (nextday - 1) LOOP
                    IF jscmonthdays[i] = TRUE THEN
                        nextday := i;

                        -- Wrap into next month
                        IF nextmonth = 12 THEN
                            nextyear := nextyear + 1;
                            nextmonth := 1;
                        ELSE
                            nextmonth := nextmonth + 1;
                        END IF;
                        gotit := TRUE;
                        foundval := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END IF;

        -- Was the last day flag selected?
        IF nextday = 32 THEN
            IF nextmonth = 1 THEN
                nextday := 31;
            ELSIF nextmonth = 2 THEN
                IF pgagent.pga_is_leap_year(nextyear) = TRUE THEN
                    nextday := 29;
                ELSE
                    nextday := 28;
                END IF;
            ELSIF nextmonth = 3 THEN
                nextday := 31;
            ELSIF nextmonth = 4 THEN
                nextday := 30;
            ELSIF nextmonth = 5 THEN
                nextday := 31;
            ELSIF nextmonth = 6 THEN
                nextday := 30;
            ELSIF nextmonth = 7 THEN
                nextday := 31;
            ELSIF nextmonth = 8 THEN
                nextday := 31;
            ELSIF nextmonth = 9 THEN
                nextday := 30;
            ELSIF nextmonth = 10 THEN
                nextday := 31;
            ELSIF nextmonth = 11 THEN
                nextday := 30;
            ELSIF nextmonth = 12 THEN
                nextday := 31;
            END IF;
        END IF;

        --
        -- Get the next run hour
        --
        -- If the year, month or day have incremented, get the lowest hour,
        -- otherwise look for the next hour matching or after the current one.
        IF (nextyear > date_part('YEAR', runafter) OR nextmonth > date_part('MONTH', runafter) OR nextday > date_part('DAY', runafter) OR daytweak = TRUE) THEN
            nexthour := 0;
            FOR i IN 1 .. 24 LOOP
                IF jschours[i] = TRUE THEN
                    nexthour := i - 1;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        ELSE
            nexthour := date_part('HOUR', runafter);
            gotit := FALSE;
            FOR i IN (nexthour + 1) .. 24 LOOP
                IF jschours[i] = TRUE THEN
                    nexthour := i - 1;
                    gotit := TRUE;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            IF gotit = FALSE THEN
                FOR i IN 1 .. nexthour LOOP
                    IF jschours[i] = TRUE THEN
                        nexthour := i - 1;

                        -- Wrap into next month
                        IF (nextmonth = 1 OR nextmonth = 3 OR nextmonth = 5 OR nextmonth = 7 OR nextmonth = 8 OR nextmonth = 10 OR nextmonth = 12) THEN
                            d = 31;
                        ELSIF (nextmonth = 4 OR nextmonth = 6 OR nextmonth = 9 OR nextmonth = 11) THEN
                            d = 30;
                        ELSE
                            IF pgagent.pga_is_leap_year(nextyear) = TRUE THEN
                                d := 29;
                            ELSE
                                d := 28;
                            END IF;
                        END IF;

                        IF nextday = d THEN
                            nextday := 1;
                            IF nextmonth = 12 THEN
                                nextyear := nextyear + 1;
                                nextmonth := 1;
                            ELSE
                                nextmonth := nextmonth + 1;
                            END IF;
                        ELSE
                            nextday := nextday + 1;
                        END IF;

                        gotit := TRUE;
                        foundval := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END IF;

        --
        -- Get the next run minute
        --
        -- If the year, month day or hour have incremented, get the lowest minute,
        -- otherwise look for the next minute matching or after the current one.
        IF (nextyear > date_part('YEAR', runafter) OR nextmonth > date_part('MONTH', runafter) OR nextday > date_part('DAY', runafter) OR nexthour > date_part('HOUR', runafter) OR daytweak = TRUE) THEN
            nextminute := 0;
            IF minutetweak = TRUE THEN
        d := 1;
            ELSE
        d := date_part('MINUTE', runafter)::int2;
            END IF;
            FOR i IN d .. 60 LOOP
                IF jscminutes[i] = TRUE THEN
                    nextminute := i - 1;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        ELSE
            nextminute := date_part('MINUTE', runafter);
            gotit := FALSE;
            FOR i IN (nextminute + 1) .. 60 LOOP
                IF jscminutes[i] = TRUE THEN
                    nextminute := i - 1;
                    gotit := TRUE;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            IF gotit = FALSE THEN
                FOR i IN 1 .. nextminute LOOP
                    IF jscminutes[i] = TRUE THEN
                        nextminute := i - 1;

                        -- Wrap into next hour
                        IF (nextmonth = 1 OR nextmonth = 3 OR nextmonth = 5 OR nextmonth = 7 OR nextmonth = 8 OR nextmonth = 10 OR nextmonth = 12) THEN
                            d = 31;
                        ELSIF (nextmonth = 4 OR nextmonth = 6 OR nextmonth = 9 OR nextmonth = 11) THEN
                            d = 30;
                        ELSE
                            IF pgagent.pga_is_leap_year(nextyear) = TRUE THEN
                                d := 29;
                            ELSE
                                d := 28;
                            END IF;
                        END IF;

                        IF nexthour = 23 THEN
                            nexthour = 0;
                            IF nextday = d THEN
                                nextday := 1;
                                IF nextmonth = 12 THEN
                                    nextyear := nextyear + 1;
                                    nextmonth := 1;
                                ELSE
                                    nextmonth := nextmonth + 1;
                                END IF;
                            ELSE
                                nextday := nextday + 1;
                            END IF;
                        ELSE
                            nexthour := nexthour + 1;
                        END IF;

                        gotit := TRUE;
                        foundval := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END IF;

        -- Build the result, and check it is not the same as runafter - this may
        -- happen if all array entries are set to false. In this case, add a minute.

        nextrun := (nextyear::varchar || '-'::varchar || nextmonth::varchar || '-' || nextday::varchar || ' ' || nexthour::varchar || ':' || nextminute::varchar)::timestamptz;

        IF nextrun = runafter AND foundval = FALSE THEN
                nextrun := nextrun + INTERVAL '1 Minute';
        END IF;

        -- If the result is past the end date, exit.
        IF nextrun > jscend THEN
            RETURN NULL;
        END IF;

        -- Check to ensure that the nextrun time is actually still valid. Its
        -- possible that wrapped values may have carried the nextrun onto an
        -- invalid time or date.
        IF ((jscminutes = '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}' OR jscminutes[date_part('MINUTE', nextrun) + 1] = TRUE) AND
            (jschours = '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}' OR jschours[date_part('HOUR', nextrun) + 1] = TRUE) AND
            (jscmonthdays = '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}' OR jscmonthdays[date_part('DAY', nextrun)] = TRUE OR
            (jscmonthdays = '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,t}' AND
             ((date_part('MONTH', nextrun) IN (1,3,5,7,8,10,12) AND date_part('DAY', nextrun) = 31) OR
              (date_part('MONTH', nextrun) IN (4,6,9,11) AND date_part('DAY', nextrun) = 30) OR
              (date_part('MONTH', nextrun) = 2 AND ((pgagent.pga_is_leap_year(date_part('YEAR', nextrun)::int2) AND date_part('DAY', nextrun) = 29) OR date_part('DAY', nextrun) = 28))))) AND
            (jscmonths = '{f,f,f,f,f,f,f,f,f,f,f,f}' OR jscmonths[date_part('MONTH', nextrun)] = TRUE)) THEN


            -- Now, check to see if the nextrun time found is a) on an acceptable
            -- weekday, and b) not matched by an exception. If not, set
            -- runafter = nextrun and try again.

            -- Check for a wildcard weekday
            gotit := FALSE;
            FOR i IN 1 .. 7 LOOP
                IF jscweekdays[i] = TRUE THEN
                    gotit := TRUE;
                    EXIT;
                END IF;
            END LOOP;

            -- OK, is the correct weekday selected, or a wildcard?
            IF (jscweekdays[date_part('DOW', nextrun) + 1] = TRUE OR gotit = FALSE) THEN

                -- Check for exceptions
                SELECT INTO d jexid FROM pgagent.pga_exception WHERE jexscid = jscid AND ((jexdate = nextrun::date AND jextime = nextrun::time) OR (jexdate = nextrun::date AND jextime IS NULL) OR (jexdate IS NULL AND jextime = nextrun::time));
                IF FOUND THEN
                    -- Nuts - found an exception. Increment the time and try again
                    runafter := nextrun + INTERVAL '1 Minute';
                    bingo := FALSE;
                    minutetweak := TRUE;
            daytweak := FALSE;
                ELSE
                    bingo := TRUE;
                END IF;
            ELSE
                -- We're on the wrong week day - increment a day and try again.
                runafter := nextrun + INTERVAL '1 Day';
                bingo := FALSE;
                minutetweak := FALSE;
                daytweak := TRUE;
            END IF;

        ELSE
            runafter := nextrun + INTERVAL '1 Minute';
            bingo := FALSE;
            minutetweak := TRUE;
        daytweak := FALSE;
        END IF;

    END LOOP;

    RETURN nextrun;
END;
$_$;
    DROP FUNCTION pgagent.pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[]);
       pgagent          postgres    false    6         `           0    0    FUNCTION pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[])    COMMENT     Ù   COMMENT ON FUNCTION pgagent.pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[]) IS 'Calculates the next runtime for a given schedule';
          pgagent          postgres    false    265                    1255    51569    pga_schedule_trigger()    FUNCTION     /  CREATE FUNCTION pgagent.pga_schedule_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        -- update pga_job from remaining schedules
        -- the actual calculation of jobnextrun will be performed in the trigger
        UPDATE pgagent.pga_job
           SET jobnextrun = NULL
         WHERE jobenabled AND jobid=OLD.jscjobid;
        RETURN OLD;
    ELSE
        UPDATE pgagent.pga_job
           SET jobnextrun = NULL
         WHERE jobenabled AND jobid=NEW.jscjobid;
        RETURN NEW;
    END IF;
END;
$$;
 .   DROP FUNCTION pgagent.pga_schedule_trigger();
       pgagent          postgres    false    6         a           0    0    FUNCTION pga_schedule_trigger()    COMMENT     u   COMMENT ON FUNCTION pgagent.pga_schedule_trigger() IS 'Update the job''s next run time whenever a schedule changes';
          pgagent          postgres    false    284                    1255    51563    pgagent_schema_version()    FUNCTION     í   CREATE FUNCTION pgagent.pgagent_schema_version() RETURNS smallint
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- RETURNS PGAGENT MAJOR VERSION
    -- WE WILL CHANGE THE MAJOR VERSION, ONLY IF THERE IS A SCHEMA CHANGE
    RETURN 4;
END;
$$;
 0   DROP FUNCTION pgagent.pgagent_schema_version();
       pgagent          postgres    false    6                    1255    51247    get_back_money_function()    FUNCTION       CREATE FUNCTION public.get_back_money_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

if(NEW.has_suspended=true and OLD.has_suspended=false) then

update users set money=money+ OLD.price*(select count(*) from ticket where user_id=id and concert_id=OLD.id) where id in (select users.id from users,ticket where ticket.concert_id=OLD.id );


end if;
return NEW;





END;$$;
 0   DROP FUNCTION public.get_back_money_function();
       public          postgres    false                    1255    51168    get_interactions()    FUNCTION     ~  CREATE FUNCTION public.get_interactions() RETURNS TABLE(__id integer, _mid integer, _sid integer, _genre character varying, inter bigint)
    LANGUAGE plpgsql
    AS $$begin
return Query(select _id,mid,sid,genre ,sum(interactions)
from((select users.id as _id,music_id as mid,singer_id as sid,genre as genre,2 as interactions
from users,musiclikes,musics,albums
where  users.id=musiclikes.user_id 
and musics.id=musiclikes.music_id
and musics.album_id=albums.id
)
union all
(select users.id as _id,music_id as mid,singer_id as sid,genre as genre,1 as interactions
from users,playlistlikes,playlist_music,musics,albums
where  users.id=playlistlikes.user_id
and playlistlikes.playlist_id=playlist_music.playlist_id
and playlist_music.music_id=musics.id
and musics.album_id=albums.id
)
union all
(
select users.id as _id,music_id as mid,singer_id as sid,genre as genre,4 as interactions
from users,favoritemusics,musics,albums
where  users.id=favoritemusics.user_id 
and musics.id=favoritemusics.music_id
and musics.album_id=albums.id
)
union all 
(
select users.id as _id,music_id as mid,singer_id as sid,genre as genre,1 as interactions
from users,favoriteplaylists,playlist_music,musics,albums
where  users.id=favoriteplaylists.user_id
and favoriteplaylists.playlist_id=playlist_music.playlist_id
and playlist_music.music_id=musics.id
and musics.album_id=albums.id
))group by _id,mid,sid,genre); 

end;$$;
 )   DROP FUNCTION public.get_interactions();
       public          postgres    false                    1255    51249    get_money_function()    FUNCTION     3  CREATE FUNCTION public.get_money_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN


declare concert_price bigint;
begin
	select price into concert_price from concerts where id=NEW.concert_id;
	
	update users set money=money-concert_price where id=NEW.user_id ;
end;


return NEW;




END;$$;
 +   DROP FUNCTION public.get_money_function();
       public          postgres    false                    1255    51163    get_musics_in_playlist(integer)    FUNCTION       CREATE FUNCTION public.get_musics_in_playlist(_id integer) RETURNS TABLE(id integer, album_id integer, name character varying, genre character varying, rangeage character varying, cover_image_path character varying, can_add_to_playlist boolean, text text)
    LANGUAGE plpgsql
    AS $$
begin

	return Query(
		select musics.id , musics.album_id , musics.name , musics.genre ,musics.rangeage , musics.cover_image_path ,musics.can_add_to_playlist ,musics.text 
		from musics
		join playlists on playlists.id=musics.id
	);

end $$;
 :   DROP FUNCTION public.get_musics_in_playlist(_id integer);
       public          postgres    false                    1255    51216    get_predictions(integer)    FUNCTION     ó  CREATE FUNCTION public.get_predictions(_user_id integer) RETURNS TABLE(image_url character varying, audio_url character varying, name character varying, singer_id integer, id integer, rank integer)
    LANGUAGE plpgsql
    AS $$
begin
return query
with base_predictions as (select musics.image_url,musics.audio_url,musics.name,albums.singer_id,musics.id as _music_id,predictions.rank as music_id from predictions,musics,albums
where predictions.music_id=musics.id and album_id=albums.id and predictions.user_id=_user_id)

 
 select * from(
	 select * from base_predictions
	 union 
	 (select musics.image_url,musics.audio_url,musics.name,albums.singer_id,musics.id,-1 as rank 
	 from musics
	 LEFT JOIN  musiclikes ON musics.id=musiclikes.music_id 
	 JOIN albums ON musics.album_id=albums.id 
	 where musics.id not in(select  _music_id from base_predictions)
	 group by musics.image_url,musics.name,albums.singer_id,musics.id
	 order by count(*))
 ) as combined_result
 order by rank desc
 limit 6;
 
 
end;$$;
 8   DROP FUNCTION public.get_predictions(_user_id integer);
       public          postgres    false         
           1255    51196    get_singer_id(integer)    FUNCTION     ì   CREATE FUNCTION public.get_singer_id(music_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$begin

declare res int;
begin
	select singer_id into res from musics,albums where albums.id=musics.album_id;
	return res;
end;

end$$;
 6   DROP FUNCTION public.get_singer_id(music_id integer);
       public          postgres    false                    1255    51200    get_users_playlists(integer)    FUNCTION     9  CREATE FUNCTION public.get_users_playlists(user_id integer) RETURNS TABLE(id integer, owner_id integer, is_public boolean, image_url character varying, name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY 
    SELECT 
	
        playlists.id AS id,
        playlists.owner_id AS owner_id,
        playlists.is_public AS is_public,
		
        (
            SELECT musics.image_url
            FROM playlists
            JOIN playlist_music ON playlists.id = playlist_music.playlist_id
            JOIN musics ON musics.id = playlist_music.music_id
            WHERE playlists.id = playlists.id  -- Ensure correct reference
            ORDER BY playlist_music.music_id
            LIMIT 1
        ) AS image_url,playlists.name AS name
    FROM playlists
    WHERE playlists.owner_id = user_id;
END;
$$;
 ;   DROP FUNCTION public.get_users_playlists(user_id integer);
       public          postgres    false                     1255    51242    notify_comment()    FUNCTION     s  CREATE FUNCTION public.notify_comment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	declare singer_name varchar(200);
	declare music_name varchar(200);
	begin
		select users.username,musics.name into singer_name,music_name from musics,albums,users where musics.album_id=albums.id and albums.singer_id=users.id and NEW.music_id=musics.id;
		
	    INSERT INTO messages(sender_id,reciever_id,text) 
		(
		(select NEW.user_id,friendrequests.sender_id, '<p style="opacity:60%">ð¬ commented on  music  <strong>' || music_name ||'</strong>ð¬</p>'
		from friendrequests where accepted and reciever_id=NEW.user_id)
		union all 
		(select NEW.user_id,friendrequests.reciever_id, '<p style="opacity:60%">ð¬ commented on  music  <strong>' || music_name ||'</strong>ð¬</p>'
		from friendrequests where accepted and sender_id=NEW.user_id)
		
		);
	    RETURN NEW;
	end;
END;
$$;
 '   DROP FUNCTION public.notify_comment();
       public          postgres    false                    1255    51244    notify_like()    FUNCTION       CREATE FUNCTION public.notify_like() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	declare singer_name varchar(200);
	declare musicname varchar(200);
	
	begin
		select users.username  , musics.name into singer_name,musicname from musics,albums,users where musics.album_id=albums.id and albums.singer_id=users.id and NEW.music_id=musics.id;
		
	    INSERT INTO messages(sender_id,reciever_id,text) 
		(
		(select NEW.user_id,friendrequests.sender_id, '<p style="opacity:60%">â¤ï¸ liked music <strong>' || musicname || '</string> by '|| singer_name ||'â¤ï¸</p>'
		from friendrequests where accepted and reciever_id=NEW.user_id)
		union all 
		(select NEW.user_id,friendrequests.reciever_id, '<p style="opacity:60%">â¤ï¸ liked music <strong>' || musicname || '</string> by '|| singer_name ||'â¤ï¸</p>'
		from friendrequests where accepted and sender_id=NEW.user_id)
		
		);
	    RETURN NEW;
	end;
END;
$$;
 $   DROP FUNCTION public.notify_like();
       public          postgres    false                    1259    51511    pga_exception    TABLE        CREATE TABLE pgagent.pga_exception (
    jexid integer NOT NULL,
    jexscid integer NOT NULL,
    jexdate date,
    jextime time without time zone
);
 "   DROP TABLE pgagent.pga_exception;
       pgagent         heap    postgres    false    6                    1259    51510    pga_exception_jexid_seq    SEQUENCE        CREATE SEQUENCE pgagent.pga_exception_jexid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE pgagent.pga_exception_jexid_seq;
       pgagent          postgres    false    6    258         b           0    0    pga_exception_jexid_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE pgagent.pga_exception_jexid_seq OWNED BY pgagent.pga_exception.jexid;
          pgagent          postgres    false    257         ü            1259    51435    pga_job    TABLE       CREATE TABLE pgagent.pga_job (
    jobid integer NOT NULL,
    jobjclid integer NOT NULL,
    jobname text NOT NULL,
    jobdesc text DEFAULT ''::text NOT NULL,
    jobhostagent text DEFAULT ''::text NOT NULL,
    jobenabled boolean DEFAULT true NOT NULL,
    jobcreated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jobchanged timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jobagentid integer,
    jobnextrun timestamp with time zone,
    joblastrun timestamp with time zone
);
    DROP TABLE pgagent.pga_job;
       pgagent         heap    postgres    false    6         c           0    0    TABLE pga_job    COMMENT     6   COMMENT ON TABLE pgagent.pga_job IS 'Job main entry';
          pgagent          postgres    false    252         d           0    0    COLUMN pga_job.jobagentid    COMMENT     [   COMMENT ON COLUMN pgagent.pga_job.jobagentid IS 'Agent that currently executes this job.';
          pgagent          postgres    false    252         û            1259    51434    pga_job_jobid_seq    SEQUENCE        CREATE SEQUENCE pgagent.pga_job_jobid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE pgagent.pga_job_jobid_seq;
       pgagent          postgres    false    252    6         e           0    0    pga_job_jobid_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE pgagent.pga_job_jobid_seq OWNED BY pgagent.pga_job.jobid;
          pgagent          postgres    false    251         ø            1259    51416    pga_jobagent    TABLE     ¯   CREATE TABLE pgagent.pga_jobagent (
    jagpid integer NOT NULL,
    jaglogintime timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jagstation text NOT NULL
);
 !   DROP TABLE pgagent.pga_jobagent;
       pgagent         heap    postgres    false    6         f           0    0    TABLE pga_jobagent    COMMENT     >   COMMENT ON TABLE pgagent.pga_jobagent IS 'Active job agents';
          pgagent          postgres    false    248         ú            1259    51425    pga_jobclass    TABLE     ]   CREATE TABLE pgagent.pga_jobclass (
    jclid integer NOT NULL,
    jclname text NOT NULL
);
 !   DROP TABLE pgagent.pga_jobclass;
       pgagent         heap    postgres    false    6         g           0    0    TABLE pga_jobclass    COMMENT     ?   COMMENT ON TABLE pgagent.pga_jobclass IS 'Job classification';
          pgagent          postgres    false    250         ù            1259    51424    pga_jobclass_jclid_seq    SEQUENCE        CREATE SEQUENCE pgagent.pga_jobclass_jclid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE pgagent.pga_jobclass_jclid_seq;
       pgagent          postgres    false    250    6         h           0    0    pga_jobclass_jclid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE pgagent.pga_jobclass_jclid_seq OWNED BY pgagent.pga_jobclass.jclid;
          pgagent          postgres    false    249                    1259    51525 
   pga_joblog    TABLE       CREATE TABLE pgagent.pga_joblog (
    jlgid integer NOT NULL,
    jlgjobid integer NOT NULL,
    jlgstatus character(1) DEFAULT 'r'::bpchar NOT NULL,
    jlgstart timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jlgduration interval,
    CONSTRAINT pga_joblog_jlgstatus_check CHECK ((jlgstatus = ANY (ARRAY['r'::bpchar, 's'::bpchar, 'f'::bpchar, 'i'::bpchar, 'd'::bpchar])))
);
    DROP TABLE pgagent.pga_joblog;
       pgagent         heap    postgres    false    6         i           0    0    TABLE pga_joblog    COMMENT     8   COMMENT ON TABLE pgagent.pga_joblog IS 'Job run logs.';
          pgagent          postgres    false    260         j           0    0    COLUMN pga_joblog.jlgstatus    COMMENT        COMMENT ON COLUMN pgagent.pga_joblog.jlgstatus IS 'Status of job: r=running, s=successfully finished, f=failed, i=no steps to execute, d=aborted';
          pgagent          postgres    false    260                    1259    51524    pga_joblog_jlgid_seq    SEQUENCE        CREATE SEQUENCE pgagent.pga_joblog_jlgid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE pgagent.pga_joblog_jlgid_seq;
       pgagent          postgres    false    6    260         k           0    0    pga_joblog_jlgid_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE pgagent.pga_joblog_jlgid_seq OWNED BY pgagent.pga_joblog.jlgid;
          pgagent          postgres    false    259         þ            1259    51459    pga_jobstep    TABLE        CREATE TABLE pgagent.pga_jobstep (
    jstid integer NOT NULL,
    jstjobid integer NOT NULL,
    jstname text NOT NULL,
    jstdesc text DEFAULT ''::text NOT NULL,
    jstenabled boolean DEFAULT true NOT NULL,
    jstkind character(1) NOT NULL,
    jstcode text NOT NULL,
    jstconnstr text DEFAULT ''::text NOT NULL,
    jstdbname name DEFAULT ''::name NOT NULL,
    jstonerror character(1) DEFAULT 'f'::bpchar NOT NULL,
    jscnextrun timestamp with time zone,
    CONSTRAINT pga_jobstep_check CHECK ((((jstconnstr <> ''::text) AND (jstkind = 's'::bpchar)) OR ((jstconnstr = ''::text) AND ((jstkind = 'b'::bpchar) OR (jstdbname <> ''::name))))),
    CONSTRAINT pga_jobstep_check1 CHECK ((((jstdbname <> ''::name) AND (jstkind = 's'::bpchar)) OR ((jstdbname = ''::name) AND ((jstkind = 'b'::bpchar) OR (jstconnstr <> ''::text))))),
    CONSTRAINT pga_jobstep_jstkind_check CHECK ((jstkind = ANY (ARRAY['b'::bpchar, 's'::bpchar]))),
    CONSTRAINT pga_jobstep_jstonerror_check CHECK ((jstonerror = ANY (ARRAY['f'::bpchar, 's'::bpchar, 'i'::bpchar])))
);
     DROP TABLE pgagent.pga_jobstep;
       pgagent         heap    postgres    false    6         l           0    0    TABLE pga_jobstep    COMMENT     C   COMMENT ON TABLE pgagent.pga_jobstep IS 'Job step to be executed';
          pgagent          postgres    false    254         m           0    0    COLUMN pga_jobstep.jstkind    COMMENT     T   COMMENT ON COLUMN pgagent.pga_jobstep.jstkind IS 'Kind of jobstep: s=sql, b=batch';
          pgagent          postgres    false    254         n           0    0    COLUMN pga_jobstep.jstonerror    COMMENT     ¼   COMMENT ON COLUMN pgagent.pga_jobstep.jstonerror IS 'What to do if step returns an error: f=fail the job, s=mark step as succeeded and continue, i=mark as fail but ignore it and proceed';
          pgagent          postgres    false    254         ý            1259    51458    pga_jobstep_jstid_seq    SEQUENCE        CREATE SEQUENCE pgagent.pga_jobstep_jstid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE pgagent.pga_jobstep_jstid_seq;
       pgagent          postgres    false    254    6         o           0    0    pga_jobstep_jstid_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE pgagent.pga_jobstep_jstid_seq OWNED BY pgagent.pga_jobstep.jstid;
          pgagent          postgres    false    253                    1259    51541    pga_jobsteplog    TABLE     Ü  CREATE TABLE pgagent.pga_jobsteplog (
    jslid integer NOT NULL,
    jsljlgid integer NOT NULL,
    jsljstid integer NOT NULL,
    jslstatus character(1) DEFAULT 'r'::bpchar NOT NULL,
    jslresult integer,
    jslstart timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jslduration interval,
    jsloutput text,
    CONSTRAINT pga_jobsteplog_jslstatus_check CHECK ((jslstatus = ANY (ARRAY['r'::bpchar, 's'::bpchar, 'i'::bpchar, 'f'::bpchar, 'd'::bpchar])))
);
 #   DROP TABLE pgagent.pga_jobsteplog;
       pgagent         heap    postgres    false    6         p           0    0    TABLE pga_jobsteplog    COMMENT     A   COMMENT ON TABLE pgagent.pga_jobsteplog IS 'Job step run logs.';
          pgagent          postgres    false    262         q           0    0    COLUMN pga_jobsteplog.jslstatus    COMMENT     ¦   COMMENT ON COLUMN pgagent.pga_jobsteplog.jslstatus IS 'Status of job step: r=running, s=successfully finished,  f=failed stopping job, i=ignored failure, d=aborted';
          pgagent          postgres    false    262         r           0    0    COLUMN pga_jobsteplog.jslresult    COMMENT     Q   COMMENT ON COLUMN pgagent.pga_jobsteplog.jslresult IS 'Return code of job step';
          pgagent          postgres    false    262                    1259    51540    pga_jobsteplog_jslid_seq    SEQUENCE        CREATE SEQUENCE pgagent.pga_jobsteplog_jslid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE pgagent.pga_jobsteplog_jslid_seq;
       pgagent          postgres    false    6    262         s           0    0    pga_jobsteplog_jslid_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE pgagent.pga_jobsteplog_jslid_seq OWNED BY pgagent.pga_jobsteplog.jslid;
          pgagent          postgres    false    261                     1259    51483    pga_schedule    TABLE     '  CREATE TABLE pgagent.pga_schedule (
    jscid integer NOT NULL,
    jscjobid integer NOT NULL,
    jscname text NOT NULL,
    jscdesc text DEFAULT ''::text NOT NULL,
    jscenabled boolean DEFAULT true NOT NULL,
    jscstart timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jscend timestamp with time zone,
    jscminutes boolean[] DEFAULT '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    jschours boolean[] DEFAULT '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    jscweekdays boolean[] DEFAULT '{f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    jscmonthdays boolean[] DEFAULT '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    jscmonths boolean[] DEFAULT '{f,f,f,f,f,f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    CONSTRAINT pga_schedule_jschours_size CHECK ((array_upper(jschours, 1) = 24)),
    CONSTRAINT pga_schedule_jscminutes_size CHECK ((array_upper(jscminutes, 1) = 60)),
    CONSTRAINT pga_schedule_jscmonthdays_size CHECK ((array_upper(jscmonthdays, 1) = 32)),
    CONSTRAINT pga_schedule_jscmonths_size CHECK ((array_upper(jscmonths, 1) = 12)),
    CONSTRAINT pga_schedule_jscweekdays_size CHECK ((array_upper(jscweekdays, 1) = 7))
);
 !   DROP TABLE pgagent.pga_schedule;
       pgagent         heap    postgres    false    6         t           0    0    TABLE pga_schedule    COMMENT     D   COMMENT ON TABLE pgagent.pga_schedule IS 'Job schedule exceptions';
          pgagent          postgres    false    256         ÿ            1259    51482    pga_schedule_jscid_seq    SEQUENCE        CREATE SEQUENCE pgagent.pga_schedule_jscid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE pgagent.pga_schedule_jscid_seq;
       pgagent          postgres    false    256    6         u           0    0    pga_schedule_jscid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE pgagent.pga_schedule_jscid_seq OWNED BY pgagent.pga_schedule.jscid;
          pgagent          postgres    false    255         Ù            1259    50881    albumcomments    TABLE     »   CREATE TABLE public.albumcomments (
    id integer NOT NULL,
    album_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 !   DROP TABLE public.albumcomments;
       public         heap    postgres    false         v           0    0    TABLE albumcomments    ACL     9   GRANT ALL ON TABLE public.albumcomments TO ballmer_peak;
          public          postgres    false    217         Ø            1259    50880    albumcomment_id_seq    SEQUENCE        CREATE SEQUENCE public.albumcomment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.albumcomment_id_seq;
       public          postgres    false    217         w           0    0    albumcomment_id_seq    SEQUENCE OWNED BY     L   ALTER SEQUENCE public.albumcomment_id_seq OWNED BY public.albumcomments.id;
          public          postgres    false    216         x           0    0    SEQUENCE albumcomment_id_seq    ACL     B   GRANT ALL ON SEQUENCE public.albumcomment_id_seq TO ballmer_peak;
          public          postgres    false    216         ì            1259    50950 
   albumlikes    TABLE     `   CREATE TABLE public.albumlikes (
    album_id integer NOT NULL,
    user_id integer NOT NULL
);
    DROP TABLE public.albumlikes;
       public         heap    postgres    false         y           0    0    TABLE albumlikes    ACL     6   GRANT ALL ON TABLE public.albumlikes TO ballmer_peak;
          public          postgres    false    236         Û            1259    50888    albums    TABLE     p   CREATE TABLE public.albums (
    id integer NOT NULL,
    singer_id integer,
    name character varying(100)
);
    DROP TABLE public.albums;
       public         heap    postgres    false         z           0    0    TABLE albums    ACL     2   GRANT ALL ON TABLE public.albums TO ballmer_peak;
          public          postgres    false    219         Ú            1259    50887    albums_id_seq    SEQUENCE        CREATE SEQUENCE public.albums_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.albums_id_seq;
       public          postgres    false    219         {           0    0    albums_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.albums_id_seq OWNED BY public.albums.id;
          public          postgres    false    218         |           0    0    SEQUENCE albums_id_seq    ACL     <   GRANT ALL ON SEQUENCE public.albums_id_seq TO ballmer_peak;
          public          postgres    false    218         Ý            1259    50893    concerts    TABLE        CREATE TABLE public.concerts (
    id integer NOT NULL,
    singer_id integer,
    price bigint,
    date date,
    has_suspended boolean DEFAULT false
);
    DROP TABLE public.concerts;
       public         heap    postgres    false         }           0    0    TABLE concerts    ACL     4   GRANT ALL ON TABLE public.concerts TO ballmer_peak;
          public          postgres    false    221         Ü            1259    50892    concerts_id_seq    SEQUENCE        CREATE SEQUENCE public.concerts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.concerts_id_seq;
       public          postgres    false    221         ~           0    0    concerts_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.concerts_id_seq OWNED BY public.concerts.id;
          public          postgres    false    220                    0    0    SEQUENCE concerts_id_seq    ACL     >   GRANT ALL ON SEQUENCE public.concerts_id_seq TO ballmer_peak;
          public          postgres    false    220         ß            1259    50899    favoritemusics    TABLE     k   CREATE TABLE public.favoritemusics (
    id integer NOT NULL,
    music_id integer,
    user_id integer
);
 "   DROP TABLE public.favoritemusics;
       public         heap    postgres    false                    0    0    TABLE favoritemusics    ACL     :   GRANT ALL ON TABLE public.favoritemusics TO ballmer_peak;
          public          postgres    false    223         Þ            1259    50898    favoritemusics_id_seq    SEQUENCE        CREATE SEQUENCE public.favoritemusics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.favoritemusics_id_seq;
       public          postgres    false    223                    0    0    favoritemusics_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.favoritemusics_id_seq OWNED BY public.favoritemusics.id;
          public          postgres    false    222                    0    0    SEQUENCE favoritemusics_id_seq    ACL     D   GRANT ALL ON SEQUENCE public.favoritemusics_id_seq TO ballmer_peak;
          public          postgres    false    222         á            1259    50904    favoriteplaylists    TABLE     q   CREATE TABLE public.favoriteplaylists (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer
);
 %   DROP TABLE public.favoriteplaylists;
       public         heap    postgres    false                    0    0    TABLE favoriteplaylists    ACL     =   GRANT ALL ON TABLE public.favoriteplaylists TO ballmer_peak;
          public          postgres    false    225         à            1259    50903    favoriteplaylists_id_seq    SEQUENCE        CREATE SEQUENCE public.favoriteplaylists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.favoriteplaylists_id_seq;
       public          postgres    false    225                    0    0    favoriteplaylists_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.favoriteplaylists_id_seq OWNED BY public.favoriteplaylists.id;
          public          postgres    false    224                    0    0 !   SEQUENCE favoriteplaylists_id_seq    ACL     G   GRANT ALL ON SEQUENCE public.favoriteplaylists_id_seq TO ballmer_peak;
          public          postgres    false    224         â            1259    50908 	   followers    TABLE     b   CREATE TABLE public.followers (
    follower_id integer NOT NULL,
    user_id integer NOT NULL
);
    DROP TABLE public.followers;
       public         heap    postgres    false                    0    0    TABLE followers    ACL     5   GRANT ALL ON TABLE public.followers TO ballmer_peak;
          public          postgres    false    226         ã            1259    50911    friendrequests    TABLE        CREATE TABLE public.friendrequests (
    sender_id integer NOT NULL,
    reciever_id integer NOT NULL,
    accepted boolean DEFAULT false
);
 "   DROP TABLE public.friendrequests;
       public         heap    postgres    false                    0    0    TABLE friendrequests    ACL     :   GRANT ALL ON TABLE public.friendrequests TO ballmer_peak;
          public          postgres    false    227         ÷            1259    51218    messages    TABLE     »   CREATE TABLE public.messages (
    id integer NOT NULL,
    sender_id integer,
    reciever_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.messages;
       public         heap    postgres    false                    0    0    TABLE messages    ACL     F   GRANT ALL ON TABLE public.messages TO ballmer_peak WITH GRANT OPTION;
          public          postgres    false    247         ö            1259    51217    messages_id_seq    SEQUENCE        CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.messages_id_seq;
       public          postgres    false    247                    0    0    messages_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;
          public          postgres    false    246                    0    0    SEQUENCE messages_id_seq    ACL     G   GRANT SELECT,USAGE ON SEQUENCE public.messages_id_seq TO ballmer_peak;
          public          postgres    false    246         å            1259    50916    musiccomments    TABLE     »   CREATE TABLE public.musiccomments (
    id integer NOT NULL,
    music_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 !   DROP TABLE public.musiccomments;
       public         heap    postgres    false                    0    0    TABLE musiccomments    ACL     9   GRANT ALL ON TABLE public.musiccomments TO ballmer_peak;
          public          postgres    false    229         ä            1259    50915    musiccomments_id_seq    SEQUENCE        CREATE SEQUENCE public.musiccomments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.musiccomments_id_seq;
       public          postgres    false    229                    0    0    musiccomments_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.musiccomments_id_seq OWNED BY public.musiccomments.id;
          public          postgres    false    228                    0    0    SEQUENCE musiccomments_id_seq    ACL     C   GRANT ALL ON SEQUENCE public.musiccomments_id_seq TO ballmer_peak;
          public          postgres    false    228         æ            1259    50923 
   musiclikes    TABLE     `   CREATE TABLE public.musiclikes (
    music_id integer NOT NULL,
    user_id integer NOT NULL
);
    DROP TABLE public.musiclikes;
       public         heap    postgres    false                    0    0    TABLE musiclikes    ACL     6   GRANT ALL ON TABLE public.musiclikes TO ballmer_peak;
          public          postgres    false    230         è            1259    50928    musics    TABLE     q  CREATE TABLE public.musics (
    id integer NOT NULL,
    album_id integer,
    name character varying(100),
    genre character varying(100),
    rangeage character varying(100),
    image_url character varying(200) DEFAULT NULL::character varying,
    can_add_to_playlist boolean DEFAULT false,
    text text DEFAULT ''::text,
    audio_url character varying(200)
);
    DROP TABLE public.musics;
       public         heap    postgres    false                    0    0    TABLE musics    ACL     2   GRANT ALL ON TABLE public.musics TO ballmer_peak;
          public          postgres    false    232         ç            1259    50927    musics_id_seq    SEQUENCE        CREATE SEQUENCE public.musics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.musics_id_seq;
       public          postgres    false    232                    0    0    musics_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.musics_id_seq OWNED BY public.musics.id;
          public          postgres    false    231                    0    0    SEQUENCE musics_id_seq    ACL     <   GRANT ALL ON SEQUENCE public.musics_id_seq TO ballmer_peak;
          public          postgres    false    231         ô            1259    51147    playlist_music    TABLE     h   CREATE TABLE public.playlist_music (
    music_id integer NOT NULL,
    playlist_id integer NOT NULL
);
 "   DROP TABLE public.playlist_music;
       public         heap    postgres    false                    0    0    TABLE playlist_music    ACL     :   GRANT ALL ON TABLE public.playlist_music TO ballmer_peak;
          public          postgres    false    244         ê            1259    50938    playlistcomments    TABLE     Á   CREATE TABLE public.playlistcomments (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 $   DROP TABLE public.playlistcomments;
       public         heap    postgres    false                    0    0    TABLE playlistcomments    ACL     <   GRANT ALL ON TABLE public.playlistcomments TO ballmer_peak;
          public          postgres    false    234         é            1259    50937    playlistcomments_id_seq    SEQUENCE        CREATE SEQUENCE public.playlistcomments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.playlistcomments_id_seq;
       public          postgres    false    234                    0    0    playlistcomments_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.playlistcomments_id_seq OWNED BY public.playlistcomments.id;
          public          postgres    false    233                    0    0     SEQUENCE playlistcomments_id_seq    ACL     F   GRANT ALL ON SEQUENCE public.playlistcomments_id_seq TO ballmer_peak;
          public          postgres    false    233         ë            1259    50945    playlistlikes    TABLE     f   CREATE TABLE public.playlistlikes (
    playlist_id integer NOT NULL,
    user_id integer NOT NULL
);
 !   DROP TABLE public.playlistlikes;
       public         heap    postgres    false                    0    0    TABLE playlistlikes    ACL     9   GRANT ALL ON TABLE public.playlistlikes TO ballmer_peak;
          public          postgres    false    235         î            1259    50955 	   playlists    TABLE        CREATE TABLE public.playlists (
    id integer NOT NULL,
    owner_id integer,
    is_public boolean DEFAULT true,
    name character varying(100)
);
    DROP TABLE public.playlists;
       public         heap    postgres    false                    0    0    TABLE playlists    ACL     5   GRANT ALL ON TABLE public.playlists TO ballmer_peak;
          public          postgres    false    238         í            1259    50954    playlists_id_seq    SEQUENCE        CREATE SEQUENCE public.playlists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.playlists_id_seq;
       public          postgres    false    238                    0    0    playlists_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.playlists_id_seq OWNED BY public.playlists.id;
          public          postgres    false    237                    0    0    SEQUENCE playlists_id_seq    ACL     ?   GRANT ALL ON SEQUENCE public.playlists_id_seq TO ballmer_peak;
          public          postgres    false    237         õ            1259    51169    predictions    TABLE     |   CREATE TABLE public.predictions (
    user_id integer NOT NULL,
    music_id integer NOT NULL,
    rank integer NOT NULL
);
    DROP TABLE public.predictions;
       public         heap    postgres    false                    0    0    TABLE predictions    ACL     7   GRANT ALL ON TABLE public.predictions TO ballmer_peak;
          public          postgres    false    245         ï            1259    50960    test    TABLE     J   CREATE TABLE public.test (
    message character varying(100) NOT NULL
);
    DROP TABLE public.test;
       public         heap    postgres    false                    0    0 
   TABLE test    ACL     0   GRANT ALL ON TABLE public.test TO ballmer_peak;
          public          postgres    false    239         ó            1259    50972    ticket    TABLE        CREATE TABLE public.ticket (
    id integer NOT NULL,
    user_id integer NOT NULL,
    concert_id integer NOT NULL,
    purchase_date date
);
    DROP TABLE public.ticket;
       public         heap    postgres    false                    0    0    TABLE ticket    ACL     2   GRANT ALL ON TABLE public.ticket TO ballmer_peak;
          public          postgres    false    243         ò            1259    50971    ticket_id_seq    SEQUENCE        CREATE SEQUENCE public.ticket_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.ticket_id_seq;
       public          postgres    false    243                    0    0    ticket_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.ticket_id_seq OWNED BY public.ticket.id;
          public          postgres    false    242                    0    0    SEQUENCE ticket_id_seq    ACL     <   GRANT ALL ON SEQUENCE public.ticket_id_seq TO ballmer_peak;
          public          postgres    false    242         ñ            1259    50964    users    TABLE       CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(100),
    email character varying(100),
    birthdate date,
    address character varying(100),
    has_membership boolean DEFAULT false,
    money bigint DEFAULT 0,
    is_singer boolean DEFAULT false,
    password character varying(260),
    image_url character varying(200),
    CONSTRAINT money_check CHECK ((money >= 0))
);
    DROP TABLE public.users;
       public         heap    postgres    false                    0    0    TABLE users    ACL     C   GRANT ALL ON TABLE public.users TO ballmer_peak WITH GRANT OPTION;
          public          postgres    false    241         ð            1259    50963    users_id_seq    SEQUENCE        CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.users_id_seq;
       public          postgres    false    241                     0    0    users_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
          public          postgres    false    240         ¡           0    0    SEQUENCE users_id_seq    ACL     ;   GRANT ALL ON SEQUENCE public.users_id_seq TO ballmer_peak;
          public          postgres    false    240                    2604    51514    pga_exception jexid    DEFAULT     |   ALTER TABLE ONLY pgagent.pga_exception ALTER COLUMN jexid SET DEFAULT nextval('pgagent.pga_exception_jexid_seq'::regclass);
 C   ALTER TABLE pgagent.pga_exception ALTER COLUMN jexid DROP DEFAULT;
       pgagent          postgres    false    257    258    258         ù           2604    51438    pga_job jobid    DEFAULT     p   ALTER TABLE ONLY pgagent.pga_job ALTER COLUMN jobid SET DEFAULT nextval('pgagent.pga_job_jobid_seq'::regclass);
 =   ALTER TABLE pgagent.pga_job ALTER COLUMN jobid DROP DEFAULT;
       pgagent          postgres    false    251    252    252         ø           2604    51428    pga_jobclass jclid    DEFAULT     z   ALTER TABLE ONLY pgagent.pga_jobclass ALTER COLUMN jclid SET DEFAULT nextval('pgagent.pga_jobclass_jclid_seq'::regclass);
 B   ALTER TABLE pgagent.pga_jobclass ALTER COLUMN jclid DROP DEFAULT;
       pgagent          postgres    false    249    250    250                    2604    51528    pga_joblog jlgid    DEFAULT     v   ALTER TABLE ONLY pgagent.pga_joblog ALTER COLUMN jlgid SET DEFAULT nextval('pgagent.pga_joblog_jlgid_seq'::regclass);
 @   ALTER TABLE pgagent.pga_joblog ALTER COLUMN jlgid DROP DEFAULT;
       pgagent          postgres    false    260    259    260         ÿ           2604    51462    pga_jobstep jstid    DEFAULT     x   ALTER TABLE ONLY pgagent.pga_jobstep ALTER COLUMN jstid SET DEFAULT nextval('pgagent.pga_jobstep_jstid_seq'::regclass);
 A   ALTER TABLE pgagent.pga_jobstep ALTER COLUMN jstid DROP DEFAULT;
       pgagent          postgres    false    254    253    254                    2604    51544    pga_jobsteplog jslid    DEFAULT     ~   ALTER TABLE ONLY pgagent.pga_jobsteplog ALTER COLUMN jslid SET DEFAULT nextval('pgagent.pga_jobsteplog_jslid_seq'::regclass);
 D   ALTER TABLE pgagent.pga_jobsteplog ALTER COLUMN jslid DROP DEFAULT;
       pgagent          postgres    false    262    261    262                    2604    51486    pga_schedule jscid    DEFAULT     z   ALTER TABLE ONLY pgagent.pga_schedule ALTER COLUMN jscid SET DEFAULT nextval('pgagent.pga_schedule_jscid_seq'::regclass);
 B   ALTER TABLE pgagent.pga_schedule ALTER COLUMN jscid DROP DEFAULT;
       pgagent          postgres    false    255    256    256         Þ           2604    50884    albumcomments id    DEFAULT     s   ALTER TABLE ONLY public.albumcomments ALTER COLUMN id SET DEFAULT nextval('public.albumcomment_id_seq'::regclass);
 ?   ALTER TABLE public.albumcomments ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    216    217    217         à           2604    50891 	   albums id    DEFAULT     f   ALTER TABLE ONLY public.albums ALTER COLUMN id SET DEFAULT nextval('public.albums_id_seq'::regclass);
 8   ALTER TABLE public.albums ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    219    219         á           2604    50896    concerts id    DEFAULT     j   ALTER TABLE ONLY public.concerts ALTER COLUMN id SET DEFAULT nextval('public.concerts_id_seq'::regclass);
 :   ALTER TABLE public.concerts ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    221    220    221         ã           2604    50902    favoritemusics id    DEFAULT     v   ALTER TABLE ONLY public.favoritemusics ALTER COLUMN id SET DEFAULT nextval('public.favoritemusics_id_seq'::regclass);
 @   ALTER TABLE public.favoritemusics ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    223    222    223         ä           2604    50907    favoriteplaylists id    DEFAULT     |   ALTER TABLE ONLY public.favoriteplaylists ALTER COLUMN id SET DEFAULT nextval('public.favoriteplaylists_id_seq'::regclass);
 C   ALTER TABLE public.favoriteplaylists ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    224    225    225         õ           2604    51221    messages id    DEFAULT     j   ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);
 :   ALTER TABLE public.messages ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    246    247    247         æ           2604    50919    musiccomments id    DEFAULT     t   ALTER TABLE ONLY public.musiccomments ALTER COLUMN id SET DEFAULT nextval('public.musiccomments_id_seq'::regclass);
 ?   ALTER TABLE public.musiccomments ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    229    228    229         è           2604    50931 	   musics id    DEFAULT     f   ALTER TABLE ONLY public.musics ALTER COLUMN id SET DEFAULT nextval('public.musics_id_seq'::regclass);
 8   ALTER TABLE public.musics ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    231    232    232         ì           2604    50941    playlistcomments id    DEFAULT     z   ALTER TABLE ONLY public.playlistcomments ALTER COLUMN id SET DEFAULT nextval('public.playlistcomments_id_seq'::regclass);
 B   ALTER TABLE public.playlistcomments ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    234    233    234         î           2604    50958    playlists id    DEFAULT     l   ALTER TABLE ONLY public.playlists ALTER COLUMN id SET DEFAULT nextval('public.playlists_id_seq'::regclass);
 ;   ALTER TABLE public.playlists ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    237    238    238         ô           2604    50975 	   ticket id    DEFAULT     f   ALTER TABLE ONLY public.ticket ALTER COLUMN id SET DEFAULT nextval('public.ticket_id_seq'::regclass);
 8   ALTER TABLE public.ticket ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    242    243    243         ð           2604    50967    users id    DEFAULT     d   ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
 7   ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    241    240    241         P          0    51511    pga_exception 
   TABLE DATA           J   COPY pgagent.pga_exception (jexid, jexscid, jexdate, jextime) FROM stdin;
    pgagent          postgres    false    258       5200.dat J          0    51435    pga_job 
   TABLE DATA              COPY pgagent.pga_job (jobid, jobjclid, jobname, jobdesc, jobhostagent, jobenabled, jobcreated, jobchanged, jobagentid, jobnextrun, joblastrun) FROM stdin;
    pgagent          postgres    false    252       5194.dat F          0    51416    pga_jobagent 
   TABLE DATA           I   COPY pgagent.pga_jobagent (jagpid, jaglogintime, jagstation) FROM stdin;
    pgagent          postgres    false    248       5190.dat H          0    51425    pga_jobclass 
   TABLE DATA           7   COPY pgagent.pga_jobclass (jclid, jclname) FROM stdin;
    pgagent          postgres    false    250       5192.dat R          0    51525 
   pga_joblog 
   TABLE DATA           X   COPY pgagent.pga_joblog (jlgid, jlgjobid, jlgstatus, jlgstart, jlgduration) FROM stdin;
    pgagent          postgres    false    260       5202.dat L          0    51459    pga_jobstep 
   TABLE DATA              COPY pgagent.pga_jobstep (jstid, jstjobid, jstname, jstdesc, jstenabled, jstkind, jstcode, jstconnstr, jstdbname, jstonerror, jscnextrun) FROM stdin;
    pgagent          postgres    false    254       5196.dat T          0    51541    pga_jobsteplog 
   TABLE DATA           |   COPY pgagent.pga_jobsteplog (jslid, jsljlgid, jsljstid, jslstatus, jslresult, jslstart, jslduration, jsloutput) FROM stdin;
    pgagent          postgres    false    262       5204.dat N          0    51483    pga_schedule 
   TABLE DATA           ¤   COPY pgagent.pga_schedule (jscid, jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths) FROM stdin;
    pgagent          postgres    false    256       5198.dat '          0    50881    albumcomments 
   TABLE DATA           L   COPY public.albumcomments (id, album_id, user_id, text, "time") FROM stdin;
    public          postgres    false    217       5159.dat :          0    50950 
   albumlikes 
   TABLE DATA           7   COPY public.albumlikes (album_id, user_id) FROM stdin;
    public          postgres    false    236       5178.dat )          0    50888    albums 
   TABLE DATA           5   COPY public.albums (id, singer_id, name) FROM stdin;
    public          postgres    false    219       5161.dat +          0    50893    concerts 
   TABLE DATA           M   COPY public.concerts (id, singer_id, price, date, has_suspended) FROM stdin;
    public          postgres    false    221       5163.dat -          0    50899    favoritemusics 
   TABLE DATA           ?   COPY public.favoritemusics (id, music_id, user_id) FROM stdin;
    public          postgres    false    223       5165.dat /          0    50904    favoriteplaylists 
   TABLE DATA           E   COPY public.favoriteplaylists (id, playlist_id, user_id) FROM stdin;
    public          postgres    false    225       5167.dat 0          0    50908 	   followers 
   TABLE DATA           9   COPY public.followers (follower_id, user_id) FROM stdin;
    public          postgres    false    226       5168.dat 1          0    50911    friendrequests 
   TABLE DATA           J   COPY public.friendrequests (sender_id, reciever_id, accepted) FROM stdin;
    public          postgres    false    227       5169.dat E          0    51218    messages 
   TABLE DATA           L   COPY public.messages (id, sender_id, reciever_id, text, "time") FROM stdin;
    public          postgres    false    247       5189.dat 3          0    50916    musiccomments 
   TABLE DATA           L   COPY public.musiccomments (id, music_id, user_id, text, "time") FROM stdin;
    public          postgres    false    229       5171.dat 4          0    50923 
   musiclikes 
   TABLE DATA           7   COPY public.musiclikes (music_id, user_id) FROM stdin;
    public          postgres    false    230       5172.dat 6          0    50928    musics 
   TABLE DATA           v   COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text, audio_url) FROM stdin;
    public          postgres    false    232       5174.dat B          0    51147    playlist_music 
   TABLE DATA           ?   COPY public.playlist_music (music_id, playlist_id) FROM stdin;
    public          postgres    false    244       5186.dat 8          0    50938    playlistcomments 
   TABLE DATA           R   COPY public.playlistcomments (id, playlist_id, user_id, text, "time") FROM stdin;
    public          postgres    false    234       5176.dat 9          0    50945    playlistlikes 
   TABLE DATA           =   COPY public.playlistlikes (playlist_id, user_id) FROM stdin;
    public          postgres    false    235       5177.dat <          0    50955 	   playlists 
   TABLE DATA           B   COPY public.playlists (id, owner_id, is_public, name) FROM stdin;
    public          postgres    false    238       5180.dat C          0    51169    predictions 
   TABLE DATA           >   COPY public.predictions (user_id, music_id, rank) FROM stdin;
    public          postgres    false    245       5187.dat =          0    50960    test 
   TABLE DATA           '   COPY public.test (message) FROM stdin;
    public          postgres    false    239       5181.dat A          0    50972    ticket 
   TABLE DATA           H   COPY public.ticket (id, user_id, concert_id, purchase_date) FROM stdin;
    public          postgres    false    243       5185.dat ?          0    50964    users 
   TABLE DATA              COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password, image_url) FROM stdin;
    public          postgres    false    241       5183.dat ¢           0    0    pga_exception_jexid_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('pgagent.pga_exception_jexid_seq', 1, false);
          pgagent          postgres    false    257         £           0    0    pga_job_jobid_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('pgagent.pga_job_jobid_seq', 2, true);
          pgagent          postgres    false    251         ¤           0    0    pga_jobclass_jclid_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('pgagent.pga_jobclass_jclid_seq', 5, true);
          pgagent          postgres    false    249         ¥           0    0    pga_joblog_jlgid_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('pgagent.pga_joblog_jlgid_seq', 1, false);
          pgagent          postgres    false    259         ¦           0    0    pga_jobstep_jstid_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('pgagent.pga_jobstep_jstid_seq', 1, false);
          pgagent          postgres    false    253         §           0    0    pga_jobsteplog_jslid_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('pgagent.pga_jobsteplog_jslid_seq', 1, false);
          pgagent          postgres    false    261         ¨           0    0    pga_schedule_jscid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('pgagent.pga_schedule_jscid_seq', 1, false);
          pgagent          postgres    false    255         ©           0    0    albumcomment_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.albumcomment_id_seq', 1, false);
          public          postgres    false    216         ª           0    0    albums_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.albums_id_seq', 8, true);
          public          postgres    false    218         «           0    0    concerts_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.concerts_id_seq', 4, true);
          public          postgres    false    220         ¬           0    0    favoritemusics_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.favoritemusics_id_seq', 1, false);
          public          postgres    false    222         ­           0    0    favoriteplaylists_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.favoriteplaylists_id_seq', 1, false);
          public          postgres    false    224         ®           0    0    messages_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.messages_id_seq', 7, true);
          public          postgres    false    246         ¯           0    0    musiccomments_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.musiccomments_id_seq', 8, true);
          public          postgres    false    228         °           0    0    musics_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.musics_id_seq', 1, false);
          public          postgres    false    231         ±           0    0    playlistcomments_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.playlistcomments_id_seq', 1, false);
          public          postgres    false    233         ²           0    0    playlists_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.playlists_id_seq', 11, true);
          public          postgres    false    237         ³           0    0    ticket_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.ticket_id_seq', 10, true);
          public          postgres    false    242         ´           0    0    users_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.users_id_seq', 31, true);
          public          postgres    false    240         a           2606    51516     pga_exception pga_exception_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY pgagent.pga_exception
    ADD CONSTRAINT pga_exception_pkey PRIMARY KEY (jexid);
 K   ALTER TABLE ONLY pgagent.pga_exception DROP CONSTRAINT pga_exception_pkey;
       pgagent            postgres    false    258         W           2606    51447    pga_job pga_job_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY pgagent.pga_job
    ADD CONSTRAINT pga_job_pkey PRIMARY KEY (jobid);
 ?   ALTER TABLE ONLY pgagent.pga_job DROP CONSTRAINT pga_job_pkey;
       pgagent            postgres    false    252         R           2606    51423    pga_jobagent pga_jobagent_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY pgagent.pga_jobagent
    ADD CONSTRAINT pga_jobagent_pkey PRIMARY KEY (jagpid);
 I   ALTER TABLE ONLY pgagent.pga_jobagent DROP CONSTRAINT pga_jobagent_pkey;
       pgagent            postgres    false    248         U           2606    51432    pga_jobclass pga_jobclass_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY pgagent.pga_jobclass
    ADD CONSTRAINT pga_jobclass_pkey PRIMARY KEY (jclid);
 I   ALTER TABLE ONLY pgagent.pga_jobclass DROP CONSTRAINT pga_jobclass_pkey;
       pgagent            postgres    false    250         d           2606    51533    pga_joblog pga_joblog_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY pgagent.pga_joblog
    ADD CONSTRAINT pga_joblog_pkey PRIMARY KEY (jlgid);
 E   ALTER TABLE ONLY pgagent.pga_joblog DROP CONSTRAINT pga_joblog_pkey;
       pgagent            postgres    false    260         Z           2606    51475    pga_jobstep pga_jobstep_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY pgagent.pga_jobstep
    ADD CONSTRAINT pga_jobstep_pkey PRIMARY KEY (jstid);
 G   ALTER TABLE ONLY pgagent.pga_jobstep DROP CONSTRAINT pga_jobstep_pkey;
       pgagent            postgres    false    254         g           2606    51551 "   pga_jobsteplog pga_jobsteplog_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY pgagent.pga_jobsteplog
    ADD CONSTRAINT pga_jobsteplog_pkey PRIMARY KEY (jslid);
 M   ALTER TABLE ONLY pgagent.pga_jobsteplog DROP CONSTRAINT pga_jobsteplog_pkey;
       pgagent            postgres    false    262         ]           2606    51503    pga_schedule pga_schedule_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY pgagent.pga_schedule
    ADD CONSTRAINT pga_schedule_pkey PRIMARY KEY (jscid);
 I   ALTER TABLE ONLY pgagent.pga_schedule DROP CONSTRAINT pga_schedule_pkey;
       pgagent            postgres    false    256         "           2606    50977    albumcomments albumcomment_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY public.albumcomments DROP CONSTRAINT albumcomment_pkey;
       public            postgres    false    217         $           2606    50981    albums albums_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.albums DROP CONSTRAINT albums_pkey;
       public            postgres    false    219         (           2606    50983    concerts concert_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY public.concerts DROP CONSTRAINT concert_pkey;
       public            postgres    false    221         *           2606    50985 "   favoritemusics favoritemusics_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.favoritemusics DROP CONSTRAINT favoritemusics_pkey;
       public            postgres    false    223         ,           2606    50987 (   favoriteplaylists favoriteplaylists_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.favoriteplaylists DROP CONSTRAINT favoriteplaylists_pkey;
       public            postgres    false    225         .           2606    50989    followers followers_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (user_id, follower_id);
 B   ALTER TABLE ONLY public.followers DROP CONSTRAINT followers_pkey;
       public            postgres    false    226    226         0           2606    50991 "   friendrequests friendrequests_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_pkey PRIMARY KEY (sender_id, reciever_id);
 L   ALTER TABLE ONLY public.friendrequests DROP CONSTRAINT friendrequests_pkey;
       public            postgres    false    227    227         P           2606    51225    messages messages_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_pkey;
       public            postgres    false    247         2           2606    50993     musiccomments musiccomments_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_pkey;
       public            postgres    false    229         6           2606    50997    musics musics_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.musics DROP CONSTRAINT musics_pkey;
       public            postgres    false    232         4           2606    51202    musiclikes pk 
   CONSTRAINT     Z   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT pk PRIMARY KEY (user_id, music_id);
 7   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT pk;
       public            postgres    false    230    230         <           2606    51204    albumlikes pk2 
   CONSTRAINT     [   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT pk2 PRIMARY KEY (album_id, user_id);
 8   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT pk2;
       public            postgres    false    236    236         :           2606    51206    playlistlikes pk_playlistlikes 
   CONSTRAINT     n   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT pk_playlistlikes PRIMARY KEY (playlist_id, user_id);
 H   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT pk_playlistlikes;
       public            postgres    false    235    235         L           2606    51151 "   playlist_music playlist_music_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_pkey PRIMARY KEY (music_id, playlist_id);
 L   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_pkey;
       public            postgres    false    244    244         8           2606    50999 &   playlistcomments playlistcomments_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_pkey;
       public            postgres    false    234         >           2606    51003    playlists playlists_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.playlists DROP CONSTRAINT playlists_pkey;
       public            postgres    false    238         N           2606    51173    predictions predictions_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_pkey PRIMARY KEY (user_id, music_id, rank);
 F   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_pkey;
       public            postgres    false    245    245    245         B           2606    51005    test test_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (message);
 8   ALTER TABLE ONLY public.test DROP CONSTRAINT test_pkey;
       public            postgres    false    239         J           2606    51007    ticket ticket_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_pkey;
       public            postgres    false    243         D           2606    51146    users unique_email 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_email UNIQUE (email);
 <   ALTER TABLE ONLY public.users DROP CONSTRAINT unique_email;
       public            postgres    false    241         &           2606    51191    albums unique_name 
   CONSTRAINT     M   ALTER TABLE ONLY public.albums
    ADD CONSTRAINT unique_name UNIQUE (name);
 <   ALTER TABLE ONLY public.albums DROP CONSTRAINT unique_name;
       public            postgres    false    219         @           2606    51187 #   playlists unique_name_for_each_user 
   CONSTRAINT     h   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT unique_name_for_each_user UNIQUE (owner_id, name);
 M   ALTER TABLE ONLY public.playlists DROP CONSTRAINT unique_name_for_each_user;
       public            postgres    false    238    238         F           2606    51144    users unique_username 
   CONSTRAINT     T   ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_username UNIQUE (username);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT unique_username;
       public            postgres    false    241         H           2606    51009    users users_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    241         ^           1259    51523    pga_exception_datetime    INDEX     d   CREATE UNIQUE INDEX pga_exception_datetime ON pgagent.pga_exception USING btree (jexdate, jextime);
 +   DROP INDEX pgagent.pga_exception_datetime;
       pgagent            postgres    false    258    258         _           1259    51522    pga_exception_jexscid    INDEX     S   CREATE INDEX pga_exception_jexscid ON pgagent.pga_exception USING btree (jexscid);
 *   DROP INDEX pgagent.pga_exception_jexscid;
       pgagent            postgres    false    258         S           1259    51433    pga_jobclass_name    INDEX     U   CREATE UNIQUE INDEX pga_jobclass_name ON pgagent.pga_jobclass USING btree (jclname);
 &   DROP INDEX pgagent.pga_jobclass_name;
       pgagent            postgres    false    250         b           1259    51539    pga_joblog_jobid    INDEX     L   CREATE INDEX pga_joblog_jobid ON pgagent.pga_joblog USING btree (jlgjobid);
 %   DROP INDEX pgagent.pga_joblog_jobid;
       pgagent            postgres    false    260         [           1259    51509    pga_jobschedule_jobid    INDEX     S   CREATE INDEX pga_jobschedule_jobid ON pgagent.pga_schedule USING btree (jscjobid);
 *   DROP INDEX pgagent.pga_jobschedule_jobid;
       pgagent            postgres    false    256         X           1259    51481    pga_jobstep_jobid    INDEX     N   CREATE INDEX pga_jobstep_jobid ON pgagent.pga_jobstep USING btree (jstjobid);
 &   DROP INDEX pgagent.pga_jobstep_jobid;
       pgagent            postgres    false    254         e           1259    51562    pga_jobsteplog_jslid    INDEX     T   CREATE INDEX pga_jobsteplog_jslid ON pgagent.pga_jobsteplog USING btree (jsljlgid);
 )   DROP INDEX pgagent.pga_jobsteplog_jslid;
       pgagent            postgres    false    262                    2620    51572 #   pga_exception pga_exception_trigger    TRIGGER        CREATE TRIGGER pga_exception_trigger AFTER INSERT OR DELETE OR UPDATE ON pgagent.pga_exception FOR EACH ROW EXECUTE FUNCTION pgagent.pga_exception_trigger();
 =   DROP TRIGGER pga_exception_trigger ON pgagent.pga_exception;
       pgagent          postgres    false    258    285         µ           0    0 .   TRIGGER pga_exception_trigger ON pga_exception    COMMENT        COMMENT ON TRIGGER pga_exception_trigger ON pgagent.pga_exception IS 'Update the job''s next run time whenever an exception changes';
          pgagent          postgres    false    5014                    2620    51568    pga_job pga_job_trigger    TRIGGER     y   CREATE TRIGGER pga_job_trigger BEFORE UPDATE ON pgagent.pga_job FOR EACH ROW EXECUTE FUNCTION pgagent.pga_job_trigger();
 1   DROP TRIGGER pga_job_trigger ON pgagent.pga_job;
       pgagent          postgres    false    283    252         ¶           0    0 "   TRIGGER pga_job_trigger ON pga_job    COMMENT     ]   COMMENT ON TRIGGER pga_job_trigger ON pgagent.pga_job IS 'Update the job''s next run time.';
          pgagent          postgres    false    5012                    2620    51570 !   pga_schedule pga_schedule_trigger    TRIGGER        CREATE TRIGGER pga_schedule_trigger AFTER INSERT OR DELETE OR UPDATE ON pgagent.pga_schedule FOR EACH ROW EXECUTE FUNCTION pgagent.pga_schedule_trigger();
 ;   DROP TRIGGER pga_schedule_trigger ON pgagent.pga_schedule;
       pgagent          postgres    false    256    284         ·           0    0 ,   TRIGGER pga_schedule_trigger ON pga_schedule    COMMENT        COMMENT ON TRIGGER pga_schedule_trigger ON pgagent.pga_schedule IS 'Update the job''s next run time whenever a schedule changes';
          pgagent          postgres    false    5013                    2620    51248    concerts get_back_money    TRIGGER     ~   CREATE TRIGGER get_back_money AFTER UPDATE ON public.concerts FOR EACH ROW EXECUTE FUNCTION public.get_back_money_function();
 0   DROP TRIGGER get_back_money ON public.concerts;
       public          postgres    false    279    221                    2620    51250    ticket get_money    TRIGGER     s   CREATE TRIGGER get_money BEFORE INSERT ON public.ticket FOR EACH ROW EXECUTE FUNCTION public.get_money_function();
 )   DROP TRIGGER get_money ON public.ticket;
       public          postgres    false    243    282                    2620    51243 '   musiccomments notify_comment_to_friends    TRIGGER        CREATE TRIGGER notify_comment_to_friends AFTER INSERT ON public.musiccomments FOR EACH ROW EXECUTE FUNCTION public.notify_comment();
 @   DROP TRIGGER notify_comment_to_friends ON public.musiccomments;
       public          postgres    false    229    288                    2620    51245 $   musiclikes notify_comment_to_friends    TRIGGER        CREATE TRIGGER notify_comment_to_friends AFTER INSERT ON public.musiclikes FOR EACH ROW EXECUTE FUNCTION public.notify_like();
 =   DROP TRIGGER notify_comment_to_friends ON public.musiclikes;
       public          postgres    false    287    230                    2606    51517 (   pga_exception pga_exception_jexscid_fkey    FK CONSTRAINT     ¸   ALTER TABLE ONLY pgagent.pga_exception
    ADD CONSTRAINT pga_exception_jexscid_fkey FOREIGN KEY (jexscid) REFERENCES pgagent.pga_schedule(jscid) ON UPDATE RESTRICT ON DELETE CASCADE;
 S   ALTER TABLE ONLY pgagent.pga_exception DROP CONSTRAINT pga_exception_jexscid_fkey;
       pgagent          postgres    false    4957    258    256                    2606    51453    pga_job pga_job_jobagentid_fkey    FK CONSTRAINT     ´   ALTER TABLE ONLY pgagent.pga_job
    ADD CONSTRAINT pga_job_jobagentid_fkey FOREIGN KEY (jobagentid) REFERENCES pgagent.pga_jobagent(jagpid) ON UPDATE RESTRICT ON DELETE SET NULL;
 J   ALTER TABLE ONLY pgagent.pga_job DROP CONSTRAINT pga_job_jobagentid_fkey;
       pgagent          postgres    false    248    4946    252                    2606    51448    pga_job pga_job_jobjclid_fkey    FK CONSTRAINT     ¯   ALTER TABLE ONLY pgagent.pga_job
    ADD CONSTRAINT pga_job_jobjclid_fkey FOREIGN KEY (jobjclid) REFERENCES pgagent.pga_jobclass(jclid) ON UPDATE RESTRICT ON DELETE RESTRICT;
 H   ALTER TABLE ONLY pgagent.pga_job DROP CONSTRAINT pga_job_jobjclid_fkey;
       pgagent          postgres    false    252    250    4949                    2606    51534 #   pga_joblog pga_joblog_jlgjobid_fkey    FK CONSTRAINT     ¯   ALTER TABLE ONLY pgagent.pga_joblog
    ADD CONSTRAINT pga_joblog_jlgjobid_fkey FOREIGN KEY (jlgjobid) REFERENCES pgagent.pga_job(jobid) ON UPDATE RESTRICT ON DELETE CASCADE;
 N   ALTER TABLE ONLY pgagent.pga_joblog DROP CONSTRAINT pga_joblog_jlgjobid_fkey;
       pgagent          postgres    false    252    260    4951                    2606    51476 %   pga_jobstep pga_jobstep_jstjobid_fkey    FK CONSTRAINT     ±   ALTER TABLE ONLY pgagent.pga_jobstep
    ADD CONSTRAINT pga_jobstep_jstjobid_fkey FOREIGN KEY (jstjobid) REFERENCES pgagent.pga_job(jobid) ON UPDATE RESTRICT ON DELETE CASCADE;
 P   ALTER TABLE ONLY pgagent.pga_jobstep DROP CONSTRAINT pga_jobstep_jstjobid_fkey;
       pgagent          postgres    false    254    252    4951                    2606    51552 +   pga_jobsteplog pga_jobsteplog_jsljlgid_fkey    FK CONSTRAINT     º   ALTER TABLE ONLY pgagent.pga_jobsteplog
    ADD CONSTRAINT pga_jobsteplog_jsljlgid_fkey FOREIGN KEY (jsljlgid) REFERENCES pgagent.pga_joblog(jlgid) ON UPDATE RESTRICT ON DELETE CASCADE;
 V   ALTER TABLE ONLY pgagent.pga_jobsteplog DROP CONSTRAINT pga_jobsteplog_jsljlgid_fkey;
       pgagent          postgres    false    260    262    4964                    2606    51557 +   pga_jobsteplog pga_jobsteplog_jsljstid_fkey    FK CONSTRAINT     »   ALTER TABLE ONLY pgagent.pga_jobsteplog
    ADD CONSTRAINT pga_jobsteplog_jsljstid_fkey FOREIGN KEY (jsljstid) REFERENCES pgagent.pga_jobstep(jstid) ON UPDATE RESTRICT ON DELETE CASCADE;
 V   ALTER TABLE ONLY pgagent.pga_jobsteplog DROP CONSTRAINT pga_jobsteplog_jsljstid_fkey;
       pgagent          postgres    false    4954    262    254                    2606    51504 '   pga_schedule pga_schedule_jscjobid_fkey    FK CONSTRAINT     ³   ALTER TABLE ONLY pgagent.pga_schedule
    ADD CONSTRAINT pga_schedule_jscjobid_fkey FOREIGN KEY (jscjobid) REFERENCES pgagent.pga_job(jobid) ON UPDATE RESTRICT ON DELETE CASCADE;
 R   ALTER TABLE ONLY pgagent.pga_schedule DROP CONSTRAINT pga_schedule_jscjobid_fkey;
       pgagent          postgres    false    252    256    4951         h           2606    51010 (   albumcomments albumcomment_album_id_fkey    FK CONSTRAINT     ­   ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.albumcomments DROP CONSTRAINT albumcomment_album_id_fkey;
       public          postgres    false    217    4900    219         i           2606    51015 '   albumcomments albumcomment_user_id_fkey    FK CONSTRAINT     ª   ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.albumcomments DROP CONSTRAINT albumcomment_user_id_fkey;
       public          postgres    false    241    217    4936         }           2606    51020 #   albumlikes albumlikes_album_id_fkey    FK CONSTRAINT     ¨   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 M   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT albumlikes_album_id_fkey;
       public          postgres    false    219    236    4900         ~           2606    51025 "   albumlikes albumlikes_user_id_fkey    FK CONSTRAINT     ¥   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 L   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT albumlikes_user_id_fkey;
       public          postgres    false    4936    236    241         j           2606    51030    albums albums_singer_id_fkey    FK CONSTRAINT     ¡   ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.albums DROP CONSTRAINT albums_singer_id_fkey;
       public          postgres    false    4936    219    241         k           2606    51035    concerts concert_singer_id_fkey    FK CONSTRAINT     ¤   ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 I   ALTER TABLE ONLY public.concerts DROP CONSTRAINT concert_singer_id_fkey;
       public          postgres    false    4936    221    241         l           2606    51040 +   favoritemusics favoritemusics_music_id_fkey    FK CONSTRAINT     °   ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.favoritemusics DROP CONSTRAINT favoritemusics_music_id_fkey;
       public          postgres    false    4918    223    232         m           2606    51045 *   favoritemusics favoritemusics_user_id_fkey    FK CONSTRAINT     ­   ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 T   ALTER TABLE ONLY public.favoritemusics DROP CONSTRAINT favoritemusics_user_id_fkey;
       public          postgres    false    223    4936    241         n           2606    51050 4   favoriteplaylists favoriteplaylists_playlist_id_fkey    FK CONSTRAINT     ¿   ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 ^   ALTER TABLE ONLY public.favoriteplaylists DROP CONSTRAINT favoriteplaylists_playlist_id_fkey;
       public          postgres    false    238    225    4926         o           2606    51055 0   favoriteplaylists favoriteplaylists_user_id_fkey    FK CONSTRAINT     ³   ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.favoriteplaylists DROP CONSTRAINT favoriteplaylists_user_id_fkey;
       public          postgres    false    241    4936    225         p           2606    51060 $   followers followers_follower_id_fkey    FK CONSTRAINT     «   ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.followers DROP CONSTRAINT followers_follower_id_fkey;
       public          postgres    false    241    226    4936         q           2606    51065     followers followers_user_id_fkey    FK CONSTRAINT     £   ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 J   ALTER TABLE ONLY public.followers DROP CONSTRAINT followers_user_id_fkey;
       public          postgres    false    226    4936    241         r           2606    51070 .   friendrequests friendrequests_reciever_id_fkey    FK CONSTRAINT     µ   ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.friendrequests DROP CONSTRAINT friendrequests_reciever_id_fkey;
       public          postgres    false    227    241    4936         s           2606    51075 ,   friendrequests friendrequests_sender_id_fkey    FK CONSTRAINT     ±   ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.friendrequests DROP CONSTRAINT friendrequests_sender_id_fkey;
       public          postgres    false    241    4936    227                    2606    51231 "   messages messages_reciever_id_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id);
 L   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_reciever_id_fkey;
       public          postgres    false    247    241    4936                    2606    51226     messages messages_sender_id_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);
 J   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_sender_id_fkey;
       public          postgres    false    247    4936    241         t           2606    51080 )   musiccomments musiccomments_music_id_fkey    FK CONSTRAINT     ®   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_music_id_fkey;
       public          postgres    false    229    232    4918         u           2606    51085 (   musiccomments musiccomments_user_id_fkey    FK CONSTRAINT     «   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_user_id_fkey;
       public          postgres    false    4936    241    229         v           2606    51090 $   musiclikes musicllikes_music_id_fkey    FK CONSTRAINT     ©   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT musicllikes_music_id_fkey;
       public          postgres    false    4918    232    230         w           2606    51095 #   musiclikes musicllikes_user_id_fkey    FK CONSTRAINT     ¦   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 M   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT musicllikes_user_id_fkey;
       public          postgres    false    241    4936    230         x           2606    51100    musics musics_album_id_fkey    FK CONSTRAINT         ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.musics DROP CONSTRAINT musics_album_id_fkey;
       public          postgres    false    232    219    4900                    2606    51152 +   playlist_music playlist_music_music_id_fkey    FK CONSTRAINT     °   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_music_id_fkey;
       public          postgres    false    4918    244    232                    2606    51157 .   playlist_music playlist_music_playlist_id_fkey    FK CONSTRAINT     ¹   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_playlist_id_fkey;
       public          postgres    false    244    4926    238         y           2606    51105 2   playlistcomments playlistcomments_playlist_id_fkey    FK CONSTRAINT     ½   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 \   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_playlist_id_fkey;
       public          postgres    false    234    238    4926         z           2606    51110 .   playlistcomments playlistcomments_user_id_fkey    FK CONSTRAINT     ±   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_user_id_fkey;
       public          postgres    false    241    234    4936         {           2606    51115 +   playlistlikes playlistlike_playlist_id_fkey    FK CONSTRAINT     ¶   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT playlistlike_playlist_id_fkey;
       public          postgres    false    4926    235    238         |           2606    51120 '   playlistlikes playlistlike_user_id_fkey    FK CONSTRAINT     ª   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT playlistlike_user_id_fkey;
       public          postgres    false    235    4936    241                    2606    51125 !   playlists playlists_owner_id_fkey    FK CONSTRAINT     ¥   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.playlists DROP CONSTRAINT playlists_owner_id_fkey;
       public          postgres    false    4936    241    238                    2606    51179 %   predictions predictions_music_id_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id);
 O   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_music_id_fkey;
       public          postgres    false    4918    245    232                    2606    51174 $   predictions predictions_user_id_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
 N   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_user_id_fkey;
       public          postgres    false    241    4936    245                    2606    51130    ticket ticket_concert_id_fkey    FK CONSTRAINT     ¦   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_concert_id_fkey FOREIGN KEY (concert_id) REFERENCES public.concerts(id) ON UPDATE CASCADE ON DELETE CASCADE;
 G   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_concert_id_fkey;
       public          postgres    false    243    221    4904                    2606    51135    ticket ticket_user_id_fkey    FK CONSTRAINT        ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_user_id_fkey;
       public          postgres    false    241    243    4936                                                                                                                                                                                                                                                                                                                                                                                                                                                              5200.dat                                                                                            0000600 0004000 0002000 00000000005 14644346411 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5194.dat                                                                                            0000600 0004000 0002000 00000000005 14644346411 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5190.dat                                                                                            0000600 0004000 0002000 00000000005 14644346411 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5192.dat                                                                                            0000600 0004000 0002000 00000000134 14644346411 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	Routine Maintenance
2	Data Import
3	Data Export
4	Data Summarisation
5	Miscellaneous
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                    5202.dat                                                                                            0000600 0004000 0002000 00000000005 14644346411 0014244 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5196.dat                                                                                            0000600 0004000 0002000 00000000005 14644346411 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5204.dat                                                                                            0000600 0004000 0002000 00000000005 14644346411 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5198.dat                                                                                            0000600 0004000 0002000 00000000005 14644346411 0014262 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5159.dat                                                                                            0000600 0004000 0002000 00000000135 14644346411 0014263 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Great album!	2024-07-12 00:47:49.867549
2	2	2	Not bad.	2024-07-12 00:47:49.867549
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                   5178.dat                                                                                            0000600 0004000 0002000 00000000022 14644346411 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	2
2	22
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              5161.dat                                                                                            0000600 0004000 0002000 00000000066 14644346411 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	Album A
2	2	Album B
6	22	some alb1
8	22	name
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                          5163.dat                                                                                            0000600 0004000 0002000 00000000135 14644346411 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	1000	2023-01-01	f
2	2	2000	2023-02-01	t
4	22	100	2003-10-10	f
3	22	100	2003-10-10	t
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                   5165.dat                                                                                            0000600 0004000 0002000 00000000027 14644346411 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
2	2	2
3	1	2
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         5167.dat                                                                                            0000600 0004000 0002000 00000000013 14644346411 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     5168.dat                                                                                            0000600 0004000 0002000 00000000027 14644346411 0014263 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2
2	1
22	3
3	22
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         5169.dat                                                                                            0000600 0004000 0002000 00000000031 14644346411 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	f
22	2	t
22	3	f
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       5189.dat                                                                                            0000600 0004000 0002000 00000000746 14644346411 0014276 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	22	3	3	2024-07-12 15:56:23.280546
2	22	3	3	2024-07-12 15:56:36.658916
3	22	3	salam daash	2024-07-12 16:02:59.52322
4	22	2	commented on a music by User One	2024-07-12 19:55:22.306985
5	22	2	<p style="opacity:60%"> commented on a music by User One</p>	2024-07-12 19:56:33.391058
6	22	2	<p style="opacity:60%">â¤ï¸ liked music by User Oneâ¤ï¸</p>	2024-07-12 20:00:07.92187
7	22	2	<p style="opacity:60%">â¤ï¸ liked music Song A by User Oneâ¤ï¸</p>	2024-07-12 20:03:22.111754
\.


                          5171.dat                                                                                            0000600 0004000 0002000 00000000413 14644346411 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Love this song!	2024-07-12 00:47:21.696607
2	2	2	Nice track.	2024-07-12 00:47:21.696607
3	1	22	some text	2024-07-11 21:34:40.217333
4	1	22	some text	2024-07-11 21:34:42.538641
7	1	22	salam	2024-07-12 19:55:22.306985
8	1	22	salam	2024-07-12 19:56:33.391058
\.


                                                                                                                                                                                                                                                     5172.dat                                                                                            0000600 0004000 0002000 00000000034 14644346411 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	2
1	22
6	22
5	22
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    5174.dat                                                                                            0000600 0004000 0002000 00000002061 14644346411 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	Song A	Pop	All	/path/to/image1.jpg	t	Lyrics for Song A	\N
2	2	Song B	Rock	18+	/path/to/image2.jpg	f	Lyrics for Song B	\N
4	1	some music	Pop	13to18	/path/	t	some text	\N
6	1	name	Pop	13to19	\N	f	some text	\N
7	1	name	Pop	13to19	\N	f	some text	\N
8	1	name	Pop	13to19	\N	f	some text	\N
9	1	name	Pop	13to19	\N	f	some text	\N
10	1	name	Pop	13to19	\N	f	some text	\N
11	1	name	Pop	13to19	\N	f	some text	\N
12	1	name	Pop	13to19	\N	f	some text	\N
13	1	name	Pop	13to19	\N	f	some text	\N
14	1	name	Pop	13to19	\N	f	some text	\N
15	1	name	Pop	13to19	\N	f	some text	\N
16	1	dwde	wde	wdewd	\N	t	wedew	\N
5	1	name	Pop	13to19	/path	f	some text	\N
17	1	name	Pop	someage	\N	t	some text	\N
18	1	name	Pop	someage	\N	t	some text	\N
19	1	name	Pop	someage	\N	t	some text	\N
20	1	name	Pop	someage	\N	t	some text	\N
21	1	name	Pop	someage	\N	t	some text	\N
22	1	name	Pop	someage	\N	t	some text	\N
23	1	name	Pop	someage	musics\\23.png	t	some text	audios\\23.png
24	1	name	Pop	someage	musics\\24.png	t	some text	audios\\24.png
25	1	name	Pop	someage	/musics\\25.png	t	some text	/audios\\25.png
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                               5186.dat                                                                                            0000600 0004000 0002000 00000000027 14644346411 0014263 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	1
2	10
1	11
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         5176.dat                                                                                            0000600 0004000 0002000 00000000066 14644346411 0014265 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Great playlist!	2024-07-12 00:48:50.507124
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                          5177.dat                                                                                            0000600 0004000 0002000 00000000016 14644346411 0014261 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
1	22
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  5180.dat                                                                                            0000600 0004000 0002000 00000000125 14644346411 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	t	name1\n
6	22	t	name3
8	1	t	name3
9	22	t	None
10	22	t	name
11	22	t	iwniwde
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                           5187.dat                                                                                            0000600 0004000 0002000 00000000121 14644346411 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        2	1	1
2	2	2
2	5	3
2	6	4
1	1	1
1	2	2
1	5	3
1	6	4
22	1	1
22	2	2
22	5	3
22	6	4
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                               5181.dat                                                                                            0000600 0004000 0002000 00000000005 14644346411 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5185.dat                                                                                            0000600 0004000 0002000 00000000032 14644346411 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	22	1	\N
10	22	3	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      5183.dat                                                                                            0000600 0004000 0002000 00000004204 14644346411 0014261 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        26	sa1alam21111	salam@1salamq.com21111	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	.png is not expected
27	sa1alam211111	salam@1salamq.com211111	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	.png is not expected
12	salam2222	test@test2.com222	2003-04-09	some adr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	\N
2	User One	user1@example.com	1990-01-01	123 Main St	t	1100	f	\N	\N
13	salam	salam@salam.com	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	\N
19	salam2	salam@salam.com2	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	\N
21	saalam2	salam@salamq.com2	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	\N
1	ErfanG	e.geramizadeh13821359@gmail.com	2003-04-09	some addrr	t	100	f	0582bd2c13fff71d7f40ef5586e3f4da05a3a61fe5ba9f0b4d06e99905ab83ea	\N
23	sa1alam21	salam@1salamq.com21	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	musics\\23.png
24	sa1alam211	salam@1salamq.com211	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	musics\\24.png
25	sa1alam2111	salam@1salamq.com2111	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	images\\25.png
28	sa1alam2111111	salam@1salamq.com2111111	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	.png is not expected
29	sa1alam2111112	salam@1salamq.com2111112	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	.png is not expected
30	sa1alam2111113	salam@1salamq.com2111113	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	images\\30.png
31	sa1ala1m2	salam@1sala1mq.com2	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	\N
3	User Two	user2@example.com	1985-05-15	456 Elm St	f	1100	t	\N	\N
22	sa1alam2	salam@1salamq.com2	2003-02-02	addr	t	1001	t	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                            restore.sql                                                                                         0000600 0004000 0002000 00000261000 14644346411 0015372 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE ballmer_peak;
--
-- Name: ballmer_peak; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE ballmer_peak WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';


ALTER DATABASE ballmer_peak OWNER TO postgres;

\connect ballmer_peak

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgagent; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pgagent;


ALTER SCHEMA pgagent OWNER TO postgres;

--
-- Name: SCHEMA pgagent; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA pgagent IS 'pgAgent system tables';


--
-- Name: pga_exception_trigger(); Type: FUNCTION; Schema: pgagent; Owner: postgres
--

CREATE FUNCTION pgagent.pga_exception_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE

    v_jobid int4 := 0;

BEGIN

     IF TG_OP = 'DELETE' THEN

        SELECT INTO v_jobid jscjobid FROM pgagent.pga_schedule WHERE jscid = OLD.jexscid;

        -- update pga_job from remaining schedules
        -- the actual calculation of jobnextrun will be performed in the trigger
        UPDATE pgagent.pga_job
           SET jobnextrun = NULL
         WHERE jobenabled AND jobid = v_jobid;
        RETURN OLD;
    ELSE

        SELECT INTO v_jobid jscjobid FROM pgagent.pga_schedule WHERE jscid = NEW.jexscid;

        UPDATE pgagent.pga_job
           SET jobnextrun = NULL
         WHERE jobenabled AND jobid = v_jobid;
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION pgagent.pga_exception_trigger() OWNER TO postgres;

--
-- Name: FUNCTION pga_exception_trigger(); Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON FUNCTION pgagent.pga_exception_trigger() IS 'Update the job''s next run time whenever an exception changes';


--
-- Name: pga_is_leap_year(smallint); Type: FUNCTION; Schema: pgagent; Owner: postgres
--

CREATE FUNCTION pgagent.pga_is_leap_year(smallint) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
BEGIN
    IF $1 % 4 != 0 THEN
        RETURN FALSE;
    END IF;

    IF $1 % 100 != 0 THEN
        RETURN TRUE;
    END IF;

    RETURN $1 % 400 = 0;
END;
$_$;


ALTER FUNCTION pgagent.pga_is_leap_year(smallint) OWNER TO postgres;

--
-- Name: FUNCTION pga_is_leap_year(smallint); Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON FUNCTION pgagent.pga_is_leap_year(smallint) IS 'Returns TRUE if $1 is a leap year';


--
-- Name: pga_job_trigger(); Type: FUNCTION; Schema: pgagent; Owner: postgres
--

CREATE FUNCTION pgagent.pga_job_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.jobenabled THEN
        IF NEW.jobnextrun IS NULL THEN
             SELECT INTO NEW.jobnextrun
                    MIN(pgagent.pga_next_schedule(jscid, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths))
               FROM pgagent.pga_schedule
              WHERE jscenabled AND jscjobid=OLD.jobid;
        END IF;
    ELSE
        NEW.jobnextrun := NULL;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION pgagent.pga_job_trigger() OWNER TO postgres;

--
-- Name: FUNCTION pga_job_trigger(); Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON FUNCTION pgagent.pga_job_trigger() IS 'Update the job''s next run time.';


--
-- Name: pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[]); Type: FUNCTION; Schema: pgagent; Owner: postgres
--

CREATE FUNCTION pgagent.pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[]) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $_$
DECLARE
    jscid           ALIAS FOR $1;
    jscstart        ALIAS FOR $2;
    jscend          ALIAS FOR $3;
    jscminutes      ALIAS FOR $4;
    jschours        ALIAS FOR $5;
    jscweekdays     ALIAS FOR $6;
    jscmonthdays    ALIAS FOR $7;
    jscmonths       ALIAS FOR $8;

    nextrun         timestamp := '1970-01-01 00:00:00-00';
    runafter        timestamp := '1970-01-01 00:00:00-00';

    bingo            bool := FALSE;
    gotit            bool := FALSE;
    foundval        bool := FALSE;
    daytweak        bool := FALSE;
    minutetweak        bool := FALSE;

    i                int2 := 0;
    d                int2 := 0;

    nextminute        int2 := 0;
    nexthour        int2 := 0;
    nextday            int2 := 0;
    nextmonth       int2 := 0;
    nextyear        int2 := 0;


BEGIN
    -- No valid start date has been specified
    IF jscstart IS NULL THEN RETURN NULL; END IF;

    -- The schedule is past its end date
    IF jscend IS NOT NULL AND jscend < now() THEN RETURN NULL; END IF;

    -- Get the time to find the next run after. It will just be the later of
    -- now() + 1m and the start date for the time being, however, we might want to
    -- do more complex things using this value in the future.
    IF date_trunc('MINUTE', jscstart) > date_trunc('MINUTE', (now() + '1 Minute'::interval)) THEN
        runafter := date_trunc('MINUTE', jscstart);
    ELSE
        runafter := date_trunc('MINUTE', (now() + '1 Minute'::interval));
    END IF;

    --
    -- Enter a loop, generating next run timestamps until we find one
    -- that falls on the required weekday, and is not matched by an exception
    --

    WHILE bingo = FALSE LOOP

        --
        -- Get the next run year
        --
        nextyear := date_part('YEAR', runafter);

        --
        -- Get the next run month
        --
        nextmonth := date_part('MONTH', runafter);
        gotit := FALSE;
        FOR i IN (nextmonth) .. 12 LOOP
            IF jscmonths[i] = TRUE THEN
                nextmonth := i;
                gotit := TRUE;
                foundval := TRUE;
                EXIT;
            END IF;
        END LOOP;
        IF gotit = FALSE THEN
            FOR i IN 1 .. (nextmonth - 1) LOOP
                IF jscmonths[i] = TRUE THEN
                    nextmonth := i;

                    -- Wrap into next year
                    nextyear := nextyear + 1;
                    gotit := TRUE;
                    foundval := TRUE;
                    EXIT;
                END IF;
           END LOOP;
        END IF;

        --
        -- Get the next run day
        --
        -- If the year, or month have incremented, get the lowest day,
        -- otherwise look for the next day matching or after today.
        IF (nextyear > date_part('YEAR', runafter) OR nextmonth > date_part('MONTH', runafter)) THEN
            nextday := 1;
            FOR i IN 1 .. 32 LOOP
                IF jscmonthdays[i] = TRUE THEN
                    nextday := i;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        ELSE
            nextday := date_part('DAY', runafter);
            gotit := FALSE;
            FOR i IN nextday .. 32 LOOP
                IF jscmonthdays[i] = TRUE THEN
                    nextday := i;
                    gotit := TRUE;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            IF gotit = FALSE THEN
                FOR i IN 1 .. (nextday - 1) LOOP
                    IF jscmonthdays[i] = TRUE THEN
                        nextday := i;

                        -- Wrap into next month
                        IF nextmonth = 12 THEN
                            nextyear := nextyear + 1;
                            nextmonth := 1;
                        ELSE
                            nextmonth := nextmonth + 1;
                        END IF;
                        gotit := TRUE;
                        foundval := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END IF;

        -- Was the last day flag selected?
        IF nextday = 32 THEN
            IF nextmonth = 1 THEN
                nextday := 31;
            ELSIF nextmonth = 2 THEN
                IF pgagent.pga_is_leap_year(nextyear) = TRUE THEN
                    nextday := 29;
                ELSE
                    nextday := 28;
                END IF;
            ELSIF nextmonth = 3 THEN
                nextday := 31;
            ELSIF nextmonth = 4 THEN
                nextday := 30;
            ELSIF nextmonth = 5 THEN
                nextday := 31;
            ELSIF nextmonth = 6 THEN
                nextday := 30;
            ELSIF nextmonth = 7 THEN
                nextday := 31;
            ELSIF nextmonth = 8 THEN
                nextday := 31;
            ELSIF nextmonth = 9 THEN
                nextday := 30;
            ELSIF nextmonth = 10 THEN
                nextday := 31;
            ELSIF nextmonth = 11 THEN
                nextday := 30;
            ELSIF nextmonth = 12 THEN
                nextday := 31;
            END IF;
        END IF;

        --
        -- Get the next run hour
        --
        -- If the year, month or day have incremented, get the lowest hour,
        -- otherwise look for the next hour matching or after the current one.
        IF (nextyear > date_part('YEAR', runafter) OR nextmonth > date_part('MONTH', runafter) OR nextday > date_part('DAY', runafter) OR daytweak = TRUE) THEN
            nexthour := 0;
            FOR i IN 1 .. 24 LOOP
                IF jschours[i] = TRUE THEN
                    nexthour := i - 1;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        ELSE
            nexthour := date_part('HOUR', runafter);
            gotit := FALSE;
            FOR i IN (nexthour + 1) .. 24 LOOP
                IF jschours[i] = TRUE THEN
                    nexthour := i - 1;
                    gotit := TRUE;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            IF gotit = FALSE THEN
                FOR i IN 1 .. nexthour LOOP
                    IF jschours[i] = TRUE THEN
                        nexthour := i - 1;

                        -- Wrap into next month
                        IF (nextmonth = 1 OR nextmonth = 3 OR nextmonth = 5 OR nextmonth = 7 OR nextmonth = 8 OR nextmonth = 10 OR nextmonth = 12) THEN
                            d = 31;
                        ELSIF (nextmonth = 4 OR nextmonth = 6 OR nextmonth = 9 OR nextmonth = 11) THEN
                            d = 30;
                        ELSE
                            IF pgagent.pga_is_leap_year(nextyear) = TRUE THEN
                                d := 29;
                            ELSE
                                d := 28;
                            END IF;
                        END IF;

                        IF nextday = d THEN
                            nextday := 1;
                            IF nextmonth = 12 THEN
                                nextyear := nextyear + 1;
                                nextmonth := 1;
                            ELSE
                                nextmonth := nextmonth + 1;
                            END IF;
                        ELSE
                            nextday := nextday + 1;
                        END IF;

                        gotit := TRUE;
                        foundval := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END IF;

        --
        -- Get the next run minute
        --
        -- If the year, month day or hour have incremented, get the lowest minute,
        -- otherwise look for the next minute matching or after the current one.
        IF (nextyear > date_part('YEAR', runafter) OR nextmonth > date_part('MONTH', runafter) OR nextday > date_part('DAY', runafter) OR nexthour > date_part('HOUR', runafter) OR daytweak = TRUE) THEN
            nextminute := 0;
            IF minutetweak = TRUE THEN
        d := 1;
            ELSE
        d := date_part('MINUTE', runafter)::int2;
            END IF;
            FOR i IN d .. 60 LOOP
                IF jscminutes[i] = TRUE THEN
                    nextminute := i - 1;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        ELSE
            nextminute := date_part('MINUTE', runafter);
            gotit := FALSE;
            FOR i IN (nextminute + 1) .. 60 LOOP
                IF jscminutes[i] = TRUE THEN
                    nextminute := i - 1;
                    gotit := TRUE;
                    foundval := TRUE;
                    EXIT;
                END IF;
            END LOOP;
            IF gotit = FALSE THEN
                FOR i IN 1 .. nextminute LOOP
                    IF jscminutes[i] = TRUE THEN
                        nextminute := i - 1;

                        -- Wrap into next hour
                        IF (nextmonth = 1 OR nextmonth = 3 OR nextmonth = 5 OR nextmonth = 7 OR nextmonth = 8 OR nextmonth = 10 OR nextmonth = 12) THEN
                            d = 31;
                        ELSIF (nextmonth = 4 OR nextmonth = 6 OR nextmonth = 9 OR nextmonth = 11) THEN
                            d = 30;
                        ELSE
                            IF pgagent.pga_is_leap_year(nextyear) = TRUE THEN
                                d := 29;
                            ELSE
                                d := 28;
                            END IF;
                        END IF;

                        IF nexthour = 23 THEN
                            nexthour = 0;
                            IF nextday = d THEN
                                nextday := 1;
                                IF nextmonth = 12 THEN
                                    nextyear := nextyear + 1;
                                    nextmonth := 1;
                                ELSE
                                    nextmonth := nextmonth + 1;
                                END IF;
                            ELSE
                                nextday := nextday + 1;
                            END IF;
                        ELSE
                            nexthour := nexthour + 1;
                        END IF;

                        gotit := TRUE;
                        foundval := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END IF;

        -- Build the result, and check it is not the same as runafter - this may
        -- happen if all array entries are set to false. In this case, add a minute.

        nextrun := (nextyear::varchar || '-'::varchar || nextmonth::varchar || '-' || nextday::varchar || ' ' || nexthour::varchar || ':' || nextminute::varchar)::timestamptz;

        IF nextrun = runafter AND foundval = FALSE THEN
                nextrun := nextrun + INTERVAL '1 Minute';
        END IF;

        -- If the result is past the end date, exit.
        IF nextrun > jscend THEN
            RETURN NULL;
        END IF;

        -- Check to ensure that the nextrun time is actually still valid. Its
        -- possible that wrapped values may have carried the nextrun onto an
        -- invalid time or date.
        IF ((jscminutes = '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}' OR jscminutes[date_part('MINUTE', nextrun) + 1] = TRUE) AND
            (jschours = '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}' OR jschours[date_part('HOUR', nextrun) + 1] = TRUE) AND
            (jscmonthdays = '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}' OR jscmonthdays[date_part('DAY', nextrun)] = TRUE OR
            (jscmonthdays = '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,t}' AND
             ((date_part('MONTH', nextrun) IN (1,3,5,7,8,10,12) AND date_part('DAY', nextrun) = 31) OR
              (date_part('MONTH', nextrun) IN (4,6,9,11) AND date_part('DAY', nextrun) = 30) OR
              (date_part('MONTH', nextrun) = 2 AND ((pgagent.pga_is_leap_year(date_part('YEAR', nextrun)::int2) AND date_part('DAY', nextrun) = 29) OR date_part('DAY', nextrun) = 28))))) AND
            (jscmonths = '{f,f,f,f,f,f,f,f,f,f,f,f}' OR jscmonths[date_part('MONTH', nextrun)] = TRUE)) THEN


            -- Now, check to see if the nextrun time found is a) on an acceptable
            -- weekday, and b) not matched by an exception. If not, set
            -- runafter = nextrun and try again.

            -- Check for a wildcard weekday
            gotit := FALSE;
            FOR i IN 1 .. 7 LOOP
                IF jscweekdays[i] = TRUE THEN
                    gotit := TRUE;
                    EXIT;
                END IF;
            END LOOP;

            -- OK, is the correct weekday selected, or a wildcard?
            IF (jscweekdays[date_part('DOW', nextrun) + 1] = TRUE OR gotit = FALSE) THEN

                -- Check for exceptions
                SELECT INTO d jexid FROM pgagent.pga_exception WHERE jexscid = jscid AND ((jexdate = nextrun::date AND jextime = nextrun::time) OR (jexdate = nextrun::date AND jextime IS NULL) OR (jexdate IS NULL AND jextime = nextrun::time));
                IF FOUND THEN
                    -- Nuts - found an exception. Increment the time and try again
                    runafter := nextrun + INTERVAL '1 Minute';
                    bingo := FALSE;
                    minutetweak := TRUE;
            daytweak := FALSE;
                ELSE
                    bingo := TRUE;
                END IF;
            ELSE
                -- We're on the wrong week day - increment a day and try again.
                runafter := nextrun + INTERVAL '1 Day';
                bingo := FALSE;
                minutetweak := FALSE;
                daytweak := TRUE;
            END IF;

        ELSE
            runafter := nextrun + INTERVAL '1 Minute';
            bingo := FALSE;
            minutetweak := TRUE;
        daytweak := FALSE;
        END IF;

    END LOOP;

    RETURN nextrun;
END;
$_$;


ALTER FUNCTION pgagent.pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[]) OWNER TO postgres;

--
-- Name: FUNCTION pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[]); Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON FUNCTION pgagent.pga_next_schedule(integer, timestamp with time zone, timestamp with time zone, boolean[], boolean[], boolean[], boolean[], boolean[]) IS 'Calculates the next runtime for a given schedule';


--
-- Name: pga_schedule_trigger(); Type: FUNCTION; Schema: pgagent; Owner: postgres
--

CREATE FUNCTION pgagent.pga_schedule_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        -- update pga_job from remaining schedules
        -- the actual calculation of jobnextrun will be performed in the trigger
        UPDATE pgagent.pga_job
           SET jobnextrun = NULL
         WHERE jobenabled AND jobid=OLD.jscjobid;
        RETURN OLD;
    ELSE
        UPDATE pgagent.pga_job
           SET jobnextrun = NULL
         WHERE jobenabled AND jobid=NEW.jscjobid;
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION pgagent.pga_schedule_trigger() OWNER TO postgres;

--
-- Name: FUNCTION pga_schedule_trigger(); Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON FUNCTION pgagent.pga_schedule_trigger() IS 'Update the job''s next run time whenever a schedule changes';


--
-- Name: pgagent_schema_version(); Type: FUNCTION; Schema: pgagent; Owner: postgres
--

CREATE FUNCTION pgagent.pgagent_schema_version() RETURNS smallint
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- RETURNS PGAGENT MAJOR VERSION
    -- WE WILL CHANGE THE MAJOR VERSION, ONLY IF THERE IS A SCHEMA CHANGE
    RETURN 4;
END;
$$;


ALTER FUNCTION pgagent.pgagent_schema_version() OWNER TO postgres;

--
-- Name: get_back_money_function(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_back_money_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

if(NEW.has_suspended=true and OLD.has_suspended=false) then

update users set money=money+ OLD.price*(select count(*) from ticket where user_id=id and concert_id=OLD.id) where id in (select users.id from users,ticket where ticket.concert_id=OLD.id );


end if;
return NEW;





END;$$;


ALTER FUNCTION public.get_back_money_function() OWNER TO postgres;

--
-- Name: get_interactions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_interactions() RETURNS TABLE(__id integer, _mid integer, _sid integer, _genre character varying, inter bigint)
    LANGUAGE plpgsql
    AS $$begin
return Query(select _id,mid,sid,genre ,sum(interactions)
from((select users.id as _id,music_id as mid,singer_id as sid,genre as genre,2 as interactions
from users,musiclikes,musics,albums
where  users.id=musiclikes.user_id 
and musics.id=musiclikes.music_id
and musics.album_id=albums.id
)
union all
(select users.id as _id,music_id as mid,singer_id as sid,genre as genre,1 as interactions
from users,playlistlikes,playlist_music,musics,albums
where  users.id=playlistlikes.user_id
and playlistlikes.playlist_id=playlist_music.playlist_id
and playlist_music.music_id=musics.id
and musics.album_id=albums.id
)
union all
(
select users.id as _id,music_id as mid,singer_id as sid,genre as genre,4 as interactions
from users,favoritemusics,musics,albums
where  users.id=favoritemusics.user_id 
and musics.id=favoritemusics.music_id
and musics.album_id=albums.id
)
union all 
(
select users.id as _id,music_id as mid,singer_id as sid,genre as genre,1 as interactions
from users,favoriteplaylists,playlist_music,musics,albums
where  users.id=favoriteplaylists.user_id
and favoriteplaylists.playlist_id=playlist_music.playlist_id
and playlist_music.music_id=musics.id
and musics.album_id=albums.id
))group by _id,mid,sid,genre); 

end;$$;


ALTER FUNCTION public.get_interactions() OWNER TO postgres;

--
-- Name: get_money_function(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_money_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN


declare concert_price bigint;
begin
	select price into concert_price from concerts where id=NEW.concert_id;
	
	update users set money=money-concert_price where id=NEW.user_id ;
end;


return NEW;




END;$$;


ALTER FUNCTION public.get_money_function() OWNER TO postgres;

--
-- Name: get_musics_in_playlist(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_musics_in_playlist(_id integer) RETURNS TABLE(id integer, album_id integer, name character varying, genre character varying, rangeage character varying, cover_image_path character varying, can_add_to_playlist boolean, text text)
    LANGUAGE plpgsql
    AS $$
begin

	return Query(
		select musics.id , musics.album_id , musics.name , musics.genre ,musics.rangeage , musics.cover_image_path ,musics.can_add_to_playlist ,musics.text 
		from musics
		join playlists on playlists.id=musics.id
	);

end $$;


ALTER FUNCTION public.get_musics_in_playlist(_id integer) OWNER TO postgres;

--
-- Name: get_predictions(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_predictions(_user_id integer) RETURNS TABLE(image_url character varying, audio_url character varying, name character varying, singer_id integer, id integer, rank integer)
    LANGUAGE plpgsql
    AS $$
begin
return query
with base_predictions as (select musics.image_url,musics.audio_url,musics.name,albums.singer_id,musics.id as _music_id,predictions.rank as music_id from predictions,musics,albums
where predictions.music_id=musics.id and album_id=albums.id and predictions.user_id=_user_id)

 
 select * from(
	 select * from base_predictions
	 union 
	 (select musics.image_url,musics.audio_url,musics.name,albums.singer_id,musics.id,-1 as rank 
	 from musics
	 LEFT JOIN  musiclikes ON musics.id=musiclikes.music_id 
	 JOIN albums ON musics.album_id=albums.id 
	 where musics.id not in(select  _music_id from base_predictions)
	 group by musics.image_url,musics.name,albums.singer_id,musics.id
	 order by count(*))
 ) as combined_result
 order by rank desc
 limit 6;
 
 
end;$$;


ALTER FUNCTION public.get_predictions(_user_id integer) OWNER TO postgres;

--
-- Name: get_singer_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_singer_id(music_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$begin

declare res int;
begin
	select singer_id into res from musics,albums where albums.id=musics.album_id;
	return res;
end;

end$$;


ALTER FUNCTION public.get_singer_id(music_id integer) OWNER TO postgres;

--
-- Name: get_users_playlists(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_users_playlists(user_id integer) RETURNS TABLE(id integer, owner_id integer, is_public boolean, image_url character varying, name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY 
    SELECT 
	
        playlists.id AS id,
        playlists.owner_id AS owner_id,
        playlists.is_public AS is_public,
		
        (
            SELECT musics.image_url
            FROM playlists
            JOIN playlist_music ON playlists.id = playlist_music.playlist_id
            JOIN musics ON musics.id = playlist_music.music_id
            WHERE playlists.id = playlists.id  -- Ensure correct reference
            ORDER BY playlist_music.music_id
            LIMIT 1
        ) AS image_url,playlists.name AS name
    FROM playlists
    WHERE playlists.owner_id = user_id;
END;
$$;


ALTER FUNCTION public.get_users_playlists(user_id integer) OWNER TO postgres;

--
-- Name: notify_comment(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_comment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	declare singer_name varchar(200);
	declare music_name varchar(200);
	begin
		select users.username,musics.name into singer_name,music_name from musics,albums,users where musics.album_id=albums.id and albums.singer_id=users.id and NEW.music_id=musics.id;
		
	    INSERT INTO messages(sender_id,reciever_id,text) 
		(
		(select NEW.user_id,friendrequests.sender_id, '<p style="opacity:60%">ð¬ commented on  music  <strong>' || music_name ||'</strong>ð¬</p>'
		from friendrequests where accepted and reciever_id=NEW.user_id)
		union all 
		(select NEW.user_id,friendrequests.reciever_id, '<p style="opacity:60%">ð¬ commented on  music  <strong>' || music_name ||'</strong>ð¬</p>'
		from friendrequests where accepted and sender_id=NEW.user_id)
		
		);
	    RETURN NEW;
	end;
END;
$$;


ALTER FUNCTION public.notify_comment() OWNER TO postgres;

--
-- Name: notify_like(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_like() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	declare singer_name varchar(200);
	declare musicname varchar(200);
	
	begin
		select users.username  , musics.name into singer_name,musicname from musics,albums,users where musics.album_id=albums.id and albums.singer_id=users.id and NEW.music_id=musics.id;
		
	    INSERT INTO messages(sender_id,reciever_id,text) 
		(
		(select NEW.user_id,friendrequests.sender_id, '<p style="opacity:60%">â¤ï¸ liked music <strong>' || musicname || '</string> by '|| singer_name ||'â¤ï¸</p>'
		from friendrequests where accepted and reciever_id=NEW.user_id)
		union all 
		(select NEW.user_id,friendrequests.reciever_id, '<p style="opacity:60%">â¤ï¸ liked music <strong>' || musicname || '</string> by '|| singer_name ||'â¤ï¸</p>'
		from friendrequests where accepted and sender_id=NEW.user_id)
		
		);
	    RETURN NEW;
	end;
END;
$$;


ALTER FUNCTION public.notify_like() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: pga_exception; Type: TABLE; Schema: pgagent; Owner: postgres
--

CREATE TABLE pgagent.pga_exception (
    jexid integer NOT NULL,
    jexscid integer NOT NULL,
    jexdate date,
    jextime time without time zone
);


ALTER TABLE pgagent.pga_exception OWNER TO postgres;

--
-- Name: pga_exception_jexid_seq; Type: SEQUENCE; Schema: pgagent; Owner: postgres
--

CREATE SEQUENCE pgagent.pga_exception_jexid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pgagent.pga_exception_jexid_seq OWNER TO postgres;

--
-- Name: pga_exception_jexid_seq; Type: SEQUENCE OWNED BY; Schema: pgagent; Owner: postgres
--

ALTER SEQUENCE pgagent.pga_exception_jexid_seq OWNED BY pgagent.pga_exception.jexid;


--
-- Name: pga_job; Type: TABLE; Schema: pgagent; Owner: postgres
--

CREATE TABLE pgagent.pga_job (
    jobid integer NOT NULL,
    jobjclid integer NOT NULL,
    jobname text NOT NULL,
    jobdesc text DEFAULT ''::text NOT NULL,
    jobhostagent text DEFAULT ''::text NOT NULL,
    jobenabled boolean DEFAULT true NOT NULL,
    jobcreated timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jobchanged timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jobagentid integer,
    jobnextrun timestamp with time zone,
    joblastrun timestamp with time zone
);


ALTER TABLE pgagent.pga_job OWNER TO postgres;

--
-- Name: TABLE pga_job; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TABLE pgagent.pga_job IS 'Job main entry';


--
-- Name: COLUMN pga_job.jobagentid; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON COLUMN pgagent.pga_job.jobagentid IS 'Agent that currently executes this job.';


--
-- Name: pga_job_jobid_seq; Type: SEQUENCE; Schema: pgagent; Owner: postgres
--

CREATE SEQUENCE pgagent.pga_job_jobid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pgagent.pga_job_jobid_seq OWNER TO postgres;

--
-- Name: pga_job_jobid_seq; Type: SEQUENCE OWNED BY; Schema: pgagent; Owner: postgres
--

ALTER SEQUENCE pgagent.pga_job_jobid_seq OWNED BY pgagent.pga_job.jobid;


--
-- Name: pga_jobagent; Type: TABLE; Schema: pgagent; Owner: postgres
--

CREATE TABLE pgagent.pga_jobagent (
    jagpid integer NOT NULL,
    jaglogintime timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jagstation text NOT NULL
);


ALTER TABLE pgagent.pga_jobagent OWNER TO postgres;

--
-- Name: TABLE pga_jobagent; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TABLE pgagent.pga_jobagent IS 'Active job agents';


--
-- Name: pga_jobclass; Type: TABLE; Schema: pgagent; Owner: postgres
--

CREATE TABLE pgagent.pga_jobclass (
    jclid integer NOT NULL,
    jclname text NOT NULL
);


ALTER TABLE pgagent.pga_jobclass OWNER TO postgres;

--
-- Name: TABLE pga_jobclass; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TABLE pgagent.pga_jobclass IS 'Job classification';


--
-- Name: pga_jobclass_jclid_seq; Type: SEQUENCE; Schema: pgagent; Owner: postgres
--

CREATE SEQUENCE pgagent.pga_jobclass_jclid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pgagent.pga_jobclass_jclid_seq OWNER TO postgres;

--
-- Name: pga_jobclass_jclid_seq; Type: SEQUENCE OWNED BY; Schema: pgagent; Owner: postgres
--

ALTER SEQUENCE pgagent.pga_jobclass_jclid_seq OWNED BY pgagent.pga_jobclass.jclid;


--
-- Name: pga_joblog; Type: TABLE; Schema: pgagent; Owner: postgres
--

CREATE TABLE pgagent.pga_joblog (
    jlgid integer NOT NULL,
    jlgjobid integer NOT NULL,
    jlgstatus character(1) DEFAULT 'r'::bpchar NOT NULL,
    jlgstart timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jlgduration interval,
    CONSTRAINT pga_joblog_jlgstatus_check CHECK ((jlgstatus = ANY (ARRAY['r'::bpchar, 's'::bpchar, 'f'::bpchar, 'i'::bpchar, 'd'::bpchar])))
);


ALTER TABLE pgagent.pga_joblog OWNER TO postgres;

--
-- Name: TABLE pga_joblog; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TABLE pgagent.pga_joblog IS 'Job run logs.';


--
-- Name: COLUMN pga_joblog.jlgstatus; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON COLUMN pgagent.pga_joblog.jlgstatus IS 'Status of job: r=running, s=successfully finished, f=failed, i=no steps to execute, d=aborted';


--
-- Name: pga_joblog_jlgid_seq; Type: SEQUENCE; Schema: pgagent; Owner: postgres
--

CREATE SEQUENCE pgagent.pga_joblog_jlgid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pgagent.pga_joblog_jlgid_seq OWNER TO postgres;

--
-- Name: pga_joblog_jlgid_seq; Type: SEQUENCE OWNED BY; Schema: pgagent; Owner: postgres
--

ALTER SEQUENCE pgagent.pga_joblog_jlgid_seq OWNED BY pgagent.pga_joblog.jlgid;


--
-- Name: pga_jobstep; Type: TABLE; Schema: pgagent; Owner: postgres
--

CREATE TABLE pgagent.pga_jobstep (
    jstid integer NOT NULL,
    jstjobid integer NOT NULL,
    jstname text NOT NULL,
    jstdesc text DEFAULT ''::text NOT NULL,
    jstenabled boolean DEFAULT true NOT NULL,
    jstkind character(1) NOT NULL,
    jstcode text NOT NULL,
    jstconnstr text DEFAULT ''::text NOT NULL,
    jstdbname name DEFAULT ''::name NOT NULL,
    jstonerror character(1) DEFAULT 'f'::bpchar NOT NULL,
    jscnextrun timestamp with time zone,
    CONSTRAINT pga_jobstep_check CHECK ((((jstconnstr <> ''::text) AND (jstkind = 's'::bpchar)) OR ((jstconnstr = ''::text) AND ((jstkind = 'b'::bpchar) OR (jstdbname <> ''::name))))),
    CONSTRAINT pga_jobstep_check1 CHECK ((((jstdbname <> ''::name) AND (jstkind = 's'::bpchar)) OR ((jstdbname = ''::name) AND ((jstkind = 'b'::bpchar) OR (jstconnstr <> ''::text))))),
    CONSTRAINT pga_jobstep_jstkind_check CHECK ((jstkind = ANY (ARRAY['b'::bpchar, 's'::bpchar]))),
    CONSTRAINT pga_jobstep_jstonerror_check CHECK ((jstonerror = ANY (ARRAY['f'::bpchar, 's'::bpchar, 'i'::bpchar])))
);


ALTER TABLE pgagent.pga_jobstep OWNER TO postgres;

--
-- Name: TABLE pga_jobstep; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TABLE pgagent.pga_jobstep IS 'Job step to be executed';


--
-- Name: COLUMN pga_jobstep.jstkind; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON COLUMN pgagent.pga_jobstep.jstkind IS 'Kind of jobstep: s=sql, b=batch';


--
-- Name: COLUMN pga_jobstep.jstonerror; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON COLUMN pgagent.pga_jobstep.jstonerror IS 'What to do if step returns an error: f=fail the job, s=mark step as succeeded and continue, i=mark as fail but ignore it and proceed';


--
-- Name: pga_jobstep_jstid_seq; Type: SEQUENCE; Schema: pgagent; Owner: postgres
--

CREATE SEQUENCE pgagent.pga_jobstep_jstid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pgagent.pga_jobstep_jstid_seq OWNER TO postgres;

--
-- Name: pga_jobstep_jstid_seq; Type: SEQUENCE OWNED BY; Schema: pgagent; Owner: postgres
--

ALTER SEQUENCE pgagent.pga_jobstep_jstid_seq OWNED BY pgagent.pga_jobstep.jstid;


--
-- Name: pga_jobsteplog; Type: TABLE; Schema: pgagent; Owner: postgres
--

CREATE TABLE pgagent.pga_jobsteplog (
    jslid integer NOT NULL,
    jsljlgid integer NOT NULL,
    jsljstid integer NOT NULL,
    jslstatus character(1) DEFAULT 'r'::bpchar NOT NULL,
    jslresult integer,
    jslstart timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jslduration interval,
    jsloutput text,
    CONSTRAINT pga_jobsteplog_jslstatus_check CHECK ((jslstatus = ANY (ARRAY['r'::bpchar, 's'::bpchar, 'i'::bpchar, 'f'::bpchar, 'd'::bpchar])))
);


ALTER TABLE pgagent.pga_jobsteplog OWNER TO postgres;

--
-- Name: TABLE pga_jobsteplog; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TABLE pgagent.pga_jobsteplog IS 'Job step run logs.';


--
-- Name: COLUMN pga_jobsteplog.jslstatus; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON COLUMN pgagent.pga_jobsteplog.jslstatus IS 'Status of job step: r=running, s=successfully finished,  f=failed stopping job, i=ignored failure, d=aborted';


--
-- Name: COLUMN pga_jobsteplog.jslresult; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON COLUMN pgagent.pga_jobsteplog.jslresult IS 'Return code of job step';


--
-- Name: pga_jobsteplog_jslid_seq; Type: SEQUENCE; Schema: pgagent; Owner: postgres
--

CREATE SEQUENCE pgagent.pga_jobsteplog_jslid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pgagent.pga_jobsteplog_jslid_seq OWNER TO postgres;

--
-- Name: pga_jobsteplog_jslid_seq; Type: SEQUENCE OWNED BY; Schema: pgagent; Owner: postgres
--

ALTER SEQUENCE pgagent.pga_jobsteplog_jslid_seq OWNED BY pgagent.pga_jobsteplog.jslid;


--
-- Name: pga_schedule; Type: TABLE; Schema: pgagent; Owner: postgres
--

CREATE TABLE pgagent.pga_schedule (
    jscid integer NOT NULL,
    jscjobid integer NOT NULL,
    jscname text NOT NULL,
    jscdesc text DEFAULT ''::text NOT NULL,
    jscenabled boolean DEFAULT true NOT NULL,
    jscstart timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    jscend timestamp with time zone,
    jscminutes boolean[] DEFAULT '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    jschours boolean[] DEFAULT '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    jscweekdays boolean[] DEFAULT '{f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    jscmonthdays boolean[] DEFAULT '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    jscmonths boolean[] DEFAULT '{f,f,f,f,f,f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    CONSTRAINT pga_schedule_jschours_size CHECK ((array_upper(jschours, 1) = 24)),
    CONSTRAINT pga_schedule_jscminutes_size CHECK ((array_upper(jscminutes, 1) = 60)),
    CONSTRAINT pga_schedule_jscmonthdays_size CHECK ((array_upper(jscmonthdays, 1) = 32)),
    CONSTRAINT pga_schedule_jscmonths_size CHECK ((array_upper(jscmonths, 1) = 12)),
    CONSTRAINT pga_schedule_jscweekdays_size CHECK ((array_upper(jscweekdays, 1) = 7))
);


ALTER TABLE pgagent.pga_schedule OWNER TO postgres;

--
-- Name: TABLE pga_schedule; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TABLE pgagent.pga_schedule IS 'Job schedule exceptions';


--
-- Name: pga_schedule_jscid_seq; Type: SEQUENCE; Schema: pgagent; Owner: postgres
--

CREATE SEQUENCE pgagent.pga_schedule_jscid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pgagent.pga_schedule_jscid_seq OWNER TO postgres;

--
-- Name: pga_schedule_jscid_seq; Type: SEQUENCE OWNED BY; Schema: pgagent; Owner: postgres
--

ALTER SEQUENCE pgagent.pga_schedule_jscid_seq OWNED BY pgagent.pga_schedule.jscid;


--
-- Name: albumcomments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albumcomments (
    id integer NOT NULL,
    album_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.albumcomments OWNER TO postgres;

--
-- Name: albumcomment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.albumcomment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.albumcomment_id_seq OWNER TO postgres;

--
-- Name: albumcomment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.albumcomment_id_seq OWNED BY public.albumcomments.id;


--
-- Name: albumlikes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albumlikes (
    album_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.albumlikes OWNER TO postgres;

--
-- Name: albums; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albums (
    id integer NOT NULL,
    singer_id integer,
    name character varying(100)
);


ALTER TABLE public.albums OWNER TO postgres;

--
-- Name: albums_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.albums_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.albums_id_seq OWNER TO postgres;

--
-- Name: albums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.albums_id_seq OWNED BY public.albums.id;


--
-- Name: concerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.concerts (
    id integer NOT NULL,
    singer_id integer,
    price bigint,
    date date,
    has_suspended boolean DEFAULT false
);


ALTER TABLE public.concerts OWNER TO postgres;

--
-- Name: concerts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.concerts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.concerts_id_seq OWNER TO postgres;

--
-- Name: concerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.concerts_id_seq OWNED BY public.concerts.id;


--
-- Name: favoritemusics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favoritemusics (
    id integer NOT NULL,
    music_id integer,
    user_id integer
);


ALTER TABLE public.favoritemusics OWNER TO postgres;

--
-- Name: favoritemusics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.favoritemusics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.favoritemusics_id_seq OWNER TO postgres;

--
-- Name: favoritemusics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favoritemusics_id_seq OWNED BY public.favoritemusics.id;


--
-- Name: favoriteplaylists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favoriteplaylists (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer
);


ALTER TABLE public.favoriteplaylists OWNER TO postgres;

--
-- Name: favoriteplaylists_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.favoriteplaylists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.favoriteplaylists_id_seq OWNER TO postgres;

--
-- Name: favoriteplaylists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favoriteplaylists_id_seq OWNED BY public.favoriteplaylists.id;


--
-- Name: followers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.followers (
    follower_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.followers OWNER TO postgres;

--
-- Name: friendrequests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friendrequests (
    sender_id integer NOT NULL,
    reciever_id integer NOT NULL,
    accepted boolean DEFAULT false
);


ALTER TABLE public.friendrequests OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    sender_id integer,
    reciever_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO postgres;

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: musiccomments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.musiccomments (
    id integer NOT NULL,
    music_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.musiccomments OWNER TO postgres;

--
-- Name: musiccomments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.musiccomments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.musiccomments_id_seq OWNER TO postgres;

--
-- Name: musiccomments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musiccomments_id_seq OWNED BY public.musiccomments.id;


--
-- Name: musiclikes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.musiclikes (
    music_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.musiclikes OWNER TO postgres;

--
-- Name: musics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.musics (
    id integer NOT NULL,
    album_id integer,
    name character varying(100),
    genre character varying(100),
    rangeage character varying(100),
    image_url character varying(200) DEFAULT NULL::character varying,
    can_add_to_playlist boolean DEFAULT false,
    text text DEFAULT ''::text,
    audio_url character varying(200)
);


ALTER TABLE public.musics OWNER TO postgres;

--
-- Name: musics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.musics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.musics_id_seq OWNER TO postgres;

--
-- Name: musics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musics_id_seq OWNED BY public.musics.id;


--
-- Name: playlist_music; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.playlist_music (
    music_id integer NOT NULL,
    playlist_id integer NOT NULL
);


ALTER TABLE public.playlist_music OWNER TO postgres;

--
-- Name: playlistcomments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.playlistcomments (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.playlistcomments OWNER TO postgres;

--
-- Name: playlistcomments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.playlistcomments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.playlistcomments_id_seq OWNER TO postgres;

--
-- Name: playlistcomments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.playlistcomments_id_seq OWNED BY public.playlistcomments.id;


--
-- Name: playlistlikes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.playlistlikes (
    playlist_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.playlistlikes OWNER TO postgres;

--
-- Name: playlists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.playlists (
    id integer NOT NULL,
    owner_id integer,
    is_public boolean DEFAULT true,
    name character varying(100)
);


ALTER TABLE public.playlists OWNER TO postgres;

--
-- Name: playlists_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.playlists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.playlists_id_seq OWNER TO postgres;

--
-- Name: playlists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.playlists_id_seq OWNED BY public.playlists.id;


--
-- Name: predictions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.predictions (
    user_id integer NOT NULL,
    music_id integer NOT NULL,
    rank integer NOT NULL
);


ALTER TABLE public.predictions OWNER TO postgres;

--
-- Name: test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test (
    message character varying(100) NOT NULL
);


ALTER TABLE public.test OWNER TO postgres;

--
-- Name: ticket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ticket (
    id integer NOT NULL,
    user_id integer NOT NULL,
    concert_id integer NOT NULL,
    purchase_date date
);


ALTER TABLE public.ticket OWNER TO postgres;

--
-- Name: ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ticket_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ticket_id_seq OWNER TO postgres;

--
-- Name: ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ticket_id_seq OWNED BY public.ticket.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(100),
    email character varying(100),
    birthdate date,
    address character varying(100),
    has_membership boolean DEFAULT false,
    money bigint DEFAULT 0,
    is_singer boolean DEFAULT false,
    password character varying(260),
    image_url character varying(200),
    CONSTRAINT money_check CHECK ((money >= 0))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: pga_exception jexid; Type: DEFAULT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_exception ALTER COLUMN jexid SET DEFAULT nextval('pgagent.pga_exception_jexid_seq'::regclass);


--
-- Name: pga_job jobid; Type: DEFAULT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_job ALTER COLUMN jobid SET DEFAULT nextval('pgagent.pga_job_jobid_seq'::regclass);


--
-- Name: pga_jobclass jclid; Type: DEFAULT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobclass ALTER COLUMN jclid SET DEFAULT nextval('pgagent.pga_jobclass_jclid_seq'::regclass);


--
-- Name: pga_joblog jlgid; Type: DEFAULT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_joblog ALTER COLUMN jlgid SET DEFAULT nextval('pgagent.pga_joblog_jlgid_seq'::regclass);


--
-- Name: pga_jobstep jstid; Type: DEFAULT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobstep ALTER COLUMN jstid SET DEFAULT nextval('pgagent.pga_jobstep_jstid_seq'::regclass);


--
-- Name: pga_jobsteplog jslid; Type: DEFAULT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobsteplog ALTER COLUMN jslid SET DEFAULT nextval('pgagent.pga_jobsteplog_jslid_seq'::regclass);


--
-- Name: pga_schedule jscid; Type: DEFAULT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_schedule ALTER COLUMN jscid SET DEFAULT nextval('pgagent.pga_schedule_jscid_seq'::regclass);


--
-- Name: albumcomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomments ALTER COLUMN id SET DEFAULT nextval('public.albumcomment_id_seq'::regclass);


--
-- Name: albums id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums ALTER COLUMN id SET DEFAULT nextval('public.albums_id_seq'::regclass);


--
-- Name: concerts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts ALTER COLUMN id SET DEFAULT nextval('public.concerts_id_seq'::regclass);


--
-- Name: favoritemusics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics ALTER COLUMN id SET DEFAULT nextval('public.favoritemusics_id_seq'::regclass);


--
-- Name: favoriteplaylists id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists ALTER COLUMN id SET DEFAULT nextval('public.favoriteplaylists_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: musiccomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments ALTER COLUMN id SET DEFAULT nextval('public.musiccomments_id_seq'::regclass);


--
-- Name: musics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics ALTER COLUMN id SET DEFAULT nextval('public.musics_id_seq'::regclass);


--
-- Name: playlistcomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments ALTER COLUMN id SET DEFAULT nextval('public.playlistcomments_id_seq'::regclass);


--
-- Name: playlists id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists ALTER COLUMN id SET DEFAULT nextval('public.playlists_id_seq'::regclass);


--
-- Name: ticket id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket ALTER COLUMN id SET DEFAULT nextval('public.ticket_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: pga_exception; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_exception (jexid, jexscid, jexdate, jextime) FROM stdin;
\.
COPY pgagent.pga_exception (jexid, jexscid, jexdate, jextime) FROM '$$PATH$$/5200.dat';

--
-- Data for Name: pga_job; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_job (jobid, jobjclid, jobname, jobdesc, jobhostagent, jobenabled, jobcreated, jobchanged, jobagentid, jobnextrun, joblastrun) FROM stdin;
\.
COPY pgagent.pga_job (jobid, jobjclid, jobname, jobdesc, jobhostagent, jobenabled, jobcreated, jobchanged, jobagentid, jobnextrun, joblastrun) FROM '$$PATH$$/5194.dat';

--
-- Data for Name: pga_jobagent; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobagent (jagpid, jaglogintime, jagstation) FROM stdin;
\.
COPY pgagent.pga_jobagent (jagpid, jaglogintime, jagstation) FROM '$$PATH$$/5190.dat';

--
-- Data for Name: pga_jobclass; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobclass (jclid, jclname) FROM stdin;
\.
COPY pgagent.pga_jobclass (jclid, jclname) FROM '$$PATH$$/5192.dat';

--
-- Data for Name: pga_joblog; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_joblog (jlgid, jlgjobid, jlgstatus, jlgstart, jlgduration) FROM stdin;
\.
COPY pgagent.pga_joblog (jlgid, jlgjobid, jlgstatus, jlgstart, jlgduration) FROM '$$PATH$$/5202.dat';

--
-- Data for Name: pga_jobstep; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobstep (jstid, jstjobid, jstname, jstdesc, jstenabled, jstkind, jstcode, jstconnstr, jstdbname, jstonerror, jscnextrun) FROM stdin;
\.
COPY pgagent.pga_jobstep (jstid, jstjobid, jstname, jstdesc, jstenabled, jstkind, jstcode, jstconnstr, jstdbname, jstonerror, jscnextrun) FROM '$$PATH$$/5196.dat';

--
-- Data for Name: pga_jobsteplog; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobsteplog (jslid, jsljlgid, jsljstid, jslstatus, jslresult, jslstart, jslduration, jsloutput) FROM stdin;
\.
COPY pgagent.pga_jobsteplog (jslid, jsljlgid, jsljstid, jslstatus, jslresult, jslstart, jslduration, jsloutput) FROM '$$PATH$$/5204.dat';

--
-- Data for Name: pga_schedule; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_schedule (jscid, jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths) FROM stdin;
\.
COPY pgagent.pga_schedule (jscid, jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths) FROM '$$PATH$$/5198.dat';

--
-- Data for Name: albumcomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumcomments (id, album_id, user_id, text, "time") FROM stdin;
\.
COPY public.albumcomments (id, album_id, user_id, text, "time") FROM '$$PATH$$/5159.dat';

--
-- Data for Name: albumlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumlikes (album_id, user_id) FROM stdin;
\.
COPY public.albumlikes (album_id, user_id) FROM '$$PATH$$/5178.dat';

--
-- Data for Name: albums; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albums (id, singer_id, name) FROM stdin;
\.
COPY public.albums (id, singer_id, name) FROM '$$PATH$$/5161.dat';

--
-- Data for Name: concerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.concerts (id, singer_id, price, date, has_suspended) FROM stdin;
\.
COPY public.concerts (id, singer_id, price, date, has_suspended) FROM '$$PATH$$/5163.dat';

--
-- Data for Name: favoritemusics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoritemusics (id, music_id, user_id) FROM stdin;
\.
COPY public.favoritemusics (id, music_id, user_id) FROM '$$PATH$$/5165.dat';

--
-- Data for Name: favoriteplaylists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoriteplaylists (id, playlist_id, user_id) FROM stdin;
\.
COPY public.favoriteplaylists (id, playlist_id, user_id) FROM '$$PATH$$/5167.dat';

--
-- Data for Name: followers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.followers (follower_id, user_id) FROM stdin;
\.
COPY public.followers (follower_id, user_id) FROM '$$PATH$$/5168.dat';

--
-- Data for Name: friendrequests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friendrequests (sender_id, reciever_id, accepted) FROM stdin;
\.
COPY public.friendrequests (sender_id, reciever_id, accepted) FROM '$$PATH$$/5169.dat';

--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, sender_id, reciever_id, text, "time") FROM stdin;
\.
COPY public.messages (id, sender_id, reciever_id, text, "time") FROM '$$PATH$$/5189.dat';

--
-- Data for Name: musiccomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiccomments (id, music_id, user_id, text, "time") FROM stdin;
\.
COPY public.musiccomments (id, music_id, user_id, text, "time") FROM '$$PATH$$/5171.dat';

--
-- Data for Name: musiclikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiclikes (music_id, user_id) FROM stdin;
\.
COPY public.musiclikes (music_id, user_id) FROM '$$PATH$$/5172.dat';

--
-- Data for Name: musics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text, audio_url) FROM stdin;
\.
COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text, audio_url) FROM '$$PATH$$/5174.dat';

--
-- Data for Name: playlist_music; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlist_music (music_id, playlist_id) FROM stdin;
\.
COPY public.playlist_music (music_id, playlist_id) FROM '$$PATH$$/5186.dat';

--
-- Data for Name: playlistcomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistcomments (id, playlist_id, user_id, text, "time") FROM stdin;
\.
COPY public.playlistcomments (id, playlist_id, user_id, text, "time") FROM '$$PATH$$/5176.dat';

--
-- Data for Name: playlistlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistlikes (playlist_id, user_id) FROM stdin;
\.
COPY public.playlistlikes (playlist_id, user_id) FROM '$$PATH$$/5177.dat';

--
-- Data for Name: playlists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlists (id, owner_id, is_public, name) FROM stdin;
\.
COPY public.playlists (id, owner_id, is_public, name) FROM '$$PATH$$/5180.dat';

--
-- Data for Name: predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.predictions (user_id, music_id, rank) FROM stdin;
\.
COPY public.predictions (user_id, music_id, rank) FROM '$$PATH$$/5187.dat';

--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test (message) FROM stdin;
\.
COPY public.test (message) FROM '$$PATH$$/5181.dat';

--
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket (id, user_id, concert_id, purchase_date) FROM stdin;
\.
COPY public.ticket (id, user_id, concert_id, purchase_date) FROM '$$PATH$$/5185.dat';

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password, image_url) FROM stdin;
\.
COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password, image_url) FROM '$$PATH$$/5183.dat';

--
-- Name: pga_exception_jexid_seq; Type: SEQUENCE SET; Schema: pgagent; Owner: postgres
--

SELECT pg_catalog.setval('pgagent.pga_exception_jexid_seq', 1, false);


--
-- Name: pga_job_jobid_seq; Type: SEQUENCE SET; Schema: pgagent; Owner: postgres
--

SELECT pg_catalog.setval('pgagent.pga_job_jobid_seq', 2, true);


--
-- Name: pga_jobclass_jclid_seq; Type: SEQUENCE SET; Schema: pgagent; Owner: postgres
--

SELECT pg_catalog.setval('pgagent.pga_jobclass_jclid_seq', 5, true);


--
-- Name: pga_joblog_jlgid_seq; Type: SEQUENCE SET; Schema: pgagent; Owner: postgres
--

SELECT pg_catalog.setval('pgagent.pga_joblog_jlgid_seq', 1, false);


--
-- Name: pga_jobstep_jstid_seq; Type: SEQUENCE SET; Schema: pgagent; Owner: postgres
--

SELECT pg_catalog.setval('pgagent.pga_jobstep_jstid_seq', 1, false);


--
-- Name: pga_jobsteplog_jslid_seq; Type: SEQUENCE SET; Schema: pgagent; Owner: postgres
--

SELECT pg_catalog.setval('pgagent.pga_jobsteplog_jslid_seq', 1, false);


--
-- Name: pga_schedule_jscid_seq; Type: SEQUENCE SET; Schema: pgagent; Owner: postgres
--

SELECT pg_catalog.setval('pgagent.pga_schedule_jscid_seq', 1, false);


--
-- Name: albumcomment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albumcomment_id_seq', 1, false);


--
-- Name: albums_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albums_id_seq', 8, true);


--
-- Name: concerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.concerts_id_seq', 4, true);


--
-- Name: favoritemusics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favoritemusics_id_seq', 1, false);


--
-- Name: favoriteplaylists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favoriteplaylists_id_seq', 1, false);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 7, true);


--
-- Name: musiccomments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musiccomments_id_seq', 8, true);


--
-- Name: musics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musics_id_seq', 1, false);


--
-- Name: playlistcomments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlistcomments_id_seq', 1, false);


--
-- Name: playlists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlists_id_seq', 11, true);


--
-- Name: ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_id_seq', 10, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 31, true);


--
-- Name: pga_exception pga_exception_pkey; Type: CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_exception
    ADD CONSTRAINT pga_exception_pkey PRIMARY KEY (jexid);


--
-- Name: pga_job pga_job_pkey; Type: CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_job
    ADD CONSTRAINT pga_job_pkey PRIMARY KEY (jobid);


--
-- Name: pga_jobagent pga_jobagent_pkey; Type: CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobagent
    ADD CONSTRAINT pga_jobagent_pkey PRIMARY KEY (jagpid);


--
-- Name: pga_jobclass pga_jobclass_pkey; Type: CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobclass
    ADD CONSTRAINT pga_jobclass_pkey PRIMARY KEY (jclid);


--
-- Name: pga_joblog pga_joblog_pkey; Type: CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_joblog
    ADD CONSTRAINT pga_joblog_pkey PRIMARY KEY (jlgid);


--
-- Name: pga_jobstep pga_jobstep_pkey; Type: CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobstep
    ADD CONSTRAINT pga_jobstep_pkey PRIMARY KEY (jstid);


--
-- Name: pga_jobsteplog pga_jobsteplog_pkey; Type: CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobsteplog
    ADD CONSTRAINT pga_jobsteplog_pkey PRIMARY KEY (jslid);


--
-- Name: pga_schedule pga_schedule_pkey; Type: CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_schedule
    ADD CONSTRAINT pga_schedule_pkey PRIMARY KEY (jscid);


--
-- Name: albumcomments albumcomment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_pkey PRIMARY KEY (id);


--
-- Name: albums albums_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (id);


--
-- Name: concerts concert_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_pkey PRIMARY KEY (id);


--
-- Name: favoritemusics favoritemusics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_pkey PRIMARY KEY (id);


--
-- Name: favoriteplaylists favoriteplaylists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_pkey PRIMARY KEY (id);


--
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (user_id, follower_id);


--
-- Name: friendrequests friendrequests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_pkey PRIMARY KEY (sender_id, reciever_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: musiccomments musiccomments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_pkey PRIMARY KEY (id);


--
-- Name: musics musics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_pkey PRIMARY KEY (id);


--
-- Name: musiclikes pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT pk PRIMARY KEY (user_id, music_id);


--
-- Name: albumlikes pk2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT pk2 PRIMARY KEY (album_id, user_id);


--
-- Name: playlistlikes pk_playlistlikes; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT pk_playlistlikes PRIMARY KEY (playlist_id, user_id);


--
-- Name: playlist_music playlist_music_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_pkey PRIMARY KEY (music_id, playlist_id);


--
-- Name: playlistcomments playlistcomments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_pkey PRIMARY KEY (id);


--
-- Name: playlists playlists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (id);


--
-- Name: predictions predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_pkey PRIMARY KEY (user_id, music_id, rank);


--
-- Name: test test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (message);


--
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- Name: users unique_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_email UNIQUE (email);


--
-- Name: albums unique_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT unique_name UNIQUE (name);


--
-- Name: playlists unique_name_for_each_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT unique_name_for_each_user UNIQUE (owner_id, name);


--
-- Name: users unique_username; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_username UNIQUE (username);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: pga_exception_datetime; Type: INDEX; Schema: pgagent; Owner: postgres
--

CREATE UNIQUE INDEX pga_exception_datetime ON pgagent.pga_exception USING btree (jexdate, jextime);


--
-- Name: pga_exception_jexscid; Type: INDEX; Schema: pgagent; Owner: postgres
--

CREATE INDEX pga_exception_jexscid ON pgagent.pga_exception USING btree (jexscid);


--
-- Name: pga_jobclass_name; Type: INDEX; Schema: pgagent; Owner: postgres
--

CREATE UNIQUE INDEX pga_jobclass_name ON pgagent.pga_jobclass USING btree (jclname);


--
-- Name: pga_joblog_jobid; Type: INDEX; Schema: pgagent; Owner: postgres
--

CREATE INDEX pga_joblog_jobid ON pgagent.pga_joblog USING btree (jlgjobid);


--
-- Name: pga_jobschedule_jobid; Type: INDEX; Schema: pgagent; Owner: postgres
--

CREATE INDEX pga_jobschedule_jobid ON pgagent.pga_schedule USING btree (jscjobid);


--
-- Name: pga_jobstep_jobid; Type: INDEX; Schema: pgagent; Owner: postgres
--

CREATE INDEX pga_jobstep_jobid ON pgagent.pga_jobstep USING btree (jstjobid);


--
-- Name: pga_jobsteplog_jslid; Type: INDEX; Schema: pgagent; Owner: postgres
--

CREATE INDEX pga_jobsteplog_jslid ON pgagent.pga_jobsteplog USING btree (jsljlgid);


--
-- Name: pga_exception pga_exception_trigger; Type: TRIGGER; Schema: pgagent; Owner: postgres
--

CREATE TRIGGER pga_exception_trigger AFTER INSERT OR DELETE OR UPDATE ON pgagent.pga_exception FOR EACH ROW EXECUTE FUNCTION pgagent.pga_exception_trigger();


--
-- Name: TRIGGER pga_exception_trigger ON pga_exception; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TRIGGER pga_exception_trigger ON pgagent.pga_exception IS 'Update the job''s next run time whenever an exception changes';


--
-- Name: pga_job pga_job_trigger; Type: TRIGGER; Schema: pgagent; Owner: postgres
--

CREATE TRIGGER pga_job_trigger BEFORE UPDATE ON pgagent.pga_job FOR EACH ROW EXECUTE FUNCTION pgagent.pga_job_trigger();


--
-- Name: TRIGGER pga_job_trigger ON pga_job; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TRIGGER pga_job_trigger ON pgagent.pga_job IS 'Update the job''s next run time.';


--
-- Name: pga_schedule pga_schedule_trigger; Type: TRIGGER; Schema: pgagent; Owner: postgres
--

CREATE TRIGGER pga_schedule_trigger AFTER INSERT OR DELETE OR UPDATE ON pgagent.pga_schedule FOR EACH ROW EXECUTE FUNCTION pgagent.pga_schedule_trigger();


--
-- Name: TRIGGER pga_schedule_trigger ON pga_schedule; Type: COMMENT; Schema: pgagent; Owner: postgres
--

COMMENT ON TRIGGER pga_schedule_trigger ON pgagent.pga_schedule IS 'Update the job''s next run time whenever a schedule changes';


--
-- Name: concerts get_back_money; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER get_back_money AFTER UPDATE ON public.concerts FOR EACH ROW EXECUTE FUNCTION public.get_back_money_function();


--
-- Name: ticket get_money; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER get_money BEFORE INSERT ON public.ticket FOR EACH ROW EXECUTE FUNCTION public.get_money_function();


--
-- Name: musiccomments notify_comment_to_friends; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_comment_to_friends AFTER INSERT ON public.musiccomments FOR EACH ROW EXECUTE FUNCTION public.notify_comment();


--
-- Name: musiclikes notify_comment_to_friends; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_comment_to_friends AFTER INSERT ON public.musiclikes FOR EACH ROW EXECUTE FUNCTION public.notify_like();


--
-- Name: pga_exception pga_exception_jexscid_fkey; Type: FK CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_exception
    ADD CONSTRAINT pga_exception_jexscid_fkey FOREIGN KEY (jexscid) REFERENCES pgagent.pga_schedule(jscid) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: pga_job pga_job_jobagentid_fkey; Type: FK CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_job
    ADD CONSTRAINT pga_job_jobagentid_fkey FOREIGN KEY (jobagentid) REFERENCES pgagent.pga_jobagent(jagpid) ON UPDATE RESTRICT ON DELETE SET NULL;


--
-- Name: pga_job pga_job_jobjclid_fkey; Type: FK CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_job
    ADD CONSTRAINT pga_job_jobjclid_fkey FOREIGN KEY (jobjclid) REFERENCES pgagent.pga_jobclass(jclid) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: pga_joblog pga_joblog_jlgjobid_fkey; Type: FK CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_joblog
    ADD CONSTRAINT pga_joblog_jlgjobid_fkey FOREIGN KEY (jlgjobid) REFERENCES pgagent.pga_job(jobid) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: pga_jobstep pga_jobstep_jstjobid_fkey; Type: FK CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobstep
    ADD CONSTRAINT pga_jobstep_jstjobid_fkey FOREIGN KEY (jstjobid) REFERENCES pgagent.pga_job(jobid) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: pga_jobsteplog pga_jobsteplog_jsljlgid_fkey; Type: FK CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobsteplog
    ADD CONSTRAINT pga_jobsteplog_jsljlgid_fkey FOREIGN KEY (jsljlgid) REFERENCES pgagent.pga_joblog(jlgid) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: pga_jobsteplog pga_jobsteplog_jsljstid_fkey; Type: FK CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_jobsteplog
    ADD CONSTRAINT pga_jobsteplog_jsljstid_fkey FOREIGN KEY (jsljstid) REFERENCES pgagent.pga_jobstep(jstid) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: pga_schedule pga_schedule_jscjobid_fkey; Type: FK CONSTRAINT; Schema: pgagent; Owner: postgres
--

ALTER TABLE ONLY pgagent.pga_schedule
    ADD CONSTRAINT pga_schedule_jscjobid_fkey FOREIGN KEY (jscjobid) REFERENCES pgagent.pga_job(jobid) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: albumcomments albumcomment_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: albumcomments albumcomment_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: albumlikes albumlikes_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: albumlikes albumlikes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: albums albums_singer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: concerts concert_singer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: favoritemusics favoritemusics_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: favoritemusics favoritemusics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: favoriteplaylists favoriteplaylists_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: favoriteplaylists favoriteplaylists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: followers followers_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: followers followers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: friendrequests friendrequests_reciever_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: friendrequests friendrequests_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: messages messages_reciever_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id);


--
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: musiccomments musiccomments_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: musiccomments musiccomments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: musiclikes musicllikes_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: musiclikes musicllikes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: musics musics_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: playlist_music playlist_music_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: playlist_music playlist_music_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: playlistcomments playlistcomments_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: playlistcomments playlistcomments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: playlistlikes playlistlike_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: playlistlikes playlistlike_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: playlists playlists_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: predictions predictions_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id);


--
-- Name: predictions predictions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: ticket ticket_concert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_concert_id_fkey FOREIGN KEY (concert_id) REFERENCES public.concerts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ticket ticket_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: DATABASE ballmer_peak; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE ballmer_peak TO ballmer_peak WITH GRANT OPTION;


--
-- Name: TABLE albumcomments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.albumcomments TO ballmer_peak;


--
-- Name: SEQUENCE albumcomment_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.albumcomment_id_seq TO ballmer_peak;


--
-- Name: TABLE albumlikes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.albumlikes TO ballmer_peak;


--
-- Name: TABLE albums; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.albums TO ballmer_peak;


--
-- Name: SEQUENCE albums_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.albums_id_seq TO ballmer_peak;


--
-- Name: TABLE concerts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.concerts TO ballmer_peak;


--
-- Name: SEQUENCE concerts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.concerts_id_seq TO ballmer_peak;


--
-- Name: TABLE favoritemusics; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.favoritemusics TO ballmer_peak;


--
-- Name: SEQUENCE favoritemusics_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.favoritemusics_id_seq TO ballmer_peak;


--
-- Name: TABLE favoriteplaylists; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.favoriteplaylists TO ballmer_peak;


--
-- Name: SEQUENCE favoriteplaylists_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.favoriteplaylists_id_seq TO ballmer_peak;


--
-- Name: TABLE followers; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.followers TO ballmer_peak;


--
-- Name: TABLE friendrequests; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.friendrequests TO ballmer_peak;


--
-- Name: TABLE messages; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.messages TO ballmer_peak WITH GRANT OPTION;


--
-- Name: SEQUENCE messages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.messages_id_seq TO ballmer_peak;


--
-- Name: TABLE musiccomments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.musiccomments TO ballmer_peak;


--
-- Name: SEQUENCE musiccomments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.musiccomments_id_seq TO ballmer_peak;


--
-- Name: TABLE musiclikes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.musiclikes TO ballmer_peak;


--
-- Name: TABLE musics; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.musics TO ballmer_peak;


--
-- Name: SEQUENCE musics_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.musics_id_seq TO ballmer_peak;


--
-- Name: TABLE playlist_music; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.playlist_music TO ballmer_peak;


--
-- Name: TABLE playlistcomments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.playlistcomments TO ballmer_peak;


--
-- Name: SEQUENCE playlistcomments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.playlistcomments_id_seq TO ballmer_peak;


--
-- Name: TABLE playlistlikes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.playlistlikes TO ballmer_peak;


--
-- Name: TABLE playlists; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.playlists TO ballmer_peak;


--
-- Name: SEQUENCE playlists_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.playlists_id_seq TO ballmer_peak;


--
-- Name: TABLE predictions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.predictions TO ballmer_peak;


--
-- Name: TABLE test; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.test TO ballmer_peak;


--
-- Name: TABLE ticket; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ticket TO ballmer_peak;


--
-- Name: SEQUENCE ticket_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.ticket_id_seq TO ballmer_peak;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO ballmer_peak WITH GRANT OPTION;


--
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.users_id_seq TO ballmer_peak;


--
-- PostgreSQL database dump complete
--

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                