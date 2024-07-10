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
    
@method_decorator(csrf_exempt, name='dispatch')
class Test(AuthorizationMixin, APIView):
    def post(self, request:HttpRequest, *args, **kwargs):
        # Your logic here
        return JsonResponse({"user": request.COOKIES["username"]})
    
class Conecrts(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute("select * from Concerts")
        return JsonResponse(serialize(data[0],data[1]),safe=False)
class Concert(AuthorizationMixin,APIView):
     def get(self,request,pk):
        data=execute("select * from concerts where id = %s;",[str(pk)])
        print(data)
        return JsonResponse(serialize_one(data[0],data[1]),safe=False)
     

class Musics(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute("select * from musics")
    
        return JsonResponse(serialize(data[0],data[1]),safe=False)
class Music( AuthorizationMixin,APIView):
    def get(self,request,pk):
        data=execute("select * from musics where id = %s;",[str(pk)])
        return JsonResponse(serialize_one(data[0],data[1]),safe=False)

class SingerAlbum(AuthorizationMixin,APIView):
    def get(self,request,singer_pk):
        data=execute("select * from albums where singer_id = %s;",[str(singer_pk)])
        return JsonResponse(serialize(data[0],data[1]),safe=False)
class AlbumSong(AuthorizationMixin, APIView):
    def get(self,request,album_pk):
        data=execute("select * from musics where album_id = %s;",[str(album_pk)])
        return JsonResponse(serialize(data[0],data[1]),safe=False)
    

class UserPlaylist(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute(" select * from get_users_playlists(%s)",[str(request.COOKIES["id"])])
        
        return JsonResponse(serialize(data[0],data[1]),safe=False)
    
class Playlist(AuthorizationMixin,APIView):
    def get(self,request,playlist_id):
        data=execute("select * from get_users_playlists((select owner_id from playlists where playlists.id=%s)) where  id=%s",[playlist_id,playlist_id])
        
        return JsonResponse(serialize(data[0],data[1]),safe=False)
    
class UserPredictions(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute("select * from get_predictions(%s);",[str(request.COOKIES["id"])])
        l=serialize(data[0],data[1])

        return JsonResponse(change(sorted(l, key=lambda x: x['rank']),"singer_id","users","username"),safe=False)
    

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
        try:
            id=execute("select MAX(id) from musics")[1][0][0]+1
            file_path=None
            
            post=request.POST
            stat,field=check(post,"name","album_id","rangeage","text","genre")
            if( not stat):
                return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
            if 'file' in request.FILES:
                
                
                song_file = request.FILES['file']
                if song_file.size > MAX_UPLOAD_SIZE:
                    return JsonResponse({'message':'File size exceeds the maximum limit of 5 MB.'},status=status.HTTP_400_BAD_REQUEST)

                file_extension = os.path.splitext(song_file.name)[1]
                file_path=str(id)+file_extension
                save_path = os.path.join(MEDIA_ROOT, 'musics',file_path)
                
                
                
                with open(save_path, 'wb+') as destination:
                    for chunk in song_file.chunks():
                        destination.write(chunk)
                return JsonResponse({ "message":"uploaded successful"},status=status.HTTP_200_OK)
            can_add=True
            if("can_add_to_playlist" in post and not post["can_add_to_playlist" ]):
                can_add=False
                
            execute("insert into musics(id,album_id,name,genre,rangeage,image_url,can_add_to_playlist,text) values(%s,%s,%s,%s,%s,%s,%s,%s)",
                        [id,post["album_id"],post["name"],post["genre"],post["rangeage"],file_path,can_add,post["text"]],False,True)
           
            return JsonResponse({ "message":"added successfully"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)

            
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




        