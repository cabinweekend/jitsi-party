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

FULFILLMENT_QUERY = '''
mutation fulfillmentCreateV2($fulfillment: FulfillmentV2Input!) {
  fulfillmentCreateV2(fulfillment: $fulfillment) {
    fulfillment {
      id
    }
    userErrors {
      field
      message
    }
  }
}'''

def generate_temporary_password() -> str:
    return "".join(random.choice(string.ascii_letters) for _ in range(20)) + "".join(
        random.choice(string.digits) for _ in range(3)
    )

def fulfill_order(fulfillment_order_id, fulfillment_order_line_item_ids):
    query = '''
    mutation fulfillmentCreateV2($fulfillment: FulfillmentV2Input!) {
      fulfillmentCreateV2(fulfillment: $fulfillment) {
        fulfillment {
          id
        }
        userErrors {
          field
          message
        }
      }
    }'''

    shopify.GraphQL().execute(query=query,
                              variables={'fulfillment': {
                                  'lineItemsByFulfillmentOrder': [{
                                      'fulfillmentOrderId': "gid://shopify/FulfillmentOrder/6048093339901",
                                      'fulfillmentOrderLineItems': [{
                                          'id': "gid://shopify/FulfillmentOrderLineItem/12795399176445",
                                          'quantity': 1
                                      }]
                                  }]
                              }})


def get_secret(client, arn):
    response = client.get_secret_value(SecretId=arn)
    return response["SecretString"]

def lambda_handler(event, context):
    smclient = boto3.client('secretsmanager')
    # slack_bot_token = get_secret(smclient, SLACK_BOT_TOKEN_ARN)

    users = defaultdict(set)
    fulfillments = defaultdict(set)

    # Extract user groups from the order
    for record in event.get("Records", []):
        order = json.loads(record["body"])
        logger.info(f"Processing order ID {order['id']}")
        customer_email = order.get("customer", {}).get("email")
        if not customer_email:
            logger.warn(f"Oder {order['id']} doesn't have customer email!")
            continue

        for item in order.get("line_items", []):
            if SYNC_MAP.get(item['product_id']):
                users[customer_email].add(SYNC_MAP[item['product_id']])
                fulfillments[order['id']].add(item['id'])

    if len(users.keys()) < 1:
        # Nothing left to do
        return

    cognito_client = boto3.client("cognito-idp")
    for user, groups in users.items():
        if len(groups) > 0:
            try:
                logger.info(f"Creating user {user}")
                cognito_client.admin_create_user(
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
                    logger.info(f"User {user} already exists")
                else:
                    raise error

            for group in groups:
                logger.info(f"Adding {user} to {group}")
                cognito_client.admin_add_user_to_group(
                    UserPoolId=AWS_COGNITO_USER_POOL_ID,
                    Username=user,
                    GroupName=group,
                )

    shopify_pass = get_secret(smclient, SHOPIFY_PASS_ARN)
    shopify_session = shopify.Session(SHOPIFY_SHOP_URL, SHOPIFY_API_VERSION, shopify_pass)
    shopify.ShopifyResource.activate_session(shopify_session)
    for order_id, line_items in fulfillments.items():
        for fulfillment_order in shopify.FulfillmentOrders().find(order_id=order_id):
            items = [{'id': f"gid://shopify/FulfillmentOrderLineItem/{item.id}",'quantity': 1}
                     for item in filter(lambda x: x.line_item_id in line_items, fulfillment_order.line_items)]
            if len(items) < 1:
                continue

            shopify.GraphQL().execute(query=FULFILLMENT_QUERY,
                                      variables={'fulfillment': {
                                          'lineItemsByFulfillmentOrder': [{
                                              'fulfillmentOrderId': f"gid://shopify/FulfillmentOrder/{fulfillment_order.id}",
                                              'fulfillmentOrderLineItems': items
                                          }]
                                      }})
    shopify.ShopifyResource.clear_session()
