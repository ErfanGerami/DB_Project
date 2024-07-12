toc.dat                                                                                             0000600 0004000 0002000 00000171343 14644314513 0014455 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP   7                     |            ballmer_peak    16.2    16.3 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false         �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false         �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false         �           1262    41870    ballmer_peak    DATABASE     �   CREATE DATABASE ballmer_peak WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE ballmer_peak;
                postgres    false         �           0    0    DATABASE ballmer_peak    ACL     F   GRANT ALL ON DATABASE ballmer_peak TO ballmer_peak WITH GRANT OPTION;
                   postgres    false    5074                    1255    51247    get_back_money_function()    FUNCTION     �  CREATE FUNCTION public.get_back_money_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

if(NEW.has_suspended=true and OLD.has_suspended=false) then

update users set money=money+ OLD.price*(select count(*) from ticket where user_id=id and concert_id=OLD.id) where id in (select users.id from users,ticket where ticket.concert_id=OLD.id );


end if;
return NEW;





END;$$;
 0   DROP FUNCTION public.get_back_money_function();
       public          postgres    false                    1255    51168    get_interactions()    FUNCTION     ~  CREATE FUNCTION public.get_interactions() RETURNS TABLE(__id integer, _mid integer, _sid integer, _genre character varying, inter bigint)
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
       public          postgres    false                    1255    51249    get_money_function()    FUNCTION     3  CREATE FUNCTION public.get_money_function() RETURNS trigger
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
       public          postgres    false         �            1255    51163    get_musics_in_playlist(integer)    FUNCTION       CREATE FUNCTION public.get_musics_in_playlist(_id integer) RETURNS TABLE(id integer, album_id integer, name character varying, genre character varying, rangeage character varying, cover_image_path character varying, can_add_to_playlist boolean, text text)
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
       public          postgres    false                    1255    51216    get_predictions(integer)    FUNCTION     �  CREATE FUNCTION public.get_predictions(_user_id integer) RETURNS TABLE(image_url character varying, audio_url character varying, name character varying, singer_id integer, id integer, rank integer)
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
       public          postgres    false         �            1255    51196    get_singer_id(integer)    FUNCTION     �   CREATE FUNCTION public.get_singer_id(music_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$begin

declare res int;
begin
	select singer_id into res from musics,albums where albums.id=musics.album_id;
	return res;
end;

end$$;
 6   DROP FUNCTION public.get_singer_id(music_id integer);
       public          postgres    false                    1255    51200    get_users_playlists(integer)    FUNCTION     9  CREATE FUNCTION public.get_users_playlists(user_id integer) RETURNS TABLE(id integer, owner_id integer, is_public boolean, image_url character varying, name character varying)
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
       public          postgres    false         
           1255    51242    notify_comment()    FUNCTION     s  CREATE FUNCTION public.notify_comment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	declare singer_name varchar(200);
	declare music_name varchar(200);
	begin
		select users.username,musics.name into singer_name,music_name from musics,albums,users where musics.album_id=albums.id and albums.singer_id=users.id and NEW.music_id=musics.id;
		
	    INSERT INTO messages(sender_id,reciever_id,text) 
		(
		(select NEW.user_id,friendrequests.sender_id, '<p style="opacity:60%">💬 commented on  music  <strong>' || music_name ||'</strong>💬</p>'
		from friendrequests where accepted and reciever_id=NEW.user_id)
		union all 
		(select NEW.user_id,friendrequests.reciever_id, '<p style="opacity:60%">💬 commented on  music  <strong>' || music_name ||'</strong>💬</p>'
		from friendrequests where accepted and sender_id=NEW.user_id)
		
		);
	    RETURN NEW;
	end;
END;
$$;
 '   DROP FUNCTION public.notify_comment();
       public          postgres    false         	           1255    51244    notify_like()    FUNCTION     �  CREATE FUNCTION public.notify_like() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	declare singer_name varchar(200);
	declare musicname varchar(200);
	
	begin
		select users.username  , musics.name into singer_name,musicname from musics,albums,users where musics.album_id=albums.id and albums.singer_id=users.id and NEW.music_id=musics.id;
		
	    INSERT INTO messages(sender_id,reciever_id,text) 
		(
		(select NEW.user_id,friendrequests.sender_id, '<p style="opacity:60%">❤️ liked music <strong>' || musicname || '</string> by '|| singer_name ||'❤️</p>'
		from friendrequests where accepted and reciever_id=NEW.user_id)
		union all 
		(select NEW.user_id,friendrequests.reciever_id, '<p style="opacity:60%">❤️ liked music <strong>' || musicname || '</string> by '|| singer_name ||'❤️</p>'
		from friendrequests where accepted and sender_id=NEW.user_id)
		
		);
	    RETURN NEW;
	end;
END;
$$;
 $   DROP FUNCTION public.notify_like();
       public          postgres    false         �            1259    50881    albumcomments    TABLE     �   CREATE TABLE public.albumcomments (
    id integer NOT NULL,
    album_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 !   DROP TABLE public.albumcomments;
       public         heap    postgres    false         �           0    0    TABLE albumcomments    ACL     9   GRANT ALL ON TABLE public.albumcomments TO ballmer_peak;
          public          postgres    false    216         �            1259    50880    albumcomment_id_seq    SEQUENCE     �   CREATE SEQUENCE public.albumcomment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.albumcomment_id_seq;
       public          postgres    false    216         �           0    0    albumcomment_id_seq    SEQUENCE OWNED BY     L   ALTER SEQUENCE public.albumcomment_id_seq OWNED BY public.albumcomments.id;
          public          postgres    false    215         �           0    0    SEQUENCE albumcomment_id_seq    ACL     B   GRANT ALL ON SEQUENCE public.albumcomment_id_seq TO ballmer_peak;
          public          postgres    false    215         �            1259    50950 
   albumlikes    TABLE     `   CREATE TABLE public.albumlikes (
    album_id integer NOT NULL,
    user_id integer NOT NULL
);
    DROP TABLE public.albumlikes;
       public         heap    postgres    false         �           0    0    TABLE albumlikes    ACL     6   GRANT ALL ON TABLE public.albumlikes TO ballmer_peak;
          public          postgres    false    235         �            1259    50888    albums    TABLE     p   CREATE TABLE public.albums (
    id integer NOT NULL,
    singer_id integer,
    name character varying(100)
);
    DROP TABLE public.albums;
       public         heap    postgres    false         �           0    0    TABLE albums    ACL     2   GRANT ALL ON TABLE public.albums TO ballmer_peak;
          public          postgres    false    218         �            1259    50887    albums_id_seq    SEQUENCE     �   CREATE SEQUENCE public.albums_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.albums_id_seq;
       public          postgres    false    218         �           0    0    albums_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.albums_id_seq OWNED BY public.albums.id;
          public          postgres    false    217         �           0    0    SEQUENCE albums_id_seq    ACL     <   GRANT ALL ON SEQUENCE public.albums_id_seq TO ballmer_peak;
          public          postgres    false    217         �            1259    50893    concerts    TABLE     �   CREATE TABLE public.concerts (
    id integer NOT NULL,
    singer_id integer,
    price bigint,
    date date,
    has_suspended boolean DEFAULT false
);
    DROP TABLE public.concerts;
       public         heap    postgres    false         �           0    0    TABLE concerts    ACL     4   GRANT ALL ON TABLE public.concerts TO ballmer_peak;
          public          postgres    false    220         �            1259    50892    concerts_id_seq    SEQUENCE     �   CREATE SEQUENCE public.concerts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.concerts_id_seq;
       public          postgres    false    220         �           0    0    concerts_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.concerts_id_seq OWNED BY public.concerts.id;
          public          postgres    false    219         �           0    0    SEQUENCE concerts_id_seq    ACL     >   GRANT ALL ON SEQUENCE public.concerts_id_seq TO ballmer_peak;
          public          postgres    false    219         �            1259    50899    favoritemusics    TABLE     k   CREATE TABLE public.favoritemusics (
    id integer NOT NULL,
    music_id integer,
    user_id integer
);
 "   DROP TABLE public.favoritemusics;
       public         heap    postgres    false         �           0    0    TABLE favoritemusics    ACL     :   GRANT ALL ON TABLE public.favoritemusics TO ballmer_peak;
          public          postgres    false    222         �            1259    50898    favoritemusics_id_seq    SEQUENCE     �   CREATE SEQUENCE public.favoritemusics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.favoritemusics_id_seq;
       public          postgres    false    222         �           0    0    favoritemusics_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.favoritemusics_id_seq OWNED BY public.favoritemusics.id;
          public          postgres    false    221         �           0    0    SEQUENCE favoritemusics_id_seq    ACL     D   GRANT ALL ON SEQUENCE public.favoritemusics_id_seq TO ballmer_peak;
          public          postgres    false    221         �            1259    50904    favoriteplaylists    TABLE     q   CREATE TABLE public.favoriteplaylists (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer
);
 %   DROP TABLE public.favoriteplaylists;
       public         heap    postgres    false         �           0    0    TABLE favoriteplaylists    ACL     =   GRANT ALL ON TABLE public.favoriteplaylists TO ballmer_peak;
          public          postgres    false    224         �            1259    50903    favoriteplaylists_id_seq    SEQUENCE     �   CREATE SEQUENCE public.favoriteplaylists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.favoriteplaylists_id_seq;
       public          postgres    false    224         �           0    0    favoriteplaylists_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.favoriteplaylists_id_seq OWNED BY public.favoriteplaylists.id;
          public          postgres    false    223         �           0    0 !   SEQUENCE favoriteplaylists_id_seq    ACL     G   GRANT ALL ON SEQUENCE public.favoriteplaylists_id_seq TO ballmer_peak;
          public          postgres    false    223         �            1259    50908 	   followers    TABLE     b   CREATE TABLE public.followers (
    follower_id integer NOT NULL,
    user_id integer NOT NULL
);
    DROP TABLE public.followers;
       public         heap    postgres    false         �           0    0    TABLE followers    ACL     5   GRANT ALL ON TABLE public.followers TO ballmer_peak;
          public          postgres    false    225         �            1259    50911    friendrequests    TABLE     �   CREATE TABLE public.friendrequests (
    sender_id integer NOT NULL,
    reciever_id integer NOT NULL,
    accepted boolean DEFAULT false
);
 "   DROP TABLE public.friendrequests;
       public         heap    postgres    false         �           0    0    TABLE friendrequests    ACL     :   GRANT ALL ON TABLE public.friendrequests TO ballmer_peak;
          public          postgres    false    226         �            1259    51218    messages    TABLE     �   CREATE TABLE public.messages (
    id integer NOT NULL,
    sender_id integer,
    reciever_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.messages;
       public         heap    postgres    false         �           0    0    TABLE messages    ACL     F   GRANT ALL ON TABLE public.messages TO ballmer_peak WITH GRANT OPTION;
          public          postgres    false    246         �            1259    51217    messages_id_seq    SEQUENCE     �   CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.messages_id_seq;
       public          postgres    false    246         �           0    0    messages_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;
          public          postgres    false    245         �           0    0    SEQUENCE messages_id_seq    ACL     G   GRANT SELECT,USAGE ON SEQUENCE public.messages_id_seq TO ballmer_peak;
          public          postgres    false    245         �            1259    50916    musiccomments    TABLE     �   CREATE TABLE public.musiccomments (
    id integer NOT NULL,
    music_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 !   DROP TABLE public.musiccomments;
       public         heap    postgres    false         �           0    0    TABLE musiccomments    ACL     9   GRANT ALL ON TABLE public.musiccomments TO ballmer_peak;
          public          postgres    false    228         �            1259    50915    musiccomments_id_seq    SEQUENCE     �   CREATE SEQUENCE public.musiccomments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.musiccomments_id_seq;
       public          postgres    false    228         �           0    0    musiccomments_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.musiccomments_id_seq OWNED BY public.musiccomments.id;
          public          postgres    false    227         �           0    0    SEQUENCE musiccomments_id_seq    ACL     C   GRANT ALL ON SEQUENCE public.musiccomments_id_seq TO ballmer_peak;
          public          postgres    false    227         �            1259    50923 
   musiclikes    TABLE     `   CREATE TABLE public.musiclikes (
    music_id integer NOT NULL,
    user_id integer NOT NULL
);
    DROP TABLE public.musiclikes;
       public         heap    postgres    false         �           0    0    TABLE musiclikes    ACL     6   GRANT ALL ON TABLE public.musiclikes TO ballmer_peak;
          public          postgres    false    229         �            1259    50928    musics    TABLE     q  CREATE TABLE public.musics (
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
       public         heap    postgres    false         �           0    0    TABLE musics    ACL     2   GRANT ALL ON TABLE public.musics TO ballmer_peak;
          public          postgres    false    231         �            1259    50927    musics_id_seq    SEQUENCE     �   CREATE SEQUENCE public.musics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.musics_id_seq;
       public          postgres    false    231         �           0    0    musics_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.musics_id_seq OWNED BY public.musics.id;
          public          postgres    false    230         �           0    0    SEQUENCE musics_id_seq    ACL     <   GRANT ALL ON SEQUENCE public.musics_id_seq TO ballmer_peak;
          public          postgres    false    230         �            1259    51147    playlist_music    TABLE     h   CREATE TABLE public.playlist_music (
    music_id integer NOT NULL,
    playlist_id integer NOT NULL
);
 "   DROP TABLE public.playlist_music;
       public         heap    postgres    false         �           0    0    TABLE playlist_music    ACL     :   GRANT ALL ON TABLE public.playlist_music TO ballmer_peak;
          public          postgres    false    243         �            1259    50938    playlistcomments    TABLE     �   CREATE TABLE public.playlistcomments (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer,
    text text,
    "time" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 $   DROP TABLE public.playlistcomments;
       public         heap    postgres    false         �           0    0    TABLE playlistcomments    ACL     <   GRANT ALL ON TABLE public.playlistcomments TO ballmer_peak;
          public          postgres    false    233         �            1259    50937    playlistcomments_id_seq    SEQUENCE     �   CREATE SEQUENCE public.playlistcomments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.playlistcomments_id_seq;
       public          postgres    false    233         �           0    0    playlistcomments_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.playlistcomments_id_seq OWNED BY public.playlistcomments.id;
          public          postgres    false    232         �           0    0     SEQUENCE playlistcomments_id_seq    ACL     F   GRANT ALL ON SEQUENCE public.playlistcomments_id_seq TO ballmer_peak;
          public          postgres    false    232         �            1259    50945    playlistlikes    TABLE     f   CREATE TABLE public.playlistlikes (
    playlist_id integer NOT NULL,
    user_id integer NOT NULL
);
 !   DROP TABLE public.playlistlikes;
       public         heap    postgres    false         �           0    0    TABLE playlistlikes    ACL     9   GRANT ALL ON TABLE public.playlistlikes TO ballmer_peak;
          public          postgres    false    234         �            1259    50955 	   playlists    TABLE     �   CREATE TABLE public.playlists (
    id integer NOT NULL,
    owner_id integer,
    is_public boolean DEFAULT true,
    name character varying(100)
);
    DROP TABLE public.playlists;
       public         heap    postgres    false         �           0    0    TABLE playlists    ACL     5   GRANT ALL ON TABLE public.playlists TO ballmer_peak;
          public          postgres    false    237         �            1259    50954    playlists_id_seq    SEQUENCE     �   CREATE SEQUENCE public.playlists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.playlists_id_seq;
       public          postgres    false    237         �           0    0    playlists_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.playlists_id_seq OWNED BY public.playlists.id;
          public          postgres    false    236         �           0    0    SEQUENCE playlists_id_seq    ACL     ?   GRANT ALL ON SEQUENCE public.playlists_id_seq TO ballmer_peak;
          public          postgres    false    236         �            1259    51169    predictions    TABLE     |   CREATE TABLE public.predictions (
    user_id integer NOT NULL,
    music_id integer NOT NULL,
    rank integer NOT NULL
);
    DROP TABLE public.predictions;
       public         heap    postgres    false         �           0    0    TABLE predictions    ACL     7   GRANT ALL ON TABLE public.predictions TO ballmer_peak;
          public          postgres    false    244         �            1259    50960    test    TABLE     J   CREATE TABLE public.test (
    message character varying(100) NOT NULL
);
    DROP TABLE public.test;
       public         heap    postgres    false         �           0    0 
   TABLE test    ACL     0   GRANT ALL ON TABLE public.test TO ballmer_peak;
          public          postgres    false    238         �            1259    50972    ticket    TABLE     �   CREATE TABLE public.ticket (
    id integer NOT NULL,
    user_id integer NOT NULL,
    concert_id integer NOT NULL,
    purchase_date date
);
    DROP TABLE public.ticket;
       public         heap    postgres    false         �           0    0    TABLE ticket    ACL     2   GRANT ALL ON TABLE public.ticket TO ballmer_peak;
          public          postgres    false    242         �            1259    50971    ticket_id_seq    SEQUENCE     �   CREATE SEQUENCE public.ticket_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.ticket_id_seq;
       public          postgres    false    242         �           0    0    ticket_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.ticket_id_seq OWNED BY public.ticket.id;
          public          postgres    false    241         �           0    0    SEQUENCE ticket_id_seq    ACL     <   GRANT ALL ON SEQUENCE public.ticket_id_seq TO ballmer_peak;
          public          postgres    false    241         �            1259    50964    users    TABLE     �  CREATE TABLE public.users (
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
       public         heap    postgres    false         �           0    0    TABLE users    ACL     C   GRANT ALL ON TABLE public.users TO ballmer_peak WITH GRANT OPTION;
          public          postgres    false    240         �            1259    50963    users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.users_id_seq;
       public          postgres    false    240         �           0    0    users_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
          public          postgres    false    239         �           0    0    SEQUENCE users_id_seq    ACL     ;   GRANT ALL ON SEQUENCE public.users_id_seq TO ballmer_peak;
          public          postgres    false    239         �           2604    50884    albumcomments id    DEFAULT     s   ALTER TABLE ONLY public.albumcomments ALTER COLUMN id SET DEFAULT nextval('public.albumcomment_id_seq'::regclass);
 ?   ALTER TABLE public.albumcomments ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    215    216    216         �           2604    50891 	   albums id    DEFAULT     f   ALTER TABLE ONLY public.albums ALTER COLUMN id SET DEFAULT nextval('public.albums_id_seq'::regclass);
 8   ALTER TABLE public.albums ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    217    218         �           2604    50896    concerts id    DEFAULT     j   ALTER TABLE ONLY public.concerts ALTER COLUMN id SET DEFAULT nextval('public.concerts_id_seq'::regclass);
 :   ALTER TABLE public.concerts ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    219    220    220         �           2604    50902    favoritemusics id    DEFAULT     v   ALTER TABLE ONLY public.favoritemusics ALTER COLUMN id SET DEFAULT nextval('public.favoritemusics_id_seq'::regclass);
 @   ALTER TABLE public.favoritemusics ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    221    222    222         �           2604    50907    favoriteplaylists id    DEFAULT     |   ALTER TABLE ONLY public.favoriteplaylists ALTER COLUMN id SET DEFAULT nextval('public.favoriteplaylists_id_seq'::regclass);
 C   ALTER TABLE public.favoriteplaylists ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    223    224    224         �           2604    51221    messages id    DEFAULT     j   ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);
 :   ALTER TABLE public.messages ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    246    245    246         �           2604    50919    musiccomments id    DEFAULT     t   ALTER TABLE ONLY public.musiccomments ALTER COLUMN id SET DEFAULT nextval('public.musiccomments_id_seq'::regclass);
 ?   ALTER TABLE public.musiccomments ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    228    227    228         �           2604    50931 	   musics id    DEFAULT     f   ALTER TABLE ONLY public.musics ALTER COLUMN id SET DEFAULT nextval('public.musics_id_seq'::regclass);
 8   ALTER TABLE public.musics ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    230    231    231         �           2604    50941    playlistcomments id    DEFAULT     z   ALTER TABLE ONLY public.playlistcomments ALTER COLUMN id SET DEFAULT nextval('public.playlistcomments_id_seq'::regclass);
 B   ALTER TABLE public.playlistcomments ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    232    233    233         �           2604    50958    playlists id    DEFAULT     l   ALTER TABLE ONLY public.playlists ALTER COLUMN id SET DEFAULT nextval('public.playlists_id_seq'::regclass);
 ;   ALTER TABLE public.playlists ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    237    236    237         �           2604    50975 	   ticket id    DEFAULT     f   ALTER TABLE ONLY public.ticket ALTER COLUMN id SET DEFAULT nextval('public.ticket_id_seq'::regclass);
 8   ALTER TABLE public.ticket ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    242    241    242         �           2604    50967    users id    DEFAULT     d   ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
 7   ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    239    240    240         �          0    50881    albumcomments 
   TABLE DATA           L   COPY public.albumcomments (id, album_id, user_id, text, "time") FROM stdin;
    public          postgres    false    216       5038.dat �          0    50950 
   albumlikes 
   TABLE DATA           7   COPY public.albumlikes (album_id, user_id) FROM stdin;
    public          postgres    false    235       5057.dat �          0    50888    albums 
   TABLE DATA           5   COPY public.albums (id, singer_id, name) FROM stdin;
    public          postgres    false    218       5040.dat �          0    50893    concerts 
   TABLE DATA           M   COPY public.concerts (id, singer_id, price, date, has_suspended) FROM stdin;
    public          postgres    false    220       5042.dat �          0    50899    favoritemusics 
   TABLE DATA           ?   COPY public.favoritemusics (id, music_id, user_id) FROM stdin;
    public          postgres    false    222       5044.dat �          0    50904    favoriteplaylists 
   TABLE DATA           E   COPY public.favoriteplaylists (id, playlist_id, user_id) FROM stdin;
    public          postgres    false    224       5046.dat �          0    50908 	   followers 
   TABLE DATA           9   COPY public.followers (follower_id, user_id) FROM stdin;
    public          postgres    false    225       5047.dat �          0    50911    friendrequests 
   TABLE DATA           J   COPY public.friendrequests (sender_id, reciever_id, accepted) FROM stdin;
    public          postgres    false    226       5048.dat �          0    51218    messages 
   TABLE DATA           L   COPY public.messages (id, sender_id, reciever_id, text, "time") FROM stdin;
    public          postgres    false    246       5068.dat �          0    50916    musiccomments 
   TABLE DATA           L   COPY public.musiccomments (id, music_id, user_id, text, "time") FROM stdin;
    public          postgres    false    228       5050.dat �          0    50923 
   musiclikes 
   TABLE DATA           7   COPY public.musiclikes (music_id, user_id) FROM stdin;
    public          postgres    false    229       5051.dat �          0    50928    musics 
   TABLE DATA           v   COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text, audio_url) FROM stdin;
    public          postgres    false    231       5053.dat �          0    51147    playlist_music 
   TABLE DATA           ?   COPY public.playlist_music (music_id, playlist_id) FROM stdin;
    public          postgres    false    243       5065.dat �          0    50938    playlistcomments 
   TABLE DATA           R   COPY public.playlistcomments (id, playlist_id, user_id, text, "time") FROM stdin;
    public          postgres    false    233       5055.dat �          0    50945    playlistlikes 
   TABLE DATA           =   COPY public.playlistlikes (playlist_id, user_id) FROM stdin;
    public          postgres    false    234       5056.dat �          0    50955 	   playlists 
   TABLE DATA           B   COPY public.playlists (id, owner_id, is_public, name) FROM stdin;
    public          postgres    false    237       5059.dat �          0    51169    predictions 
   TABLE DATA           >   COPY public.predictions (user_id, music_id, rank) FROM stdin;
    public          postgres    false    244       5066.dat �          0    50960    test 
   TABLE DATA           '   COPY public.test (message) FROM stdin;
    public          postgres    false    238       5060.dat �          0    50972    ticket 
   TABLE DATA           H   COPY public.ticket (id, user_id, concert_id, purchase_date) FROM stdin;
    public          postgres    false    242       5064.dat �          0    50964    users 
   TABLE DATA              COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password, image_url) FROM stdin;
    public          postgres    false    240       5062.dat             0    0    albumcomment_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.albumcomment_id_seq', 1, false);
          public          postgres    false    215                    0    0    albums_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.albums_id_seq', 8, true);
          public          postgres    false    217                    0    0    concerts_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.concerts_id_seq', 4, true);
          public          postgres    false    219                    0    0    favoritemusics_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.favoritemusics_id_seq', 1, false);
          public          postgres    false    221                    0    0    favoriteplaylists_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.favoriteplaylists_id_seq', 1, false);
          public          postgres    false    223                    0    0    messages_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.messages_id_seq', 7, true);
          public          postgres    false    245                    0    0    musiccomments_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.musiccomments_id_seq', 8, true);
          public          postgres    false    227                    0    0    musics_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.musics_id_seq', 1, false);
          public          postgres    false    230                    0    0    playlistcomments_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.playlistcomments_id_seq', 1, false);
          public          postgres    false    232         	           0    0    playlists_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.playlists_id_seq', 11, true);
          public          postgres    false    236         
           0    0    ticket_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.ticket_id_seq', 10, true);
          public          postgres    false    241                    0    0    users_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.users_id_seq', 31, true);
          public          postgres    false    239         �           2606    50977    albumcomments albumcomment_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY public.albumcomments DROP CONSTRAINT albumcomment_pkey;
       public            postgres    false    216         �           2606    50981    albums albums_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.albums DROP CONSTRAINT albums_pkey;
       public            postgres    false    218         �           2606    50983    concerts concert_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY public.concerts DROP CONSTRAINT concert_pkey;
       public            postgres    false    220         �           2606    50985 "   favoritemusics favoritemusics_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.favoritemusics DROP CONSTRAINT favoritemusics_pkey;
       public            postgres    false    222         �           2606    50987 (   favoriteplaylists favoriteplaylists_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.favoriteplaylists DROP CONSTRAINT favoriteplaylists_pkey;
       public            postgres    false    224         �           2606    50989    followers followers_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (user_id, follower_id);
 B   ALTER TABLE ONLY public.followers DROP CONSTRAINT followers_pkey;
       public            postgres    false    225    225         �           2606    50991 "   friendrequests friendrequests_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_pkey PRIMARY KEY (sender_id, reciever_id);
 L   ALTER TABLE ONLY public.friendrequests DROP CONSTRAINT friendrequests_pkey;
       public            postgres    false    226    226         �           2606    51225    messages messages_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_pkey;
       public            postgres    false    246         �           2606    50993     musiccomments musiccomments_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_pkey;
       public            postgres    false    228         �           2606    50997    musics musics_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.musics DROP CONSTRAINT musics_pkey;
       public            postgres    false    231         �           2606    51202    musiclikes pk 
   CONSTRAINT     Z   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT pk PRIMARY KEY (user_id, music_id);
 7   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT pk;
       public            postgres    false    229    229         �           2606    51204    albumlikes pk2 
   CONSTRAINT     [   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT pk2 PRIMARY KEY (album_id, user_id);
 8   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT pk2;
       public            postgres    false    235    235         �           2606    51206    playlistlikes pk_playlistlikes 
   CONSTRAINT     n   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT pk_playlistlikes PRIMARY KEY (playlist_id, user_id);
 H   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT pk_playlistlikes;
       public            postgres    false    234    234         �           2606    51151 "   playlist_music playlist_music_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_pkey PRIMARY KEY (music_id, playlist_id);
 L   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_pkey;
       public            postgres    false    243    243         �           2606    50999 &   playlistcomments playlistcomments_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_pkey;
       public            postgres    false    233         �           2606    51003    playlists playlists_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.playlists DROP CONSTRAINT playlists_pkey;
       public            postgres    false    237         �           2606    51173    predictions predictions_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_pkey PRIMARY KEY (user_id, music_id, rank);
 F   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_pkey;
       public            postgres    false    244    244    244         �           2606    51005    test test_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (message);
 8   ALTER TABLE ONLY public.test DROP CONSTRAINT test_pkey;
       public            postgres    false    238         �           2606    51007    ticket ticket_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_pkey;
       public            postgres    false    242         �           2606    51146    users unique_email 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_email UNIQUE (email);
 <   ALTER TABLE ONLY public.users DROP CONSTRAINT unique_email;
       public            postgres    false    240         �           2606    51191    albums unique_name 
   CONSTRAINT     M   ALTER TABLE ONLY public.albums
    ADD CONSTRAINT unique_name UNIQUE (name);
 <   ALTER TABLE ONLY public.albums DROP CONSTRAINT unique_name;
       public            postgres    false    218         �           2606    51187 #   playlists unique_name_for_each_user 
   CONSTRAINT     h   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT unique_name_for_each_user UNIQUE (owner_id, name);
 M   ALTER TABLE ONLY public.playlists DROP CONSTRAINT unique_name_for_each_user;
       public            postgres    false    237    237         �           2606    51144    users unique_username 
   CONSTRAINT     T   ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_username UNIQUE (username);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT unique_username;
       public            postgres    false    240         �           2606    51009    users users_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    240                    2620    51248    concerts get_back_money    TRIGGER     ~   CREATE TRIGGER get_back_money AFTER UPDATE ON public.concerts FOR EACH ROW EXECUTE FUNCTION public.get_back_money_function();
 0   DROP TRIGGER get_back_money ON public.concerts;
       public          postgres    false    220    261                    2620    51250    ticket get_money    TRIGGER     s   CREATE TRIGGER get_money BEFORE INSERT ON public.ticket FOR EACH ROW EXECUTE FUNCTION public.get_money_function();
 )   DROP TRIGGER get_money ON public.ticket;
       public          postgres    false    242    263                    2620    51243 '   musiccomments notify_comment_to_friends    TRIGGER     �   CREATE TRIGGER notify_comment_to_friends AFTER INSERT ON public.musiccomments FOR EACH ROW EXECUTE FUNCTION public.notify_comment();
 @   DROP TRIGGER notify_comment_to_friends ON public.musiccomments;
       public          postgres    false    266    228                    2620    51245 $   musiclikes notify_comment_to_friends    TRIGGER        CREATE TRIGGER notify_comment_to_friends AFTER INSERT ON public.musiclikes FOR EACH ROW EXECUTE FUNCTION public.notify_like();
 =   DROP TRIGGER notify_comment_to_friends ON public.musiclikes;
       public          postgres    false    229    265         �           2606    51010 (   albumcomments albumcomment_album_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.albumcomments DROP CONSTRAINT albumcomment_album_id_fkey;
       public          postgres    false    216    4813    218         �           2606    51015 '   albumcomments albumcomment_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albumcomments
    ADD CONSTRAINT albumcomment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.albumcomments DROP CONSTRAINT albumcomment_user_id_fkey;
       public          postgres    false    240    4849    216                    2606    51020 #   albumlikes albumlikes_album_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 M   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT albumlikes_album_id_fkey;
       public          postgres    false    235    4813    218                    2606    51025 "   albumlikes albumlikes_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 L   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT albumlikes_user_id_fkey;
       public          postgres    false    240    4849    235         �           2606    51030    albums albums_singer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.albums DROP CONSTRAINT albums_singer_id_fkey;
       public          postgres    false    4849    240    218         �           2606    51035    concerts concert_singer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 I   ALTER TABLE ONLY public.concerts DROP CONSTRAINT concert_singer_id_fkey;
       public          postgres    false    240    4849    220         �           2606    51040 +   favoritemusics favoritemusics_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.favoritemusics DROP CONSTRAINT favoritemusics_music_id_fkey;
       public          postgres    false    4831    222    231         �           2606    51045 *   favoritemusics favoritemusics_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 T   ALTER TABLE ONLY public.favoritemusics DROP CONSTRAINT favoritemusics_user_id_fkey;
       public          postgres    false    240    222    4849                     2606    51050 4   favoriteplaylists favoriteplaylists_playlist_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 ^   ALTER TABLE ONLY public.favoriteplaylists DROP CONSTRAINT favoriteplaylists_playlist_id_fkey;
       public          postgres    false    4839    224    237                    2606    51055 0   favoriteplaylists favoriteplaylists_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.favoriteplaylists DROP CONSTRAINT favoriteplaylists_user_id_fkey;
       public          postgres    false    240    224    4849                    2606    51060 $   followers followers_follower_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.followers DROP CONSTRAINT followers_follower_id_fkey;
       public          postgres    false    240    225    4849                    2606    51065     followers followers_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 J   ALTER TABLE ONLY public.followers DROP CONSTRAINT followers_user_id_fkey;
       public          postgres    false    240    225    4849                    2606    51070 .   friendrequests friendrequests_reciever_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.friendrequests DROP CONSTRAINT friendrequests_reciever_id_fkey;
       public          postgres    false    226    4849    240                    2606    51075 ,   friendrequests friendrequests_sender_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.friendrequests DROP CONSTRAINT friendrequests_sender_id_fkey;
       public          postgres    false    240    226    4849                    2606    51231 "   messages messages_reciever_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id);
 L   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_reciever_id_fkey;
       public          postgres    false    4849    240    246                    2606    51226     messages messages_sender_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);
 J   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_sender_id_fkey;
       public          postgres    false    246    4849    240                    2606    51080 )   musiccomments musiccomments_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_music_id_fkey;
       public          postgres    false    228    4831    231                    2606    51085 (   musiccomments musiccomments_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_user_id_fkey;
       public          postgres    false    240    228    4849                    2606    51090 $   musiclikes musicllikes_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT musicllikes_music_id_fkey;
       public          postgres    false    229    231    4831         	           2606    51095 #   musiclikes musicllikes_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 M   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT musicllikes_user_id_fkey;
       public          postgres    false    229    4849    240         
           2606    51100    musics musics_album_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.musics DROP CONSTRAINT musics_album_id_fkey;
       public          postgres    false    4813    218    231                    2606    51152 +   playlist_music playlist_music_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_music_id_fkey;
       public          postgres    false    231    4831    243                    2606    51157 .   playlist_music playlist_music_playlist_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_playlist_id_fkey;
       public          postgres    false    4839    243    237                    2606    51105 2   playlistcomments playlistcomments_playlist_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 \   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_playlist_id_fkey;
       public          postgres    false    4839    237    233                    2606    51110 .   playlistcomments playlistcomments_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_user_id_fkey;
       public          postgres    false    4849    240    233                    2606    51115 +   playlistlikes playlistlike_playlist_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT playlistlike_playlist_id_fkey;
       public          postgres    false    4839    234    237                    2606    51120 '   playlistlikes playlistlike_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT playlistlike_user_id_fkey;
       public          postgres    false    234    240    4849                    2606    51125 !   playlists playlists_owner_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.playlists DROP CONSTRAINT playlists_owner_id_fkey;
       public          postgres    false    240    237    4849                    2606    51179 %   predictions predictions_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id);
 O   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_music_id_fkey;
       public          postgres    false    244    231    4831                    2606    51174 $   predictions predictions_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
 N   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_user_id_fkey;
       public          postgres    false    240    4849    244                    2606    51130    ticket ticket_concert_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_concert_id_fkey FOREIGN KEY (concert_id) REFERENCES public.concerts(id) ON UPDATE CASCADE ON DELETE CASCADE;
 G   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_concert_id_fkey;
       public          postgres    false    220    4817    242                    2606    51135    ticket ticket_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_user_id_fkey;
       public          postgres    false    240    242    4849                                                                                                                                                                                                                                                                                                     5038.dat                                                                                            0000600 0004000 0002000 00000000135 14644314513 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Great album!	2024-07-12 00:47:49.867549
2	2	2	Not bad.	2024-07-12 00:47:49.867549
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                   5057.dat                                                                                            0000600 0004000 0002000 00000000022 14644314513 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	2
2	22
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              5040.dat                                                                                            0000600 0004000 0002000 00000000066 14644314513 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	Album A
2	2	Album B
6	22	some alb1
8	22	name
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                          5042.dat                                                                                            0000600 0004000 0002000 00000000135 14644314513 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	1000	2023-01-01	f
2	2	2000	2023-02-01	t
4	22	100	2003-10-10	f
3	22	100	2003-10-10	t
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                   5044.dat                                                                                            0000600 0004000 0002000 00000000027 14644314513 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
2	2	2
3	1	2
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         5046.dat                                                                                            0000600 0004000 0002000 00000000013 14644314513 0014247 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     5047.dat                                                                                            0000600 0004000 0002000 00000000027 14644314513 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2
2	1
22	3
3	22
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         5048.dat                                                                                            0000600 0004000 0002000 00000000031 14644314513 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	f
22	2	t
22	3	f
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       5068.dat                                                                                            0000600 0004000 0002000 00000000746 14644314513 0014270 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	22	3	3	2024-07-12 15:56:23.280546
2	22	3	3	2024-07-12 15:56:36.658916
3	22	3	salam daash	2024-07-12 16:02:59.52322
4	22	2	commented on a music by User One	2024-07-12 19:55:22.306985
5	22	2	<p style="opacity:60%"> commented on a music by User One</p>	2024-07-12 19:56:33.391058
6	22	2	<p style="opacity:60%">❤️ liked music by User One❤️</p>	2024-07-12 20:00:07.92187
7	22	2	<p style="opacity:60%">❤️ liked music Song A by User One❤️</p>	2024-07-12 20:03:22.111754
\.


                          5050.dat                                                                                            0000600 0004000 0002000 00000000413 14644314513 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Love this song!	2024-07-12 00:47:21.696607
2	2	2	Nice track.	2024-07-12 00:47:21.696607
3	1	22	some text	2024-07-11 21:34:40.217333
4	1	22	some text	2024-07-11 21:34:42.538641
7	1	22	salam	2024-07-12 19:55:22.306985
8	1	22	salam	2024-07-12 19:56:33.391058
\.


                                                                                                                                                                                                                                                     5051.dat                                                                                            0000600 0004000 0002000 00000000034 14644314513 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	2
1	22
6	22
5	22
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    5053.dat                                                                                            0000600 0004000 0002000 00000002061 14644314513 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	Song A	Pop	All	/path/to/image1.jpg	t	Lyrics for Song A	\N
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


                                                                                                                                                                                                                                                                                                                                                                                                                                                                               5065.dat                                                                                            0000600 0004000 0002000 00000000027 14644314513 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	1
2	10
1	11
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         5055.dat                                                                                            0000600 0004000 0002000 00000000066 14644314513 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Great playlist!	2024-07-12 00:48:50.507124
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                          5056.dat                                                                                            0000600 0004000 0002000 00000000016 14644314513 0014253 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
1	22
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  5059.dat                                                                                            0000600 0004000 0002000 00000000125 14644314513 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	t	name1\n
6	22	t	name3
8	1	t	name3
9	22	t	None
10	22	t	name
11	22	t	iwniwde
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                           5066.dat                                                                                            0000600 0004000 0002000 00000000035 14644314513 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
1	2	2
2	2	1
2	1	2
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   5060.dat                                                                                            0000600 0004000 0002000 00000000005 14644314513 0014244 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5064.dat                                                                                            0000600 0004000 0002000 00000000032 14644314513 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	22	1	\N
10	22	3	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      5062.dat                                                                                            0000600 0004000 0002000 00000004204 14644314513 0014253 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        26	sa1alam21111	salam@1salamq.com21111	2003-02-02	addr	f	100	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0	.png is not expected
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


                                                                                                                                                                                                                                                                                                                                                                                            restore.sql                                                                                         0000600 0004000 0002000 00000136360 14644314513 0015402 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
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
		(select NEW.user_id,friendrequests.sender_id, '<p style="opacity:60%">💬 commented on  music  <strong>' || music_name ||'</strong>💬</p>'
		from friendrequests where accepted and reciever_id=NEW.user_id)
		union all 
		(select NEW.user_id,friendrequests.reciever_id, '<p style="opacity:60%">💬 commented on  music  <strong>' || music_name ||'</strong>💬</p>'
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
		(select NEW.user_id,friendrequests.sender_id, '<p style="opacity:60%">❤️ liked music <strong>' || musicname || '</string> by '|| singer_name ||'❤️</p>'
		from friendrequests where accepted and reciever_id=NEW.user_id)
		union all 
		(select NEW.user_id,friendrequests.reciever_id, '<p style="opacity:60%">❤️ liked music <strong>' || musicname || '</string> by '|| singer_name ||'❤️</p>'
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
-- Data for Name: albumcomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumcomments (id, album_id, user_id, text, "time") FROM stdin;
\.
COPY public.albumcomments (id, album_id, user_id, text, "time") FROM '$$PATH$$/5038.dat';

--
-- Data for Name: albumlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumlikes (album_id, user_id) FROM stdin;
\.
COPY public.albumlikes (album_id, user_id) FROM '$$PATH$$/5057.dat';

--
-- Data for Name: albums; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albums (id, singer_id, name) FROM stdin;
\.
COPY public.albums (id, singer_id, name) FROM '$$PATH$$/5040.dat';

--
-- Data for Name: concerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.concerts (id, singer_id, price, date, has_suspended) FROM stdin;
\.
COPY public.concerts (id, singer_id, price, date, has_suspended) FROM '$$PATH$$/5042.dat';

--
-- Data for Name: favoritemusics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoritemusics (id, music_id, user_id) FROM stdin;
\.
COPY public.favoritemusics (id, music_id, user_id) FROM '$$PATH$$/5044.dat';

--
-- Data for Name: favoriteplaylists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoriteplaylists (id, playlist_id, user_id) FROM stdin;
\.
COPY public.favoriteplaylists (id, playlist_id, user_id) FROM '$$PATH$$/5046.dat';

--
-- Data for Name: followers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.followers (follower_id, user_id) FROM stdin;
\.
COPY public.followers (follower_id, user_id) FROM '$$PATH$$/5047.dat';

--
-- Data for Name: friendrequests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friendrequests (sender_id, reciever_id, accepted) FROM stdin;
\.
COPY public.friendrequests (sender_id, reciever_id, accepted) FROM '$$PATH$$/5048.dat';

--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, sender_id, reciever_id, text, "time") FROM stdin;
\.
COPY public.messages (id, sender_id, reciever_id, text, "time") FROM '$$PATH$$/5068.dat';

--
-- Data for Name: musiccomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiccomments (id, music_id, user_id, text, "time") FROM stdin;
\.
COPY public.musiccomments (id, music_id, user_id, text, "time") FROM '$$PATH$$/5050.dat';

--
-- Data for Name: musiclikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiclikes (music_id, user_id) FROM stdin;
\.
COPY public.musiclikes (music_id, user_id) FROM '$$PATH$$/5051.dat';

--
-- Data for Name: musics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text, audio_url) FROM stdin;
\.
COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text, audio_url) FROM '$$PATH$$/5053.dat';

--
-- Data for Name: playlist_music; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlist_music (music_id, playlist_id) FROM stdin;
\.
COPY public.playlist_music (music_id, playlist_id) FROM '$$PATH$$/5065.dat';

--
-- Data for Name: playlistcomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistcomments (id, playlist_id, user_id, text, "time") FROM stdin;
\.
COPY public.playlistcomments (id, playlist_id, user_id, text, "time") FROM '$$PATH$$/5055.dat';

--
-- Data for Name: playlistlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistlikes (playlist_id, user_id) FROM stdin;
\.
COPY public.playlistlikes (playlist_id, user_id) FROM '$$PATH$$/5056.dat';

--
-- Data for Name: playlists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlists (id, owner_id, is_public, name) FROM stdin;
\.
COPY public.playlists (id, owner_id, is_public, name) FROM '$$PATH$$/5059.dat';

--
-- Data for Name: predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.predictions (user_id, music_id, rank) FROM stdin;
\.
COPY public.predictions (user_id, music_id, rank) FROM '$$PATH$$/5066.dat';

--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test (message) FROM stdin;
\.
COPY public.test (message) FROM '$$PATH$$/5060.dat';

--
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket (id, user_id, concert_id, purchase_date) FROM stdin;
\.
COPY public.ticket (id, user_id, concert_id, purchase_date) FROM '$$PATH$$/5064.dat';

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password, image_url) FROM stdin;
\.
COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password, image_url) FROM '$$PATH$$/5062.dat';

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

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                