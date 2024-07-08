"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from django.db import connection
import helper
from django.http import JsonResponse,HttpResponse
import jwt
from datetime import datetime, timedelta
from .settings import SECRET_KEY,EXPIRATION_TIME
from .views import *          
urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/login',login),
    path('auth/register',register),
    path('test',Test.as_view()),
    path('musics',Musics.as_view()),
    path('musics/<int:pk>',Music.as_view()),
    path('concerts',Conecrts.as_view()),
    path('concerts/<int:pk>',Concert.as_view()),
    path('singer/album/<int:album_pk>',SingerAlbum.as_view()),
    path('album/<int:album_pk>',SingerAlbum.as_view()),
    path('playlists/<int:playlist_pk>',PlayList.as_view()),

]
