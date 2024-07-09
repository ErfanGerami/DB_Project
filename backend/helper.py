import jwt
from datetime import datetime, timedelta
from backend.settings import SECRET_KEY,EXPIRATION_TIME
from django.db import connection
import hashlib

def serialize(desc:tuple,inp:list):
    resp=list()

    for rec in inp:
        dic=dict()
        for i in range(len(desc)):
            dic[desc[i]]=rec[i]
        resp.append(dic)
    return resp


def serialize_one(desc,inp:tuple):
    resp=dict()
    for i in range(len(desc)):
            resp[desc[i]]=inp[0][i]
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