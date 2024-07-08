from django.db import connection
from helper import *
from django.http import JsonResponse,HttpResponse,HttpRequest
from  rest_framework import status 
import jwt
from datetime import datetime, timedelta
from .settings import SECRET_KEY,EXPIRATION_TIME
import hashlib
from helper import *

from django.views.decorators.csrf import csrf_exempt


def testView(request):

    mess=list()
    resp=dict()
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM test;")
        rows = cursor.fetchall()
       
        resp=serialize_one(rows[0],cursor.description)
    return JsonResponse(resp,safe=False,status=200)
        

@csrf_exempt
def generateTokenView(request:HttpRequest):
    if(request.method=='POST'):
        username=request.POST["username"]
        password=request.POST["password"]
        hash_object = hashlib.sha256()
        hash_object.update(password.encode('utf-8'))
        hash_hex = hash_object.hexdigest()

        row=execute("select * from users where password=%s  and username=%s ",[hash_hex,username]);
        if(len(row)!=1):
            return JsonResponse({"error":"no such user"},status=status.HTTP_400_BAD_REQUEST)
        

        return JsonResponse({'token':generate_jwt_token(username,hash_hex)})
    return JsonResponse({"error":"get method is not supported"},status=status.HTTP_405_METHOD_NOT_ALLOWED)
