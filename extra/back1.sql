--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.3

-- Started on 2024-07-11 00:15:27

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
-- TOC entry 261 (class 1255 OID 51168)
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
-- TOC entry 248 (class 1255 OID 51163)
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
-- TOC entry 263 (class 1255 OID 51185)
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
-- TOC entry 249 (class 1255 OID 51196)
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
-- TOC entry 262 (class 1255 OID 51189)
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
-- TOC entry 216 (class 1259 OID 50881)
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
-- TOC entry 215 (class 1259 OID 50880)
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
-- TOC entry 5059 (class 0 OID 0)
-- Dependencies: 215
-- Name: albumcomment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.albumcomment_id_seq OWNED BY public.albumcomment.id;


--
-- TOC entry 238 (class 1259 OID 50950)
-- Name: albumlikes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albumlikes (
    id integer NOT NULL,
    album_id integer,
    user_id integer
);


ALTER TABLE public.albumlikes OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 50949)
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
-- TOC entry 5062 (class 0 OID 0)
-- Dependencies: 237
-- Name: albumlikes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.albumlikes_id_seq OWNED BY public.albumlikes.id;


--
-- TOC entry 218 (class 1259 OID 50888)
-- Name: albums; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albums (
    id integer NOT NULL,
    singer_id integer,
    name character varying(100)
);


ALTER TABLE public.albums OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 50887)
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
-- TOC entry 5065 (class 0 OID 0)
-- Dependencies: 217
-- Name: albums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.albums_id_seq OWNED BY public.albums.id;


--
-- TOC entry 220 (class 1259 OID 50893)
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
-- TOC entry 219 (class 1259 OID 50892)
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
-- TOC entry 5068 (class 0 OID 0)
-- Dependencies: 219
-- Name: concerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.concerts_id_seq OWNED BY public.concerts.id;


--
-- TOC entry 222 (class 1259 OID 50899)
-- Name: favoritemusics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favoritemusics (
    id integer NOT NULL,
    music_id integer,
    user_id integer
);


ALTER TABLE public.favoritemusics OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 50898)
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
-- TOC entry 5071 (class 0 OID 0)
-- Dependencies: 221
-- Name: favoritemusics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favoritemusics_id_seq OWNED BY public.favoritemusics.id;


--
-- TOC entry 224 (class 1259 OID 50904)
-- Name: favoriteplaylists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favoriteplaylists (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer
);


ALTER TABLE public.favoriteplaylists OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 50903)
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
-- TOC entry 5074 (class 0 OID 0)
-- Dependencies: 223
-- Name: favoriteplaylists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favoriteplaylists_id_seq OWNED BY public.favoriteplaylists.id;


--
-- TOC entry 225 (class 1259 OID 50908)
-- Name: followers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.followers (
    follower_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.followers OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 50911)
-- Name: friendrequests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friendrequests (
    sender_id integer NOT NULL,
    reciever_id integer NOT NULL,
    accepted boolean DEFAULT false
);


ALTER TABLE public.friendrequests OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 50916)
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
-- TOC entry 227 (class 1259 OID 50915)
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
-- TOC entry 5079 (class 0 OID 0)
-- Dependencies: 227
-- Name: musiccomments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musiccomments_id_seq OWNED BY public.musiccomments.id;


--
-- TOC entry 230 (class 1259 OID 50923)
-- Name: musiclikes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.musiclikes (
    id integer NOT NULL,
    music_id integer,
    user_id integer
);


ALTER TABLE public.musiclikes OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 50922)
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
-- TOC entry 5082 (class 0 OID 0)
-- Dependencies: 229
-- Name: musicllikes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musicllikes_id_seq OWNED BY public.musiclikes.id;


--
-- TOC entry 232 (class 1259 OID 50928)
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
-- TOC entry 231 (class 1259 OID 50927)
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
-- TOC entry 5085 (class 0 OID 0)
-- Dependencies: 231
-- Name: musics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musics_id_seq OWNED BY public.musics.id;


--
-- TOC entry 246 (class 1259 OID 51147)
-- Name: playlist_music; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.playlist_music (
    music_id integer NOT NULL,
    playlist_id integer NOT NULL
);


ALTER TABLE public.playlist_music OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 50938)
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
-- TOC entry 233 (class 1259 OID 50937)
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
-- TOC entry 5089 (class 0 OID 0)
-- Dependencies: 233
-- Name: playlistcomments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.playlistcomments_id_seq OWNED BY public.playlistcomments.id;


