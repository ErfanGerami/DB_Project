import jwt
from datetime import datetime, timedelta
from backend.settings import SECRET_KEY,EXPIRATION_TIME
from django.db import connection

def serialize(inp:list,desc:tuple):
    resp=list()

    for rec in inp:
        dic=dict()
        for i in range(len(inp)):
            dic[desc[i][0]]=rec[i]
        resp.append(dic)
    return resp


def serialize_one(inp:tuple,desc):
    resp=dict()
    for i in range(len(inp)):
            resp[desc[i][0]]=inp[i]
    return resp
def generate_jwt_token(username,password):
    expiration = datetime.utcnow() + EXPIRATION_TIME
    payload = {
        'username': username,
        'exp': expiration,
        'password':password
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return token


def authenticate(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])

        row=execute("select * from users where password=%s  and username=%s ",[payload["password"],payload["username"]]);
        if(len(row)!=1):
            return None
        return row[0][0]
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
     
def execute(query:str,params):
    rows=list()
    with connection.cursor() as cursor:
            cursor.execute(query,params)
            rows = cursor.fetchall()
    return rows
    

     
     
     