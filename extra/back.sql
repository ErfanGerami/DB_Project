toc.dat                                                                                             0000600 0004000 0002000 00000161056 14643571706 0014465 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP   
                     |            ballmer_peak    16.2    16.3 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false         �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false         �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false         �           1262    41870    ballmer_peak    DATABASE     �   CREATE DATABASE ballmer_peak WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE ballmer_peak;
                postgres    false         �           0    0    DATABASE ballmer_peak    ACL     4   GRANT ALL ON DATABASE ballmer_peak TO ballmer_peak;
                   postgres    false    5058                    1255    51168    get_interactions()    FUNCTION     ~  CREATE FUNCTION public.get_interactions() RETURNS TABLE(__id integer, _mid integer, _sid integer, _genre character varying, inter bigint)
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
       public          postgres    false                    1255    51185    get_predictions(integer)    FUNCTION     �  CREATE FUNCTION public.get_predictions(_user_id integer) RETURNS TABLE(image_url character varying, name character varying, singer_id integer, music_id integer, rank integer)
    LANGUAGE plpgsql
    AS $$begin
return query
with base_predictions as (select musics.image_url,musics.name,albums.singer_id,musics.id as _music_id,predictions.rank as music_id from predictions,musics,albums
where predictions.music_id=musics.id and album_id=albums.id and predictions.user_id=_user_id)

 
 select * from(
	 select * from base_predictions
	 union 
	 (select musics.image_url,musics.name,albums.singer_id,musics.id,-1 as rank 
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
       public          postgres    false                    1255    51189    get_users_playlists(integer)    FUNCTION       CREATE FUNCTION public.get_users_playlists(user_id integer) RETURNS TABLE(id integer, owner_id integer, is_public boolean, image_url character varying)
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
        ) AS image_url
    FROM playlists
    WHERE playlists.owner_id = user_id;
END;
$$;
 ;   DROP FUNCTION public.get_users_playlists(user_id integer);
       public          postgres    false         �            1259    50881    albumcomment    TABLE     x   CREATE TABLE public.albumcomment (
    id integer NOT NULL,
    album_id integer,
    user_id integer,
    text text
);
     DROP TABLE public.albumcomment;
       public         heap    postgres    false         �           0    0    TABLE albumcomment    ACL     8   GRANT ALL ON TABLE public.albumcomment TO ballmer_peak;
          public          postgres    false    216         �            1259    50880    albumcomment_id_seq    SEQUENCE     �   CREATE SEQUENCE public.albumcomment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.albumcomment_id_seq;
       public          postgres    false    216         �           0    0    albumcomment_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.albumcomment_id_seq OWNED BY public.albumcomment.id;
          public          postgres    false    215         �           0    0    SEQUENCE albumcomment_id_seq    ACL     B   GRANT ALL ON SEQUENCE public.albumcomment_id_seq TO ballmer_peak;
          public          postgres    false    215         �            1259    50950 
   albumlikes    TABLE     g   CREATE TABLE public.albumlikes (
    id integer NOT NULL,
    album_id integer,
    user_id integer
);
    DROP TABLE public.albumlikes;
       public         heap    postgres    false         �           0    0    TABLE albumlikes    ACL     6   GRANT ALL ON TABLE public.albumlikes TO ballmer_peak;
          public          postgres    false    238         �            1259    50949    albumlikes_id_seq    SEQUENCE     �   CREATE SEQUENCE public.albumlikes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.albumlikes_id_seq;
       public          postgres    false    238         �           0    0    albumlikes_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.albumlikes_id_seq OWNED BY public.albumlikes.id;
          public          postgres    false    237         �           0    0    SEQUENCE albumlikes_id_seq    ACL     @   GRANT ALL ON SEQUENCE public.albumlikes_id_seq TO ballmer_peak;
          public          postgres    false    237         �            1259    50888    albums    TABLE     p   CREATE TABLE public.albums (
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
          public          postgres    false    226         �            1259    50916    musiccomments    TABLE     y   CREATE TABLE public.musiccomments (
    id integer NOT NULL,
    music_id integer,
    user_id integer,
    text text
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
   musiclikes    TABLE     g   CREATE TABLE public.musiclikes (
    id integer NOT NULL,
    music_id integer,
    user_id integer
);
    DROP TABLE public.musiclikes;
       public         heap    postgres    false         �           0    0    TABLE musiclikes    ACL     6   GRANT ALL ON TABLE public.musiclikes TO ballmer_peak;
          public          postgres    false    230         �            1259    50922    musicllikes_id_seq    SEQUENCE     �   CREATE SEQUENCE public.musicllikes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.musicllikes_id_seq;
       public          postgres    false    230         �           0    0    musicllikes_id_seq    SEQUENCE OWNED BY     H   ALTER SEQUENCE public.musicllikes_id_seq OWNED BY public.musiclikes.id;
          public          postgres    false    229         �           0    0    SEQUENCE musicllikes_id_seq    ACL     A   GRANT ALL ON SEQUENCE public.musicllikes_id_seq TO ballmer_peak;
          public          postgres    false    229         �            1259    50928    musics    TABLE     K  CREATE TABLE public.musics (
    id integer NOT NULL,
    album_id integer,
    name character varying(100),
    genre character varying(100),
    rangeage character varying(100),
    image_url character varying(200) DEFAULT NULL::character varying,
    can_add_to_playlist boolean DEFAULT false,
    text text DEFAULT ''::text
);
    DROP TABLE public.musics;
       public         heap    postgres    false         �           0    0    TABLE musics    ACL     2   GRANT ALL ON TABLE public.musics TO ballmer_peak;
          public          postgres    false    232         �            1259    50927    musics_id_seq    SEQUENCE     �   CREATE SEQUENCE public.musics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.musics_id_seq;
       public          postgres    false    232         �           0    0    musics_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.musics_id_seq OWNED BY public.musics.id;
          public          postgres    false    231         �           0    0    SEQUENCE musics_id_seq    ACL     <   GRANT ALL ON SEQUENCE public.musics_id_seq TO ballmer_peak;
          public          postgres    false    231         �            1259    51147    playlist_music    TABLE     h   CREATE TABLE public.playlist_music (
    music_id integer NOT NULL,
    playlist_id integer NOT NULL
);
 "   DROP TABLE public.playlist_music;
       public         heap    postgres    false         �           0    0    TABLE playlist_music    ACL     :   GRANT ALL ON TABLE public.playlist_music TO ballmer_peak;
          public          postgres    false    246         �            1259    50938    playlistcomments    TABLE        CREATE TABLE public.playlistcomments (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer,
    text text
);
 $   DROP TABLE public.playlistcomments;
       public         heap    postgres    false         �           0    0    TABLE playlistcomments    ACL     <   GRANT ALL ON TABLE public.playlistcomments TO ballmer_peak;
          public          postgres    false    234         �            1259    50937    playlistcomments_id_seq    SEQUENCE     �   CREATE SEQUENCE public.playlistcomments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.playlistcomments_id_seq;
       public          postgres    false    234         �           0    0    playlistcomments_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.playlistcomments_id_seq OWNED BY public.playlistcomments.id;
          public          postgres    false    233         �           0    0     SEQUENCE playlistcomments_id_seq    ACL     F   GRANT ALL ON SEQUENCE public.playlistcomments_id_seq TO ballmer_peak;
          public          postgres    false    233         �            1259    50945    playlistlikes    TABLE     m   CREATE TABLE public.playlistlikes (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer
);
 !   DROP TABLE public.playlistlikes;
       public         heap    postgres    false         �           0    0    TABLE playlistlikes    ACL     9   GRANT ALL ON TABLE public.playlistlikes TO ballmer_peak;
          public          postgres    false    236         �            1259    50944    playlistlikes_id_seq    SEQUENCE     �   CREATE SEQUENCE public.playlistlikes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.playlistlikes_id_seq;
       public          postgres    false    236         �           0    0    playlistlikes_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.playlistlikes_id_seq OWNED BY public.playlistlikes.id;
          public          postgres    false    235         �           0    0    SEQUENCE playlistlikes_id_seq    ACL     C   GRANT ALL ON SEQUENCE public.playlistlikes_id_seq TO ballmer_peak;
          public          postgres    false    235         �            1259    50955 	   playlists    TABLE     �   CREATE TABLE public.playlists (
    id integer NOT NULL,
    owner_id integer,
    is_public boolean DEFAULT true,
    name character varying(100)
);
    DROP TABLE public.playlists;
       public         heap    postgres    false         �           0    0    TABLE playlists    ACL     5   GRANT ALL ON TABLE public.playlists TO ballmer_peak;
          public          postgres    false    240         �            1259    50954    playlists_id_seq    SEQUENCE     �   CREATE SEQUENCE public.playlists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.playlists_id_seq;
       public          postgres    false    240         �           0    0    playlists_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.playlists_id_seq OWNED BY public.playlists.id;
          public          postgres    false    239         �           0    0    SEQUENCE playlists_id_seq    ACL     ?   GRANT ALL ON SEQUENCE public.playlists_id_seq TO ballmer_peak;
          public          postgres    false    239         �            1259    51169    predictions    TABLE     |   CREATE TABLE public.predictions (
    user_id integer NOT NULL,
    music_id integer NOT NULL,
    rank integer NOT NULL
);
    DROP TABLE public.predictions;
       public         heap    postgres    false         �           0    0    TABLE predictions    ACL     7   GRANT ALL ON TABLE public.predictions TO ballmer_peak;
          public          postgres    false    247         �            1259    50960    test    TABLE     J   CREATE TABLE public.test (
    message character varying(100) NOT NULL
);
    DROP TABLE public.test;
       public         heap    postgres    false         �           0    0 
   TABLE test    ACL     0   GRANT ALL ON TABLE public.test TO ballmer_peak;
          public          postgres    false    241         �            1259    50972    ticket    TABLE     �   CREATE TABLE public.ticket (
    id integer NOT NULL,
    user_id integer NOT NULL,
    concert_id integer NOT NULL,
    purchase_date date
);
    DROP TABLE public.ticket;
       public         heap    postgres    false         �           0    0    TABLE ticket    ACL     2   GRANT ALL ON TABLE public.ticket TO ballmer_peak;
          public          postgres    false    245         �            1259    50971    ticket_id_seq    SEQUENCE     �   CREATE SEQUENCE public.ticket_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.ticket_id_seq;
       public          postgres    false    245         �           0    0    ticket_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.ticket_id_seq OWNED BY public.ticket.id;
          public          postgres    false    244         �           0    0    SEQUENCE ticket_id_seq    ACL     <   GRANT ALL ON SEQUENCE public.ticket_id_seq TO ballmer_peak;
          public          postgres    false    244         �            1259    50964    users    TABLE     F  CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(100),
    email character varying(100),
    birthdate date,
    address character varying(100),
    has_membership boolean DEFAULT false,
    money bigint DEFAULT 0,
    is_singer boolean DEFAULT false,
    password character varying(260)
);
    DROP TABLE public.users;
       public         heap    postgres    false         �           0    0    TABLE users    ACL     C   GRANT ALL ON TABLE public.users TO ballmer_peak WITH GRANT OPTION;
          public          postgres    false    243         �            1259    50963    users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.users_id_seq;
       public          postgres    false    243         �           0    0    users_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
          public          postgres    false    242         �           0    0    SEQUENCE users_id_seq    ACL     ;   GRANT ALL ON SEQUENCE public.users_id_seq TO ballmer_peak;
          public          postgres    false    242         �           2604    50884    albumcomment id    DEFAULT     r   ALTER TABLE ONLY public.albumcomment ALTER COLUMN id SET DEFAULT nextval('public.albumcomment_id_seq'::regclass);
 >   ALTER TABLE public.albumcomment ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    216    215    216         �           2604    50953    albumlikes id    DEFAULT     n   ALTER TABLE ONLY public.albumlikes ALTER COLUMN id SET DEFAULT nextval('public.albumlikes_id_seq'::regclass);
 <   ALTER TABLE public.albumlikes ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    238    237    238         �           2604    50891 	   albums id    DEFAULT     f   ALTER TABLE ONLY public.albums ALTER COLUMN id SET DEFAULT nextval('public.albums_id_seq'::regclass);
 8   ALTER TABLE public.albums ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    217    218         �           2604    50896    concerts id    DEFAULT     j   ALTER TABLE ONLY public.concerts ALTER COLUMN id SET DEFAULT nextval('public.concerts_id_seq'::regclass);
 :   ALTER TABLE public.concerts ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    220    219    220         �           2604    50902    favoritemusics id    DEFAULT     v   ALTER TABLE ONLY public.favoritemusics ALTER COLUMN id SET DEFAULT nextval('public.favoritemusics_id_seq'::regclass);
 @   ALTER TABLE public.favoritemusics ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    222    221    222         �           2604    50907    favoriteplaylists id    DEFAULT     |   ALTER TABLE ONLY public.favoriteplaylists ALTER COLUMN id SET DEFAULT nextval('public.favoriteplaylists_id_seq'::regclass);
 C   ALTER TABLE public.favoriteplaylists ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    223    224    224         �           2604    50919    musiccomments id    DEFAULT     t   ALTER TABLE ONLY public.musiccomments ALTER COLUMN id SET DEFAULT nextval('public.musiccomments_id_seq'::regclass);
 ?   ALTER TABLE public.musiccomments ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    228    227    228         �           2604    50926    musiclikes id    DEFAULT     o   ALTER TABLE ONLY public.musiclikes ALTER COLUMN id SET DEFAULT nextval('public.musicllikes_id_seq'::regclass);
 <   ALTER TABLE public.musiclikes ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    229    230    230         �           2604    50931 	   musics id    DEFAULT     f   ALTER TABLE ONLY public.musics ALTER COLUMN id SET DEFAULT nextval('public.musics_id_seq'::regclass);
 8   ALTER TABLE public.musics ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    231    232    232         �           2604    50941    playlistcomments id    DEFAULT     z   ALTER TABLE ONLY public.playlistcomments ALTER COLUMN id SET DEFAULT nextval('public.playlistcomments_id_seq'::regclass);
 B   ALTER TABLE public.playlistcomments ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    233    234    234         �           2604    50948    playlistlikes id    DEFAULT     t   ALTER TABLE ONLY public.playlistlikes ALTER COLUMN id SET DEFAULT nextval('public.playlistlikes_id_seq'::regclass);
 ?   ALTER TABLE public.playlistlikes ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    236    235    236         �           2604    50958    playlists id    DEFAULT     l   ALTER TABLE ONLY public.playlists ALTER COLUMN id SET DEFAULT nextval('public.playlists_id_seq'::regclass);
 ;   ALTER TABLE public.playlists ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    240    239    240         �           2604    50975 	   ticket id    DEFAULT     f   ALTER TABLE ONLY public.ticket ALTER COLUMN id SET DEFAULT nextval('public.ticket_id_seq'::regclass);
 8   ALTER TABLE public.ticket ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    245    244    245         �           2604    50967    users id    DEFAULT     d   ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
 7   ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    243    242    243         �          0    50881    albumcomment 
   TABLE DATA           C   COPY public.albumcomment (id, album_id, user_id, text) FROM stdin;
    public          postgres    false    216       5021.dat �          0    50950 
   albumlikes 
   TABLE DATA           ;   COPY public.albumlikes (id, album_id, user_id) FROM stdin;
    public          postgres    false    238       5043.dat �          0    50888    albums 
   TABLE DATA           5   COPY public.albums (id, singer_id, name) FROM stdin;
    public          postgres    false    218       5023.dat �          0    50893    concerts 
   TABLE DATA           M   COPY public.concerts (id, singer_id, price, date, has_suspended) FROM stdin;
    public          postgres    false    220       5025.dat �          0    50899    favoritemusics 
   TABLE DATA           ?   COPY public.favoritemusics (id, music_id, user_id) FROM stdin;
    public          postgres    false    222       5027.dat �          0    50904    favoriteplaylists 
   TABLE DATA           E   COPY public.favoriteplaylists (id, playlist_id, user_id) FROM stdin;
    public          postgres    false    224       5029.dat �          0    50908 	   followers 
   TABLE DATA           9   COPY public.followers (follower_id, user_id) FROM stdin;
    public          postgres    false    225       5030.dat �          0    50911    friendrequests 
   TABLE DATA           J   COPY public.friendrequests (sender_id, reciever_id, accepted) FROM stdin;
    public          postgres    false    226       5031.dat �          0    50916    musiccomments 
   TABLE DATA           D   COPY public.musiccomments (id, music_id, user_id, text) FROM stdin;
    public          postgres    false    228       5033.dat �          0    50923 
   musiclikes 
   TABLE DATA           ;   COPY public.musiclikes (id, music_id, user_id) FROM stdin;
    public          postgres    false    230       5035.dat �          0    50928    musics 
   TABLE DATA           k   COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text) FROM stdin;
    public          postgres    false    232       5037.dat �          0    51147    playlist_music 
   TABLE DATA           ?   COPY public.playlist_music (music_id, playlist_id) FROM stdin;
    public          postgres    false    246       5051.dat �          0    50938    playlistcomments 
   TABLE DATA           J   COPY public.playlistcomments (id, playlist_id, user_id, text) FROM stdin;
    public          postgres    false    234       5039.dat �          0    50945    playlistlikes 
   TABLE DATA           A   COPY public.playlistlikes (id, playlist_id, user_id) FROM stdin;
    public          postgres    false    236       5041.dat �          0    50955 	   playlists 
   TABLE DATA           B   COPY public.playlists (id, owner_id, is_public, name) FROM stdin;
    public          postgres    false    240       5045.dat �          0    51169    predictions 
   TABLE DATA           >   COPY public.predictions (user_id, music_id, rank) FROM stdin;
    public          postgres    false    247       5052.dat �          0    50960    test 
   TABLE DATA           '   COPY public.test (message) FROM stdin;
    public          postgres    false    241       5046.dat �          0    50972    ticket 
   TABLE DATA           H   COPY public.ticket (id, user_id, concert_id, purchase_date) FROM stdin;
    public          postgres    false    245       5050.dat �          0    50964    users 
   TABLE DATA           t   COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password) FROM stdin;
    public          postgres    false    243       5048.dat �           0    0    albumcomment_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.albumcomment_id_seq', 1, false);
          public          postgres    false    215         �           0    0    albumlikes_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.albumlikes_id_seq', 1, false);
          public          postgres    false    237         �           0    0    albums_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.albums_id_seq', 8, true);
          public          postgres    false    217         �           0    0    concerts_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.concerts_id_seq', 1, false);
          public          postgres    false    219         �           0    0    favoritemusics_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.favoritemusics_id_seq', 1, false);
          public          postgres    false    221         �           0    0    favoriteplaylists_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.favoriteplaylists_id_seq', 1, false);
          public          postgres    false    223         �           0    0    musiccomments_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.musiccomments_id_seq', 1, false);
          public          postgres    false    227         �           0    0    musicllikes_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.musicllikes_id_seq', 1, false);
          public          postgres    false    229         �           0    0    musics_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.musics_id_seq', 1, false);
          public          postgres    false    231         �           0    0    playlistcomments_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.playlistcomments_id_seq', 1, false);
          public          postgres    false    233         �           0    0    playlistlikes_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.playlistlikes_id_seq', 1, false);
          public          postgres    false    235         �           0    0    playlists_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.playlists_id_seq', 10, true);
          public          postgres    false    239         �           0    0    ticket_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.ticket_id_seq', 1, false);
          public          postgres    false    244                     0    0    users_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.users_id_seq', 22, true);
          public          postgres    false    242         �           2606    50977    albumcomment albumcomment_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.albumcomment DROP CONSTRAINT albumcomment_pkey;
       public            postgres    false    216         �           2606    50979    albumlikes albumlikes_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT albumlikes_pkey;
       public            postgres    false    238         �           2606    50981    albums albums_pkey 
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
       public            postgres    false    226    226         �           2606    50993     musiccomments musiccomments_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_pkey;
       public            postgres    false    228         �           2606    50995    musiclikes musicllikes_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT musicllikes_pkey;
       public            postgres    false    230         �           2606    50997    musics musics_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.musics DROP CONSTRAINT musics_pkey;
       public            postgres    false    232         �           2606    51151 "   playlist_music playlist_music_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_pkey PRIMARY KEY (music_id, playlist_id);
 L   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_pkey;
       public            postgres    false    246    246         �           2606    50999 &   playlistcomments playlistcomments_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_pkey;
       public            postgres    false    234         �           2606    51001    playlistlikes playlistlike_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT playlistlike_pkey;
       public            postgres    false    236         �           2606    51003    playlists playlists_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.playlists DROP CONSTRAINT playlists_pkey;
       public            postgres    false    240         �           2606    51173    predictions predictions_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_pkey PRIMARY KEY (user_id, music_id, rank);
 F   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_pkey;
       public            postgres    false    247    247    247         �           2606    51005    test test_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (message);
 8   ALTER TABLE ONLY public.test DROP CONSTRAINT test_pkey;
       public            postgres    false    241         �           2606    51007    ticket ticket_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_pkey;
       public            postgres    false    245         �           2606    51146    users unique_email 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_email UNIQUE (email);
 <   ALTER TABLE ONLY public.users DROP CONSTRAINT unique_email;
       public            postgres    false    243         �           2606    51191    albums unique_name 
   CONSTRAINT     M   ALTER TABLE ONLY public.albums
    ADD CONSTRAINT unique_name UNIQUE (name);
 <   ALTER TABLE ONLY public.albums DROP CONSTRAINT unique_name;
       public            postgres    false    218         �           2606    51187 #   playlists unique_name_for_each_user 
   CONSTRAINT     h   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT unique_name_for_each_user UNIQUE (owner_id, name);
 M   ALTER TABLE ONLY public.playlists DROP CONSTRAINT unique_name_for_each_user;
       public            postgres    false    240    240         �           2606    51144    users unique_username 
   CONSTRAINT     T   ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_username UNIQUE (username);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT unique_username;
       public            postgres    false    243         �           2606    51009    users users_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public            postgres    false    243         �           2606    51010 '   albumcomment albumcomment_album_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.albumcomment DROP CONSTRAINT albumcomment_album_id_fkey;
       public          postgres    false    218    216    4804         �           2606    51015 &   albumcomment albumcomment_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 P   ALTER TABLE ONLY public.albumcomment DROP CONSTRAINT albumcomment_user_id_fkey;
       public          postgres    false    243    4840    216                    2606    51020 #   albumlikes albumlikes_album_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 M   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT albumlikes_album_id_fkey;
       public          postgres    false    238    4804    218                    2606    51025 "   albumlikes albumlikes_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 L   ALTER TABLE ONLY public.albumlikes DROP CONSTRAINT albumlikes_user_id_fkey;
       public          postgres    false    238    4840    243         �           2606    51030    albums albums_singer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.albums DROP CONSTRAINT albums_singer_id_fkey;
       public          postgres    false    4840    218    243         �           2606    51035    concerts concert_singer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 I   ALTER TABLE ONLY public.concerts DROP CONSTRAINT concert_singer_id_fkey;
       public          postgres    false    220    4840    243         �           2606    51040 +   favoritemusics favoritemusics_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.favoritemusics DROP CONSTRAINT favoritemusics_music_id_fkey;
       public          postgres    false    232    222    4822         �           2606    51045 *   favoritemusics favoritemusics_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 T   ALTER TABLE ONLY public.favoritemusics DROP CONSTRAINT favoritemusics_user_id_fkey;
       public          postgres    false    243    4840    222         �           2606    51050 4   favoriteplaylists favoriteplaylists_playlist_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 ^   ALTER TABLE ONLY public.favoriteplaylists DROP CONSTRAINT favoriteplaylists_playlist_id_fkey;
       public          postgres    false    4830    240    224         �           2606    51055 0   favoriteplaylists favoriteplaylists_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.favoriteplaylists DROP CONSTRAINT favoriteplaylists_user_id_fkey;
       public          postgres    false    4840    243    224         �           2606    51060 $   followers followers_follower_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.followers DROP CONSTRAINT followers_follower_id_fkey;
       public          postgres    false    4840    225    243         �           2606    51065     followers followers_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 J   ALTER TABLE ONLY public.followers DROP CONSTRAINT followers_user_id_fkey;
       public          postgres    false    243    4840    225         �           2606    51070 .   friendrequests friendrequests_reciever_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.friendrequests DROP CONSTRAINT friendrequests_reciever_id_fkey;
       public          postgres    false    243    226    4840         �           2606    51075 ,   friendrequests friendrequests_sender_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.friendrequests DROP CONSTRAINT friendrequests_sender_id_fkey;
       public          postgres    false    226    243    4840         �           2606    51080 )   musiccomments musiccomments_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_music_id_fkey;
       public          postgres    false    232    4822    228         �           2606    51085 (   musiccomments musiccomments_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.musiccomments DROP CONSTRAINT musiccomments_user_id_fkey;
       public          postgres    false    4840    243    228         �           2606    51090 $   musiclikes musicllikes_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT musicllikes_music_id_fkey;
       public          postgres    false    230    4822    232         �           2606    51095 #   musiclikes musicllikes_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 M   ALTER TABLE ONLY public.musiclikes DROP CONSTRAINT musicllikes_user_id_fkey;
       public          postgres    false    230    243    4840         �           2606    51100    musics musics_album_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;
 E   ALTER TABLE ONLY public.musics DROP CONSTRAINT musics_album_id_fkey;
       public          postgres    false    218    232    4804         	           2606    51152 +   playlist_music playlist_music_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_music_id_fkey;
       public          postgres    false    4822    232    246         
           2606    51157 .   playlist_music playlist_music_playlist_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.playlist_music DROP CONSTRAINT playlist_music_playlist_id_fkey;
       public          postgres    false    240    4830    246                     2606    51105 2   playlistcomments playlistcomments_playlist_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 \   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_playlist_id_fkey;
       public          postgres    false    4830    240    234                    2606    51110 .   playlistcomments playlistcomments_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.playlistcomments DROP CONSTRAINT playlistcomments_user_id_fkey;
       public          postgres    false    4840    234    243                    2606    51115 +   playlistlikes playlistlike_playlist_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT playlistlike_playlist_id_fkey;
       public          postgres    false    240    236    4830                    2606    51120 '   playlistlikes playlistlike_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.playlistlikes DROP CONSTRAINT playlistlike_user_id_fkey;
       public          postgres    false    4840    236    243                    2606    51125 !   playlists playlists_owner_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.playlists DROP CONSTRAINT playlists_owner_id_fkey;
       public          postgres    false    240    4840    243                    2606    51179 %   predictions predictions_music_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id);
 O   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_music_id_fkey;
       public          postgres    false    247    4822    232                    2606    51174 $   predictions predictions_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
 N   ALTER TABLE ONLY public.predictions DROP CONSTRAINT predictions_user_id_fkey;
       public          postgres    false    4840    247    243                    2606    51130    ticket ticket_concert_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_concert_id_fkey FOREIGN KEY (concert_id) REFERENCES public.concerts(id) ON UPDATE CASCADE ON DELETE CASCADE;
 G   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_concert_id_fkey;
       public          postgres    false    245    220    4808                    2606    51135    ticket ticket_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.ticket DROP CONSTRAINT ticket_user_id_fkey;
       public          postgres    false    4840    243    245                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          5021.dat                                                                                            0000600 0004000 0002000 00000000047 14643571706 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Great album!