--
-- TOC entry 236 (class 1259 OID 50945)
-- Name: playlistlikes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.playlistlikes (
    id integer NOT NULL,
    playlist_id integer,
    user_id integer
);


ALTER TABLE public.playlistlikes OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 50944)
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
-- TOC entry 5092 (class 0 OID 0)
-- Dependencies: 235
-- Name: playlistlikes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.playlistlikes_id_seq OWNED BY public.playlistlikes.id;


--
-- TOC entry 240 (class 1259 OID 50955)
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
-- TOC entry 239 (class 1259 OID 50954)
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
-- TOC entry 5095 (class 0 OID 0)
-- Dependencies: 239
-- Name: playlists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.playlists_id_seq OWNED BY public.playlists.id;


--
-- TOC entry 247 (class 1259 OID 51169)
-- Name: predictions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.predictions (
    user_id integer NOT NULL,
    music_id integer NOT NULL,
    rank integer NOT NULL
);


ALTER TABLE public.predictions OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 50960)
-- Name: test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test (
    message character varying(100) NOT NULL
);


ALTER TABLE public.test OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 50972)
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
-- TOC entry 244 (class 1259 OID 50971)
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
-- TOC entry 5100 (class 0 OID 0)
-- Dependencies: 244
-- Name: ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ticket_id_seq OWNED BY public.ticket.id;


--
-- TOC entry 243 (class 1259 OID 50964)
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
-- TOC entry 242 (class 1259 OID 50963)
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
-- TOC entry 5103 (class 0 OID 0)
-- Dependencies: 242
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 4778 (class 2604 OID 50884)
-- Name: albumcomment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment ALTER COLUMN id SET DEFAULT nextval('public.albumcomment_id_seq'::regclass);


--
-- TOC entry 4793 (class 2604 OID 50953)
-- Name: albumlikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes ALTER COLUMN id SET DEFAULT nextval('public.albumlikes_id_seq'::regclass);


--
-- TOC entry 4779 (class 2604 OID 50891)
-- Name: albums id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums ALTER COLUMN id SET DEFAULT nextval('public.albums_id_seq'::regclass);


--
-- TOC entry 4780 (class 2604 OID 50896)
-- Name: concerts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts ALTER COLUMN id SET DEFAULT nextval('public.concerts_id_seq'::regclass);


--
-- TOC entry 4782 (class 2604 OID 50902)
-- Name: favoritemusics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics ALTER COLUMN id SET DEFAULT nextval('public.favoritemusics_id_seq'::regclass);


--
-- TOC entry 4783 (class 2604 OID 50907)
-- Name: favoriteplaylists id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists ALTER COLUMN id SET DEFAULT nextval('public.favoriteplaylists_id_seq'::regclass);


--
-- TOC entry 4785 (class 2604 OID 50919)
-- Name: musiccomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments ALTER COLUMN id SET DEFAULT nextval('public.musiccomments_id_seq'::regclass);


--
-- TOC entry 4786 (class 2604 OID 50926)
-- Name: musiclikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes ALTER COLUMN id SET DEFAULT nextval('public.musicllikes_id_seq'::regclass);


--
-- TOC entry 4787 (class 2604 OID 50931)
-- Name: musics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics ALTER COLUMN id SET DEFAULT nextval('public.musics_id_seq'::regclass);


--
-- TOC entry 4791 (class 2604 OID 50941)
-- Name: playlistcomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments ALTER COLUMN id SET DEFAULT nextval('public.playlistcomments_id_seq'::regclass);


--
-- TOC entry 4792 (class 2604 OID 50948)
-- Name: playlistlikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes ALTER COLUMN id SET DEFAULT nextval('public.playlistlikes_id_seq'::regclass);


--
-- TOC entry 4794 (class 2604 OID 50958)
-- Name: playlists id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists ALTER COLUMN id SET DEFAULT nextval('public.playlists_id_seq'::regclass);


--
-- TOC entry 4800 (class 2604 OID 50975)
-- Name: ticket id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket ALTER COLUMN id SET DEFAULT nextval('public.ticket_id_seq'::regclass);


--
-- TOC entry 4796 (class 2604 OID 50967)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 5021 (class 0 OID 50881)
-- Dependencies: 216
-- Data for Name: albumcomment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumcomment (id, album_id, user_id, text) FROM stdin;
1	1	1	Great album!
2	2	2	Not bad.
\.


