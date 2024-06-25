from django.db import connection
from helper import *
from django.http import JsonResponse,HttpResponse,HttpRequest
from  rest_framework import status 
import jwt
from datetime import datetime, timedelta
from .settings import SECRET_KEY,EXPIRATION_TIME

def testView(request):

    mess=list()
    resp=dict()
    with connection.cursor() as cursor:
        cursor.description
        cursor.execute("SELECT * FROM test;")
        rows = cursor.fetchall()
        print(rows)
        resp=serialize_one(rows[0],cursor.description)
    return JsonResponse(resp,safe=False,status=200)
        


def generateTokenView(request:HttpRequest):
    if(request.method=='POST'):
        username=request.POST["username"]
        password=request.POST["password"]

        return JsonResponse({'token':generate_jwt_token(username,password)})
    return JsonResponse({"error":"get method is not supported"},status=status.HTTP_405_METHOD_NOT_ALLOWED)
         