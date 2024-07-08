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
  
from django.utils.decorators import method_decorator


@api_view(['POST'])
def login(request:HttpRequest):
    if(request.method=='POST'):
        username=request.POST["username"]
        password=request.POST["password"]
        
        hashed_pass=hash(password)
        print(username,hashed_pass)
        row=execute("select * from users where password=%s  and username=%s ",[hashed_pass,username])[1]
        if(len(row)!=1):
            return JsonResponse({"error":"no such user"},status=status.HTTP_400_BAD_REQUEST)
        

        return JsonResponse({'token':generate_jwt_token(username,hashed_pass)},status=200)
    return JsonResponse({"message":"get method is not supported"},status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@csrf_exempt
def register(request):
    stat,field=check(request.POST,"password","username","email","birthdate","address")
    if( not stat):
        print(field)
        return JsonResponse({"message":f"{field} is required"},status=status.HTTP_400_BAD_REQUEST)
    try:
        post=request.POST
        execute("insert into users(username,password,email,birthdate,address) values(%s,%s,%s,%s,%s)",
                [post["username"],hash(post["password"]),post["email"],post["birthdate"],post["address"]],False,True)
                
        return JsonResponse({ "message":"register successful"},status=status.HTTP_200_OK)
    except Exception as e:
        return JsonResponse({ "message": str(e)},status=status.HTTP_400_BAD_REQUEST)
    
@method_decorator(csrf_exempt, name='dispatch')
class Test(AuthorizationMixin, APIView):
    def post(self, request:HttpRequest, *args, **kwargs):
        # Your logic here
        return JsonResponse({"user": request.COOKIES["username"]})
    
class Conecrts( APIView):
    def get(self,request):
        data=execute("select * from Concerts")
        return JsonResponse(serialize(data[0],data[1]),safe=False)
class Concert( APIView):
     def get(self,request,pk):
        data=execute("select * from concerts where id = %s;",[str(pk)])
        print(data)
        return JsonResponse(serialize_one(data[0],data[1]),safe=False)
     

class Musics( APIView):
    def get(self,request):
        data=execute("select * from musics")
    
        return JsonResponse(serialize(data[0],data[1]),safe=False)
class Music( APIView):
    def get(self,request,pk):
        data=execute("select * from musics where id = %s;",[str(pk)])
        return JsonResponse(serialize_one(data[0],data[1]),safe=False)

class SingerAlbum( APIView):
    def get(self,request,album_pk):
        data=execute("select * from musics where album_id = %s;",[str(album_pk)])
        return JsonResponse(serialize(data[0],data[1]),safe=False)
class AlbumSong(AuthorizationMixin, APIView):
    def get(self,request,album_pk):
        data=execute("select * from musics where album_id = %s;",[str(album_pk)])
        return JsonResponse(serialize(data[0],data[1]),safe=False)
    
class PlayList( APIView):
    def get(self,request,playlist_pk):
        data=execute(" select * from get_musics_in_playlist(%s)",[str(playlist_pk)])
        return JsonResponse(serialize(data[0],data[1]),safe=False)
    
 
