import pandas as pd
from sqlalchemy import create_engine,text
from sklearn.metrics.pairwise import cosine_similarity
import psycopg2


conn = psycopg2.connect(
    dbname='ballmer_peak', 
    user='ballmer_peak', 
    password='ballmer_peak',  
    host='127.0.0.1',          
    port='5432'                
)

cur = conn.cursor()




DATABASE_TYPE = 'postgresql'
DBAPI = 'psycopg2'
ENDPOINT = '127.0.0.1'  
USER = 'ballmer_peak'
PASSWORD = 'ballmer_peak'
PORT = 5432
DATABASE = 'ballmer_peak'


DATABASE_URL = f"{DATABASE_TYPE}+{DBAPI}://{USER}:{PASSWORD}@{ENDPOINT}:{PORT}/{DATABASE}"

engine = create_engine(DATABASE_URL)

query = "select * from get_interactions();"
df = pd.read_sql(query, engine)

aggregated_data = df.groupby(['__id', '_mid']).agg({'inter': 'sum'}).reset_index()

user_item_matrix = aggregated_data.pivot(index='__id', columns='_mid', values='inter')
user_item_matrix.fillna(0, inplace=True)

user_similarity = cosine_similarity(user_item_matrix)
user_similarity_df = pd.DataFrame(user_similarity, index=user_item_matrix.index, columns=user_item_matrix.index)

def predict(user_id, user_similarity, user_item_matrix):
    sim_scores = user_similarity[user_id]
    
    predicted_scores = user_item_matrix.T.dot(sim_scores) / sim_scores.sum()
    
    return predicted_scores

def get_top_n_recommendations(user_id, predictions, n=10):
    top_n_recommendations = predictions.sort_values(ascending=False).head(n)
    return top_n_recommendations

query = "select id from users"
df = pd.read_sql(query, engine)
print(df.values)

for i in df.values:
    user_id=i[0]
    if(user_id not in user_similarity_df):
        continue
    print(user_id)
    print("refrf")

    predictions = predict(user_id, user_similarity_df, user_item_matrix)
    top_10_recommendations = get_top_n_recommendations(user_id, predictions, n=10)

    l=top_10_recommendations.keys()
    for pred in range(len(l)):
        with engine.connect() as connection:
                    query_insert = text("INSERT INTO predictions (user_id, music_id, rank) VALUES (:user_id, :music_id, :rank)")
                    cur.execute(f"INSERT INTO predictions (user_id, music_id, rank) VALUES ({int(user_id)}, { int(l[pred])}, {pred+1})")

                    conn.commit()

cur.close()
conn.close()
                    
    

