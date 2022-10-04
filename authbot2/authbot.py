# NOTE: Suppress service URL deprecation warnings.  See [0] for details.
#
# [0] https://github.com/boto/botocore/issues/2705
import warnings
warnings.filterwarnings('ignore', category=FutureWarning, module='botocore.client')

from botocore.exceptions import ClientError
from collections import defaultdict
import boto3
import json
import logging
import os
import random
import shopify
import string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SYNC_MAP = {
    7596932628710: 'AllHolidays2022', # "all-holidays-ticket-2022-pass"
    7534667235558: 'Benefactors', # "spring-2022-benefactors-support-the-satanic-estate"
    7598116438246: 'AllConferences2022', # "all-conferences-ticket-2022"
    7920168337638: 'OverdoseAwareness2022', # "the-satanic-temple-soberfaction-international-overdose-awareness-day-memorial-event"
    7894734995686: 'Temple23August2022',    # "copy-of-8-23-22-violence"
    7885895401702: 'Temple30August2022', # "8-30-22-the-paradox-and-dangers-of-superstitions"
    7886411038950: 'Temple6September2022', # "9-06-22-other-voice-military-conditioning-traumas"
    7920810557670: 'Temple13September2022', # "9-13-22-satanic-immigrants"
    7921196695782: 'Temple20September2022', # "9-20-22-umoja"
    7921198072038: 'Temple4October2022',  # "10-04-22-satanic-culture-and-me"
    7921198661862: 'Temple18October2022', # "10-18-22-memento-mori"
    7923734348006: 'Temple25October2022', # "10-25-22-inviolable-black-mass"
    7927605166310: 'Temple1November2022', # "11-01-22-continuing-cultural-rituals"
    7934184128742: 'Temple6December2022', # "copy-of-12-06-22-empathy-within-reason"
}

# FIXME: Use secret manager instead
AWS_COGNITO_USER_POOL_ID = os.environ.get("AWS_COGNITO_USER_POOL_ID")
SHOPIFY_API_VERSION = "2022-07"
SHOPIFY_KEY_ARN = os.environ.get("SHOPIFY_KEY_ARN")
SHOPIFY_PASS_ARN = os.environ.get("SHOPIFY_PASS_ARN")
SHOPIFY_SHOP_URL = os.environ.get("SHOPIFY_SHOP_URL")
SLACK_BOT_TOKEN_ARN = os.environ.get("SLACK_BOT_TOKEN_ARN")

def generate_temporary_password() -> str:
    return "".join(random.choice(string.ascii_letters) for _ in range(20)) + "".join(
        random.choice(string.digits) for _ in range(3)
    )

def get_secret(client, arn):
    response = client.get_secret_value(SecretId=arn)
    return response["SecretString"]

def lambda_handler(event, context):
    # smclient = boto3.client('secretsmanager')
    # shopify_key = get_secret(smclient, SHOPIFY_KEY_ARN)
    # shopify_pass = get_secret(smclient, SHOPIFY_PASS_ARN)
    # slack_bot_token = get_secret(smclient, SLACK_BOT_TOKEN_ARN)

    users = defaultdict(set)

    for record in event.get("Records"):
        order = json.loads(record["body"])
        order = order["order"]
        logger.info(f"Processing order ID {order['id']}")
        customer_email = order["customer"]["email"]
        if not customer_email:
            log.warn(f"Oder {order['id']} doesn't have customer email!")
            continue

        for product in order["line_items"]:
            if SYNC_MAP.get(product['product_id']):
                users[customer_email].add(SYNC_MAP[product['product_id']])

    client = boto3.client("cognito-idp")
    for user, groups in users.items():
        if len(groups) > 0:
            try:
                logger.info(f"Creating user {user}")
                client.admin_create_user(
                    UserPoolId=AWS_COGNITO_USER_POOL_ID,
                    Username=user,
                    UserAttributes=[
                        {"Name": "email_verified", "Value": "True"},
                        {"Name": "email", "Value": user},
                    ],
                    TemporaryPassword=generate_temporary_password(),
                    DesiredDeliveryMediums=["EMAIL"],
                )
            except ClientError as error:
                if error.response['Error']['Code'] == 'UsernameExistsException':
                    logger.warn(f"User {user} already exists")
                else:
                    raise error

            for group in groups:
                logger.info(f"Adding {user} to {group}")
                client.admin_add_user_to_group(
                    UserPoolId=AWS_COGNITO_USER_POOL_ID,
                    Username=user,
                    GroupName=group,
                )
