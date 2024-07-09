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
from .mixin import AuthorizationMixin
import json
from django.utils.decorators import method_decorator


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
    
class PlayList(AuthorizationMixin,APIView):
    def get(self,request,playlist_pk):
        data=execute(" select * from get_musics_in_playlist(%s)",[str(playlist_pk)])
        return JsonResponse(serialize(data[0],data[1]),safe=False)
    
class UserPlaylist(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute(" select * from playlists where owner_id = %s",[str(request.COOKIES["id"])])
        return JsonResponse(serialize(data[0],data[1]),safe=False)
    

class UserPredictions(AuthorizationMixin,APIView):
    def get(self,request):
        data=execute("select * from get_predictions(%s);",[str(request.COOKIES["id"])])
        l=serialize(data[0],data[1])
        return JsonResponse(sorted(l, key=lambda x: x['rank']),safe=False)
    

class AddPLaylist(AuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        try:
            data=json.loads(request.body)

            data=execute("insert into playlists(owner_id,name) values(%s,%s)",[str(request.COOKIES["id"]),str(data.get("playlist_name"))],False,True)
            return JsonResponse({ "message":"added successfully"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)

class AddToPLaylist(AuthorizationMixin,APIView):
    def post(self,request:HttpRequest):
        try:

            data=json.loads(request.body)
            data=execute("insert into playlist_music values(%s,%s)",[str(data.get("music_id")),str(data.get("playlist_id"))],False,True)
            return JsonResponse({ "message":"added successfully"},status=status.HTTP_200_OK)
        except Exception as e:
            return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
        
