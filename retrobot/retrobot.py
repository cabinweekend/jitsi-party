# NOTE: Suppress service URL deprecation warnings.  See [0] for details.
#
# [0] https://github.com/boto/botocore/issues/2705
import warnings
warnings.filterwarnings('ignore', category=FutureWarning, module='botocore.client')

import boto3
import datetime
import json
import logging
import os
import shopify

logger = logging.getLogger()
logger.setLevel(logging.INFO)

BACKFILL_BUS_ARN = os.environ.get("BACKFILL_BUS_ARN")
BACKFILL_DAYS = int(os.environ.get("BACKFILL_DAYS", 7))
SHOPIFY_API_VERSION = "2022-07"
SHOPIFY_PASS_ARN = os.environ.get("SHOPIFY_PASS_ARN")
SHOPIFY_SHOP_URL = os.environ.get("SHOPIFY_SHOP_URL")

def get_secret(client, arn):
    response = client.get_secret_value(SecretId=arn)
    return response["SecretString"]

def lambda_handler(event, context):
    ebclient = boto3.client('events')
    smclient = boto3.client('secretsmanager')

    if event.get("days", 0):
        BACKFILL_DAYS = event.get("days")

    timestamp = (datetime.datetime.now()-datetime.timedelta(days=BACKFILL_DAYS)).isoformat()

    shopify_pass = get_secret(smclient, SHOPIFY_PASS_ARN)
    shopify_session = shopify.Session(SHOPIFY_SHOP_URL, SHOPIFY_API_VERSION, shopify_pass)
    shopify.ShopifyResource.activate_session(shopify_session)

    if shopify.Order.count(updated_at_min=timestamp) > 0:
        for order in shopify.Order.find(updated_at_min=timestamp):
            ebclient.put_events(Entries=[{
                'Detail': json.dumps({'payload': order.to_dict()}),
                'DetailType': 'retrobot',
                'EventBusName': BACKFILL_BUS_ARN,
                'Source': 'retrobot',
                'Time': datetime.datetime.now(),
            }],)

    shopify.ShopifyResource.clear_session()
