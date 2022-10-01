# NOTE: Suppress service URL deprecation warnings.  See [0] for details.
#
# [0] https://github.com/boto/botocore/issues/2705
import warnings
warnings.filterwarnings('ignore', category=FutureWarning, module='botocore.client')

import base64
import boto3
import hashlib
import hmac
import logging
import os
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

API_SHARED_SECRET = os.environ.get("API_SHARED_SECRET")
SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL")

def lambda_handler(event, context):
    data = event.get("body")
    headers = event.get("headers")
    if event.get("isBase64Encoded"):
        data = base64.b64decode(data)

    digest = hmac.new(API_SHARED_SECRET.encode('utf-8'), data, digestmod=hashlib.sha256).digest()
    computed_hmac = base64.b64encode(digest)
    hmac_header = headers.get('X-Shopify-Hmac-Sha256')

    if not hmac_header or not hmac.compare_digest(computed_hmac, hmac_header.encode('utf-8')):
        logger.error(f'HMAC authentication failed: expected "{computed_hmac}", received "{hmac_header}".')
        return { "statusCode" : 401 }

    sqs = boto3.client('sqs')
    response = sqs.send_message(
        MessageBody=data.decode('utf-8'),
        MessageGroupId="1",
        MessageDeduplicationId=str(uuid.uuid4()),
        QueueUrl=SQS_QUEUE_URL,
    )

    msg_id = response['MessageId']
    logger.info(f'Enqueued {msg_id}.')

    return { "statusCode": 200 }
