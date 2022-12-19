# NOTE: Suppress service URL deprecation warnings.  See [0] for details.
#
# [0] https://github.com/boto/botocore/issues/2705
import warnings
warnings.filterwarnings('ignore', category=FutureWarning, module='botocore.client')

from botocore.exceptions import ClientError
from collections import defaultdict
from pyactiveresource.connection import ResourceNotFound
from sys import exit
import boto3
import logging
import os
import random
import shopify
import string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

AWS_COGNITO_USER_POOL_ID = os.environ.get("AWS_COGNITO_USER_POOL_ID")
SHOPIFY_API_VERSION = "2022-07"
SHOPIFY_PASS_ARN = os.environ.get("SHOPIFY_PASS_ARN")
SHOPIFY_SHOP_URL = os.environ.get("SHOPIFY_SHOP_URL")
TAG_PREFIX = "authbot:"

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

def get_secret(client, arn):
    response = client.get_secret_value(SecretId=arn)
    return response["SecretString"]

def lambda_handler(event, context):
    fulfillments = set()
    groups = set()
    products_ids = set()
    smclient = boto3.client('secretsmanager')

    order = event["detail"]["payload"]
    order_id = order["id"]
    logger.info(f"Processing order ID {order_id}")
    customer_email = order.get("customer", {}).get("email")
    if not customer_email:
        logger.warn(f"Oder {order_id} doesn't have customer email! Exiting.")
        sys.exit()

    shopify_pass = get_secret(smclient, SHOPIFY_PASS_ARN)
    shopify_session = shopify.Session(SHOPIFY_SHOP_URL, SHOPIFY_API_VERSION, shopify_pass)
    shopify.ShopifyResource.activate_session(shopify_session)

    for item in order.get("line_items", []):
        product_id = item['product_id']
        logger.info(f"Found product {product_id}")
        products_ids.add(product_id)

    for product in shopify.Product.find(ids=",".join([str(x) for x in products_ids])):
        for tag in product.tags.split(","):
            if tag.startswith(TAG_PREFIX):
                groups.add(tag.replace(TAG_PREFIX, ""))

        if len(groups) < 1:
            # Nothing to do
            continue

        fulfillments.add(item['id'])

    cognito_client = boto3.client("cognito-idp")
    cognito_groups = cognito_client.list_groups(UserPoolId=AWS_COGNITO_USER_POOL_ID)
    cognito_groups = [x['GroupName'] for x in cognito_groups['Groups']]

    try:
        logger.info(f"Creating user {customer_email}")
        cognito_client.admin_create_user(
            DesiredDeliveryMediums=["EMAIL"],
            TemporaryPassword=generate_temporary_password(),
            UserAttributes=[
                {"Name": "email_verified", "Value": "True"},
                {"Name": "email", "Value": customer_email},
            ],
            UserPoolId=AWS_COGNITO_USER_POOL_ID,
            Username=customer_email,
        )
    except ClientError as error:
        if error.response['Error']['Code'] == 'UsernameExistsException':
            logger.info(f"User {customer_email} already exists. Skipping creation.")
        elif error.response['Error']['Code'] == 'CodeDeliveryFailureException':
            logger.warning(f"User {customer_email} created with error {error}")
        else:
            raise error

    for group in groups:
        if not group in cognito_groups:
            try:
                logger.info(f"Creating group {group}")
                cognito_client.create_group(
                    Description=f"Created by AuthBot2.",
                    GroupName=group,
                    UserPoolId=AWS_COGNITO_USER_POOL_ID,
                )
            except:
                logger.error(f"Can't create group {group}!")
                raise

        logger.info(f"Adding {customer_email} to {group}")
        cognito_client.admin_add_user_to_group(
            GroupName=group,
            UserPoolId=AWS_COGNITO_USER_POOL_ID,
            Username=customer_email,
        )

    for fulfillment_order in shopify.FulfillmentOrders().find(order_id=order_id):
        items = [{'id': f"gid://shopify/FulfillmentOrderLineItem/{item.id}",'quantity': 1}
                 for item in filter(lambda x: x.line_item_id in fulfillments, fulfillment_order.line_items)]
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
