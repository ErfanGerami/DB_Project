from django.db import connection
from helper import *
from django.http import JsonResponse,HttpResponse,HttpRequest
from  rest_framework import status 
import jwt
from datetime import datetime, timedelta
from .settings import SECRET_KEY,EXPIRATION_TIME
import hashlib
from helper import *
from rest_framework.views import APIView
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from .mixin import AuthorizationMixin,SingerAuthorizationMixin
import json
from django.utils.decorators import method_decorator
import os
from .settings import MEDIA_ROOT,MAX_UPLOAD_SIZE
from .db import *
import os
from django.utils.html import escape

@api_view(['POST'])
def login(request:HttpRequest):
    if(request.method=='POST'):
        data = json.loads(request.body)
        
        username=data.get("username")
        password=data.get("password")
        
        hashed_pass=hash(password)
        print(username,hashed_pass)

        row=execute("select * from users where password=%s  and username=%s ",[hashed_pass,username])[1]
        id=row[0][0]
        email=row[0][2]
        birthdate=row[0][3]
        address=row[0][4]
        has_membership=row[0][5]
        money=int(row[0][6])
        is_singer=row[0][7]


        if(len(row)!=1):
            return JsonResponse({"error":"no such user"},status=status.HTTP_400_BAD_REQUEST)
        

        return JsonResponse({'token':generate_jwt_token(username,hashed_pass,id,email,birthdate,address,has_membership,money,is_singer)},status=200)
    return JsonResponse({"message":"get method is not supported"},status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@csrf_exempt
def register(request):
    data = json.loads(request.body)
        
    
    stat,field=check(data,"password","username","email","birthdate","address")
    if( not stat):
        print(field)
        return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
    try:
        post=request.POST
        execute("insert into users(username,password,email,birthdate,address) values(%s,%s,%s,%s,%s)",
                [data["username"],hash(data["password"]),data["email"],data["birthdate"],data["address"]],False,True)
                
        return JsonResponse({ "message":"register successful"},status=status.HTTP_200_OK)
    except Exception as e:
        return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
    
@api_view(['POST'])
@csrf_exempt
def singer_register(request):
    
        post=request.POST
        print(post)
        
        id=get_highest_id("users")+1
        stat,field=check(post,"password","username","email","birthdate","address")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
    
        
        stat,field=check(request.FILES,"image")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
            
                
                
            
        res,path=save_file(request.FILES['image'],["jpg","png","jpeg","ico"],str(id),"/images")
        print(res)
        if(not res):
            return JsonResponse({'message':path},status=status.HTTP_400_BAD_REQUEST)

        post=request.POST
        execute("insert into users(id,username,password,email,birthdate,address,image_url,is_singer) values(%s,%s,%s,%s,%s,%s,%s,%s)",
                [id,post["username"],hash(post["password"]),post["email"],post["birthdate"],post["address"],path,True],False,True)
                
        return JsonResponse({ "message":"register successful"},status=status.HTTP_200_OK)
    
    
@method_decorator(csrf_exempt, name='dispatch')
class Test(AuthorizationMixin, APIView):
    def post(self, request:HttpRequest, *args, **kwargs):
        # Your logic here
        return JsonResponse({"user_id": request.COOKIES["id"]})
    
class Conecrts(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute("select * from concerts")
        return JsonResponse(serialize(data[0],data[1],concert_modifier,request),safe=False)
class Concert(AuthorizationMixin,APIView):
     def get(self,request,pk):
        data=execute("select * from concerts where id = %s;",[str(pk)])
        print(data)
        return JsonResponse(serialize_one(data[0],data[1]),safe=False)
     

class Musics(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute("select * from musics")
    
        return JsonResponse(serialize(data[0],data[1],music_modifier,request),safe=False)
class Music( AuthorizationMixin,APIView):
    def get(self,request,pk):
        data=execute("select * from musics where id = %s;",[str(pk)])
        
        return JsonResponse(serialize_one(data[0],data[1],music_modifier,request),safe=False)

class SingerAlbum(AuthorizationMixin,APIView):
    def get(self,request,singer_pk):
        data=execute("select * from albums where singer_id = %s;",[str(singer_pk)])
        return JsonResponse(serialize(data[0],data[1],album_modifier,request),safe=False)
class AlbumSong(AuthorizationMixin, APIView):
    def get(self,request,album_id):
        data=execute("select * from albums where id = %s;",[str(album_id)])
        return JsonResponse(serialize(data[0],data[1],album_modifier,request),safe=False)
    

class UserPlaylist(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute(" select * from get_users_playlists(%s)",[str(request.COOKIES["id"])])
        
        return JsonResponse(serialize(data[0],data[1],playlist_modifier,request),safe=False)
    
class Playlist(AuthorizationMixin,APIView):
    def get(self,request,playlist_id):
        data=execute("select * from get_users_playlists((select owner_id from playlists where playlists.id=%s)) where  id=%s",[playlist_id,playlist_id])
        return JsonResponse(serialize(data[0],data[1]),safe=False)

class PlaylistMusics(AuthorizationMixin,APIView):
    def get(self,request,playlist_id):
        data=execute("select * from playlists where id=%s and owner_id=%s",[playlist_id,request.COOKIES["id"]])       
        return JsonResponse(serialize_one(data[0],data[1],playlist_modifier,request),safe=False)

class UserPredictions(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute("select * from get_predictions(%s);",[str(request.COOKIES["id"])])
        l=serialize(data[0],data[1],music_modifier,request)
        

        return JsonResponse(sorted(l, key=lambda x: x['rank']),safe=False)
    

class AddPLaylist(AuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        try:
            data=json.loads(request.body)
            stat,field=check(data,"playlist_name")
            if( not stat):
                
                return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)

            data=execute("insert into playlists(owner_id,name) values(%s,%s)",[str(request.COOKIES["id"]),str(data.get("playlist_name"))],False,True)
            return JsonResponse({ "message":"added successfully"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)

class AddToPLaylist(AuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        try:

            data=json.loads(request.body)
            if(len(execute("select * from playlists where id= %s and owner_id=%s ",[str(data.get("playlist_id")),request.COOKIES["id"]])[1])!=1):
                return JsonResponse({ "message":"user doesnt have a playlist with that id"},status=status.HTTP_400_BAD_REQUEST)
            if( not execute("select can_add_to_playlist from musics where id=%s",[str(data.get("music_id"))])[1][0][0]):
                return JsonResponse({ "message": "singer prevented this from being added to a playlist"},status=status.HTTP_400_BAD_REQUEST)
            data=execute("insert into playlist_music values(%s,%s)",[str(data.get("music_id")),str(data.get("playlist_id"))],False,True)
            return JsonResponse({ "message":"added successfully"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
class AddAlbum(SingerAuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        try:
            data=json.loads(request.body)
            stat,field=check(data,"name")
            if( not stat):
                return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
            execute("insert into albums(singer_id,name) values (%s,%s)",[request.COOKIES["id"],data["name"]],False,True)
            return JsonResponse({ "message":"added successfully"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
 
class AddMusic(SingerAuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        
            id=get_highest_id("musics")+1
            file_path=None
            
            post=request.POST
            stat,field=check(post,"name","album_id","rangeage","text","genre")
            
            if( not stat):
                return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
            
            stat,field=check(request.FILES,"image","audio")
            if( not stat):
                return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
            
                
                
            
            res,image_path=save_file(request.FILES['image'],["jpg","png","jpeg","ico"],str(id),"/musics")
            if(not res):
                return JsonResponse({'message':image_path},status=status.HTTP_400_BAD_REQUEST)

            res,audio_path=save_file(request.FILES['audio'],["mp4","wav","mp3","wma","m4a","flac"],str(id),"/audios")
            if(not res):
                return JsonResponse({'message':audio_path},status=status.HTTP_400_BAD_REQUEST)

            can_add=True
            if("can_add_to_playlist" in post and not post["can_add_to_playlist" ]):
                can_add=False
                
            execute("insert into musics(id,album_id,name,genre,rangeage,can_add_to_playlist,text,image_url,audio_url) values(%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                        [id,post["album_id"],post["name"],post["genre"],post["rangeage"],can_add,post["text"],image_path,audio_path],False,True)
           
            return JsonResponse({ "message":"added successfully"},status=status.HTTP_200_OK)
        

            
class CanAddToPlaylist(SingerAuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"music_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            if(int(execute("select * from get_singer_id(%s)",[data["music_id"]])[1][0][0])!=request.COOKIES["id"]):
                return JsonResponse({'message':'not this singers music'},status=status.HTTP_400_BAD_REQUEST)
            set_true=True
            if(request.path.split("/")[-1]=="false"):
                set_true=False
            execute("update musics set can_add_to_playlist =%s where id=%s",[set_true,request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"altered successfully"},status=status.HTTP_200_OK)

        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)



class LikeMusic(AuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"music_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            execute("insert into musiclikes(music_id,user_id) values(%s,%s)",[data["music_id"],request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"liked"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
    def delete(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"music_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            execute("delete from musiclikes  where music_id=%s and user_id=%s",[data["music_id"],request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"disliked"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
class AllLikes(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            musics_query=execute("select image_url,musics.name,singer_id,music_id as id,audio_url from musics,musiclikes,albums where albums.id=musics.album_id and  musiclikes.music_id=musics.id and musiclikes.user_id=%s",[request.COOKIES["id"]])
            musics=serialize(musics_query[0],musics_query[1],music_modifier,request)
            return JsonResponse(musics,safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)

class LikeAlbums(AuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"album_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            execute("insert into albumlikes(album_id,user_id) values(%s,%s)",[data["album_id"],request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"liked"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
    def delete(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"album_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            execute("delete from albumlikes  where album_id=%s and user_id=%s",[data["album_id"],request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"disliked"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)     

class AllLikesAlbums(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            albums=execute("select album_id as id,singer_id,name from albums,albumlikes where albumlikes.user_id=%s",[request.COOKIES["id"]])
            return JsonResponse(serialize(albums[0],albums[1],album_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
class LikePlaylists(AuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"playlist_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            execute("insert into playlistlikes(playlist_id,user_id) values(%s,%s)",[data["playlist_id"],request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"liked"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
    def delete(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"playlist_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            execute("delete from playlistlikes  where plaaylist_id=%s and user_id=%s",[data["playlist_id"],request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"disliked"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        

class AllLikesPlaylists(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            playlists=execute("select id,is_public,name from playlists,playlistlikes where playlistlikes.user_id=%s",[request.COOKIES["id"]])
            
            return JsonResponse(serialize(playlists[0],playlists[1],playlist_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        


class AllSingers(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            singers=execute("select * from users where is_singer")
            
            return JsonResponse(serialize(singers[0],singers[1],user_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)




class Comment(AuthorizationMixin,APIView):
    def post(self,request:HttpRequest):

            data=json.loads(request.body)
            stat,field=check(data,"music_id","text")
            if( not stat):
                return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
            execute("insert into musiccomments(music_id,user_id,text) values(%s,%s,%s)",[data.get("music_id"),request.COOKIES["id"],data.get("text")],False,True)
            return JsonResponse({ "message":"added successfuly"},status=status.HTTP_200_OK)

       

class GetComments(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest,music_id):
        try:
            all_comments=execute("select * from musiccomments where music_id=%s",[music_id])
            return JsonResponse(serialize(all_comments[0],all_comments[1],comment_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
class ALLFollowers(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            followers=execute("select * from users,followers where users.id=followers.follower_id and followers.user_id=%s",[request.COOKIES["id"]])
            
            return JsonResponse(serialize(followers[0],followers[1],user_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)

class ALLFollowings(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            folloings=execute("select * from users,followers where users.id=followers.user_id and followers.follower_id=%s",[request.COOKIES["id"]])
            
            return JsonResponse(serialize(folloings[0],folloings[1],user_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)

class Follow(AuthorizationMixin,APIView):

    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"user_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        if(int(request.COOKIES["id"])==int(data.get("user_id"))):
            return JsonResponse({ "message": "follower and following can not be the same"},status=status.HTTP_400_BAD_REQUEST)

        try:
            execute("insert into followers values(%s,%s)",[request.COOKIES["id"],data.get("user_id")],False,True)
            return JsonResponse({ "message":"followed"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
    def delete(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"user_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            execute("delete from followers  where user_id=%s and follower_id=%s",[data.get("user_id"),request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"unfollowed"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
class ALLFriendRealted(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            my_id=request.COOKIES["id"]
            all_friendrequests=execute("""
                                       (select sender_id,reciever_id,accepted,0 as type from friendrequests where not accepted and sender_id=%s)
                                       union all
                                       (select sender_id,reciever_id,accepted,1 as type from friendrequests where  accepted and sender_id=%s)
                                       union all
                                       (select sender_id,reciever_id,accepted,2 as type from friendrequests where not accepted and reciever_id=%s)
                                       union all
                                       (select sender_id,reciever_id,accepted,3 as type from friendrequests where  accepted and reciever_id=%s)
                                       

                                       """
                                       ,[my_id,my_id,my_id,my_id])
            
            return JsonResponse(serialize(all_friendrequests[0],all_friendrequests[1],friendrequest_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST) 
        

class RequestFriendship(AuthorizationMixin,APIView):

    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"reciever_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        if(int(request.COOKIES["id"])==int(data.get("reciever_id"))):
            return JsonResponse({ "message": "cant send a request to yourself"},status=status.HTTP_400_BAD_REQUEST)
        if(len(execute("select * from friendrequests where  reciever_id=%s and sender_id=%s",[request.COOKIES["id"],data.get("reciever_id")])[1])):
            return JsonResponse({ "message": "there is already a friendrequest betwean these two users"},status=status.HTTP_400_BAD_REQUEST)

        try:
            execute("insert into friendrequests(sender_id,reciever_id) values(%s,%s)",[request.COOKIES["id"],data.get("reciever_id")],False,True)
            return JsonResponse({ "message":"followed"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)

class AcceptFriendRequest(AuthorizationMixin,APIView):

    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"sender_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            execute("update friendrequests set accepted=true where sender_id=%s and reciever_id=%s",[data.get("sender_id"),request.COOKIES["id"]],False,True)
            return JsonResponse({ "message":"followed"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
class GetUser(AuthorizationMixin,APIView):

    def get(self,request:HttpRequest):
        
        try:
            user=execute("select * from users where id=%s",[request.COOKIES["id"]])
            return JsonResponse(serialize_one(user[0],user[1],user_modifier,request),status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        


class Message(AuthorizationMixin,APIView):

    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"reciever_id")

        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        
        try:
            #check if usr is friend
            execute("insert into messages(sender_id,reciever_id,text) values(%s,%s,%s)",[request.COOKIES["id"],data.get("reciever_id"),escape(data.get("text"))],False,True)
            return JsonResponse({ "message":"sent"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
class AllChatFriends(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            friends=execute("select  * from users,friendrequests where accepted and (friendrequests.sender_id=%s and friendrequests.reciever_id=users.id) or (friendrequests.sender_id=users.id and friendrequests.reciever_id=%s)",[request.COOKIES["id"],request.COOKIES["id"]])
            return JsonResponse(serialize(friends[0],friends[1],user_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
class Chat(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest,user_id):
        try:
            messages=execute("select messages.id,sender_id,text,username from messages,users where users.id=sender_id and   (%s,%s) in ((sender_id,reciever_id) ,(reciever_id,sender_id) ) order by time asc ",[request.COOKIES["id"],user_id])
            return JsonResponse(serialize(messages[0],messages[1]),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)


class Users(AuthorizationMixin,APIView):
    def get(self,request:HttpRequest):
        try:
            singers=execute("select * from users ")
            
            return JsonResponse(serialize(singers[0],singers[1],user_modifier,request),safe=False)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        


class AddConcert(SingerAuthorizationMixin,APIView):

    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"date","price")

        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        
        try:
            #check if usr is friend
            execute("insert into concerts(singer_id,price,date) values(%s,%s,%s)",[request.COOKIES["id"],data.get("price"),data.get("date")],False,True)
            return JsonResponse({ "message":"added"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        

    
    
class BuyTicket(AuthorizationMixin,APIView):

    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"concert_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        
        try:
            if(execute("select has_suspended from concerts where id=%s",[data.get("concert_id")])[1][0][0]):
                return JsonResponse({ "message":"concert is suspended"},status=status.HTTP_200_OK)
            
            money=int(execute("select money from users where id=%s",[request.COOKIES["id"]])[1][0][0])
            price=int(execute("select price from concerts where id=%s",[data.get("concert_id")])[1][0][0])
            
            if(money<price):
                return JsonResponse({ "message":"not enought money"},status=status.HTTP_200_OK)
            execute("insert into ticket(user_id,concert_id) values(%s,%s)",[request.COOKIES["id"],data.get("concert_id")],False,True)
            print(1)
            return JsonResponse({ "message":"added"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)

class SuspendConcert(SingerAuthorizationMixin,APIView):

    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"concert_id")
        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        try:
            if(int(execute("select singer_id from concerts where id=%s",[data.get("concert_id")])[1][0][0])!=request.COOKIES["id"]):
                return JsonResponse({ "message": "not your concert"},status=status.HTTP_400_BAD_REQUEST)
            
            execute("update   concerts set has_suspended=true where id=%s",[data.get("concert_id")],False,True)
            return JsonResponse({ "message":"suspended"},status=status.HTTP_200_OK)

        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
class Deposit(AuthorizationMixin,APIView):

    def post(self,request:HttpRequest):
        data=json.loads(request.body)
        stat,field=check(data,"money")

        if( not stat):
            return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
        
        try:
            execute("update users set money= money + %s where id=%s",[data.get("money"),request.COOKIES["id"]],False,True)
        
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
