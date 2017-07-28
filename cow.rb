require 'logger'

main_pid = $$
logger = Logger.new $stdout
logger.formatter = proc do |_severity, datetime, _progname, msg|
  name = $$ == main_pid ? 'MAIN' : $$
  "#{datetime}: [#{name}] #{msg}\n"
end

memory = proc do
  memory_usage_mb = `ps -o rss -p #{$$}`.chomp.split("\n").last.to_i / 1024
  logger.info "Memory usage is #{memory_usage_mb} MB"
  memory_usage_mb
end

array = []

experiment = proc do |purpose, &blk|
  logger.info "Experiment reason - #{purpose}"
  initial_memory = memory.call
  blk.call
  final = memory.call - initial_memory
  logger.info "Memory increase by #{final} MB!!"
  logger.info "----End of experiment\n\n"
end

experiment.call('Start') do
  (1..5_000_000).each { |e| array << e}
end


fork do
  experiment.call('No changes') do
  logger.info "I won\'t mess up with shared memory"
  end
end

Process.wait

fork do
  experiment.call('Access elements') do
    array.each {|e| e }
  end
end


Process.wait

fork do
  experiment.call('Modify elements') do
    array.map {|e| e  * 2}
  end
end

Process.wait