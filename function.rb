# frozen_string_literal: true

require 'json'
require 'jwt'
require 'pp'

def main(event:, context:)
  # You shouldn't need to use context, but its fields are explained here:
  # https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
  requestHandler(event)
end

def response(body: nil, status: 200)
  {
    body: body ? body.to_json + "\n" : '',
    statusCode: status
  }
end

def requestHandler(event)
  headers = event['headers']
  content_type = headers['Content-Type'] || ""
  authorization = headers['Authorization'] || ""

  httpMethod = event['httpMethod'] || ""
  path = event['path']
  post_body = event['body'] || ""

  if path == '/'
    result = handleGET(httpMethod, authorization)
    response(body: result[0], status: result[1])
  elsif path == '/token'
    result = handlePOST(httpMethod, post_body, content_type)  
    response(body: result[0], status: result[1])
  else
    response(body: "Other requests", status: 404)
  end
end


def valid_json(json_string)
  begin
    JSON.parse(json_string)
    return true
  rescue JSON::ParserError => e
    return false
  end
end

# return decodeded token/error, status code
def handlePOST(httpMethod, post_body, content_type)
  if httpMethod != 'POST'
    return 'Do not use the appropriate HTTP method', 405
  end

  if content_type != 'application/json'
    return "Invalid Content Type",415
  end

  if !valid_json(post_body)
    return "Invalid Json body", 422
  end 

  ENV['JWT_SECRET'] = 'NOTASECRET'
  payload = {
    data: JSON.parse(post_body),
    exp: Time.now.to_i + 5, #expire time 5s
    nbf: Time.now.to_i + 2  #not before time: 2s
  }

  return {token: (JWT.encode payload, ENV['JWT_SECRET'], 'HS256')}, 201
end

def handleGET(httpMethod, authorization)
  if httpMethod != 'GET'
    return 'Do not use the appropriate HTTP method', 405
  end 

  parserResults = authorization.split('Bearer ')
  token = (parserResults[1] || "")

  if !parserResults[0].empty? and token.empty?
    return "Invalid header provided", 403
  end

  ENV['JWT_SECRET'] = 'NOTASECRET'
  begin
    decodedToken =  JWT.decode token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }
    #puts decodedToken
    #puts decodedToken['data']
  rescue JWT::ImmatureSignature
    return "Not ready for reponse! ",401  
  rescue JWT::ExpiredSignature
    return "ExpiredSignature! ", 401  
  rescue JWT::DecodeError
    return "Invalid token", 403 
  end

  return decodedToken[0]["data"], 200
end


if $PROGRAM_NAME == __FILE__
  # If you run this file directly via `ruby function.rb` the following code
  # will execute. You can use the code below to help you test your functions
  # without needing to deploy first.
  ENV['JWT_SECRET'] = 'NOTASECRET'

  # Call /token
  PP.pp main(context: {}, event: {
               'body' => '{"name": "bboe"}',
               'headers' => { 'Content-Type' => 'application/json' },
               'httpMethod' => 'POST',
               'path' => '/token'
             })

  # Generate a token
  payload = {
    data: { user_id: 128 },
    exp: Time.now.to_i + 1,
    nbf: Time.now.to_i
  }
  token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  # Call /
  PP.pp main(context: {}, event: {
               'headers' => { 'Authorization' => "Bearer #{token}",
                              'Content-Type' => 'application/json' },
               'httpMethod' => 'GET',
               'path' => '/'
             })
end