2	2	2	Not bad.
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         5043.dat                                                                                            0000600 0004000 0002000 00000000021 14643571706 0014253 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
2	2	2
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               5023.dat                                                                                            0000600 0004000 0002000 00000000066 14643571706 0014262 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	Album A
2	2	Album B
6	22	some alb1
8	22	name
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                          5025.dat                                                                                            0000600 0004000 0002000 00000000061 14643571706 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	1000	2023-01-01	f
2	2	2000	2023-02-01	t
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                               5027.dat                                                                                            0000600 0004000 0002000 00000000027 14643571706 0014263 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
2	2	2
3	1	2
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         5029.dat                                                                                            0000600 0004000 0002000 00000000013 14643571706 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     5030.dat                                                                                            0000600 0004000 0002000 00000000015 14643571706 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2
2	1
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   5031.dat                                                                                            0000600 0004000 0002000 00000000021 14643571706 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2	f
2	1	t
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               5033.dat                                                                                            0000600 0004000 0002000 00000000055 14643571706 0014261 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Love this song!
2	2	2	Nice track.
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   5035.dat                                                                                            0000600 0004000 0002000 00000000021 14643571706 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
2	2	2
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               5037.dat                                                                                            0000600 0004000 0002000 00000001117 14643571706 0014265 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	Song A	Pop	All	/path/to/image1.jpg	t	Lyrics for Song A
2	2	Song B	Rock	18+	/path/to/image2.jpg	f	Lyrics for Song B
4	1	some music	Pop	13to18	/path/	t	some text
5	1	name	Pop	13to19	\N	f	some text
6	1	name	Pop	13to19	\N	f	some text
7	1	name	Pop	13to19	\N	f	some text
8	1	name	Pop	13to19	\N	f	some text
9	1	name	Pop	13to19	\N	f	some text
10	1	name	Pop	13to19	\N	f	some text
11	1	name	Pop	13to19	\N	f	some text
12	1	name	Pop	13to19	\N	f	some text
13	1	name	Pop	13to19	\N	f	some text
14	1	name	Pop	13to19	\N	f	some text
15	1	name	Pop	13to19	\N	f	some text
16	1	dwde	wde	wdewd	\N	t	wedew
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                 5051.dat                                                                                            0000600 0004000 0002000 00000000022 14643571706 0014253 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	1
2	10
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              5039.dat                                                                                            0000600 0004000 0002000 00000000033 14643571706 0014263 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1	Great playlist!
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     5041.dat                                                                                            0000600 0004000 0002000 00000000013 14643571706 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     5045.dat                                                                                            0000600 0004000 0002000 00000000105 14643571706 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	t	name1\n
6	22	t	name3
8	1	t	name3
9	22	t	None
10	22	t	name
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                           5052.dat                                                                                            0000600 0004000 0002000 00000000035 14643571706 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	1
1	2	2
2	2	1
2	1	2
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   5046.dat                                                                                            0000600 0004000 0002000 00000000005 14643571706 0014260 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5050.dat                                                                                            0000600 0004000 0002000 00000000005 14643571706 0014253 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5048.dat                                                                                            0000600 0004000 0002000 00000001517 14643571706 0014273 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        12	salam2222	test@test2.com222	2003-04-09	some adr	f	0	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
2	User One	user1@example.com	1990-01-01	123 Main St	t	1000	f	\N
3	User Two	user2@example.com	1985-05-15	456 Elm St	f	500	t	\N
13	salam	salam@salam.com	2003-02-02	addr	f	0	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
19	salam2	salam@salam.com2	2003-02-02	addr	f	0	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
21	saalam2	salam@salamq.com2	2003-02-02	addr	f	0	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
22	sa1alam2	salam@1salamq.com2	2003-02-02	addr	t	0	t	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
1	ErfanG	e.geramizadeh13821359@gmail.com	2003-04-09	some addrr	t	0	f	0582bd2c13fff71d7f40ef5586e3f4da05a3a61fe5ba9f0b4d06e99905ab83ea
\.


                                                                                                                                                                                 restore.sql                                                                                         0000600 0004000 0002000 00000126701 14643571706 0015410 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
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

