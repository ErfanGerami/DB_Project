import jwt
from datetime import datetime, timedelta
from backend.settings import SECRET_KEY,EXPIRATION_TIME

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
        print(payload)
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
     
     