--
-- TOC entry 5043 (class 0 OID 50950)
-- Dependencies: 238
-- Data for Name: albumlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumlikes (id, album_id, user_id) FROM stdin;
1	1	1
2	2	2
\.


--
-- TOC entry 5023 (class 0 OID 50888)
-- Dependencies: 218
-- Data for Name: albums; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albums (id, singer_id, name) FROM stdin;
1	2	Album A
2	2	Album B
6	22	some alb1
8	22	name
\.


--
-- TOC entry 5025 (class 0 OID 50893)
-- Dependencies: 220
-- Data for Name: concerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.concerts (id, singer_id, price, date, has_suspended) FROM stdin;
1	2	1000	2023-01-01	f
2	2	2000	2023-02-01	t
\.


--
-- TOC entry 5027 (class 0 OID 50899)
-- Dependencies: 222
-- Data for Name: favoritemusics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoritemusics (id, music_id, user_id) FROM stdin;
1	1	1
2	2	2
3	1	2
\.


--
-- TOC entry 5029 (class 0 OID 50904)
-- Dependencies: 224
-- Data for Name: favoriteplaylists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoriteplaylists (id, playlist_id, user_id) FROM stdin;
1	1	1
\.


--
-- TOC entry 5030 (class 0 OID 50908)
-- Dependencies: 225
-- Data for Name: followers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.followers (follower_id, user_id) FROM stdin;
1	2
2	1
\.


--
-- TOC entry 5031 (class 0 OID 50911)
-- Dependencies: 226
-- Data for Name: friendrequests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friendrequests (sender_id, reciever_id, accepted) FROM stdin;
1	2	f
2	1	t
\.


--
-- TOC entry 5033 (class 0 OID 50916)
-- Dependencies: 228
-- Data for Name: musiccomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiccomments (id, music_id, user_id, text) FROM stdin;
1	1	1	Love this song!
2	2	2	Nice track.
\.


--
-- TOC entry 5035 (class 0 OID 50923)
-- Dependencies: 230
-- Data for Name: musiclikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiclikes (id, music_id, user_id) FROM stdin;
1	1	1
2	2	2
\.


--
-- TOC entry 5037 (class 0 OID 50928)
-- Dependencies: 232
-- Data for Name: musics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musics (id, album_id, name, genre, rangeage, image_url, can_add_to_playlist, text) FROM stdin;
1	1	Song A	Pop	All	/path/to/image1.jpg	t	Lyrics for Song A
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


--
-- TOC entry 5051 (class 0 OID 51147)
-- Dependencies: 246
-- Data for Name: playlist_music; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlist_music (music_id, playlist_id) FROM stdin;
1	1
2	1
2	10
\.


--
-- TOC entry 5039 (class 0 OID 50938)
-- Dependencies: 234
-- Data for Name: playlistcomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistcomments (id, playlist_id, user_id, text) FROM stdin;
1	1	1	Great playlist!
\.


--
-- TOC entry 5041 (class 0 OID 50945)
-- Dependencies: 236
-- Data for Name: playlistlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistlikes (id, playlist_id, user_id) FROM stdin;
1	1	1
\.


--
-- TOC entry 5045 (class 0 OID 50955)
-- Dependencies: 240
-- Data for Name: playlists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlists (id, owner_id, is_public, name) FROM stdin;
1	1	t	name1\n
6	22	t	name3
8	1	t	name3
9	22	t	None
10	22	t	name
\.


--
-- TOC entry 5052 (class 0 OID 51169)
-- Dependencies: 247
-- Data for Name: predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.predictions (user_id, music_id, rank) FROM stdin;
1	1	1
1	2	2
2	2	1
2	1	2
\.


--
-- TOC entry 5046 (class 0 OID 50960)
-- Dependencies: 241
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test (message) FROM stdin;
\.


--
-- TOC entry 5050 (class 0 OID 50972)
-- Dependencies: 245
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket (id, user_id, concert_id, purchase_date) FROM stdin;
\.


