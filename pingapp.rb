#!/usr/bin/env ruby
require "net/https"
require "uri"
require "logger"

@interval = 0.1
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

$stdout.sync = true
@logger = Logger.new(STDOUT)
@logger.level = Logger::INFO

@slowest_time = 0.0
@failures = 0
@successes = 0

@initial_time = Time.now

def update_slowest(t0)
  diff = Time.now - t0
  if diff > @slowest_time
    @slowest_time = diff
  end

end

Signal.trap("INT") {
  puts("Exiting...")
  time_taken = Time.now - @initial_time
  report = <<-EOF
Total time: #{time_taken}s
Successful requests: #{@successes}
Failures: #{@failures}
Slowest time: #{@slowest_time}
EOF
  File.write('pingapp_report.log', report)
  exit
}

while true
  sleep @interval

  t0 = Time.now
  begin
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
  rescue Exception => e
    @logger.info( "ERROR: #{e.message}: #{e.cause}")
    update_slowest(t0)
    @failures += 1
    next
  end

  if response.code == '200'
    if not @validation or response.body.include? @validation
      @logger.info( "OK")
      @successes += 1
    else
      @logger.info( "ERROR: response does not contain string: #{@validation}")
      @failures += 1
    end
  else
    @logger.info( "ERROR: Response code: " + response.code)
    @failures += 1
  end
  update_slowest(t0)

end
