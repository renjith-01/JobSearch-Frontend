
from flask import Flask

app = Flask(__name__)

@app.route('/', methods=['GET'])
def health_check():
    return {'status' : 'Pass', 'details' : 'Working ...'}, 200