--
-- TOC entry 5048 (class 0 OID 50964)
-- Dependencies: 243
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, birthdate, address, has_membership, money, is_singer, password) FROM stdin;
12	salam2222	test@test2.com222	2003-04-09	some adr	f	0	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
2	User One	user1@example.com	1990-01-01	123 Main St	t	1000	f	\N
3	User Two	user2@example.com	1985-05-15	456 Elm St	f	500	t	\N
13	salam	salam@salam.com	2003-02-02	addr	f	0	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
19	salam2	salam@salam.com2	2003-02-02	addr	f	0	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
21	saalam2	salam@salamq.com2	2003-02-02	addr	f	0	f	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
22	sa1alam2	salam@1salamq.com2	2003-02-02	addr	t	0	t	a8897efbf898671b5815103a44c73e7cd6b1b364ec2dc92f4068d44acec9dcc0
1	ErfanG	e.geramizadeh13821359@gmail.com	2003-04-09	some addrr	t	0	f	0582bd2c13fff71d7f40ef5586e3f4da05a3a61fe5ba9f0b4d06e99905ab83ea
\.


--
-- TOC entry 5105 (class 0 OID 0)
-- Dependencies: 215
-- Name: albumcomment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albumcomment_id_seq', 1, false);


--
-- TOC entry 5106 (class 0 OID 0)
-- Dependencies: 237
-- Name: albumlikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albumlikes_id_seq', 1, false);


--
-- TOC entry 5107 (class 0 OID 0)
-- Dependencies: 217
-- Name: albums_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albums_id_seq', 8, true);


--
-- TOC entry 5108 (class 0 OID 0)
-- Dependencies: 219
-- Name: concerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.concerts_id_seq', 1, false);


--
-- TOC entry 5109 (class 0 OID 0)
-- Dependencies: 221
-- Name: favoritemusics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favoritemusics_id_seq', 1, false);


--
-- TOC entry 5110 (class 0 OID 0)
-- Dependencies: 223
-- Name: favoriteplaylists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favoriteplaylists_id_seq', 1, false);


--
-- TOC entry 5111 (class 0 OID 0)
-- Dependencies: 227
-- Name: musiccomments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musiccomments_id_seq', 1, false);


--
-- TOC entry 5112 (class 0 OID 0)
-- Dependencies: 229
-- Name: musicllikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musicllikes_id_seq', 1, false);


--
-- TOC entry 5113 (class 0 OID 0)
-- Dependencies: 231
-- Name: musics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musics_id_seq', 1, false);


--
-- TOC entry 5114 (class 0 OID 0)
-- Dependencies: 233
-- Name: playlistcomments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlistcomments_id_seq', 1, false);


--
-- TOC entry 5115 (class 0 OID 0)
-- Dependencies: 235
-- Name: playlistlikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlistlikes_id_seq', 1, false);


--
-- TOC entry 5116 (class 0 OID 0)
-- Dependencies: 239
-- Name: playlists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlists_id_seq', 10, true);


--
-- TOC entry 5117 (class 0 OID 0)
-- Dependencies: 244
-- Name: ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_id_seq', 1, false);


--
-- TOC entry 5118 (class 0 OID 0)
-- Dependencies: 242
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 22, true);


--
-- TOC entry 4802 (class 2606 OID 50977)
-- Name: albumcomment albumcomment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_pkey PRIMARY KEY (id);


--
-- TOC entry 4828 (class 2606 OID 50979)
-- Name: albumlikes albumlikes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_pkey PRIMARY KEY (id);


--
-- TOC entry 4804 (class 2606 OID 50981)
-- Name: albums albums_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (id);


--
-- TOC entry 4808 (class 2606 OID 50983)
-- Name: concerts concert_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_pkey PRIMARY KEY (id);


--
-- TOC entry 4810 (class 2606 OID 50985)
-- Name: favoritemusics favoritemusics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_pkey PRIMARY KEY (id);


--
-- TOC entry 4812 (class 2606 OID 50987)
-- Name: favoriteplaylists favoriteplaylists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_pkey PRIMARY KEY (id);


--
-- TOC entry 4814 (class 2606 OID 50989)
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (user_id, follower_id);


--
-- TOC entry 4816 (class 2606 OID 50991)
-- Name: friendrequests friendrequests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_pkey PRIMARY KEY (sender_id, reciever_id);


--
-- TOC entry 4818 (class 2606 OID 50993)
-- Name: musiccomments musiccomments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_pkey PRIMARY KEY (id);


--
-- TOC entry 4820 (class 2606 OID 50995)
-- Name: musiclikes musicllikes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_pkey PRIMARY KEY (id);


