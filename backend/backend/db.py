from helper import *
def get_liked(music_id:int,user_id:int)-> bool:
    print(execute("select * from musiclikes where music_id=%s and user_id=%s ",[music_id,user_id]))
    return bool(len(execute("select * from musiclikes where music_id=%s and user_id=%s ",[music_id,user_id])[1]))