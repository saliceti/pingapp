#!/usr/bin/env ruby
require "net/https"
require "uri"

@interval = 1
@timeout = 10.0

testURL = ARGV[0]
@validation = ARGV[1]

uri = URI.parse(testURL)
http = Net::HTTP.new(uri.host, uri.port)
http.read_timeout = @timeout
if uri.scheme == 'https'
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

@slowest_time = 0.0
@failures = 0
@successes = 0

def tputs(text)
  time = Time.now
  puts time.strftime("%H:%M:%S") + ' ' + text
end

def update_slowest(t0)
  diff = Time.now - t0
  if diff > @slowest_time
    @slowest_time = diff
  end

end

Signal.trap("INT") {
  puts "Exiting..."
  puts "Successful requests: #{@successes}"
  puts "Failures: #{@failures}"
  puts "Slowest time: #{@slowest_time}"
  exit
}

while true
  sleep @interval

  t0 = Time.now
  begin
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
  rescue Exception => e
    tputs "ERROR: #{e.message}: #{e.cause}"
    update_slowest(t0)
    @failures += 1
    next
  end

  if response.code == '200'
    if not @validation or response.body.include? @validation
      tputs "OK"
      @successes += 1
    else
      tputs "ERROR: response does not contain string: #{@validation}"
      @failures += 1
    end
  else
    tputs "ERROR: Response code: " + response.code
    @failures += 1
  end
  update_slowest(t0)

end
