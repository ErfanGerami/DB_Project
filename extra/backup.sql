--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.3

-- Started on 2024-07-08 10:55:45

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
-- TOC entry 5027 (class 0 OID 0)
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
-- TOC entry 5028 (class 0 OID 0)
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
-- TOC entry 5029 (class 0 OID 0)
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
-- TOC entry 5030 (class 0 OID 0)
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
-- TOC entry 5031 (class 0 OID 0)
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
-- TOC entry 5032 (class 0 OID 0)
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
-- TOC entry 5033 (class 0 OID 0)
-- Dependencies: 227
-- Name: musiccomments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musiccomments_id_seq OWNED BY public.musiccomments.id;


--
-- TOC entry 230 (class 1259 OID 50923)
-- Name: musicllikes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.musicllikes (
    id integer NOT NULL,
    music_id integer,
    user_id integer
);


ALTER TABLE public.musicllikes OWNER TO postgres;

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
-- TOC entry 5034 (class 0 OID 0)
-- Dependencies: 229
-- Name: musicllikes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musicllikes_id_seq OWNED BY public.musicllikes.id;


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
    cover_image_path character varying(200) DEFAULT NULL::character varying,
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
-- TOC entry 5035 (class 0 OID 0)
-- Dependencies: 231
-- Name: musics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.musics_id_seq OWNED BY public.musics.id;


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
-- TOC entry 5036 (class 0 OID 0)
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
-- TOC entry 5037 (class 0 OID 0)
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
    is_public boolean DEFAULT true
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
-- TOC entry 5038 (class 0 OID 0)
-- Dependencies: 239
-- Name: playlists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.playlists_id_seq OWNED BY public.playlists.id;


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
-- TOC entry 5039 (class 0 OID 0)
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
    name character varying(100),
    email character varying(100),
    birthday date,
    address character varying(100),
    has_membership boolean DEFAULT false,
    money bigint DEFAULT 0,
    is_singer boolean DEFAULT false
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
-- TOC entry 5040 (class 0 OID 0)
-- Dependencies: 242
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 4765 (class 2604 OID 50884)
-- Name: albumcomment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment ALTER COLUMN id SET DEFAULT nextval('public.albumcomment_id_seq'::regclass);


--
-- TOC entry 4780 (class 2604 OID 50953)
-- Name: albumlikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes ALTER COLUMN id SET DEFAULT nextval('public.albumlikes_id_seq'::regclass);


--
-- TOC entry 4766 (class 2604 OID 50891)
-- Name: albums id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums ALTER COLUMN id SET DEFAULT nextval('public.albums_id_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 50896)
-- Name: concerts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts ALTER COLUMN id SET DEFAULT nextval('public.concerts_id_seq'::regclass);


--
-- TOC entry 4769 (class 2604 OID 50902)
-- Name: favoritemusics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics ALTER COLUMN id SET DEFAULT nextval('public.favoritemusics_id_seq'::regclass);


--
-- TOC entry 4770 (class 2604 OID 50907)
-- Name: favoriteplaylists id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists ALTER COLUMN id SET DEFAULT nextval('public.favoriteplaylists_id_seq'::regclass);


--
-- TOC entry 4772 (class 2604 OID 50919)
-- Name: musiccomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments ALTER COLUMN id SET DEFAULT nextval('public.musiccomments_id_seq'::regclass);


--
-- TOC entry 4773 (class 2604 OID 50926)
-- Name: musicllikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musicllikes ALTER COLUMN id SET DEFAULT nextval('public.musicllikes_id_seq'::regclass);


--
-- TOC entry 4774 (class 2604 OID 50931)
-- Name: musics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics ALTER COLUMN id SET DEFAULT nextval('public.musics_id_seq'::regclass);


--
-- TOC entry 4778 (class 2604 OID 50941)
-- Name: playlistcomments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments ALTER COLUMN id SET DEFAULT nextval('public.playlistcomments_id_seq'::regclass);


--
-- TOC entry 4779 (class 2604 OID 50948)
-- Name: playlistlikes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes ALTER COLUMN id SET DEFAULT nextval('public.playlistlikes_id_seq'::regclass);


--
-- TOC entry 4781 (class 2604 OID 50958)
-- Name: playlists id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists ALTER COLUMN id SET DEFAULT nextval('public.playlists_id_seq'::regclass);


--
-- TOC entry 4787 (class 2604 OID 50975)
-- Name: ticket id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket ALTER COLUMN id SET DEFAULT nextval('public.ticket_id_seq'::regclass);


--
-- TOC entry 4783 (class 2604 OID 50967)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 4992 (class 0 OID 50881)
-- Dependencies: 216
-- Data for Name: albumcomment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumcomment (id, album_id, user_id, text) FROM stdin;
\.


--
-- TOC entry 5014 (class 0 OID 50950)
-- Dependencies: 238
-- Data for Name: albumlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albumlikes (id, album_id, user_id) FROM stdin;
\.


--
-- TOC entry 4994 (class 0 OID 50888)
-- Dependencies: 218
-- Data for Name: albums; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albums (id, singer_id, name) FROM stdin;
\.


--
-- TOC entry 4996 (class 0 OID 50893)
-- Dependencies: 220
-- Data for Name: concerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.concerts (id, singer_id, price, date, has_suspended) FROM stdin;
\.


--
-- TOC entry 4998 (class 0 OID 50899)
-- Dependencies: 222
-- Data for Name: favoritemusics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoritemusics (id, music_id, user_id) FROM stdin;
\.


--
-- TOC entry 5000 (class 0 OID 50904)
-- Dependencies: 224
-- Data for Name: favoriteplaylists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favoriteplaylists (id, playlist_id, user_id) FROM stdin;
\.


--
-- TOC entry 5001 (class 0 OID 50908)
-- Dependencies: 225
-- Data for Name: followers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.followers (follower_id, user_id) FROM stdin;
\.


--
-- TOC entry 5002 (class 0 OID 50911)
-- Dependencies: 226
-- Data for Name: friendrequests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friendrequests (sender_id, reciever_id, accepted) FROM stdin;
\.


--
-- TOC entry 5004 (class 0 OID 50916)
-- Dependencies: 228
-- Data for Name: musiccomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musiccomments (id, music_id, user_id, text) FROM stdin;
\.


--
-- TOC entry 5006 (class 0 OID 50923)
-- Dependencies: 230
-- Data for Name: musicllikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musicllikes (id, music_id, user_id) FROM stdin;
\.


--
-- TOC entry 5008 (class 0 OID 50928)
-- Dependencies: 232
-- Data for Name: musics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.musics (id, album_id, name, genre, rangeage, cover_image_path, can_add_to_playlist, text) FROM stdin;
\.


--
-- TOC entry 5010 (class 0 OID 50938)
-- Dependencies: 234
-- Data for Name: playlistcomments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistcomments (id, playlist_id, user_id, text) FROM stdin;
\.


--
-- TOC entry 5012 (class 0 OID 50945)
-- Dependencies: 236
-- Data for Name: playlistlikes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlistlikes (id, playlist_id, user_id) FROM stdin;
\.


--
-- TOC entry 5016 (class 0 OID 50955)
-- Dependencies: 240
-- Data for Name: playlists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.playlists (id, owner_id, is_public) FROM stdin;
\.


--
-- TOC entry 5017 (class 0 OID 50960)
-- Dependencies: 241
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test (message) FROM stdin;
\.


--
-- TOC entry 5021 (class 0 OID 50972)
-- Dependencies: 245
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket (id, user_id, concert_id, purchase_date) FROM stdin;
\.


--
-- TOC entry 5019 (class 0 OID 50964)
-- Dependencies: 243
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, birthday, address, has_membership, money, is_singer) FROM stdin;
\.


