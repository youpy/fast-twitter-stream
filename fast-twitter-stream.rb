require 'rubygems'
require 'sinatra'
require 'json'  
require 'tweetstream'  
require 'pit'

# doesn't work on thin and webrick
set :server, 'mongrel'

get '/' do
  <<HTML
  <html> <head>
    <title>Server Push</title>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.1/jquery.min.js"></script>
    <script src="/js/server_push.js"></script>
  </head>
  <body>
    <h1>Server Push</h1>
    <div id="content"></div>
  </body>
</html>
HTML
end

get '/js/server_push.js' do
  <<JS
$(function() {
  var xhr = new XMLHttpRequest();
  xhr.multipart = true;
  xhr.onreadystatechange = function() {
    if(xhr.readyState == 4) {
      var status = eval(xhr.responseText);
      $('#content').append('<p>' + status.text + '</p>');
    }
  };
  xhr.open("GET", "/push");
  xhr.send(null);
});
JS
end

get '/push' do
  boundary = '|||'
  response['Content-Type'] = 'multipart/x-mixed-replace; boundary="' + boundary + '"'

  MultipartResponse.new(boundary, 'text/javascript')
end

class MultipartResponse
  def initialize(boundary, content_type)
    @config = Pit.get("twitter.com", :require => {
        "username" => "your username in twitter",
        "password" => "your password in twitter"
      })

    @boundary = boundary
    @content_type = content_type
  end

  def each
    yield "--#{@boundary}\n"

    TweetStream::Client.new(@config['username'], @config['password']).sample do |status|  
      yield "Content-Type: #{@content_type}\n\n(#{status.to_json})\n--#{@boundary}\n"
    end  
  end
end
