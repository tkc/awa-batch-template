import json
import urllib.request
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # SNS メッセージのパース
    message = json.loads(event['Records'][0]['Sns']['Message'])
    logger.info("Message: " + str(message))
    
    # CloudWatch Alarm からの情報を取得
    alarm_name = message.get('AlarmName', 'Unknown Alarm')
    alarm_description = message.get('AlarmDescription', 'No description available')
    alarm_reason = message.get('NewStateReason', 'No details available')
    alarm_time = message.get('StateChangeTime', 'Unknown time')
    alarm_region = message.get('Region', 'Unknown region')
    
    # ジョブ詳細を取得（可能な場合）
    job_details = "No specific job details available"
    if 'Trigger' in message:
        dimensions = message.get('Trigger', {}).get('Dimensions', [])
        for dim in dimensions:
            if dim.get('name') == 'JobDefinition':
                job_details = f"Job Definition: {dim.get('value', 'Unknown')}"
    
    # Slack 通知のペイロード作成
    slack_message = {
        'text': ':rotating_light: AWS Batch Job Failed :rotating_light:',
        'attachments': [
            {
                'color': 'danger',
                'fields': [
                    {
                        'title': 'Alarm Name',
                        'value': alarm_name,
                        'short': False
                    },
                    {
                        'title': 'Description',
                        'value': alarm_description,
                        'short': False
                    },
                    {
                        'title': 'Reason',
                        'value': alarm_reason,
                        'short': False
                    },
                    {
                        'title': 'Time',
                        'value': alarm_time,
                        'short': True
                    },
                    {
                        'title': 'Region',
                        'value': alarm_region,
                        'short': True
                    },
                    {
                        'title': 'Job Details',
                        'value': job_details,
                        'short': False
                    }
                ],
                'footer': 'AWS Batch Monitoring',
                'ts': int(context.get_remaining_time_in_millis() / 1000)
            }
        ]
    }
    
    # Slack Webhook URL を環境変数から取得
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    
    # Slack 通知の送信
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(slack_message).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    
    try:
        response = urllib.request.urlopen(req)
        logger.info(f"Slack notification sent successfully. Status: {response.getcode()}")
        return {
            'statusCode': 200,
            'body': 'Notification sent to Slack successfully!'
        }
    except Exception as e:
        logger.error(f"Error sending to Slack: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error sending notification to Slack: {str(e)}"
        }
