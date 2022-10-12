def handler(event, context):
    body = """
        <html>
            <head>
                <title>AWS Lambda Function</title>
            </head>
            <body>
                <p>This is from AWS Lambda Function</p>
            </body>
        </html>
    """
    response = {
        "statusCode": 200,
        "statusDescripion": "OK",
        "headers": {
            "Content-Type": "text/html; charset=utf-8"
        },
        "body": body
    }
    return response