CREATE FUNCTION public.get_predictions(_user_id integer) RETURNS TABLE(image_url character varying, name character varying, singer_id integer, music_id integer, rank integer)
    LANGUAGE plpgsql
    AS $$begin
return query
with base_predictions as (select musics.image_url,musics.name,albums.singer_id,musics.id as _music_id,predictions.rank as music_id from predictions,musics,albums
where predictions.music_id=musics.id and album_id=albums.id and predictions.user_id=_user_id)

 
 select * from(
	 select * from base_predictions
	 union 
	 (select musics.image_url,musics.name,albums.singer_id,musics.id,-1 as rank 
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

CREATE FUNCTION public.get_users_playlists(user_id integer) RETURNS TABLE(id integer, owner_id integer, is_public boolean, image_url character varying)
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
        ) AS image_url
    FROM playlists
    WHERE playlists.owner_id = user_id;
END;
$$;


ALTER FUNCTION public.get_users_playlists(user_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: albumcomment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albumcomment (
    id integer NOT NULL,
    album_id integer,
    user_id integer,
    text text
);


ALTER TABLE public.albumcomment OWNER TO postgres;

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

ALTER SEQUENCE public.albumcomment_id_seq OWNED BY public.albumcomment.id;


--
-- Name: albumlikes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albumlikes (
    id integer NOT NULL,
    album_id integer,
    user_id integer
);


ALTER TABLE public.albumlikes OWNER TO postgres;

--
-- Name: albumlikes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.albumlikes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.albumlikes_id_seq OWNER TO postgres;

--
-- Name: albumlikes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.albumlikes_id_seq OWNED BY public.albumlikes.id;


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
-- Name: musiccomments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.musiccomments (
    id integer NOT NULL,
    music_id integer,
    user_id integer,
    text text
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
    id integer NOT NULL,
    music_id integer,
    user_id integer
);


ALTER TABLE public.musiclikes OWNER TO postgres;

--
-- Name: musicllikes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.musicllikes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.musicllikes_id_seq OWNER TO postgres;

--
-- Name: musicllikes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musicllikes_id_seq OWNED BY public.musiclikes.id;


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
    text text DEFAULT ''::text
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
    text text
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
    id integer NOT NULL,
    playlist_id integer,
    user_id integer
);


ALTER TABLE public.playlistlikes OWNER TO postgres;

--
-- Name: playlistlikes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.playlistlikes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.playlistlikes_id_seq OWNER TO postgres;

--
-- Name: playlistlikes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.playlistlikes_id_seq OWNED BY public.playlistlikes.id;


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
    password character varying(260)
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
-- Name: albumcomment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment ALTER COLUMN id SET DEFAULT nextval('public.albumcomment_id_seq'::regclass);


--
-- Name: albumlikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes ALTER COLUMN id SET DEFAULT nextval('public.albumlikes_id_seq'::regclass);


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
-- Name: musiccomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments ALTER COLUMN id SET DEFAULT nextval('public.musiccomments_id_seq'::regclass);


--
-- Name: musiclikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes ALTER COLUMN id SET DEFAULT nextval('public.musicllikes_id_seq'::regclass);


--
-- Name: musics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics ALTER COLUMN id SET DEFAULT nextval('public.musics_id_seq'::regclass);


--
-- Name: playlistcomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments ALTER COLUMN id SET DEFAULT nextval('public.playlistcomments_id_seq'::regclass);


--
-- Name: playlistlikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes ALTER COLUMN id SET DEFAULT nextval('public.playlistlikes_id_seq'::regclass);


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
-- Data for Name: albumcomment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumcomment (id, album_id, user_id, text) FROM stdin;
\.
COPY public.albumcomment (id, album_id, user_id, text) FROM '$$PATH$$/5021.dat';

--
-- Data for Name: albumlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumlikes (id, album_id, user_id) FROM stdin;
\.
COPY public.albumlikes (id, album_id, user_id) FROM '$$PATH$$/5043.dat';

--
-- Data for Name: albums; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albums (id, singer_id, name) FROM stdin;
\.
COPY public.albums (id, singer_id, name) FROM '$$PATH$$/5023.dat';

--
-- Data for Name: concerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.concerts (id, singer_id, price, date, has_suspended) FROM stdin;
\.
COPY public.concerts (id, singer_id, price, date, has_suspended) FROM '$$PATH$$/5025.dat';

--
-- Data for Name: favoritemusics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoritemusics (id, music_id, user_id) FROM stdin;
\.
COPY public.favoritemusics (id, music_id, user_id) FROM '$$PATH$$/5027.dat';

--
-- Data for Name: favoriteplaylists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoriteplaylists (id, playlist_id, user_id) FROM stdin;
\.
COPY public.favoriteplaylists (id, playlist_id, user_id) FROM '$$PATH$$/5029.dat';

--
-- Data for Name: followers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.followers (follower_id, user_id) FROM stdin;
\.
COPY public.followers (follower_id, user_id) FROM '$$PATH$$/5030.dat';

--
-- Data for Name: friendrequests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friendrequests (sender_id, reciever_id, accepted) FROM stdin;
\.
COPY public.friendrequests (sender_id, reciever_id, accepted) FROM '$$PATH$$/5031.dat';

--
-- Data for Name: musiccomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiccomments (id, music_id, user_id, text) FROM stdin;
\.
COPY public.musiccomments (id, music_id, user_id, text) FROM '$$PATH$$/5033.dat';

--
-- Data for Name: musiclikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiclikes (id, music_id, user_id) FROM stdin;
\.
COPY public.musiclikes (id, music_id, user_id) FROM '$$PATH$$/5035.dat';

--
-- Data for Name: musics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text) FROM stdin;
\.
COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text) FROM '$$PATH$$/5037.dat';

