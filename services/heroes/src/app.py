import json
import os
import os.path
import random
import sys

import psycopg2
from flask import abort, Flask, jsonify, request, Response


HERO_ORM = {
    'countryOfBirth': 'country_of_birth',
    'dateOfBirth': 'date_of_birth',
    'familyName': 'family_name',
    'givenName': 'given_name',
    'middleName': 'middle_name'
}

# where is this module?
thisDir = os.path.dirname(__file__)


def connection():
    user = os.getenv('POSTGRES_USER', 'postgres')
    password = os.getenv('POSTGRES_PASSWORD', '')
    database = os.getenv('POSTGRES_DB', 'main')
    host = os.getenv('POSTGRES_HOST', 'localhost')
    port = os.getenv('POSTGRES_PORT', 5432)

    dsn = "host={0} dbname={1} user={2} password={3} port={4}"
    return psycopg2.connect(dsn.format(host, database, user, password, port))

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

app = Flask(__name__)

@app.after_request
def after_request_func(response):
    response.access_control_allow_headers = ['Content-Type']
    response.access_control_allow_origin = '*'
    response.access_control_allow_methods = ['OPTIONS','POST','GET']
    return response

@app.route('/')
def index():
    fields = []
    data_rows = []

    with connection() as conn:
        with conn.cursor() as cursor:
          cursor.execute("SELECT * FROM applicant")
          fields = [desc[0] for desc in cursor.description]
          for row in cursor:
              data_rows.append(dict(zip(fields, row)))
    return jsonify(data_rows)


@app.route('/', methods=['POST'])
def add_new():
    body = {}

    # Extract the values
    if request.content_type == 'application/x-www-form-urlencoded':
        body = request.form.to_dict(flat=True)
    elif request.data:
        body = json.loads(request.data)
    else:
        return f'Unrecognized Content Type {request.content_type}', 400

    # Map the input params to the field name
    # hero = { HERO_ORM[k]: v for k, v in body.items() if k in HERO_ORM }

    # Insert into the database
    template = "INSERT INTO applicant ({0}) VALUES ({1}) RETURNING ID;"
    sql = template.format(', '.join(HERO_ORM.values()),
                          ', '.join(['%({0})s'.format(x) for x in HERO_ORM]))

    with connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, body)
            id = cursor.fetchone()[0]

    uri = f'{request.base_url}{id}'
    resp = Response(uri, 201)
    resp.location = uri

    return resp


@app.route('/<int:id>')
def get(id):
    fields = []
    record = {}

    with connection() as conn:
        with conn.cursor() as cursor:
          cursor.execute("SELECT * FROM applicant WHERE id = %s", (id, ))
          fields = [desc[0] for desc in cursor.description]
          record = cursor.fetchone()

    if record is None:
        return f'Unknown hero', 404

    return jsonify(dict(zip(fields, record)))


# run the app.
if __name__ == "__main__":
    # Setting debug to True enables debug output. This line should be
    # removed before deploying a production app.
    app.debug = True
    app.run('0.0.0.0')
