import json
import random

def root_handler(event, context):

    fortunes = [
        "We'll burn that bridge when we come to it",
        "Two wrongs don't make a right, but three rights make a left",
        "That horse has sailed",
        "You can't have everything, where would you put it?",
        "What's the difference between a joke and a rhetorical question?",
        "I own the world's worst thesaurus. Not only is it awful, it's awful.",
        "6:30 is the best time on a clock, hands down.",
        "I remember my Grandfather's last words: Hold the ladder steady",
        "Geology rocks, but geography’s where it’s at.",
    ]

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps({
           'content': random.choice(fortunes)
        })
    }