--
-- Data for Name: playlist_music; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlist_music (music_id, playlist_id) FROM stdin;
\.
COPY public.playlist_music (music_id, playlist_id) FROM '$$PATH$$/5051.dat';

--
-- Data for Name: playlistcomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistcomments (id, playlist_id, user_id, text) FROM stdin;
\.
COPY public.playlistcomments (id, playlist_id, user_id, text) FROM '$$PATH$$/5039.dat';

--
-- Data for Name: playlistlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistlikes (id, playlist_id, user_id) FROM stdin;
\.
COPY public.playlistlikes (id, playlist_id, user_id) FROM '$$PATH$$/5041.dat';

--
-- Data for Name: playlists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlists (id, owner_id, is_public, name) FROM stdin;
\.
COPY public.playlists (id, owner_id, is_public, name) FROM '$$PATH$$/5045.dat';

--
-- Data for Name: predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.predictions (user_id, music_id, rank) FROM stdin;
\.
COPY public.predictions (user_id, music_id, rank) FROM '$$PATH$$/5052.dat';

--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test (message) FROM stdin;
\.
COPY public.test (message) FROM '$$PATH$$/5046.dat';

--
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket (id, user_id, concert_id, purchase_date) FROM stdin;
\.
COPY public.ticket (id, user_id, concert_id, purchase_date) FROM '$$PATH$$/5050.dat';

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password) FROM stdin;
\.
COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password) FROM '$$PATH$$/5048.dat';