--
-- TOC entry 5041 (class 0 OID 0)
-- Dependencies: 215
-- Name: albumcomment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albumcomment_id_seq', 1, false);


--
-- TOC entry 5042 (class 0 OID 0)
-- Dependencies: 237
-- Name: albumlikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albumlikes_id_seq', 1, false);


--
-- TOC entry 5043 (class 0 OID 0)
-- Dependencies: 217
-- Name: albums_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albums_id_seq', 1, false);


--
-- TOC entry 5044 (class 0 OID 0)
-- Dependencies: 219
-- Name: concerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.concerts_id_seq', 1, false);


--
-- TOC entry 5045 (class 0 OID 0)
-- Dependencies: 221
-- Name: favoritemusics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favoritemusics_id_seq', 1, false);


--
-- TOC entry 5046 (class 0 OID 0)
-- Dependencies: 223
-- Name: favoriteplaylists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favoriteplaylists_id_seq', 1, false);


--
-- TOC entry 5047 (class 0 OID 0)
-- Dependencies: 227
-- Name: musiccomments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musiccomments_id_seq', 1, false);


--
-- TOC entry 5048 (class 0 OID 0)
-- Dependencies: 229
-- Name: musicllikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musicllikes_id_seq', 1, false);


--
-- TOC entry 5049 (class 0 OID 0)
-- Dependencies: 231
-- Name: musics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.musics_id_seq', 1, false);


--
-- TOC entry 5050 (class 0 OID 0)
-- Dependencies: 233
-- Name: playlistcomments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlistcomments_id_seq', 1, false);


--
-- TOC entry 5051 (class 0 OID 0)
-- Dependencies: 235
-- Name: playlistlikes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlistlikes_id_seq', 1, false);


--
-- TOC entry 5052 (class 0 OID 0)
-- Dependencies: 239
-- Name: playlists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.playlists_id_seq', 1, false);


--
-- TOC entry 5053 (class 0 OID 0)
-- Dependencies: 244
-- Name: ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_id_seq', 1, false);


--
-- TOC entry 5054 (class 0 OID 0)
-- Dependencies: 242
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- TOC entry 4789 (class 2606 OID 50977)
-- Name: albumcomment albumcomment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_pkey PRIMARY KEY (id);


--
-- TOC entry 4813 (class 2606 OID 50979)
-- Name: albumlikes albumlikes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_pkey PRIMARY KEY (id);


