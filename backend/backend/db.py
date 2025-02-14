from helper import *
from django.http import HttpRequest
#modifiers----------------
def music_modifier(dic:dict,request:HttpRequest)->dict:
    print(dic)
    dic["singer_name"]=execute("select username from musics,albums,users where users.id=albums.singer_id and musics.album_id=albums.id and musics.id=%s",[dic["id"]])[1][0][0]
    if(dic["image_url"]):
        dic["image_url"]="http://"+request.get_host()+dic["image_url"]
    else:
        dic["image_url"]=None
    if("audio_url" in dic and dic["audio_url"]):
        dic["audio_url"]="http://"+request.get_host()+dic["audio_url"]
    else:
        dic["audio_url"]=None
    dic["liked"]=bool(len(execute("select * from musiclikes where music_id=%s and user_id=%s ",[dic["id"],request.COOKIES["id"]])[1]))


def playlist_modifier(dic:dict,request:HttpRequest):
    image=execute("select image_url from musics,playlist_music where playlist_music.music_id=musics.id and musics.image_url is not null and playlist_id =%s limit 1 ",[dic["id"]])
    if(len(image[1])):
        dic["image_url"]="http://"+request.get_host()+image[1][0][0]
    else:
        dic["image_url"]=None

    musics_query=execute("select image_url,musics.name,singer_id,musics.id,audio_url from musics,playlist_music,albums where musics.id=music_id and albums.id=musics.album_id and playlist_id=%s",[dic["id"]])
    dic["musics"]=serialize(musics_query[0],musics_query[1],music_modifier,request)


def album_modifier(dic:dict,request:HttpRequest):
    image=execute("select image_url from musics where  musics.image_url is  not null and album_id =%s limit 1 ",[dic["id"]])
    if(len(image[1])):
        dic["image_url"]="http://"+request.get_host()+image[1][0][0]
    else:
        dic["image_url"]=None
    musics_query=execute("select * from musics where album_id=%s",[dic["id"]])
    dic["musics"]=serialize(musics_query[0],musics_query[1],music_modifier,request)
    dic["singer_name"]=execute("select username from albums,users where users.id=albums.singer_id and albums.id=%s",[dic["id"]])[1][0][0]
                           
def user_modifier(dic:dict,request:HttpRequest):
    print
    dic["is_followed"]=bool(len(execute("select from followers where follower_id=%s and user_id=%s",[request.COOKIES["id"],dic["id"]])[1]))
    if(dic["image_url"]):
        dic["image_url"]="http://"+request.get_host()+dic["image_url"]
    else:
        dic["image_url"]=None
    if("password" in dic):
        del dic["password"]

def comment_modifier(dic:dict,request:HttpRequest):
    dic["username"]=execute("select username from users where id=%s",[dic["user_id"]])[1][0][0]

def friendrequest_modifier(dic:dict,request:HttpRequest):
    dic["reciever_name"]=execute("select username from users where id=%s",[dic["reciever_id"]])[1][0][0]
    dic["sender_name"]=execute("select username from users where id=%s",[dic["sender_id"]])[1][0][0]

def concert_modifier(dic:dict,request:HttpRequest):
    dic["singer_name"]=execute("select username from users where id=%s",[dic["singer_id"]])[1][0][0]
    dic["ticket_count"]=execute("select count(*) from ticket where user_id=%s and concert_id=%s",[request.COOKIES["id"],dic["id"]])[1][0][0]

    