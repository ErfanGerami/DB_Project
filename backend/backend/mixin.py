from django.http import JsonResponse
from rest_framework.views import APIView
from helper import *
from django.http import JsonResponse
from django.conf import settings
from rest_framework.views import APIView
import jwt
from django.contrib.auth.models import User
from django.utils.decorators import method_decorator
from django.contrib.auth.models import AnonymousUser
from django.views.decorators.csrf import csrf_exempt

@method_decorator(csrf_exempt, name='dispatch')
class AuthorizationMixin:
    def dispatch(self, request, *args, **kwargs): 
        auth_header = request.headers.get('Authorization')
        
        if auth_header:
            try:
                token_type, token = auth_header.split()
                if token_type.lower() == 'bearer':
                    try:
                            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
                            print(payload)
                    except jwt.ExpiredSignatureError:
                        return JsonResponse({"message": "token expired"}, status=401)
                    except jwt.InvalidTokenError:
                        return JsonResponse({"message": "invalid token"}, status=401)
                    rows = execute("SELECT * FROM users WHERE  username=%s", [payload.get("username")])
                    print(rows[1])
                    if len(rows[1]) != 1:

                        return JsonResponse({"message": "User not found or multiple users found"}, status=401)
                    #request.user=AnonymousUser  ()
                    request.COOKIES["id"]=rows[1][0][0]
                    request.COOKIES["username"]=rows[1][0][1]

                    
                else:
                    return JsonResponse({"message": "Invalid token"}, status=401)
            except ValueError:
                return JsonResponse({"error": "Invalid Authorization header format"}, status=401)
            except jwt.DecodeError:
                return JsonResponse({"error": "Invalid token"}, status=401)
        else:
            return JsonResponse({"error": "Authorization header missing"}, status=401)

        # Ensure to call super().dispatch() to pass control to the next middleware or view
        return super().dispatch(request, *args, **kwargs)
    

@method_decorator(csrf_exempt, name='dispatch')
class SingerAuthorizationMixin:
    def dispatch(self, request, *args, **kwargs): 
        auth_header = request.headers.get('Authorization')
        
        if auth_header:
            try:
                token_type, token = auth_header.split()
                if token_type.lower() == 'bearer':
                    try:
                            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
                    except jwt.ExpiredSignatureError:
                        return JsonResponse({"message": "token expired"}, status=401)
                    except jwt.InvalidTokenError:
                        return JsonResponse({"message": "invalid token"}, status=401)
                    rows = execute("SELECT * FROM users WHERE  username=%s", [payload.get("username")])
                    if len(rows[1]) != 1:

                        return JsonResponse({"message": "User not found or multiple users found"}, status=401)
                    #request.user=AnonymousUser  ()
                  
                    print( execute("select is_singer from users where id=%s",[rows[1][0][0]]))
                   

                    if(not execute("select is_singer from users where id=%s",[rows[1][0][0]])[1][0][0]):
                        return JsonResponse({"message": "User is not a singer"}, status=401)
                    request.COOKIES["id"]=rows[1][0][0]
                    request.COOKIES["username"]=rows[1][0][1]

                    
                else:
                    return JsonResponse({"message": "Invalid token"}, status=401)
            except ValueError:
                return JsonResponse({"error": "Invalid Authorization header format"}, status=401)
            except jwt.DecodeError:
                return JsonResponse({"error": "Invalid token"}, status=401)
        else:
            return JsonResponse({"error": "Authorization header missing"}, status=401)

        # Ensure to call super().dispatch() to pass control to the next middleware or view
        return super().dispatch(request, *args, **kwargs)
