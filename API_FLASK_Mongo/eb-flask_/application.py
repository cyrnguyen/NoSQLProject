from flask import Flask
from flask import jsonify
from flask import request
from flask_pymongo import PyMongo
import pandas as pd
import json
from pycountry_convert import country_alpha2_to_country_name,country_name_to_country_alpha3
from datetime import datetime

application = Flask(__name__)

application.config['MONGO_DBNAME'] = 'year2'
#application.config['MONGO_URI'] = 'mongodb://localhost:27017/gdelt' endofyear
application.config['MONGO_URI'] = 'mongodb://172.31.41.137:27017/year2'


mongo = PyMongo(application)

def convert_country_alpha3(code2):
  try:
    code2 = ''.join(filter(str.isalpha, code2))	
    name = country_alpha2_to_country_name(code2)
    code3 = country_name_to_country_alpha3(name)
  except:
    code3 = "XXX"

  return code3

def get_datetime(date):
    year = int(date[:4])
    month = int(date[4:6])
    day = int(date[-2:])
    dt =datetime(year,month,day)
    return dt

def to_nestedjson(df):
    """ Convert to nested dictionary. """
    drec = dict()
    ncols = df.values.shape[1]
    for line in df.values:
        d = drec
        for j, col in enumerate(line[:-1]):
            if not col in d.keys():
                if j != ncols-2:
                    d[col] = {}
                    d = d[col]
                else:
                    d[col] = line[-1]
            else:
                if j!= ncols-2:
                    d = d[col]
    return drec


#countries = pd.read_csv("countries_table.csv")

# some bits of text for the page.
header_text = '''
    <html>\n<head> <title>API de requete de la base GDELT</title> </head>\n<body>'''
instructions = '''
    <p><em>Hint</em>: This is a RESTful web service! Append a query
    to the URL (for example: <code>/result?20050101_20101231</code>) to query 
    specific range date.</p>\n'''
home_link = '<p><a href="/">Back</a></p>\n'
footer_text = '</body>\n</html>'


# add a rule for the index page.
application.add_url_rule('/', 'index', (lambda: header_text +
    say_hello() + instructions + footer_text))

# add a rule when the page is accessed with a name appended to the site
# URL.
application.add_url_rule('/<username>', 'hello', (lambda username:
    header_text + say_hello(username) + home_link + footer_text))


@application.route('/hello/<username>', methods=['GET'])
# print a nice greeting.
def say_hello(username = "World"):
    return '<p>Hello %s!</p>\n' % username


#get value on date range : ?start=20100101&end=20101231 of shape YYYYMMDD
@application.route('/result', methods=['GET'])
def GetCountryMovingOpinion():
  DateStart = get_datetime(request.args.get('start'))
  DateEnd = get_datetime(request.args.get('end'))
  col = mongo.db.opinions
  output = []

  q = col.find({'day': {'$gte': DateStart, '$lt': DateEnd}})
    
  if q:
    for s in q:
      #print(s)
      output.append({'day' : s['day'], 'country' : s['country'],'Num_Mentions' : s['Num_Mentions'], 'AvgTone' : s['AvgTone']})
  else:
    output = "No such dates"
  return jsonify({'result' : output})


@application.route('/result2', methods=['GET'])
def GetCountryMovingOpinion2():
  DateStart = get_datetime(request.args.get('start'))
  DateEnd = get_datetime(request.args.get('end'))
  col = mongo.db.opinions

  q = col.find({'day': {'$gte': DateStart, '$lt': DateEnd}})
  df =  pd.DataFrame(list(q))
  df['country'] = df['country'].apply(lambda row: convert_country_alpha3(row))
  df["day"] = df["day"].apply(lambda row : row.strftime('%Y%m%d'))

  count = df[['day','country','Num_Mentions']]

  count_json = to_nestedjson(count)

  tone = df[['day','country','AvgTone']]

  tone_json = to_nestedjson(tone)

  final_json = json.dumps({"Frequency": count_json, "Tone": tone_json})
  return final_json

# run the app.
if __name__ == "__main__":
    # Setting debug to True enables debug output. This line should be
    # removed before deploying a production app.
    application.debug = True
    application.run()
