import jwt
from datetime import datetime, timedelta
from backend.settings import SECRET_KEY,EXPIRATION_TIME
from django.db import connection
import hashlib
from backend.settings import MAX_UPLOAD_SIZE,MEDIA_ROOT
import os

def serialize(desc:tuple,inp:list,function=lambda x, y: None,request=None):
    resp=list()

    for rec in inp:
        dic=dict()
        for i in range(len(desc)):
            dic[desc[i]]=rec[i]
        function(dic,request)
        resp.append(dic)
    return resp


def serialize_one(desc,inp:tuple,function=lambda x, y: None,request=None):
    resp=dict()
    for i in range(len(desc)):
            resp[desc[i]]=inp[0][i]
    function(resp,request)
    return resp
def generate_jwt_token(username,password,id,email,birthdate,address,has_membership,money,is_singer):
    expiration = datetime.utcnow() + EXPIRATION_TIME
    payload = {
        'id':str(id),
        'email':email,
        'birthdate':str(birthdate),
        'address':address,
        'has_membership':str(has_membership),
        'money':str(money),
        'is_singer':str(is_singer),
        'username': username,
        'exp': expiration,
        
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return token


def authenticate(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])

        row=execute("select * from users where password=%s  and username=%s ",[payload["password"],payload["username"]])[1];
        if(len(row)!=1):
            return None
        return row[0][0]
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
     
def execute(query:str,params=None,get_result=True,commit=False):
    rows=list()
    desc=list()
    with connection.cursor() as cursor:
            cursor.execute(query,params)
            if(get_result):
                desc=[col[0] for col in cursor.description]
            
            if(get_result):
                rows = cursor.fetchall()
            if(commit):
                 connection.commit() 
    if(get_result):       
        return [desc,list(rows)]    
    else:
         return None
   
    
def check(dic,*args):
    for attrib in args:
          if(attrib not in dic):
               return False,attrib
    return True,None

def hash(data):
    hash_object = hashlib.sha256()
    hash_object.update(data.encode('utf-8'))
    return hash_object.hexdigest()


def change(data,new_name,table1_attrib:str,table2:str,table2_atttribs:str):
    for i in data:
        i[new_name]=execute(f"select  {table2_atttribs} from {table2} where id={i[table1_attrib]}")[1][0][0]
    return data
     
     
     
def save_file(file,formats:list,dest_name,dest_path=""):
    if file.size > MAX_UPLOAD_SIZE:
            return False,"File size exceeds the maximum limit ."
        
    file_extension = os.path.splitext(file.name)[1]
    print(file_extension)
    if (file_extension[1:len(file_extension)].lower() not in formats ):
         return False,f"{file_extension[1:len(file_extension)]} is not expected"
    file_path=os.path.join(dest_path, dest_name+file_extension)
    save_path = str(MEDIA_ROOT)+file_path
    print(MEDIA_ROOT)
    with open(save_path, 'wb+') as destination:
        for chunk in file.chunks():
            destination.write(chunk)
    return True,file_path
def get_highest_id(table):
     id_query=execute(f"select MAX(id) from {table}")
     if(len(id_query)[1]):
          
        return id_query[1][0][0]
     else:
          return 1