--
-- TOC entry 4822 (class 2606 OID 50997)
-- Name: musics musics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_pkey PRIMARY KEY (id);


--
-- TOC entry 4844 (class 2606 OID 51151)
-- Name: playlist_music playlist_music_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_pkey PRIMARY KEY (music_id, playlist_id);


--
-- TOC entry 4824 (class 2606 OID 50999)
-- Name: playlistcomments playlistcomments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_pkey PRIMARY KEY (id);


--
-- TOC entry 4826 (class 2606 OID 51001)
-- Name: playlistlikes playlistlike_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_pkey PRIMARY KEY (id);


--
-- TOC entry 4830 (class 2606 OID 51003)
-- Name: playlists playlists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (id);


--
-- TOC entry 4846 (class 2606 OID 51173)
-- Name: predictions predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_pkey PRIMARY KEY (user_id, music_id, rank);


--
-- TOC entry 4834 (class 2606 OID 51005)
-- Name: test test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (message);


--
-- TOC entry 4842 (class 2606 OID 51007)
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 4836 (class 2606 OID 51146)
-- Name: users unique_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_email UNIQUE (email);


--
-- TOC entry 4806 (class 2606 OID 51191)
-- Name: albums unique_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT unique_name UNIQUE (name);


--
-- TOC entry 4832 (class 2606 OID 51187)
-- Name: playlists unique_name_for_each_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT unique_name_for_each_user UNIQUE (owner_id, name);


--
-- TOC entry 4838 (class 2606 OID 51144)
-- Name: users unique_username; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_username UNIQUE (username);


--
-- TOC entry 4840 (class 2606 OID 51009)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4847 (class 2606 OID 51010)
-- Name: albumcomment albumcomment_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4848 (class 2606 OID 51015)
-- Name: albumcomment albumcomment_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4868 (class 2606 OID 51020)
-- Name: albumlikes albumlikes_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4869 (class 2606 OID 51025)
-- Name: albumlikes albumlikes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4849 (class 2606 OID 51030)
-- Name: albums albums_singer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4850 (class 2606 OID 51035)
-- Name: concerts concert_singer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4851 (class 2606 OID 51040)
-- Name: favoritemusics favoritemusics_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4852 (class 2606 OID 51045)
-- Name: favoritemusics favoritemusics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4853 (class 2606 OID 51050)
-- Name: favoriteplaylists favoriteplaylists_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4854 (class 2606 OID 51055)
-- Name: favoriteplaylists favoriteplaylists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4855 (class 2606 OID 51060)
-- Name: followers followers_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4856 (class 2606 OID 51065)
-- Name: followers followers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4857 (class 2606 OID 51070)
-- Name: friendrequests friendrequests_reciever_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4858 (class 2606 OID 51075)
-- Name: friendrequests friendrequests_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4859 (class 2606 OID 51080)
-- Name: musiccomments musiccomments_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4860 (class 2606 OID 51085)
-- Name: musiccomments musiccomments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4861 (class 2606 OID 51090)
-- Name: musiclikes musicllikes_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4862 (class 2606 OID 51095)
-- Name: musiclikes musicllikes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiclikes
    ADD CONSTRAINT musicllikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4863 (class 2606 OID 51100)
-- Name: musics musics_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4873 (class 2606 OID 51152)
-- Name: playlist_music playlist_music_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4874 (class 2606 OID 51157)
-- Name: playlist_music playlist_music_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlist_music
    ADD CONSTRAINT playlist_music_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4864 (class 2606 OID 51105)
-- Name: playlistcomments playlistcomments_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4865 (class 2606 OID 51110)
-- Name: playlistcomments playlistcomments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4866 (class 2606 OID 51115)
-- Name: playlistlikes playlistlike_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4867 (class 2606 OID 51120)
-- Name: playlistlikes playlistlike_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4870 (class 2606 OID 51125)
-- Name: playlists playlists_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4875 (class 2606 OID 51179)
-- Name: predictions predictions_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id);


--
-- TOC entry 4876 (class 2606 OID 51174)
-- Name: predictions predictions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.predictions
    ADD CONSTRAINT predictions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 4871 (class 2606 OID 51130)
-- Name: ticket ticket_concert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_concert_id_fkey FOREIGN KEY (concert_id) REFERENCES public.concerts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4872 (class 2606 OID 51135)
-- Name: ticket ticket_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5058 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE albumcomment; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.albumcomment TO ballmer_peak;


