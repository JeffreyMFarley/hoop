import os
import os.path
import random
import sys

from flask import Flask, jsonify, request


TABLE = {
    'brute': 'brutethink.txt',
    'easy': 'easy-names.txt',
    'name': 'names.txt',
    'star': 'stars.txt',
    'noun': 'nouns.txt',
    'verb': 'verbs.txt'
}


# where is this module?
thisDir = os.path.dirname(__file__)


def to_absolute(fileName):
    return os.path.join(thisDir, fileName)


def load(fileName):
    with open(fileName, 'r') as f:
        for line in f:
            yield line.strip()


def getName(source, size=10):
    fileName = TABLE[source]

    words = [l for l in load(to_absolute(fileName))]

    for i in range(0, size):
        yield random.choice(words)


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

@app.route("/")
def root():
    return jsonify([request.base_url + x for x in TABLE.keys()])


@app.route('/brute')
def brute():
    return jsonify(list(getName('brute')))


@app.route('/easy')
def easy():
    return jsonify(list(getName('easy')))


@app.route('/name')
def name():
    return jsonify(list(getName('name')))


@app.route('/star')
def star():
    return jsonify(list(getName('star')))


@app.route('/noun')
def noun():
    return jsonify(list(getName('noun')))


@app.route('/verb')
def verb():
    return jsonify(list(getName('verb')))

# run the app.
if __name__ == "__main__":
    # Setting debug to True enables debug output. This line should be
    # removed before deploying a production app.
    app.debug = True
    app.run('0.0.0.0')