--
-- TOC entry 4791 (class 2606 OID 50981)
-- Name: albums albums_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (id);


--
-- TOC entry 4793 (class 2606 OID 50983)
-- Name: concerts concert_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_pkey PRIMARY KEY (id);


--
-- TOC entry 4795 (class 2606 OID 50985)
-- Name: favoritemusics favoritemusics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_pkey PRIMARY KEY (id);


--
-- TOC entry 4797 (class 2606 OID 50987)
-- Name: favoriteplaylists favoriteplaylists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_pkey PRIMARY KEY (id);


--
-- TOC entry 4799 (class 2606 OID 50989)
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (user_id, follower_id);


--
-- TOC entry 4801 (class 2606 OID 50991)
-- Name: friendrequests friendrequests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_pkey PRIMARY KEY (sender_id, reciever_id);


--
-- TOC entry 4803 (class 2606 OID 50993)
-- Name: musiccomments musiccomments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_pkey PRIMARY KEY (id);


--
-- TOC entry 4805 (class 2606 OID 50995)
-- Name: musicllikes musicllikes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musicllikes
    ADD CONSTRAINT musicllikes_pkey PRIMARY KEY (id);


--
-- TOC entry 4807 (class 2606 OID 50997)
-- Name: musics musics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_pkey PRIMARY KEY (id);


--
-- TOC entry 4809 (class 2606 OID 50999)
-- Name: playlistcomments playlistcomments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_pkey PRIMARY KEY (id);


--
-- TOC entry 4811 (class 2606 OID 51001)
-- Name: playlistlikes playlistlike_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_pkey PRIMARY KEY (id);


--
-- TOC entry 4815 (class 2606 OID 51003)
-- Name: playlists playlists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (id);


--
-- TOC entry 4817 (class 2606 OID 51005)
-- Name: test test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (message);


--
-- TOC entry 4821 (class 2606 OID 51007)
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id);


--
-- TOC entry 4819 (class 2606 OID 51009)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4822 (class 2606 OID 51010)
-- Name: albumcomment albumcomment_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4823 (class 2606 OID 51015)
-- Name: albumcomment albumcomment_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumcomment
    ADD CONSTRAINT albumcomment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4843 (class 2606 OID 51020)
-- Name: albumlikes albumlikes_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4844 (class 2606 OID 51025)
-- Name: albumlikes albumlikes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albumlikes
    ADD CONSTRAINT albumlikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4824 (class 2606 OID 51030)
-- Name: albums albums_singer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4825 (class 2606 OID 51035)
-- Name: concerts concert_singer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.concerts
    ADD CONSTRAINT concert_singer_id_fkey FOREIGN KEY (singer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4826 (class 2606 OID 51040)
-- Name: favoritemusics favoritemusics_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4827 (class 2606 OID 51045)
-- Name: favoritemusics favoritemusics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoritemusics
    ADD CONSTRAINT favoritemusics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4828 (class 2606 OID 51050)
-- Name: favoriteplaylists favoriteplaylists_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4829 (class 2606 OID 51055)
-- Name: favoriteplaylists favoriteplaylists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favoriteplaylists
    ADD CONSTRAINT favoriteplaylists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4830 (class 2606 OID 51060)
-- Name: followers followers_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4831 (class 2606 OID 51065)
-- Name: followers followers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4832 (class 2606 OID 51070)
-- Name: friendrequests friendrequests_reciever_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_reciever_id_fkey FOREIGN KEY (reciever_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4833 (class 2606 OID 51075)
-- Name: friendrequests friendrequests_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendrequests
    ADD CONSTRAINT friendrequests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4834 (class 2606 OID 51080)
-- Name: musiccomments musiccomments_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4835 (class 2606 OID 51085)
-- Name: musiccomments musiccomments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musiccomments
    ADD CONSTRAINT musiccomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4836 (class 2606 OID 51090)
-- Name: musicllikes musicllikes_music_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musicllikes
    ADD CONSTRAINT musicllikes_music_id_fkey FOREIGN KEY (music_id) REFERENCES public.musics(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4837 (class 2606 OID 51095)
-- Name: musicllikes musicllikes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musicllikes
    ADD CONSTRAINT musicllikes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4838 (class 2606 OID 51100)
-- Name: musics musics_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.musics
    ADD CONSTRAINT musics_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4839 (class 2606 OID 51105)
-- Name: playlistcomments playlistcomments_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4840 (class 2606 OID 51110)
-- Name: playlistcomments playlistcomments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistcomments
    ADD CONSTRAINT playlistcomments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4841 (class 2606 OID 51115)
-- Name: playlistlikes playlistlike_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4842 (class 2606 OID 51120)
-- Name: playlistlikes playlistlike_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlistlikes
    ADD CONSTRAINT playlistlike_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4845 (class 2606 OID 51125)
-- Name: playlists playlists_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4846 (class 2606 OID 51130)
-- Name: ticket ticket_concert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_concert_id_fkey FOREIGN KEY (concert_id) REFERENCES public.concerts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4847 (class 2606 OID 51135)
-- Name: ticket ticket_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2024-07-08 10:55:46

--
-- PostgreSQL database dump complete
--