--
-- TOC entry 5060 (class 0 OID 0)
-- Dependencies: 215
-- Name: SEQUENCE albumcomment_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.albumcomment_id_seq TO ballmer_peak;


--
-- TOC entry 5061 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE albumlikes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.albumlikes TO ballmer_peak;


--
-- TOC entry 5063 (class 0 OID 0)
-- Dependencies: 237
-- Name: SEQUENCE albumlikes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.albumlikes_id_seq TO ballmer_peak;


--
-- TOC entry 5064 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE albums; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.albums TO ballmer_peak;


--
-- TOC entry 5066 (class 0 OID 0)
-- Dependencies: 217
-- Name: SEQUENCE albums_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.albums_id_seq TO ballmer_peak;


--
-- TOC entry 5067 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE concerts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.concerts TO ballmer_peak;


--
-- TOC entry 5069 (class 0 OID 0)
-- Dependencies: 219
-- Name: SEQUENCE concerts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.concerts_id_seq TO ballmer_peak;


--
-- TOC entry 5070 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE favoritemusics; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.favoritemusics TO ballmer_peak;


--
-- TOC entry 5072 (class 0 OID 0)
-- Dependencies: 221
-- Name: SEQUENCE favoritemusics_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.favoritemusics_id_seq TO ballmer_peak;


--
-- TOC entry 5073 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE favoriteplaylists; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.favoriteplaylists TO ballmer_peak;


--
-- TOC entry 5075 (class 0 OID 0)
-- Dependencies: 223
-- Name: SEQUENCE favoriteplaylists_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.favoriteplaylists_id_seq TO ballmer_peak;


--
-- TOC entry 5076 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE followers; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.followers TO ballmer_peak;


--
-- TOC entry 5077 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE friendrequests; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.friendrequests TO ballmer_peak;


--
-- TOC entry 5078 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE musiccomments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.musiccomments TO ballmer_peak;


--
-- TOC entry 5080 (class 0 OID 0)
-- Dependencies: 227
-- Name: SEQUENCE musiccomments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.musiccomments_id_seq TO ballmer_peak;


--
-- TOC entry 5081 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE musiclikes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.musiclikes TO ballmer_peak;


--
-- TOC entry 5083 (class 0 OID 0)
-- Dependencies: 229
-- Name: SEQUENCE musicllikes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.musicllikes_id_seq TO ballmer_peak;


--
-- TOC entry 5084 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE musics; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.musics TO ballmer_peak;


--
-- TOC entry 5086 (class 0 OID 0)
-- Dependencies: 231
-- Name: SEQUENCE musics_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.musics_id_seq TO ballmer_peak;


--
-- TOC entry 5087 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE playlist_music; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.playlist_music TO ballmer_peak;


--
-- TOC entry 5088 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE playlistcomments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.playlistcomments TO ballmer_peak;


--
-- TOC entry 5090 (class 0 OID 0)
-- Dependencies: 233
-- Name: SEQUENCE playlistcomments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.playlistcomments_id_seq TO ballmer_peak;


--
-- TOC entry 5091 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE playlistlikes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.playlistlikes TO ballmer_peak;


--
-- TOC entry 5093 (class 0 OID 0)
-- Dependencies: 235
-- Name: SEQUENCE playlistlikes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.playlistlikes_id_seq TO ballmer_peak;


--
-- TOC entry 5094 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE playlists; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.playlists TO ballmer_peak;


--
-- TOC entry 5096 (class 0 OID 0)
-- Dependencies: 239
-- Name: SEQUENCE playlists_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.playlists_id_seq TO ballmer_peak;


--
-- TOC entry 5097 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE predictions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.predictions TO ballmer_peak;


--
-- TOC entry 5098 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE test; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.test TO ballmer_peak;


--
-- TOC entry 5099 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE ticket; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ticket TO ballmer_peak;


--
-- TOC entry 5101 (class 0 OID 0)
-- Dependencies: 244
-- Name: SEQUENCE ticket_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.ticket_id_seq TO ballmer_peak;


--
-- TOC entry 5102 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO ballmer_peak WITH GRANT OPTION;


--
-- TOC entry 5104 (class 0 OID 0)
-- Dependencies: 242
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.users_id_seq TO ballmer_peak;


-- Completed on 2024-07-11 00:15:27

--
-- PostgreSQL database dump complete
--