--
-- Name: albumcomment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albumcomment_id_seq', 1, false);


--
-- Name: albumlikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albumlikes_id_seq', 1, false);


--
-- Name: albums_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albums_id_seq', 8, true);


--
-- Name: concerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.concerts_id_seq', 1, false);


--
-- Name: favoritemusics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favoritemusics_id_seq', 1, false);


--
-- Name: favoriteplaylists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favoriteplaylists_id_seq', 1, false);


--
-- Name: musiccomments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musiccomments_id_seq', 1, false);


--
-- Name: musicllikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musicllikes_id_seq', 1, false);


--
-- Name: musics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musics_id_seq', 1, false);


--
-- Name: playlistcomments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlistcomments_id_seq', 1, false);


--
-- Name: playlistlikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlistlikes_id_seq', 1, false);


--
-- Name: playlists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlists_id_seq', 10, true);


--
-- Name: ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 22, true);


--
-- Name: albumcomment albumcomment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_pkey PRIMARY KEY (id);


--
-- Name: albumlikes albumlikes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_pkey PRIMARY KEY (id);


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
-- Name: musiccomments musiccomments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_pkey PRIMARY KEY (id);


--
-- Name: musiclikes musicllikes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_pkey PRIMARY KEY (id);


--
-- Name: musics musics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_pkey PRIMARY KEY (id);


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
-- Name: playlistlikes playlistlike_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_pkey PRIMARY KEY (id);


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
-- Name: albumcomment albumcomment_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: albumcomment albumcomment_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
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

GRANT ALL ON DATABASE ballmer_peak TO ballmer_peak;


--
-- Name: TABLE albumcomment; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.albumcomment TO ballmer_peak;


--
-- Name: SEQUENCE albumcomment_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.albumcomment_id_seq TO ballmer_peak;


--
-- Name: TABLE albumlikes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.albumlikes TO ballmer_peak;


--
-- Name: SEQUENCE albumlikes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.albumlikes_id_seq TO ballmer_peak;


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
-- Name: SEQUENCE musicllikes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.musicllikes_id_seq TO ballmer_peak;


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
-- Name: SEQUENCE playlistlikes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.playlistlikes_id_seq TO ballmer_peak;


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

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               