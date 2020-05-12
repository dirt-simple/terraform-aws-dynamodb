'use strict';
var AWS = require("aws-sdk");
var sns = new AWS.SNS();

const REVISION_RECORD_TOPIC_ARN = process.env.REVISION_RECORD_TOPIC_ARN;
const MODEL_NAME = process.env.MODEL_NAME;
const MODEL_SCHEMA_VERSION = process.env.MODEL_SCHEMA_VERSION;
const MODEL_IDENTIFIER_FIELD = process.env.MODEL_IDENTIFIER_FIELD;

exports.handler = (event, context, callback) => {

    event.Records.forEach((record) => {
      console.log('Handling the following dynamodb record event: ', JSON.stringify(record));
      var newImage = AWS.DynamoDB.Converter.unmarshall(record.dynamodb.NewImage)
      var oldImage = AWS.DynamoDB.Converter.unmarshall(record.dynamodb.OldImage)
      
      var revision_record = construct_revision_record(
        newImage['last_updated_by'],
        MODEL_NAME,
        Object.keys(newImage).length === 0 ? oldImage[MODEL_IDENTIFIER_FIELD] : newImage[MODEL_IDENTIFIER_FIELD],
        oldImage,
        MODEL_SCHEMA_VERSION,
        newImage,
        MODEL_SCHEMA_VERSION
      )

      var event_message = construct_sns_revision_params(revision_record)
      console.info('Publishing the following dynamodb event record: ', JSON.stringify(event_message));
      sns.publish(event_message, function(err, data) {
        if (err) {
            console.error("Unable to send message. Error JSON:", JSON.stringify(err, null, 2));
            context.fail(JSON.stringify(err, null, 2))
        } else {
            console.log("Results from sending message: ", JSON.stringify(data, null, 2));
            context.succeed(JSON.stringify(err, null, 2))
        }
      });
    });

    callback(null, `Successfully processed ${event.Records.length} records.`);
}; 

function construct_revision_record(cognito_id, model_name, identifier, old_model=null, old_schema_version=null, new_model=null, new_schema_version=null) {
  return {
    "change_initiator": cognito_id,
    "model": model_name,
    "identifier": identifier,
    "old_image": old_model,
    "old_schema_version": old_schema_version ? old_schema_version : new_schema_version,
    "new_image": new_model,
    "new_schema_version": new_schema_version ? new_schema_version : old_schema_version,
    "envelope_version": "1.0",
    "timestamp": ((new Date()).getTime() / 1000)
  }
}

function construct_sns_revision_params(revision_record){
  var message = {}
  add_message(message, revision_record)
  add_messages_attrs(message, revision_record)
  add_additional_messages_attrs(message, revision_record)
  add_topic_arn(message, REVISION_RECORD_TOPIC_ARN)
  return message;
}

function add_message(message, revision_record){
  message['Message'] = JSON.stringify(revision_record)
}

function add_additional_messages_attrs(message, revision_record){
  if(process.env.ADDITIONAL_MODEL_IDENTIFIER_FIELD){
    const model_data = Object.keys(revision_record.new_image).length === 0 ? revision_record.old_image : revision_record.new_image
    process.env.ADDITIONAL_MODEL_IDENTIFIER_FIELD.split(":").forEach( identifier => {
      if(model_data[identifier]){
        message.MessageAttributes[identifier] = {
          'DataType': 'String',
          'StringValue': model_data[identifier]
        }  
      }
    })
  }
}

function add_messages_attrs(message, revision_record){
  message['MessageAttributes'] = {
    'envelope_version': {
        'DataType': 'String',
        'StringValue': revision_record.envelope_version
    },
    'old_schema_version': {
        'DataType': 'String',
        'StringValue': revision_record.old_schema_version
    },
    'new_schema_version': {
        'DataType': 'String',
        'StringValue': revision_record.new_schema_version
    },
    'model': {
        'DataType': 'String',
        'StringValue': revision_record.model
    }
  }
}
function add_topic_arn(message, arn){
  message['TopicArn'] = arn
}

